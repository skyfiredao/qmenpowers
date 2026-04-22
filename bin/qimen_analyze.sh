#!/usr/bin/env bash
# Copyright (C) 2025 — Licensed under GPL-3.0
# See https://www.gnu.org/licenses/gpl-3.0.html
set -euo pipefail

# --- Resolve SCRIPT_DIR (follow symlinks) ---
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

# --- Defaults ---
INPUT_PATH="./qmen_event.json"
OUTPUT_PATH="./qmen_analysis.json"
QUESTION_TYPE=""
VERBOSE=0
_SHOW_WANWU=""

# --- Help ---
show_help() {
  cat <<'HELP'
用法: qimen_analyze.sh [选项]

奇门遁甲分析
万物类象查表 + 用神标记

选项:
  --input=PATH        输入起局 JSON（默认: ./qmen_event.json）
  --output=PATH       输出分析 JSON（默认: ./qmen_analysis.json）
  --question=TYPE     问题类型（必填，见下方）
  --verbose           完整万物类象提取（默认精简）
  --wanwu             文本输出中显示万物类象
  -h, --help          显示帮助

问题类型:
  事业          事业仕途
  求财          求财理财
  婚姻感情      婚姻感情
  疾病健康      疾病健康
  出行          出行远行
  官司诉讼      官司诉讼
  寻人寻物      寻人寻物
  天气          天气气象
  家宅风水      家宅风水
HELP
}

# --- Parse options ---
while (( $# > 0 )); do
  case "$1" in
    --input=*)   INPUT_PATH="${1#--input=}"; shift ;;
    --output=*)  OUTPUT_PATH="${1#--output=}"; shift ;;
    --question=*) QUESTION_TYPE="${1#--question=}"; shift ;;
    --verbose)   VERBOSE=1; shift ;;
    --wanwu)     _SHOW_WANWU="true"; shift ;;
    -h|--help)   show_help; exit 0 ;;
    *)           echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# --- Validate ---
if [[ -z "$QUESTION_TYPE" ]]; then
  echo "Error: --question=TYPE is required" >&2
  echo "Valid types: 事业,求财,婚姻感情,疾病健康,出行,官司诉讼,寻人寻物,天气,家宅风水" >&2
  exit 1
fi

# --- Source libraries ---
source "$BASE_DIR/lib/data_loader.sh"

# --- Load data files (only analysis-relevant ones, not full engine data) ---
dl_load_file "$BASE_DIR/data/wanwu_prefix_map.dat"
dl_load_file "$BASE_DIR/data/rules_yongshen.dat"
dl_load_file "$BASE_DIR/data/wanwu_nine_stars.dat"
dl_load_file "$BASE_DIR/data/wanwu_eight_gates.dat"
dl_load_file "$BASE_DIR/data/wanwu_eight_deities.dat"
dl_load_file "$BASE_DIR/data/wanwu_tiangan.dat"
dl_load_file "$BASE_DIR/data/wanwu_dizhi.dat"
dl_load_file "$BASE_DIR/data/wanwu_wuxing.dat"
dl_load_file "$BASE_DIR/data/wanwu_geju.dat"

source "$BASE_DIR/lib/qimen_analysis.sh"

# --- Execute analysis pipeline ---
dl_set "plate_source" "$INPUT_PATH"
dl_set "question_type" "$QUESTION_TYPE"

qa_parse_plate_json "$INPUT_PATH"
qa_find_ri_gan_palace
qa_find_shi_gan_palace
qa_load_yongshen_rules "$QUESTION_TYPE"
qa_mark_yongshen

# Look up wanwu correspondences for all palaces
for p in 1 2 3 4 6 7 8 9; do
    qa_lookup_wanwu "$p" "$VERBOSE"
    qa_lookup_combination "$p"
done
# Palace 5: stem only (no star/gate/deity)
qa_lookup_wanwu 5 "$VERBOSE" stem_only
qa_lookup_combination 5

# Generate output
qa_output_analysis_text
qa_output_analysis_json "$OUTPUT_PATH"
echo "Analysis written to: $OUTPUT_PATH" >&2
