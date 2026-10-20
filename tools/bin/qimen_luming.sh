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
REFERENCE="year"
OUTPUT_JSON="./qmen_luming.json"

show_help() {
  cat <<'HELP'
用法: qimen_luming.sh [选项]

六亲禄命分析 — 年干定本命宫,逐宫分配六亲

选项:
  --reference=year|day    以年干或日干为本命参考(默认:year)
  --input=PATH            输入盘面JSON(默认:./qmen_birth.json)
  --output=PATH           输出JSON路径(默认:./qmen_luming.json)
  -h, --help              显示帮助
HELP
}

while (( $# > 0 )); do
  case "$1" in
    --reference=*) REFERENCE="${1#--reference=}"; shift ;;
    --input=*)     BIRTH_JSON_PATH="${1#--input=}"; shift ;;
    --output=*)    OUTPUT_JSON="${1#--output=}"; shift ;;
    -h|--help)     show_help; exit 0 ;;
    *)             echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ ! -f "$BIRTH_JSON_PATH" ]]; then
  echo "Error: plate not found: $BIRTH_JSON_PATH" >&2
  exit 1
fi

source "$BASE_DIR/lib/data_loader.sh"

source "$BASE_DIR/lib/qimen_json.sh"
qj_parse_plate_json "$BIRTH_JSON_PATH"

dl_load_file "$BASE_DIR/data/meta_palace.dat"
dl_load_file "$BASE_DIR/data/meta_huaqizhen.dat"
dl_load_file "$BASE_DIR/data/rules_luming.dat"

# --- Wuxing helpers ---
_lm_gan_wuxing() {
  case "$1" in
    甲|乙) echo "木" ;; 丙|丁) echo "火" ;; 戊|己) echo "土" ;;
    庚|辛) echo "金" ;; 壬|癸) echo "水" ;; *) echo "" ;;
  esac
}

# 八神全名→短名 (匹配 rules_luming.dat 中的 神X_X 键)
_lm_deity_short() {
  case "$1" in
    值符) echo "符" ;;
    螣蛇) echo "蛇" ;;
    太阴) echo "阴" ;;
    六合) echo "合" ;;
    白虎) echo "虎" ;;
    勾陈) echo "勾" ;;
    玄武) echo "玄" ;;
    朱雀) echo "雀" ;;
    九地) echo "地" ;;
    九天) echo "天" ;;
    *)    echo "$1" ;;
  esac
}

_lm_liuqin() {
  local my_wx="$1" other_wx="$2"
  if [[ "$my_wx" == "$other_wx" ]]; then echo "兄弟"; return; fi
  case "${my_wx}_${other_wx}" in
    木_火|火_土|土_金|金_水|水_木) echo "子孙" ;;
    火_木|土_火|金_土|水_金|木_水) echo "父母" ;;
    木_土|火_金|土_水|金_木|水_火) echo "妻财" ;;
    土_木|金_火|水_土|木_金|火_水) echo "官禄" ;;
    *) echo "" ;;
  esac
}

# 断语键别名: rules_luming.dat 沿用古籍称谓「妻妾」, 脚本分类器为「妻财」, 查询时须映射
_lm_lq_key() {
  if [[ "$1" == "妻财" ]]; then echo "妻妾"; else echo "$1"; fi
}

# --- Extract reference stem ---
_lm_ref_stem=""
_lm_ref_gz=""
if [[ "$REFERENCE" == "year" ]]; then
  dl_get_v "plate_si_zhu_year" 2>/dev/null || true
  _lm_ref_gz="${_DL_RET:-}"
else
  dl_get_v "plate_si_zhu_day" 2>/dev/null || true
  _lm_ref_gz="${_DL_RET:-}"
fi

# Extract stem via prefix match (locale-safe)
for _g in 甲 乙 丙 丁 戊 己 庚 辛 壬 癸; do
  if [[ "$_lm_ref_gz" == "${_g}"* ]]; then
    _lm_ref_stem="$_g"
    break
  fi
done

# 六甲遁干: 甲依其旬首所遁之仪代之
# 甲子→戊, 甲戌→己, 甲申→庚, 甲午→辛, 甲辰→壬, 甲寅→癸
if [[ "$_lm_ref_stem" == "甲" ]]; then
  case "$_lm_ref_gz" in
    甲子*) _lm_ref_stem="戊" ;;
    甲戌*) _lm_ref_stem="己" ;;
    甲申*) _lm_ref_stem="庚" ;;
    甲午*) _lm_ref_stem="辛" ;;
    甲辰*) _lm_ref_stem="壬" ;;
    甲寅*) _lm_ref_stem="癸" ;;
    *)     _lm_ref_stem="戊" ;;
  esac
fi

if [[ -z "$_lm_ref_stem" ]]; then
  echo "Error: cannot extract reference stem from '$_lm_ref_gz'" >&2
  exit 1
fi

_lm_ref_wx=$(_lm_gan_wuxing "$_lm_ref_stem")

# --- Find benming palace (本命宫) ---
_lm_benming_palace=0
for p in 1 2 3 4 6 7 8 9; do
  dl_get_v "palace_${p}_tian_gan" 2>/dev/null || true
  if [[ "$_DL_RET" == "$_lm_ref_stem" ]]; then
    _lm_benming_palace=$p
    break
  fi
done
if (( _lm_benming_palace == 0 )); then
  for p in 1 2 3 4 6 7 8 9; do
    dl_get_v "palace_${p}_di_gan" 2>/dev/null || true
    if [[ "$_DL_RET" == "$_lm_ref_stem" ]]; then
      _lm_benming_palace=$p
      break
    fi
  done
fi

# --- Compute liuqin for each palace ---
_LM_PNAMES=(坎1宫 坤2宫 震3宫 巽4宫 中5宫 乾6宫 兑7宫 艮8宫 离9宫)
_lm_results=()
for p in 1 2 3 4 6 7 8 9; do
  dl_get_v "palace_${p}_tian_gan" 2>/dev/null || true; tg="${_DL_RET:-}"
  dl_get_v "palace_${p}_di_gan" 2>/dev/null || true; dg="${_DL_RET:-}"
  dl_get_v "palace_${p}_star" 2>/dev/null || true; star="${_DL_RET:-}"
  dl_get_v "palace_${p}_gate" 2>/dev/null || true; gate="${_DL_RET:-}"
  dl_get_v "palace_${p}_deity" 2>/dev/null || true; deity="${_DL_RET:-}"
  dl_get_v "palace_${p}_state" 2>/dev/null || true; state="${_DL_RET:-}"
  dl_get_v "palace_${p}_pozhi" 2>/dev/null || true; pozhi="${_DL_RET:-false}"

  tg_wx=$(_lm_gan_wuxing "$tg")
  liuqin=$(_lm_liuqin "$_lm_ref_wx" "$tg_wx")
  pname="${_LM_PNAMES[$((p - 1))]}"

  _lm_results+=("${p}|${pname}|${liuqin}|${tg}|${dg}|${star}|${gate}|${deity}|${state}|${pozhi}")
  if [[ "$liuqin" == "官禄" ]]; then
    _lm_results+=("${p}|${pname}|疾厄|${tg}|${dg}|${star}|${gate}|${deity}|${state}|${pozhi}")
  fi
done

# --- Text output ---
printf '六亲禄命分析\n'
printf '参考: %s干 [%s] 五行:%s\n' "$REFERENCE" "$_lm_ref_stem" "$_lm_ref_wx"
printf '本命宫: %d宫\n' "$_lm_benming_palace"

# 本命宫八神断语 (神性情 + 神论命)
_lm_bm_deity=""
if (( _lm_benming_palace > 0 )); then
  dl_get_v "palace_${_lm_benming_palace}_deity" 2>/dev/null || true
  _lm_bm_deity="${_DL_RET:-}"
fi
if [[ -n "$_lm_bm_deity" ]]; then
  _lm_short_deity=$(_lm_deity_short "$_lm_bm_deity")
  _lm_dn_xq=$(dl_get "神性情_${_lm_short_deity}" 2>/dev/null) || true
  _lm_dn_lm=$(dl_get "神论命_${_lm_short_deity}" 2>/dev/null) || true
  [[ -n "$_lm_dn_xq" ]] && printf '本命八神性情: %s\n' "$_lm_dn_xq"
  [[ -n "$_lm_dn_lm" ]] && printf '本命八神论命: %s\n' "$_lm_dn_lm"
fi
printf '\n'

# Group by liuqin
for lq in 父母 兄弟 子孙 官禄 妻财 疾厄; do
  printf '[%s]\n' "$lq"
  found=0
  for entry in "${_lm_results[@]}"; do
    IFS='|' read -r ep epname elq etg edg estar egate edeity estate epozhi <<< "$entry"
    if [[ "$elq" == "$lq" ]]; then
      found=1
      bm_mark=""
      if (( ep == _lm_benming_palace )); then bm_mark=" [本命]"; fi
      printf '  %s: 天%s地%s %s %s %s %s%s\n' \
        "$epname" "$etg" "$edg" "$estar" "$egate" "$edeity" "$estate" "$bm_mark"
      short_gate="${egate:0:1}"
      verdict_key="门_${short_gate}_$(_lm_lq_key "$lq")"
      verdict=""
      verdict=$(dl_get "$verdict_key" 2>/dev/null) || true
      if [[ -n "$verdict" ]]; then
        printf '    门断: %s\n' "$verdict"
      fi
      short_deity=$(_lm_deity_short "$edeity")
      deity_pref=$(dl_get "神喜忌_${short_deity}_$(_lm_lq_key "$lq")" 2>/dev/null) || true
      if [[ -z "$deity_pref" && "$ep" == "$_lm_benming_palace" ]]; then
        deity_pref=$(dl_get "神喜忌_${short_deity}_本命" 2>/dev/null) || true
      fi
      if [[ -z "$deity_pref" ]]; then
        deity_pref=$(dl_get "神喜忌_${short_deity}_默认" 2>/dev/null) || true
      fi
      if [[ -n "$deity_pref" ]]; then
        printf '    神断: %s\n' "$deity_pref"
      fi
    fi
  done
  if (( found == 0 )); then
    printf '  (无)\n'
  fi
  printf '\n'
done

# --- JSON output ---
{
  printf '{\n'
  printf '  "reference": "%s",\n' "$REFERENCE"
  printf '  "ref_stem": "%s",\n' "$_lm_ref_stem"
  printf '  "ref_wuxing": "%s",\n' "$_lm_ref_wx"
  printf '  "benming_palace": %d,\n' "$_lm_benming_palace"
  printf '  "benming_deity": "%s",\n' "${_lm_bm_deity:-}"
  printf '  "benming_deity_personality": "%s",\n' "${_lm_dn_xq:-}"
  printf '  "benming_deity_destiny": "%s",\n' "${_lm_dn_lm:-}"
  printf '  "palaces": [\n'
  first=1
  for entry in "${_lm_results[@]}"; do
    IFS='|' read -r ep epname elq etg edg estar egate edeity estate epozhi <<< "$entry"
    if (( first == 0 )); then printf ',\n'; fi
    first=0
    is_bm="false"
    if (( ep == _lm_benming_palace )); then is_bm="true"; fi
    j_short_gate="${egate:0:1}"
    j_gate_verdict=$(dl_get "门_${j_short_gate}_$(_lm_lq_key "$elq")" 2>/dev/null) || true
    j_short_deity=$(_lm_deity_short "$edeity")
    j_deity_pref=$(dl_get "神喜忌_${j_short_deity}_$(_lm_lq_key "$elq")" 2>/dev/null) || true
    if [[ -z "$j_deity_pref" && "$ep" == "$_lm_benming_palace" ]]; then
      j_deity_pref=$(dl_get "神喜忌_${j_short_deity}_本命" 2>/dev/null) || true
    fi
    if [[ -z "$j_deity_pref" ]]; then
      j_deity_pref=$(dl_get "神喜忌_${j_short_deity}_默认" 2>/dev/null) || true
    fi
    printf '    {"palace": %d, "name": "%s", "liuqin": "%s", "tian_gan": "%s", "di_gan": "%s", "star": "%s", "gate": "%s", "deity": "%s", "state": "%s", "pozhi": %s, "benming": %s, "gate_verdict": "%s", "deity_verdict": "%s"}' \
      "$ep" "$epname" "$elq" "$etg" "$edg" "$estar" "$egate" "$edeity" "$estate" "$epozhi" "$is_bm" "${j_gate_verdict:-}" "${j_deity_pref:-}"
  done
  printf '\n  ]\n'
  printf '}\n'
} > "$OUTPUT_JSON"

echo "禄命分析已写入: $OUTPUT_JSON" >&2
