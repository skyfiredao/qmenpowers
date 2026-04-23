#!/usr/bin/env bash
# Copyright (C) 2025 — Licensed under GPL-3.0
# See https://www.gnu.org/licenses/gpl-3.0.html
# qimen_event.sh — Event analysis library for qmenpowers (问事局专用).
# Sourced AFTER data_loader.sh, qimen_json.sh, and required .dat files are loaded.

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
                _qj_je_v "$field"; _je1="$_JE"
                _qj_je_v "$v"; _je2="$_JE"
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
            _qj_je_v "$label"; printf '"%s"' "$_JE" >&"$fd"
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
        printf '  神: %s  星: %s  门: %s\n' "$deity" "$star" "$gate"
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
    _qj_je_v "$source"; printf '  "source": "%s",\n' "$_JE" >&3
    _qj_je_v "$question_type"; printf '  "question_type": "%s",\n' "$_JE" >&3
    _qj_je_v "$dt"; printf '  "datetime": "%s",\n' "$_JE" >&3
    printf '  "si_zhu": {\n' >&3
    _qj_je_v "$si_year"; printf '    "year": "%s",\n' "$_JE" >&3
    _qj_je_v "$si_month"; printf '    "month": "%s",\n' "$_JE" >&3
    _qj_je_v "$si_day"; printf '    "day": "%s",\n' "$_JE" >&3
    _qj_je_v "$si_hour"; printf '    "hour": "%s"\n' "$_JE" >&3
    printf '  },\n' >&3
    printf '  "ju": {\n' >&3
    _qj_je_v "$ju_type"; printf '    "type": "%s",\n' "$_JE" >&3
    printf '    "number": %s,\n' "$ju_number" >&3
    _qj_je_v "$ju_yuan"; printf '    "yuan": "%s"\n' "$_JE" >&3
    printf '  },\n' >&3
    _qj_je_v "$ri_stem"; printf '  "ri_gan": {"stem": "%s", "palace": %s},\n' "$_JE" "$ri_palace" >&3
    _qj_je_v "$shi_stem"; printf '  "shi_gan": {"stem": "%s", "palace": %s},\n' "$_JE" "$shi_palace" >&3

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
        _qj_je_v "$ys_type"; _je1="$_JE"
        _qj_je_v "$ys_name"; _je2="$_JE"
        printf '\n    {"priority": %d, "type": "%s", "name": "%s", "palace": %s}' \
            "$i" "$_je1" "$_je2" "$ys_palace" >&3
    done
    if (( count > 0 )); then
        printf '\n' >&3
    fi
    printf '  ],\n' >&3

    _qj_je_v "$zf_star"; printf '  "zhi_fu": {"star": "%s", "palace": %s},\n' "$_JE" "$zf_palace" >&3
    _qj_je_v "$zs_gate"; printf '  "zhi_shi": {"gate": "%s", "palace": %s},\n' "$_JE" "$zs_palace" >&3
    _qj_je_v "$kw0b"; _je1="$_JE"
    _qj_je_v "$kw1b"; _je2="$_JE"
    printf '  "kong_wang": [{"branch": "%s", "palace": %s}, {"branch": "%s", "palace": %s}],\n' \
        "$_je1" "$kw0p" "$_je2" "$kw1p" >&3
    _qj_je_v "$ymb"; printf '  "yi_ma": {"branch": "%s", "palace": %s},\n' "$_JE" "$ymp" >&3

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
        _qj_je_v "$name"; printf '      "name": "%s",\n' "$_JE" >&3
        _qj_je_v "$wuxing"; printf '      "wuxing": "%s",\n' "$_JE" >&3
        _qj_je_v "$direction"; printf '      "direction": "%s",\n' "$_JE" >&3
        _qj_je_v "$star"; printf '      "star": "%s",\n' "$_JE" >&3
        _qj_je_v "$gate"; printf '      "gate": "%s",\n' "$_JE" >&3
        _qj_je_v "$deity"; printf '      "deity": "%s",\n' "$_JE" >&3
        _qj_je_v "$tian"; printf '      "tian_gan": "%s",\n' "$_JE" >&3
        _qj_je_v "$di"; printf '      "di_gan": "%s",\n' "$_JE" >&3
        _qj_je_v "$state"; printf '      "state": "%s",\n' "$_JE" >&3
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
        _qj_je_v "$combo_key"; _je1="$_JE"
        _qj_je_v "$combo_name"; _je2="$_JE"
        _qj_je_v "$combo_jixi"; _je3="$_JE"
        _qj_je_v "$combo_meaning"; _je4="$_JE"
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
        _qj_je_v "$combo_key"; _je1="$_JE"
        _qj_je_v "$combo_name"; _je2="$_JE"
        _qj_je_v "$combo_jixi"; _je3="$_JE"
        _qj_je_v "$combo_meaning"; _je4="$_JE"
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
        _qj_je_v "$combo_key"; _je1="$_JE"
        _qj_je_v "$combo_name"; _je2="$_JE"
        _qj_je_v "$combo_jixi"; _je3="$_JE"
        _qj_je_v "$combo_meaning"; _je4="$_JE"
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
        _qj_je_v "$combo_key"; _je1="$_JE"
        _qj_je_v "$combo_name"; _je2="$_JE"
        _qj_je_v "$combo_jixi"; _je3="$_JE"
        _qj_je_v "$combo_meaning"; _je4="$_JE"
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
