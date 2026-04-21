#!/usr/bin/env bash
# Copyright (C) 2025 — Licensed under GPL-3.0
# See https://www.gnu.org/licenses/gpl-3.0.html
set -euo pipefail

# --- Resolve SCRIPT_DIR (follow symlinks — needed for install.sh symlink) ---
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
OUTPUT_MODE="text"
TIANQIN_MODE="jikun"
INFO_ONLY=0
DATETIME_ARG=""
PLATE_TYPE="event"
JSON_OUTPUT_PATH=""

# --- Help ---
show_help() {
  cat <<'HELP'
Usage: qimen.sh [OPTIONS] [DATETIME]

奇门遁甲起局 (Qi Men Dun Jia Plate Setting)
时家奇门 · 置闰法

DATETIME format: "YYYY-MM-DD HH:MM" (default: current time)

Options:
  -j, --json          Output as JSON
  --type=TYPE         Plate type: "event" (default) or "birth"
                      event → ./qmen_event.json, birth → ./qmen_birth.json
  --tianqin=MODE      天禽 handling: "jikun" (default), "follow-tiannei", or "follow-zhifu"
  --output=PATH       JSON output file path (overrides --type default)
  --info-only         Show ju determination info only
  -h, --help          Show this help
HELP
}

# --- Parse options ---
while (( $# > 0 )); do
  case "$1" in
    -j|--json)
      OUTPUT_MODE="json"
      shift
      ;;
    --tianqin=*)
      TIANQIN_MODE="${1#--tianqin=}"
      shift
      ;;
    --type=*)
      PLATE_TYPE="${1#--type=}"
      shift
      ;;
    --output=*)
      JSON_OUTPUT_PATH="${1#--output=}"
      shift
      ;;
    --info-only)
      INFO_ONLY=1
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    -*)
      echo "Unknown option: $1" >&2
      show_help >&2
      exit 1
      ;;
    *)
      DATETIME_ARG="$1"
      shift
      ;;
  esac
done

# --- Validate type and set default output path ---
case "$PLATE_TYPE" in
  event|birth) ;;
  *) echo "Error: invalid --type value: $PLATE_TYPE (expected: event or birth)" >&2; exit 1 ;;
esac
if [[ -z "$JSON_OUTPUT_PATH" ]]; then
  if [[ "$PLATE_TYPE" == "birth" ]]; then
    JSON_OUTPUT_PATH="./qmen_birth.json"
  else
    JSON_OUTPUT_PATH="./qmen_event.json"
  fi
fi

# --- Source libraries and load data ---
source "$BASE_DIR/lib/data_loader.sh"
dl_load_all "$BASE_DIR/data"
source "$BASE_DIR/lib/qimen_engine.sh"
source "$BASE_DIR/lib/qimen_output.sh"

# --- Parse datetime ---
if [[ -n "$DATETIME_ARG" ]]; then
  if [[ ! "$DATETIME_ARG" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}$ ]]; then
    echo "Error: invalid datetime format. Expected: YYYY-MM-DD HH:MM" >&2
    exit 1
  fi
  date_part="${DATETIME_ARG%% *}"
  time_part="${DATETIME_ARG##* }"
  IFS='-' read -r Y M D <<< "$date_part"
  IFS=':' read -r HOUR MIN <<< "$time_part"
else
  Y=$(date +%Y)
  M=$(date +%m)
  D=$(date +%d)
  HOUR=$(date +%H)
  MIN=$(date +%M)
fi

Y=$((10#$Y))
M=$((10#$M))
D=$((10#$D))
HOUR=$((10#$HOUR))
MIN=$((10#$MIN))

# --- Export tianqin option ---
export QM_TIANQIN_MODE="${TIANQIN_MODE}"

# --- Compute and output ---
qm_compute_plate "$Y" "$M" "$D" "$HOUR" "$MIN"

if (( INFO_ONLY )); then
  echo "局: $QM_JU_TYPE ${QM_JU_NUM}局 ($QM_YUAN)"
  (( QM_IS_RUN )) && echo "闰局"
  echo "值符: $QM_ZHIFU_STAR  值使: $QM_ZHISHI_GATE"
  echo "四柱: $(cal_ganzhi_name $QM_YEAR_GZ) $(cal_ganzhi_name $QM_MONTH_GZ) $(cal_ganzhi_name $QM_DAY_GZ) $(cal_ganzhi_name $QM_HOUR_GZ)"
elif [[ "$OUTPUT_MODE" == "json" ]]; then
  qm_output_json
else
  qm_output_text
fi

# Always write JSON file (except info-only mode)
if (( ! INFO_ONLY )); then
  qm_write_json_file "$JSON_OUTPUT_PATH"
fi
