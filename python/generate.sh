#!/usr/bin/env bash
# Generate Python gRPC stubs from repo-root IDL into python/{domain}/…
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PY="$ROOT/python"

for d in board profile bubble_pal_api bubble_pal_engine content_fetcher; do
  rm -rf "$PY/$d"
done

python3 -m grpc_tools.protoc \
  -I"$ROOT" \
  -I"$(python3 -c 'import grpc_tools, pathlib; print(pathlib.Path(grpc_tools.__file__).parent / "proto")')" \
  --python_out="$PY" \
  --grpc_python_out="$PY" \
  --pyi_out="$PY" \
  "$ROOT"/board/v1/*.proto \
  "$ROOT"/profile/v1/*.proto \
  "$ROOT"/bubble_pal_api/v1/*.proto \
  "$ROOT"/bubble_pal_engine/v1/*.proto \
  "$ROOT"/content_fetcher/v1/*.proto

find "$PY" -type d \( -path "$PY/board" -o -path "$PY/board/*" \
  -o -path "$PY/profile" -o -path "$PY/profile/*" \
  -o -path "$PY/bubble_pal_api" -o -path "$PY/bubble_pal_api/*" \
  -o -path "$PY/bubble_pal_engine" -o -path "$PY/bubble_pal_engine/*" \
  -o -path "$PY/content_fetcher" -o -path "$PY/content_fetcher/*" \) \
  -exec touch {}/__init__.py \;

echo "generated under $PY/{board,profile,…}"
