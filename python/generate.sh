#!/usr/bin/env bash
# Usage: ./generate.sh <idl_dir>
#   ./generate.sh board
#   ./generate.sh bubble_pal_engine
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PY="$(cd "$(dirname "$0")" && pwd)"
DOMAIN="${1:?usage: $0 <board|profile|bubble_pal_api|bubble_pal_engine|content_fetcher>}"
IDL="$ROOT/$DOMAIN"
[[ -d "$IDL" ]] || { echo "missing IDL dir: $IDL" >&2; exit 1; }

# clear previous generated tree for this domain only
rm -rf "$PY/$DOMAIN"

python3 -m grpc_tools.protoc \
  -I"$ROOT" \
  -I"$(python3 -c 'import grpc_tools, pathlib; print(pathlib.Path(grpc_tools.__file__).parent / "proto")')" \
  --python_out="$PY" \
  --grpc_python_out="$PY" \
  --pyi_out="$PY" \
  "$IDL"/v1/*.proto

find "$PY/$DOMAIN" -type d -exec touch {}/__init__.py \;

# hatch package metadata for this domain
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

[tool.hatch.build.targets.wheel]
packages = ["${DOMAIN}"]

[tool.hatch.build.targets.sdist]
include = ["${DOMAIN}", "README.md"]
EOF

echo "generated $DOMAIN → package ${PKG_NAME}==${VERSION}"
