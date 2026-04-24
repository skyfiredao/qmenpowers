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

BIRTH_JSON_PATH="./qmen_birth.json"
BIRTH_YEAR_STEM=""
_SHOW_WANWU=""

show_help() {
  cat <<'HELP'
用法: qimen_caiguan.sh [选项]

财官诊断 — 财富事业双维度分析

选项:
  --wanwu                 文本输出中显示万物类象
  -h, --help              显示帮助

依赖: ./qmen_birth.json（由 qimen.sh --type=birth "YYYY-MM-DD HH:MM" 生成）
HELP
}

while (( $# > 0 )); do
  case "$1" in
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

source "$BASE_DIR/lib/data_loader.sh"

dl_load_file "$BASE_DIR/data/meta_huaqizhen.dat"
dl_load_file "$BASE_DIR/data/hangye_quxiang.dat"
dl_load_file "$BASE_DIR/data/rules_buzhen.dat"
dl_load_file "$BASE_DIR/data/buzhen_xiangshu.dat"
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
source "$BASE_DIR/lib/qimen_caiguan.sh"

_extract_birth_year_stem() {
  local line=""
  while IFS= read -r line; do
    if [[ "$line" == *'"year":'* ]]; then
      local val="${line#*\"year\": \"}"
      val="${val%%\"*}"
      _qj_extract_stem "$val"
      return 0
    fi
  done < "$BIRTH_JSON_PATH"
  echo "Error: could not extract year from $BIRTH_JSON_PATH" >&2
  return 1
}

_BIRTH_DATETIME=""
_BIRTH_SIZHU=""
_extract_birth_header() {
  local line="" dt="" y="" m="" d="" h=""
  while IFS= read -r line; do
    if [[ "$line" == *'"datetime":'* ]]; then
      dt="${line#*\"datetime\": \"}"; dt="${dt%%\"*}"
      _BIRTH_DATETIME="$dt"
    fi
    if [[ "$line" == *'"year":'* && -z "$y" ]]; then
      y="${line#*\"year\": \"}"; y="${y%%\"*}"
    fi
    if [[ "$line" == *'"month":'* && -z "$m" ]]; then
      m="${line#*\"month\": \"}"; m="${m%%\"*}"
    fi
    if [[ "$line" == *'"day":'* && -z "$d" ]]; then
      d="${line#*\"day\": \"}"; d="${d%%\"*}"
    fi
    if [[ "$line" == *'"hour":'* && -z "$h" ]]; then
      h="${line#*\"hour\": \"}"; h="${h%%\"*}"
    fi
  done < "$BIRTH_JSON_PATH"
  _BIRTH_SIZHU="${y} ${m} ${d} ${h}"
}

BIRTH_YEAR_STEM="$(_extract_birth_year_stem)"
if [[ -z "$BIRTH_YEAR_STEM" ]]; then
  echo "Error: failed to extract birth year stem from $BIRTH_JSON_PATH" >&2
  exit 1
fi
_extract_birth_header

hq_run_analysis "$BIRTH_JSON_PATH" "$BIRTH_YEAR_STEM" "./qmen_caiguan.json"
echo "Caiguan analysis written to: ./qmen_caiguan.json" >&2
