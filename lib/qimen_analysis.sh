#!/usr/bin/env bash
# Copyright (C) 2025 — Licensed under GPL-3.0
# See https://www.gnu.org/licenses/gpl-3.0.html
# qimen_analysis.sh — Analysis computation library for qmenpowers.
# Sourced AFTER data_loader.sh and required .dat files are loaded.

_qa_json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    echo "$s"
}

_JE=""
_qa_je_v() {
    _JE="$1"
    _JE="${_JE//\\/\\\\}"
    _JE="${_JE//\"/\\\"}"
}

_qa_extract_stem() {
    local gz="$1" g
    for g in 甲 乙 丙 丁 戊 己 庚 辛 壬 癸; do
        if [[ "$gz" == "${g}"* ]]; then
            echo "$g"
            return
        fi
    done
}

_qa_json_line_str() {
    local line="$1" v
    v="${line#*: \"}"
    v="${v%\"*}"
    echo "$v"
}

_qa_json_line_raw() {
    local line="$1" v
    v="${line#*: }"
    v="${v%,}"
    echo "$v"
}

qa_parse_plate_json() {
    local filepath="$1"
    local line=""
    local in_si_zhu=0 in_ju=0 in_zhi_fu=0 in_zhi_shi=0 in_palaces=0
    local found_si_zhu=0 found_palaces=0
    local current_palace=""
    local field="" val="" qkey="" qfirst="" tmp="" b1="" b2="" p1="" p2=""

    [[ -f "$filepath" ]] || {
        echo "ERROR: plate JSON not found: $filepath" >&2
        return 1
    }

    dl_set "plate_source" "$filepath"

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" == *'"si_zhu": {'* ]]; then
            in_si_zhu=1
            found_si_zhu=1
            continue
        fi
        if [[ "$line" == *'"ju": {'* ]]; then
            in_ju=1
            continue
        fi
        if [[ "$line" == *'"zhi_fu": {'* ]]; then
            in_zhi_fu=1
            continue
        fi
        if [[ "$line" == *'"zhi_shi": {'* ]]; then
            in_zhi_shi=1
            continue
        fi
        if [[ "$line" == *'"palaces": {'* ]]; then
            in_palaces=1
            found_palaces=1
            continue
        fi

        # top-level direct fields
        if [[ "$line" == *'"datetime": '* ]]; then
            dl_set "plate_datetime" "$(_qa_json_line_str "$line")"
            continue
        fi
        if [[ "$line" == *'"kong_wang": ['* ]]; then
            tmp="$line"
            tmp="${tmp#*\"branch\": \"}"
            b1="${tmp%%\"*}"
            tmp="${tmp#*\"palace\": }"
            p1="${tmp%%[^0-9]*}"

            tmp="${tmp#*\"branch\": \"}"
            b2="${tmp%%\"*}"
            tmp="${tmp#*\"palace\": }"
            p2="${tmp%%[^0-9]*}"

            dl_set "plate_kong_wang_0_branch" "$b1"
            dl_set "plate_kong_wang_0_palace" "$p1"
            dl_set "plate_kong_wang_1_branch" "$b2"
            dl_set "plate_kong_wang_1_palace" "$p2"
            continue
        fi
        if [[ "$line" == *'"yi_ma": {'* ]]; then
            tmp="${line#*\"branch\": \"}"
            val="${tmp%%\"*}"
            dl_set "plate_yi_ma_branch" "$val"
            tmp="${line#*\"palace\": }"
            val="${tmp%%\}*}"
            val="${val%,}"
            dl_set "plate_yi_ma_palace" "$val"
            continue
        fi

        if (( in_si_zhu == 1 )); then
            if [[ "$line" == *'}'* ]]; then
                in_si_zhu=0
                continue
            fi
            if [[ "$line" == *'"year": '* ]]; then
                dl_set "plate_si_zhu_year" "$(_qa_json_line_str "$line")"
            elif [[ "$line" == *'"month": '* ]]; then
                dl_set "plate_si_zhu_month" "$(_qa_json_line_str "$line")"
            elif [[ "$line" == *'"day": '* ]]; then
                dl_set "plate_si_zhu_day" "$(_qa_json_line_str "$line")"
            elif [[ "$line" == *'"hour": '* ]]; then
                dl_set "plate_si_zhu_hour" "$(_qa_json_line_str "$line")"
            fi
            continue
        fi

        if (( in_ju == 1 )); then
            if [[ "$line" == *'}'* ]]; then
                in_ju=0
                continue
            fi
            if [[ "$line" == *'"type": '* ]]; then
                dl_set "plate_ju_type" "$(_qa_json_line_str "$line")"
            elif [[ "$line" == *'"number": '* ]]; then
                dl_set "plate_ju_number" "$(_qa_json_line_raw "$line")"
            elif [[ "$line" == *'"yuan": '* ]]; then
                dl_set "plate_ju_yuan" "$(_qa_json_line_str "$line")"
            elif [[ "$line" == *'"run": '* ]]; then
                dl_set "plate_ju_run" "$(_qa_json_line_raw "$line")"
            fi
            continue
        fi

        if (( in_zhi_fu == 1 )); then
            if [[ "$line" == *'}'* ]]; then
                in_zhi_fu=0
                continue
            fi
            if [[ "$line" == *'"star": '* ]]; then
                dl_set "plate_zhi_fu_star" "$(_qa_json_line_str "$line")"
            elif [[ "$line" == *'"palace": '* ]]; then
                dl_set "plate_zhi_fu_palace" "$(_qa_json_line_raw "$line")"
            fi
            continue
        fi

        if (( in_zhi_shi == 1 )); then
            if [[ "$line" == *'}'* ]]; then
                in_zhi_shi=0
                continue
            fi
            if [[ "$line" == *'"gate": '* ]]; then
                dl_set "plate_zhi_shi_gate" "$(_qa_json_line_str "$line")"
            elif [[ "$line" == *'"palace": '* ]]; then
                dl_set "plate_zhi_shi_palace" "$(_qa_json_line_raw "$line")"
            fi
            continue
        fi

        if (( in_palaces == 1 )); then
            # end of all palaces section
            if [[ -z "$current_palace" && "$line" == '  }' ]]; then
                in_palaces=0
                continue
            fi

            # palace object start: "N": {
            if [[ -z "$current_palace" && "$line" == *'": {'* ]]; then
                tmp="${line#*\"}"
                qfirst="${tmp%%\"*}"
                case "$qfirst" in
                    1|2|3|4|5|6|7|8|9)
                        current_palace="$qfirst"
                        ;;
                esac
                continue
            fi

            # palace object end
            if [[ -n "$current_palace" && "$line" == '    },' ]]; then
                current_palace=""
                continue
            fi
            if [[ -n "$current_palace" && "$line" == '    }' ]]; then
                current_palace=""
                continue
            fi

            if [[ -n "$current_palace" && "$line" == *'": '* ]]; then
                tmp="${line#*\"}"
                field="${tmp%%\"*}"
                qkey="palace_${current_palace}_${field}"

                case "$field" in
                    name|wuxing|direction|star|star_wuxing|gate|gate_wuxing|deity|tian_gan|tian_gan_wuxing|di_gan|di_gan_wuxing|state)
                        val="$(_qa_json_line_str "$line")"
                        dl_set "$qkey" "$val"
                        ;;
                    kong_wang|yi_ma|ji_xing|geng|rumu_gan|rumu_star|rumu_gate|men_po|star_fan_yin|gate_fan_yin|star_fu_yin|gate_fu_yin|gan_fan_yin|gan_fu_yin)
                        val="$(_qa_json_line_raw "$line")"
                        dl_set "$qkey" "$val"
                        ;;
                esac
            fi
            continue
        fi
    done < "$filepath"

    if (( found_palaces == 0 || found_si_zhu == 0 )); then
        echo "ERROR: malformed plate JSON (missing si_zhu or palaces): $filepath" >&2
        return 1
    fi

    return 0
}

qa_find_ri_gan_palace() {
    local day_gz stem p di
    dl_get_v "plate_si_zhu_day" 2>/dev/null || true; day_gz="$_DL_RET"
    stem="$(_qa_extract_stem "$day_gz")"
    dl_set "ri_gan_stem" "$stem"
    dl_set "ri_gan_palace" ""

    for p in 1 2 3 4 5 6 7 8 9; do
        dl_get_v "palace_${p}_di_gan" 2>/dev/null || true; di="$_DL_RET"
        if [[ -n "$stem" && "$di" == "$stem" ]]; then
            dl_set "ri_gan_palace" "$p"
            return 0
        fi
    done
    return 0
}

qa_find_shi_gan_palace() {
    local hour_gz stem p di
    dl_get_v "plate_si_zhu_hour" 2>/dev/null || true; hour_gz="$_DL_RET"
    stem="$(_qa_extract_stem "$hour_gz")"
    dl_set "shi_gan_stem" "$stem"
    dl_set "shi_gan_palace" ""

    for p in 1 2 3 4 5 6 7 8 9; do
        dl_get_v "palace_${p}_di_gan" 2>/dev/null || true; di="$_DL_RET"
        if [[ -n "$stem" && "$di" == "$stem" ]]; then
            dl_set "shi_gan_palace" "$p"
            return 0
        fi
    done
    return 0
}

qa_load_yongshen_rules() {
    local question_type="$1"
    local i=0 key rule type name
    dl_set "question_type" "$question_type"
    dl_set "yongshen_count" "0"

    while :; do
        key="${question_type}_${i}"
        dl_get_v "$key" 2>/dev/null || true; rule="$_DL_RET"
        [[ -n "$rule" ]] || break

        type="${rule%%,*}"
        name="${rule#*,}"
        dl_set "yongshen_${i}_type" "$type"
        dl_set "yongshen_${i}_name" "$name"
        i=$((i + 1))
    done

    dl_set "yongshen_count" "$i"
    return 0
}

qa_mark_yongshen() {
    local i count type name p target
    dl_get_v "yongshen_count" 2>/dev/null || true; count="$_DL_RET"
    [[ -n "$count" ]] || count=0

    for p in 1 2 3 4 5 6 7 8 9; do
        dl_set "palace_${p}_is_yongshen" "false"
    done

    for ((i=0; i<count; i++)); do
        dl_get_v "yongshen_${i}_type" 2>/dev/null || true; type="$_DL_RET"
        dl_get_v "yongshen_${i}_name" 2>/dev/null || true; name="$_DL_RET"
        dl_set "yongshen_${i}_palace" ""

        for p in 1 2 3 4 6 7 8 9; do
            target=""
            case "$type" in
                star)
                    dl_get_v "palace_${p}_star" 2>/dev/null || true; target="$_DL_RET"
                    ;;
                gate)
                    dl_get_v "palace_${p}_gate" 2>/dev/null || true; target="$_DL_RET"
                    ;;
                deity)
                    dl_get_v "palace_${p}_deity" 2>/dev/null || true; target="$_DL_RET"
                    ;;
                stem)
                    dl_get_v "palace_${p}_tian_gan" 2>/dev/null || true; target="$_DL_RET"
                    ;;
            esac
            if [[ -n "$name" && "$target" == "$name" ]]; then
                dl_set "yongshen_${i}_palace" "$p"
                dl_set "palace_${p}_is_yongshen" "true"
                break
            fi
        done
    done
    return 0
}

_qa_lookup_wanwu_for_symbol() {
    local palace_num="$1" element="$2" map_type="$3" symbol="$4" verbose="$5"
    local map_key prefix k v i field
    local concise_fields

    case "$map_type" in
        GAN) concise_fields="五行阴阳 方位 颜色 概念 身体脏腑 性格品质 人物 形态 地理 动物 植物 器物" ;;
        STAR) concise_fields="五行 吉凶 核心描述 颜色 人物 性格品质 场所环境 身体 疾病 事业行为 占断适宜 占断不宜" ;;
        GATE) concise_fields="五行 吉凶 核心描述 颜色 人物 性格品质 场所环境 身体 疾病 事业行为 占断适宜 占断不宜" ;;
        DEITY) concise_fields="五行 吉凶 核心描述 颜色 代表人物 性格品质 场所环境 身体疾病 事件行为 占断含义" ;;
        *) concise_fields="五行 吉凶 人物" ;;
    esac

    [[ -n "$symbol" ]] || return 0

    map_key="${map_type}_${symbol}"
    dl_get_v "$map_key" 2>/dev/null || true; prefix="$_DL_RET"
    [[ -n "$prefix" ]] || return 0

    if [[ "$verbose" == "1" ]]; then
        for ((i=0; i<${#_DL_KEYS[@]}; i++)); do
            k="${_DL_KEYS[$i]}"
            if [[ "$k" == "${prefix}_"* ]]; then
                field="${k#${prefix}_}"
                v="${_DL_VALS[$i]}"
                dl_set "wanwu_${palace_num}_${element}_${field}" "$v"
            fi
        done
    else
        for field in $concise_fields; do
            dl_get_v "${prefix}_${field}" 2>/dev/null || true; v="$_DL_RET"
            if [[ -n "$v" ]]; then
                dl_set "wanwu_${palace_num}_${element}_${field}" "$v"
            fi
        done
    fi

    return 0
}

qa_lookup_wanwu() {
    local palace_num="$1"
    local verbose="${2:-0}"
    local stem_only="${3:-}"
    local star gate deity tian_gan di_gan

    [[ "$palace_num" == "5" ]] && stem_only="1"

    dl_get_v "palace_${palace_num}_tian_gan" 2>/dev/null || true; tian_gan="$_DL_RET"
    dl_get_v "palace_${palace_num}_di_gan" 2>/dev/null || true; di_gan="$_DL_RET"

    _qa_lookup_wanwu_for_symbol "$palace_num" "tian_gan" "GAN" "$tian_gan" "$verbose"
    _qa_lookup_wanwu_for_symbol "$palace_num" "di_gan" "GAN" "$di_gan" "$verbose"

    if [[ -n "$stem_only" ]]; then
        return 0
    fi

    dl_get_v "palace_${palace_num}_star" 2>/dev/null || true; star="$_DL_RET"
    dl_get_v "palace_${palace_num}_gate" 2>/dev/null || true; gate="$_DL_RET"
    dl_get_v "palace_${palace_num}_deity" 2>/dev/null || true; deity="$_DL_RET"

    _qa_lookup_wanwu_for_symbol "$palace_num" "star" "STAR" "$star" "$verbose"
    _qa_lookup_wanwu_for_symbol "$palace_num" "gate" "GATE" "$gate" "$verbose"
    _qa_lookup_wanwu_for_symbol "$palace_num" "deity" "DEITY" "$deity" "$verbose"
    return 0
}

qa_lookup_combination() {
    local palace_num="$1"
    local tian di key name jixi meaning

    dl_get_v "palace_${palace_num}_tian_gan" 2>/dev/null || true; tian="$_DL_RET"
    dl_get_v "palace_${palace_num}_di_gan" 2>/dev/null || true; di="$_DL_RET"

    if [[ -z "$tian" || -z "$di" ]]; then
        dl_set "combo_${palace_num}_key" ""
        dl_set "combo_${palace_num}_name" ""
        dl_set "combo_${palace_num}_jixi" ""
        dl_set "combo_${palace_num}_meaning" ""
        return 0
    fi

    key="${tian}加${di}"
    dl_get_v "${key}_名称" 2>/dev/null || true; name="$_DL_RET"
    dl_get_v "${key}_吉凶" 2>/dev/null || true; jixi="$_DL_RET"
    dl_get_v "${key}_含义" 2>/dev/null || true; meaning="$_DL_RET"

    dl_set "combo_${palace_num}_key" "$key"
    dl_set "combo_${palace_num}_name" "$name"
    dl_set "combo_${palace_num}_jixi" "$jixi"
    dl_set "combo_${palace_num}_meaning" "$meaning"
    return 0
}

_qa_emit_wanwu_json() {
    local fd="$1" palace_num="$2"
    local prefix="wanwu_${palace_num}_"
    local prefix_len=${#prefix}
    local i k rest element field v
    local e_first=1 f_first
    local cur_element=""

    # Collect matching entries: single O(n) scan instead of per-field lookups
    local w_elements=()
    local w_fields=()
    local w_values=()
    local w_count=0

    for ((i=0; i<${#_DL_KEYS[@]}; i++)); do
        k="${_DL_KEYS[$i]}"
        if [[ "$k" == "${prefix}"* ]]; then
            rest="${k:$prefix_len}"
            element="${rest%%_*}"
            field="${rest#*_}"
            w_elements[$w_count]="$element"
            w_fields[$w_count]="$field"
            w_values[$w_count]="${_DL_VALS[$i]}"
            w_count=$((w_count + 1))
        fi
    done

    printf '      "wanwu": {' >&"$fd"

    for element in star gate deity tian_gan di_gan; do
        f_first=1
        for ((i=0; i<w_count; i++)); do
            if [[ "${w_elements[$i]}" == "$element" ]]; then
                field="${w_fields[$i]}"
                v="${w_values[$i]}"
                if (( f_first == 1 )); then
                    if (( e_first == 0 )); then
                        printf ',' >&"$fd"
                    fi
                    e_first=0
                    printf '\n        "%s": {' "$element" >&"$fd"
                else
                    printf ',' >&"$fd"
                fi
                f_first=0
                _qa_je_v "$field"; _je1="$_JE"
                _qa_je_v "$v"; _je2="$_JE"
                printf '\n          "%s": "%s"' "$_je1" "$_je2" >&"$fd"
            fi
        done
        if (( f_first == 0 )); then
            printf '\n        }' >&"$fd"
        fi
    done

    if (( e_first == 0 )); then
        printf '\n      }' >&"$fd"
    else
        printf '}' >&"$fd"
    fi
}

_qa_emit_markers_json() {
    local fd="$1" palace_num="$2"
    local first=1 k label

    printf '      "markers": [' >&"$fd"
    for k in kong_wang yi_ma ji_xing geng rumu_gan rumu_star rumu_gate men_po star_fan_yin gate_fan_yin star_fu_yin gate_fu_yin gan_fan_yin gan_fu_yin; do
        dl_get_v "palace_${palace_num}_${k}" 2>/dev/null || continue
        if [[ "$_DL_RET" == "true" ]]; then
            case "$k" in
                kong_wang) label="空亡" ;;
                yi_ma) label="驿马" ;;
                ji_xing) label="击刑" ;;
                geng) label="庚" ;;
                rumu_gan) label="干墓" ;;
                rumu_star) label="星墓" ;;
                rumu_gate) label="门墓" ;;
                men_po) label="门迫" ;;
                star_fan_yin) label="星反吟" ;;
                gate_fan_yin) label="门反吟" ;;
                star_fu_yin) label="星伏吟" ;;
                gate_fu_yin) label="门伏吟" ;;
                gan_fan_yin) label="干反吟" ;;
                gan_fu_yin) label="干伏吟" ;;
                *) label="" ;;
            esac
            if (( first == 0 )); then
                printf ', ' >&"$fd"
            fi
            first=0
            _qa_je_v "$label"; printf '"%s"' "$_JE" >&"$fd"
        fi
    done
    printf ']' >&"$fd"
}

qa_output_analysis_text() {
    local question_type dt
    local si_year si_month si_day si_hour
    local ju_type ju_number ju_yuan
    local ri_stem ri_palace shi_stem shi_palace
    local zf_star zf_palace zs_gate zs_palace
    local kw0b kw0p kw1b kw1p ymb ymp
    local i p count ys_type ys_name ys_palace
    local name wuxing direction star gate deity tian di state
    local combo_key combo_name combo_jixi combo_meaning
    local markers boolv

    dl_get_v "question_type" 2>/dev/null || true; question_type="$_DL_RET"
    dl_get_v "plate_datetime" 2>/dev/null || true; dt="$_DL_RET"
    dl_get_v "plate_si_zhu_year" 2>/dev/null || true; si_year="$_DL_RET"
    dl_get_v "plate_si_zhu_month" 2>/dev/null || true; si_month="$_DL_RET"
    dl_get_v "plate_si_zhu_day" 2>/dev/null || true; si_day="$_DL_RET"
    dl_get_v "plate_si_zhu_hour" 2>/dev/null || true; si_hour="$_DL_RET"
    dl_get_v "plate_ju_type" 2>/dev/null || true; ju_type="$_DL_RET"
    dl_get_v "plate_ju_number" 2>/dev/null || true; ju_number="$_DL_RET"
    dl_get_v "plate_ju_yuan" 2>/dev/null || true; ju_yuan="$_DL_RET"
    dl_get_v "ri_gan_stem" 2>/dev/null || true; ri_stem="$_DL_RET"
    dl_get_v "ri_gan_palace" 2>/dev/null || true; ri_palace="$_DL_RET"
    dl_get_v "shi_gan_stem" 2>/dev/null || true; shi_stem="$_DL_RET"
    dl_get_v "shi_gan_palace" 2>/dev/null || true; shi_palace="$_DL_RET"
    dl_get_v "plate_zhi_fu_star" 2>/dev/null || true; zf_star="$_DL_RET"
    dl_get_v "plate_zhi_fu_palace" 2>/dev/null || true; zf_palace="$_DL_RET"
    dl_get_v "plate_zhi_shi_gate" 2>/dev/null || true; zs_gate="$_DL_RET"
    dl_get_v "plate_zhi_shi_palace" 2>/dev/null || true; zs_palace="$_DL_RET"
    dl_get_v "plate_kong_wang_0_branch" 2>/dev/null || true; kw0b="$_DL_RET"
    dl_get_v "plate_kong_wang_0_palace" 2>/dev/null || true; kw0p="$_DL_RET"
    dl_get_v "plate_kong_wang_1_branch" 2>/dev/null || true; kw1b="$_DL_RET"
    dl_get_v "plate_kong_wang_1_palace" 2>/dev/null || true; kw1p="$_DL_RET"
    dl_get_v "plate_yi_ma_branch" 2>/dev/null || true; ymb="$_DL_RET"
    dl_get_v "plate_yi_ma_palace" 2>/dev/null || true; ymp="$_DL_RET"

    printf '\n奇门遁甲分析\n'
    printf '问题类型: %s\n' "$question_type"
    printf '时间: %s\n' "$dt"
    printf '四柱: %s %s %s %s\n' "$si_year" "$si_month" "$si_day" "$si_hour"
    printf '局  : %s%s局 (%s)\n' "$ju_type" "$ju_number" "$ju_yuan"
    printf '日干: %s(%s宫)  时干: %s(%s宫)\n' "$ri_stem" "$ri_palace" "$shi_stem" "$shi_palace"
    printf '值符: %s(%s宫)  值使: %s(%s宫)\n' "$zf_star" "$zf_palace" "$zs_gate" "$zs_palace"
    printf '空亡: %s(%s宫) %s(%s宫)\n' "$kw0b" "$kw0p" "$kw1b" "$kw1p"
    printf '驿马: %s(%s宫)\n' "$ymb" "$ymp"

    dl_get_v "yongshen_count" 2>/dev/null || true; count="$_DL_RET"
    [[ -n "$count" ]] || count=0

    printf '\n用神:\n'
    for ((i=0; i<count; i++)); do
        dl_get_v "yongshen_${i}_name" 2>/dev/null || true; ys_name="$_DL_RET"
        dl_get_v "yongshen_${i}_type" 2>/dev/null || true; ys_type="$_DL_RET"
        dl_get_v "yongshen_${i}_palace" 2>/dev/null || true; ys_palace="$_DL_RET"
        local ys_type_cn=""
        case "$ys_type" in
            star) ys_type_cn="星" ;; gate) ys_type_cn="门" ;;
            deity) ys_type_cn="神" ;; stem) ys_type_cn="干" ;;
            *) ys_type_cn="$ys_type" ;;
        esac
        printf '  [%d] %s(%s) — %s宫\n' "$i" "$ys_name" "$ys_type_cn" "$ys_palace"
    done

    printf '\n重点格局:\n'
    for ((i=0; i<count; i++)); do
        dl_get_v "yongshen_${i}_palace" 2>/dev/null || true; ys_palace="$_DL_RET"
        [[ -n "$ys_palace" ]] || continue
        dl_get_v "palace_${ys_palace}_name" 2>/dev/null || true; name="$_DL_RET"
        dl_get_v "palace_${ys_palace}_direction" 2>/dev/null || true; direction="$_DL_RET"
        dl_get_v "combo_${ys_palace}_key" 2>/dev/null || true; combo_key="$_DL_RET"
        dl_get_v "combo_${ys_palace}_name" 2>/dev/null || true; combo_name="$_DL_RET"
        dl_get_v "combo_${ys_palace}_jixi" 2>/dev/null || true; combo_jixi="$_DL_RET"
        dl_get_v "combo_${ys_palace}_meaning" 2>/dev/null || true; combo_meaning="$_DL_RET"
        if [[ -n "$combo_key" ]]; then
            printf '  %s(%s): %s %s(%s) — %s\n' "$name" "$direction" "$combo_key" "$combo_name" "$combo_jixi" "$combo_meaning"
        fi
    done
    if [[ -n "$ri_palace" && "$ri_palace" != "0" ]]; then
        dl_get_v "palace_${ri_palace}_name" 2>/dev/null || true; name="$_DL_RET"
        dl_get_v "palace_${ri_palace}_direction" 2>/dev/null || true; direction="$_DL_RET"
        dl_get_v "combo_${ri_palace}_key" 2>/dev/null || true; combo_key="$_DL_RET"
        dl_get_v "combo_${ri_palace}_name" 2>/dev/null || true; combo_name="$_DL_RET"
        dl_get_v "combo_${ri_palace}_jixi" 2>/dev/null || true; combo_jixi="$_DL_RET"
        dl_get_v "combo_${ri_palace}_meaning" 2>/dev/null || true; combo_meaning="$_DL_RET"
        if [[ -n "$combo_key" ]]; then
            printf '  %s(%s)[日干]: %s %s(%s) — %s\n' "$name" "$direction" "$combo_key" "$combo_name" "$combo_jixi" "$combo_meaning"
        fi
    fi
    if [[ -n "$shi_palace" && "$shi_palace" != "0" ]]; then
        dl_get_v "palace_${shi_palace}_name" 2>/dev/null || true; name="$_DL_RET"
        dl_get_v "palace_${shi_palace}_direction" 2>/dev/null || true; direction="$_DL_RET"
        dl_get_v "combo_${shi_palace}_key" 2>/dev/null || true; combo_key="$_DL_RET"
        dl_get_v "combo_${shi_palace}_name" 2>/dev/null || true; combo_name="$_DL_RET"
        dl_get_v "combo_${shi_palace}_jixi" 2>/dev/null || true; combo_jixi="$_DL_RET"
        dl_get_v "combo_${shi_palace}_meaning" 2>/dev/null || true; combo_meaning="$_DL_RET"
        if [[ -n "$combo_key" ]]; then
            printf '  %s(%s)[时干]: %s %s(%s) — %s\n' "$name" "$direction" "$combo_key" "$combo_name" "$combo_jixi" "$combo_meaning"
        fi
    fi

    printf '\n逐宫分析:\n'
    for p in 4 3 8 1 6 7 2 9 5; do
        dl_get_v "palace_${p}_name" 2>/dev/null || true; name="$_DL_RET"
        dl_get_v "palace_${p}_wuxing" 2>/dev/null || true; wuxing="$_DL_RET"
        dl_get_v "palace_${p}_direction" 2>/dev/null || true; direction="$_DL_RET"
        dl_get_v "palace_${p}_tian_gan" 2>/dev/null || true; tian="$_DL_RET"
        dl_get_v "palace_${p}_di_gan" 2>/dev/null || true; di="$_DL_RET"

        if [[ "$p" == "5" ]]; then
            printf '[ %s｜%s｜%s ]\n' "$name" "$direction" "$wuxing"
            printf '  天盘: %s  地盘: %s\n' "$tian" "$di"
            dl_get_v "combo_${p}_key" 2>/dev/null || true; combo_key="$_DL_RET"
            dl_get_v "combo_${p}_name" 2>/dev/null || true; combo_name="$_DL_RET"
            dl_get_v "combo_${p}_jixi" 2>/dev/null || true; combo_jixi="$_DL_RET"
            dl_get_v "combo_${p}_meaning" 2>/dev/null || true; combo_meaning="$_DL_RET"
            if [[ -n "$combo_key" ]]; then
                printf '  组合: %s %s(%s) — %s\n' "$combo_key" "$combo_name" "$combo_jixi" "$combo_meaning"
            fi
            printf '\n'
            continue
        fi

        dl_get_v "palace_${p}_star" 2>/dev/null || true; star="$_DL_RET"
        dl_get_v "palace_${p}_gate" 2>/dev/null || true; gate="$_DL_RET"
        dl_get_v "palace_${p}_deity" 2>/dev/null || true; deity="$_DL_RET"
        dl_get_v "palace_${p}_state" 2>/dev/null || true; state="$_DL_RET"

        printf '[ %s｜%s｜%s ]\n' "$name" "$direction" "$wuxing"
        printf '  星: %s  门: %s  神: %s\n' "$star" "$gate" "$deity"
        printf '  天盘: %s  地盘: %s\n' "$tian" "$di"
        printf '  状态: %s\n' "$state"

        markers=""
        for _mk in kong_wang yi_ma ji_xing geng rumu_gan rumu_star rumu_gate men_po star_fan_yin gate_fan_yin star_fu_yin gate_fu_yin gan_fan_yin gan_fu_yin; do
            dl_get_v "palace_${p}_${_mk}" 2>/dev/null || true
            if [[ "$_DL_RET" == "true" ]]; then
                case "$_mk" in
                    kong_wang) markers="$markers [空亡]" ;; yi_ma) markers="$markers [驿马]" ;;
                    ji_xing) markers="$markers [击刑]" ;; geng) markers="$markers [庚]" ;;
                    rumu_gan) markers="$markers [干墓]" ;; rumu_star) markers="$markers [星墓]" ;;
                    rumu_gate) markers="$markers [门墓]" ;; men_po) markers="$markers [门迫]" ;;
                    star_fan_yin) markers="$markers [星反吟]" ;; gate_fan_yin) markers="$markers [门反吟]" ;;
                    star_fu_yin) markers="$markers [星伏吟]" ;; gate_fu_yin) markers="$markers [门伏吟]" ;;
                    gan_fan_yin) markers="$markers [干反吟]" ;; gan_fu_yin) markers="$markers [干伏吟]" ;;
                esac
            fi
        done
        if [[ -n "$markers" ]]; then
            printf '  格局:%s\n' "$markers"
        fi

        dl_get_v "combo_${p}_key" 2>/dev/null || true; combo_key="$_DL_RET"
        dl_get_v "combo_${p}_name" 2>/dev/null || true; combo_name="$_DL_RET"
        dl_get_v "combo_${p}_jixi" 2>/dev/null || true; combo_jixi="$_DL_RET"
        dl_get_v "combo_${p}_meaning" 2>/dev/null || true; combo_meaning="$_DL_RET"
        if [[ -n "$combo_key" ]]; then
            printf '  组合: %s %s(%s) — %s\n' "$combo_key" "$combo_name" "$combo_jixi" "$combo_meaning"
        fi

        dl_get_v "palace_${p}_is_yongshen" 2>/dev/null || true; boolv="$_DL_RET"
        if [[ "$boolv" == "true" ]]; then
            printf '  用神: 是\n'
        fi

        if [[ "$_SHOW_WANWU" == "true" ]]; then
        local prefix="wanwu_${p}_"
        local prefix_len=${#prefix}
        local has_wanwu=0
        local cur_el="" k rest el field v el_prefix el_cn
        for el in star gate deity tian_gan di_gan; do
            case "$el" in
                star) el_cn="星" ;; gate) el_cn="门" ;; deity) el_cn="神" ;;
                tian_gan) el_cn="天干" ;; di_gan) el_cn="地干" ;;
            esac
            el_prefix="${prefix}${el}_"
            local el_prefix_len=${#el_prefix}
            local el_first=1
            for ((i=0; i<${#_DL_KEYS[@]}; i++)); do
                k="${_DL_KEYS[$i]}"
                if [[ "$k" == "${el_prefix}"* ]]; then
                    v="${_DL_VALS[$i]}"
                    [[ -n "$v" ]] || continue
                    field="${k:$el_prefix_len}"
                    if (( has_wanwu == 0 )); then
                        printf '  万物类象:\n'
                        has_wanwu=1
                    fi
                    if (( el_first == 1 )); then
                        printf '    [%s]\n' "$el_cn"
                        el_first=0
                    fi
                    printf '      %s: %s\n' "$field" "$v"
                fi
            done
        done
        fi
        printf '\n'
    done
}

qa_output_analysis_json() {
    local output_path="$1"
    local source question_type dt
    local si_year si_month si_day si_hour
    local ju_type ju_number ju_yuan
    local ri_stem ri_palace shi_stem shi_palace
    local zf_star zf_palace zs_gate zs_palace
    local kw0b kw0p kw1b kw1p ymb ymp
    local i p count first kc_first ys_type ys_name ys_palace
    local name wuxing direction star gate deity tian di state
    local boolv combo_key combo_name combo_jixi combo_meaning
    local _je1 _je2 _je3 _je4

    exec 3>"$output_path" || {
        echo "ERROR: cannot write analysis JSON: $output_path" >&2
        return 1
    }

    dl_get_v "plate_source" 2>/dev/null || true; source="$_DL_RET"
    dl_get_v "question_type" 2>/dev/null || true; question_type="$_DL_RET"
    dl_get_v "plate_datetime" 2>/dev/null || true; dt="$_DL_RET"
    dl_get_v "plate_si_zhu_year" 2>/dev/null || true; si_year="$_DL_RET"
    dl_get_v "plate_si_zhu_month" 2>/dev/null || true; si_month="$_DL_RET"
    dl_get_v "plate_si_zhu_day" 2>/dev/null || true; si_day="$_DL_RET"
    dl_get_v "plate_si_zhu_hour" 2>/dev/null || true; si_hour="$_DL_RET"
    dl_get_v "plate_ju_type" 2>/dev/null || true; ju_type="$_DL_RET"
    dl_get_v "plate_ju_number" 2>/dev/null || true; ju_number="$_DL_RET"
    dl_get_v "plate_ju_yuan" 2>/dev/null || true; ju_yuan="$_DL_RET"
    dl_get_v "ri_gan_stem" 2>/dev/null || true; ri_stem="$_DL_RET"
    dl_get_v "ri_gan_palace" 2>/dev/null || true; ri_palace="$_DL_RET"
    dl_get_v "shi_gan_stem" 2>/dev/null || true; shi_stem="$_DL_RET"
    dl_get_v "shi_gan_palace" 2>/dev/null || true; shi_palace="$_DL_RET"
    dl_get_v "plate_zhi_fu_star" 2>/dev/null || true; zf_star="$_DL_RET"
    dl_get_v "plate_zhi_fu_palace" 2>/dev/null || true; zf_palace="$_DL_RET"
    dl_get_v "plate_zhi_shi_gate" 2>/dev/null || true; zs_gate="$_DL_RET"
    dl_get_v "plate_zhi_shi_palace" 2>/dev/null || true; zs_palace="$_DL_RET"
    dl_get_v "plate_kong_wang_0_branch" 2>/dev/null || true; kw0b="$_DL_RET"
    dl_get_v "plate_kong_wang_0_palace" 2>/dev/null || true; kw0p="$_DL_RET"
    dl_get_v "plate_kong_wang_1_branch" 2>/dev/null || true; kw1b="$_DL_RET"
    dl_get_v "plate_kong_wang_1_palace" 2>/dev/null || true; kw1p="$_DL_RET"
    dl_get_v "plate_yi_ma_branch" 2>/dev/null || true; ymb="$_DL_RET"
    dl_get_v "plate_yi_ma_palace" 2>/dev/null || true; ymp="$_DL_RET"

    [[ -n "$ju_number" ]] || ju_number=0
    [[ -n "$zf_palace" ]] || zf_palace=0
    [[ -n "$zs_palace" ]] || zs_palace=0
    [[ -n "$kw0p" ]] || kw0p=0
    [[ -n "$kw1p" ]] || kw1p=0
    [[ -n "$ymp" ]] || ymp=0
    [[ -n "$ri_palace" ]] || ri_palace=0
    [[ -n "$shi_palace" ]] || shi_palace=0

    printf '{\n' >&3
    _qa_je_v "$source"; printf '  "source": "%s",\n' "$_JE" >&3
    _qa_je_v "$question_type"; printf '  "question_type": "%s",\n' "$_JE" >&3
    _qa_je_v "$dt"; printf '  "datetime": "%s",\n' "$_JE" >&3
    printf '  "si_zhu": {\n' >&3
    _qa_je_v "$si_year"; printf '    "year": "%s",\n' "$_JE" >&3
    _qa_je_v "$si_month"; printf '    "month": "%s",\n' "$_JE" >&3
    _qa_je_v "$si_day"; printf '    "day": "%s",\n' "$_JE" >&3
    _qa_je_v "$si_hour"; printf '    "hour": "%s"\n' "$_JE" >&3
    printf '  },\n' >&3
    printf '  "ju": {\n' >&3
    _qa_je_v "$ju_type"; printf '    "type": "%s",\n' "$_JE" >&3
    printf '    "number": %s,\n' "$ju_number" >&3
    _qa_je_v "$ju_yuan"; printf '    "yuan": "%s"\n' "$_JE" >&3
    printf '  },\n' >&3
    _qa_je_v "$ri_stem"; printf '  "ri_gan": {"stem": "%s", "palace": %s},\n' "$_JE" "$ri_palace" >&3
    _qa_je_v "$shi_stem"; printf '  "shi_gan": {"stem": "%s", "palace": %s},\n' "$_JE" "$shi_palace" >&3

    dl_get_v "yongshen_count" 2>/dev/null || true; count="$_DL_RET"
    [[ -n "$count" ]] || count=0
    printf '  "yongshen": [' >&3
    for ((i=0; i<count; i++)); do
        dl_get_v "yongshen_${i}_type" 2>/dev/null || true; ys_type="$_DL_RET"
        dl_get_v "yongshen_${i}_name" 2>/dev/null || true; ys_name="$_DL_RET"
        dl_get_v "yongshen_${i}_palace" 2>/dev/null || true; ys_palace="$_DL_RET"
        [[ -n "$ys_palace" ]] || ys_palace=0
        if (( i > 0 )); then
            printf ',' >&3
        fi
        _qa_je_v "$ys_type"; _je1="$_JE"
        _qa_je_v "$ys_name"; _je2="$_JE"
        printf '\n    {"priority": %d, "type": "%s", "name": "%s", "palace": %s}' \
            "$i" "$_je1" "$_je2" "$ys_palace" >&3
    done
    if (( count > 0 )); then
        printf '\n' >&3
    fi
    printf '  ],\n' >&3

    _qa_je_v "$zf_star"; printf '  "zhi_fu": {"star": "%s", "palace": %s},\n' "$_JE" "$zf_palace" >&3
    _qa_je_v "$zs_gate"; printf '  "zhi_shi": {"gate": "%s", "palace": %s},\n' "$_JE" "$zs_palace" >&3
    _qa_je_v "$kw0b"; _je1="$_JE"
    _qa_je_v "$kw1b"; _je2="$_JE"
    printf '  "kong_wang": [{"branch": "%s", "palace": %s}, {"branch": "%s", "palace": %s}],\n' \
        "$_je1" "$kw0p" "$_je2" "$kw1p" >&3
    _qa_je_v "$ymb"; printf '  "yi_ma": {"branch": "%s", "palace": %s},\n' "$_JE" "$ymp" >&3

    printf '  "palaces": {\n' >&3
    first=1
    for p in 1 2 3 4 5 6 7 8 9; do
        dl_get_v "palace_${p}_name" 2>/dev/null || true; name="$_DL_RET"
        dl_get_v "palace_${p}_wuxing" 2>/dev/null || true; wuxing="$_DL_RET"
        dl_get_v "palace_${p}_direction" 2>/dev/null || true; direction="$_DL_RET"
        dl_get_v "palace_${p}_star" 2>/dev/null || true; star="$_DL_RET"
        dl_get_v "palace_${p}_gate" 2>/dev/null || true; gate="$_DL_RET"
        dl_get_v "palace_${p}_deity" 2>/dev/null || true; deity="$_DL_RET"
        dl_get_v "palace_${p}_tian_gan" 2>/dev/null || true; tian="$_DL_RET"
        dl_get_v "palace_${p}_di_gan" 2>/dev/null || true; di="$_DL_RET"
        dl_get_v "palace_${p}_state" 2>/dev/null || true; state="$_DL_RET"
        dl_get_v "palace_${p}_is_yongshen" 2>/dev/null || true; boolv="$_DL_RET"
        [[ -n "$boolv" ]] || boolv="false"
        dl_get_v "combo_${p}_key" 2>/dev/null || true; combo_key="$_DL_RET"
        dl_get_v "combo_${p}_name" 2>/dev/null || true; combo_name="$_DL_RET"
        dl_get_v "combo_${p}_jixi" 2>/dev/null || true; combo_jixi="$_DL_RET"
        dl_get_v "combo_${p}_meaning" 2>/dev/null || true; combo_meaning="$_DL_RET"

        if (( first == 0 )); then
            printf ',\n' >&3
        fi
        first=0

        printf '    "%d": {\n' "$p" >&3
        _qa_je_v "$name"; printf '      "name": "%s",\n' "$_JE" >&3
        _qa_je_v "$wuxing"; printf '      "wuxing": "%s",\n' "$_JE" >&3
        _qa_je_v "$direction"; printf '      "direction": "%s",\n' "$_JE" >&3
        _qa_je_v "$star"; printf '      "star": "%s",\n' "$_JE" >&3
        _qa_je_v "$gate"; printf '      "gate": "%s",\n' "$_JE" >&3
        _qa_je_v "$deity"; printf '      "deity": "%s",\n' "$_JE" >&3
        _qa_je_v "$tian"; printf '      "tian_gan": "%s",\n' "$_JE" >&3
        _qa_je_v "$di"; printf '      "di_gan": "%s",\n' "$_JE" >&3
        _qa_je_v "$state"; printf '      "state": "%s",\n' "$_JE" >&3
        _qa_emit_markers_json 3 "$p"
        printf ',\n' >&3
        printf '      "is_yongshen": %s,\n' "$boolv" >&3
        if [[ "$ri_palace" == "$p" ]]; then
            printf '      "is_ri_gan": true,\n' >&3
        else
            printf '      "is_ri_gan": false,\n' >&3
        fi
        if [[ "$shi_palace" == "$p" ]]; then
            printf '      "is_shi_gan": true,\n' >&3
        else
            printf '      "is_shi_gan": false,\n' >&3
        fi
        _qa_emit_wanwu_json 3 "$p"
        printf ',\n' >&3
        _qa_je_v "$combo_key"; _je1="$_JE"
        _qa_je_v "$combo_name"; _je2="$_JE"
        _qa_je_v "$combo_jixi"; _je3="$_JE"
        _qa_je_v "$combo_meaning"; _je4="$_JE"
        printf '      "combination": {"tian_di": "%s", "name": "%s", "jixi": "%s", "meaning": "%s"}\n' \
            "$_je1" "$_je2" "$_je3" "$_je4" >&3
        printf '    }' >&3
    done
    printf '\n  },\n' >&3

    printf '  "key_combinations": [' >&3
    kc_first=1
    for ((i=0; i<count; i++)); do
        dl_get_v "yongshen_${i}_palace" 2>/dev/null || true; ys_palace="$_DL_RET"
        [[ -n "$ys_palace" ]] || continue
        dl_get_v "combo_${ys_palace}_key" 2>/dev/null || true; combo_key="$_DL_RET"
        dl_get_v "combo_${ys_palace}_name" 2>/dev/null || true; combo_name="$_DL_RET"
        dl_get_v "combo_${ys_palace}_jixi" 2>/dev/null || true; combo_jixi="$_DL_RET"
        dl_get_v "combo_${ys_palace}_meaning" 2>/dev/null || true; combo_meaning="$_DL_RET"
        if (( kc_first == 0 )); then
            printf ',' >&3
        fi
        kc_first=0
        _qa_je_v "$combo_key"; _je1="$_JE"
        _qa_je_v "$combo_name"; _je2="$_JE"
        _qa_je_v "$combo_jixi"; _je3="$_JE"
        _qa_je_v "$combo_meaning"; _je4="$_JE"
        printf '\n    {"palace": %s, "role": "yongshen", "tian_di": "%s", "name": "%s", "jixi": "%s", "meaning": "%s"}' \
            "$ys_palace" "$_je1" "$_je2" "$_je3" "$_je4" >&3
    done

    if [[ -n "$ri_palace" && "$ri_palace" != "0" ]]; then
        dl_get_v "combo_${ri_palace}_key" 2>/dev/null || true; combo_key="$_DL_RET"
        dl_get_v "combo_${ri_palace}_name" 2>/dev/null || true; combo_name="$_DL_RET"
        dl_get_v "combo_${ri_palace}_jixi" 2>/dev/null || true; combo_jixi="$_DL_RET"
        dl_get_v "combo_${ri_palace}_meaning" 2>/dev/null || true; combo_meaning="$_DL_RET"
        if (( kc_first == 0 )); then
            printf ',' >&3
        fi
        kc_first=0
        _qa_je_v "$combo_key"; _je1="$_JE"
        _qa_je_v "$combo_name"; _je2="$_JE"
        _qa_je_v "$combo_jixi"; _je3="$_JE"
        _qa_je_v "$combo_meaning"; _je4="$_JE"
        printf '\n    {"palace": %s, "role": "ri_gan", "tian_di": "%s", "name": "%s", "jixi": "%s", "meaning": "%s"}' \
            "$ri_palace" "$_je1" "$_je2" "$_je3" "$_je4" >&3
    fi

    if [[ -n "$shi_palace" && "$shi_palace" != "0" ]]; then
        dl_get_v "combo_${shi_palace}_key" 2>/dev/null || true; combo_key="$_DL_RET"
        dl_get_v "combo_${shi_palace}_name" 2>/dev/null || true; combo_name="$_DL_RET"
        dl_get_v "combo_${shi_palace}_jixi" 2>/dev/null || true; combo_jixi="$_DL_RET"
        dl_get_v "combo_${shi_palace}_meaning" 2>/dev/null || true; combo_meaning="$_DL_RET"
        if (( kc_first == 0 )); then
            printf ',' >&3
        fi
        kc_first=0
        _qa_je_v "$combo_key"; _je1="$_JE"
        _qa_je_v "$combo_name"; _je2="$_JE"
        _qa_je_v "$combo_jixi"; _je3="$_JE"
        _qa_je_v "$combo_meaning"; _je4="$_JE"
        printf '\n    {"palace": %s, "role": "shi_gan", "tian_di": "%s", "name": "%s", "jixi": "%s", "meaning": "%s"}' \
            "$shi_palace" "$_je1" "$_je2" "$_je3" "$_je4" >&3
    fi

    if (( kc_first == 0 )); then
        printf '\n' >&3
    fi
    printf '  ]\n' >&3
    printf '}\n' >&3

    exec 3>&-
    return 0
}
