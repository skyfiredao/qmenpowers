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

INPUT_PATH=""
OUTPUT_PATH="./qmen_wanwu.json"
PALACE_NUM=""
OPT_STEM=""
OPT_STAR=""
OPT_GATE=""
OPT_DEITY=""
OPT_STATE=""

show_help() {
  cat <<'HELP'
用法: qimen_wanwu.sh [选项]

万物类象提取工具 — 提取指定宫位或符号组合的全部万物类象

两种模式（互斥）:
  盘面模式: --palace=N        从盘面JSON提取第N宫全部符号的万物类象
  手工模式: --stem/--star/... 直接指定符号，至少一个

盘面模式选项:
  --input=PATH            输入盘面 JSON（默认: ./qmen_birth.json）
  --palace=N              宫位号（1-9）

手工模式选项:
  --stem=X                天干（如: 丙）
  --star=X                九星（如: 天冲）
  --gate=X                八门（如: 伤门）
  --deity=X               八神（如: 九天）
  --state=X               十二长生（如: 帝旺）

通用选项:
  --output=PATH           输出 JSON（默认: ./qmen_wanwu.json）
  -h, --help              显示帮助
HELP
}

while (( $# > 0 )); do
  case "$1" in
    --input=*)    INPUT_PATH="${1#--input=}"; shift ;;
    --output=*)   OUTPUT_PATH="${1#--output=}"; shift ;;
    --palace=*)   PALACE_NUM="${1#--palace=}"; shift ;;
    --stem=*)     OPT_STEM="${1#--stem=}"; shift ;;
    --star=*)     OPT_STAR="${1#--star=}"; shift ;;
    --gate=*)     OPT_GATE="${1#--gate=}"; shift ;;
    --deity=*)    OPT_DEITY="${1#--deity=}"; shift ;;
    --state=*)    OPT_STATE="${1#--state=}"; shift ;;
    -h|--help)    show_help; exit 0 ;;
    *)            echo "未知选项: $1" >&2; exit 1 ;;
  esac
done

# Mode detection
MANUAL_MODE=0
if [[ -n "$OPT_STEM" || -n "$OPT_STAR" || -n "$OPT_GATE" || -n "$OPT_DEITY" || -n "$OPT_STATE" ]]; then
  MANUAL_MODE=1
fi

if [[ "$MANUAL_MODE" -eq 1 && -n "$PALACE_NUM" ]]; then
  echo "错误: --palace 和手工模式（--stem/--star/--gate/--deity/--state）不能同时使用" >&2
  exit 1
fi

if [[ "$MANUAL_MODE" -eq 0 && -z "$PALACE_NUM" ]]; then
  echo "错误: 请指定 --palace=N 或至少一个手工符号（--stem/--star/--gate/--deity/--state）" >&2
  exit 1
fi

source "$BASE_DIR/lib/data_loader.sh"

# Load wanwu data files
dl_load_file "$BASE_DIR/data/wanwu_prefix_map.dat"
dl_load_file "$BASE_DIR/data/wanwu_tiangan.dat"
dl_load_file "$BASE_DIR/data/wanwu_nine_stars.dat"
dl_load_file "$BASE_DIR/data/wanwu_eight_gates.dat"
dl_load_file "$BASE_DIR/data/wanwu_eight_deities.dat"

# --- Palace mode: extract symbols from plate JSON ---
if [[ "$MANUAL_MODE" -eq 0 ]]; then
  [[ -z "$INPUT_PATH" ]] && INPUT_PATH="./qmen_birth.json"
  if [[ ! -f "$INPUT_PATH" ]]; then
    echo "错误: 盘面文件不存在: $INPUT_PATH" >&2
    echo "先生成盘面: qimen.sh --type=birth \"YYYY-MM-DD HH:MM\"" >&2
    exit 1
  fi

  source "$BASE_DIR/lib/qimen_json.sh"
  qj_parse_plate_json "$INPUT_PATH"

  dl_get_v "palace_${PALACE_NUM}_tian_gan" 2>/dev/null || true; OPT_STEM="$_DL_RET"
  dl_get_v "palace_${PALACE_NUM}_star" 2>/dev/null || true; OPT_STAR="$_DL_RET"
  dl_get_v "palace_${PALACE_NUM}_gate" 2>/dev/null || true; OPT_GATE="$_DL_RET"
  dl_get_v "palace_${PALACE_NUM}_deity" 2>/dev/null || true; OPT_DEITY="$_DL_RET"
  dl_get_v "palace_${PALACE_NUM}_state" 2>/dev/null || true; OPT_STATE="$_DL_RET"

  # Also get di_gan for reference
  local_di_gan=""
  dl_get_v "palace_${PALACE_NUM}_di_gan" 2>/dev/null || true; local_di_gan="$_DL_RET"
fi

# --- Lookup function: get all fields for a symbol ---
# Usage: _ww_lookup TYPE SYMBOL
# TYPE: GAN / STAR / GATE / DEITY
# Outputs key=value pairs to stdout, stores in dl as ww_TYPE_FIELD
_ww_lookup() {
  local map_type="$1" symbol="$2"
  local map_key prefix k v i field

  [[ -n "$symbol" ]] || return 0

  map_key="${map_type}_${symbol}"
  dl_get_v "$map_key" 2>/dev/null || true; prefix="$_DL_RET"
  [[ -n "$prefix" ]] || return 0

  local type_lower
  case "$map_type" in
    GAN)   type_lower="stem" ;;
    STAR)  type_lower="star" ;;
    GATE)  type_lower="gate" ;;
    DEITY) type_lower="deity" ;;
    *)     type_lower="unknown" ;;
  esac

  for ((i=0; i<${#_DL_KEYS[@]}; i++)); do
    k="${_DL_KEYS[$i]}"
    if [[ "$k" == "${prefix}_"* ]]; then
      field="${k#${prefix}_}"
      v="${_DL_VALS[$i]}"
      dl_set "ww_${type_lower}_${field}" "$v"
    fi
  done
}

# --- Text output ---
_ww_print_section() {
  local label="$1" symbol="$2" type_lower="$3"
  local found=0

  [[ -n "$symbol" ]] || return 0

  local i k v field
  for ((i=0; i<${#_DL_KEYS[@]}; i++)); do
    k="${_DL_KEYS[$i]}"
    if [[ "$k" == "ww_${type_lower}_"* ]]; then
      if (( found == 0 )); then
        echo ""
        echo "[$label] $symbol"
        found=1
      fi
      field="${k#ww_${type_lower}_}"
      v="${_DL_VALS[$i]}"
      echo "  ${field}: ${v}"
    fi
  done
}

# --- JSON output ---
_ww_json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  echo "$s"
}

_ww_emit_json_section() {
  local fd="$1" type_lower="$2" symbol="$3" is_first_ref="$4"
  local found=0 first_field=1

  [[ -n "$symbol" ]] || return 0

  local i k v field
  for ((i=0; i<${#_DL_KEYS[@]}; i++)); do
    k="${_DL_KEYS[$i]}"
    if [[ "$k" == "ww_${type_lower}_"* ]]; then
      if (( found == 0 )); then
        if [[ "${!is_first_ref}" == "1" ]]; then
          eval "$is_first_ref=0"
        else
          printf ',\n' >&"$fd"
        fi
        printf '    "%s": {\n' "$type_lower" >&"$fd"
        printf '      "symbol": "%s"' "$(_ww_json_escape "$symbol")" >&"$fd"
        found=1
      fi
      field="${k#ww_${type_lower}_}"
      v="$(_ww_json_escape "${_DL_VALS[$i]}")"
      printf ',\n      "%s": "%s"' "$field" "$v" >&"$fd"
    fi
  done

  if (( found == 1 )); then
    printf '\n    }' >&"$fd"
  fi
}

# --- Main ---
echo "万物类象提取"

if [[ "$MANUAL_MODE" -eq 0 ]]; then
  echo "盘面: $INPUT_PATH"
  echo "宫位: ${PALACE_NUM}宫"

  # Print palace info
  dl_get_v "palace_${PALACE_NUM}_name" 2>/dev/null || true
  [[ -n "$_DL_RET" ]] && echo "宫名: $_DL_RET"
fi

echo ""
echo "符号:"
[[ -n "$OPT_STEM" ]] && echo "  天干: $OPT_STEM"
[[ -n "$OPT_STAR" ]] && echo "  九星: $OPT_STAR"
[[ -n "$OPT_GATE" ]] && echo "  八门: $OPT_GATE"
[[ -n "$OPT_DEITY" ]] && echo "  八神: $OPT_DEITY"
[[ -n "$OPT_STATE" ]] && echo "  十二长生: $OPT_STATE"
if [[ "$MANUAL_MODE" -eq 0 && -n "$local_di_gan" ]]; then
  echo "  地盘干: $local_di_gan"
fi

# Perform lookups
_ww_lookup "GAN" "$OPT_STEM"
_ww_lookup "STAR" "$OPT_STAR"
_ww_lookup "GATE" "$OPT_GATE"
_ww_lookup "DEITY" "$OPT_DEITY"

# Print text sections
_ww_print_section "天干" "$OPT_STEM" "stem"
_ww_print_section "九星" "$OPT_STAR" "star"
_ww_print_section "八门" "$OPT_GATE" "gate"
_ww_print_section "八神" "$OPT_DEITY" "deity"

# State section (simple, no dat lookup — just display name)
if [[ -n "$OPT_STATE" ]]; then
  echo ""
  echo "[十二长生] $OPT_STATE"
  case "$OPT_STATE" in
    长生) echo "  含义: 初生,萌发,新生力量,充满希望" ;;
    沐浴) echo "  含义: 沐浴更衣,不稳定,桃花,轻浮,变动" ;;
    冠带) echo "  含义: 成长,装饰,初具规模,开始崭露头角" ;;
    临官) echo "  含义: 当官,有权,成熟,独当一面,事业上升" ;;
    帝旺) echo "  含义: 极盛,鼎盛,最强状态,物极必反" ;;
    衰)   echo "  含义: 开始衰退,力不从心,守成,保守" ;;
    病)   echo "  含义: 病弱,困顿,需要调养,虚弱无力" ;;
    死)   echo "  含义: 死寂,终结,僵化,毫无生气" ;;
    墓)   echo "  含义: 入墓,收藏,封闭,隐藏,积蓄" ;;
    绝)   echo "  含义: 断绝,消亡,最低谷,绝处逢生" ;;
    胎)   echo "  含义: 孕育,酝酿,尚未成形,潜在可能" ;;
    养)   echo "  含义: 养育,培养,等待时机,蓄势待发" ;;
  esac
fi

# --- Write JSON ---
exec 3>"$OUTPUT_PATH"
printf '{\n' >&3

if [[ "$MANUAL_MODE" -eq 0 ]]; then
  printf '  "mode": "palace",\n' >&3
  printf '  "palace": %s,\n' "$PALACE_NUM" >&3
  printf '  "input": "%s",\n' "$(_ww_json_escape "$INPUT_PATH")" >&3
else
  printf '  "mode": "manual",\n' >&3
fi

printf '  "symbols": {\n' >&3
local_sym_first=1
if [[ -n "$OPT_STEM" ]]; then
  [[ "$local_sym_first" -eq 1 ]] && local_sym_first=0 || printf ',\n' >&3
  printf '    "stem": "%s"' "$(_ww_json_escape "$OPT_STEM")" >&3
fi
if [[ -n "$OPT_STAR" ]]; then
  [[ "$local_sym_first" -eq 1 ]] && local_sym_first=0 || printf ',\n' >&3
  printf '    "star": "%s"' "$(_ww_json_escape "$OPT_STAR")" >&3
fi
if [[ -n "$OPT_GATE" ]]; then
  [[ "$local_sym_first" -eq 1 ]] && local_sym_first=0 || printf ',\n' >&3
  printf '    "gate": "%s"' "$(_ww_json_escape "$OPT_GATE")" >&3
fi
if [[ -n "$OPT_DEITY" ]]; then
  [[ "$local_sym_first" -eq 1 ]] && local_sym_first=0 || printf ',\n' >&3
  printf '    "deity": "%s"' "$(_ww_json_escape "$OPT_DEITY")" >&3
fi
if [[ -n "$OPT_STATE" ]]; then
  [[ "$local_sym_first" -eq 1 ]] && local_sym_first=0 || printf ',\n' >&3
  printf '    "state": "%s"' "$(_ww_json_escape "$OPT_STATE")" >&3
fi
if [[ "$MANUAL_MODE" -eq 0 && -n "$local_di_gan" ]]; then
  printf ',\n    "di_gan": "%s"' "$(_ww_json_escape "$local_di_gan")" >&3
fi
printf '\n  },\n' >&3

printf '  "wanwu": {\n' >&3
local_ww_first=1
_ww_emit_json_section 3 "stem" "$OPT_STEM" "local_ww_first"
_ww_emit_json_section 3 "star" "$OPT_STAR" "local_ww_first"
_ww_emit_json_section 3 "gate" "$OPT_GATE" "local_ww_first"
_ww_emit_json_section 3 "deity" "$OPT_DEITY" "local_ww_first"

# State in JSON
if [[ -n "$OPT_STATE" ]]; then
  state_meaning=""
  case "$OPT_STATE" in
    长生) state_meaning="初生,萌发,新生力量,充满希望" ;;
    沐浴) state_meaning="沐浴更衣,不稳定,桃花,轻浮,变动" ;;
    冠带) state_meaning="成长,装饰,初具规模,开始崭露头角" ;;
    临官) state_meaning="当官,有权,成熟,独当一面,事业上升" ;;
    帝旺) state_meaning="极盛,鼎盛,最强状态,物极必反" ;;
    衰)   state_meaning="开始衰退,力不从心,守成,保守" ;;
    病)   state_meaning="病弱,困顿,需要调养,虚弱无力" ;;
    死)   state_meaning="死寂,终结,僵化,毫无生气" ;;
    墓)   state_meaning="入墓,收藏,封闭,隐藏,积蓄" ;;
    绝)   state_meaning="断绝,消亡,最低谷,绝处逢生" ;;
    胎)   state_meaning="孕育,酝酿,尚未成形,潜在可能" ;;
    养)   state_meaning="养育,培养,等待时机,蓄势待发" ;;
  esac
  if [[ -n "$state_meaning" ]]; then
    if [[ "$local_ww_first" -eq 1 ]]; then
      local_ww_first=0
    else
      printf ',\n' >&3
    fi
    printf '    "state": {\n' >&3
    printf '      "symbol": "%s",\n' "$(_ww_json_escape "$OPT_STATE")" >&3
    printf '      "含义": "%s"\n' "$(_ww_json_escape "$state_meaning")" >&3
    printf '    }' >&3
  fi
fi

printf '\n  }\n' >&3
printf '}\n' >&3
exec 3>&-

echo ""
echo "万物类象已写入: $OUTPUT_PATH" >&2
