#!/usr/bin/env bash
set -euo pipefail

# voice-changer-lab のルートで vibeboard を起動する。
# 追加引数 (--port 等) はそのまま vibeboard に渡す。
# 例: ./run-vibeboard.sh --port 3020

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLI="$ROOT_DIR/vibeboard/dist/cli.js"

if [ ! -f "$CLI" ]; then
  echo "[run-vibeboard] $CLI が見つかりません。初回は次を実行してください:" >&2
  echo "  (cd \"$ROOT_DIR/vibeboard\" && npm install)" >&2
  exit 1
fi

exec node "$CLI" --root "$ROOT_DIR" "$@"
