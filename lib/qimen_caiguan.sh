#!/usr/bin/env bash
# Copyright (C) 2025 — Licensed under GPL-3.0
# See https://www.gnu.org/licenses/gpl-3.0.html
# qimen_caiguan.sh — 财官诊断 analysis library.
# Sourced AFTER qimen_banmenhuaqizhen.sh (for hq_* helpers).

# --- Text accumulation arrays ---
# Format: "name|desc|palace|yr_display|lh_display|liuhai_count|type"
_HQ_CAIFU_TEXT=()
_HQ_SHIYE_TEXT=()
# Format: "stem|palace|liuhai_str|wuhe_note"
_HQ_GANCAI_TEXT_HEADER=()
_HQ_GANCAI_TEXT_STEMS=()
# Format: "label|name|palace|liuhai_str"
_HQ_FUSHI_TEXT=()
# Format: "role|desc|stem|palace|liuhai_str"
_HQ_TIANGAN_ROLES_TEXT=()

# --- Lookup star/gate auspiciousness ---
_hq_star_jixi() {
    local name="$1"
    local i=0
    while [[ $i -lt ${#STAR_NAMES[@]} ]]; do
        if [[ "${STAR_NAMES[$i]}" == "$name" ]]; then
            echo "${STAR_JIXI[$i]}"
            return
        fi
        i=$((i + 1))
    done
    echo ""
}

_hq_gate_jixi() {
    local name="$1"
    local i=0
    while [[ $i -lt ${#GATE_NAMES[@]} ]]; do
        if [[ "${GATE_NAMES[$i]}" == "$name" ]]; then
            echo "${GATE_JIXI[$i]}"
            return
        fi
        i=$((i + 1))
    done
    echo ""
}

_hq_stem_wuxing() {
    case "$1" in
        甲|乙) echo "木";; 丙|丁) echo "火";; 戊|己) echo "土";;
        庚|辛) echo "金";; 壬|癸) echo "水";; *) echo "";;
    esac
}

_hq_star_wuxing() {
    local name="$1"
    local i=0
    while [[ $i -lt ${#STAR_NAMES[@]} ]]; do
        if [[ "${STAR_NAMES[$i]}" == "$name" ]]; then
            echo "${STAR_WUXING[$i]}"
            return
        fi
        i=$((i + 1))
    done
    echo ""
}

_hq_gate_wuxing() {
    local name="$1"
    local i=0
    while [[ $i -lt ${#GATE_NAMES[@]} ]]; do
        if [[ "${GATE_NAMES[$i]}" == "$name" ]]; then
            echo "${GATE_WUXING[$i]}"
            return
        fi
        i=$((i + 1))
    done
    echo ""
}

# --- Print palace detail block (indented) ---
# Outputs: 天盘, 地盘, 星(吉凶), 门(吉凶), 神 — each on its own line
_hq_print_palace_detail() {
    local p="$1"
    local indent="${2:-    }"

    dl_get_v "palace_${p}_tian_gan" 2>/dev/null || true; local tg="$_DL_RET"
    dl_get_v "palace_${p}_di_gan" 2>/dev/null || true; local dg="$_DL_RET"
    dl_get_v "palace_${p}_star" 2>/dev/null || true; local star="$_DL_RET"
    dl_get_v "palace_${p}_gate" 2>/dev/null || true; local gate="$_DL_RET"
    dl_get_v "palace_${p}_deity" 2>/dev/null || true; local deity="$_DL_RET"

    local tg_wx="" dg_wx=""
    tg_wx="$(_hq_stem_wuxing "$tg")"
    dg_wx="$(_hq_stem_wuxing "$dg")"

    local star_jx="" star_wx=""
    if [[ -n "$star" ]]; then
        star_jx="$(_hq_star_jixi "$star")"
        star_wx="$(_hq_star_wuxing "$star")"
    fi
    local gate_jx="" gate_wx=""
    if [[ -n "$gate" ]]; then
        gate_jx="$(_hq_gate_jixi "$gate")"
        gate_wx="$(_hq_gate_wuxing "$gate")"
    fi

    if [[ -n "$tg_wx" ]]; then
        printf '%s天盘: %s(%s)\n' "$indent" "$tg" "$tg_wx"
    else
        printf '%s天盘: %s\n' "$indent" "$tg"
    fi
    if [[ -n "$dg_wx" ]]; then
        printf '%s地盘: %s(%s)\n' "$indent" "$dg" "$dg_wx"
    else
        printf '%s地盘: %s\n' "$indent" "$dg"
    fi
    if [[ -n "$star_wx" && -n "$star_jx" ]]; then
        printf '%s星: %s(%s,%s)\n' "$indent" "$star" "$star_wx" "$star_jx"
    elif [[ -n "$star_jx" ]]; then
        printf '%s星: %s(%s)\n' "$indent" "$star" "$star_jx"
    else
        printf '%s星: %s\n' "$indent" "$star"
    fi
    if [[ -n "$gate_wx" && -n "$gate_jx" ]]; then
        printf '%s门: %s(%s,%s)\n' "$indent" "$gate" "$gate_wx" "$gate_jx"
    elif [[ -n "$gate_jx" ]]; then
        printf '%s门: %s(%s)\n' "$indent" "$gate" "$gate_jx"
    else
        printf '%s门: %s\n' "$indent" "$gate"
    fi
    printf '%s神: %s\n' "$indent" "$deity"
}

# --- Build palace label: 八卦N宫(方位·五行) ---
_hq_palace_label() {
    local p="$1"
    if [[ $p -le 0 ]]; then
        echo "不在盘上"
        return
    fi
    if [[ $p -eq 5 ]]; then
        echo "中5宫(中,土)"
        return
    fi
    local bgua=""
    case $p in
        1) bgua="坎";; 2) bgua="坤";; 3) bgua="震";; 4) bgua="巽";;
        6) bgua="乾";; 7) bgua="兑";; 8) bgua="艮";; 9) bgua="离";;
    esac
    dl_get_v "palace_${p}_direction" 2>/dev/null || true; local pdir="$_DL_RET"
    dl_get_v "palace_${p}_wuxing" 2>/dev/null || true; local pwx="$_DL_RET"
    echo "${bgua}${p}宫(${pdir},${pwx})"
}

# --- Print per-palace buzhen plan (if available) ---
_hq_print_buzhen_for_palace() {
    local p="$1"
    local indent="${2:-    }"
    local plan="${_BZ_PAL_PLAN_TEXT[$p]:-}"
    if [[ -z "$plan" ]]; then
        return
    fi
    local line="" min_spaces=999
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local stripped="${line#"${line%%[! ]*}"}"
        local leading_len=$(( ${#line} - ${#stripped} ))
        if [[ $leading_len -lt $min_spaces ]]; then
            min_spaces=$leading_len
        fi
    done <<< "$plan"
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local stripped="${line#"${line%%[! ]*}"}"
        local leading_len=$(( ${#line} - ${#stripped} ))
        local relative_indent=$(( leading_len - min_spaces ))
        local pad=""
        local ri=0
        while [[ $ri -lt $relative_indent ]]; do
            pad="${pad} "
            ri=$((ri + 1))
        done
        printf '%s%s%s\n' "$indent" "$pad" "$stripped"
    done <<< "$plan"
}

# --- Analyze one 要害 element ---
_HQ_YAOHAI_JSON_ITEMS=()
_HQ_YAOHAI_TEXT_ITEMS=()
hq_analyze_yaohai() {
    local idx="$1" prefix="$2"
    local yh_name yh_type yh_desc palace

    eval "yh_name=\"\${${prefix}_${idx}_name:-}\""
    eval "yh_type=\"\${${prefix}_${idx}_type:-}\""
    eval "yh_desc=\"\${${prefix}_${idx}_desc:-}\""

    local palace_json="null"
    local liuhai_str="" liuhai_count=0
    local yuegling_rel=""

    if [[ "$yh_type" == "special" ]]; then
        _hq_je_v "$yh_name"; local j_name="$_JE"
        _hq_je_v "$yh_desc"; local j_desc="$_JE"
        _HQ_YAOHAI_JSON_ITEMS+=("{ \"name\": \"${j_name}\", \"type\": \"${yh_type}\", \"desc\": \"${j_desc}\", \"palace\": null, \"palace_info\": null, \"liuhai\": \"\", \"liuhai_count\": 0, \"yuegling_relation\": \"\" }")
        _HQ_YAOHAI_TEXT_ITEMS+=("${yh_name}|${yh_desc}|0|||0|special")
        return
    fi

    hq_locate_symbol "$yh_name" "$yh_type"
    palace=$_HQ_FOUND_PALACE

    if [[ $palace -gt 0 && $palace -ne 5 ]]; then
        hq_detect_liuhai "$palace"
        liuhai_str="$_HQ_LIUHAI"
        liuhai_count=$_HQ_LIUHAI_COUNT

        dl_get_v "palace_${palace}_wuxing" 2>/dev/null || true
        local pal_wx="$_DL_RET"
        if [[ -n "$HQ_YUEGLING_WX" && -n "$pal_wx" ]]; then
            yuegling_rel="$(hq_wuxing_relation "$HQ_YUEGLING_WX" "$pal_wx")"
        fi

        hq_palace_summary_json "$palace"
        palace_json="{ $_HQ_PAL_JSON }"
    fi

    _hq_je_v "$yh_name"; local j_name="$_JE"
    _hq_je_v "$yh_desc"; local j_desc="$_JE"
    _hq_je_v "$liuhai_str"; local j_lh="$_JE"
    _hq_je_v "$yuegling_rel"; local j_yr="$_JE"
    local yuegling_cn=""
    if [[ -n "$yuegling_rel" ]]; then
        yuegling_cn="$(hq_wuxing_relation_cn "$yuegling_rel")"
    fi
    _hq_je_v "$yuegling_cn"; local j_yrcn="$_JE"

    _HQ_YAOHAI_JSON_ITEMS+=("{ \"name\": \"${j_name}\", \"type\": \"${yh_type}\", \"desc\": \"${j_desc}\", \"palace\": ${palace}, \"palace_info\": ${palace_json}, \"liuhai\": \"${j_lh}\", \"liuhai_count\": ${liuhai_count}, \"yuegling_relation\": \"${j_yr}\", \"yuegling_relation_cn\": \"${j_yrcn}\" }")

    local yr_display=""
    if [[ -n "$yuegling_cn" ]]; then
        yr_display="${yuegling_cn}"
    fi
    _HQ_YAOHAI_TEXT_ITEMS+=("${yh_name}|${yh_desc}|${palace}|${yr_display}|${liuhai_str}|${liuhai_count}|${yh_type}")
}

# --- Analyze 干财 stems in the plate ---
_HQ_GANCAI_JSON=""
hq_analyze_gan_cai() {
    local ri_cai nian_cai items=""
    dl_get_v "hq_ri_gan_cai" 2>/dev/null || true; ri_cai="$_DL_RET"
    dl_get_v "hq_nian_gan_cai" 2>/dev/null || true; nian_cai="$_DL_RET"
    dl_get_v "hq_ri_gan" 2>/dev/null || true; local ri_gan="$_DL_RET"
    dl_get_v "hq_nian_gan" 2>/dev/null || true; local nian_gan="$_DL_RET"

    _HQ_GANCAI_TEXT_HEADER=()
    _HQ_GANCAI_TEXT_HEADER+=("日干: ${ri_gan} → 财干: ${ri_cai}")
    _HQ_GANCAI_TEXT_HEADER+=("年干: ${nian_gan} → 财干: ${nian_cai}")

    _HQ_GANCAI_TEXT_STEMS=()

    local all_cai_stems=""
    local IFS=','
    local seen=""

    for s in $ri_cai; do
        if [[ ",$seen," != *",$s,"* ]]; then
            seen="${seen:+${seen},}${s}"
        fi
    done
    for s in $nian_cai; do
        if [[ ",$seen," != *",$s,"* ]]; then
            seen="${seen:+${seen},}${s}"
        fi
    done

    local first=1
    IFS=','
    for stem in $seen; do
        hq_find_stem_palace "$stem"
        local di_palace=$_HQ_FOUND_PALACE
        hq_find_stem_palace_tian "$stem"
        local tian_palace=$_HQ_FOUND_PALACE

        local use_palace=0
        if [[ $di_palace -gt 0 ]]; then
            use_palace=$di_palace
        elif [[ $tian_palace -gt 0 ]]; then
            use_palace=$tian_palace
        fi

        local liuhai_str="" liuhai_count=0 palace_json="null"
        if [[ $use_palace -gt 0 && $use_palace -ne 5 ]]; then
            hq_detect_liuhai "$use_palace"
            liuhai_str="$_HQ_LIUHAI"
            liuhai_count=$_HQ_LIUHAI_COUNT
            hq_palace_summary_json "$use_palace"
            palace_json="{ $_HQ_PAL_JSON }"
        fi

        local is_ri=false is_nian=false
        if [[ ",$ri_cai," == *",$stem,"* ]]; then is_ri=true; fi
        if [[ ",$nian_cai," == *",$stem,"* ]]; then is_nian=true; fi

        _hq_je_v "$stem"; local j_stem="$_JE"
        _hq_je_v "$liuhai_str"; local j_lh="$_JE"

        local wuhe_alt=""
        if [[ $use_palace -eq 0 ]]; then
            # 缺甲找值符：笔记L369 "甲合己，缺甲找值符"
            # 当缺甲时，不找己，而是找值符所在宫的天盘天干
            if [[ "$stem" == "甲" ]]; then
                dl_get_v "plate_zhi_fu_palace" 2>/dev/null || true
                local zf_pal="$_DL_RET"
                if [[ -n "$zf_pal" && "$zf_pal" -gt 0 ]]; then
                    dl_get_v "palace_${zf_pal}_tian_gan" 2>/dev/null || true
                    wuhe_alt="$_DL_RET"
                fi
            else
                dl_get_v "wuhe_${stem}" 2>/dev/null || true; wuhe_alt="$_DL_RET"
            fi
            if [[ -n "$wuhe_alt" ]]; then
                hq_find_stem_palace "$wuhe_alt"
                local alt_p=$_HQ_FOUND_PALACE
                if [[ $alt_p -eq 0 ]]; then
                    hq_find_stem_palace_tian "$wuhe_alt"
                    alt_p=$_HQ_FOUND_PALACE
                fi
                if [[ $alt_p -gt 0 ]]; then
                    use_palace=$alt_p
                    if [[ $use_palace -ne 5 ]]; then
                        hq_detect_liuhai "$use_palace"
                        liuhai_str="$_HQ_LIUHAI"
                        liuhai_count=$_HQ_LIUHAI_COUNT
                        hq_palace_summary_json "$use_palace"
                        palace_json="{ $_HQ_PAL_JSON }"
                        _hq_je_v "$liuhai_str"; j_lh="$_JE"
                    fi
                fi
            fi
        fi

        _hq_je_v "$wuhe_alt"; local j_wuhe="$_JE"

        local wuhe_note=""
        if [[ -n "$wuhe_alt" && $di_palace -eq 0 && $tian_palace -eq 0 ]]; then
            if [[ "$stem" == "甲" ]]; then
                wuhe_note="值符宫干→${wuhe_alt}"
            else
                wuhe_note="五合→${wuhe_alt}"
            fi
        fi
        # Format: "stem|palace|liuhai_str|wuhe_note"
        _HQ_GANCAI_TEXT_STEMS+=("${stem}|${use_palace}|${liuhai_str}|${wuhe_note}")

        (( first )) || items="${items},"
        first=0
        items="${items}
      { \"stem\": \"${j_stem}\", \"is_ri_gan_cai\": ${is_ri}, \"is_nian_gan_cai\": ${is_nian}, \"palace\": ${use_palace}, \"palace_info\": ${palace_json}, \"liuhai\": \"${j_lh}\", \"liuhai_count\": ${liuhai_count}, \"wuhe_alt\": \"${j_wuhe}\" }"
    done

    _hq_je_v "$ri_gan"; local j_ri="$_JE"
    _hq_je_v "$nian_gan"; local j_nian="$_JE"
    _hq_je_v "$ri_cai"; local j_rc="$_JE"
    _hq_je_v "$nian_cai"; local j_nc="$_JE"

    _HQ_GANCAI_JSON="{ \"ri_gan\": \"${j_ri}\", \"ri_gan_cai\": \"${j_rc}\", \"nian_gan\": \"${j_nian}\", \"nian_gan_cai\": \"${j_nc}\", \"stems\": [${items}
    ] }"
}

# --- Derive industry from 戊's palace (star/gate/deity/stem) ---
_HQ_HANGYE_PALACE=0
_HQ_HANGYE_STAR=""
_HQ_HANGYE_GATE=""
_HQ_HANGYE_DEITY=""
_HQ_HANGYE_TIAN_GAN=""
_HQ_HANGYE_MATCHED=()
_HQ_HANGYE_STAR_CAREER=""
_HQ_HANGYE_JSON="null"

_hq_hangye_sym_at_palace() {
    local sym_type="$1" sym_name="$2"
    case "$sym_type" in
        star) [[ "$_HQ_HANGYE_STAR" == "$sym_name" ]] && return 0 ;;
        gate) [[ "$_HQ_HANGYE_GATE" == "$sym_name" ]] && return 0 ;;
        deity) [[ "$_HQ_HANGYE_DEITY" == "$sym_name" ]] && return 0 ;;
        stem) [[ "$_HQ_HANGYE_TIAN_GAN" == "$sym_name" ]] && return 0 ;;
    esac
    return 1
}

hq_derive_hangye() {
    _HQ_HANGYE_PALACE=0
    _HQ_HANGYE_STAR=""
    _HQ_HANGYE_GATE=""
    _HQ_HANGYE_DEITY=""
    _HQ_HANGYE_TIAN_GAN=""
    _HQ_HANGYE_MATCHED=()
    _HQ_HANGYE_STAR_CAREER=""
    _HQ_HANGYE_JSON="null"

    hq_find_stem_palace "戊"
    local p=$_HQ_FOUND_PALACE
    [[ $p -le 0 ]] && return
    _HQ_HANGYE_PALACE=$p

    if [[ $p -eq 5 ]]; then return; fi

    dl_get_v "palace_${p}_star" 2>/dev/null || true; _HQ_HANGYE_STAR="$_DL_RET"
    dl_get_v "palace_${p}_gate" 2>/dev/null || true; _HQ_HANGYE_GATE="$_DL_RET"
    dl_get_v "palace_${p}_deity" 2>/dev/null || true; _HQ_HANGYE_DEITY="$_DL_RET"
    dl_get_v "palace_${p}_tian_gan" 2>/dev/null || true; _HQ_HANGYE_TIAN_GAN="$_DL_RET"

    if [[ -n "$_HQ_HANGYE_STAR" ]]; then
        dl_get_v "${_HQ_HANGYE_STAR}_行业" 2>/dev/null || true
        _HQ_HANGYE_STAR_CAREER="$_DL_RET"
    fi

    local key val job_name
    local i=0
    while [[ $i -lt ${#_DL_KEYS[@]} ]]; do
        key="${_DL_KEYS[$i]}"
        val="${_DL_VALS[$i]}"
        i=$((i + 1))
        [[ "$key" != hangye_* ]] && continue
        job_name="${key#hangye_}"
        [[ -z "$val" ]] && continue

        local IFS=',' arr
        read -ra arr <<< "$val"
        local j=0 all_match=1
        while [[ $j -lt ${#arr[@]} ]]; do
            local st="${arr[$j]}"
            local sn="${arr[$((j+1))]}"
            j=$((j + 2))
            if ! _hq_hangye_sym_at_palace "$st" "$sn"; then
                all_match=0
                break
            fi
        done
        if [[ $all_match -eq 1 ]]; then
            _HQ_HANGYE_MATCHED+=("$job_name")
        fi
    done

    local matched_str=""
    local mi=0
    while [[ $mi -lt ${#_HQ_HANGYE_MATCHED[@]} ]]; do
        [[ $mi -gt 0 ]] && matched_str="${matched_str},"
        _hq_je_v "${_HQ_HANGYE_MATCHED[$mi]}"; matched_str="${matched_str}\"${_JE}\""
        mi=$((mi + 1))
    done
    _hq_je_v "$_HQ_HANGYE_STAR"; local j_s="$_JE"
    _hq_je_v "$_HQ_HANGYE_GATE"; local j_g="$_JE"
    _hq_je_v "$_HQ_HANGYE_DEITY"; local j_d="$_JE"
    _hq_je_v "$_HQ_HANGYE_TIAN_GAN"; local j_tg="$_JE"
    _hq_je_v "$_HQ_HANGYE_STAR_CAREER"; local j_sc="$_JE"
    _HQ_HANGYE_JSON="{ \"palace\": ${p}, \"star\": \"${j_s}\", \"gate\": \"${j_g}\", \"deity\": \"${j_d}\", \"tian_gan\": \"${j_tg}\", \"star_career\": \"${j_sc}\", \"matched\": [${matched_str}] }"
}

# --- Locate 符使 (zhifu + zhishi) ---
_HQ_FUSHI_JSON=""
hq_analyze_fushi() {
    dl_get_v "plate_zhi_fu_star" 2>/dev/null || true; local zf_star="$_DL_RET"
    dl_get_v "plate_zhi_fu_palace" 2>/dev/null || true; local zf_palace="$_DL_RET"
    dl_get_v "plate_zhi_shi_gate" 2>/dev/null || true; local zs_gate="$_DL_RET"
    dl_get_v "plate_zhi_shi_palace" 2>/dev/null || true; local zs_palace="$_DL_RET"

    local zf_liuhai="" zf_lh_count=0 zs_liuhai="" zs_lh_count=0
    if [[ -n "$zf_palace" && "$zf_palace" -gt 0 && "$zf_palace" -ne 5 ]]; then
        hq_detect_liuhai "$zf_palace"
        zf_liuhai="$_HQ_LIUHAI"
        zf_lh_count=$_HQ_LIUHAI_COUNT
    fi
    if [[ -n "$zs_palace" && "$zs_palace" -gt 0 && "$zs_palace" -ne 5 ]]; then
        hq_detect_liuhai "$zs_palace"
        zs_liuhai="$_HQ_LIUHAI"
        zs_lh_count=$_HQ_LIUHAI_COUNT
    fi

    _hq_je_v "$zf_star"; local j_zfs="$_JE"
    _hq_je_v "$zs_gate"; local j_zsg="$_JE"
    _hq_je_v "$zf_liuhai"; local j_zflh="$_JE"
    _hq_je_v "$zs_liuhai"; local j_zslh="$_JE"

    _HQ_FUSHI_JSON="{ \"zhi_fu\": { \"star\": \"${j_zfs}\", \"palace\": ${zf_palace:-0}, \"liuhai\": \"${j_zflh}\", \"liuhai_count\": ${zf_lh_count} }, \"zhi_shi\": { \"gate\": \"${j_zsg}\", \"palace\": ${zs_palace:-0}, \"liuhai\": \"${j_zslh}\", \"liuhai_count\": ${zs_lh_count} } }"

    # Format: "label|name|palace|liuhai_str"
    _HQ_FUSHI_TEXT=()
    _HQ_FUSHI_TEXT+=("值符|${zf_star}|${zf_palace:-0}|${zf_liuhai}")
    _HQ_FUSHI_TEXT+=("值使|${zs_gate}|${zs_palace:-0}|${zs_liuhai}")
}

# --- Locate 诸天干 roles ---
_HQ_TIANGAN_ROLES_JSON=""
hq_analyze_tiangan_roles() {
    local year_gz month_gz hour_gz
    dl_get_v "plate_si_zhu_year" 2>/dev/null || true; year_gz="$_DL_RET"
    dl_get_v "plate_si_zhu_month" 2>/dev/null || true; month_gz="$_DL_RET"
    dl_get_v "plate_si_zhu_hour" 2>/dev/null || true; hour_gz="$_DL_RET"

    local year_stem month_stem hour_stem
    year_stem="$(_hq_extract_stem "$year_gz")"
    month_stem="$(_hq_extract_stem "$month_gz")"
    hour_stem="$(_hq_extract_stem "$hour_gz")"

    local items="" first=1
    local role stem
    _HQ_TIANGAN_ROLES_TEXT=()
    for role_stem in "年干_大老板_${year_stem}" "月干_同事_${month_stem}" "时干_下属_${hour_stem}"; do
        local IFS='_'
        read -r role desc stem <<< "$role_stem"
        IFS=','

        hq_find_stem_palace "$stem"
        local p=$_HQ_FOUND_PALACE
        if [[ $p -eq 0 ]]; then
            hq_find_stem_palace_tian "$stem"
            p=$_HQ_FOUND_PALACE
        fi

        local liuhai_str="" liuhai_count=0
        if [[ $p -gt 0 && $p -ne 5 ]]; then
            hq_detect_liuhai "$p"
            liuhai_str="$_HQ_LIUHAI"
            liuhai_count=$_HQ_LIUHAI_COUNT
        fi

        _hq_je_v "$role"; local j_role="$_JE"
        _hq_je_v "$desc"; local j_desc="$_JE"
        _hq_je_v "$stem"; local j_stem="$_JE"
        _hq_je_v "$liuhai_str"; local j_lh="$_JE"

        (( first )) || items="${items},"
        first=0
        items="${items}
      { \"role\": \"${j_role}\", \"desc\": \"${j_desc}\", \"stem\": \"${j_stem}\", \"palace\": ${p}, \"liuhai\": \"${j_lh}\", \"liuhai_count\": ${liuhai_count} }"

        # Format: "role|desc|stem|palace|liuhai_str"
        _HQ_TIANGAN_ROLES_TEXT+=("${role}|${desc}|${stem}|${p}|${liuhai_str}")
    done

    _HQ_TIANGAN_ROLES_JSON="[${items}
    ]"
}

# --- Output one yaohai item in palace-centric format ---
_hq_special_section_name() {
    local name="$1"
    case "$name" in
        月令) echo "月令(见上方「月令(大环境,天时)」)" ;;
        行业) echo "行业(见下方「适合行业」章节)" ;;
        干财) echo "干财(见下方「干财」章节)" ;;
        符使) echo "符使(见下方「符使」章节)" ;;
        诸天干) echo "天干角色(见下方「天干角色」章节)" ;;
        *) echo "${name}(见下方)" ;;
    esac
}

_hq_output_yaohai_item() {
    local line="$1"
    local show_buzhen="$2"
    local indent="  "
    local sub_indent="    "

    local IFS='|'
    read -r t_name t_desc t_palace t_yr t_lh t_lhc t_type <<< "$line"

    if [[ "$t_type" == "special" ]]; then
        return
    fi

    if [[ "$t_palace" -le 0 ]]; then
        return
    fi

    local pal_label
    pal_label="$(_hq_palace_label "$t_palace")"
    printf '\n%s%s(%s) — %s\n' "$indent" "$t_name" "$t_desc" "$pal_label"

    # 特定要害项的上下文说明
    if [[ "$t_name" == "时干" ]]; then
        printf '%s正确的时间做正确的事\n' "$sub_indent"
    fi

    if [[ "$t_palace" -ne 5 ]]; then
        _hq_print_palace_detail "$t_palace" "$sub_indent"
        if [[ -n "$t_lh" ]]; then
            printf '%s六害: %s\n' "$sub_indent" "$(_bz_format_liuhai_brackets "$t_lh")"
        fi
        if [[ -n "$t_yr" ]]; then
            printf '%s月令关系: %s\n' "$sub_indent" "$t_yr"
        fi
        if [[ "$show_buzhen" == "true" ]]; then
            local plan="${_BZ_PAL_PLAN_TEXT[$t_palace]:-}"
            if [[ -n "$plan" ]]; then
                printf '%s化解:\n' "$sub_indent"
                _hq_print_buzhen_for_palace "$t_palace" "${sub_indent}  "
            fi
        fi
    fi
}

# --- Output a section with palace detail for item with palace ---
_hq_output_palace_item() {
    local label="$1"
    local p="$2"
    local liuhai_str="$3"
    local extra_note="$4"
    local show_buzhen="$5"
    local indent="  "
    local sub_indent="    "

    if [[ "$p" -le 0 ]]; then
        return
    fi

    local pal_label
    pal_label="$(_hq_palace_label "$p")"

    if [[ -n "$extra_note" ]]; then
        printf '\n%s%s — %s (%s)\n' "$indent" "$label" "$pal_label" "$extra_note"
    else
        printf '\n%s%s — %s\n' "$indent" "$label" "$pal_label"
    fi

    if [[ "$p" -ne 5 ]]; then
        _hq_print_palace_detail "$p" "$sub_indent"
        if [[ -n "$liuhai_str" ]]; then
            printf '%s六害: %s\n' "$sub_indent" "$(_bz_format_liuhai_brackets "$liuhai_str")"
        fi
        if [[ "$show_buzhen" == "true" ]]; then
            local plan="${_BZ_PAL_PLAN_TEXT[$p]:-}"
            if [[ -n "$plan" ]]; then
                printf '%s化解:\n' "$sub_indent"
                _hq_print_buzhen_for_palace "$p" "${sub_indent}  "
            fi
        fi
    fi
}

hq_output_caiguan_text() {
    local birth_year_stem="$1"
    local has_buzhen="${2:-false}"

    dl_get_v "plate_datetime" 2>/dev/null || true; local dt="$_DL_RET"
    dl_get_v "plate_si_zhu_year" 2>/dev/null || true; local sz_y="$_DL_RET"
    dl_get_v "plate_si_zhu_month" 2>/dev/null || true; local sz_m="$_DL_RET"
    dl_get_v "plate_si_zhu_day" 2>/dev/null || true; local sz_d="$_DL_RET"
    dl_get_v "plate_si_zhu_hour" 2>/dev/null || true; local sz_h="$_DL_RET"
    dl_get_v "plate_ju_type" 2>/dev/null || true; local ju_t="$_DL_RET"
    dl_get_v "plate_ju_number" 2>/dev/null || true; local ju_n="$_DL_RET"
    dl_get_v "plate_ju_yuan" 2>/dev/null || true; local ju_yuan="$_DL_RET"
    dl_get_v "hq_yuegling_branch" 2>/dev/null || true; local yl_branch="$_DL_RET"

    printf '财官诊断\n'
    printf '========\n'
    if [[ -n "${_BIRTH_DATETIME:-}" ]]; then
        printf '出生时间: %s\n' "$_BIRTH_DATETIME"
    fi
    if [[ -n "${_BIRTH_SIZHU:-}" ]]; then
        printf '出生四柱: %s\n' "$_BIRTH_SIZHU"
    fi
    printf '年干: %s\n' "$birth_year_stem"
    if [[ "${_SHOW_EVENT_HEADER:-}" == "true" ]]; then
        printf '\n'
        printf '起局时间: %s\n' "$dt"
        printf '起局四柱: %s %s %s %s\n' "$sz_y" "$sz_m" "$sz_d" "$sz_h"
        printf '局  : %s%s局 (%s)\n' "$ju_t" "$ju_n" "$ju_yuan"
    fi
    printf '\n'
    printf '月令(大环境,天时): %s(%s)\n' "$yl_branch" "$HQ_YUEGLING_WX"
    printf '  月令是天时大势，决定做事的难度和量级，难以完全逆转\n'
    printf '  选择被月令生助的方向会事半功倍，逆天时看性价比\n'
    printf '  月令生→扩张(量大) | 月令同→稳健(量大) | 克月令→努力(量小) | 生月令→损耗(量小) | 月令克→大亏(量小，最差)\n'

    # === 财富七要害 ===
    printf '\n=== 财富七要害 ===\n'
    for line in "${_HQ_CAIFU_TEXT[@]}"; do
        _hq_output_yaohai_item "$line" "$has_buzhen"
    done

    # === 事业七要害 ===
    printf '\n=== 事业七要害 ===\n'
    for line in "${_HQ_SHIYE_TEXT[@]}"; do
        _hq_output_yaohai_item "$line" "$has_buzhen"
    done

    # === 踩一捧一 ===
    printf '\n=== 踩一捧一(财富与事业只能二选一) ===\n'
    printf '  财富和事业二者不可兼得，需要踩一捧一，反之必出事\n'
    printf '  财富总六害: %d | 事业总六害: %d\n' "$_HQ_CAIFU_TOTAL_LIUHAI" "$_HQ_SHIYE_TOTAL_LIUHAI"
    printf '  建议: %s\n' "$_HQ_CAIYIPENGYI"

    # === 干财 ===
    printf '\n=== 干财(控制力) ===\n'
    printf '  日干/年干所克天干，可控制和利用的资源上限\n'
    for line in "${_HQ_GANCAI_TEXT_HEADER[@]}"; do
        printf '  %s\n' "$line"
    done
    for line in "${_HQ_GANCAI_TEXT_STEMS[@]}"; do
        local IFS='|'
        read -r gc_stem gc_palace gc_lh gc_note <<< "$line"
        _hq_output_palace_item "$gc_stem" "$gc_palace" "$gc_lh" "$gc_note" "$has_buzhen"
    done

    # === 符使 ===
    printf '\n=== 符使(直属上级) ===\n'
    printf '  值符为顶头上司，值使为直属领导\n'
    for line in "${_HQ_FUSHI_TEXT[@]}"; do
        local IFS='|'
        read -r fs_label fs_name fs_palace fs_lh <<< "$line"
        _hq_output_palace_item "${fs_label}: ${fs_name}" "$fs_palace" "$fs_lh" "" "$has_buzhen"
    done

    # === 天干角色 ===
    printf '\n=== 天干角色(各角色人事) ===\n'
    printf '  年干=大老板(最有权，不直接参与工作)，月干=同事，日干=自己，时干=下属\n'
    printf '  天干有问题就是阻碍的根源\n'
    for line in "${_HQ_TIANGAN_ROLES_TEXT[@]}"; do
        local IFS='|'
        read -r tr_role tr_desc tr_stem tr_palace tr_lh <<< "$line"
        _hq_output_palace_item "${tr_role}(${tr_desc}): ${tr_stem}" "$tr_palace" "$tr_lh" "" "$has_buzhen"
    done

    # === 适合行业 ===
    if [[ $_HQ_HANGYE_PALACE -gt 0 && $_HQ_HANGYE_PALACE -ne 5 ]]; then
        local hy_label
        hy_label="$(_hq_palace_label "$_HQ_HANGYE_PALACE")"
        printf '\n=== 适合行业(从戊所在宫推算) ===\n'
        printf '  戊在 %s\n' "$hy_label"
        printf '  宫内符号: 星 %s / 门 %s / 神 %s / 天盘干 %s\n' \
            "$_HQ_HANGYE_STAR" "$_HQ_HANGYE_GATE" "$_HQ_HANGYE_DEITY" "$_HQ_HANGYE_TIAN_GAN"

        if [[ ${#_HQ_HANGYE_MATCHED[@]} -gt 0 ]]; then
            printf '\n  匹配行业:\n'
            local mi=0
            while [[ $mi -lt ${#_HQ_HANGYE_MATCHED[@]} ]]; do
                printf '    %s\n' "${_HQ_HANGYE_MATCHED[$mi]}"
                mi=$((mi + 1))
            done
        fi

        if [[ -n "$_HQ_HANGYE_STAR_CAREER" ]]; then
            printf '\n  星 %s 行业方向(化气阵):\n' "$_HQ_HANGYE_STAR"
            printf '    %s\n' "$_HQ_HANGYE_STAR_CAREER"
        fi

        local hy_yr_rel=""
        if [[ -n "$HQ_YUEGLING_WX" ]]; then
            local p=$_HQ_HANGYE_PALACE
            dl_get_v "palace_${p}_wuxing" 2>/dev/null || true; local p_wx="$_DL_RET"
            if [[ -n "$p_wx" ]]; then
                local rel
                rel="$(hq_wuxing_relation "$HQ_YUEGLING_WX" "$p_wx")"
                hy_yr_rel="$(hq_wuxing_relation_cn "$rel")"
            fi
        fi
        if [[ -n "$hy_yr_rel" ]]; then
            printf '\n  月令与戊宫: %s\n' "$hy_yr_rel"
        fi
    fi
}

# --- Main output: generate caiguan analysis JSON ---
hq_output_json() {
    local output_path="$1"
    local birth_year_stem="$2"

    dl_get_v "plate_datetime" 2>/dev/null || true; local dt="$_DL_RET"
    dl_get_v "plate_si_zhu_year" 2>/dev/null || true; local sz_y="$_DL_RET"
    dl_get_v "plate_si_zhu_month" 2>/dev/null || true; local sz_m="$_DL_RET"
    dl_get_v "plate_si_zhu_day" 2>/dev/null || true; local sz_d="$_DL_RET"
    dl_get_v "plate_si_zhu_hour" 2>/dev/null || true; local sz_h="$_DL_RET"
    dl_get_v "plate_ju_type" 2>/dev/null || true; local ju_t="$_DL_RET"
    dl_get_v "plate_ju_number" 2>/dev/null || true; local ju_n="$_DL_RET"
    dl_get_v "plate_ju_yuan" 2>/dev/null || true; local ju_yuan="$_DL_RET"

    _hq_je_v "$dt"; local j_dt="$_JE"
    _hq_je_v "$sz_y"; local j_sy="$_JE"
    _hq_je_v "$sz_m"; local j_sm="$_JE"
    _hq_je_v "$sz_d"; local j_sd="$_JE"
    _hq_je_v "$sz_h"; local j_sh="$_JE"
    _hq_je_v "$ju_t"; local j_jt="$_JE"
    _hq_je_v "$ju_yuan"; local j_jy="$_JE"
    _hq_je_v "$birth_year_stem"; local j_bys="$_JE"

    local caifu_arr="" first=1
    for item in "${_HQ_CAIFU_ITEMS[@]}"; do
        (( first )) || caifu_arr="${caifu_arr},"
        first=0
        caifu_arr="${caifu_arr}
      ${item}"
    done

    local shiye_arr="" first=1
    for item in "${_HQ_SHIYE_ITEMS[@]}"; do
        (( first )) || shiye_arr="${shiye_arr},"
        first=0
        shiye_arr="${shiye_arr}
      ${item}"
    done

    _hq_je_v "$_HQ_CAIYIPENGYI"; local j_cypy="$_JE"

    cat > "$output_path" <<ENDJSON
{
  "datetime": "${j_dt}",
  "si_zhu": { "year": "${j_sy}", "month": "${j_sm}", "day": "${j_sd}", "hour": "${j_sh}" },
  "ju": { "type": "${j_jt}", "number": ${ju_n:-0}, "yuan": "${j_jy}" },
  "birth_year_stem": "${j_bys}",
  "yuegling": ${_HQ_YUEGLING_RELS_JSON},
  "caifu_yaohai": [${caifu_arr}
  ],
  "shiye_yaohai": [${shiye_arr}
  ],
  "summary": {
    "caifu_total_liuhai": ${_HQ_CAIFU_TOTAL_LIUHAI},
    "shiye_total_liuhai": ${_HQ_SHIYE_TOTAL_LIUHAI},
    "caiyipengyi": "${j_cypy}"
  },
  "gan_cai": ${_HQ_GANCAI_JSON},
  "fushi": ${_HQ_FUSHI_JSON},
  "tiangan_roles": ${_HQ_TIANGAN_ROLES_JSON},
  "hangye": ${_HQ_HANGYE_JSON}
}
ENDJSON
}

# --- Pipeline entry point ---
hq_run_analysis() {
    local input_path="$1" birth_year_stem="$2" output_path="$3"

    qa_parse_plate_json "$input_path"

    hq_compute_yuegling
    hq_compute_gan_cai "$birth_year_stem"

    _HQ_CAIFU_ITEMS=()
    _HQ_YAOHAI_JSON_ITEMS=()
    _HQ_YAOHAI_TEXT_ITEMS=()
    local cf_count="${caifu_count:-7}"
    local i=0
    while [[ $i -lt ${cf_count:-7} ]]; do
        hq_analyze_yaohai "$i" "caifu"
        i=$((i + 1))
    done
    _HQ_CAIFU_ITEMS=("${_HQ_YAOHAI_JSON_ITEMS[@]}")
    _HQ_CAIFU_TEXT=("${_HQ_YAOHAI_TEXT_ITEMS[@]}")

    _HQ_SHIYE_ITEMS=()
    _HQ_YAOHAI_JSON_ITEMS=()
    _HQ_YAOHAI_TEXT_ITEMS=()
    local sy_count="${shiye_count:-7}"
    i=0
    while [[ $i -lt ${sy_count:-7} ]]; do
        hq_analyze_yaohai "$i" "shiye"
        i=$((i + 1))
    done
    _HQ_SHIYE_ITEMS=("${_HQ_YAOHAI_JSON_ITEMS[@]}")
    _HQ_SHIYE_TEXT=("${_HQ_YAOHAI_TEXT_ITEMS[@]}")

    hq_analyze_gan_cai
    hq_compute_yuegling_relations
    hq_analyze_fushi
    hq_analyze_tiangan_roles
    hq_derive_hangye

    # Compute summary: total liuhai counts for caifu vs shiye
    _HQ_CAIFU_TOTAL_LIUHAI=0
    for item in "${_HQ_CAIFU_ITEMS[@]}"; do
        local _cnt
        _cnt="$(echo "$item" | sed -n 's/.*"liuhai_count": *\([0-9]*\).*/\1/p')"
        _HQ_CAIFU_TOTAL_LIUHAI=$((_HQ_CAIFU_TOTAL_LIUHAI + ${_cnt:-0}))
    done
    _HQ_SHIYE_TOTAL_LIUHAI=0
    for item in "${_HQ_SHIYE_ITEMS[@]}"; do
        local _cnt
        _cnt="$(echo "$item" | sed -n 's/.*"liuhai_count": *\([0-9]*\).*/\1/p')"
        _HQ_SHIYE_TOTAL_LIUHAI=$((_HQ_SHIYE_TOTAL_LIUHAI + ${_cnt:-0}))
    done
    if [[ $_HQ_CAIFU_TOTAL_LIUHAI -lt $_HQ_SHIYE_TOTAL_LIUHAI ]]; then
        _HQ_CAIYIPENGYI="财富六害较少，建议捧财富、踩事业"
    elif [[ $_HQ_CAIFU_TOTAL_LIUHAI -gt $_HQ_SHIYE_TOTAL_LIUHAI ]]; then
        _HQ_CAIYIPENGYI="事业六害较少，建议捧事业、踩财富"
    else
        _HQ_CAIYIPENGYI="财富与事业六害相当，需结合月令和具体要害综合判断"
    fi

    # Run buzhen pipeline for per-palace resolution data
    local has_buzhen="false"
    if type bz_scan_all_palaces >/dev/null 2>&1; then
        bz_scan_all_palaces
        bz_identify_protected_stems "$birth_year_stem" "" ""
        bz_check_protected_safety
        bz_generate_miexiang
        bz_generate_prescription
        has_buzhen="true"
    fi

    hq_output_caiguan_text "$birth_year_stem" "$has_buzhen"
    hq_output_json "$output_path" "$birth_year_stem"
}
