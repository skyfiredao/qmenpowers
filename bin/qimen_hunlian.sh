#!/usr/bin/env bash
# Copyright (C) 2025 — Licensed under GPL-3.0
# See https://www.gnu.org/licenses/gpl-3.0.html
set -euo pipefail

_resolve_link() {
  local f="$1"
  while [[ -L "$f" ]]; do
    local dir="$(cd "$(dirname "$f")" && pwd)"
    f="$(readlink "$f")"
    [[ "$f" != /* ]] && f="$dir/$f"
  done
  echo "$f"
}
SCRIPT_DIR="$(cd "$(dirname "$(_resolve_link "${BASH_SOURCE[0]}")")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

INPUT_PATH="./qmen_birth.json"
OUTPUT_PATH="./qmen_hunlian.json"
BIRTH_JSON_PATH="./qmen_birth.json"
_SHOW_WANWU=""

show_help() {
  cat <<'HELP'
用法: qimen_hunlian.sh [选项]

婚恋分析 — 脱单·厮守·桃花·情趣

选项:
  --input=PATH            输入起局 JSON（默认: ./qmen_birth.json）
  --output=PATH           输出分析 JSON（默认: ./qmen_hunlian.json）
  --wanwu                 文本输出中显示万物类象
  -h, --help              显示帮助

依赖: ./qmen_birth.json（由 qimen.sh --type=birth "YYYY-MM-DD HH:MM" 生成）
HELP
}

while (( $# > 0 )); do
  case "$1" in
    --input=*)            INPUT_PATH="${1#--input=}"; shift ;;
    --output=*)           OUTPUT_PATH="${1#--output=}"; shift ;;
    --wanwu)              _SHOW_WANWU="true"; shift ;;
    -h|--help)            show_help; exit 0 ;;
    *)                    echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ ! -f "$INPUT_PATH" ]]; then
  echo "Error: plate not found: $INPUT_PATH" >&2
  echo "Generate it first: qimen.sh \"YYYY-MM-DD HH:MM\"" >&2
  exit 1
fi

if [[ ! -f "$BIRTH_JSON_PATH" ]]; then
  echo "Error: birth plate not found: $BIRTH_JSON_PATH" >&2
  echo "Generate it first: qimen.sh --type=birth \"YYYY-MM-DD HH:MM\"" >&2
  exit 1
fi

source "$BASE_DIR/lib/data_loader.sh"

dl_load_file "$BASE_DIR/data/rules_hunlian.dat"
dl_load_file "$BASE_DIR/data/meta_palace.dat"
dl_load_file "$BASE_DIR/data/meta_huaqizhen.dat"
dl_load_file "$BASE_DIR/data/nine_stars.dat"
dl_load_file "$BASE_DIR/data/eight_gates.dat"
dl_load_file "$BASE_DIR/data/wanwu_prefix_map.dat"
dl_load_file "$BASE_DIR/data/wanwu_nine_stars.dat"
dl_load_file "$BASE_DIR/data/wanwu_eight_gates.dat"
dl_load_file "$BASE_DIR/data/wanwu_eight_deities.dat"
dl_load_file "$BASE_DIR/data/wanwu_tiangan.dat"
dl_load_file "$BASE_DIR/data/wanwu_dizhi.dat"

source "$BASE_DIR/lib/qimen_json.sh"
source "$BASE_DIR/lib/qimen_banmenhuaqizhen.sh"
source "$BASE_DIR/lib/qimen_hunlian.sh"

_SHOW_EVENT_HEADER=""
if [[ "$INPUT_PATH" != "$BIRTH_JSON_PATH" ]]; then
  _SHOW_EVENT_HEADER="true"
fi

hl_run_analysis "$INPUT_PATH" "$BIRTH_JSON_PATH" "$OUTPUT_PATH"
echo "Hunlian analysis written to: $OUTPUT_PATH" >&2
