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
_XG_INNER_PALACE_DIR=""
_XG_INNER_STAR=""
_XG_INNER_GATE=""
_XG_INNER_DEITY=""
_XG_INNER_STEM_XINGGE=""
_XG_INNER_STAR_XINGGE=""
_XG_INNER_GATE_XINGGE=""
_XG_INNER_DEITY_XINGGE=""
_XG_INNER_STEM_YUANXING=""
_XG_INNER_STAR_YUANXING=""
_XG_INNER_GATE_YUANXING=""
_XG_INNER_DEITY_YUANXING=""
_XG_INNER_STEM_XINGWEI=""
_XG_INNER_STAR_XINGWEI=""
_XG_INNER_GATE_XINGWEI=""
_XG_INNER_DEITY_XINGWEI=""
_XG_INNER_LODGE_PALACE=0

_XG_OUTER_STEM=""
_XG_OUTER_STEM_WUXING=""
_XG_OUTER_WUXING_COLOR=""
_XG_OUTER_PALACE=0
_XG_OUTER_PALACE_NAME="未找到"
_XG_OUTER_PALACE_WUXING=""
_XG_OUTER_PALACE_DIR=""
_XG_OUTER_STAR=""
_XG_OUTER_GATE=""
_XG_OUTER_DEITY=""
_XG_OUTER_STEM_XINGGE=""
_XG_OUTER_STAR_XINGGE=""
_XG_OUTER_GATE_XINGGE=""
_XG_OUTER_DEITY_XINGGE=""
_XG_OUTER_STEM_YUANXING=""
_XG_OUTER_STAR_YUANXING=""
_XG_OUTER_GATE_YUANXING=""
_XG_OUTER_DEITY_YUANXING=""
_XG_OUTER_STEM_XINGWEI=""
_XG_OUTER_STAR_XINGWEI=""
_XG_OUTER_GATE_XINGWEI=""
_XG_OUTER_DEITY_XINGWEI=""
_XG_OUTER_LODGE_PALACE=0

# ---- Liuhai (六害) globals ----
_XG_INNER_LIUHAI=""
_XG_INNER_ACTIONS_COUNT=0
_XG_INNER_ACT_TYPES=()
_XG_INNER_ACT_DESCS=()
_XG_INNER_ACT_RAWS=()
_XG_INNER_MIEXIANG=""

_XG_OUTER_LIUHAI=""
_XG_OUTER_ACTIONS_COUNT=0
_XG_OUTER_ACT_TYPES=()
_XG_OUTER_ACT_DESCS=()
_XG_OUTER_ACT_RAWS=()
_XG_OUTER_MIEXIANG=""

_XG_PALACE_DIR=""
_xg_palace_direction() {
    local p="$1"
    case "$p" in
        1) _XG_PALACE_DIR="北" ;;
        2) _XG_PALACE_DIR="西南" ;;
        3) _XG_PALACE_DIR="东" ;;
        4) _XG_PALACE_DIR="东南" ;;
        5) _XG_PALACE_DIR="中" ;;
        6) _XG_PALACE_DIR="西北" ;;
        7) _XG_PALACE_DIR="西" ;;
        8) _XG_PALACE_DIR="东北" ;;
        9) _XG_PALACE_DIR="南" ;;
        *) _XG_PALACE_DIR="" ;;
    esac
}

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
    local in_si_zhu=0 in_palaces=0 in_ju=0
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

        if [[ "$line" == *'"ju": {'* ]]; then
            in_ju=1
            continue
        fi
        if (( in_ju == 1 )); then
            if [[ "$line" == *'}'* ]]; then
                in_ju=0
                continue
            fi
            if [[ "$line" == *'"type": '* ]]; then
                val="${line#*\"type\": \"}"; val="${val%%\"*}"
                dl_set "ju_type" "$val"
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
                    tian_gan|di_gan|star|gate|deity)
                        val="${line#*\"${field}\": \"}"
                        val="${val%%\"*}"
                        dl_set "palace_${current_palace}_${field}" "$val"
                        ;;
                    tianqin)
                        val="${line#*\"tianqin\": }"
                        val="${val%%,*}"
                        val="${val%%[[:space:]]*}"
                        if [[ "$val" == "true" ]]; then
                            dl_set "tianqin_host_palace" "$current_palace"
                        fi
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
    for p in 1 2 3 4 5 6 7 8 9; do
        dl_get_v "palace_${p}_tian_gan" 2>/dev/null || true
        tg="$_DL_RET"
        if [[ "$tg" == "$stem" ]]; then
            echo "$p"
            return
        fi
    done
    for p in 1 2 3 4 5 6 7 8 9; do
        dl_get_v "palace_${p}_di_gan" 2>/dev/null || true
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
    local palace=0 palace_cn="" palace_name="未找到" palace_wuxing="" palace_dir=""
    local star="" gate="" deity=""
    local stem_wuxing="" wuxing_color=""
    local stem_xg="" star_xg="" gate_xg="" deity_xg=""
    local stem_yx="" star_yx="" gate_yx="" deity_yx=""
    local stem_xw="" star_xw="" gate_xw="" deity_xw=""
    local lodge_palace=0

    palace="$(_xg_find_stem_palace_tian "$stem")"

    dl_get_v "${stem}_五行" 2>/dev/null || true; stem_wuxing="$_DL_RET"
    if [[ -n "$stem_wuxing" ]]; then
        dl_get_v "${stem_wuxing}_颜色" 2>/dev/null || true; wuxing_color="$_DL_RET"
    fi

    dl_get_v "${stem}_性格" 2>/dev/null || true; stem_xg="$_DL_RET"
    dl_get_v "${stem}_原型" 2>/dev/null || true; stem_yx="$_DL_RET"
    dl_get_v "${stem}_行为" 2>/dev/null || true; stem_xw="$_DL_RET"

    if (( palace > 0 )); then
        # 中宫(5宫)没有星门神，用天禽寄宫的星门神数据
        local data_palace=$palace
        if (( palace == 5 )); then
            dl_get_v "ju_type" 2>/dev/null || true
            if [[ "$_DL_RET" == "阳遁" ]]; then
                data_palace=2
            else
                data_palace=8
            fi
            lodge_palace=$data_palace
        fi

        dl_get_v "palace_${data_palace}_star" 2>/dev/null || true; star="$_DL_RET"
        dl_get_v "palace_${data_palace}_gate" 2>/dev/null || true; gate="$_DL_RET"
        dl_get_v "palace_${data_palace}_deity" 2>/dev/null || true; deity="$_DL_RET"

        if [[ -n "$star" ]]; then
            dl_get_v "${star}_性格" 2>/dev/null || true; star_xg="$_DL_RET"
            dl_get_v "${star}_原型" 2>/dev/null || true; star_yx="$_DL_RET"
            dl_get_v "${star}_行为" 2>/dev/null || true; star_xw="$_DL_RET"
        fi
        if [[ -n "$gate" ]]; then
            dl_get_v "${gate}_性格" 2>/dev/null || true; gate_xg="$_DL_RET"
            dl_get_v "${gate}_原型" 2>/dev/null || true; gate_yx="$_DL_RET"
            dl_get_v "${gate}_行为" 2>/dev/null || true; gate_xw="$_DL_RET"
        fi
        if [[ -n "$deity" ]]; then
            dl_get_v "${deity}_性格" 2>/dev/null || true; deity_xg="$_DL_RET"
            dl_get_v "${deity}_原型" 2>/dev/null || true; deity_yx="$_DL_RET"
            dl_get_v "${deity}_行为" 2>/dev/null || true; deity_xw="$_DL_RET"
        fi

        palace_cn="$(_xg_num_to_cn "$palace")"
        if (( palace == 5 )); then
            palace_name="中"
            palace_wuxing="土"
        else
            dl_get_v "${palace_cn}宫_名称" 2>/dev/null || true; palace_name="$_DL_RET"
            dl_get_v "${palace_cn}宫_五行" 2>/dev/null || true; palace_wuxing="$_DL_RET"
            [[ -n "$palace_name" ]] || palace_name="未找到"
        fi
        _xg_palace_direction "$palace"; palace_dir="$_XG_PALACE_DIR"
    fi

    if [[ "$role" == "inner" ]]; then
        _XG_INNER_STEM="$stem"
        _XG_INNER_STEM_WUXING="$stem_wuxing"
        _XG_INNER_WUXING_COLOR="$wuxing_color"
        _XG_INNER_PALACE="$palace"
        _XG_INNER_PALACE_NAME="$palace_name"
        _XG_INNER_PALACE_WUXING="$palace_wuxing"
        _XG_INNER_PALACE_DIR="$palace_dir"
        _XG_INNER_STAR="$star"
        _XG_INNER_GATE="$gate"
        _XG_INNER_DEITY="$deity"
        _XG_INNER_STEM_XINGGE="$stem_xg"
        _XG_INNER_STAR_XINGGE="$star_xg"
        _XG_INNER_GATE_XINGGE="$gate_xg"
        _XG_INNER_DEITY_XINGGE="$deity_xg"
        _XG_INNER_STEM_YUANXING="$stem_yx"
        _XG_INNER_STAR_YUANXING="$star_yx"
        _XG_INNER_GATE_YUANXING="$gate_yx"
        _XG_INNER_DEITY_YUANXING="$deity_yx"
        _XG_INNER_STEM_XINGWEI="$stem_xw"
        _XG_INNER_STAR_XINGWEI="$star_xw"
        _XG_INNER_GATE_XINGWEI="$gate_xw"
        _XG_INNER_DEITY_XINGWEI="$deity_xw"
        _XG_INNER_LODGE_PALACE="$lodge_palace"
    else
        _XG_OUTER_STEM="$stem"
        _XG_OUTER_STEM_WUXING="$stem_wuxing"
        _XG_OUTER_WUXING_COLOR="$wuxing_color"
        _XG_OUTER_PALACE="$palace"
        _XG_OUTER_PALACE_NAME="$palace_name"
        _XG_OUTER_PALACE_WUXING="$palace_wuxing"
        _XG_OUTER_PALACE_DIR="$palace_dir"
        _XG_OUTER_STAR="$star"
        _XG_OUTER_GATE="$gate"
        _XG_OUTER_DEITY="$deity"
        _XG_OUTER_STEM_XINGGE="$stem_xg"
        _XG_OUTER_STAR_XINGGE="$star_xg"
        _XG_OUTER_GATE_XINGGE="$gate_xg"
        _XG_OUTER_DEITY_XINGGE="$deity_xg"
        _XG_OUTER_STEM_YUANXING="$stem_yx"
        _XG_OUTER_STAR_YUANXING="$star_yx"
        _XG_OUTER_GATE_YUANXING="$gate_yx"
        _XG_OUTER_DEITY_YUANXING="$deity_yx"
        _XG_OUTER_STEM_XINGWEI="$stem_xw"
        _XG_OUTER_STAR_XINGWEI="$star_xw"
        _XG_OUTER_GATE_XINGWEI="$gate_xw"
        _XG_OUTER_DEITY_XINGWEI="$deity_xw"
        _XG_OUTER_LODGE_PALACE="$lodge_palace"
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
    # Args: role_label stem stem_wuxing palace palace_name palace_wuxing direction color
    #       stem_xg star star_xg gate gate_xg deity deity_xg
    #       stem_yx star_yx gate_yx deity_yx
    #       stem_xw star_xw gate_xw deity_xw
    local role_label="$1"
    local stem="$2"
    local stem_wuxing="$3"
    local palace="$4"
    local palace_name="$5"
    local palace_wuxing="$6"
    local direction="$7"
    local color="$8"
    local stem_xg="$9"
    local star="${10}"
    local star_xg="${11}"
    local gate="${12}"
    local gate_xg="${13}"
    local deity="${14}"
    local deity_xg="${15}"
    local stem_yx="${16}"
    local star_yx="${17}"
    local gate_yx="${18}"
    local deity_yx="${19}"
    local stem_xw="${20}"
    local star_xw="${21}"
    local gate_xw="${22}"
    local deity_xw="${23}"
    local lodge_palace="${24}"

    local palace_txt="未找到"
    if (( palace > 0 )); then
        palace_txt="${palace_name}${palace}宫(${direction},${palace_wuxing})"
        if (( lodge_palace > 0 )); then
            local lp_cn=""
            lp_cn="$(_xg_num_to_cn "$lodge_palace")"
            local lp_name=""
            if (( lodge_palace == 5 )); then
                lp_name="中"
            else
                dl_get_v "${lp_cn}宫_名称" 2>/dev/null || true; lp_name="$_DL_RET"
            fi
            _xg_palace_direction "$lodge_palace"
            palace_txt="${palace_txt}, 寄${lp_name}${lodge_palace}宫(${_XG_PALACE_DIR})"
        fi
    fi

    printf '%s(%s,%s)\n' "$role_label" "$stem" "${stem_wuxing:-?}"
    printf '  %s\n' "$palace_txt"

    # 天干
    printf '  天干: %s\n' "$stem"
    if [[ -n "$stem_xg" ]]; then
        printf '  性格: %s\n' "$stem_xg"
    fi
    if [[ -n "$stem_yx" ]]; then
        printf '  原型: %s\n' "$stem_yx"
    fi
    if [[ -n "$stem_xw" ]]; then
        printf '  行为: %s\n' "$stem_xw"
    fi

    # 神
    if [[ -n "$deity" ]]; then
        printf '\n'
        printf '  神: %s\n' "$deity"
        if [[ -n "$deity_xg" ]]; then
            printf '  性格: %s\n' "$deity_xg"
        fi
        if [[ -n "$deity_yx" ]]; then
            printf '  原型: %s\n' "$deity_yx"
        fi
        if [[ -n "$deity_xw" ]]; then
            printf '  行为: %s\n' "$deity_xw"
        fi
    fi

    # 星
    if [[ -n "$star" ]]; then
        printf '\n'
        printf '  星: %s\n' "$star"
        if [[ -n "$star_xg" ]]; then
            printf '  性格: %s\n' "$star_xg"
        fi
        if [[ -n "$star_yx" ]]; then
            printf '  原型: %s\n' "$star_yx"
        fi
        if [[ -n "$star_xw" ]]; then
            printf '  行为: %s\n' "$star_xw"
        fi
    fi

    # 门
    if [[ -n "$gate" ]]; then
        printf '\n'
        printf '  门: %s\n' "$gate"
        if [[ -n "$gate_xg" ]]; then
            printf '  性格: %s\n' "$gate_xg"
        fi
        if [[ -n "$gate_yx" ]]; then
            printf '  原型: %s\n' "$gate_yx"
        fi
        if [[ -n "$gate_xw" ]]; then
            printf '  行为: %s\n' "$gate_xw"
        fi
    fi
}

_xg_format_action() {
    local type="$1"
    local raw_line="$2"
    local miexiang="${3:-}"
    local result=""

    local tmp="$raw_line"
    local stem="" position="" color="" material="" desc=""
    local branch="" zodiac="" alt=""
    local move="" note="" reason=""

    case "$type" in
        压击刑)
            move=""
            if [[ "$raw_line" == *'"move_away": "'* ]]; then
                move="${raw_line#*\"move_away\": \"}"
                move="${move%%\"*}"
            fi
            result="    压击刑(${move}击刑 → 用合化解):"
            if [[ -n "$move" && -n "$miexiang" ]]; then
                local IFS='|'
                local mx_items=()
                read -ra mx_items <<< "$miexiang"
                IFS=','
                local mx_item=""
                for mx_item in "${mx_items[@]}"; do
                    local mx_stem="${mx_item%%(*}"
                    if [[ "$mx_stem" == "$move" ]]; then
                        result="${result}
      先灭象: 将${mx_item}"
                        break
                    fi
                done
            elif [[ -n "$move" ]]; then
                result="${result}
      先灭象: 将${move}的象移走"
            fi
            while [[ "$tmp" == *'"stem":'* ]]; do
                stem="${tmp#*\"stem\": \"}"
                stem="${stem%%\"*}"
                position="${tmp#*\"position\": \"}"
                position="${position%%\"*}"
                color="${tmp#*\"color\": \"}"
                color="${color%%\"*}"
                material="${tmp#*\"material\": \"}"
                material="${material%%\"*}"
                desc="${tmp#*\"desc\": \"}"
                desc="${desc%%\"*}"
                result="${result}
      天干 ${stem} — ${position} ${color} ${material} ${desc}"
                tmp="${tmp#*\"jinji\"}"
            done
            tmp="$raw_line"
            local dz_section="${tmp#*\"dizhi\":}"
            dz_section="${dz_section%%\]*}]"
            tmp="$dz_section"
            while [[ "$tmp" == *'"branch":'* ]]; do
                branch="${tmp#*\"branch\": \"}"
                branch="${branch%%\"*}"
                position="${tmp#*\"position\": \"}"
                position="${position%%\"*}"
                color="${tmp#*\"color\": \"}"
                color="${color%%\"*}"
                zodiac="${tmp#*\"zodiac\": \"}"
                zodiac="${zodiac%%\"*}"
                alt="${tmp#*\"alt\": \"}"
                alt="${alt%%\"*}"
                result="${result}
      地支 ${branch} — ${position} ${color} ${zodiac}(${alt})"
                tmp="${tmp#*\"alt\"*\"}"
                tmp="${tmp#*\"}"
            done
            ;;
        压入墓)
            result="    压入墓(入墓 → 用冲打开墓库):"
            local dz_section="${tmp#*\"dizhi\":}"
            dz_section="${dz_section%%\]*}]"
            tmp="$dz_section"
            while [[ "$tmp" == *'"branch":'* ]]; do
                branch="${tmp#*\"branch\": \"}"
                branch="${branch%%\"*}"
                position="${tmp#*\"position\": \"}"
                position="${position%%\"*}"
                color="${tmp#*\"color\": \"}"
                color="${color%%\"*}"
                zodiac="${tmp#*\"zodiac\": \"}"
                zodiac="${zodiac%%\"*}"
                alt="${tmp#*\"alt\": \"}"
                alt="${alt%%\"*}"
                result="${result}
      地支 ${branch} — ${position} ${color} ${zodiac}(${alt})"
                tmp="${tmp#*\"alt\"*\"}"
                tmp="${tmp#*\"}"
            done
            ;;
        压庚白虎)
            reason=""
            if [[ "$raw_line" == *'"reason": "'* ]]; then
                reason="${raw_line#*\"reason\": \"}"
                reason="${reason%%\"*}"
            fi
            result="    压${reason:-庚白虎}(${reason:-庚白虎}凶煞 → 以柔克刚):"
            while [[ "$tmp" == *'"stem":'* ]]; do
                stem="${tmp#*\"stem\": \"}"
                stem="${stem%%\"*}"
                position="${tmp#*\"position\": \"}"
                position="${position%%\"*}"
                color="${tmp#*\"color\": \"}"
                color="${color%%\"*}"
                material="${tmp#*\"material\": \"}"
                material="${material%%\"*}"
                desc="${tmp#*\"desc\": \"}"
                desc="${desc%%\"*}"
                result="${result}
      天干 ${stem} — ${position} ${color} ${material} ${desc}"
                tmp="${tmp#*\"jinji\"}"
            done
            ;;
        填空亡)
            note=""
            if [[ "$raw_line" == *'"note": "'* ]]; then
                note="${raw_line#*\"note\": \"}"
                note="${note%%\"*}"
            fi
            local kw_wuxing=""
            if [[ "$raw_line" == *'"wuxing": "'* ]]; then
                kw_wuxing="${raw_line#*\"wuxing\": \"}"
                kw_wuxing="${kw_wuxing%%\"*}"
            fi
            result="    填空亡(虚假不实 → 缺${kw_wuxing}补${kw_wuxing}):"
            local dz_section="${tmp#*\"dizhi\":}"
            dz_section="${dz_section%%\]*}]"
            tmp="$dz_section"
            while [[ "$tmp" == *'"branch":'* ]]; do
                branch="${tmp#*\"branch\": \"}"
                branch="${branch%%\"*}"
                position="${tmp#*\"position\": \"}"
                position="${position%%\"*}"
                color="${tmp#*\"color\": \"}"
                color="${color%%\"*}"
                zodiac="${tmp#*\"zodiac\": \"}"
                zodiac="${zodiac%%\"*}"
                alt="${tmp#*\"alt\": \"}"
                alt="${alt%%\"*}"
                result="${result}
      地支 ${branch} — ${position} ${color} ${zodiac}(${alt})"
                tmp="${tmp#*\"alt\"*\"}"
                tmp="${tmp#*\"}"
            done
            ;;
        压门迫)
            local mp_gate=""
            if [[ "$raw_line" == *'"gate": "'* ]]; then
                mp_gate="${raw_line#*\"gate\": \"}"
                mp_gate="${mp_gate%%\"*}"
            fi
            result="    压门迫(${mp_gate}克宫 → 用合化解):"
            local dz_section="${tmp#*\"dizhi\":}"
            dz_section="${dz_section%%\]*}]"
            tmp="$dz_section"
            while [[ "$tmp" == *'"branch":'* ]]; do
                branch="${tmp#*\"branch\": \"}"
                branch="${branch%%\"*}"
                position="${tmp#*\"position\": \"}"
                position="${position%%\"*}"
                color="${tmp#*\"color\": \"}"
                color="${color%%\"*}"
                zodiac="${tmp#*\"zodiac\": \"}"
                zodiac="${zodiac%%\"*}"
                alt="${tmp#*\"alt\": \"}"
                alt="${alt%%\"*}"
                result="${result}
      地支 ${branch} — ${position} ${color} ${zodiac}(${alt})"
                tmp="${tmp#*\"alt\"*\"}"
                tmp="${tmp#*\"}"
            done
            ;;
        *)
            result="    ${type}"
            ;;
    esac
    echo "$result"
}

_xg_parse_huaqizhen() {
    local hq_path="$1"
    if [[ ! -f "$hq_path" ]]; then
        return 0
    fi

    local inner_match_palace=0
    local outer_match_palace=0

    if (( _XG_INNER_PALACE == 5 && _XG_INNER_LODGE_PALACE > 0 )); then
        inner_match_palace=$_XG_INNER_LODGE_PALACE
    else
        inner_match_palace=$_XG_INNER_PALACE
    fi

    if (( _XG_OUTER_PALACE == 5 && _XG_OUTER_LODGE_PALACE > 0 )); then
        outer_match_palace=$_XG_OUTER_LODGE_PALACE
    else
        outer_match_palace=$_XG_OUTER_PALACE
    fi

    if (( inner_match_palace == 0 && outer_match_palace == 0 )); then
        return 0
    fi

    local in_miexiang=0
    local in_buzhen=0
    local cur_palace=0
    local cur_liuhai=""
    local in_actions=0
    local brace_depth=0
    local cur_action_raw=""
    local line=""

    while IFS= read -r line || [[ -n "$line" ]]; do
        local trimmed="${line#"${line%%[![:space:]]*}"}"

        if (( in_buzhen == 0 )); then
            if [[ "$trimmed" == '"miexiang":'* ]]; then
                in_miexiang=1
                continue
            fi
            if (( in_miexiang == 1 )); then
                if [[ "$trimmed" == ']'* ]]; then
                    in_miexiang=0
                    continue
                fi
                if [[ "$trimmed" == *'"palace":'* && "$trimmed" == *'"xiang":'* ]]; then
                    local mx_palace="${trimmed#*\"palace\": }"
                    mx_palace="${mx_palace%%,*}"
                    mx_palace="${mx_palace//[^0-9]/}"
                    if (( mx_palace == inner_match_palace || mx_palace == outer_match_palace )); then
                        local mx_stem="${trimmed#*\"stem\": \"}"
                        mx_stem="${mx_stem%%\"*}"
                        local mx_color="${trimmed#*\"color\": \"}"
                        mx_color="${mx_color%%\"*}"
                        local mx_material="${trimmed#*\"material\": \"}"
                        mx_material="${mx_material%%\"*}"
                        local mx_desc="${trimmed#*\"desc\": \"}"
                        mx_desc="${mx_desc%%\"*}"
                        local mx_method="${trimmed#*\"method\": \"}"
                        mx_method="${mx_method%%\"*}"
                        local mx_safe="${trimmed#*\"safe_to\": \"}"
                        mx_safe="${mx_safe%%\"*}"
                        local mx_text="${mx_stem}(${mx_color} ${mx_material} ${mx_desc}), ${mx_method}, 安全方位: ${mx_safe}"
                        if (( mx_palace == inner_match_palace )); then
                            _XG_INNER_MIEXIANG="${_XG_INNER_MIEXIANG:+${_XG_INNER_MIEXIANG}|}${mx_text}"
                        fi
                        if (( mx_palace == outer_match_palace )); then
                            _XG_OUTER_MIEXIANG="${_XG_OUTER_MIEXIANG:+${_XG_OUTER_MIEXIANG}|}${mx_text}"
                        fi
                    fi
                fi
                continue
            fi
            if [[ "$trimmed" == '"buzhen":'* ]]; then
                in_buzhen=1
            fi
            continue
        fi

        if (( in_actions == 1 )); then
            if [[ "$trimmed" == ']'* ]]; then
                in_actions=0
                if [[ -n "$cur_liuhai" ]]; then
                    if (( cur_palace == inner_match_palace )); then
                        _XG_INNER_LIUHAI="$cur_liuhai"
                    fi
                    if (( cur_palace == outer_match_palace )); then
                        _XG_OUTER_LIUHAI="$cur_liuhai"
                    fi
                fi
                continue
            fi
            if [[ "$trimmed" == '{'* ]]; then
                brace_depth=1
                cur_action_raw="$trimmed"
                local opens="${trimmed//[^\{]/}"
                local closes="${trimmed//[^\}]/}"
                brace_depth=$(( ${#opens} - ${#closes} ))
                if (( brace_depth <= 0 )); then
                    _xg_store_action "$cur_palace" "$inner_match_palace" "$outer_match_palace" "$cur_action_raw"
                    cur_action_raw=""
                    brace_depth=0
                fi
                continue
            fi
            if (( brace_depth > 0 )); then
                cur_action_raw="${cur_action_raw} ${trimmed}"
                local opens="${trimmed//[^\{]/}"
                local closes="${trimmed//[^\}]/}"
                brace_depth=$(( brace_depth + ${#opens} - ${#closes} ))
                if (( brace_depth <= 0 )); then
                    _xg_store_action "$cur_palace" "$inner_match_palace" "$outer_match_palace" "$cur_action_raw"
                    cur_action_raw=""
                    brace_depth=0
                fi
                continue
            fi
            continue
        fi

        if [[ "$trimmed" == *'"palace":'* && "$trimmed" == *'"liuhai":'* ]]; then
            cur_palace="${trimmed#*\"palace\": }"
            cur_palace="${cur_palace%%,*}"
            cur_palace="${cur_palace//[^0-9]/}"
            cur_liuhai="${trimmed#*\"liuhai\": \"}"
            cur_liuhai="${cur_liuhai%%\"*}"
            if [[ "$trimmed" == *'"actions":'* ]]; then
                in_actions=1
                brace_depth=0
            fi
            continue
        fi
    done < "$hq_path"
    return 0
}

_xg_store_action() {
    local palace="$1"
    local inner_p="$2"
    local outer_p="$3"
    local raw="$4"

    local act_type="${raw#*\"type\": \"}"
    act_type="${act_type%%\"*}"

    local miexiang=""
    if (( palace == inner_p )); then
        miexiang="$_XG_INNER_MIEXIANG"
    fi
    if (( palace == outer_p )); then
        miexiang="$_XG_OUTER_MIEXIANG"
    fi

    local desc=""
    desc="$(_xg_format_action "$act_type" "$raw" "$miexiang")"

    if (( palace == inner_p )); then
        _XG_INNER_ACT_TYPES+=("$act_type")
        _XG_INNER_ACT_DESCS+=("$desc")
        _XG_INNER_ACT_RAWS+=("$raw")
        _XG_INNER_ACTIONS_COUNT=$(( _XG_INNER_ACTIONS_COUNT + 1 ))
    fi
    if (( palace == outer_p )); then
        _XG_OUTER_ACT_TYPES+=("$act_type")
        _XG_OUTER_ACT_DESCS+=("$desc")
        _XG_OUTER_ACT_RAWS+=("$raw")
        _XG_OUTER_ACTIONS_COUNT=$(( _XG_OUTER_ACTIONS_COUNT + 1 ))
    fi
}

_xg_print_liuhai_text() {
    local liuhai="$1"
    shift
    local count="$1"
    shift

    if [[ -z "$liuhai" ]]; then
        return 0
    fi

    printf '\n  六害:'
    local IFS=','
    local items=()
    read -ra items <<< "$liuhai"
    local item=""
    for item in "${items[@]}"; do
        item="${item#"${item%%[![:space:]]*}"}"
        printf ' [%s]' "$item"
    done
    printf '\n'

    if (( count > 0 )); then
        printf '\n  化解:\n'
        local i=0
        while (( i < count )); do
            printf '%s\n' "$1"
            shift
            i=$(( i + 1 ))
        done
    fi
}

xg_print_text() {
    printf '性格分析\n'
    printf '========\n'
    printf '出生时间: %s\n' "$_XG_DATETIME"
    printf '出生四柱: %s\n' "$_XG_SIZHU_TEXT"
    printf '\n'
    printf '=== 内在性格(日干) ===\n\n'
    _xg_print_role_text "日干" "$_XG_INNER_STEM" "$_XG_INNER_STEM_WUXING" "$_XG_INNER_PALACE" "$_XG_INNER_PALACE_NAME" "$_XG_INNER_PALACE_WUXING" "$_XG_INNER_PALACE_DIR" "$_XG_INNER_WUXING_COLOR" "$_XG_INNER_STEM_XINGGE" "$_XG_INNER_STAR" "$_XG_INNER_STAR_XINGGE" "$_XG_INNER_GATE" "$_XG_INNER_GATE_XINGGE" "$_XG_INNER_DEITY" "$_XG_INNER_DEITY_XINGGE" "$_XG_INNER_STEM_YUANXING" "$_XG_INNER_STAR_YUANXING" "$_XG_INNER_GATE_YUANXING" "$_XG_INNER_DEITY_YUANXING" "$_XG_INNER_STEM_XINGWEI" "$_XG_INNER_STAR_XINGWEI" "$_XG_INNER_GATE_XINGWEI" "$_XG_INNER_DEITY_XINGWEI" "$_XG_INNER_LODGE_PALACE"
    _xg_print_liuhai_text "$_XG_INNER_LIUHAI" "$_XG_INNER_ACTIONS_COUNT" "${_XG_INNER_ACT_DESCS[@]+"${_XG_INNER_ACT_DESCS[@]}"}"
    printf '\n'
    printf '=== 外在性格(时干) ===\n\n'
    _xg_print_role_text "时干" "$_XG_OUTER_STEM" "$_XG_OUTER_STEM_WUXING" "$_XG_OUTER_PALACE" "$_XG_OUTER_PALACE_NAME" "$_XG_OUTER_PALACE_WUXING" "$_XG_OUTER_PALACE_DIR" "$_XG_OUTER_WUXING_COLOR" "$_XG_OUTER_STEM_XINGGE" "$_XG_OUTER_STAR" "$_XG_OUTER_STAR_XINGGE" "$_XG_OUTER_GATE" "$_XG_OUTER_GATE_XINGGE" "$_XG_OUTER_DEITY" "$_XG_OUTER_DEITY_XINGGE" "$_XG_OUTER_STEM_YUANXING" "$_XG_OUTER_STAR_YUANXING" "$_XG_OUTER_GATE_YUANXING" "$_XG_OUTER_DEITY_YUANXING" "$_XG_OUTER_STEM_XINGWEI" "$_XG_OUTER_STAR_XINGWEI" "$_XG_OUTER_GATE_XINGWEI" "$_XG_OUTER_DEITY_XINGWEI" "$_XG_OUTER_LODGE_PALACE"
    _xg_print_liuhai_text "$_XG_OUTER_LIUHAI" "$_XG_OUTER_ACTIONS_COUNT" "${_XG_OUTER_ACT_DESCS[@]+"${_XG_OUTER_ACT_DESCS[@]}"}"
    printf '\n'
}

_xg_je_str() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    printf '%s' "$s"
}

_xg_write_actions_json() {
    local prefix="$1"
    local count_var="${prefix}_ACTIONS_COUNT"
    local count="${!count_var}"

    if (( count == 0 )); then
        printf '    "actions": []\n'
        return
    fi

    printf '    "actions": [\n'
    local i=0
    while (( i < count )); do
        local raw_arr="${prefix}_ACT_RAWS[$i]"
        local raw="${!raw_arr}"
        raw="${raw%,}"
        raw="${raw% }"
        local comma=","
        if (( i == count - 1 )); then comma=""; fi
        printf '      %s%s\n' "$raw" "$comma"
        i=$(( i + 1 ))
    done
    printf '    ]\n'
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
    _xg_je_v "$_XG_INNER_PALACE_DIR"; local j_ipd="$_JE"
    _xg_je_v "$_XG_INNER_STAR"; local j_ist="$_JE"
    _xg_je_v "$_XG_INNER_GATE"; local j_iga="$_JE"
    _xg_je_v "$_XG_INNER_DEITY"; local j_ide="$_JE"
    _xg_je_v "$_XG_INNER_STEM_XINGGE"; local j_isx="$_JE"
    _xg_je_v "$_XG_INNER_STAR_XINGGE"; local j_istx="$_JE"
    _xg_je_v "$_XG_INNER_GATE_XINGGE"; local j_igx="$_JE"
    _xg_je_v "$_XG_INNER_DEITY_XINGGE"; local j_idx="$_JE"
    _xg_je_v "$_XG_INNER_STEM_YUANXING"; local j_isy="$_JE"
    _xg_je_v "$_XG_INNER_STAR_YUANXING"; local j_isty="$_JE"
    _xg_je_v "$_XG_INNER_GATE_YUANXING"; local j_igy="$_JE"
    _xg_je_v "$_XG_INNER_DEITY_YUANXING"; local j_idy="$_JE"
    _xg_je_v "$_XG_INNER_STEM_XINGWEI"; local j_isxw="$_JE"
    _xg_je_v "$_XG_INNER_STAR_XINGWEI"; local j_istxw="$_JE"
    _xg_je_v "$_XG_INNER_GATE_XINGWEI"; local j_igxw="$_JE"
    _xg_je_v "$_XG_INNER_DEITY_XINGWEI"; local j_idxw="$_JE"

    _xg_je_v "$_XG_OUTER_STEM"; local j_os="$_JE"
    _xg_je_v "$_XG_OUTER_STEM_WUXING"; local j_osw="$_JE"
    _xg_je_v "$_XG_OUTER_WUXING_COLOR"; local j_owc="$_JE"
    _xg_je_v "$_XG_OUTER_PALACE_NAME"; local j_opn="$_JE"
    _xg_je_v "$_XG_OUTER_PALACE_WUXING"; local j_opw="$_JE"
    _xg_je_v "$_XG_OUTER_PALACE_DIR"; local j_opd="$_JE"
    _xg_je_v "$_XG_OUTER_STAR"; local j_ost="$_JE"
    _xg_je_v "$_XG_OUTER_GATE"; local j_oga="$_JE"
    _xg_je_v "$_XG_OUTER_DEITY"; local j_ode="$_JE"
    _xg_je_v "$_XG_OUTER_STEM_XINGGE"; local j_osx="$_JE"
    _xg_je_v "$_XG_OUTER_STAR_XINGGE"; local j_ostx="$_JE"
    _xg_je_v "$_XG_OUTER_GATE_XINGGE"; local j_ogx="$_JE"
    _xg_je_v "$_XG_OUTER_DEITY_XINGGE"; local j_odx="$_JE"
    _xg_je_v "$_XG_OUTER_STEM_YUANXING"; local j_osy="$_JE"
    _xg_je_v "$_XG_OUTER_STAR_YUANXING"; local j_osty="$_JE"
    _xg_je_v "$_XG_OUTER_GATE_YUANXING"; local j_ogy="$_JE"
    _xg_je_v "$_XG_OUTER_DEITY_YUANXING"; local j_ody="$_JE"
    _xg_je_v "$_XG_OUTER_STEM_XINGWEI"; local j_osxw="$_JE"
    _xg_je_v "$_XG_OUTER_STAR_XINGWEI"; local j_ostxw="$_JE"
    _xg_je_v "$_XG_OUTER_GATE_XINGWEI"; local j_ogxw="$_JE"
    _xg_je_v "$_XG_OUTER_DEITY_XINGWEI"; local j_odxw="$_JE"

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
    printf '    "palace_direction": "%s",\n' "$j_ipd" >&3
    printf '    "star": "%s",\n' "$j_ist" >&3
    printf '    "gate": "%s",\n' "$j_iga" >&3
    printf '    "deity": "%s",\n' "$j_ide" >&3
    printf '    "stem_xingge": "%s",\n' "$j_isx" >&3
    printf '    "star_xingge": "%s",\n' "$j_istx" >&3
    printf '    "gate_xingge": "%s",\n' "$j_igx" >&3
    printf '    "deity_xingge": "%s",\n' "$j_idx" >&3
    printf '    "stem_yuanxing": "%s",\n' "$j_isy" >&3
    printf '    "star_yuanxing": "%s",\n' "$j_isty" >&3
    printf '    "gate_yuanxing": "%s",\n' "$j_igy" >&3
    printf '    "deity_yuanxing": "%s",\n' "$j_idy" >&3
    printf '    "stem_xingwei": "%s",\n' "$j_isxw" >&3
    printf '    "star_xingwei": "%s",\n' "$j_istxw" >&3
    printf '    "gate_xingwei": "%s",\n' "$j_igxw" >&3
    printf '    "deity_xingwei": "%s",\n' "$j_idxw" >&3
    printf '    "liuhai": "%s",\n' "$(_xg_je_str "$_XG_INNER_LIUHAI")" >&3
    _xg_write_actions_json "_XG_INNER" >&3
    printf '  },\n' >&3
    printf '  "outer": {\n' >&3
    printf '    "stem": "%s",\n' "$j_os" >&3
    printf '    "stem_wuxing": "%s",\n' "$j_osw" >&3
    printf '    "wuxing_color": "%s",\n' "$j_owc" >&3
    printf '    "palace": %s,\n' "${_XG_OUTER_PALACE:-0}" >&3
    printf '    "palace_name": "%s",\n' "$j_opn" >&3
    printf '    "palace_wuxing": "%s",\n' "$j_opw" >&3
    printf '    "palace_direction": "%s",\n' "$j_opd" >&3
    printf '    "star": "%s",\n' "$j_ost" >&3
    printf '    "gate": "%s",\n' "$j_oga" >&3
    printf '    "deity": "%s",\n' "$j_ode" >&3
    printf '    "stem_xingge": "%s",\n' "$j_osx" >&3
    printf '    "star_xingge": "%s",\n' "$j_ostx" >&3
    printf '    "gate_xingge": "%s",\n' "$j_ogx" >&3
    printf '    "deity_xingge": "%s",\n' "$j_odx" >&3
    printf '    "stem_yuanxing": "%s",\n' "$j_osy" >&3
    printf '    "star_yuanxing": "%s",\n' "$j_osty" >&3
    printf '    "gate_yuanxing": "%s",\n' "$j_ogy" >&3
    printf '    "deity_yuanxing": "%s",\n' "$j_ody" >&3
    printf '    "stem_xingwei": "%s",\n' "$j_osxw" >&3
    printf '    "star_xingwei": "%s",\n' "$j_ostxw" >&3
    printf '    "gate_xingwei": "%s",\n' "$j_ogxw" >&3
    printf '    "deity_xingwei": "%s",\n' "$j_odxw" >&3
    printf '    "liuhai": "%s",\n' "$(_xg_je_str "$_XG_OUTER_LIUHAI")" >&3
    _xg_write_actions_json "_XG_OUTER" >&3
    printf '  }\n' >&3
    printf '}\n' >&3

    exec 3>&-
    return 0
}

xg_run_analysis() {
    local input_path="$1"
    local output_path="$2"
    local huaqizhen_path="${3:-}"
    xg_analyze "$input_path" || return 1
    if [[ -n "$huaqizhen_path" ]]; then
        _xg_parse_huaqizhen "$huaqizhen_path"
    fi
    xg_print_text
    xg_write_json "$output_path" || return 1
    return 0
}
