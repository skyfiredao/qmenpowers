#!/usr/bin/env bash
# Copyright (C) 2025 — Licensed under GPL-3.0
# See https://www.gnu.org/licenses/gpl-3.0.html
# qimen_json.sh — Shared JSON parsing and utility library for qmenpowers.
# Sourced AFTER data_loader.sh and required .dat files are loaded.

_qj_json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    echo "$s"
}

_JE=""
_qj_je_v() {
    _JE="$1"
    _JE="${_JE//\\/\\\\}"
    _JE="${_JE//\"/\\\"}"
}

_qj_extract_stem() {
    local gz="$1" g
    for g in 甲 乙 丙 丁 戊 己 庚 辛 壬 癸; do
        if [[ "$gz" == "${g}"* ]]; then
            echo "$g"
            return
        fi
    done
}

_qj_json_line_str() {
    local line="$1" v
    v="${line#*: \"}"
    v="${v%\"*}"
    echo "$v"
}

_qj_json_line_raw() {
    local line="$1" v
    v="${line#*: }"
    v="${v%,}"
    echo "$v"
}

qj_parse_plate_json() {
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
            dl_set "plate_datetime" "$(_qj_json_line_str "$line")"
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
        if [[ "$line" == *'"tianqin_host_palace": '* ]]; then
            tmp="${line#*\"tianqin_host_palace\": }"
            val="${tmp%%[^0-9]*}"
            dl_set "plate_tianqin_host_palace" "$val"
            continue
        fi

        if (( in_si_zhu == 1 )); then
            if [[ "$line" == *'}'* ]]; then
                in_si_zhu=0
                continue
            fi
            if [[ "$line" == *'"year": '* ]]; then
                dl_set "plate_si_zhu_year" "$(_qj_json_line_str "$line")"
            elif [[ "$line" == *'"month": '* ]]; then
                dl_set "plate_si_zhu_month" "$(_qj_json_line_str "$line")"
            elif [[ "$line" == *'"day": '* ]]; then
                dl_set "plate_si_zhu_day" "$(_qj_json_line_str "$line")"
            elif [[ "$line" == *'"hour": '* ]]; then
                dl_set "plate_si_zhu_hour" "$(_qj_json_line_str "$line")"
            fi
            continue
        fi

        if (( in_ju == 1 )); then
            if [[ "$line" == *'}'* ]]; then
                in_ju=0
                continue
            fi
            if [[ "$line" == *'"type": '* ]]; then
                dl_set "plate_ju_type" "$(_qj_json_line_str "$line")"
            elif [[ "$line" == *'"number": '* ]]; then
                dl_set "plate_ju_number" "$(_qj_json_line_raw "$line")"
            elif [[ "$line" == *'"yuan": '* ]]; then
                dl_set "plate_ju_yuan" "$(_qj_json_line_str "$line")"
            elif [[ "$line" == *'"run": '* ]]; then
                dl_set "plate_ju_run" "$(_qj_json_line_raw "$line")"
            fi
            continue
        fi

        if (( in_zhi_fu == 1 )); then
            if [[ "$line" == *'}'* ]]; then
                in_zhi_fu=0
                continue
            fi
            if [[ "$line" == *'"star": '* ]]; then
                dl_set "plate_zhi_fu_star" "$(_qj_json_line_str "$line")"
            elif [[ "$line" == *'"palace": '* ]]; then
                dl_set "plate_zhi_fu_palace" "$(_qj_json_line_raw "$line")"
            fi
            continue
        fi

        if (( in_zhi_shi == 1 )); then
            if [[ "$line" == *'}'* ]]; then
                in_zhi_shi=0
                continue
            fi
            if [[ "$line" == *'"gate": '* ]]; then
                dl_set "plate_zhi_shi_gate" "$(_qj_json_line_str "$line")"
            elif [[ "$line" == *'"palace": '* ]]; then
                dl_set "plate_zhi_shi_palace" "$(_qj_json_line_raw "$line")"
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
                    name|wuxing|direction|star|star_wuxing|gate|gate_wuxing|deity|tian_gan|tian_gan_wuxing|di_gan|di_gan_wuxing|state|tianqin_stem|tianqin_stem_wuxing)
                        val="$(_qj_json_line_str "$line")"
                        dl_set "$qkey" "$val"
                        ;;
                    kong_wang|yi_ma|ji_xing|geng|rumu_gan|rumu_star|rumu_gate|men_po|star_fan_yin|gate_fan_yin|star_fu_yin|gate_fu_yin|gan_fan_yin|gan_fu_yin|tianqin)
                        val="$(_qj_json_line_raw "$line")"
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

qj_find_ri_gan_palace() {
    local day_gz stem p di
    dl_get_v "plate_si_zhu_day" 2>/dev/null || true; day_gz="$_DL_RET"
    stem="$(_qj_extract_stem "$day_gz")"
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

qj_find_shi_gan_palace() {
    local hour_gz stem p di
    dl_get_v "plate_si_zhu_hour" 2>/dev/null || true; hour_gz="$_DL_RET"
    stem="$(_qj_extract_stem "$hour_gz")"
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

_qj_lookup_wanwu_for_symbol() {
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

qj_lookup_wanwu() {
    local palace_num="$1"
    local verbose="${2:-0}"
    local stem_only="${3:-}"
    local star gate deity tian_gan di_gan

    [[ "$palace_num" == "5" ]] && stem_only="1"

    dl_get_v "palace_${palace_num}_tian_gan" 2>/dev/null || true; tian_gan="$_DL_RET"
    dl_get_v "palace_${palace_num}_di_gan" 2>/dev/null || true; di_gan="$_DL_RET"

    _qj_lookup_wanwu_for_symbol "$palace_num" "tian_gan" "GAN" "$tian_gan" "$verbose"
    _qj_lookup_wanwu_for_symbol "$palace_num" "di_gan" "GAN" "$di_gan" "$verbose"

    if [[ -n "$stem_only" ]]; then
        return 0
    fi

    dl_get_v "palace_${palace_num}_star" 2>/dev/null || true; star="$_DL_RET"
    dl_get_v "palace_${palace_num}_gate" 2>/dev/null || true; gate="$_DL_RET"
    dl_get_v "palace_${palace_num}_deity" 2>/dev/null || true; deity="$_DL_RET"

    _qj_lookup_wanwu_for_symbol "$palace_num" "star" "STAR" "$star" "$verbose"
    _qj_lookup_wanwu_for_symbol "$palace_num" "gate" "GATE" "$gate" "$verbose"
    _qj_lookup_wanwu_for_symbol "$palace_num" "deity" "DEITY" "$deity" "$verbose"
    return 0
}
