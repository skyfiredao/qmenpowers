#!/usr/bin/env bash
# Copyright (C) 2025 — Licensed under GPL-3.0
# See https://www.gnu.org/licenses/gpl-3.0.html
# qimen_xingge.sh — 性格分析 core computation library.
# Sourced AFTER data_loader.sh and required .dat files are loaded.

# ---- JSON escape helper ----
_JE=""
_xg_je_v() {
    _JE="$1"
    _JE="${_JE//\\/\\\\}"
    _JE="${_JE//\"/\\\"}"
}

# ---- Globals ----
_XG_SHOW_WANWU="${_SHOW_WANWU:-}"

_XG_DATETIME=""
_XG_SIZHU_YEAR=""
_XG_SIZHU_MONTH=""
_XG_SIZHU_DAY=""
_XG_SIZHU_HOUR=""
_XG_SIZHU_TEXT=""

_XG_INNER_STEM=""
_XG_INNER_STEM_WUXING=""
_XG_INNER_WUXING_COLOR=""
_XG_INNER_PALACE=0
_XG_INNER_PALACE_NAME="未找到"
_XG_INNER_PALACE_WUXING=""
_XG_INNER_STAR=""
_XG_INNER_GATE=""
_XG_INNER_DEITY=""
_XG_INNER_STEM_XINGGE=""
_XG_INNER_STAR_XINGGE=""
_XG_INNER_GATE_XINGGE=""
_XG_INNER_DEITY_XINGGE=""

_XG_OUTER_STEM=""
_XG_OUTER_STEM_WUXING=""
_XG_OUTER_WUXING_COLOR=""
_XG_OUTER_PALACE=0
_XG_OUTER_PALACE_NAME="未找到"
_XG_OUTER_PALACE_WUXING=""
_XG_OUTER_STAR=""
_XG_OUTER_GATE=""
_XG_OUTER_DEITY=""
_XG_OUTER_STEM_XINGGE=""
_XG_OUTER_STAR_XINGGE=""
_XG_OUTER_GATE_XINGGE=""
_XG_OUTER_DEITY_XINGGE=""

_xg_num_to_cn() {
    case "$1" in
        1) echo "一" ;;
        2) echo "二" ;;
        3) echo "三" ;;
        4) echo "四" ;;
        5) echo "五" ;;
        6) echo "六" ;;
        7) echo "七" ;;
        8) echo "八" ;;
        9) echo "九" ;;
        *) echo "" ;;
    esac
}

_xg_extract_stem() {
    local gz="$1" g
    for g in 甲 乙 丙 丁 戊 己 庚 辛 壬 癸; do
        if [[ "$gz" == "${g}"* ]]; then
            echo "$g"
            return
        fi
    done
    echo ""
}

# 将 plate JSON 中核心字段提取并写入 dl key-value 存储。
_xg_parse_birth_json() {
    local filepath="$1"
    local line=""
    local in_si_zhu=0 in_palaces=0
    local current_palace=""
    local field="" val="" tmp="" first=""

    [[ -f "$filepath" ]] || {
        echo "错误：输入文件不存在：$filepath" >&2
        return 1
    }

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" == *'"datetime": '* ]]; then
            val="${line#*\"datetime\": \"}"
            val="${val%%\"*}"
            dl_set "datetime" "$val"
            continue
        fi

        if [[ "$line" == *'"si_zhu": {'* ]]; then
            in_si_zhu=1
            continue
        fi
        if (( in_si_zhu == 1 )); then
            if [[ "$line" == *'}'* ]]; then
                in_si_zhu=0
                continue
            fi
            if [[ "$line" == *'"year": '* ]]; then
                val="${line#*\"year\": \"}"; val="${val%%\"*}"
                dl_set "si_zhu_year" "$val"
            elif [[ "$line" == *'"month": '* ]]; then
                val="${line#*\"month\": \"}"; val="${val%%\"*}"
                dl_set "si_zhu_month" "$val"
            elif [[ "$line" == *'"day": '* ]]; then
                val="${line#*\"day\": \"}"; val="${val%%\"*}"
                dl_set "si_zhu_day" "$val"
            elif [[ "$line" == *'"hour": '* ]]; then
                val="${line#*\"hour\": \"}"; val="${val%%\"*}"
                dl_set "si_zhu_hour" "$val"
            fi
            continue
        fi

        if [[ "$line" == *'"palaces": {'* ]]; then
            in_palaces=1
            continue
        fi

        if (( in_palaces == 1 )); then
            if [[ -z "$current_palace" && "$line" == '  }' ]]; then
                in_palaces=0
                continue
            fi

            if [[ -z "$current_palace" && "$line" == *'": {'* ]]; then
                tmp="${line#*\"}"
                first="${tmp%%\"*}"
                case "$first" in
                    1|2|3|4|5|6|7|8|9)
                        current_palace="$first"
                        ;;
                esac
                continue
            fi

            if [[ -n "$current_palace" && ( "$line" == '    },' || "$line" == '    }' ) ]]; then
                current_palace=""
                continue
            fi

            if [[ -n "$current_palace" && "$line" == *'": '* ]]; then
                tmp="${line#*\"}"
                field="${tmp%%\"*}"
                case "$field" in
                    tian_gan|star|gate|deity)
                        val="${line#*\"${field}\": \"}"
                        val="${val%%\"*}"
                        dl_set "palace_${current_palace}_${field}" "$val"
                        ;;
                esac
            fi
            continue
        fi
    done < "$filepath"

    return 0
}

_xg_find_stem_palace_tian() {
    local stem="$1" p tg
    for p in 1 2 3 4 6 7 8 9; do
        dl_get_v "palace_${p}_tian_gan" 2>/dev/null || true
        tg="$_DL_RET"
        if [[ "$tg" == "$stem" ]]; then
            echo "$p"
            return
        fi
    done
    echo "0"
}

_xg_fill_role() {
    # Args:
    #   $1 role (inner|outer)
    #   $2 stem
    local role="$1"
    local stem="$2"
    local palace=0 palace_cn="" palace_name="未找到" palace_wuxing=""
    local star="" gate="" deity=""
    local stem_wuxing="" wuxing_color=""
    local stem_xg="" star_xg="" gate_xg="" deity_xg=""

    palace="$(_xg_find_stem_palace_tian "$stem")"

    dl_get_v "${stem}_五行" 2>/dev/null || true; stem_wuxing="$_DL_RET"
    if [[ -n "$stem_wuxing" ]]; then
        dl_get_v "${stem_wuxing}_颜色" 2>/dev/null || true; wuxing_color="$_DL_RET"
    fi

    dl_get_v "${stem}_性格" 2>/dev/null || true; stem_xg="$_DL_RET"

    if (( palace > 0 )); then
        dl_get_v "palace_${palace}_star" 2>/dev/null || true; star="$_DL_RET"
        dl_get_v "palace_${palace}_gate" 2>/dev/null || true; gate="$_DL_RET"
        dl_get_v "palace_${palace}_deity" 2>/dev/null || true; deity="$_DL_RET"

        if [[ -n "$star" ]]; then
            dl_get_v "${star}_性格" 2>/dev/null || true; star_xg="$_DL_RET"
        fi
        if [[ -n "$gate" ]]; then
            dl_get_v "${gate}_性格" 2>/dev/null || true; gate_xg="$_DL_RET"
        fi
        if [[ -n "$deity" ]]; then
            dl_get_v "${deity}_性格" 2>/dev/null || true; deity_xg="$_DL_RET"
        fi

        palace_cn="$(_xg_num_to_cn "$palace")"
        dl_get_v "${palace_cn}宫_名称" 2>/dev/null || true; palace_name="$_DL_RET"
        dl_get_v "${palace_cn}宫_五行" 2>/dev/null || true; palace_wuxing="$_DL_RET"
        [[ -n "$palace_name" ]] || palace_name="未找到"
    fi

    if [[ "$role" == "inner" ]]; then
        _XG_INNER_STEM="$stem"
        _XG_INNER_STEM_WUXING="$stem_wuxing"
        _XG_INNER_WUXING_COLOR="$wuxing_color"
        _XG_INNER_PALACE="$palace"
        _XG_INNER_PALACE_NAME="$palace_name"
        _XG_INNER_PALACE_WUXING="$palace_wuxing"
        _XG_INNER_STAR="$star"
        _XG_INNER_GATE="$gate"
        _XG_INNER_DEITY="$deity"
        _XG_INNER_STEM_XINGGE="$stem_xg"
        _XG_INNER_STAR_XINGGE="$star_xg"
        _XG_INNER_GATE_XINGGE="$gate_xg"
        _XG_INNER_DEITY_XINGGE="$deity_xg"
    else
        _XG_OUTER_STEM="$stem"
        _XG_OUTER_STEM_WUXING="$stem_wuxing"
        _XG_OUTER_WUXING_COLOR="$wuxing_color"
        _XG_OUTER_PALACE="$palace"
        _XG_OUTER_PALACE_NAME="$palace_name"
        _XG_OUTER_PALACE_WUXING="$palace_wuxing"
        _XG_OUTER_STAR="$star"
        _XG_OUTER_GATE="$gate"
        _XG_OUTER_DEITY="$deity"
        _XG_OUTER_STEM_XINGGE="$stem_xg"
        _XG_OUTER_STAR_XINGGE="$star_xg"
        _XG_OUTER_GATE_XINGGE="$gate_xg"
        _XG_OUTER_DEITY_XINGGE="$deity_xg"
    fi
}

xg_analyze() {
    # Args: $1 input_path
    local input_path="$1"
    local day_gz="" hour_gz=""
    local ri_gan="" shi_gan=""

    _xg_parse_birth_json "$input_path" || return 1

    dl_get_v "datetime" 2>/dev/null || true; _XG_DATETIME="$_DL_RET"
    dl_get_v "si_zhu_year" 2>/dev/null || true; _XG_SIZHU_YEAR="$_DL_RET"
    dl_get_v "si_zhu_month" 2>/dev/null || true; _XG_SIZHU_MONTH="$_DL_RET"
    dl_get_v "si_zhu_day" 2>/dev/null || true; _XG_SIZHU_DAY="$_DL_RET"
    dl_get_v "si_zhu_hour" 2>/dev/null || true; _XG_SIZHU_HOUR="$_DL_RET"

    _XG_SIZHU_TEXT="${_XG_SIZHU_YEAR} ${_XG_SIZHU_MONTH} ${_XG_SIZHU_DAY} ${_XG_SIZHU_HOUR}"

    day_gz="$_XG_SIZHU_DAY"
    hour_gz="$_XG_SIZHU_HOUR"
    ri_gan="$(_xg_extract_stem "$day_gz")"
    shi_gan="$(_xg_extract_stem "$hour_gz")"

    if [[ -z "$ri_gan" || -z "$shi_gan" ]]; then
        echo "错误：无法从四柱中提取日干/时干。" >&2
        return 1
    fi

    _xg_fill_role "inner" "$ri_gan"
    _xg_fill_role "outer" "$shi_gan"
    return 0
}

_xg_print_role_text() {
    # Args: role_label stem palace palace_name palace_wuxing color stem_xg star star_xg gate gate_xg deity deity_xg
    local role_label="$1"
    local stem="$2"
    local palace="$3"
    local palace_name="$4"
    local palace_wuxing="$5"
    local color="$6"
    local stem_xg="$7"
    local star="$8"
    local star_xg="$9"
    local gate="${10}"
    local gate_xg="${11}"
    local deity="${12}"
    local deity_xg="${13}"

    local palace_txt="未找到"
    if (( palace > 0 )); then
        palace_txt="${palace}宫${palace_name}(${palace_wuxing})"
    fi

    printf '%s: %s | 宫位: %s | 五行色: %s\n' "$role_label" "$stem" "$palace_txt" "${color:-未知}"
    printf '  天干: %s — %s\n' "$stem" "$stem_xg"
    printf '  星  : %s — %s\n' "$star" "$star_xg"
    printf '  门  : %s — %s\n' "$gate" "$gate_xg"
    printf '  神  : %s — %s\n' "$deity" "$deity_xg"
}

xg_print_text() {
    printf '════════════════════════════════════════════\n'
    printf '  出生局性格分析\n'
    printf '════════════════════════════════════════════\n'
    printf '出生时间: %s\n' "$_XG_DATETIME"
    printf '四柱: %s\n' "$_XG_SIZHU_TEXT"
    printf '\n'
    printf '── 内在性格（日干）──────────────────\n'
    _xg_print_role_text "日干" "$_XG_INNER_STEM" "$_XG_INNER_PALACE" "$_XG_INNER_PALACE_NAME" "$_XG_INNER_PALACE_WUXING" "$_XG_INNER_WUXING_COLOR" "$_XG_INNER_STEM_XINGGE" "$_XG_INNER_STAR" "$_XG_INNER_STAR_XINGGE" "$_XG_INNER_GATE" "$_XG_INNER_GATE_XINGGE" "$_XG_INNER_DEITY" "$_XG_INNER_DEITY_XINGGE"
    printf '\n'
    printf '── 外在性格（时干）──────────────────\n'
    _xg_print_role_text "时干" "$_XG_OUTER_STEM" "$_XG_OUTER_PALACE" "$_XG_OUTER_PALACE_NAME" "$_XG_OUTER_PALACE_WUXING" "$_XG_OUTER_WUXING_COLOR" "$_XG_OUTER_STEM_XINGGE" "$_XG_OUTER_STAR" "$_XG_OUTER_STAR_XINGGE" "$_XG_OUTER_GATE" "$_XG_OUTER_GATE_XINGGE" "$_XG_OUTER_DEITY" "$_XG_OUTER_DEITY_XINGGE"
}

xg_write_json() {
    # Args: $1 output_path
    local output_path="$1"

    _xg_je_v "$_XG_DATETIME"; local j_dt="$_JE"
    _xg_je_v "$_XG_SIZHU_TEXT"; local j_sizhu="$_JE"

    _xg_je_v "$_XG_INNER_STEM"; local j_is="$_JE"
    _xg_je_v "$_XG_INNER_STEM_WUXING"; local j_isw="$_JE"
    _xg_je_v "$_XG_INNER_WUXING_COLOR"; local j_iwc="$_JE"
    _xg_je_v "$_XG_INNER_PALACE_NAME"; local j_ipn="$_JE"
    _xg_je_v "$_XG_INNER_PALACE_WUXING"; local j_ipw="$_JE"
    _xg_je_v "$_XG_INNER_STAR"; local j_ist="$_JE"
    _xg_je_v "$_XG_INNER_GATE"; local j_iga="$_JE"
    _xg_je_v "$_XG_INNER_DEITY"; local j_ide="$_JE"
    _xg_je_v "$_XG_INNER_STEM_XINGGE"; local j_isx="$_JE"
    _xg_je_v "$_XG_INNER_STAR_XINGGE"; local j_istx="$_JE"
    _xg_je_v "$_XG_INNER_GATE_XINGGE"; local j_igx="$_JE"
    _xg_je_v "$_XG_INNER_DEITY_XINGGE"; local j_idx="$_JE"

    _xg_je_v "$_XG_OUTER_STEM"; local j_os="$_JE"
    _xg_je_v "$_XG_OUTER_STEM_WUXING"; local j_osw="$_JE"
    _xg_je_v "$_XG_OUTER_WUXING_COLOR"; local j_owc="$_JE"
    _xg_je_v "$_XG_OUTER_PALACE_NAME"; local j_opn="$_JE"
    _xg_je_v "$_XG_OUTER_PALACE_WUXING"; local j_opw="$_JE"
    _xg_je_v "$_XG_OUTER_STAR"; local j_ost="$_JE"
    _xg_je_v "$_XG_OUTER_GATE"; local j_oga="$_JE"
    _xg_je_v "$_XG_OUTER_DEITY"; local j_ode="$_JE"
    _xg_je_v "$_XG_OUTER_STEM_XINGGE"; local j_osx="$_JE"
    _xg_je_v "$_XG_OUTER_STAR_XINGGE"; local j_ostx="$_JE"
    _xg_je_v "$_XG_OUTER_GATE_XINGGE"; local j_ogx="$_JE"
    _xg_je_v "$_XG_OUTER_DEITY_XINGGE"; local j_odx="$_JE"

    exec 3>"$output_path" || {
        echo "错误：无法写入输出文件：$output_path" >&2
        return 1
    }

    printf '{\n' >&3
    printf '  "type": "xingge",\n' >&3
    printf '  "birth_info": {\n' >&3
    printf '    "datetime": "%s",\n' "$j_dt" >&3
    printf '    "sizhu": "%s"\n' "$j_sizhu" >&3
    printf '  },\n' >&3
    printf '  "inner": {\n' >&3
    printf '    "stem": "%s",\n' "$j_is" >&3
    printf '    "stem_wuxing": "%s",\n' "$j_isw" >&3
    printf '    "wuxing_color": "%s",\n' "$j_iwc" >&3
    printf '    "palace": %s,\n' "${_XG_INNER_PALACE:-0}" >&3
    printf '    "palace_name": "%s",\n' "$j_ipn" >&3
    printf '    "palace_wuxing": "%s",\n' "$j_ipw" >&3
    printf '    "star": "%s",\n' "$j_ist" >&3
    printf '    "gate": "%s",\n' "$j_iga" >&3
    printf '    "deity": "%s",\n' "$j_ide" >&3
    printf '    "stem_xingge": "%s",\n' "$j_isx" >&3
    printf '    "star_xingge": "%s",\n' "$j_istx" >&3
    printf '    "gate_xingge": "%s",\n' "$j_igx" >&3
    printf '    "deity_xingge": "%s"\n' "$j_idx" >&3
    printf '  },\n' >&3
    printf '  "outer": {\n' >&3
    printf '    "stem": "%s",\n' "$j_os" >&3
    printf '    "stem_wuxing": "%s",\n' "$j_osw" >&3
    printf '    "wuxing_color": "%s",\n' "$j_owc" >&3
    printf '    "palace": %s,\n' "${_XG_OUTER_PALACE:-0}" >&3
    printf '    "palace_name": "%s",\n' "$j_opn" >&3
    printf '    "palace_wuxing": "%s",\n' "$j_opw" >&3
    printf '    "star": "%s",\n' "$j_ost" >&3
    printf '    "gate": "%s",\n' "$j_oga" >&3
    printf '    "deity": "%s",\n' "$j_ode" >&3
    printf '    "stem_xingge": "%s",\n' "$j_osx" >&3
    printf '    "star_xingge": "%s",\n' "$j_ostx" >&3
    printf '    "gate_xingge": "%s",\n' "$j_ogx" >&3
    printf '    "deity_xingge": "%s"\n' "$j_odx" >&3
    printf '  }\n' >&3
    printf '}\n' >&3

    exec 3>&-
    return 0
}

xg_run_analysis() {
    # Args: $1 input_path $2 output_path
    local input_path="$1"
    local output_path="$2"
    xg_analyze "$input_path" || return 1
    xg_print_text
    xg_write_json "$output_path" || return 1
    return 0
}
