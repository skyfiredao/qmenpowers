#!/usr/bin/env bash
# Copyright (C) 2026 — Licensed under GPL-3.0
# See https://www.gnu.org/licenses/gpl-3.0.html
# 真太阳时计算工具
# 公式: 真太阳时 = 当地平太阳时 + 均时差
#       当地平太阳时 = 标准时间 + (当地经度 - 标准子午线) × 4分钟/度
#       标准子午线 = 时区 × 15
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

# --- Defaults ---
LONGITUDE=""
TIMEZONE=8
DATETIME=""
SHICHEN=""
OUTPUT_JSON="./qmen_zhentaiyangshi.json"

show_help() {
  cat <<'HELP'
用法: qimen_zhentaiyangshi.sh [选项] "YYYY-MM-DD HH:MM"
      qimen_zhentaiyangshi.sh --shichen=申时 [选项] "YYYY-MM-DD"

真太阳时计算工具 — 经度校正 + 均时差校正

模式:
  正向（默认）    输入钟表时间 → 输出真太阳时和时辰
  反向（--shichen） 输入时辰+日期 → 输出对应的钟表时间窗口

选项:
  --longitude=N         当地经度（东经为正，西经为负；时区自动推导）
  --timezone=N          时区偏移（经度默认为该时区标准子午线）
                        以上二选一，不传则默认东八区（经度120°）
  --shichen=X           反向查询：输入时辰，输出钟表时间窗口
                        支持：子/丑/寅/卯/辰/巳/午/未/申/酉/戌/亥（带不带"时"均可）
  --output=PATH         输出 JSON 路径（默认: ./qmen_zhentaiyangshi.json）
  -h, --help            显示帮助

示例:
  # 正向：北京时间 → 真太阳时
  qimen_zhentaiyangshi.sh --longitude=116.4 "2026-04-30 14:30"

  # 反向：申时在乌鲁木齐（经度定位）对应几点？
  qimen_zhentaiyangshi.sh --shichen=申时 --longitude=87.6 "2026-04-30"

  # 反向：子时在纽约（时区定位）对应几点？
  qimen_zhentaiyangshi.sh --shichen=子 --timezone=-5 "2026-04-30"
HELP
}

_parse_10x() {
  local val="$1"
  local sign=1
  if [[ "$val" == -* ]]; then
    sign=-1
    val="${val#-}"
  fi
  local int_part="${val%%.*}"
  local frac_part="0"
  if [[ "$val" == *.* ]]; then
    frac_part="${val#*.}"
    frac_part="${frac_part:0:1}"
    [[ -z "$frac_part" ]] && frac_part=0
  fi
  int_part=$((10#${int_part:-0}))
  frac_part=$((10#$frac_part))
  echo $(( sign * (int_part * 10 + frac_part) ))
}

# --- Argument parsing ---
_LNG_SET=""
_TZ_SET=""
while (( $# > 0 )); do
  case "$1" in
    --longitude=*) LONGITUDE="${1#*=}"; _LNG_SET=1 ;;
    --timezone=*)  TIMEZONE="${1#*=}"; _TZ_SET=1 ;;
    --shichen=*)   SHICHEN="${1#*=}" ;;
    --output=*)    OUTPUT_JSON="${1#*=}" ;;
    -h|--help)     show_help; exit 0 ;;
    -*)            echo "错误: 未知选项 $1" >&2; exit 1 ;;
    *)             DATETIME="$1" ;;
  esac
  shift
done

if [[ -n "$_LNG_SET" && -n "$_TZ_SET" ]]; then
  echo "错误: --longitude 和 --timezone 互斥，只能指定其中一个" >&2
  echo "      --longitude=N  → 时区自动推导（经度÷15取整）" >&2
  echo "      --timezone=N   → 经度默认为该时区标准子午线（时区×15）" >&2
  exit 1
fi

if [[ -n "$_LNG_SET" ]]; then
  _lng_10x=$(_parse_10x "$LONGITUDE")
  if (( _lng_10x >= 0 )); then
    TIMEZONE=$(( (_lng_10x + 75) / 150 ))
  else
    TIMEZONE=$(( (_lng_10x - 75) / 150 ))
  fi
elif [[ -z "$_TZ_SET" ]]; then
  LONGITUDE=120
fi

if [[ -z "$LONGITUDE" ]]; then
  LONGITUDE=$(( TIMEZONE * 15 ))
fi

if [[ -z "$DATETIME" ]]; then
  echo "错误: 必须指定日期时间" >&2
  if [[ -n "$SHICHEN" ]]; then
    echo "反向模式格式: \"YYYY-MM-DD\"" >&2
  else
    echo "正向模式格式: \"YYYY-MM-DD HH:MM\"" >&2
  fi
  exit 1
fi

# --- Parse datetime ---
if [[ "$DATETIME" =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})$ ]]; then
  YEAR="${BASH_REMATCH[1]}"
  MONTH="${BASH_REMATCH[2]}"
  DAY="${BASH_REMATCH[3]}"
  HOUR=12; MINUTE=0
  _DATE_ONLY=1
elif [[ "$DATETIME" =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})[[:space:]]([0-9]{2}):([0-9]{2})$ ]]; then
  YEAR="${BASH_REMATCH[1]}"
  MONTH="${BASH_REMATCH[2]}"
  DAY="${BASH_REMATCH[3]}"
  HOUR="${BASH_REMATCH[4]}"
  MINUTE="${BASH_REMATCH[5]}"
  _DATE_ONLY=""
else
  echo "错误: 日期格式不正确，需要 \"YYYY-MM-DD\" 或 \"YYYY-MM-DD HH:MM\"" >&2
  exit 1
fi

if [[ -n "$SHICHEN" && -z "$_DATE_ONLY" ]]; then
  _DATE_ONLY=""
fi

YEAR=$((10#$YEAR))
MONTH=$((10#$MONTH))
DAY=$((10#$DAY))
HOUR=$((10#$HOUR))
MINUTE=$((10#$MINUTE))

# --- Leap year check ---
_is_leap() {
  local y=$1
  if (( y % 400 == 0 )); then return 0
  elif (( y % 100 == 0 )); then return 1
  elif (( y % 4 == 0 )); then return 0
  else return 1
  fi
}

# --- Day of year ---
_day_of_year() {
  local y=$1 m=$2 d=$3
  # Days in each month (non-leap)
  local months=(0 31 28 31 30 31 30 31 31 30 31 30 31)
  if _is_leap "$y"; then
    months[2]=29
  fi
  local doy=0
  local i
  for (( i=1; i<m; i++ )); do
    doy=$(( doy + months[i] ))
  done
  doy=$(( doy + d ))
  echo "$doy"
}

# --- Equation of Time lookup table ---
# 25 data points: (day_of_year, EoT_in_seconds)
# EoT values are approximate standard values for a non-leap year
# Sources: astronomical almanac standard approximation
#
# Positive = sun ahead of mean (true solar noon before clock noon)
# Negative = sun behind mean (true solar noon after clock noon)

# Day-of-year for each sample point
_EOT_DAYS=(1 15 32 46 60 74 91 105 121 135 152 166 182 196 213 227 244 258 274 288 305 319 335 349 365)

# EoT in seconds at each sample point
_EOT_SECS=(-204 -558 -816 -852 -750 -558 -246 0 168 222 138 0 -210 -354 -378 -270 -12 252 606 858 984 918 672 300 -162)

# Linear interpolation between two table entries
# All integer arithmetic, result in seconds
_eot_interpolate() {
  local doy=$1
  local n=${#_EOT_DAYS[@]}
  local i

  # Find bracketing interval
  for (( i=0; i<n-1; i++ )); do
    if (( doy <= _EOT_DAYS[i+1] )); then
      break
    fi
  done

  local d0=${_EOT_DAYS[$i]}
  local d1=${_EOT_DAYS[$((i+1))]}
  local v0=${_EOT_SECS[$i]}
  local v1=${_EOT_SECS[$((i+1))]}

  # Linear interpolation: v0 + (v1-v0) * (doy-d0) / (d1-d0)
  local span=$(( d1 - d0 ))
  local offset=$(( doy - d0 ))
  local diff=$(( v1 - v0 ))

  # Integer division with rounding
  local result=$(( v0 + (diff * offset + span/2) / span ))
  echo "$result"
}

# --- Longitude correction ---
# Each degree of longitude difference = 4 minutes = 240 seconds
# Correction = (local_longitude - standard_meridian) * 240 seconds
# Standard meridian = timezone * 15 degrees
#
# We use 10x precision for longitude (one decimal place)
_longitude_correction_secs() {
  local lng_10x=$1  # longitude * 10
  local tz=$2       # timezone integer
  local std_meridian_10x=$(( tz * 150 ))  # (tz * 15) * 10
  local diff_10x=$(( lng_10x - std_meridian_10x ))
  # correction_secs = diff_degrees * 240 = (diff_10x / 10) * 240 = diff_10x * 24
  echo $(( diff_10x * 24 ))
}

# --- Time to minutes-of-day ---
_time_to_minutes() {
  echo $(( $1 * 60 + $2 ))
}

# --- Minutes-of-day to HH:MM (handles overflow/underflow across midnight) ---
_minutes_to_time() {
  local total=$1
  # Normalize to 0-1439 range
  while (( total < 0 )); do
    total=$(( total + 1440 ))
  done
  while (( total >= 1440 )); do
    total=$(( total - 1440 ))
  done
  printf "%02d:%02d" $(( total / 60 )) $(( total % 60 ))
}

# --- Determine shichen (时辰) from HH:MM ---
# 子时 23:00-01:00, 丑时 01:00-03:00, ... 亥时 21:00-23:00
_get_shichen() {
  local total_min=$1
  # Normalize
  while (( total_min < 0 )); do total_min=$(( total_min + 1440 )); done
  while (( total_min >= 1440 )); do total_min=$(( total_min - 1440 )); done

  local h=$(( total_min / 60 ))
  local m=$(( total_min % 60 ))

  # Shichen boundaries (starting from 子时 at 23:00)
  # 23:00-01:00 子  01:00-03:00 丑  03:00-05:00 寅
  # 05:00-07:00 卯  07:00-09:00 辰  09:00-11:00 巳
  # 11:00-13:00 午  13:00-15:00 未  15:00-17:00 申
  # 17:00-19:00 酉  19:00-21:00 戌  21:00-23:00 亥

  if (( h == 23 || h == 0 )); then echo "子时"
  elif (( h >= 1 && h < 3 )); then echo "丑时"
  elif (( h >= 3 && h < 5 )); then echo "寅时"
  elif (( h >= 5 && h < 7 )); then echo "卯时"
  elif (( h >= 7 && h < 9 )); then echo "辰时"
  elif (( h >= 9 && h < 11 )); then echo "巳时"
  elif (( h >= 11 && h < 13 )); then echo "午时"
  elif (( h >= 13 && h < 15 )); then echo "未时"
  elif (( h >= 15 && h < 17 )); then echo "申时"
  elif (( h >= 17 && h < 19 )); then echo "酉时"
  elif (( h >= 19 && h < 21 )); then echo "戌时"
  else echo "亥时"
  fi
}

# --- Get shichen for the input standard time ---
_get_input_shichen() {
  local total_min=$1
  _get_shichen "$total_min"
}

# --- Main computation ---

# 1. Parse longitude to 10x integer
LNG_10X=$(_parse_10x "$LONGITUDE")

# 2. Day of year
DOY=$(_day_of_year "$YEAR" "$MONTH" "$DAY")

# 3. Equation of Time (seconds)
EOT_SECS=$(_eot_interpolate "$DOY")

# 4. Longitude correction (seconds)
# _longitude_correction_secs returns (lng_10x - tz*150) * 24 = degree_diff * 240 = seconds
LNG_CORR_SECS=$(_longitude_correction_secs "$LNG_10X" "$TIMEZONE")

# 5. Total correction in seconds
TOTAL_CORR_SECS=$(( LNG_CORR_SECS + EOT_SECS ))

# 6. Convert to minutes (rounded)
if (( TOTAL_CORR_SECS >= 0 )); then
  TOTAL_CORR_MIN=$(( (TOTAL_CORR_SECS + 30) / 60 ))
else
  TOTAL_CORR_MIN=$(( (TOTAL_CORR_SECS - 30) / 60 ))
fi

# --- Format signed minutes+seconds display ---
_fmt_minsec() {
  local secs=$1 abs_secs sign_char min sec
  if (( secs < 0 )); then abs_secs=$(( -secs )); sign_char="-"
  else abs_secs=$secs; sign_char="+"; fi
  min=$(( abs_secs / 60 ))
  sec=$(( abs_secs % 60 ))
  echo "${sign_char}${min}分${sec}秒"
}

# --- Shichen true solar time boundaries (start minute of day) ---
_shichen_range() {
  local sc="$1"
  sc="${sc%时}"
  case "$sc" in
    子) echo "1380 60" ;;
    丑) echo "60 180" ;;
    寅) echo "180 300" ;;
    卯) echo "300 420" ;;
    辰) echo "420 540" ;;
    巳) echo "540 660" ;;
    午) echo "660 780" ;;
    未) echo "780 900" ;;
    申) echo "900 1020" ;;
    酉) echo "1020 1140" ;;
    戌) echo "1140 1260" ;;
    亥) echo "1260 1380" ;;
    *) echo "" ;;
  esac
}

# ============================================================
# Branch: reverse mode (--shichen) vs forward mode
# ============================================================

if [[ -n "$SHICHEN" ]]; then
  # --- Reverse mode: shichen → clock time window ---
  _range=$(_shichen_range "$SHICHEN")
  if [[ -z "$_range" ]]; then
    echo "错误: 无法识别时辰 \"${SHICHEN}\"" >&2
    echo "支持: 子/丑/寅/卯/辰/巳/午/未/申/酉/戌/亥" >&2
    exit 1
  fi
  _sc_start=${_range% *}
  _sc_end=${_range#* }
  _sc_name="${SHICHEN%时}时"

  # clock_time = true_solar_time - correction
  _clock_start=$(( _sc_start - TOTAL_CORR_MIN ))
  _clock_end=$(( _sc_end - TOTAL_CORR_MIN ))

  _clock_start_str=$(_minutes_to_time "$_clock_start")
  _clock_end_str=$(_minutes_to_time "$_clock_end")

  # 子时跨midnight: use 23:00-01:00 as single range
  if [[ "$_sc_name" == "子时" ]]; then
    _clock_start=$(( 1380 - TOTAL_CORR_MIN ))
    _clock_end=$(( 1500 - TOTAL_CORR_MIN ))
    _clock_start_str=$(_minutes_to_time "$_clock_start")
    _clock_end_str=$(_minutes_to_time "$_clock_end")
  fi
  _RANGE_DISPLAY="${_clock_start_str} - ${_clock_end_str}"

  echo "真太阳时反向查询"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "查询时辰: ${_sc_name}（真太阳时 $(_minutes_to_time "$_sc_start") - $(_minutes_to_time "$_sc_end")）"
  echo "查询日期: $(printf "%04d-%02d-%02d" "$YEAR" "$MONTH" "$DAY")"
  echo "当地经度: ${LONGITUDE}°"
  echo "时区偏移: UTC$(printf "%+d" "$TIMEZONE")"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "经度校正: $(_fmt_minsec "$LNG_CORR_SECS")"
  echo "均时差  : $(_fmt_minsec "$EOT_SECS")"
  echo "总校正  : $(_fmt_minsec "$TOTAL_CORR_SECS")"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "钟表时间: ${_RANGE_DISPLAY}"

  # --- JSON ---
  cat > "$OUTPUT_JSON" <<EOF
{
  "mode": "reverse",
  "input": {
    "shichen": "${_sc_name}",
    "date": "$(printf "%04d-%02d-%02d" "$YEAR" "$MONTH" "$DAY")",
    "longitude": ${LONGITUDE},
    "timezone": ${TIMEZONE}
  },
  "correction": {
    "longitude_seconds": ${LNG_CORR_SECS},
    "eot_seconds": ${EOT_SECS},
    "total_seconds": ${TOTAL_CORR_SECS},
    "total_minutes": ${TOTAL_CORR_MIN}
  },
  "result": {
    "clock_start": "${_clock_start_str}",
    "clock_end": "${_clock_end_str}",
    "shichen": "${_sc_name}"
  }
}
EOF

else
  # --- Forward mode: clock time → true solar time ---
  INPUT_MIN=$(_time_to_minutes "$HOUR" "$MINUTE")
  TRUE_SOLAR_MIN=$(( INPUT_MIN + TOTAL_CORR_MIN ))

  TRUE_SOLAR_TIME=$(_minutes_to_time "$TRUE_SOLAR_MIN")
  INPUT_SHICHEN=$(_get_shichen "$INPUT_MIN")
  TRUE_SHICHEN=$(_get_shichen "$TRUE_SOLAR_MIN")

  if (( TOTAL_CORR_MIN >= 0 )); then
    DIFF_DISPLAY="+${TOTAL_CORR_MIN}分钟"
  else
    DIFF_DISPLAY="${TOTAL_CORR_MIN}分钟"
  fi

  SHICHEN_CHANGED=""
  if [[ "$INPUT_SHICHEN" != "$TRUE_SHICHEN" ]]; then
    SHICHEN_CHANGED="⚠ 时辰变化: ${INPUT_SHICHEN} → ${TRUE_SHICHEN}"
  fi

  echo "真太阳时计算"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "标准时间: $(printf "%04d-%02d-%02d %02d:%02d" "$YEAR" "$MONTH" "$DAY" "$HOUR" "$MINUTE")（${INPUT_SHICHEN}）"
  echo "当地经度: ${LONGITUDE}°"
  echo "时区偏移: UTC$(printf "%+d" "$TIMEZONE")"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "经度校正: $(_fmt_minsec "$LNG_CORR_SECS")"
  echo "均时差  : $(_fmt_minsec "$EOT_SECS")"
  echo "总校正  : ${DIFF_DISPLAY}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "真太阳时: ${TRUE_SOLAR_TIME}（${TRUE_SHICHEN}）"
  if [[ -n "$SHICHEN_CHANGED" ]]; then
    echo ""
    echo "$SHICHEN_CHANGED"
  fi

  # --- JSON ---
  cat > "$OUTPUT_JSON" <<EOF
{
  "mode": "forward",
  "input": {
    "datetime": "$(printf "%04d-%02d-%02d %02d:%02d" "$YEAR" "$MONTH" "$DAY" "$HOUR" "$MINUTE")",
    "longitude": ${LONGITUDE},
    "timezone": ${TIMEZONE}
  },
  "correction": {
    "longitude_seconds": ${LNG_CORR_SECS},
    "eot_seconds": ${EOT_SECS},
    "total_seconds": ${TOTAL_CORR_SECS},
    "total_minutes": ${TOTAL_CORR_MIN}
  },
  "result": {
    "true_solar_time": "${TRUE_SOLAR_TIME}",
    "shichen": "${TRUE_SHICHEN}",
    "input_shichen": "${INPUT_SHICHEN}",
    "shichen_changed": $([ "$INPUT_SHICHEN" != "$TRUE_SHICHEN" ] && echo "true" || echo "false")
  }
}
EOF
fi
