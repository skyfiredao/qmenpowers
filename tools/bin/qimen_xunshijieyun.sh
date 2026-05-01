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
YIXIANG_STEMS=""
OUTPUT_DIR="./60ke"

show_help() {
  cat <<'HELP'
用法: qimen_xunshijieyun.sh [选项]

寻时借运 — 幻化六十课

选项:
  --input=PATH            输入起局 JSON（默认: ./qmen_birth.json）
  --yixiang=X1,X2         意象保护（财富,暴力,权威,突破,表现,情欲 或直接天干）
  --output-dir=PATH       六十课输出目录（默认: ./60ke/）
  -h, --help              显示帮助

依赖: ./qmen_birth.json（由 qimen_qiju.sh --type=birth "YYYY-MM-DD HH:MM" 生成）
HELP
}

while (( $# > 0 )); do
  case "$1" in
    --input=*)        INPUT_PATH="${1#--input=}"; shift ;;
    --yixiang=*)      YIXIANG_STEMS="${1#--yixiang=}"; shift ;;
    --output-dir=*)   OUTPUT_DIR="${1#--output-dir=}"; shift ;;
    -h|--help)        show_help; exit 0 ;;
    *)                echo "Error: unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ ! -f "$INPUT_PATH" ]]; then
  echo "Error: input plate not found: $INPUT_PATH" >&2
  echo "Generate first: qimen_qiju.sh --type=birth \"YYYY-MM-DD HH:MM\"" >&2
  exit 1
fi

# --- Source libraries (one-time load) ---
source "$BASE_DIR/lib/data_loader.sh"
dl_load_all "$BASE_DIR/data"

source "$BASE_DIR/lib/qimen_engine.sh"
source "$BASE_DIR/lib/qimen_output.sh"
source "$BASE_DIR/lib/qimen_json.sh"

export QM_TIANQIN_MODE="follow-tiannei"

# --- Parse input plate ---
qj_parse_plate_json "$INPUT_PATH"

dl_get_v "plate_datetime" 2>/dev/null || true
_XS_DATETIME="$_DL_RET"
_XS_DATE="${_XS_DATETIME%% *}"
_XS_TIME="${_XS_DATETIME##* }"
IFS='-' read -r _XS_Y _XS_M _XS_D <<< "$_XS_DATE"
IFS=':' read -r _XS_HOUR _XS_MIN <<< "$_XS_TIME"
_XS_Y=$((10#$_XS_Y)); _XS_M=$((10#$_XS_M)); _XS_D=$((10#$_XS_D))
_XS_HOUR=$((10#$_XS_HOUR)); _XS_MIN=$((10#$_XS_MIN))

# --- Initial full computation (populates all QM_* arrays) ---
qm_compute_plate "$_XS_Y" "$_XS_M" "$_XS_D" "$_XS_HOUR" "$_XS_MIN"

declare -a _XS_SAVED_EARTH=()
for ((_xp=1; _xp<=9; _xp++)); do
  _XS_SAVED_EARTH[$_xp]="${QM_EARTH[$_xp]}"
done

_XS_SAVED_JU_TYPE="$QM_JU_TYPE"
_XS_SAVED_JU_NUM="$QM_JU_NUM"
_XS_SAVED_YUAN="$QM_YUAN"
_XS_SAVED_IS_RUN="$QM_IS_RUN"
_XS_SAVED_DAY_GZ="$QM_DAY_GZ"
_XS_SAVED_MONTH_GZ="$QM_MONTH_GZ"
_XS_SAVED_YEAR_GZ="$QM_YEAR_GZ"

dl_get_v "plate_ju_type" 2>/dev/null || true; _XS_JU_TYPE="$_DL_RET"
dl_get_v "plate_ju_number" 2>/dev/null || true; _XS_JU_NUM="$_DL_RET"

# --- Map yixiang concepts to stems ---
_xs_yixiang_to_stem() {
  case "$1" in
    财富) echo "戊" ;; 暴力) echo "庚" ;; 权威) echo "甲" ;;
    突破) echo "辛" ;; 表现) echo "丙" ;; 情欲) echo "癸" ;;
    甲|乙|丙|丁|戊|己|庚|辛|壬|癸) echo "$1" ;;
    *) echo "Error: unknown yixiang: $1" >&2; return 1 ;;
  esac
}

# --- Build fixed protected stems (from input plate, invariant across courses) ---
dl_get_v "plate_si_zhu_day" 2>/dev/null || true
_XS_DAY_GZ_STR="$_DL_RET"
_XS_DAY_STEM="${_XS_DAY_GZ_STR:0:1}"

dl_get_v "plate_si_zhu_hour" 2>/dev/null || true
_XS_HOUR_GZ_STR="$_DL_RET"
_XS_HOUR_STEM="${_XS_HOUR_GZ_STR:0:1}"

dl_get_v "plate_si_zhu_year" 2>/dev/null || true
_XS_YEAR_GZ_STR="$_DL_RET"
_XS_YEAR_STEM="${_XS_YEAR_GZ_STR:0:1}"

_XS_FIXED_STEMS=()
_XS_FIXED_ROLES=()
_xs_add_fixed_stem() {
  local stem="$1" role="$2"
  local i
  for ((i=0; i<${#_XS_FIXED_STEMS[@]}; i++)); do
    [[ "${_XS_FIXED_STEMS[$i]}" == "$stem" ]] && return 0
  done
  _XS_FIXED_STEMS+=("$stem")
  _XS_FIXED_ROLES+=("$role")
}

_xs_add_fixed_stem "$_XS_DAY_STEM" "日干"
_xs_add_fixed_stem "$_XS_HOUR_STEM" "时干"
_xs_add_fixed_stem "$_XS_YEAR_STEM" "生年干"

if [[ -n "$YIXIANG_STEMS" ]]; then
  _xs_saved_ifs="$IFS"; IFS=','
  for _xs_yx in $YIXIANG_STEMS; do
    _xs_yx_stem=$(_xs_yixiang_to_stem "$_xs_yx") || exit 1
    _xs_add_fixed_stem "$_xs_yx_stem" "意象($_xs_yx)"
  done
  IFS="$_xs_saved_ifs"
fi

# --- Find palace for a stem (heaven plate priority, earth plate fallback) ---
_xs_find_stem_palace() {
  local stem="$1" p
  if [[ "$stem" == "甲" ]]; then
    echo "$QM_ZHIFU_TARGET_PALACE"
    return 0
  fi
  for ((p=1; p<=9; p++)); do
    if [[ "${QM_HEAVEN_STEM[$p]}" == "$stem" ]]; then
      echo "$p"
      return 0
    fi
  done
  for ((p=1; p<=9; p++)); do
    if [[ "${QM_EARTH[$p]}" == "$stem" ]]; then
      echo "$p"
      return 0
    fi
  done
  echo "0"
}

# --- Count 六害 for a palace from QM_* arrays ---
_xs_count_liuhai() {
  local palace="$1"
  _XS_LIUHAI_COUNT=0
  _XS_LIUHAI_DETAIL=""

  if (( palace == 5 || palace == 0 )); then
    return 0
  fi

  if (( QM_JIXING[palace] == 1 )); then
    _XS_LIUHAI_DETAIL="${_XS_LIUHAI_DETAIL:+${_XS_LIUHAI_DETAIL},}刑"
    _XS_LIUHAI_COUNT=$((_XS_LIUHAI_COUNT + 1))
  fi

  if (( QM_RUMU_GAN[palace] == 1 )); then
    _XS_LIUHAI_DETAIL="${_XS_LIUHAI_DETAIL:+${_XS_LIUHAI_DETAIL},}干墓"
    _XS_LIUHAI_COUNT=$((_XS_LIUHAI_COUNT + 1))
  fi
  if (( QM_RUMU_STAR[palace] == 1 )); then
    _XS_LIUHAI_DETAIL="${_XS_LIUHAI_DETAIL:+${_XS_LIUHAI_DETAIL},}星墓"
    _XS_LIUHAI_COUNT=$((_XS_LIUHAI_COUNT + 1))
  fi
  if (( QM_RUMU_GATE[palace] == 1 )); then
    _XS_LIUHAI_DETAIL="${_XS_LIUHAI_DETAIL:+${_XS_LIUHAI_DETAIL},}门墓"
    _XS_LIUHAI_COUNT=$((_XS_LIUHAI_COUNT + 1))
  fi

  if (( QM_GENG[palace] == 1 )); then
    _XS_LIUHAI_DETAIL="${_XS_LIUHAI_DETAIL:+${_XS_LIUHAI_DETAIL},}庚"
    _XS_LIUHAI_COUNT=$((_XS_LIUHAI_COUNT + 1))
  fi

  local deity_idx="${QM_DEITY[$palace]}"
  local deity_name=""
  if (( deity_idx >= 0 )); then
    deity_name=$(_qm_deity_name "$deity_idx")
  fi
  if [[ "$deity_name" == "白虎" ]]; then
    _XS_LIUHAI_DETAIL="${_XS_LIUHAI_DETAIL:+${_XS_LIUHAI_DETAIL},}虎"
    _XS_LIUHAI_COUNT=$((_XS_LIUHAI_COUNT + 1))
  fi

  local opp_palace
  opp_palace=$(_qm_opposite_palace "$palace")
  if (( opp_palace > 0 )); then
    if (( QM_GENG[opp_palace] == 1 )); then
      _XS_LIUHAI_DETAIL="${_XS_LIUHAI_DETAIL:+${_XS_LIUHAI_DETAIL},}庚(对宫)"
      _XS_LIUHAI_COUNT=$((_XS_LIUHAI_COUNT + 1))
    fi
    local opp_deity_idx="${QM_DEITY[$opp_palace]}"
    local opp_deity_name=""
    if (( opp_deity_idx >= 0 )); then
      opp_deity_name=$(_qm_deity_name "$opp_deity_idx")
    fi
    if [[ "$opp_deity_name" == "白虎" ]]; then
      _XS_LIUHAI_DETAIL="${_XS_LIUHAI_DETAIL:+${_XS_LIUHAI_DETAIL},}虎(对宫)"
      _XS_LIUHAI_COUNT=$((_XS_LIUHAI_COUNT + 1))
    fi
    if [[ "$opp_deity_name" == "玄武" ]]; then
      _XS_LIUHAI_DETAIL="${_XS_LIUHAI_DETAIL:+${_XS_LIUHAI_DETAIL},}玄武(对宫)"
      _XS_LIUHAI_COUNT=$((_XS_LIUHAI_COUNT + 1))
    fi
  fi

  if (( QM_MENPO[palace] == 1 )); then
    _XS_LIUHAI_DETAIL="${_XS_LIUHAI_DETAIL:+${_XS_LIUHAI_DETAIL},}迫"
    _XS_LIUHAI_COUNT=$((_XS_LIUHAI_COUNT + 1))
  fi

  local palace_branches="${PALACE_DIZHI[$((palace - 1))]}"
  if [[ -n "$palace_branches" ]]; then
    local _c _pdz_len=${#palace_branches}
    for ((_c=0; _c<_pdz_len; _c++)); do
      local _pch="${palace_branches:$_c:1}"
      local _bi
      _bi=$(_qm_branch_index_by_char "$_pch") || continue
      if (( _bi == QM_KONGWANG_1 || _bi == QM_KONGWANG_2 )); then
        _XS_LIUHAI_DETAIL="${_XS_LIUHAI_DETAIL:+${_XS_LIUHAI_DETAIL},}空"
        _XS_LIUHAI_COUNT=$((_XS_LIUHAI_COUNT + 1))
        break
      fi
    done
  fi
}

# --- Prepare output directory ---
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

_XS_KE_GZ=()
_XS_KE_LIUHAI=()
_XS_BEST_LIUHAI=999
_XS_BEST_KES=()

echo "寻时借运 幻化六十课"
echo "原盘: $_XS_DATETIME ${_XS_JU_TYPE}${_XS_JU_NUM}局"
echo ""

# --- Iterate 60 courses ---
for ((_xs_ke=0; _xs_ke<60; _xs_ke++)); do

  QM_HOUR_GZ="$_xs_ke"

  QM_JU_TYPE="$_XS_SAVED_JU_TYPE"
  QM_JU_NUM="$_XS_SAVED_JU_NUM"
  QM_YUAN="$_XS_SAVED_YUAN"
  QM_IS_RUN="$_XS_SAVED_IS_RUN"
  QM_DAY_GZ="$_XS_SAVED_DAY_GZ"
  QM_MONTH_GZ="$_XS_SAVED_MONTH_GZ"
  QM_YEAR_GZ="$_XS_SAVED_YEAR_GZ"

  for ((_xp=1; _xp<=9; _xp++)); do
    QM_EARTH[$_xp]="${_XS_SAVED_EARTH[$_xp]}"
  done

  for ((_xp=1; _xp<=9; _xp++)); do
    QM_HEAVEN[$_xp]=-1; QM_HEAVEN_STEM[$_xp]=""
    QM_HUMAN[$_xp]=-1; QM_DEITY[$_xp]=-1
    QM_STATES[$_xp]=""; QM_JIXING[$_xp]=0
    QM_GENG[$_xp]=0; QM_RUMU_GAN[$_xp]=0
    QM_RUMU_STAR[$_xp]=0; QM_RUMU_GATE[$_xp]=0
    QM_MENPO[$_xp]=0; QM_STAR_FANYIN[$_xp]=0
    QM_GATE_FANYIN[$_xp]=0; QM_STAR_FUYIN[$_xp]=0
    QM_GATE_FUYIN[$_xp]=0; QM_GAN_FANYIN[$_xp]=0
    QM_GAN_FUYIN[$_xp]=0
  done

  qm_find_zhifu_zhishi "$_xs_ke"
  qm_rotate_heaven "$_xs_ke"
  qm_rotate_human
  qm_lay_deities
  qm_calc_twelve_states
  qm_calc_liuyi_jixing
  qm_calc_kongwang "$_xs_ke"
  qm_calc_yima "$_xs_ke"
  qm_calc_patterns

  _xs_total_liuhai=0

  for ((_si=0; _si<${#_XS_FIXED_STEMS[@]}; _si++)); do
    _stem="${_XS_FIXED_STEMS[$_si]}"
    _palace=$(_xs_find_stem_palace "$_stem")
    if (( _palace > 0 && _palace != 5 )); then
      _xs_count_liuhai "$_palace"
      _xs_total_liuhai=$((_xs_total_liuhai + _XS_LIUHAI_COUNT))
    fi
  done

  if (( QM_ZHIFU_TARGET_PALACE > 0 && QM_ZHIFU_TARGET_PALACE != 5 )); then
    _zf_stem="${QM_HEAVEN_STEM[$QM_ZHIFU_TARGET_PALACE]}"
    if [[ -n "$_zf_stem" ]]; then
      _zf_palace=$(_xs_find_stem_palace "$_zf_stem")
      if (( _zf_palace > 0 && _zf_palace != 5 )); then
        _xs_count_liuhai "$_zf_palace"
        _xs_total_liuhai=$((_xs_total_liuhai + _XS_LIUHAI_COUNT))
      fi
    fi
  fi

  _zs_palace=0
  _zs_gate_idx="$QM_ZHISHI_GATE_INDEX"
  for ((_zsp=1; _zsp<=9; _zsp++)); do
    if (( _zsp != 5 && QM_HUMAN[_zsp] == _zs_gate_idx )); then
      _zs_palace=$_zsp
      break
    fi
  done
  if (( _zs_palace > 0 && _zs_palace != 5 )); then
    _zs_stem="${QM_HEAVEN_STEM[$_zs_palace]}"
    if [[ -n "$_zs_stem" ]]; then
      _zs_stem_palace=$(_xs_find_stem_palace "$_zs_stem")
      if (( _zs_stem_palace > 0 && _zs_stem_palace != 5 )); then
        _xs_count_liuhai "$_zs_stem_palace"
        _xs_total_liuhai=$((_xs_total_liuhai + _XS_LIUHAI_COUNT))
      fi
    fi
  fi

  _ke_num=$((_xs_ke + 1))
  _gz_name=$(cal_ganzhi_name "$_xs_ke")
  _XS_KE_GZ[$_xs_ke]="$_gz_name"
  _XS_KE_LIUHAI[$_xs_ke]="$_xs_total_liuhai"

  if (( _xs_total_liuhai < _XS_BEST_LIUHAI )); then
    _XS_BEST_LIUHAI=$_xs_total_liuhai
    _XS_BEST_KES=("$_ke_num")
  elif (( _xs_total_liuhai == _XS_BEST_LIUHAI )); then
    _XS_BEST_KES+=("$_ke_num")
  fi

  printf -v _liuhai_str "%02d" "$_xs_total_liuhai"
  printf -v _ke_str "%02d" "$_ke_num"
  qm_write_json_file "${OUTPUT_DIR}/qmen-xsjy-${_liuhai_str}-${_ke_str}.json"

done

# --- Print summary table ---
echo "课序  时柱    六害总数"
for ((_xs_ke=0; _xs_ke<60; _xs_ke++)); do
  _ke_num=$((_xs_ke + 1))
  printf -v _ke_disp "%02d" "$_ke_num"
  printf -v _lh_disp "%02d" "${_XS_KE_LIUHAI[$_xs_ke]}"
  _marker=""
  if (( ${_XS_KE_LIUHAI[$_xs_ke]} == _XS_BEST_LIUHAI )); then
    _marker="  ← 最优"
  fi
  echo "${_ke_disp}    ${_XS_KE_GZ[$_xs_ke]}    ${_lh_disp}${_marker}"
done

echo ""
if (( ${#_XS_BEST_KES[@]} == 1 )); then
  _best_idx=$((_XS_BEST_KES[0] - 1))
  echo "最优课: 第${_XS_BEST_KES[0]}课 (${_XS_KE_GZ[$_best_idx]}) 六害总数=${_XS_BEST_LIUHAI}"
else
  echo "最优六害总数: ${_XS_BEST_LIUHAI} (${#_XS_BEST_KES[@]}课并列)"
  echo "并列课:"
  for _bk in "${_XS_BEST_KES[@]}"; do
    _bi=$((_bk - 1))
    echo "  第${_bk}课 (${_XS_KE_GZ[$_bi]})"
  done
  echo ""
  echo "请选择其中一课。"
fi
echo "输出目录: $OUTPUT_DIR/"
