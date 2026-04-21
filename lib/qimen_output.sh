#!/usr/bin/env bash
# Copyright (C) 2025 — Licensed under GPL-3.0
# See https://www.gnu.org/licenses/gpl-3.0.html
# qimen_output.sh — Text grid and JSON output formatting for the Qi Men Dun Jia plate.
# Sourced AFTER data_loader.sh + qimen_engine.sh.
# Reads from global arrays populated by qm_compute_plate.

###############################################################################
# Datetime globals — set by wrapping qm_compute_plate
###############################################################################

QM_YEAR=""
QM_MONTH=""
QM_DAY=""
QM_HOUR=""
QM_MIN=""

# Wrap qm_compute_plate to capture datetime args
if declare -f qm_compute_plate >/dev/null 2>&1; then
    eval "$(echo '_qm_compute_plate_orig()'; declare -f qm_compute_plate | tail -n +2)"
    qm_compute_plate() {
        QM_YEAR="$1"
        QM_MONTH="$2"
        QM_DAY="$3"
        QM_HOUR="$4"
        QM_MIN="$5"
        _qm_compute_plate_orig "$@"
    }
fi

###############################################################################
# Internal helpers
###############################################################################

# _qm_cjk_width str — count display width (CJK=2, ASCII=1)
_qm_cjk_width() {
    local str="$1"
    local width=0 char
    local i=0 len=${#str}
    while (( i < len )); do
        char="${str:$i:1}"
        # Check byte value: CJK chars are multi-byte in UTF-8
        local byte
        byte=$(printf '%d' "'$char" 2>/dev/null) || byte=0
        if (( byte > 127 )); then
            width=$((width + 2))
        else
            width=$((width + 1))
        fi
        i=$((i + 1))
    done
    echo "$width"
}

# _qm_pad str target_width — right-pad string to target display width
_qm_pad() {
    local str="$1" target="$2"
    local w
    w=$(_qm_cjk_width "$str")
    local pad=$((target - w))
    if (( pad < 0 )); then pad=0; fi
    printf '%s' "$str"
    printf '%*s' "$pad" ""
}

# _qm_center str target_width — center string within target display width
_qm_center() {
    local str="$1" target="$2"
    local w
    w=$(_qm_cjk_width "$str")
    local total_pad=$((target - w))
    if (( total_pad < 0 )); then total_pad=0; fi
    local left=$((total_pad / 2))
    local right=$((total_pad - left))
    printf '%*s%s%*s' "$left" "" "$str" "$right" ""
}

# _qm_deity_name index — get deity name for current ju type
_qm_deity_name() {
    local idx="$1"
    if (( idx < 0 )); then
        echo ""
        return
    fi
    if [[ "$QM_JU_TYPE" == "阳遁" ]]; then
        echo "${DEITY_YANG[$idx]}"
    else
        echo "${DEITY_YIN[$idx]}"
    fi
}

# _qm_json_escape str — escape string for JSON (minimal: backslash, quote)
_qm_json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    echo "$s"
}

_qm_stem_wuxing() {
    local stem_char="$1"
    local idx
    idx=$(_qm_stem_index_by_char "$stem_char") || { echo ""; return; }
    echo "${GAN_WUXING[$idx]}"
}

_qm_branch_to_palace() {
    local branch_idx="$1"
    local branch_char="${DI_ZHI[$branch_idx]}"
    local p pdz
    for ((p=0; p<${#PALACE_DIZHI[@]}; p++)); do
        pdz="${PALACE_DIZHI[$p]}"
        [[ -z "$pdz" ]] && continue
        if [[ "$pdz" == *"$branch_char"* ]]; then
            echo $((p + 1))
            return
        fi
    done
    echo 0
}

###############################################################################
# qm_output_text — Render header + per-palace listing (分宫列出)
###############################################################################

qm_output_text() {
    # --- Header ---
    printf '奇门遁甲起局\n'
    printf '时间: %04d-%02d-%02d %02d:%02d\n' \
        "$QM_YEAR" "$QM_MONTH" "$QM_DAY" "$QM_HOUR" "$QM_MIN"

    local ygz mgz dgz hgz
    ygz=$(cal_ganzhi_name "$QM_YEAR_GZ")
    mgz=$(cal_ganzhi_name "$QM_MONTH_GZ")
    dgz=$(cal_ganzhi_name "$QM_DAY_GZ")
    hgz=$(cal_ganzhi_name "$QM_HOUR_GZ")
    printf '四柱: %s %s %s %s\n' "$ygz" "$mgz" "$dgz" "$hgz"

    local run_label=""
    if (( QM_IS_RUN == 1 )); then
        run_label=" 闰奇"
    fi
    printf '局  : %s%d局 (%s)%s\n' "$QM_JU_TYPE" "$QM_JU_NUM" "$QM_YUAN" "$run_label"
    printf '值符: %s\n' "$QM_ZHIFU_STAR"
    printf '值使: %s\n' "$QM_ZHISHI_GATE"

    local kw1 kw2 ym kw1_palace kw2_palace ym_palace
    kw1="${DI_ZHI[$QM_KONGWANG_1]}"
    kw2="${DI_ZHI[$QM_KONGWANG_2]}"
    ym="${DI_ZHI[$QM_YIMA]}"
    kw1_palace=$(_qm_branch_to_palace "$QM_KONGWANG_1")
    kw2_palace=$(_qm_branch_to_palace "$QM_KONGWANG_2")
    ym_palace=$(_qm_branch_to_palace "$QM_YIMA")
    printf '空亡: %s(%d宫) %s(%d宫)\n' \
        "$kw1" "$kw1_palace" "$kw2" "$kw2_palace"
    printf '驿马: %s(%d宫)\n' "$ym" "$ym_palace"

    # --- Per-palace listing ---
    # Directional order: 巽4(东南) 震3(正东) 艮8(东北) 坎1(正北) 乾6(西北) 兑7(正西) 坤2(西南) 离9(正南) 中5
    local _dir_order=(4 3 8 1 6 7 2 9 5)
    local p _di
    for _di in "${_dir_order[@]}"; do
        p=$_di
        printf '\n'

        local pname="${PALACE_NAMES[$((p - 1))]}"
        local pdir="${PALACE_DIRECTION[$((p - 1))]}"
        local pwuxing="${PALACE_WUXING[$((p - 1))]}"
        local pweishu="${PALACE_WEISHU[$((p - 1))]}"
        local pxiantian="${XIANTIAN_NUM[$((p - 1))]}"
        local phoutian="${HOUTIAN_NUM[$((p - 1))]}"
        local pdizhi="${PALACE_DIZHI[$((p - 1))]}"

        if (( p == 5 )); then
            printf '[ %s｜%s｜%s ]\n' "$pname" "$pdir" "$pwuxing"
            local tq_p=${QM_TIANQIN_FOLLOW_PALACE:-2}
            local tq_pname="${PALACE_NAMES[$((tq_p - 1))]}"
            printf '  天禽寄%s\n' "$tq_pname"
            printf '  地盘: %s\n' "${QM_EARTH[5]}"
            printf '  先天数: %s  后天数: %s  尾数: %s\n' "$pxiantian" "$phoutian" "${pweishu//-/,}"
            continue
        fi

        local star_idx=${QM_HEAVEN[$p]}
        local gate_idx=${QM_HUMAN[$p]}
        local deity_idx=${QM_DEITY[$p]}

        local star_name="" star_jixi=""
        if (( star_idx >= 0 && star_idx <= 8 )); then
            star_name="${STAR_NAMES[$star_idx]}"
            star_jixi="${STAR_JIXI[$star_idx]}"
        fi

        local gate_name="" gate_jixi=""
        if (( gate_idx >= 0 && gate_idx <= 8 )); then
            gate_name="${GATE_NAMES[$gate_idx]}"
            gate_jixi="${GATE_JIXI[$gate_idx]}"
        fi

        local deity_name=""
        deity_name=$(_qm_deity_name "$deity_idx")

        local tian_gan="${QM_HEAVEN_STEM[$p]}"
        local di_gan="${QM_EARTH[$p]}"
        local tian_gan_wx di_gan_wx
        tian_gan_wx=$(_qm_stem_wuxing "$tian_gan")
        di_gan_wx=$(_qm_stem_wuxing "$di_gan")

        local state="${QM_STATES[$p]}"
        if [[ "$state" == "-" ]]; then state=""; fi
        local jixing=${QM_JIXING[$p]:-0}

        # Check yi_ma for this palace
        local is_ym=""
        local ym_palace_num
        ym_palace_num=$(_qm_branch_to_palace "$QM_YIMA")
        if (( ym_palace_num == p )); then
            is_ym=" [驿马]"
        fi

        # Check kong_wang for this palace
        local is_kw=""
        local palace_dizhi="${PALACE_DIZHI[$((p - 1))]}"
        if [[ -n "$palace_dizhi" ]]; then
            local c pdz_len=${#palace_dizhi}
            for ((c=0; c<pdz_len; c++)); do
                local pch="${palace_dizhi:$c:1}"
                local bi
                bi=$(_qm_branch_index_by_char "$pch") || continue
                if (( bi == QM_KONGWANG_1 || bi == QM_KONGWANG_2 )); then
                    is_kw=" [空亡]"
                    break
                fi
            done
        fi

        printf '[ %s｜%s｜%s ]\n' "$pname" "$pdir" "$pwuxing"
        printf '  地支: %s\n' "$pdizhi"
        printf '  天盘: %s(%s)\n' "$tian_gan" "$tian_gan_wx"
        printf '  地盘: %s(%s)\n' "$di_gan" "$di_gan_wx"
        printf '  星  : %s(%s)\n' "$star_name" "$star_jixi"
        if (( QM_TIANQIN_FOLLOW_PALACE == p && star_idx != 4 )); then
            printf '  星  : 天禽(中) [寄]\n'
        fi
        printf '  门  : %s(%s)\n' "$gate_name" "$gate_jixi"
        printf '  神  : %s\n' "$deity_name"
        if [[ -n "$state" ]]; then
            printf '  状态: %s\n' "$state"
        fi
        local markers=""
        if [[ "$is_kw" == " [空亡]" ]]; then markers+=" [空亡]"; fi
        if [[ "$is_ym" == " [驿马]" ]]; then markers+=" [驿马]"; fi
        if (( jixing == 1 )); then markers+=" [击刑]"; fi
        if (( QM_GENG[p] == 1 )); then markers+=" [庚]"; fi
        if (( QM_RUMU_GAN[p] == 1 )); then markers+=" [干墓]"; fi
        if (( QM_RUMU_STAR[p] == 1 )); then markers+=" [星墓]"; fi
        if (( QM_RUMU_GATE[p] == 1 )); then markers+=" [门墓]"; fi
        if (( QM_MENPO[p] == 1 )); then markers+=" [门迫]"; fi
        if (( QM_STAR_FANYIN[p] == 1 )); then markers+=" [星反吟]"; fi
        if (( QM_GATE_FANYIN[p] == 1 )); then markers+=" [门反吟]"; fi
        if (( QM_STAR_FUYIN[p] == 1 )); then markers+=" [星伏吟]"; fi
        if (( QM_GATE_FUYIN[p] == 1 )); then markers+=" [门伏吟]"; fi
        if (( QM_GAN_FANYIN[p] == 1 )); then markers+=" [干反吟]"; fi
        if (( QM_GAN_FUYIN[p] == 1 )); then markers+=" [干伏吟]"; fi
        if [[ -n "$markers" ]]; then
            printf '  格局:%s\n' "$markers"
        fi
        printf '  先天数: %s  后天数: %s  尾数: %s\n' "$pxiantian" "$phoutian" "${pweishu//-/,}"
    done
}

###############################################################################
# qm_output_json — Output valid JSON with complete plate data
###############################################################################

_qm_generate_json() {
    local fd="${1:-1}"

    local dt
    dt=$(printf '%04d-%02d-%02d %02d:%02d' \
        "$QM_YEAR" "$QM_MONTH" "$QM_DAY" "$QM_HOUR" "$QM_MIN")

    local ygz mgz dgz hgz
    ygz=$(cal_ganzhi_name "$QM_YEAR_GZ")
    mgz=$(cal_ganzhi_name "$QM_MONTH_GZ")
    dgz=$(cal_ganzhi_name "$QM_DAY_GZ")
    hgz=$(cal_ganzhi_name "$QM_HOUR_GZ")

    local run_val="false"
    if (( QM_IS_RUN == 1 )); then
        run_val="true"
    fi

    local kw1 kw2 ym
    kw1="${DI_ZHI[$QM_KONGWANG_1]}"
    kw2="${DI_ZHI[$QM_KONGWANG_2]}"
    ym="${DI_ZHI[$QM_YIMA]}"

    # Determine zhifu palace and zhishi palace
    local zhifu_palace="$QM_ZHIFU_TARGET_PALACE"
    local zhishi_palace=0
    local g_idx="$QM_ZHISHI_GATE_INDEX"
    local p
    for ((p=1; p<=9; p++)); do
        if (( p == 5 )); then continue; fi
        if (( QM_HUMAN[p] == g_idx )); then
            zhishi_palace=$p
            break
        fi
    done

    printf '{\n' >&"$fd"
    printf '  "datetime": "%s",\n' "$(_qm_json_escape "$dt")" >&"$fd"
    printf '  "si_zhu": {\n' >&"$fd"
    printf '    "year": "%s",\n' "$(_qm_json_escape "$ygz")" >&"$fd"
    printf '    "month": "%s",\n' "$(_qm_json_escape "$mgz")" >&"$fd"
    printf '    "day": "%s",\n' "$(_qm_json_escape "$dgz")" >&"$fd"
    printf '    "hour": "%s"\n' "$(_qm_json_escape "$hgz")" >&"$fd"
    printf '  },\n' >&"$fd"
    printf '  "ju": {\n' >&"$fd"
    printf '    "type": "%s",\n' "$(_qm_json_escape "$QM_JU_TYPE")" >&"$fd"
    printf '    "number": %d,\n' "$QM_JU_NUM" >&"$fd"
    printf '    "yuan": "%s",\n' "$(_qm_json_escape "$QM_YUAN")" >&"$fd"
    printf '    "run": %s\n' "$run_val" >&"$fd"
    printf '  },\n' >&"$fd"
    printf '  "zhi_fu": {\n' >&"$fd"
    printf '    "star": "%s",\n' "$(_qm_json_escape "$QM_ZHIFU_STAR")" >&"$fd"
    printf '    "palace": %d\n' "$zhifu_palace" >&"$fd"
    printf '  },\n' >&"$fd"
    printf '  "zhi_shi": {\n' >&"$fd"
    printf '    "gate": "%s",\n' "$(_qm_json_escape "$QM_ZHISHI_GATE")" >&"$fd"
    printf '    "palace": %d\n' "$zhishi_palace" >&"$fd"
    printf '  },\n' >&"$fd"
    printf '  "kong_wang": [{"branch": "%s", "palace": %d}, {"branch": "%s", "palace": %d}],\n' \
        "$(_qm_json_escape "$kw1")" "$(_qm_branch_to_palace "$QM_KONGWANG_1")" \
        "$(_qm_json_escape "$kw2")" "$(_qm_branch_to_palace "$QM_KONGWANG_2")" >&"$fd"
    printf '  "yi_ma": {"branch": "%s", "palace": %d},\n' \
        "$(_qm_json_escape "$ym")" "$(_qm_branch_to_palace "$QM_YIMA")" >&"$fd"
    printf '  "palaces": {\n' >&"$fd"

    local first=1
    for ((p=1; p<=9; p++)); do
        if (( first == 0 )); then
            printf ',\n' >&"$fd"
        fi
        first=0

        local pname="${PALACE_NAMES[$((p - 1))]}"
        local pwuxing="${PALACE_WUXING[$((p - 1))]}"
        local pdir="${PALACE_DIRECTION[$((p - 1))]}"
        local pweishu="${PALACE_WEISHU[$((p - 1))]}"
        local pxiantian="${XIANTIAN_NUM[$((p - 1))]}"
        local phoutian="${HOUTIAN_NUM[$((p - 1))]}"
        local pdizhi="${PALACE_DIZHI[$((p - 1))]}"

        printf '    "%d": {\n' "$p" >&"$fd"
        printf '      "name": "%s",\n' "$(_qm_json_escape "$pname")" >&"$fd"
        printf '      "wuxing": "%s",\n' "$(_qm_json_escape "$pwuxing")" >&"$fd"
        printf '      "direction": "%s",\n' "$(_qm_json_escape "$pdir")" >&"$fd"
        printf '      "dizhi": "%s",\n' "$(_qm_json_escape "$pdizhi")" >&"$fd"
        printf '      "xiantian": %s,\n' "$pxiantian" >&"$fd"
        printf '      "houtian": %s,\n' "$phoutian" >&"$fd"
        printf '      "weishu": "%s"' "$(_qm_json_escape "${pweishu//-/,}")" >&"$fd"

        if (( p == 5 )); then
            local di_gan5="${QM_EARTH[5]}"
            printf ',\n      "di_gan": "%s"\n' "$(_qm_json_escape "$di_gan5")" >&"$fd"
            printf '    }' >&"$fd"
            continue
        fi

        local star_idx=${QM_HEAVEN[$p]}
        local gate_idx=${QM_HUMAN[$p]}
        local deity_idx=${QM_DEITY[$p]}

        local star_name="" star_wx="" star_jx=""
        if (( star_idx >= 0 && star_idx <= 8 )); then
            star_name="${STAR_NAMES[$star_idx]}"
            star_wx="${STAR_WUXING[$star_idx]}"
            star_jx="${STAR_JIXI[$star_idx]}"
        fi

        local gate_name="" gate_wx="" gate_jx=""
        if (( gate_idx >= 0 && gate_idx <= 8 )); then
            gate_name="${GATE_NAMES[$gate_idx]}"
            gate_wx="${GATE_WUXING[$gate_idx]}"
            gate_jx="${GATE_JIXI[$gate_idx]}"
        fi

        local deity_name=""
        deity_name=$(_qm_deity_name "$deity_idx")

        local tian_gan="${QM_HEAVEN_STEM[$p]}"
        local di_gan="${QM_EARTH[$p]}"
        local tian_gan_wx di_gan_wx
        tian_gan_wx=$(_qm_stem_wuxing "$tian_gan")
        di_gan_wx=$(_qm_stem_wuxing "$di_gan")
        local state="${QM_STATES[$p]}"
        if [[ "$state" == "-" ]]; then state=""; fi

        local is_kw="false"
        local palace_dizhi="${PALACE_DIZHI[$((p - 1))]}"
        if [[ -n "$palace_dizhi" ]]; then
            local c
            local pdz_len=${#palace_dizhi}
            for ((c=0; c<pdz_len; c++)); do
                local pch="${palace_dizhi:$c:1}"
                local bi
                bi=$(_qm_branch_index_by_char "$pch") || continue
                if (( bi == QM_KONGWANG_1 || bi == QM_KONGWANG_2 )); then
                    is_kw="true"
                    break
                fi
            done
        fi

        local is_ym="false"
        local ym_palace_num
        ym_palace_num=$(_qm_branch_to_palace "$QM_YIMA")
        if (( ym_palace_num == p )); then
            is_ym="true"
        fi

        local jixing=${QM_JIXING[$p]:-0}
        local is_jx="false"
        if (( jixing == 1 )); then is_jx="true"; fi

        local is_geng="false"
        if (( QM_GENG[p] == 1 )); then is_geng="true"; fi
        local is_rumu_gan="false"
        if (( QM_RUMU_GAN[p] == 1 )); then is_rumu_gan="true"; fi
        local is_rumu_star="false"
        if (( QM_RUMU_STAR[p] == 1 )); then is_rumu_star="true"; fi
        local is_rumu_gate="false"
        if (( QM_RUMU_GATE[p] == 1 )); then is_rumu_gate="true"; fi
        local is_menpo="false"
        if (( QM_MENPO[p] == 1 )); then is_menpo="true"; fi
        local is_star_fanyin="false"
        if (( QM_STAR_FANYIN[p] == 1 )); then is_star_fanyin="true"; fi
        local is_gate_fanyin="false"
        if (( QM_GATE_FANYIN[p] == 1 )); then is_gate_fanyin="true"; fi
        local is_star_fuyin="false"
        if (( QM_STAR_FUYIN[p] == 1 )); then is_star_fuyin="true"; fi
        local is_gate_fuyin="false"
        if (( QM_GATE_FUYIN[p] == 1 )); then is_gate_fuyin="true"; fi
        local is_gan_fanyin="false"
        if (( QM_GAN_FANYIN[p] == 1 )); then is_gan_fanyin="true"; fi
        local is_gan_fuyin="false"
        if (( QM_GAN_FUYIN[p] == 1 )); then is_gan_fuyin="true"; fi

        local is_tianqin="false"
        if (( QM_TIANQIN_FOLLOW_PALACE == p && star_idx != 4 )); then
            is_tianqin="true"
        fi

        printf ',\n' >&"$fd"
        printf '      "star": "%s",\n' "$(_qm_json_escape "$star_name")" >&"$fd"
        printf '      "star_wuxing": "%s",\n' "$(_qm_json_escape "$star_wx")" >&"$fd"
        printf '      "star_jixi": "%s",\n' "$(_qm_json_escape "$star_jx")" >&"$fd"
        printf '      "tianqin": %s,\n' "$is_tianqin" >&"$fd"
        printf '      "gate": "%s",\n' "$(_qm_json_escape "$gate_name")" >&"$fd"
        printf '      "gate_wuxing": "%s",\n' "$(_qm_json_escape "$gate_wx")" >&"$fd"
        printf '      "gate_jixi": "%s",\n' "$(_qm_json_escape "$gate_jx")" >&"$fd"
        printf '      "deity": "%s",\n' "$(_qm_json_escape "$deity_name")" >&"$fd"
        printf '      "tian_gan": "%s",\n' "$(_qm_json_escape "$tian_gan")" >&"$fd"
        printf '      "tian_gan_wuxing": "%s",\n' "$(_qm_json_escape "$tian_gan_wx")" >&"$fd"
        printf '      "di_gan": "%s",\n' "$(_qm_json_escape "$di_gan")" >&"$fd"
        printf '      "di_gan_wuxing": "%s",\n' "$(_qm_json_escape "$di_gan_wx")" >&"$fd"
        printf '      "state": "%s",\n' "$(_qm_json_escape "$state")" >&"$fd"
        printf '      "kong_wang": %s,\n' "$is_kw" >&"$fd"
        printf '      "yi_ma": %s,\n' "$is_ym" >&"$fd"
        printf '      "ji_xing": %s,\n' "$is_jx" >&"$fd"
        printf '      "geng": %s,\n' "$is_geng" >&"$fd"
        printf '      "rumu_gan": %s,\n' "$is_rumu_gan" >&"$fd"
        printf '      "rumu_star": %s,\n' "$is_rumu_star" >&"$fd"
        printf '      "rumu_gate": %s,\n' "$is_rumu_gate" >&"$fd"
        printf '      "men_po": %s,\n' "$is_menpo" >&"$fd"
        printf '      "star_fan_yin": %s,\n' "$is_star_fanyin" >&"$fd"
        printf '      "gate_fan_yin": %s,\n' "$is_gate_fanyin" >&"$fd"
        printf '      "star_fu_yin": %s,\n' "$is_star_fuyin" >&"$fd"
        printf '      "gate_fu_yin": %s,\n' "$is_gate_fuyin" >&"$fd"
        printf '      "gan_fan_yin": %s,\n' "$is_gan_fanyin" >&"$fd"
        printf '      "gan_fu_yin": %s\n' "$is_gan_fuyin" >&"$fd"
        printf '    }' >&"$fd"
    done

    printf '\n  }\n' >&"$fd"
    printf '}\n' >&"$fd"
}

qm_output_json() {
    _qm_generate_json 1
}

qm_write_json_file() {
    local filepath="$1"
    local tmpfile="${filepath}.tmp.$$"
    exec 3>"$tmpfile" || {
        echo "Error: cannot write JSON to $tmpfile" >&2
        return 1
    }
    _qm_generate_json 3
    exec 3>&-
    mv -f "$tmpfile" "$filepath" || {
        echo "Error: cannot move $tmpfile to $filepath" >&2
        rm -f "$tmpfile"
        return 1
    }
}
