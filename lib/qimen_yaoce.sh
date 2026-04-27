#!/usr/bin/env bash
# Copyright (C) 2026 — Licensed under GPL-3.0
# See https://www.gnu.org/licenses/gpl-3.0.html
# qimen_yaoce.sh — 遥测 (remote sensing) analysis library.
# Sourced AFTER qimen_json.sh and qimen_banmenhuaqizhen.sh

_YC_P_TIAN_GAN=""
_YC_P_DI_GAN=""
_YC_P_STAR=""
_YC_P_GATE=""
_YC_P_DEITY=""
_YC_P_STATE=""
_YC_P_MARKERS=""
_YC_P_PALACE_NAME=""
_YC_P_PALACE_WUXING=""
_YC_P_DIRECTION=""

# --- Local lookup helpers (self-contained, no dependency on qimen_caiguan.sh) ---
_yc_stem_wuxing() {
    case "$1" in
        甲|乙) echo "木";; 丙|丁) echo "火";; 戊|己) echo "土";;
        庚|辛) echo "金";; 壬|癸) echo "水";; *) echo "";;
    esac
}

_yc_star_jixi() {
    local name="$1" i=0
    while [[ $i -lt ${#STAR_NAMES[@]} ]]; do
        if [[ "${STAR_NAMES[$i]}" == "$name" ]]; then
            echo "${STAR_JIXI[$i]}"; return
        fi
        i=$((i + 1))
    done
    echo ""
}

_yc_gate_jixi() {
    local name="$1" i=0
    while [[ $i -lt ${#GATE_NAMES[@]} ]]; do
        if [[ "${GATE_NAMES[$i]}" == "$name" ]]; then
            echo "${GATE_JIXI[$i]}"; return
        fi
        i=$((i + 1))
    done
    echo ""
}

_YC_RESULTS_TEXT=()
_YC_RESULTS_JSON=()

_YC_BIRTH_DATETIME=""
_YC_BIRTH_SIZHU=""
_YC_BIRTH_DAY_STEM=""
_YC_BIRTH_YEAR_STEM=""
_YC_BIRTH_HOUR_STEM=""
_YC_ZHIFU_STEM=""
_YC_ZHISHI_STEM=""
_YC_EVENT_DATETIME=""
_YC_EVENT_SIZHU=""

yc_collect_palace_info() {
    local p="$1"
    if [[ $p -le 0 || $p -eq 5 ]]; then
        _YC_P_TIAN_GAN=""
        _YC_P_DI_GAN=""
        _YC_P_STAR=""
        _YC_P_GATE=""
        _YC_P_DEITY=""
        _YC_P_STATE=""
        _YC_P_MARKERS=""
        _YC_P_PALACE_NAME=""
        _YC_P_PALACE_WUXING=""
        _YC_P_DIRECTION=""
        return
    fi

    dl_get_v "palace_${p}_tian_gan" 2>/dev/null || true; _YC_P_TIAN_GAN="$_DL_RET"
    dl_get_v "palace_${p}_di_gan" 2>/dev/null || true; _YC_P_DI_GAN="$_DL_RET"
    dl_get_v "palace_${p}_star" 2>/dev/null || true; _YC_P_STAR="$_DL_RET"
    dl_get_v "palace_${p}_gate" 2>/dev/null || true; _YC_P_GATE="$_DL_RET"
    dl_get_v "palace_${p}_deity" 2>/dev/null || true; _YC_P_DEITY="$_DL_RET"
    dl_get_v "palace_${p}_state" 2>/dev/null || true; _YC_P_STATE="$_DL_RET"
    dl_get_v "palace_${p}_markers" 2>/dev/null || true; _YC_P_MARKERS="$_DL_RET"
    dl_get_v "palace_${p}_name" 2>/dev/null || true; _YC_P_PALACE_NAME="$_DL_RET"
    dl_get_v "palace_${p}_wuxing" 2>/dev/null || true; _YC_P_PALACE_WUXING="$_DL_RET"
    dl_get_v "palace_${p}_direction" 2>/dev/null || true; _YC_P_DIRECTION="$_DL_RET"
}

yc_analyze_stem_on_event() {
    local stem="$1" role_label="$2"
    
    hq_find_stem_palace_tian "$stem"
    local tp=$_HQ_FOUND_PALACE
    hq_find_stem_palace "$stem"
    local dp=$_HQ_FOUND_PALACE

    local analysis_palace=$tp
    [[ $analysis_palace -le 0 ]] && analysis_palace=$dp

    local lh_str="" lh_cnt=0
    if [[ $analysis_palace -gt 0 && $analysis_palace -ne 5 ]]; then
        hq_detect_liuhai "$analysis_palace"
        lh_str="$_HQ_LIUHAI"
        lh_cnt=$_HQ_LIUHAI_COUNT
        yc_collect_palace_info "$analysis_palace"
        
        # Extract wanwu: pass 1 for verbose if _SHOW_WANWU is set, otherwise default concise
        qj_lookup_wanwu "$analysis_palace" "${_SHOW_WANWU:+1}" ""
    else
        yc_collect_palace_info 0
    fi

    # Escape JSON
    _qj_je_v "$stem"; local j_stem="$_JE"
    _qj_je_v "$role_label"; local j_role="$_JE"
    _qj_je_v "$_YC_P_PALACE_NAME"; local j_pn="$_JE"
    _qj_je_v "$_YC_P_PALACE_WUXING"; local j_pwx="$_JE"
    _qj_je_v "$_YC_P_DIRECTION"; local j_pdir="$_JE"
    _qj_je_v "$_YC_P_TIAN_GAN"; local j_tg="$_JE"
    _qj_je_v "$_YC_P_DI_GAN"; local j_dg="$_JE"
    _qj_je_v "$_YC_P_STAR"; local j_star="$_JE"
    _qj_je_v "$_YC_P_GATE"; local j_gate="$_JE"
    _qj_je_v "$_YC_P_DEITY"; local j_deity="$_JE"
    _qj_je_v "$_YC_P_STATE"; local j_state="$_JE"
    _qj_je_v "$_YC_P_MARKERS"; local j_markers="$_JE"
    _qj_je_v "$lh_str"; local j_lh="$_JE"

    local ww_json="{}"
    if [[ $analysis_palace -gt 0 && $analysis_palace -ne 5 ]]; then
        local ww_items="" first_ww=1
        local i=0 key val
        while [[ $i -lt ${#_DL_KEYS[@]} ]]; do
            key="${_DL_KEYS[$i]}"
            val="${_DL_VALS[$i]}"
            i=$((i + 1))
            if [[ "$key" == "wanwu_${analysis_palace}_"* ]]; then
                local f="${key#wanwu_${analysis_palace}_}"
                _qj_je_v "$f"; local j_k="$_JE"
                _qj_je_v "$val"; local j_v="$_JE"
                (( first_ww )) || ww_items="${ww_items},"
                first_ww=0
                ww_items="${ww_items}\"${j_k}\": \"${j_v}\""
            fi
        done
        ww_json="{${ww_items}}"
    fi

    _YC_RESULTS_JSON+=("{
      \"stem\": \"${j_stem}\",
      \"role\": \"${j_role}\",
      \"tian_palace\": ${tp:-0},
      \"di_palace\": ${dp:-0},
      \"analysis_palace\": ${analysis_palace:-0},
      \"palace_name\": \"${j_pn}\",
      \"palace_wuxing\": \"${j_pwx}\",
      \"direction\": \"${j_pdir}\",
      \"tian_gan\": \"${j_tg}\",
      \"di_gan\": \"${j_dg}\",
      \"star\": \"${j_star}\",
      \"gate\": \"${j_gate}\",
      \"deity\": \"${j_deity}\",
      \"state\": \"${j_state}\",
      \"markers\": \"${j_markers}\",
      \"liuhai\": \"${j_lh}\",
      \"liuhai_count\": ${lh_cnt:-0},
      \"wanwu\": ${ww_json}
    }")

    _YC_RESULTS_TEXT+=("${stem}|${role_label}|${tp:-0}|${dp:-0}|${analysis_palace:-0}|${_YC_P_PALACE_NAME}|${_YC_P_PALACE_WUXING}|${_YC_P_DIRECTION}|${_YC_P_TIAN_GAN}|${_YC_P_DI_GAN}|${_YC_P_STAR}|${_YC_P_GATE}|${_YC_P_DEITY}|${_YC_P_STATE}|${_YC_P_MARKERS}|${lh_str}|${lh_cnt:-0}")
}

yc_output_text() {
    printf "遥测分析\n"
    printf "出生时间: %s\n" "$_YC_BIRTH_DATETIME"
    printf "问事时间: %s\n" "$_YC_EVENT_DATETIME"
    printf "四柱(出生): %s\n" "$_YC_BIRTH_SIZHU"
    printf "四柱(问事): %s\n" "$_YC_EVENT_SIZHU"
    printf "命主日干: %s\n" "$_YC_BIRTH_DAY_STEM"
    printf "命主时干: %s\n" "$_YC_BIRTH_HOUR_STEM"
    printf "生年天干: %s\n" "$_YC_BIRTH_YEAR_STEM"
    printf "值符宫干: %s\n" "${_YC_ZHIFU_STEM:-(无)}"
    printf "值使宫干: %s\n\n" "${_YC_ZHISHI_STEM:-(无)}"

    local line IFS='|'
    for line in "${_YC_RESULTS_TEXT[@]}"; do
        read -r stem role tp dp ap pn pwx pdir tg dg star gate deity state markers lh lhc <<< "$line"
        printf '%s\n' "--- ${role}「${stem}」在问事盘 ---"
        if [[ $tp -gt 0 ]]; then
            printf "天盘宫位: %d宫(%s,%s,%s)\n" "$tp" "$pn" "$pdir" "$pwx"
        else
            printf "天盘宫位: 不在盘上\n"
        fi
        if [[ $dp -gt 0 ]]; then
            printf "地盘宫位: %d宫\n" "$dp"
        else
            printf "地盘宫位: 不在盘上\n"
        fi
        
        if [[ $ap -gt 0 && $ap -ne 5 ]]; then
            local tg_wx="" dg_wx=""
            tg_wx="$(_yc_stem_wuxing "$tg")"
            dg_wx="$(_yc_stem_wuxing "$dg")"

            local star_jx="" gate_jx=""
            star_jx="$(_yc_star_jixi "$star")"
            gate_jx="$(_yc_gate_jixi "$gate")"

            local tg_disp="$tg" dg_disp="$dg" star_disp="$star" gate_disp="$gate"
            [[ -n "$tg_wx" ]] && tg_disp="${tg}(${tg_wx})"
            [[ -n "$dg_wx" ]] && dg_disp="${dg}(${dg_wx})"
            [[ -n "$star_jx" ]] && star_disp="${star}(${star_jx})"
            [[ -n "$gate_jx" ]] && gate_disp="${gate}(${gate_jx})"

            printf "  天盘干: %s\n" "$tg_disp"
            printf "  地盘干: %s\n" "$dg_disp"
            printf "  星: %s\n" "$star_disp"
            printf "  门: %s\n" "$gate_disp"
            printf "  神: %s\n" "$deity"
            printf "  状态: %s\n" "$state"
            printf "  格局: %s\n" "${markers:-(none)}"
            printf "  六害: %s\n" "$lh"
            printf "  六害数: %d\n" "$lhc"
            
            if [[ "${_SHOW_WANWU:-}" == "true" ]]; then
                printf "  万物类象:\n"
                local i=0 key val
                while [[ $i -lt ${#_DL_KEYS[@]} ]]; do
                    key="${_DL_KEYS[$i]}"
                    val="${_DL_VALS[$i]}"
                    i=$((i + 1))
                    if [[ "$key" == "wanwu_${ap}_"* ]]; then
                        local f="${key#wanwu_${ap}_}"
                        printf "    %s: %s\n" "$f" "$val"
                    fi
                done
            fi
        fi
        printf "\n"
    done
}

yc_output_json() {
    local output_path="$1"
    
    _qj_je_v "$_YC_BIRTH_DATETIME"; local j_bdt="$_JE"
    _qj_je_v "$_YC_EVENT_DATETIME"; local j_edt="$_JE"
    _qj_je_v "$_YC_BIRTH_DAY_STEM"; local j_bds="$_JE"
    _qj_je_v "$_YC_BIRTH_YEAR_STEM"; local j_bys="$_JE"
    _qj_je_v "$_YC_BIRTH_HOUR_STEM"; local j_bhs="$_JE"
    _qj_je_v "${_YC_ZHIFU_STEM:-}"; local j_zfs="$_JE"
    _qj_je_v "${_YC_ZHISHI_STEM:-}"; local j_zss="$_JE"
    
    local stems_arr="" first=1
    for item in "${_YC_RESULTS_JSON[@]}"; do
        (( first )) || stems_arr="${stems_arr},"
        first=0
        stems_arr="${stems_arr}
      ${item}"
    done
    
    cat > "$output_path" <<ENDJSON
{
  "type": "yaoce",
  "birth_datetime": "${j_bdt}",
  "event_datetime": "${j_edt}",
  "birth_day_stem": "${j_bds}",
  "birth_hour_stem": "${j_bhs}",
  "birth_year_stem": "${j_bys}",
  "zhifu_stem": "${j_zfs}",
  "zhishi_stem": "${j_zss}",
  "stems": [${stems_arr}
  ]
}
ENDJSON
}

yc_run_analysis() {
    local birth_json_path="$1"
    local event_json_path="$2"
    local output_path="$3"
    local yixiang_concepts="${4:-}"

    # Reset
    _YC_BIRTH_DATETIME=""
    _YC_BIRTH_SIZHU=""
    _YC_BIRTH_DAY_STEM=""
    _YC_BIRTH_YEAR_STEM=""
    _YC_BIRTH_HOUR_STEM=""
    _YC_ZHIFU_STEM=""
    _YC_ZHISHI_STEM=""

    # --- Phase 1: Parse birth plate (to extract 四柱 + 符使干) ---
    qj_parse_plate_json "$birth_json_path"

    dl_get_v "plate_datetime" 2>/dev/null || true; _YC_BIRTH_DATETIME="$_DL_RET"
    dl_get_v "plate_si_zhu_year" 2>/dev/null || true; local y="$_DL_RET"
    dl_get_v "plate_si_zhu_month" 2>/dev/null || true; local m="$_DL_RET"
    dl_get_v "plate_si_zhu_day" 2>/dev/null || true; local d="$_DL_RET"
    dl_get_v "plate_si_zhu_hour" 2>/dev/null || true; local h="$_DL_RET"
    _YC_BIRTH_SIZHU="${y} ${m} ${d} ${h}"
    _YC_BIRTH_DAY_STEM="$(_hq_extract_stem "$d")"
    _YC_BIRTH_YEAR_STEM="$(_hq_extract_stem "$y")"
    _YC_BIRTH_HOUR_STEM="$(_hq_extract_stem "$h")"

    # Extract 值符宫干 from birth plate
    dl_get_v "plate_zhi_fu_palace" 2>/dev/null || true; local zf_p="$_DL_RET"
    if [[ -n "$zf_p" && "$zf_p" -gt 0 && "$zf_p" -ne 5 ]]; then
        dl_get_v "palace_${zf_p}_tian_gan" 2>/dev/null || true; _YC_ZHIFU_STEM="$_DL_RET"
    fi

    # Extract 值使宫干 from birth plate
    dl_get_v "plate_zhi_shi_palace" 2>/dev/null || true; local zs_p="$_DL_RET"
    if [[ -n "$zs_p" && "$zs_p" -gt 0 && "$zs_p" -ne 5 ]]; then
        dl_get_v "palace_${zs_p}_tian_gan" 2>/dev/null || true; _YC_ZHISHI_STEM="$_DL_RET"
    fi

    # --- Phase 2: Parse event plate (overwrites dl store) ---
    qj_parse_plate_json "$event_json_path"

    dl_get_v "plate_datetime" 2>/dev/null || true; _YC_EVENT_DATETIME="$_DL_RET"
    dl_get_v "plate_si_zhu_year" 2>/dev/null || true; local ey="$_DL_RET"
    dl_get_v "plate_si_zhu_month" 2>/dev/null || true; local em="$_DL_RET"
    dl_get_v "plate_si_zhu_day" 2>/dev/null || true; local ed="$_DL_RET"
    dl_get_v "plate_si_zhu_hour" 2>/dev/null || true; local eh="$_DL_RET"
    _YC_EVENT_SIZHU="${ey} ${em} ${ed} ${eh}"

    # --- Phase 3: Analyze stems on event plate ---
    _YC_RESULTS_TEXT=()
    _YC_RESULTS_JSON=()

    yc_analyze_stem_on_event "$_YC_BIRTH_DAY_STEM" "日干"
    yc_analyze_stem_on_event "$_YC_BIRTH_HOUR_STEM" "时干"
    yc_analyze_stem_on_event "$_YC_BIRTH_YEAR_STEM" "生年干"

    if [[ -n "$_YC_ZHIFU_STEM" ]]; then
        yc_analyze_stem_on_event "$_YC_ZHIFU_STEM" "值符宫干"
    fi
    if [[ -n "$_YC_ZHISHI_STEM" ]]; then
        yc_analyze_stem_on_event "$_YC_ZHISHI_STEM" "值使宫干"
    fi

    # 意象干 (from --yixiang, if provided)
    if [[ -n "$yixiang_concepts" ]]; then
        local IFS=',' yx
        for yx in $yixiang_concepts; do
            [[ -z "$yx" ]] && continue
            local yx_stem=""
            # Check if it's a known concept name (e.g. 财富→戊)
            dl_get_v "yixiang_${yx}" 2>/dev/null || true
            if [[ -n "$_DL_RET" ]]; then
                yx_stem="$_DL_RET"
            else
                # Check if it's a direct stem character
                case "$yx" in
                    甲|乙|丙|丁|戊|己|庚|辛|壬|癸) yx_stem="$yx" ;;
                    *) echo "Warning: unknown yixiang concept or stem: $yx" >&2 ;;
                esac
            fi
            if [[ -n "$yx_stem" ]]; then
                yc_analyze_stem_on_event "$yx_stem" "意象(${yx})"
            fi
        done
    fi

    yc_output_text
    yc_output_json "$output_path"
}
