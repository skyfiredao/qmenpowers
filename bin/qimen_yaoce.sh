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

BIRTH_JSON_PATH="./qmen_birth.json"
EVENT_JSON_PATH="./qmen_event.json"
OUTPUT_PATH="./qmen_yaoce.json"
_SHOW_WANWU=""
_YIXIANG=""

show_help() {
  cat <<'HELP'
用法: qimen_yaoce.sh [选项]

遥测分析 — 跨盘（生日局+问事局）关联分析

将命主日干、时干、生年干及符使干定位到问事局上，分析六害、万物取象。

选项:
  --event=PATH            问事局 JSON 路径 (默认: ./qmen_event.json)
  --yixiang=C1,C2         意象保护概念: 财富,暴力,权威,突破,表现,情欲 (可选)
                          也可直接传天干字符 (如 --yixiang=戊)
  --wanwu                 文本输出中显示万物类象
  -h, --help              显示帮助

依赖:
  ./qmen_birth.json  (由 qimen.sh --type=birth "YYYY-MM-DD HH:MM" 生成)
  ./qmen_event.json  (由 qimen.sh "YYYY-MM-DD HH:MM" 生成)
HELP
}

while (( $# > 0 )); do
  case "$1" in
    --event=*)            EVENT_JSON_PATH="${1#--event=}"; shift ;;
    --yixiang=*)          _YIXIANG="${1#--yixiang=}"; shift ;;
    --wanwu)              _SHOW_WANWU="true"; shift ;;
    -h|--help)            show_help; exit 0 ;;
    *)                    echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ ! -f "$BIRTH_JSON_PATH" ]]; then
  echo "Error: birth plate not found: $BIRTH_JSON_PATH" >&2
  echo "Generate it first: qimen.sh --type=birth \"YYYY-MM-DD HH:MM\"" >&2
  exit 1
fi

if [[ ! -f "$EVENT_JSON_PATH" ]]; then
  echo "Error: event plate not found: $EVENT_JSON_PATH" >&2
  echo "Generate it first: qimen.sh \"YYYY-MM-DD HH:MM\"" >&2
  exit 1
fi

source "$BASE_DIR/lib/data_loader.sh"

dl_load_file "$BASE_DIR/data/meta_huaqizhen.dat"
dl_load_file "$BASE_DIR/data/meta_palace.dat"
dl_load_file "$BASE_DIR/data/wanwu_prefix_map.dat"
dl_load_file "$BASE_DIR/data/wanwu_nine_stars.dat"
dl_load_file "$BASE_DIR/data/wanwu_eight_gates.dat"
dl_load_file "$BASE_DIR/data/wanwu_eight_deities.dat"
dl_load_file "$BASE_DIR/data/wanwu_tiangan.dat"
dl_load_file "$BASE_DIR/data/wanwu_dizhi.dat"
dl_load_file "$BASE_DIR/data/wanwu_huaqizhen.dat"
dl_load_file "$BASE_DIR/data/nine_stars.dat"
dl_load_file "$BASE_DIR/data/eight_gates.dat"

source "$BASE_DIR/lib/qimen_json.sh"
source "$BASE_DIR/lib/qimen_banmenhuaqizhen.sh"
source "$BASE_DIR/lib/qimen_yaoce.sh"

yc_run_analysis "$BIRTH_JSON_PATH" "$EVENT_JSON_PATH" "$OUTPUT_PATH" "$_YIXIANG"
echo "Yaogce analysis written to: $OUTPUT_PATH" >&2
