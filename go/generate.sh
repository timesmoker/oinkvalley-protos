#!/usr/bin/env bash
# Usage: ./go/generate.sh <idl_dir>
#   ./go/generate.sh board          → go/board/ (module github.com/timesmoker/oinkvalley-protos/go/board, package boardv1)
#
# Go 는 jar/wheel 같은 빌드 결과물이 아니라 "태그된 커밋의 소스"를 go get 으로 받는다.
# 그래서 publish 워크플로가 이 스크립트로 생성한 코드를 태그 커밋 위의 별도 커밋에 넣고
# go/<idl_dir>/v<version> 태그만 push 한다 (브랜치에는 생성 코드가 들어가지 않는다).
#
# 도구 버전 고정 — 누가 돌려도 같은 코드가 나오도록 go/.bin 에 받아 쓴다.
set -euo pipefail

PROTOC_VERSION="27.3"
PROTOC_GEN_GO_VERSION="v1.34.2"
PROTOC_GEN_GO_GRPC_VERSION="v1.5.1"
GO_DIRECTIVE="1.22.0"
GRPC_VERSION="v1.66.2"
PROTOBUF_VERSION="v1.34.2"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GO_DIR="${ROOT}/go"
BIN="${GO_DIR}/.bin"
DOMAIN="${1:?usage: $0 <board|profile|bubble_pal_api|bubble_pal_engine|content_fetcher>}"
IDL="${ROOT}/${DOMAIN}"
[[ -d "${IDL}" ]] || { echo "missing IDL dir: ${IDL}" >&2; exit 1; }

MOD="github.com/timesmoker/oinkvalley-protos/go/${DOMAIN}"
PKG="${DOMAIN//_/}v1"   # board → boardv1, bubble_pal_api → bubblepalapiv1
OUT="${GO_DIR}/${DOMAIN}"

mkdir -p "${BIN}"
if [[ ! -x "${BIN}/protoc" ]] || ! "${BIN}/protoc" --version | grep -q "${PROTOC_VERSION}"; then
  curl -sSL -o "${BIN}/protoc.zip" \
    "https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-x86_64.zip"
  rm -rf "${BIN}/protoc-dist" && mkdir -p "${BIN}/protoc-dist"
  (cd "${BIN}/protoc-dist" && unzip -q ../protoc.zip)
  ln -sf "${BIN}/protoc-dist/bin/protoc" "${BIN}/protoc"
fi
GOBIN="${BIN}" go install "google.golang.org/protobuf/cmd/protoc-gen-go@${PROTOC_GEN_GO_VERSION}"
GOBIN="${BIN}" go install "google.golang.org/grpc/cmd/protoc-gen-go-grpc@${PROTOC_GEN_GO_GRPC_VERSION}"

# proto 파일에 go_package 가 없으므로 파일별 M 매핑으로 패키지를 지정
MAPS=()
FILES=()
for f in "${IDL}"/v1/*.proto; do
  rel="${f#${ROOT}/}"
  FILES+=("${rel}")
  MAPS+=("--go_opt=M${rel}=${MOD}/${PKG}" "--go-grpc_opt=M${rel}=${MOD}/${PKG}")
done

rm -rf "${OUT}"
mkdir -p "${OUT}"
PATH="${BIN}:${PATH}" "${BIN}/protoc" -I "${ROOT}" -I "${BIN}/protoc-dist/include" \
  --go_out="${OUT}" --go_opt=module="${MOD}" \
  --go-grpc_out="${OUT}" --go-grpc_opt=module="${MOD}" \
  "${MAPS[@]}" "${FILES[@]}"

cat > "${OUT}/go.mod" <<MOD
module ${MOD}

go ${GO_DIRECTIVE}

require (
	google.golang.org/grpc ${GRPC_VERSION}
	google.golang.org/protobuf ${PROTOBUF_VERSION}
)
MOD
(cd "${OUT}" && go mod tidy)

echo "generated ${MOD} (package ${PKG}) → go/${DOMAIN}"
