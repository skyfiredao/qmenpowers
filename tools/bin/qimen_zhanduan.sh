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

INPUT_PATH="./qmen_event.json"
OUTPUT_PATH="./qmen_zhanduan.json"
TOPIC=""


show_help() {
  cat <<'HELP'
用法: qimen_zhanduan.sh [选项]

奇门遁甲占断

选项:
  --input=PATH          输入起局 JSON（默认: ./qmen_event.json）
  --topic=KEY           占断主题（如: 婚姻、官司）
  -h, --help            显示帮助

依赖: 问事局 JSON（由 qimen_qiju.sh --type=event "YYYY-MM-DD HH:MM" 生成）
      命盘 JSON（./qmen_birth.json，自动读取年命天干）
HELP
}

while (( $# > 0 )); do
  case "$1" in
    --input=*)      INPUT_PATH="${1#--input=}"; shift ;;
    --topic=*)      TOPIC="${1#--topic=}"; shift ;;
    -h|--help)      show_help; exit 0 ;;
    *)              echo "Error: unknown option: $1" >&2; exit 1 ;;
  esac
done

# --- Source libraries ---
source "$BASE_DIR/lib/data_loader.sh"
dl_load_all "$BASE_DIR/data"
source "$BASE_DIR/lib/qimen_json.sh"
source "$BASE_DIR/lib/qimen_zhanduan.sh"

# --- No topic: show help + topic list ---
if [[ -z "$TOPIC" ]]; then
  show_help
  echo ""
  echo "可用占断主题 (${#topic_list[@]} 个):"
  for t in "${topic_list[@]}"; do
    echo "  $t"
  done
  exit 0
fi

dl_get_v "${TOPIC}_label" 2>/dev/null || true
if [[ -z "$_DL_RET" ]]; then
  echo "Error: topic not found: $TOPIC" >&2
  echo ""
  echo "可用占断主题:"
  for t in "${topic_list[@]}"; do
    echo "  $t" >&2
  done
  exit 1
fi

# --- Validate input plate ---
if [[ ! -f "$INPUT_PATH" ]]; then
  echo "Error: input plate not found: $INPUT_PATH" >&2
  echo "Generate first: qimen_qiju.sh --type=event \"YYYY-MM-DD HH:MM\"" >&2
  exit 1
fi

# --- Parse plate ---
qj_parse_plate_json "$INPUT_PATH"
qj_find_ri_gan_palace
qj_find_shi_gan_palace

# --- Auto-read nianming from birth plate ---
BIRTH_JSON_PATH="./qmen_birth.json"
if [[ -f "$BIRTH_JSON_PATH" ]]; then
  local_nm_stem=""
  while IFS= read -r _line; do
    if [[ "$_line" == *'"year":'* ]]; then
      local_nm_stem="${_line#*\"year\": \"}"
      local_nm_stem="${local_nm_stem%%\"*}"
      local_nm_stem="${local_nm_stem:0:1}"
      break
    fi
  done < "$BIRTH_JSON_PATH"
  if [[ -n "$local_nm_stem" ]]; then
    dl_set "nianming_stem" "$local_nm_stem"
    local_nm_palace=""
    for _p in 1 2 3 4 5 6 7 8 9; do
      dl_get_v "palace_${_p}_di_gan" 2>/dev/null || true
      if [[ "$_DL_RET" == "$local_nm_stem" ]]; then
        local_nm_palace="$_p"
        break
      fi
    done
    dl_set "nianming_palace" "$local_nm_palace"
  fi
fi

# --- Run topic ---
_zd_run_topic "$TOPIC"

# --- Output ---
_zd_output_text
_zd_output_json "$OUTPUT_PATH"
