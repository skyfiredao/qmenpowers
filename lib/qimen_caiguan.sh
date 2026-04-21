#!/usr/bin/env bash
# Copyright (C) 2025 — Licensed under GPL-3.0
# See https://www.gnu.org/licenses/gpl-3.0.html
# qimen_caiguan.sh — 财官诊断 analysis library.
# Sourced AFTER qimen_banmenhuaqizhen.sh (for hq_* helpers).

# --- Text accumulation arrays ---
_HQ_CAIFU_TEXT=()
_HQ_SHIYE_TEXT=()
_HQ_GANCAI_TEXT=()
_HQ_FUSHI_TEXT=()
_HQ_TIANGAN_ROLES_TEXT=()
_HQ_HANGYE_TEXT=()

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
        _HQ_YAOHAI_TEXT_ITEMS+=("${yh_name}|${yh_desc}|—|—|无|0")
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

    local pal_label="—"
    if [[ $palace -gt 0 && $palace -ne 5 ]]; then
        dl_get_v "palace_${palace}_name" 2>/dev/null || true; local pname="$_DL_RET"
        dl_get_v "palace_${palace}_direction" 2>/dev/null || true; local pdir="$_DL_RET"
        pal_label="${palace}宫(${pdir})"
    elif [[ $palace -eq 5 ]]; then
        pal_label="5宫(中)"
    fi
    local lh_display="无"
    if [[ -n "$liuhai_str" ]]; then
        lh_display="$liuhai_str (${liuhai_count}害)"
    fi
    local yr_display="${yuegling_rel}"
    if [[ -n "$yuegling_cn" ]]; then
        yr_display="${yuegling_rel}(${yuegling_cn})"
    fi
    _HQ_YAOHAI_TEXT_ITEMS+=("${yh_name}|${yh_desc}|${pal_label}|${yr_display}|${lh_display}|${liuhai_count}")
}

# --- Analyze 干财 stems in the plate ---
_HQ_GANCAI_JSON=""
hq_analyze_gan_cai() {
    local ri_cai nian_cai items=""
    dl_get_v "hq_ri_gan_cai" 2>/dev/null || true; ri_cai="$_DL_RET"
    dl_get_v "hq_nian_gan_cai" 2>/dev/null || true; nian_cai="$_DL_RET"
    dl_get_v "hq_ri_gan" 2>/dev/null || true; local ri_gan="$_DL_RET"
    dl_get_v "hq_nian_gan" 2>/dev/null || true; local nian_gan="$_DL_RET"

    _HQ_GANCAI_TEXT=()
    _HQ_GANCAI_TEXT+=("日干: ${ri_gan} → 财干: ${ri_cai}")
    _HQ_GANCAI_TEXT+=("年干: ${nian_gan} → 财干: ${nian_cai}")

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

        local stem_pal_label="不在盘上"
        if [[ $use_palace -gt 0 && $use_palace -ne 5 ]]; then
            dl_get_v "palace_${use_palace}_name" 2>/dev/null || true; local spname="$_DL_RET"
            dl_get_v "palace_${use_palace}_direction" 2>/dev/null || true; local spdir="$_DL_RET"
            stem_pal_label="${use_palace}宫(${spdir})"
        elif [[ $use_palace -eq 5 ]]; then
            stem_pal_label="5宫(中)"
        fi
        local stem_lh_display="无"
        if [[ -n "$liuhai_str" ]]; then
            stem_lh_display="$liuhai_str"
        fi
        local wuhe_note=""
        if [[ -n "$wuhe_alt" && $di_palace -eq 0 && $tian_palace -eq 0 ]]; then
            if [[ "$stem" == "甲" ]]; then
                wuhe_note=" (值符宫干→${wuhe_alt})"
            else
                wuhe_note=" (五合→${wuhe_alt})"
            fi
        fi
        _HQ_GANCAI_TEXT+=("${stem} — ${stem_pal_label}  六害: ${stem_lh_display}${wuhe_note}")

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

# --- Locate 行业 symbols ---
_HQ_HANGYE_JSON=""
hq_lookup_hangye() {
    local job="$1"
    _HQ_HANGYE_JSON="null"
    _HQ_HANGYE_TEXT=()
    [[ -z "$job" ]] && return

    dl_get_v "hangye_${job}" 2>/dev/null || true
    local mapping="$_DL_RET"
    [[ -z "$mapping" ]] && return

    local items="" first=1
    local IFS=',' arr
    read -ra arr <<< "$mapping"
    local i=0
    while [[ $i -lt ${#arr[@]} ]]; do
        local sym_type="${arr[$i]}"
        local sym_name="${arr[$((i+1))]}"
        i=$((i + 2))

        hq_locate_symbol "$sym_name" "$sym_type"
        local p=$_HQ_FOUND_PALACE
        local liuhai_str="" liuhai_count=0
        if [[ $p -gt 0 && $p -ne 5 ]]; then
            hq_detect_liuhai "$p"
            liuhai_str="$_HQ_LIUHAI"
            liuhai_count=$_HQ_LIUHAI_COUNT
        fi

        _hq_je_v "$sym_name"; local j_sn="$_JE"
        _hq_je_v "$sym_type"; local j_st="$_JE"
        _hq_je_v "$liuhai_str"; local j_lh="$_JE"

        (( first )) || items="${items},"
        first=0
        items="${items} { \"name\": \"${j_sn}\", \"type\": \"${j_st}\", \"palace\": ${p}, \"liuhai\": \"${j_lh}\", \"liuhai_count\": ${liuhai_count} }"

        local hy_lh_display="无"
        [[ -n "$liuhai_str" ]] && hy_lh_display="$liuhai_str"
        _HQ_HANGYE_TEXT+=("${sym_name}(${sym_type}) — ${p}宫  六害: ${hy_lh_display}")
    done

    _hq_je_v "$job"; local j_job="$_JE"
    _HQ_HANGYE_JSON="{ \"job\": \"${j_job}\", \"symbols\": [${items} ] }"
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

    local zf_lh_display="无" zs_lh_display="无"
    [[ -n "$zf_liuhai" ]] && zf_lh_display="$zf_liuhai"
    [[ -n "$zs_liuhai" ]] && zs_lh_display="$zs_liuhai"
    _HQ_FUSHI_TEXT=()
    _HQ_FUSHI_TEXT+=("值符: ${zf_star}(${zf_palace:-0}宫)  六害: ${zf_lh_display}")
    _HQ_FUSHI_TEXT+=("值使: ${zs_gate}(${zs_palace:-0}宫)  六害: ${zs_lh_display}")
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

        local tr_pal_label="不在盘上"
        if [[ $p -gt 0 && $p -ne 5 ]]; then
            dl_get_v "palace_${p}_name" 2>/dev/null || true; local trpname="$_DL_RET"
            dl_get_v "palace_${p}_direction" 2>/dev/null || true; local trpdir="$_DL_RET"
            tr_pal_label="${p}宫(${trpdir})"
        elif [[ $p -eq 5 ]]; then
            tr_pal_label="5宫(中)"
        fi
        local tr_lh_display="无"
        [[ -n "$liuhai_str" ]] && tr_lh_display="$liuhai_str"
        _HQ_TIANGAN_ROLES_TEXT+=("${role}(${desc}): ${stem} — ${tr_pal_label}  六害: ${tr_lh_display}")
    done

    _HQ_TIANGAN_ROLES_JSON="[${items}
    ]"
}

hq_output_caiguan_text() {
    local birth_year_stem="$1" job="$2"

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
    if [[ -n "$_BIRTH_DATETIME" ]]; then
        printf '出生时间: %s\n' "$_BIRTH_DATETIME"
    fi
    if [[ -n "$_BIRTH_SIZHU" ]]; then
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
    printf '月令: %s(%s)\n' "$yl_branch" "$HQ_YUEGLING_WX"

    printf '\n=== 财富七要害 ===\n'
    local idx=0
    for line in "${_HQ_CAIFU_TEXT[@]}"; do
        local IFS='|'
        read -r t_name t_desc t_pal t_yr t_lh t_lhc <<< "$line"
        local yr_part=""
        if [[ -n "$t_yr" && "$t_yr" != "—" ]]; then yr_part="  月令: ${t_yr}"; fi
        printf '  [%d] %s(%s) — %s  六害: %s%s\n' "$idx" "$t_name" "$t_desc" "$t_pal" "$t_lh" "$yr_part"
        idx=$((idx + 1))
    done

    printf '\n=== 事业七要害 ===\n'
    idx=0
    for line in "${_HQ_SHIYE_TEXT[@]}"; do
        local IFS='|'
        read -r t_name t_desc t_pal t_yr t_lh t_lhc <<< "$line"
        local yr_part=""
        if [[ -n "$t_yr" && "$t_yr" != "—" ]]; then yr_part="  月令: ${t_yr}"; fi
        printf '  [%d] %s(%s) — %s  六害: %s%s\n' "$idx" "$t_name" "$t_desc" "$t_pal" "$t_lh" "$yr_part"
        idx=$((idx + 1))
    done

    printf '\n=== 干财 ===\n'
    for line in "${_HQ_GANCAI_TEXT[@]}"; do
        printf '  %s\n' "$line"
    done

    printf '\n=== 符使 ===\n'
    for line in "${_HQ_FUSHI_TEXT[@]}"; do
        printf '  %s\n' "$line"
    done

    printf '\n=== 天干角色 ===\n'
    for line in "${_HQ_TIANGAN_ROLES_TEXT[@]}"; do
        printf '  %s\n' "$line"
    done

    if [[ -n "$job" && ${#_HQ_HANGYE_TEXT[@]} -gt 0 ]]; then
        printf '\n=== 行业 (%s) ===\n' "$job"
        for line in "${_HQ_HANGYE_TEXT[@]}"; do
            printf '  %s\n' "$line"
        done
    fi
}

# --- Main output: generate caiguan analysis JSON ---
hq_output_json() {
    local output_path="$1"
    local birth_year_stem="$2"
    local job="$3"

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
  "gan_cai": ${_HQ_GANCAI_JSON},
  "fushi": ${_HQ_FUSHI_JSON},
  "tiangan_roles": ${_HQ_TIANGAN_ROLES_JSON},
  "hangye": ${_HQ_HANGYE_JSON}
}
ENDJSON
}

# --- Pipeline entry point ---
hq_run_analysis() {
    local input_path="$1" birth_year_stem="$2" job="$3" output_path="$4"

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
    hq_lookup_hangye "$job"

    hq_output_caiguan_text "$birth_year_stem" "$job"
    hq_output_json "$output_path" "$birth_year_stem" "$job"
}
