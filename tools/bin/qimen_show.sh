#!/usr/bin/env bash
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

INPUT_PATH=""
OUTPUT_PATH=""

show_help() {
  cat <<'HELP'
用法: qimen_show.sh INPUT [--output=PATH]

读取起局 JSON，以文本格式显示盘面（与 qimen_qiju.sh 输出一致）。
指定 --output 时将 JSON 复制到目标路径。

参数:
  INPUT               输入 JSON 文件（必填）
  --output=PATH       复制 JSON 到指定路径（可选）
  -h, --help          显示帮助
HELP
}

while (( $# > 0 )); do
  case "$1" in
    --output=*)
      OUTPUT_PATH="${1#--output=}"
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    -*)
      echo "Error: unknown option: $1" >&2
      show_help >&2
      exit 1
      ;;
    *)
      INPUT_PATH="$1"
      shift
      ;;
  esac
done

if [[ -z "$INPUT_PATH" ]]; then
  echo "Error: input file is required." >&2
  show_help >&2
  exit 1
fi

if [[ ! -f "$INPUT_PATH" ]]; then
  echo "Error: file not found: $INPUT_PATH" >&2
  exit 1
fi

source "$BASE_DIR/lib/data_loader.sh"
dl_load_all "$BASE_DIR/data"
source "$BASE_DIR/lib/qimen_engine.sh"
source "$BASE_DIR/lib/qimen_output.sh"
source "$BASE_DIR/lib/qimen_json.sh"

qj_parse_plate_json "$INPUT_PATH"

_show_gz_to_idx() {
  local name="$1" i
  for ((i=0; i<60; i++)); do
    if [[ "$(cal_ganzhi_name "$i")" == "$name" ]]; then
      echo "$i"
      return 0
    fi
  done
  echo "0"
}

_show_star_to_idx() {
  local name="$1" i
  for ((i=0; i<${#STAR_NAMES[@]}; i++)); do
    if [[ "${STAR_NAMES[$i]}" == "$name" ]]; then
      echo "$i"
      return 0
    fi
  done
  echo "-1"
}

_show_gate_to_idx() {
  local name="$1" i
  for ((i=0; i<${#GATE_NAMES[@]}; i++)); do
    if [[ "${GATE_NAMES[$i]}" == "$name" ]]; then
      echo "$i"
      return 0
    fi
  done
  echo "-1"
}

_show_deity_to_idx() {
  local name="$1" i
  for ((i=0; i<${#DEITY_YANG[@]}; i++)); do
    if [[ "${DEITY_YANG[$i]}" == "$name" ]]; then
      echo "$i"
      return 0
    fi
  done
  for ((i=0; i<${#DEITY_YIN[@]}; i++)); do
    if [[ "${DEITY_YIN[$i]}" == "$name" ]]; then
      echo "$i"
      return 0
    fi
  done
  echo "-1"
}

_show_bool() {
  local v="$1"
  if [[ "$v" == "true" ]]; then echo 1; else echo 0; fi
}

dl_get_v "plate_datetime" 2>/dev/null || true
_SH_DT="$_DL_RET"
_SH_DATE="${_SH_DT%% *}"
_SH_TIME="${_SH_DT##* }"
IFS='-' read -r QM_YEAR QM_MONTH QM_DAY <<< "$_SH_DATE"
IFS=':' read -r QM_HOUR QM_MIN <<< "$_SH_TIME"
QM_YEAR=$((10#$QM_YEAR)); QM_MONTH=$((10#$QM_MONTH)); QM_DAY=$((10#$QM_DAY))
QM_HOUR=$((10#$QM_HOUR)); QM_MIN=$((10#$QM_MIN))

dl_get_v "plate_si_zhu_year" 2>/dev/null || true; QM_YEAR_GZ=$(_show_gz_to_idx "$_DL_RET")
dl_get_v "plate_si_zhu_month" 2>/dev/null || true; QM_MONTH_GZ=$(_show_gz_to_idx "$_DL_RET")
dl_get_v "plate_si_zhu_day" 2>/dev/null || true; QM_DAY_GZ=$(_show_gz_to_idx "$_DL_RET")
dl_get_v "plate_si_zhu_hour" 2>/dev/null || true; QM_HOUR_GZ=$(_show_gz_to_idx "$_DL_RET")

dl_get_v "plate_ju_type" 2>/dev/null || true; QM_JU_TYPE="$_DL_RET"
dl_get_v "plate_ju_number" 2>/dev/null || true; QM_JU_NUM="$_DL_RET"
dl_get_v "plate_ju_yuan" 2>/dev/null || true; QM_YUAN="$_DL_RET"
dl_get_v "plate_ju_run" 2>/dev/null || true
if [[ "$_DL_RET" == "true" ]]; then QM_IS_RUN=1; else QM_IS_RUN=0; fi

dl_get_v "plate_zhi_fu_star" 2>/dev/null || true; QM_ZHIFU_STAR="$_DL_RET"
dl_get_v "plate_zhi_shi_gate" 2>/dev/null || true; QM_ZHISHI_GATE="$_DL_RET"

dl_get_v "plate_kong_wang_0_branch" 2>/dev/null || true
QM_KONGWANG_1=$(_qm_branch_index_by_char "$_DL_RET") || QM_KONGWANG_1=0
dl_get_v "plate_kong_wang_1_branch" 2>/dev/null || true
QM_KONGWANG_2=$(_qm_branch_index_by_char "$_DL_RET") || QM_KONGWANG_2=0

dl_get_v "plate_yi_ma_branch" 2>/dev/null || true
QM_YIMA=$(_qm_branch_index_by_char "$_DL_RET") || QM_YIMA=0

dl_get_v "plate_tianqin_host_palace" 2>/dev/null || true
QM_TIANQIN_FOLLOW_PALACE="${_DL_RET:-2}"

declare -a QM_HEAVEN=() QM_HEAVEN_STEM=() QM_HUMAN=() QM_DEITY=() QM_EARTH=() QM_STATES=()
declare -a QM_JIXING=() QM_GENG=() QM_RUMU_GAN=() QM_RUMU_STAR=() QM_RUMU_GATE=() QM_MENPO=()
declare -a QM_STAR_FANYIN=() QM_GATE_FANYIN=() QM_STAR_FUYIN=() QM_GATE_FUYIN=()
declare -a QM_GAN_FANYIN=() QM_GAN_FUYIN=()

QM_TIANQIN_STEM=""

for ((_p=1; _p<=9; _p++)); do
  dl_get_v "palace_${_p}_star" 2>/dev/null || true
  QM_HEAVEN[$_p]=$(_show_star_to_idx "$_DL_RET")

  dl_get_v "palace_${_p}_tian_gan" 2>/dev/null || true
  QM_HEAVEN_STEM[$_p]="$_DL_RET"

  dl_get_v "palace_${_p}_gate" 2>/dev/null || true
  QM_HUMAN[$_p]=$(_show_gate_to_idx "$_DL_RET")

  dl_get_v "palace_${_p}_deity" 2>/dev/null || true
  QM_DEITY[$_p]=$(_show_deity_to_idx "$_DL_RET")

  dl_get_v "palace_${_p}_di_gan" 2>/dev/null || true
  QM_EARTH[$_p]="$_DL_RET"

  dl_get_v "palace_${_p}_state" 2>/dev/null || true
  QM_STATES[$_p]="$_DL_RET"

  dl_get_v "palace_${_p}_ji_xing" 2>/dev/null || true; QM_JIXING[$_p]=$(_show_bool "$_DL_RET")
  dl_get_v "palace_${_p}_geng" 2>/dev/null || true; QM_GENG[$_p]=$(_show_bool "$_DL_RET")
  dl_get_v "palace_${_p}_rumu_gan" 2>/dev/null || true; QM_RUMU_GAN[$_p]=$(_show_bool "$_DL_RET")
  dl_get_v "palace_${_p}_rumu_star" 2>/dev/null || true; QM_RUMU_STAR[$_p]=$(_show_bool "$_DL_RET")
  dl_get_v "palace_${_p}_rumu_gate" 2>/dev/null || true; QM_RUMU_GATE[$_p]=$(_show_bool "$_DL_RET")
  dl_get_v "palace_${_p}_men_po" 2>/dev/null || true; QM_MENPO[$_p]=$(_show_bool "$_DL_RET")
  dl_get_v "palace_${_p}_star_fan_yin" 2>/dev/null || true; QM_STAR_FANYIN[$_p]=$(_show_bool "$_DL_RET")
  dl_get_v "palace_${_p}_gate_fan_yin" 2>/dev/null || true; QM_GATE_FANYIN[$_p]=$(_show_bool "$_DL_RET")
  dl_get_v "palace_${_p}_star_fu_yin" 2>/dev/null || true; QM_STAR_FUYIN[$_p]=$(_show_bool "$_DL_RET")
  dl_get_v "palace_${_p}_gate_fu_yin" 2>/dev/null || true; QM_GATE_FUYIN[$_p]=$(_show_bool "$_DL_RET")
  dl_get_v "palace_${_p}_gan_fan_yin" 2>/dev/null || true; QM_GAN_FANYIN[$_p]=$(_show_bool "$_DL_RET")
  dl_get_v "palace_${_p}_gan_fu_yin" 2>/dev/null || true; QM_GAN_FUYIN[$_p]=$(_show_bool "$_DL_RET")

  if (( _p == QM_TIANQIN_FOLLOW_PALACE )); then
    dl_get_v "palace_${_p}_tianqin_stem" 2>/dev/null || true
    QM_TIANQIN_STEM="$_DL_RET"
  fi
done

qm_output_text

if [[ -n "$OUTPUT_PATH" ]]; then
  cp -f "$INPUT_PATH" "$OUTPUT_PATH"
  echo ""
  echo "→ $OUTPUT_PATH"
fi
