#!/usr/bin/env bash
# Copyright (C) 2026 — Licensed under GPL-3.0
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
BIRTH_JSON_PATH="./qmen_birth.json"
OUTPUT_PATH="./qmen_yishenhuanjiang.json"
_SHOW_WANWU=""

show_help() {
  cat <<'HELP'
用法: qimen_yishenhuanjiang.sh [选项]

移神换将化解系统 — 诊断问题 + 计算化解路径 + 物象映射

选项:
  --input=PATH            输入起局 JSON（默认: ./qmen_birth.json）
  --output=PATH           输出 JSON 路径（默认: ./qmen_yishenhuanjiang.json）
  --wanwu                 文本输出中显示详细万物类象
  -h, --help              显示帮助

依赖: ./qmen_birth.json（由 qimen_qiju.sh --type=birth "YYYY-MM-DD HH:MM" 生成）
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
  echo "Generate it first: qimen_qiju.sh --type=birth \"YYYY-MM-DD HH:MM\"" >&2
  exit 1
fi

if [[ ! -f "$BIRTH_JSON_PATH" ]]; then
  echo "Error: birth plate not found: $BIRTH_JSON_PATH" >&2
  echo "Generate it first: qimen_qiju.sh --type=birth \"YYYY-MM-DD HH:MM\"" >&2
  exit 1
fi

source "$BASE_DIR/lib/data_loader.sh"

dl_load_file "$BASE_DIR/data/rules_yishenhuanjiang.dat"
dl_load_file "$BASE_DIR/data/meta_palace.dat"
dl_load_file "$BASE_DIR/data/wanwu_prefix_map.dat"
dl_load_file "$BASE_DIR/data/wanwu_nine_stars.dat"
dl_load_file "$BASE_DIR/data/wanwu_eight_gates.dat"
dl_load_file "$BASE_DIR/data/wanwu_eight_deities.dat"
dl_load_file "$BASE_DIR/data/wanwu_tiangan.dat"
dl_load_file "$BASE_DIR/data/wanwu_dizhi.dat"
dl_load_file "$BASE_DIR/data/wanwu_wuxing.dat"
dl_load_file "$BASE_DIR/data/meta_huaqizhen.dat"
dl_load_file "$BASE_DIR/data/nine_stars.dat"
dl_load_file "$BASE_DIR/data/eight_gates.dat"

source "$BASE_DIR/lib/qimen_json.sh"
source "$BASE_DIR/lib/qimen_banmenhuaqizhen.sh"
source "$BASE_DIR/lib/qimen_yishenhuanjiang.sh"

yh_run_analysis "$INPUT_PATH" "$BIRTH_JSON_PATH" "$OUTPUT_PATH"
echo "移神换将分析已写入: $OUTPUT_PATH" >&2
