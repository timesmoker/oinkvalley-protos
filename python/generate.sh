#!/usr/bin/env bash
# Usage: ./generate.sh <idl_dir>
#   ./generate.sh board
#   ./generate.sh bubble_pal_engine
#
# Emits import root oinkvalley_<domain> (avoids clashing with app packages
# like content_fetcher). Hatch ignore-vcs=true so gitignored stubs still
# land in the wheel.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PY="$(cd "$(dirname "$0")" && pwd)"
DOMAIN="${1:?usage: $0 <board|profile|bubble_pal_api|bubble_pal_engine|content_fetcher>}"
IDL="$ROOT/$DOMAIN"
[[ -d "$IDL" ]] || { echo "missing IDL dir: $IDL" >&2; exit 1; }

OUT_PKG="oinkvalley_${DOMAIN}"

rm -rf "$PY/$DOMAIN" "$PY/$OUT_PKG"

python3 -m grpc_tools.protoc \
  -I"$ROOT" \
  -I"$(python3 -c 'import grpc_tools, pathlib; print(pathlib.Path(grpc_tools.__file__).parent / "proto")')" \
  --python_out="$PY" \
  --grpc_python_out="$PY" \
  --pyi_out="$PY" \
  "$IDL"/v1/*.proto

# content_fetcher/v1 → oinkvalley_content_fetcher/v1
mkdir -p "$PY/$OUT_PKG"
mv "$PY/$DOMAIN/v1" "$PY/$OUT_PKG/v1"
rmdir "$PY/$DOMAIN" 2>/dev/null || rm -rf "$PY/$DOMAIN"

# fix grpc stub imports: from content_fetcher.v1 → from oinkvalley_content_fetcher.v1
while IFS= read -r -d '' f; do
  sed -i "s/from ${DOMAIN}\\.v1/from ${OUT_PKG}.v1/g" "$f"
done < <(find "$PY/$OUT_PKG" -name '*_pb2_grpc.py' -print0)

find "$PY/$OUT_PKG" -type d -exec touch {}/__init__.py \;

ART="${DOMAIN//_/-}-v1"
PKG_NAME="oinkvalley-protos-${ART}"
VERSION="${VERSION:-0.0.0}"
cat > "$PY/pyproject.toml" <<EOF
[build-system]
requires = ["hatchling>=1.25"]
build-backend = "hatchling.build"

[project]
name = "${PKG_NAME}"
version = "${VERSION}"
description = "Generated gRPC stubs: ${DOMAIN}"
readme = "README.md"
requires-python = ">=3.11"
dependencies = [
  "grpcio>=1.68",
  "protobuf>=5.29",
]

[tool.hatch.build]
# generated tree is gitignored; without this the wheel ships empty metadata only
ignore-vcs = true

[tool.hatch.build.targets.wheel]
packages = ["${OUT_PKG}"]

[tool.hatch.build.targets.sdist]
include = ["${OUT_PKG}", "README.md"]
EOF

echo "generated ${OUT_PKG} → package ${PKG_NAME}==${VERSION}"
