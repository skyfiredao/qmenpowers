#!/usr/bin/env bash
# Copyright (C) 2025 — Licensed under GPL-3.0
# See https://www.gnu.org/licenses/gpl-3.0.html
# qimen_banmenhuaqizhen.sh — 八门化气阵 core library (通用引擎).
# Contains: common helpers, palace finders, liuhai detection, yuegling,
# gan_cai computation, symbol location, palace summary, yuegling relations,
# and the full buzhen (布阵) pipeline.
#
# Sourced AFTER data_loader.sh, qimen_analysis.sh (for qa_parse_plate_json),
# and required .dat files are loaded.

# --- JSON helpers ---
_hq_je_v() {
    _JE="$1"
    _JE="${_JE//\\/\\\\}"
    _JE="${_JE//\"/\\\"}"
}

_hq_extract_stem() {
    local gz="$1" g
    for g in 甲 乙 丙 丁 戊 己 庚 辛 壬 癸; do
        if [[ "$gz" == "${g}"* ]]; then
            echo "$g"
            return
        fi
    done
}

_hq_extract_branch() {
    local gz="$1" z
    for z in 子 丑 寅 卯 辰 巳 午 未 申 酉 戌 亥; do
        if [[ "$gz" == *"${z}" ]]; then
            echo "$z"
            return
        fi
    done
}

# --- Wuxing relationship helpers ---
# Returns: sheng (生助), tong (同气), ke_target (我克), sheng_target (我生), bei_ke (被克)
hq_wuxing_relation() {
    local from="$1" to="$2"
    if [[ "$from" == "$to" ]]; then
        echo "tong"
        return
    fi
    dl_get_v "sheng_${from}"; local sheng_target="$_DL_RET"
    dl_get_v "ke_wx_${from}"; local ke_target="$_DL_RET"
    if [[ "$sheng_target" == "$to" ]]; then
        echo "sheng_target"
        return
    fi
    if [[ "$ke_target" == "$to" ]]; then
        echo "ke_target"
        return
    fi
    dl_get_v "sheng_${to}"; local to_sheng="$_DL_RET"
    if [[ "$to_sheng" == "$from" ]]; then
        echo "bei_ke"
        return
    fi
    echo "sheng"
}

hq_wuxing_relation_cn() {
    local rel="$1"
    case "$rel" in
        sheng)       echo "扩张，量大" ;;
        tong)        echo "稳健，量大" ;;
        bei_ke)      echo "努力，量小" ;;
        sheng_target) echo "损耗，量小" ;;
        ke_target)   echo "大亏，量小" ;;
        *)           echo "" ;;
    esac
}

# --- Core: Find stem in palaces (earth plate = di_gan) ---
# Sets _HQ_FOUND_PALACE (0 = not found)
_HQ_FOUND_PALACE=0
hq_find_stem_palace() {
    local target_stem="$1" p di
    _HQ_FOUND_PALACE=0
    for p in 1 2 3 4 5 6 7 8 9; do
        dl_get_v "palace_${p}_di_gan" 2>/dev/null || true; di="$_DL_RET"
        if [[ "$di" == "$target_stem" ]]; then
            _HQ_FOUND_PALACE=$p
            return 0
        fi
    done
    return 0
}

# Also check heaven plate (tian_gan)
hq_find_stem_palace_tian() {
    local target_stem="$1" p tg
    _HQ_FOUND_PALACE=0
    for p in 1 2 3 4 6 7 8 9; do
        dl_get_v "palace_${p}_tian_gan" 2>/dev/null || true; tg="$_DL_RET"
        if [[ "$tg" == "$target_stem" ]]; then
            _HQ_FOUND_PALACE=$p
            return 0
        fi
    done
    return 0
}

# --- Find gate in palaces ---
hq_find_gate_palace() {
    local target_gate="$1" p g
    _HQ_FOUND_PALACE=0
    for p in 1 2 3 4 6 7 8 9; do
        dl_get_v "palace_${p}_gate" 2>/dev/null || true; g="$_DL_RET"
        if [[ "$g" == "$target_gate" ]]; then
            _HQ_FOUND_PALACE=$p
            return 0
        fi
    done
    return 0
}

# --- Find deity in palaces ---
hq_find_deity_palace() {
    local target_deity="$1" p d
    _HQ_FOUND_PALACE=0
    for p in 1 2 3 4 6 7 8 9; do
        dl_get_v "palace_${p}_deity" 2>/dev/null || true; d="$_DL_RET"
        if [[ "$d" == "$target_deity" ]]; then
            _HQ_FOUND_PALACE=$p
            return 0
        fi
    done
    return 0
}

# --- Find star in palaces ---
hq_find_star_palace() {
    local target_star="$1" p s
    _HQ_FOUND_PALACE=0
    for p in 1 2 3 4 6 7 8 9; do
        dl_get_v "palace_${p}_star" 2>/dev/null || true; s="$_DL_RET"
        if [[ "$s" == "$target_star" ]]; then
            _HQ_FOUND_PALACE=$p
            return 0
        fi
    done
    return 0
}

# --- Detect 六害 for a palace ---
# Sets _HQ_LIUHAI as comma-separated list of active hazards
_HQ_LIUHAI=""
_HQ_LIUHAI_COUNT=0
hq_detect_liuhai() {
    local palace="$1"
    _HQ_LIUHAI=""
    _HQ_LIUHAI_COUNT=0
    local markers val deity

    dl_get_v "palace_${palace}_ji_xing" 2>/dev/null || true; val="$_DL_RET"
    if [[ "$val" == "true" ]]; then
        _HQ_LIUHAI="${_HQ_LIUHAI:+${_HQ_LIUHAI},}刑"
        _HQ_LIUHAI_COUNT=$((_HQ_LIUHAI_COUNT + 1))
    fi

    dl_get_v "palace_${palace}_rumu_gan" 2>/dev/null || true; val="$_DL_RET"
    if [[ "$val" == "true" ]]; then
        _HQ_LIUHAI="${_HQ_LIUHAI:+${_HQ_LIUHAI},}干墓"
        _HQ_LIUHAI_COUNT=$((_HQ_LIUHAI_COUNT + 1))
    fi
    dl_get_v "palace_${palace}_rumu_star" 2>/dev/null || true; val="$_DL_RET"
    if [[ "$val" == "true" ]]; then
        _HQ_LIUHAI="${_HQ_LIUHAI:+${_HQ_LIUHAI},}星墓"
        _HQ_LIUHAI_COUNT=$((_HQ_LIUHAI_COUNT + 1))
    fi
    dl_get_v "palace_${palace}_rumu_gate" 2>/dev/null || true; val="$_DL_RET"
    if [[ "$val" == "true" ]]; then
        _HQ_LIUHAI="${_HQ_LIUHAI:+${_HQ_LIUHAI},}门墓"
        _HQ_LIUHAI_COUNT=$((_HQ_LIUHAI_COUNT + 1))
    fi

    dl_get_v "palace_${palace}_geng" 2>/dev/null || true; val="$_DL_RET"
    if [[ "$val" == "true" ]]; then
        _HQ_LIUHAI="${_HQ_LIUHAI:+${_HQ_LIUHAI},}庚"
        _HQ_LIUHAI_COUNT=$((_HQ_LIUHAI_COUNT + 1))
    fi

    dl_get_v "palace_${palace}_deity" 2>/dev/null || true; deity="$_DL_RET"
    if [[ "$deity" == "白虎" ]]; then
        _HQ_LIUHAI="${_HQ_LIUHAI:+${_HQ_LIUHAI},}虎"
        _HQ_LIUHAI_COUNT=$((_HQ_LIUHAI_COUNT + 1))
    fi

    # 对宫影响: 玄武/庚/白虎影响本宫和对宫
    eval "local dui_palace=\"\${duigong_${palace}:-}\""
    if [[ -n "$dui_palace" && "$dui_palace" -gt 0 ]]; then
        # Check if opposite palace has 庚
        dl_get_v "palace_${dui_palace}_geng" 2>/dev/null || true; val="$_DL_RET"
        if [[ "$val" == "true" ]]; then
            # Only add if not already present from this palace
            if [[ "$_HQ_LIUHAI" != *"庚(对宫)"* && "$_HQ_LIUHAI" != *"庚"* ]]; then
                _HQ_LIUHAI="${_HQ_LIUHAI:+${_HQ_LIUHAI},}庚(对宫)"
                _HQ_LIUHAI_COUNT=$((_HQ_LIUHAI_COUNT + 1))
            fi
        fi

        # Check if opposite palace has 白虎
        dl_get_v "palace_${dui_palace}_deity" 2>/dev/null || true; local dui_deity="$_DL_RET"
        if [[ "$dui_deity" == "白虎" ]]; then
            if [[ "$_HQ_LIUHAI" != *"虎(对宫)"* && "$_HQ_LIUHAI" != *"虎"* ]]; then
                _HQ_LIUHAI="${_HQ_LIUHAI:+${_HQ_LIUHAI},}虎(对宫)"
                _HQ_LIUHAI_COUNT=$((_HQ_LIUHAI_COUNT + 1))
            fi
        fi

        # Check if opposite palace has 玄武
        if [[ "$dui_deity" == "玄武" ]]; then
            if [[ "$_HQ_LIUHAI" != *"玄武(对宫)"* ]]; then
                _HQ_LIUHAI="${_HQ_LIUHAI:+${_HQ_LIUHAI},}玄武(对宫)"
                _HQ_LIUHAI_COUNT=$((_HQ_LIUHAI_COUNT + 1))
            fi
        fi
    fi

    dl_get_v "palace_${palace}_men_po" 2>/dev/null || true; val="$_DL_RET"
    if [[ "$val" == "true" ]]; then
        _HQ_LIUHAI="${_HQ_LIUHAI:+${_HQ_LIUHAI},}迫"
        _HQ_LIUHAI_COUNT=$((_HQ_LIUHAI_COUNT + 1))
    fi

    dl_get_v "palace_${palace}_kong_wang" 2>/dev/null || true; val="$_DL_RET"
    if [[ "$val" == "true" ]]; then
        _HQ_LIUHAI="${_HQ_LIUHAI:+${_HQ_LIUHAI},}空"
        _HQ_LIUHAI_COUNT=$((_HQ_LIUHAI_COUNT + 1))
    fi
}

# --- Compute 月令五行 ---
HQ_YUEGLING_WX=""
hq_compute_yuegling() {
    local month_gz branch
    dl_get_v "plate_si_zhu_month" 2>/dev/null || true; month_gz="$_DL_RET"
    branch="$(_hq_extract_branch "$month_gz")"
    dl_get_v "zhi_wuxing_${branch}" 2>/dev/null || true
    HQ_YUEGLING_WX="$_DL_RET"
    dl_set "hq_yuegling_branch" "$branch"
    dl_set "hq_yuegling_wuxing" "$HQ_YUEGLING_WX"
}

# --- Compute 干财 ---
hq_compute_gan_cai() {
    local birth_year_stem="$1"
    local day_gz day_stem

    dl_get_v "plate_si_zhu_day" 2>/dev/null || true; day_gz="$_DL_RET"
    day_stem="$(_hq_extract_stem "$day_gz")"

    dl_set "hq_ri_gan" "$day_stem"
    dl_get_v "ke_${day_stem}" 2>/dev/null || true
    dl_set "hq_ri_gan_cai" "$_DL_RET"

    dl_set "hq_nian_gan" "$birth_year_stem"
    dl_get_v "ke_${birth_year_stem}" 2>/dev/null || true
    dl_set "hq_nian_gan_cai" "$_DL_RET"
}

# --- Locate a symbol in the plate ---
hq_locate_symbol() {
    local name="$1" type="$2"
    _HQ_FOUND_PALACE=0

    case "$type" in
        stem)
            hq_find_stem_palace "$name"
            if [[ $_HQ_FOUND_PALACE -eq 0 ]]; then
                hq_find_stem_palace_tian "$name"
            fi
            ;;
        stem_hour)
            local hour_gz stem
            dl_get_v "plate_si_zhu_hour" 2>/dev/null || true; hour_gz="$_DL_RET"
            stem="$(_hq_extract_stem "$hour_gz")"
            hq_find_stem_palace "$stem"
            if [[ $_HQ_FOUND_PALACE -eq 0 ]]; then
                hq_find_stem_palace_tian "$stem"
            fi
            ;;
        stem_geng)
            hq_find_stem_palace "庚"
            if [[ $_HQ_FOUND_PALACE -eq 0 ]]; then
                hq_find_stem_palace_tian "庚"
            fi
            ;;
        gate)
            hq_find_gate_palace "$name"
            ;;
        deity)
            hq_find_deity_palace "$name"
            ;;
        star)
            hq_find_star_palace "$name"
            ;;
    esac
}

# --- Collect palace summary for JSON ---
_HQ_PAL_JSON=""
hq_palace_summary_json() {
    local p="$1"
    local name wx dir star gate deity tg dg state

    dl_get_v "palace_${p}_name" 2>/dev/null || true; name="$_DL_RET"
    dl_get_v "palace_${p}_wuxing" 2>/dev/null || true; wx="$_DL_RET"
    dl_get_v "palace_${p}_direction" 2>/dev/null || true; dir="$_DL_RET"
    dl_get_v "palace_${p}_star" 2>/dev/null || true; star="$_DL_RET"
    dl_get_v "palace_${p}_gate" 2>/dev/null || true; gate="$_DL_RET"
    dl_get_v "palace_${p}_deity" 2>/dev/null || true; deity="$_DL_RET"
    dl_get_v "palace_${p}_tian_gan" 2>/dev/null || true; tg="$_DL_RET"
    dl_get_v "palace_${p}_di_gan" 2>/dev/null || true; dg="$_DL_RET"
    dl_get_v "palace_${p}_state" 2>/dev/null || true; state="$_DL_RET"

    hq_detect_liuhai "$p"

    _hq_je_v "$name"; local j_name="$_JE"
    _hq_je_v "$wx"; local j_wx="$_JE"
    _hq_je_v "$dir"; local j_dir="$_JE"
    _hq_je_v "$star"; local j_star="$_JE"
    _hq_je_v "$gate"; local j_gate="$_JE"
    _hq_je_v "$deity"; local j_deity="$_JE"
    _hq_je_v "$tg"; local j_tg="$_JE"
    _hq_je_v "$dg"; local j_dg="$_JE"
    _hq_je_v "$state"; local j_state="$_JE"
    _hq_je_v "$_HQ_LIUHAI"; local j_liuhai="$_JE"

    _HQ_PAL_JSON="\"name\": \"${j_name}\", \"wuxing\": \"${j_wx}\", \"direction\": \"${j_dir}\", \"star\": \"${j_star}\", \"gate\": \"${j_gate}\", \"deity\": \"${j_deity}\", \"tian_gan\": \"${j_tg}\", \"di_gan\": \"${j_dg}\", \"state\": \"${j_state}\", \"liuhai\": \"${j_liuhai}\", \"liuhai_count\": ${_HQ_LIUHAI_COUNT}"
}

# --- 月令 relation to key symbols ---
_HQ_YUEGLING_RELS_JSON=""
hq_compute_yuegling_relations() {
    local items="" first=1
    local p wx rel

    for p in 1 2 3 4 6 7 8 9; do
        dl_get_v "palace_${p}_wuxing" 2>/dev/null || true; wx="$_DL_RET"
        [[ -z "$wx" ]] && continue
        rel="$(hq_wuxing_relation "$HQ_YUEGLING_WX" "$wx")"

        dl_get_v "palace_${p}_star" 2>/dev/null || true; local star="$_DL_RET"
        dl_get_v "palace_${p}_gate" 2>/dev/null || true; local gate="$_DL_RET"
        dl_get_v "palace_${p}_deity" 2>/dev/null || true; local deity="$_DL_RET"

        _hq_je_v "$rel"; local j_rel="$_JE"
        _hq_je_v "$wx"; local j_wx="$_JE"
        _hq_je_v "$star"; local j_star="$_JE"
        _hq_je_v "$gate"; local j_gate="$_JE"
        _hq_je_v "$deity"; local j_deity="$_JE"

        (( first )) || items="${items},"
        first=0
        items="${items}
      { \"palace\": ${p}, \"wuxing\": \"${j_wx}\", \"relation\": \"${j_rel}\", \"star\": \"${j_star}\", \"gate\": \"${j_gate}\", \"deity\": \"${j_deity}\" }"
    done

    _hq_je_v "$HQ_YUEGLING_WX"; local j_yl="$_JE"
    dl_get_v "hq_yuegling_branch" 2>/dev/null || true
    _hq_je_v "$_DL_RET"; local j_br="$_JE"

    _HQ_YUEGLING_RELS_JSON="{ \"branch\": \"${j_br}\", \"wuxing\": \"${j_yl}\", \"palaces\": [${items}
    ] }"
}

# ================================================================
# 布阵 (Buzhen) pipeline — array placement system
# ================================================================

_bz_je_v() {
    _JE="$1"
    _JE="${_JE//\\/\\\\}"
    _JE="${_JE//\"/\\\"}"
}

_bz_extract_stem() {
    local gz="$1" g
    for g in 甲 乙 丙 丁 戊 己 庚 辛 壬 癸; do
        if [[ "$gz" == "${g}"* ]]; then
            echo "$g"
            return
        fi
    done
}

_bz_in_list() {
    local needle="$1" haystack="$2"
    local IFS=','
    local item
    for item in $haystack; do
        if [[ "$item" == "$needle" ]]; then
            return 0
        fi
    done
    return 1
}

# --- Step 1: Identify protected stems ---
_BZ_PROTECTED_STEMS=()
_BZ_PROTECTED_COUNT=0

bz_identify_protected_stems() {
    local birth_year_stem="$1" family_stems="$2" yixiang_concepts="$3"
    _BZ_PROTECTED_STEMS=()
    _BZ_PROTECTED_COUNT=0

    local day_gz hour_gz day_stem hour_stem
    dl_get_v "plate_si_zhu_day" 2>/dev/null || true; day_gz="$_DL_RET"
    dl_get_v "plate_si_zhu_hour" 2>/dev/null || true; hour_gz="$_DL_RET"
    day_stem="$(_bz_extract_stem "$day_gz")"
    hour_stem="$(_bz_extract_stem "$hour_gz")"

    hq_find_stem_palace_tian "$day_stem"
    if [[ $_HQ_FOUND_PALACE -eq 0 ]]; then
        hq_find_stem_palace "$day_stem"
    fi
    local day_palace=$_HQ_FOUND_PALACE
    _BZ_PROTECTED_STEMS+=("${day_stem}:日干:${day_palace}")

    hq_find_stem_palace_tian "$hour_stem"
    if [[ $_HQ_FOUND_PALACE -eq 0 ]]; then
        hq_find_stem_palace "$hour_stem"
    fi
    local hour_palace=$_HQ_FOUND_PALACE
    _BZ_PROTECTED_STEMS+=("${hour_stem}:时干:${hour_palace}")

    if [[ -n "$birth_year_stem" ]]; then
        hq_find_stem_palace_tian "$birth_year_stem"
        if [[ $_HQ_FOUND_PALACE -eq 0 ]]; then
            hq_find_stem_palace "$birth_year_stem"
        fi
        local byp=$_HQ_FOUND_PALACE
        _BZ_PROTECTED_STEMS+=("${birth_year_stem}:生年干:${byp}")
    fi

    if [[ -n "$family_stems" ]]; then
        local IFS=',' fs
        for fs in $family_stems; do
            [[ -z "$fs" ]] && continue
            hq_find_stem_palace_tian "$fs"
            if [[ $_HQ_FOUND_PALACE -eq 0 ]]; then
                hq_find_stem_palace "$fs"
            fi
            local fp=$_HQ_FOUND_PALACE
            _BZ_PROTECTED_STEMS+=("${fs}:家人年干:${fp}")
        done
    fi

    # 意象保护天干
    if [[ -n "$yixiang_concepts" ]]; then
        local IFS=',' yx
        for yx in $yixiang_concepts; do
            [[ -z "$yx" ]] && continue
            dl_get_v "yixiang_${yx}" 2>/dev/null || true
            local yx_stem="$_DL_RET"
            if [[ -n "$yx_stem" ]]; then
                hq_find_stem_palace_tian "$yx_stem"
                if [[ $_HQ_FOUND_PALACE -eq 0 ]]; then
                    hq_find_stem_palace "$yx_stem"
                fi
                local yxp=$_HQ_FOUND_PALACE
                _BZ_PROTECTED_STEMS+=("${yx_stem}:意象(${yx}):${yxp}")
            fi
        done
    fi

    dl_get_v "plate_zhi_fu_palace" 2>/dev/null || true; local zf_p="$_DL_RET"
    if [[ -n "$zf_p" && "$zf_p" -gt 0 && "$zf_p" -ne 5 ]]; then
        dl_get_v "palace_${zf_p}_tian_gan" 2>/dev/null || true; local zf_tg="$_DL_RET"
        if [[ -n "$zf_tg" ]]; then
            _BZ_PROTECTED_STEMS+=("${zf_tg}:值符宫干:${zf_p}")
        fi
    fi

    dl_get_v "plate_zhi_shi_palace" 2>/dev/null || true; local zs_p="$_DL_RET"
    if [[ -n "$zs_p" && "$zs_p" -gt 0 && "$zs_p" -ne 5 ]]; then
        dl_get_v "palace_${zs_p}_tian_gan" 2>/dev/null || true; local zs_tg="$_DL_RET"
        if [[ -n "$zs_tg" ]]; then
            _BZ_PROTECTED_STEMS+=("${zs_tg}:值使宫干:${zs_p}")
        fi
    fi

    _BZ_PROTECTED_COUNT=${#_BZ_PROTECTED_STEMS[@]}
}

# --- Step 2: Scan liuhai for all 8 palaces ---
_BZ_PAL_LIUHAI=("" "" "" "" "" "" "" "" "" "")
_BZ_PAL_LIUHAI_COUNT=(0 0 0 0 0 0 0 0 0 0)
_BZ_PAL_GATE=("" "" "" "" "" "" "" "" "" "")
_BZ_PAL_DEITY=("" "" "" "" "" "" "" "" "" "")
_BZ_PAL_TIAN_GAN=("" "" "" "" "" "" "" "" "" "")

bz_scan_all_palaces() {
    local p
    for p in 1 2 3 4 6 7 8 9; do
        hq_detect_liuhai "$p"
        _BZ_PAL_LIUHAI[$p]="$_HQ_LIUHAI"
        _BZ_PAL_LIUHAI_COUNT[$p]=$_HQ_LIUHAI_COUNT

        dl_get_v "palace_${p}_gate" 2>/dev/null || true
        _BZ_PAL_GATE[$p]="$_DL_RET"
        dl_get_v "palace_${p}_deity" 2>/dev/null || true
        _BZ_PAL_DEITY[$p]="$_DL_RET"
        dl_get_v "palace_${p}_tian_gan" 2>/dev/null || true
        _BZ_PAL_TIAN_GAN[$p]="$_DL_RET"
    done
}

# --- Step 3: Check protected stems safety ---
_BZ_PROTECTED_JSON=""

_bz_classify_dangers() {
    local liuhai="$1"
    local dangers=""
    if _bz_in_list "刑" "$liuhai"; then dangers="${dangers:+${dangers},}击刑"; fi
    if _bz_in_list "干墓" "$liuhai" || _bz_in_list "星墓" "$liuhai" || _bz_in_list "门墓" "$liuhai"; then
        dangers="${dangers:+${dangers},}入墓"
    fi
    if _bz_in_list "庚" "$liuhai" || _bz_in_list "庚(对宫)" "$liuhai"; then dangers="${dangers:+${dangers},}庚"; fi
    if _bz_in_list "虎" "$liuhai" || _bz_in_list "虎(对宫)" "$liuhai"; then dangers="${dangers:+${dangers},}白虎"; fi
    if _bz_in_list "玄武(对宫)" "$liuhai"; then dangers="${dangers:+${dangers},}玄武(对宫)"; fi
    if _bz_in_list "迫" "$liuhai"; then dangers="${dangers:+${dangers},}门迫"; fi
    if _bz_in_list "空" "$liuhai"; then dangers="${dangers:+${dangers},}空亡"; fi
    echo "$dangers"
}

bz_check_protected_safety() {
    local items="" first=1
    local i=0
    while [[ $i -lt $_BZ_PROTECTED_COUNT ]]; do
        local entry="${_BZ_PROTECTED_STEMS[$i]}"
        local stem role palace
        local IFS=':'
        read -r stem role palace <<< "$entry"
        IFS=','

        local dangers="" liuhai=""
        if [[ "$palace" -gt 0 && "$palace" -ne 5 ]]; then
            liuhai="${_BZ_PAL_LIUHAI[$palace]}"
            dangers="$(_bz_classify_dangers "$liuhai")"
        fi

        _bz_je_v "$stem"; local j_stem="$_JE"
        _bz_je_v "$role"; local j_role="$_JE"
        _bz_je_v "$dangers"; local j_dangers="$_JE"

        (( first )) || items="${items},"
        first=0
        items="${items}
      { \"stem\": \"${j_stem}\", \"role\": \"${j_role}\", \"palace\": ${palace}, \"dangers\": \"${j_dangers}\" }"

        i=$((i + 1))
    done

    _BZ_PROTECTED_JSON="[${items}
    ]"
}

# --- Step 4: Generate miexiang (灭象) list ---
_BZ_MIEXIANG_JSON=""
_BZ_MIEXIANG_TEXT_BLOCK=""

bz_generate_miexiang() {
    _BZ_MIEXIANG_TEXT_BLOCK=""
    local items="" first=1
    local p tg liuhai

    for p in 1 2 3 4 6 7 8 9; do
        liuhai="${_BZ_PAL_LIUHAI[$p]}"
        tg="${_BZ_PAL_TIAN_GAN[$p]}"
        [[ -z "$liuhai" ]] && continue

        local has_jixing=0 has_rumu=0 has_geng=0
        if _bz_in_list "刑" "$liuhai"; then has_jixing=1; fi
        if _bz_in_list "干墓" "$liuhai" || _bz_in_list "星墓" "$liuhai" || _bz_in_list "门墓" "$liuhai"; then has_rumu=1; fi
        if _bz_in_list "庚" "$liuhai" || _bz_in_list "庚(对宫)" "$liuhai"; then has_geng=1; fi

        if (( has_jixing == 0 && has_rumu == 0 && has_geng == 0 )); then
            continue
        fi

        local reason="" method=""
        if (( has_jixing )); then
            reason="${reason:+${reason}+}击刑"
            eval "method=\"\${miexiang_jixing_method:-}\""
            method="${method//;/,}"
        fi
        if (( has_rumu )); then
            reason="${reason:+${reason}+}入墓"
            eval "method=\"\${miexiang_rumu_method:-}\""
            method="${method//;/,}"
        fi
        if (( has_geng )); then
            reason="${reason:+${reason}+}庚"
            eval "method=\"\${miexiang_geng_method:-}\""
        fi

        local xiang_color="" xiang_material="" xiang_desc=""
        if [[ -n "$tg" ]]; then
            dl_get_v "xiang_${tg}" 2>/dev/null || true
            if [[ -n "$_DL_RET" ]]; then
                local IFS=','
                read -r xiang_color xiang_material xiang_desc <<< "$_DL_RET"
                IFS=','
            fi
        fi

        eval "local safe=\"\${safe_palaces:-7;1}\""
        safe="${safe//;/,}"

        local safe_dirs="" _sp
        local IFS=','
        for _sp in $safe; do
            dl_get_v "palace_${_sp}_direction" 2>/dev/null || true
            safe_dirs="${safe_dirs:+${safe_dirs},}${_DL_RET}(${_sp}宫)"
        done
        IFS=','

        dl_get_v "palace_${p}_name" 2>/dev/null || true; local pname="$_DL_RET"
        dl_get_v "palace_${p}_direction" 2>/dev/null || true; local pdir="$_DL_RET"

        _BZ_MIEXIANG_TEXT_BLOCK="${_BZ_MIEXIANG_TEXT_BLOCK}  ${pname}(${pdir}): 天盘${tg} — ${reason}
    物象: ${xiang_color} ${xiang_material} ${xiang_desc}
    灭象方式: ${method}
    安全方位: ${safe_dirs}

"

        _bz_je_v "$tg"; local j_tg="$_JE"
        _bz_je_v "$pname"; local j_pname="$_JE"
        _bz_je_v "$pdir"; local j_pdir="$_JE"
        _bz_je_v "$reason"; local j_reason="$_JE"
        _bz_je_v "$method"; local j_method="$_JE"
        _bz_je_v "$xiang_color"; local j_color="$_JE"
        _bz_je_v "$xiang_material"; local j_mat="$_JE"
        _bz_je_v "$xiang_desc"; local j_xdesc="$_JE"

        _bz_je_v "$safe_dirs"; local j_safe="$_JE"

        (( first )) || items="${items},"
        first=0
        items="${items}
      { \"palace\": ${p}, \"name\": \"${j_pname}\", \"direction\": \"${j_pdir}\", \"stem\": \"${j_tg}\", \"reason\": \"${j_reason}\", \"method\": \"${j_method}\", \"safe_to\": \"${j_safe}\", \"xiang\": { \"color\": \"${j_color}\", \"material\": \"${j_mat}\", \"desc\": \"${j_xdesc}\" } }"
    done

    _BZ_MIEXIANG_JSON="[${items}
    ]"
}

# --- Step 5+6: Generate buzhen prescription per palace ---
_BZ_BUZHEN_JSON=""
_BZ_BUZHEN_TEXT_BLOCK=""
_BZ_JINBI_TEXT_BLOCK=""

_bz_check_jinbi() {
    local stem="$1" palace="$2"
    dl_get_v "jinbi_${stem}" 2>/dev/null || true
    [[ -z "$_DL_RET" ]] && return 1
    _bz_in_list "$palace" "$_DL_RET"
}

_bz_get_xiang_tg_text() {
    local stem="$1"
    dl_get_v "xiang_${stem}" 2>/dev/null || true
    [[ -z "$_DL_RET" ]] && return
    local color material desc
    local IFS=','
    read -r color material desc <<< "$_DL_RET"
    echo "${color} ${material} ${desc}"
}

_bz_get_xiang_dz_text() {
    local branch="$1"
    dl_get_v "xiang_${branch}" 2>/dev/null || true
    [[ -z "$_DL_RET" ]] && return
    local color zodiac alt
    local IFS=','
    read -r color zodiac alt <<< "$_DL_RET"
    echo "${color} ${zodiac}(${alt})"
}

_bz_get_xiang_tg_json() {
    local stem="$1"
    dl_get_v "xiang_${stem}" 2>/dev/null || true
    if [[ -z "$_DL_RET" ]]; then
        echo "null"
        return
    fi
    local color material desc
    local IFS=','
    read -r color material desc <<< "$_DL_RET"
    _bz_je_v "$color"; local j_c="$_JE"
    _bz_je_v "$material"; local j_m="$_JE"
    _bz_je_v "$desc"; local j_d="$_JE"
    echo "{ \"color\": \"${j_c}\", \"material\": \"${j_m}\", \"desc\": \"${j_d}\" }"
}

_bz_get_xiang_dz_json() {
    local branch="$1"
    dl_get_v "xiang_${branch}" 2>/dev/null || true
    if [[ -z "$_DL_RET" ]]; then
        echo "null"
        return
    fi
    local color zodiac alt
    local IFS=','
    read -r color zodiac alt <<< "$_DL_RET"
    _bz_je_v "$color"; local j_c="$_JE"
    _bz_je_v "$zodiac"; local j_z="$_JE"
    _bz_je_v "$alt"; local j_a="$_JE"
    echo "{ \"color\": \"${j_c}\", \"zodiac\": \"${j_z}\", \"alt\": \"${j_a}\" }"
}

_bz_format_liuhai_brackets() {
    local liuhai="$1" result="" item seen_mu=0
    local IFS=','
    for item in $liuhai; do
        [[ -z "$item" ]] && continue
        case "$item" in
            干墓|星墓|门墓)
                (( seen_mu )) && continue
                seen_mu=1
                result="${result}[墓]"
                ;;
            *) result="${result}[${item}]" ;;
        esac
    done
    echo "$result"
}

_bz_build_wanwu_symbol_line() {
    local label="$1" map_type="$2" symbol="$3"
    [[ -z "$symbol" ]] && return 0

    local prefix="" colors="" detail=""
    dl_get_v "${map_type}_${symbol}" 2>/dev/null || true; prefix="$_DL_RET"
    [[ -z "$prefix" ]] && return 0

    dl_get_v "${prefix}_颜色" 2>/dev/null || true; colors="$_DL_RET"
    dl_get_v "${prefix}_器物" 2>/dev/null || true; local objects="$_DL_RET"
    dl_get_v "${prefix}_植物" 2>/dev/null || true; local plants="$_DL_RET"
    dl_get_v "${prefix}_动物" 2>/dev/null || true; local animals="$_DL_RET"
    # 地支用生肖字段
    if [[ -z "$animals" ]]; then
        dl_get_v "${prefix}_生肖" 2>/dev/null || true; animals="$_DL_RET"
    fi

    [[ -n "$colors" ]] && detail="(${colors})"
    [[ -n "$objects" ]] && detail="${detail:+${detail} }(${objects})"
    [[ -n "$plants" ]] && detail="${detail:+${detail} }(${plants})"
    [[ -n "$animals" ]] && detail="${detail:+${detail} }(${animals})"
    [[ -z "$detail" ]] && return 0

    echo "      ${label} ${symbol}: ${detail}"
}

_bz_build_wanwu_ref_text() {
    local p="$1"
    shift
    [[ "$_SHOW_WANWU" == "true" ]] || return 0
    local placed_items=("$@")
    local lines="" seen="" line=""

    local item
    for item in "${placed_items[@]}"; do
        [[ -z "$item" ]] && continue
        local type="${item%%:*}"
        local symbol="${item#*:}"
        [[ -z "$symbol" ]] && continue

        local check="${type}:${symbol}"
        case ",$seen," in *",${check},"*) continue ;; esac
        seen="${seen:+${seen},}${check}"

        local map_type=""
        case "$type" in
            tg) map_type="GAN"; line="$(_bz_build_wanwu_symbol_line "天干" "$map_type" "$symbol")" ;;
            dz) map_type="ZHI"; line="$(_bz_build_wanwu_symbol_line "地支" "$map_type" "$symbol")" ;;
            *) continue ;;
        esac
        [[ -n "$line" ]] && lines="${lines}${line}
"
    done

    if [[ -n "$lines" ]]; then
        printf '    参考(万物类象):\n%s' "$lines"
    fi
}

bz_generate_prescription() {
    local palace_items="" p_first=1
    local p
    _BZ_BUZHEN_TEXT_BLOCK=""
    _BZ_JINBI_TEXT_BLOCK=""

    for p in 1 2 3 4 6 7 8 9; do
        local liuhai="${_BZ_PAL_LIUHAI[$p]}"
        local gate="${_BZ_PAL_GATE[$p]}"
        local deity="${_BZ_PAL_DEITY[$p]}"

        local actions="" a_first=1
        local conflicts="" c_first=1
        local _bz_pal_text="" _bz_pal_jinbi=""
        local _bz_placed_items=()

        local has_jixing=0 has_rumu=0 has_menpo=0 has_geng=0 has_baihu=0 has_kong=0
        if _bz_in_list "刑" "$liuhai"; then has_jixing=1; fi
        if _bz_in_list "干墓" "$liuhai" || _bz_in_list "星墓" "$liuhai" || _bz_in_list "门墓" "$liuhai"; then has_rumu=1; fi
        if _bz_in_list "迫" "$liuhai"; then has_menpo=1; fi
        if _bz_in_list "庚" "$liuhai" || _bz_in_list "庚(对宫)" "$liuhai"; then has_geng=1; fi
        if _bz_in_list "虎" "$liuhai" || _bz_in_list "虎(对宫)" "$liuhai"; then has_baihu=1; fi
        if _bz_in_list "空" "$liuhai"; then has_kong=1; fi

        if (( has_jixing )); then
            eval "local jx_tg_str=\"\${yazhi_jixing_${p}_tg:-}\""
            eval "local jx_dz_str=\"\${yazhi_jixing_${p}_dz:-}\""
            eval "local jx_move_str=\"\${yazhi_jixing_${p}_move:-}\""

            local IFS='|' tg_item dz_item
            local tg_arr=() dz_arr=()
            for tg_item in $jx_tg_str; do tg_arr+=("$tg_item"); done
            for dz_item in $jx_dz_str; do dz_arr+=("$dz_item"); done
            IFS=','

            local tg_json="" tg_f=1
            for tg_item in "${tg_arr[@]}"; do
                local xj
                xj="$(_bz_get_xiang_tg_json "$tg_item")"
                _bz_je_v "$tg_item"; local j_ti="$_JE"

                local jinbi_flag="false"
                if _bz_check_jinbi "$tg_item" "$p"; then jinbi_flag="true"; fi

                (( tg_f )) || tg_json="${tg_json},"
                tg_f=0
                tg_json="${tg_json} { \"stem\": \"${j_ti}\", \"position\": \"高处\", \"xiang\": ${xj}, \"jinbi\": ${jinbi_flag} }"

                if [[ "$jinbi_flag" == "true" ]]; then
                    (( c_first )) || conflicts="${conflicts},"
                    c_first=0
                    conflicts="${conflicts} \"${j_ti}不可放${p}宫\""
                    local _jb_name _jb_dir
                    dl_get_v "palace_${p}_name" 2>/dev/null || true; _jb_name="$_DL_RET"
                    dl_get_v "palace_${p}_direction" 2>/dev/null || true; _jb_dir="$_DL_RET"
                    _bz_pal_jinbi="${_bz_pal_jinbi}  ${tg_item}不可放${_jb_name}(${_jb_dir})
"
                fi
            done

            local dz_json="" dz_f=1
            for dz_item in "${dz_arr[@]}"; do
                local xj
                xj="$(_bz_get_xiang_dz_json "$dz_item")"
                _bz_je_v "$dz_item"; local j_di="$_JE"

                (( dz_f )) || dz_json="${dz_json},"
                dz_f=0
                dz_json="${dz_json} { \"branch\": \"${j_di}\", \"position\": \"低处\", \"xiang\": ${xj} }"
            done

            _bz_je_v "$jx_move_str"; local j_move="$_JE"

            _bz_pal_text="${_bz_pal_text}    压击刑:
"
            for tg_item in "${tg_arr[@]}"; do
                local _xt; _xt="$(_bz_get_xiang_tg_text "$tg_item")"
                _bz_pal_text="${_bz_pal_text}      天干 ${tg_item} — 高处 ${_xt}
"
                _bz_placed_items+=("tg:${tg_item}")
            done
            for dz_item in "${dz_arr[@]}"; do
                local _xd; _xd="$(_bz_get_xiang_dz_text "$dz_item")"
                _bz_pal_text="${_bz_pal_text}      地支 ${dz_item} — 低处 ${_xd}
"
                _bz_placed_items+=("dz:${dz_item}")
            done

            (( a_first )) || actions="${actions},"
            a_first=0
            actions="${actions}
          { \"type\": \"压击刑\", \"tiangan\": [${tg_json} ], \"dizhi\": [${dz_json} ], \"move_away\": \"${j_move}\" }"
        fi

        if (( has_rumu )); then
            local rumu_desc=""
            if _bz_in_list "干墓" "$liuhai"; then
                dl_get_v "palace_${p}_tian_gan" 2>/dev/null || true
                [[ -n "$_DL_RET" ]] && rumu_desc="${rumu_desc:+${rumu_desc},}${_DL_RET}入墓"
            fi
            if _bz_in_list "星墓" "$liuhai"; then
                dl_get_v "palace_${p}_star" 2>/dev/null || true
                [[ -n "$_DL_RET" ]] && rumu_desc="${rumu_desc:+${rumu_desc},}${_DL_RET}入墓"
            fi
            if _bz_in_list "门墓" "$liuhai"; then
                dl_get_v "palace_${p}_gate" 2>/dev/null || true
                [[ -n "$_DL_RET" ]] && rumu_desc="${rumu_desc:+${rumu_desc},}${_DL_RET}入墓"
            fi
            eval "local rumu_dz=\"\${yazhi_rumu_${p}:-}\""
            if [[ -n "$rumu_dz" ]]; then
                local xj
                xj="$(_bz_get_xiang_dz_json "$rumu_dz")"
                _bz_je_v "$rumu_dz"; local j_rd="$_JE"

                (( a_first )) || actions="${actions},"
                a_first=0
                actions="${actions}
          { \"type\": \"压入墓\", \"tiangan\": [], \"dizhi\": [{ \"branch\": \"${j_rd}\", \"position\": \"低处\", \"xiang\": ${xj} }], \"move_away\": \"\" }"

                local _xd; _xd="$(_bz_get_xiang_dz_text "$rumu_dz")"
                _bz_pal_text="${_bz_pal_text}    压入墓(${rumu_desc}):
      地支 ${rumu_dz} — 低处 ${_xd}
"
                _bz_placed_items+=("dz:${rumu_dz}")
            fi
        fi

        if (( has_menpo )); then
            eval "local menpo_raw=\"\${yazhi_menpo_${p}:-}\""
            if [[ -n "$menpo_raw" ]]; then
                local IFS=';' mp_entry
                for mp_entry in $menpo_raw; do
                    local mp_gate="${mp_entry%%:*}"
                    local mp_dz_str="${mp_entry#*:}"

                    if [[ "$gate" == "$mp_gate" ]]; then
                        local IFS='|' mp_dz_item
                        local mp_dz_arr=()
                        for mp_dz_item in $mp_dz_str; do mp_dz_arr+=("$mp_dz_item"); done
                        IFS=','

                        local mp_dz_json="" mp_f=1
                        for mp_dz_item in "${mp_dz_arr[@]}"; do
                            local xj
                            xj="$(_bz_get_xiang_dz_json "$mp_dz_item")"
                            _bz_je_v "$mp_dz_item"; local j_md="$_JE"

                            (( mp_f )) || mp_dz_json="${mp_dz_json},"
                            mp_f=0
                            mp_dz_json="${mp_dz_json} { \"branch\": \"${j_md}\", \"position\": \"低处\", \"xiang\": ${xj} }"
                        done

                        _bz_je_v "$mp_gate"; local j_mg="$_JE"

                        (( a_first )) || actions="${actions},"
                        a_first=0
                        actions="${actions}
          { \"type\": \"压门迫\", \"gate\": \"${j_mg}\", \"tiangan\": [], \"dizhi\": [${mp_dz_json} ], \"move_away\": \"\" }"

                        _bz_pal_text="${_bz_pal_text}    压门迫:
"
                        for mp_dz_item in "${mp_dz_arr[@]}"; do
                            local _xd; _xd="$(_bz_get_xiang_dz_text "$mp_dz_item")"
                            _bz_pal_text="${_bz_pal_text}      地支 ${mp_dz_item} — 低处 ${_xd}
"
                            _bz_placed_items+=("dz:${mp_dz_item}")
                        done
                    fi
                done
            fi
        fi

        if (( has_geng || has_baihu )); then
            eval "local yg_stem=\"\${yazhi_geng_baihu:-乙}\""
            eval "local yg_jinbi_p=\"\${yazhi_geng_baihu_jinbi:-6}\""

            local jinbi_flag="false"
            if [[ "$p" == "$yg_jinbi_p" ]]; then
                jinbi_flag="true"
                (( c_first )) || conflicts="${conflicts},"
                c_first=0
                conflicts="${conflicts} \"${yg_stem}不可放${p}宫(入墓)\""
                local _jb_name2 _jb_dir2
                dl_get_v "palace_${p}_name" 2>/dev/null || true; _jb_name2="$_DL_RET"
                dl_get_v "palace_${p}_direction" 2>/dev/null || true; _jb_dir2="$_DL_RET"
                _bz_pal_jinbi="${_bz_pal_jinbi}  ${yg_stem}不可放${_jb_name2}(${_jb_dir2})[入墓]
"
            fi

            local xj
            xj="$(_bz_get_xiang_tg_json "$yg_stem")"
            _bz_je_v "$yg_stem"; local j_yg="$_JE"

            local reason_str=""
            if (( has_geng )); then reason_str="庚"; fi
            if (( has_baihu )); then reason_str="${reason_str:+${reason_str}+}白虎"; fi
            _bz_je_v "$reason_str"; local j_rs="$_JE"

            (( a_first )) || actions="${actions},"
            a_first=0
            actions="${actions}
          { \"type\": \"压庚白虎\", \"reason\": \"${j_rs}\", \"tiangan\": [{ \"stem\": \"${j_yg}\", \"position\": \"高处\", \"xiang\": ${xj}, \"jinbi\": ${jinbi_flag} }], \"dizhi\": [], \"move_away\": \"\" }"

            local _xt; _xt="$(_bz_get_xiang_tg_text "$yg_stem")"
            _bz_pal_text="${_bz_pal_text}    压庚白虎:
      天干 ${yg_stem} — 高处 ${_xt}
"
            _bz_placed_items+=("tg:${yg_stem}")
        fi

        if (( has_kong )); then
            local _pw_idx=$((p-1))
            local pw="${PALACE_WUXING[$_pw_idx]-}"
            local pzhi="${PALACE_DIZHI[$_pw_idx]-}"
            if [[ -z "$pw" ]]; then
                dl_get_v "palace_${p}_wuxing" 2>/dev/null || true
                pw="$_DL_RET"
            fi
            if [[ -z "$pzhi" ]]; then
                dl_get_v "palace_${p}_dizhi" 2>/dev/null || true
                pzhi="$_DL_RET"
            fi
            _bz_je_v "$pw"; local j_pw="$_JE"
            _bz_je_v "$pzhi"; local j_pz="$_JE"
            (( a_first )) || actions="${actions},"
            a_first=0
            actions="${actions}
          { \"type\": \"填空亡\", \"tiangan\": [], \"dizhi\": [], \"move_away\": \"\", \"wuxing\": \"${j_pw}\", \"palace_dizhi\": \"${j_pz}\", \"note\": \"补${j_pw}\" }"
            _bz_pal_text="${_bz_pal_text}    填空亡: 补${pw}
"

            local _kw_remaining="$pzhi"
            while [[ -n "$_kw_remaining" ]]; do
                local _kw_branch="" _kw_candidate
                for _kw_candidate in 子 丑 寅 卯 辰 巳 午 未 申 酉 戌 亥; do
                    if [[ "$_kw_remaining" == "${_kw_candidate}"* ]]; then
                        _kw_branch="$_kw_candidate"
                        _kw_remaining="${_kw_remaining#$_kw_candidate}"
                        break
                    fi
                done
                [[ -z "$_kw_branch" ]] && break
                local _xd; _xd="$(_bz_get_xiang_dz_text "$_kw_branch")"
                _bz_pal_text="${_bz_pal_text}      地支 ${_kw_branch} — 低处 ${_xd}
"
                _bz_placed_items+=("dz:${_kw_branch}")
            done
        fi

        if [[ -z "$actions" ]]; then
            continue
        fi

        local pal_name pal_dir
        dl_get_v "palace_${p}_name" 2>/dev/null || true; pal_name="$_DL_RET"
        dl_get_v "palace_${p}_direction" 2>/dev/null || true; pal_dir="$_DL_RET"
        _bz_je_v "$pal_name"; local j_pn="$_JE"
        _bz_je_v "$pal_dir"; local j_pd="$_JE"
        _bz_je_v "$liuhai"; local j_lh="$_JE"

        (( p_first )) || palace_items="${palace_items},"
        p_first=0
        palace_items="${palace_items}
    { \"palace\": ${p}, \"name\": \"${j_pn}\", \"direction\": \"${j_pd}\", \"liuhai\": \"${j_lh}\", \"actions\": [${actions}
      ], \"jinbi_conflicts\": [${conflicts} ] }"

        local liuhai_fmt
        liuhai_fmt="$(_bz_format_liuhai_brackets "$liuhai")"
        _BZ_BUZHEN_TEXT_BLOCK="${_BZ_BUZHEN_TEXT_BLOCK}  ${pal_name}(${pal_dir}) 六害: ${liuhai_fmt}
${_bz_pal_text}"
        local _bz_wanwu_ref
        if [[ ${#_bz_placed_items[@]} -gt 0 ]]; then
            _bz_wanwu_ref="$(_bz_build_wanwu_ref_text "$p" "${_bz_placed_items[@]}")"
        else
            _bz_wanwu_ref=""
        fi
        if [[ -n "$_bz_wanwu_ref" ]]; then
            _BZ_BUZHEN_TEXT_BLOCK="${_BZ_BUZHEN_TEXT_BLOCK}${_bz_wanwu_ref}

"
        else
            _BZ_BUZHEN_TEXT_BLOCK="${_BZ_BUZHEN_TEXT_BLOCK}
"
        fi
        if [[ -n "$_bz_pal_jinbi" ]]; then
            _BZ_JINBI_TEXT_BLOCK="${_BZ_JINBI_TEXT_BLOCK}${_bz_pal_jinbi}"
        fi
    done

    _BZ_BUZHEN_JSON="[${palace_items}
    ]"
}

# --- Buzhen text output ---
bz_output_text() {
    local birth_year_stem="$1"

    dl_get_v "plate_datetime" 2>/dev/null || true; local dt="$_DL_RET"
    dl_get_v "plate_si_zhu_year" 2>/dev/null || true; local sz_y="$_DL_RET"
    dl_get_v "plate_si_zhu_month" 2>/dev/null || true; local sz_m="$_DL_RET"
    dl_get_v "plate_si_zhu_day" 2>/dev/null || true; local sz_d="$_DL_RET"
    dl_get_v "plate_si_zhu_hour" 2>/dev/null || true; local sz_h="$_DL_RET"
    dl_get_v "plate_ju_type" 2>/dev/null || true; local ju_t="$_DL_RET"
    dl_get_v "plate_ju_number" 2>/dev/null || true; local ju_n="$_DL_RET"
    dl_get_v "plate_ju_yuan" 2>/dev/null || true; local ju_yuan="$_DL_RET"

    echo "化气阵分析"
    echo "========"
    if [[ -n "${_BIRTH_DATETIME:-}" ]]; then
        echo "出生时间: ${_BIRTH_DATETIME}"
    fi
    if [[ -n "${_BIRTH_SIZHU:-}" ]]; then
        echo "出生四柱: ${_BIRTH_SIZHU}"
    fi
    echo "年干: ${birth_year_stem}"
    if [[ "${_SHOW_EVENT_HEADER:-}" == "true" ]]; then
        echo ""
        echo "起局时间: ${dt}"
        echo "起局四柱: ${sz_y} ${sz_m} ${sz_d} ${sz_h}"
        echo "局  : ${ju_t}${ju_n}局 (${ju_yuan})"
    fi
    echo ""

    echo "=== 保护天干 ==="
    local i=0
    while [[ $i -lt $_BZ_PROTECTED_COUNT ]]; do
        local entry="${_BZ_PROTECTED_STEMS[$i]}"
        local stem role palace
        local IFS=':'
        read -r stem role palace <<< "$entry"
        IFS=','

        local pname="" pdir="" dangers=""
        if [[ "$palace" -gt 0 ]]; then
            dl_get_v "palace_${palace}_name" 2>/dev/null || true; pname="$_DL_RET"
            dl_get_v "palace_${palace}_direction" 2>/dev/null || true; pdir="$_DL_RET"
            local liuhai="${_BZ_PAL_LIUHAI[$palace]}"
            dangers="$(_bz_classify_dangers "$liuhai")"
        fi

        local loc_str="${palace}宫"
        if [[ -n "$pname" ]]; then
            loc_str="${pname}(${pdir})"
        fi

        if [[ -n "$dangers" ]]; then
            echo "  ${stem}(${role}) — ${loc_str}  危险: ${dangers}"
        else
            echo "  ${stem}(${role}) — ${loc_str}"
        fi
        i=$((i + 1))
    done
    echo ""

    if [[ -n "$_BZ_MIEXIANG_TEXT_BLOCK" ]]; then
        echo "=== 灭象 ==="
        printf '%s' "$_BZ_MIEXIANG_TEXT_BLOCK"
        echo ""
    fi

    if [[ -n "$_BZ_BUZHEN_TEXT_BLOCK" ]]; then
        echo "=== 布阵 ==="
        printf '%s' "$_BZ_BUZHEN_TEXT_BLOCK"
        echo ""
    fi

    if [[ -n "$_BZ_JINBI_TEXT_BLOCK" ]]; then
        echo "=== 禁忌 ==="
        printf '%s' "$_BZ_JINBI_TEXT_BLOCK"
        echo ""
    fi

    echo "=== 注意事项 ==="
    eval "local pos_tg=\"\${position_tiangan:-高处}\""
    eval "local pos_dz=\"\${position_dizhi:-低处}\""
    eval "local pos_note=\"\${position_note:-}\""
    eval "local caution=\"\${buzhen_caution:-}\""
    echo "  天干摆${pos_tg}，地支摆${pos_dz}，${pos_note}"
    if [[ -n "$caution" ]]; then
        echo "  ${caution}"
    fi
}

# --- Buzhen JSON output ---
bz_output_json() {
    local output_path="$1"

    dl_get_v "plate_datetime" 2>/dev/null || true; local dt="$_DL_RET"
    dl_get_v "plate_si_zhu_year" 2>/dev/null || true; local sz_y="$_DL_RET"
    dl_get_v "plate_si_zhu_month" 2>/dev/null || true; local sz_m="$_DL_RET"
    dl_get_v "plate_si_zhu_day" 2>/dev/null || true; local sz_d="$_DL_RET"
    dl_get_v "plate_si_zhu_hour" 2>/dev/null || true; local sz_h="$_DL_RET"
    dl_get_v "plate_ju_type" 2>/dev/null || true; local ju_t="$_DL_RET"
    dl_get_v "plate_ju_number" 2>/dev/null || true; local ju_n="$_DL_RET"
    dl_get_v "plate_ju_yuan" 2>/dev/null || true; local ju_yuan="$_DL_RET"

    _bz_je_v "$dt"; local j_dt="$_JE"
    _bz_je_v "$sz_y"; local j_sy="$_JE"
    _bz_je_v "$sz_m"; local j_sm="$_JE"
    _bz_je_v "$sz_d"; local j_sd="$_JE"
    _bz_je_v "$sz_h"; local j_sh="$_JE"
    _bz_je_v "$ju_t"; local j_jt="$_JE"
    _bz_je_v "$ju_yuan"; local j_jy="$_JE"

    eval "local pos_tg=\"\${position_tiangan:-高处}\""
    eval "local pos_dz=\"\${position_dizhi:-低处}\""
    eval "local pos_note=\"\${position_note:-}\""
    eval "local caution=\"\${buzhen_caution:-}\""
    _bz_je_v "$pos_tg"; local j_ptg="$_JE"
    _bz_je_v "$pos_dz"; local j_pdz="$_JE"
    _bz_je_v "$pos_note"; local j_pn="$_JE"
    _bz_je_v "$caution"; local j_cau="$_JE"

    cat > "$output_path" <<ENDJSON
{
  "datetime": "${j_dt}",
  "si_zhu": { "year": "${j_sy}", "month": "${j_sm}", "day": "${j_sd}", "hour": "${j_sh}" },
  "ju": { "type": "${j_jt}", "number": ${ju_n:-0}, "yuan": "${j_jy}" },
  "protected_stems": ${_BZ_PROTECTED_JSON},
  "miexiang": ${_BZ_MIEXIANG_JSON},
  "buzhen": ${_BZ_BUZHEN_JSON},
  "global_notes": { "position_tiangan": "${j_ptg}", "position_dizhi": "${j_pdz}", "position_note": "${j_pn}", "caution": "${j_cau}" }
}
ENDJSON
}

# --- Buzhen pipeline entry point ---
bz_run_analysis() {
    local input_path="$1" birth_year_stem="$2" family_stems="$3" yixiang_concepts="$4" output_path="$5"

    qa_parse_plate_json "$input_path"

    bz_scan_all_palaces
    bz_identify_protected_stems "$birth_year_stem" "$family_stems" "$yixiang_concepts"
    bz_check_protected_safety
    bz_generate_miexiang
    bz_generate_prescription

    bz_output_text "$birth_year_stem"
    bz_output_json "$output_path"
}
