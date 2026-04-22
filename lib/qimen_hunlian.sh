#!/usr/bin/env bash
# Copyright (C) 2025 — Licensed under GPL-3.0
# See https://www.gnu.org/licenses/gpl-3.0.html
# qimen_hunlian.sh — 婚恋分析 core computation library.
# Sourced AFTER data_loader.sh, qimen_analysis.sh, qimen_banmenhuaqizhen.sh.

# --- JSON helpers ---
_JE=""
_hl_je_v() { _JE="$1"; _JE="${_JE//\\/\\\\}"; _JE="${_JE//\"/\\\"}"; }

_hl_extract_birth_ri_gan() {
    # Args: $1 = birth JSON path
    # Echoes: day stem
    local line="" filepath="$1"
    while IFS= read -r line; do
        if [[ "$line" == *'"day":'* ]]; then
            local val="${line#*\"day\": \"}"
            val="${val%%\"*}"
            _hq_extract_stem "$val"
            return 0
        fi
    done < "$filepath"
    return 1
}

_hl_extract_birth_nian_zhi() {
    # Args: $1 = birth JSON path
    # Echoes: year branch
    local line="" filepath="$1"
    while IFS= read -r line; do
        if [[ "$line" == *'"year":'* ]]; then
            local val="${line#*\"year\": \"}"
            val="${val%%\"*}"
            _hq_extract_branch "$val"
            return 0
        fi
    done < "$filepath"
    return 1
}

_hl_extract_birth_header() {
    local filepath="$1" line="" dt="" y="" m="" d="" h=""
    _HL_BIRTH_DATETIME=""
    _HL_BIRTH_SIZHU=""
    while IFS= read -r line; do
        if [[ "$line" == *'"datetime":'* ]]; then
            dt="${line#*\"datetime\": \"}"
            dt="${dt%%\"*}"
            _HL_BIRTH_DATETIME="$dt"
        fi
        if [[ "$line" == *'"year":'* && -z "$y" ]]; then
            y="${line#*\"year\": \"}"; y="${y%%\"*}"
        fi
        if [[ "$line" == *'"month":'* && -z "$m" ]]; then
            m="${line#*\"month\": \"}"; m="${m%%\"*}"
        fi
        if [[ "$line" == *'"day":'* && -z "$d" ]]; then
            d="${line#*\"day\": \"}"; d="${d%%\"*}"
        fi
        if [[ "$line" == *'"hour":'* && -z "$h" ]]; then
            h="${line#*\"hour\": \"}"; h="${h%%\"*}"
        fi
    done < "$filepath"
    _HL_BIRTH_SIZHU="${y} ${m} ${d} ${h}"
}

# --- Globals ---
_HL_BIRTH_DATETIME=""
_HL_BIRTH_SIZHU=""
_HL_RIGAN_STEM=""
_HL_RIGAN_PALACE=0
_HL_GANHE_STEM=""
_HL_GANHE_PALACE=0
_HL_LIUHE_PALACE=0
_HL_SANQI_YI_PALACE=0
_HL_SANQI_BING_PALACE=0
_HL_SANQI_DING_PALACE=0
_HL_TIANPENG_PALACE=0
_HL_SHANGMEN_PALACE=0
_HL_DING_PALACE=0
_HL_GUI_PALACE=0

_HL_TAOHUA_RIGAN_SANQI=()
_HL_TAOHUA_GANHE_SANQI=()
_HL_TAOHUA_XUANWU_RIGAN="false"
_HL_TAOHUA_XUANWU_GANHE="false"
_HL_TAOHUA_TAIYIN_RIGAN="false"
_HL_TAOHUA_TAIYIN_GANHE="false"
_HL_TAOHUA_RIGAN_AT_MUYU="false"
_HL_TAOHUA_GANHE_AT_MUYU="false"
_HL_TAOHUA_RENGUIWITH_RIGAN="false"
_HL_TAOHUA_RENGUIWITH_GANHE="false"
_HL_RUMU_PALACES=""
_HL_PIANCAI_STEM=""
_HL_PIANCAI_SANQI="false"
_HL_PIANCAI_SANQI_STEM=""
_HL_ZHAN_SOURCES=""
_HL_PROTECT_GANHE="true"
_HL_PROTECT_LIUHE="true"

_HL_FUYIN_PALACES=""
_HL_FANYIN_PALACES=""
_HL_IS_FUYIN_JU="false"
_HL_IS_FANYIN_JU="false"

_HL_RIGAN_KW="false"
_HL_GANHE_KW="false"
_HL_LIUHE_KW="false"
_HL_KW_PALACE_1=0
_HL_KW_PALACE_2=0

_HL_GEN8_LIUHAI=""
_HL_GEN8_LIUHAI_COUNT=0
_HL_GEN8_HAS_GENG="false"
_HL_GEN8_HAS_BAIHU="false"
_HL_KUN2_LIUHAI=""
_HL_KUN2_LIUHAI_COUNT=0
_HL_KUN2_HAS_GENG="false"
_HL_KUN2_HAS_BAIHU="false"

_HL_GC_GROUP=""
_HL_GC_GUCHEN=""
_HL_GC_GUASU=""
_HL_GC_JH_DZ1=""
_HL_GC_JH_DZ2=""
_HL_GC_JH_SX1=""
_HL_GC_JH_SX2=""

hl_find_ri_gan() {
    local stem="$1"
    _HL_RIGAN_STEM="$stem"
    _HL_RIGAN_PALACE=0

    hq_find_stem_palace_tian "$stem"
    if (( _HQ_FOUND_PALACE > 0 )); then
        _HL_RIGAN_PALACE=$_HQ_FOUND_PALACE
        return 0
    fi
    hq_find_stem_palace "$stem"
    _HL_RIGAN_PALACE=$_HQ_FOUND_PALACE
}

hl_find_gan_he() {
    local ri_gan="$1"
    dl_get_v "ganhe_${ri_gan}"; _HL_GANHE_STEM="$_DL_RET"
    _HL_GANHE_PALACE=0

    if [[ -n "$_HL_GANHE_STEM" ]]; then
        hq_find_stem_palace_tian "$_HL_GANHE_STEM"
        if (( _HQ_FOUND_PALACE > 0 )); then
            _HL_GANHE_PALACE=$_HQ_FOUND_PALACE
            return 0
        fi
        hq_find_stem_palace "$_HL_GANHE_STEM"
        _HL_GANHE_PALACE=$_HQ_FOUND_PALACE
    fi
}

hl_find_liuhe() {
    hq_find_deity_palace "六合"
    _HL_LIUHE_PALACE=$_HQ_FOUND_PALACE
}

hl_find_sanqi() {
    hq_find_stem_palace_tian "乙"
    _HL_SANQI_YI_PALACE=$_HQ_FOUND_PALACE
    if (( _HL_SANQI_YI_PALACE == 0 )); then
        hq_find_stem_palace "乙"; _HL_SANQI_YI_PALACE=$_HQ_FOUND_PALACE
    fi

    hq_find_stem_palace_tian "丙"
    _HL_SANQI_BING_PALACE=$_HQ_FOUND_PALACE
    if (( _HL_SANQI_BING_PALACE == 0 )); then
        hq_find_stem_palace "丙"; _HL_SANQI_BING_PALACE=$_HQ_FOUND_PALACE
    fi

    hq_find_stem_palace_tian "丁"
    _HL_SANQI_DING_PALACE=$_HQ_FOUND_PALACE
    if (( _HL_SANQI_DING_PALACE == 0 )); then
        hq_find_stem_palace "丁"; _HL_SANQI_DING_PALACE=$_HQ_FOUND_PALACE
    fi
}

hl_find_tianpeng() {
    hq_find_star_palace "天蓬"
    _HL_TIANPENG_PALACE=$_HQ_FOUND_PALACE
}

hl_find_shangmen() {
    hq_find_gate_palace "伤门"
    _HL_SHANGMEN_PALACE=$_HQ_FOUND_PALACE
}

hl_find_ding_gui() {
    hq_find_stem_palace_tian "丁"
    _HL_DING_PALACE=$_HQ_FOUND_PALACE
    if (( _HL_DING_PALACE == 0 )); then
        hq_find_stem_palace "丁"; _HL_DING_PALACE=$_HQ_FOUND_PALACE
    fi

    hq_find_stem_palace_tian "癸"
    _HL_GUI_PALACE=$_HQ_FOUND_PALACE
    if (( _HL_GUI_PALACE == 0 )); then
        hq_find_stem_palace "癸"; _HL_GUI_PALACE=$_HQ_FOUND_PALACE
    fi
}

hl_detect_taohua() {
    _HL_TAOHUA_RIGAN_SANQI=()
    _HL_TAOHUA_GANHE_SANQI=()
    _HL_TAOHUA_XUANWU_RIGAN="false"
    _HL_TAOHUA_XUANWU_GANHE="false"
    _HL_TAOHUA_TAIYIN_RIGAN="false"
    _HL_TAOHUA_TAIYIN_GANHE="false"
    _HL_TAOHUA_RIGAN_AT_MUYU="false"
    _HL_TAOHUA_GANHE_AT_MUYU="false"
    _HL_TAOHUA_RENGUIWITH_RIGAN="false"
    _HL_TAOHUA_RENGUIWITH_GANHE="false"

    local rp=$_HL_RIGAN_PALACE gp=$_HL_GANHE_PALACE

    if (( rp > 0 )); then
        if (( _HL_SANQI_YI_PALACE == rp )); then _HL_TAOHUA_RIGAN_SANQI+=("乙"); fi
        if (( _HL_SANQI_BING_PALACE == rp )); then _HL_TAOHUA_RIGAN_SANQI+=("丙"); fi
        if (( _HL_SANQI_DING_PALACE == rp )); then _HL_TAOHUA_RIGAN_SANQI+=("丁"); fi
    fi

    if (( gp > 0 )); then
        if (( _HL_SANQI_YI_PALACE == gp )); then _HL_TAOHUA_GANHE_SANQI+=("乙"); fi
        if (( _HL_SANQI_BING_PALACE == gp )); then _HL_TAOHUA_GANHE_SANQI+=("丙"); fi
        if (( _HL_SANQI_DING_PALACE == gp )); then _HL_TAOHUA_GANHE_SANQI+=("丁"); fi
    fi

    local xuanwu_p=0 taiyin_p=0
    hq_find_deity_palace "玄武"; xuanwu_p=$_HQ_FOUND_PALACE
    hq_find_deity_palace "太阴"; taiyin_p=$_HQ_FOUND_PALACE

    if (( rp > 0 )); then
        if (( xuanwu_p == rp )); then _HL_TAOHUA_XUANWU_RIGAN="true"; fi
        if (( taiyin_p == rp )); then _HL_TAOHUA_TAIYIN_RIGAN="true"; fi
    fi
    if (( gp > 0 )); then
        if (( xuanwu_p == gp )); then _HL_TAOHUA_XUANWU_GANHE="true"; fi
        if (( taiyin_p == gp )); then _HL_TAOHUA_TAIYIN_GANHE="true"; fi
    fi

    dl_get_v "muyu_${_HL_RIGAN_STEM}"; local muyu_raw="$_DL_RET"
    local muyu_palace="${muyu_raw##*,}"
    if (( rp > 0 && muyu_palace == rp )); then _HL_TAOHUA_RIGAN_AT_MUYU="true"; fi
    if (( gp > 0 && muyu_palace == gp )); then _HL_TAOHUA_GANHE_AT_MUYU="true"; fi

    if (( rp > 0 )); then
        local tg="" dg=""
        dl_get_v "palace_${rp}_tian_gan"; tg="$_DL_RET"
        dl_get_v "palace_${rp}_di_gan"; dg="$_DL_RET"
        if [[ "$tg" == "壬" || "$tg" == "癸" || "$dg" == "壬" || "$dg" == "癸" ]]; then
            _HL_TAOHUA_RENGUIWITH_RIGAN="true"
        fi
    fi
    if (( gp > 0 )); then
        local tg="" dg=""
        dl_get_v "palace_${gp}_tian_gan"; tg="$_DL_RET"
        dl_get_v "palace_${gp}_di_gan"; dg="$_DL_RET"
        if [[ "$tg" == "壬" || "$tg" == "癸" || "$dg" == "壬" || "$dg" == "癸" ]]; then
            _HL_TAOHUA_RENGUIWITH_GANHE="true"
        fi
    fi
}

hl_compute_zhan_taohua() {
    _HL_RUMU_PALACES=""
    _HL_PIANCAI_STEM=""
    _HL_PIANCAI_SANQI="false"
    _HL_PIANCAI_SANQI_STEM=""
    _HL_ZHAN_SOURCES=""
    _HL_PROTECT_GANHE="true"
    _HL_PROTECT_LIUHE="true"

    local p stem

    for p in 1 2 3 4 6 7 8 9; do
        if (( ${QM_RUMU_GAN[$p]:-0} == 1 )); then
            _HL_RUMU_PALACES="${_HL_RUMU_PALACES:+${_HL_RUMU_PALACES},}${p}"
        fi
    done

    dl_get_v "ke_${_HL_RIGAN_STEM}"
    _HL_PIANCAI_STEM="$_DL_RET"

    if [[ "$_HL_PIANCAI_STEM" == "乙" || "$_HL_PIANCAI_STEM" == "丙" || "$_HL_PIANCAI_STEM" == "丁" ]]; then
        _HL_PIANCAI_SANQI="true"
        _HL_PIANCAI_SANQI_STEM="$_HL_PIANCAI_STEM"
    fi

    if [[ "$_HL_TAOHUA_XUANWU_RIGAN" == "true" || "$_HL_TAOHUA_XUANWU_GANHE" == "true" ]]; then
        case ",${_HL_ZHAN_SOURCES}," in
            *,玄武,*) ;;
            *) _HL_ZHAN_SOURCES="${_HL_ZHAN_SOURCES:+${_HL_ZHAN_SOURCES},}玄武" ;;
        esac
    fi
    if [[ "$_HL_TAOHUA_TAIYIN_RIGAN" == "true" || "$_HL_TAOHUA_TAIYIN_GANHE" == "true" ]]; then
        case ",${_HL_ZHAN_SOURCES}," in
            *,太阴,*) ;;
            *) _HL_ZHAN_SOURCES="${_HL_ZHAN_SOURCES:+${_HL_ZHAN_SOURCES},}太阴" ;;
        esac
    fi
    if [[ "$_HL_TAOHUA_RENGUIWITH_RIGAN" == "true" || "$_HL_TAOHUA_RENGUIWITH_GANHE" == "true" ]]; then
        case ",${_HL_ZHAN_SOURCES}," in
            *,壬癸,*) ;;
            *) _HL_ZHAN_SOURCES="${_HL_ZHAN_SOURCES:+${_HL_ZHAN_SOURCES},}壬癸" ;;
        esac
    fi

    if (( ${#_HL_TAOHUA_RIGAN_SANQI[@]} > 0 )); then
        for stem in "${_HL_TAOHUA_RIGAN_SANQI[@]}"; do
            if [[ "$stem" != "$_HL_PIANCAI_STEM" ]]; then
                case ",${_HL_ZHAN_SOURCES}," in
                    *,"${stem}",*) ;;
                    *) _HL_ZHAN_SOURCES="${_HL_ZHAN_SOURCES:+${_HL_ZHAN_SOURCES},}${stem}" ;;
                esac
            fi
        done
    fi
    if (( ${#_HL_TAOHUA_GANHE_SANQI[@]} > 0 )); then
        for stem in "${_HL_TAOHUA_GANHE_SANQI[@]}"; do
            if [[ "$stem" != "$_HL_PIANCAI_STEM" ]]; then
                case ",${_HL_ZHAN_SOURCES}," in
                    *,"${stem}",*) ;;
                    *) _HL_ZHAN_SOURCES="${_HL_ZHAN_SOURCES:+${_HL_ZHAN_SOURCES},}${stem}" ;;
                esac
            fi
        done
    fi
}

hl_detect_fuyin_fanyin() {
    _HL_FUYIN_PALACES=""
    _HL_FANYIN_PALACES=""
    _HL_IS_FUYIN_JU="false"
    _HL_IS_FANYIN_JU="false"
    local p fuyin_count=0 fanyin_count=0

    for p in 1 2 3 4 6 7 8 9; do
        dl_get_v "palace_${p}_gan_fu_yin" 2>/dev/null || true
        if [[ "$_DL_RET" == "true" ]]; then
            _HL_FUYIN_PALACES="${_HL_FUYIN_PALACES:+${_HL_FUYIN_PALACES},}${p}"
            fuyin_count=$((fuyin_count + 1))
        fi
    done

    for p in 1 2 3 4 6 7 8 9; do
        dl_get_v "palace_${p}_gan_fan_yin" 2>/dev/null || true
        if [[ "$_DL_RET" == "true" ]]; then
            _HL_FANYIN_PALACES="${_HL_FANYIN_PALACES:+${_HL_FANYIN_PALACES},}${p}"
            fanyin_count=$((fanyin_count + 1))
        fi
    done

    if (( fuyin_count >= 4 )); then _HL_IS_FUYIN_JU="true"; fi
    if (( fanyin_count >= 4 )); then _HL_IS_FANYIN_JU="true"; fi
}

hl_check_kongwang() {
    _HL_RIGAN_KW="false"
    _HL_GANHE_KW="false"
    _HL_LIUHE_KW="false"

    dl_get_v "plate_kong_wang_0_palace"; _HL_KW_PALACE_1="$_DL_RET"
    dl_get_v "plate_kong_wang_1_palace"; _HL_KW_PALACE_2="$_DL_RET"

    local kw1=${_HL_KW_PALACE_1:-0} kw2=${_HL_KW_PALACE_2:-0}

    if (( _HL_RIGAN_PALACE > 0 )); then
        if (( _HL_RIGAN_PALACE == kw1 || _HL_RIGAN_PALACE == kw2 )); then
            _HL_RIGAN_KW="true"
        fi
    fi
    if (( _HL_GANHE_PALACE > 0 )); then
        if (( _HL_GANHE_PALACE == kw1 || _HL_GANHE_PALACE == kw2 )); then
            _HL_GANHE_KW="true"
        fi
    fi
    if (( _HL_LIUHE_PALACE > 0 )); then
        if (( _HL_LIUHE_PALACE == kw1 || _HL_LIUHE_PALACE == kw2 )); then
            _HL_LIUHE_KW="true"
        fi
    fi
}

hl_check_gen_kun() {
    _HL_GEN8_LIUHAI=""
    _HL_GEN8_LIUHAI_COUNT=0
    _HL_GEN8_HAS_GENG="false"
    _HL_GEN8_HAS_BAIHU="false"
    _HL_KUN2_LIUHAI=""
    _HL_KUN2_LIUHAI_COUNT=0
    _HL_KUN2_HAS_GENG="false"
    _HL_KUN2_HAS_BAIHU="false"

    hq_detect_liuhai 8
    _HL_GEN8_LIUHAI="$_HQ_LIUHAI"
    _HL_GEN8_LIUHAI_COUNT=$_HQ_LIUHAI_COUNT
    dl_get_v "palace_8_geng"; [[ "$_DL_RET" == "true" ]] && _HL_GEN8_HAS_GENG="true" || _HL_GEN8_HAS_GENG="false"
    dl_get_v "palace_8_deity"; [[ "$_DL_RET" == "白虎" ]] && _HL_GEN8_HAS_BAIHU="true" || _HL_GEN8_HAS_BAIHU="false"

    hq_detect_liuhai 2
    _HL_KUN2_LIUHAI="$_HQ_LIUHAI"
    _HL_KUN2_LIUHAI_COUNT=$_HQ_LIUHAI_COUNT
    dl_get_v "palace_2_geng"; [[ "$_DL_RET" == "true" ]] && _HL_KUN2_HAS_GENG="true" || _HL_KUN2_HAS_GENG="false"
    dl_get_v "palace_2_deity"; [[ "$_DL_RET" == "白虎" ]] && _HL_KUN2_HAS_BAIHU="true" || _HL_KUN2_HAS_BAIHU="false"
}

hl_compute_guchen_guasu() {
    local nian_zhi="$1"
    _HL_GC_GROUP=""
    _HL_GC_GUCHEN=""
    _HL_GC_GUASU=""
    _HL_GC_JH_DZ1=""
    _HL_GC_JH_DZ2=""
    _HL_GC_JH_SX1=""
    _HL_GC_JH_SX2=""

    local group=""
    case "$nian_zhi" in
        亥|子|丑) group="亥子丑" ;;
        寅|卯|辰) group="寅卯辰" ;;
        巳|午|未) group="巳午未" ;;
        申|酉|戌) group="申酉戌" ;;
        *) return 1 ;;
    esac
    _HL_GC_GROUP="$group"

    dl_get_v "guchen_guasu_${group}"; local gc_raw="$_DL_RET"
    _HL_GC_GUCHEN="${gc_raw%%,*}"
    _HL_GC_GUASU="${gc_raw##*,}"

    _HL_GC_JH_DZ1="$(_hl_dizhi_liuhe "$_HL_GC_GUCHEN")"
    _HL_GC_JH_DZ2="$(_hl_dizhi_liuhe "$_HL_GC_GUASU")"
    _HL_GC_JH_SX1="$(_hl_dizhi_shengxiao "$_HL_GC_JH_DZ1")"
    _HL_GC_JH_SX2="$(_hl_dizhi_shengxiao "$_HL_GC_JH_DZ2")"
}

_hl_palaces_to_names() {
    local nums="$1" result="" p
    if [[ -z "$nums" ]]; then echo "无"; return; fi
    local IFS=','
    for p in $nums; do
        result="${result:+${result} }$(_hl_palace_label "$p")"
    done
    echo "$result"
}

# --- Shared helpers (duplicated from caiguan for independence) ---

_hl_stem_wuxing() {
    case "$1" in
        甲|乙) echo "木";; 丙|丁) echo "火";; 戊|己) echo "土";;
        庚|辛) echo "金";; 壬|癸) echo "水";; *) echo "";;
    esac
}

_hl_star_wuxing() {
    local name="$1" i=0
    while [[ $i -lt ${#STAR_NAMES[@]} ]]; do
        if [[ "${STAR_NAMES[$i]}" == "$name" ]]; then
            echo "${STAR_WUXING[$i]}"; return
        fi
        i=$((i + 1))
    done
}

_hl_gate_wuxing() {
    local name="$1" i=0
    while [[ $i -lt ${#GATE_NAMES[@]} ]]; do
        if [[ "${GATE_NAMES[$i]}" == "$name" ]]; then
            echo "${GATE_WUXING[$i]}"; return
        fi
        i=$((i + 1))
    done
}

_hl_star_jixi() {
    local name="$1" i=0
    while [[ $i -lt ${#STAR_NAMES[@]} ]]; do
        if [[ "${STAR_NAMES[$i]}" == "$name" ]]; then
            echo "${STAR_JIXI[$i]}"; return
        fi
        i=$((i + 1))
    done
}

_hl_gate_jixi() {
    local name="$1" i=0
    while [[ $i -lt ${#GATE_NAMES[@]} ]]; do
        if [[ "${GATE_NAMES[$i]}" == "$name" ]]; then
            echo "${GATE_JIXI[$i]}"; return
        fi
        i=$((i + 1))
    done
}

_hl_dizhi_direction() {
    case "$1" in
        子) echo "北";;
        丑|寅) echo "东北";;
        卯) echo "东";;
        辰|巳) echo "东南";;
        午) echo "南";;
        未|申) echo "西南";;
        酉) echo "西";;
        戌|亥) echo "西北";;
        *) echo "";;
    esac
}

_hl_dizhi_liuhe() {
    case "$1" in
        子) echo "丑";; 丑) echo "子";;
        寅) echo "亥";; 亥) echo "寅";;
        卯) echo "戌";; 戌) echo "卯";;
        辰) echo "酉";; 酉) echo "辰";;
        巳) echo "申";; 申) echo "巳";;
        午) echo "未";; 未) echo "午";;
        *) echo "";;
    esac
}

_hl_dizhi_shengxiao() {
    case "$1" in
        子) echo "鼠";; 丑) echo "牛";; 寅) echo "虎";; 卯) echo "兔";;
        辰) echo "龙";; 巳) echo "蛇";; 午) echo "马";; 未) echo "羊";;
        申) echo "猴";; 酉) echo "鸡";; 戌) echo "狗";; 亥) echo "猪";;
        *) echo "";;
    esac
}

_hl_palace_label() {
    local p="$1"
    if [[ $p -le 0 ]]; then echo "不在盘上"; return; fi
    if [[ $p -eq 5 ]]; then echo "中5宫(中,土)"; return; fi
    local bgua=""
    case $p in
        1) bgua="坎";; 2) bgua="坤";; 3) bgua="震";; 4) bgua="巽";;
        6) bgua="乾";; 7) bgua="兑";; 8) bgua="艮";; 9) bgua="离";;
    esac
    dl_get_v "palace_${p}_direction" 2>/dev/null || true; local pdir="$_DL_RET"
    dl_get_v "palace_${p}_wuxing" 2>/dev/null || true; local pwx="$_DL_RET"
    echo "${bgua}${p}宫(${pdir},${pwx})"
}

_hl_print_palace_detail() {
    local p="$1" indent="${2:-    }"
    dl_get_v "palace_${p}_tian_gan" 2>/dev/null || true; local tg="$_DL_RET"
    dl_get_v "palace_${p}_di_gan" 2>/dev/null || true; local dg="$_DL_RET"
    dl_get_v "palace_${p}_star" 2>/dev/null || true; local star="$_DL_RET"
    dl_get_v "palace_${p}_gate" 2>/dev/null || true; local gate="$_DL_RET"
    dl_get_v "palace_${p}_deity" 2>/dev/null || true; local deity="$_DL_RET"
    local tg_wx="" dg_wx=""
    tg_wx="$(_hl_stem_wuxing "$tg")"
    dg_wx="$(_hl_stem_wuxing "$dg")"
    local star_jx="" star_wx="" gate_jx="" gate_wx=""
    if [[ -n "$star" ]]; then
        star_jx="$(_hl_star_jixi "$star")"
        star_wx="$(_hl_star_wuxing "$star")"
    fi
    if [[ -n "$gate" ]]; then
        gate_jx="$(_hl_gate_jixi "$gate")"
        gate_wx="$(_hl_gate_wuxing "$gate")"
    fi
    [[ -n "$tg_wx" ]] && printf '%s天盘: %s(%s)\n' "$indent" "$tg" "$tg_wx" || printf '%s天盘: %s\n' "$indent" "$tg"
    [[ -n "$dg_wx" ]] && printf '%s地盘: %s(%s)\n' "$indent" "$dg" "$dg_wx" || printf '%s地盘: %s\n' "$indent" "$dg"
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

_hl_print_palace_wanwu() {
    local palace_num="$1"
    [[ -n "$palace_num" && "$palace_num" != "0" ]] || return 0
    [[ "$_SHOW_WANWU" == "true" ]] || return 0
    local prefix="wanwu_${palace_num}_"
    local prefix_len=${#prefix}
    local has_wanwu=0
    local el el_cn el_prefix el_prefix_len el_first k v field i
    for el in star gate deity tian_gan di_gan; do
        case "$el" in
            star) el_cn="星" ;;
            gate) el_cn="门" ;;
            deity) el_cn="神" ;;
            tian_gan) el_cn="天干" ;;
            di_gan) el_cn="地干" ;;
        esac
        el_prefix="${prefix}${el}_"
        el_prefix_len=${#el_prefix}
        el_first=1
        for ((i=0; i<${#_DL_KEYS[@]}; i++)); do
            k="${_DL_KEYS[$i]}"
            if [[ "$k" == "${el_prefix}"* ]]; then
                v="${_DL_VALS[$i]}"
                [[ -n "$v" ]] || continue
                field="${k:$el_prefix_len}"
                case "$field" in
                    五行|五行阴阳|核心描述|场所环境|身体|疾病|身体疾病|事业行为|占断适宜|占断不宜|地理|概念|身体脏腑|占断含义) continue ;;
                esac
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
}

hl_output_text() {
    printf '婚恋分析\n'
    printf '========\n'
    printf '出生时间: %s\n' "$_HL_BIRTH_DATETIME"
    printf '出生四柱: %s\n' "$_HL_BIRTH_SIZHU"
    if [[ "${_SHOW_EVENT_HEADER:-}" == "true" ]]; then
        local evt_dt="" evt_sz_y="" evt_sz_m="" evt_sz_d="" evt_sz_h=""
        dl_get_v "plate_datetime"; evt_dt="$_DL_RET"
        dl_get_v "plate_si_zhu_year"; evt_sz_y="$_DL_RET"
        dl_get_v "plate_si_zhu_month"; evt_sz_m="$_DL_RET"
        dl_get_v "plate_si_zhu_day"; evt_sz_d="$_DL_RET"
        dl_get_v "plate_si_zhu_hour"; evt_sz_h="$_DL_RET"
        printf '\n'
        printf '起局时间: %s\n' "$evt_dt"
        printf '起局四柱: %s %s %s %s\n' "$evt_sz_y" "$evt_sz_m" "$evt_sz_d" "$evt_sz_h"
    fi

    # --- 日干(自己) ---
    local rp=$_HL_RIGAN_PALACE
    local rigan_wx=""
    rigan_wx="$(_hl_stem_wuxing "$_HL_RIGAN_STEM")"
    printf '日干(自己) — %s(%s) — %s\n' "$_HL_RIGAN_STEM" "$rigan_wx" "$(_hl_palace_label "$rp")"
    if (( rp > 0 && rp != 5 )); then
        _hl_print_palace_detail "$rp" "  "
    fi
    _hl_print_palace_wanwu "$_HL_RIGAN_PALACE"

    # --- 干合(配偶星) ---
    local gp=$_HL_GANHE_PALACE
    local ganhe_wx=""
    ganhe_wx="$(_hl_stem_wuxing "$_HL_GANHE_STEM")"
    printf '\n干合(配偶星) — %s(%s) — %s\n' "$_HL_GANHE_STEM" "$ganhe_wx" "$(_hl_palace_label "$gp")"
    printf '  干合代表配偶/伴侣，%s合%s\n' "$_HL_RIGAN_STEM" "$_HL_GANHE_STEM"
    if (( gp > 0 && gp != 5 )); then
        _hl_print_palace_detail "$gp" "  "
    fi
    _hl_print_palace_wanwu "$_HL_GANHE_PALACE"

    # --- 六合(姻缘媒人) ---
    local lp=$_HL_LIUHE_PALACE
    printf '\n六合(姻缘媒人) — %s\n' "$(_hl_palace_label "$lp")"
    printf '  人缘,合,媒,多,婚,恋,约,缘,人与人的亲密关系\n'
    if (( lp > 0 && lp != 5 )); then
        _hl_print_palace_detail "$lp" "  "
    fi
    _hl_print_palace_wanwu "$_HL_LIUHE_PALACE"

    # --- 沐浴位(桃花位) ---
    dl_get_v "muyu_${_HL_RIGAN_STEM}"; local muyu_raw="$_DL_RET"
    local muyu_dz="${muyu_raw%%,*}" muyu_p="${muyu_raw##*,}"
    printf '\n沐浴位(桃花位) — %s %s\n' "$muyu_dz" "$(_hl_palace_label "${muyu_p:-0}")"
    printf '  赤裸袒露,鱼水之欢,一夜情,淫荡,放纵,泄密\n'

    # --- 三奇 ---
    printf '\n三奇:\n'
    local sq_stems=("乙" "丙" "丁")
    local sq_palaces=($_HL_SANQI_YI_PALACE $_HL_SANQI_BING_PALACE $_HL_SANQI_DING_PALACE)
    local sq_descs=("温柔,如沐春风" "热辣,骚女猛男" "妖艳,玉女,阴柔")
    local i sn sp _sq_has_tongong=0
    for i in 0 1 2; do
        sn="${sq_stems[$i]}"
        sp="${sq_palaces[$i]}"
        local sq_wx=""
        sq_wx="$(_hl_stem_wuxing "$sn")"
        local with_rigan="" with_ganhe=""
        if (( sp > 0 && sp == _HL_RIGAN_PALACE )); then with_rigan=" [与日干同宫]"; _sq_has_tongong=1; fi
        if (( sp > 0 && sp == _HL_GANHE_PALACE )); then with_ganhe=" [与干合同宫]"; _sq_has_tongong=1; fi
        printf '  %s(%s,%s): %s%s%s\n' "$sn" "$sq_wx" "${sq_descs[$i]}" "$(_hl_palace_label "$sp")" "$with_rigan" "$with_ganhe"
    done
    if (( _sq_has_tongong )); then
        printf '  日干和干合遇到三奇,沐浴在同宫,即为桃花\n'
    fi

    # --- 桃花检测 ---
    local _taohua_found=0
    if (( ${#_HL_TAOHUA_RIGAN_SANQI[@]} > 0 )); then _taohua_found=1; fi
    if (( ${#_HL_TAOHUA_GANHE_SANQI[@]} > 0 )); then _taohua_found=1; fi
    [[ "$_HL_TAOHUA_XUANWU_RIGAN" == "true" ]] && _taohua_found=1
    [[ "$_HL_TAOHUA_XUANWU_GANHE" == "true" ]] && _taohua_found=1
    [[ "$_HL_TAOHUA_TAIYIN_RIGAN" == "true" ]] && _taohua_found=1
    [[ "$_HL_TAOHUA_TAIYIN_GANHE" == "true" ]] && _taohua_found=1
    [[ "$_HL_TAOHUA_RIGAN_AT_MUYU" == "true" ]] && _taohua_found=1
    [[ "$_HL_TAOHUA_GANHE_AT_MUYU" == "true" ]] && _taohua_found=1
    [[ "$_HL_TAOHUA_RENGUIWITH_RIGAN" == "true" ]] && _taohua_found=1
    [[ "$_HL_TAOHUA_RENGUIWITH_GANHE" == "true" ]] && _taohua_found=1
    if (( _taohua_found )); then
        printf '\n桃花检测:\n'
        printf '  烂桃花: 太阴(私密),玄武(偷人),壬癸(风流)\n'
        if (( ${#_HL_TAOHUA_RIGAN_SANQI[@]} > 0 )); then
            printf '  日干与三奇同宫: %s\n' "${_HL_TAOHUA_RIGAN_SANQI[*]}"
        fi
        if (( ${#_HL_TAOHUA_GANHE_SANQI[@]} > 0 )); then
            printf '  干合与三奇同宫: %s\n' "${_HL_TAOHUA_GANHE_SANQI[*]}"
        fi
        [[ "$_HL_TAOHUA_XUANWU_RIGAN" == "true" ]] && printf '  玄武与日干同宫 — 偷人\n'
        [[ "$_HL_TAOHUA_XUANWU_GANHE" == "true" ]] && printf '  玄武与干合同宫 — 偷人\n'
        [[ "$_HL_TAOHUA_TAIYIN_RIGAN" == "true" ]] && printf '  太阴与日干同宫 — 私密\n'
        [[ "$_HL_TAOHUA_TAIYIN_GANHE" == "true" ]] && printf '  太阴与干合同宫 — 私密\n'
        [[ "$_HL_TAOHUA_RIGAN_AT_MUYU" == "true" ]] && printf '  日干在沐浴位\n'
        [[ "$_HL_TAOHUA_GANHE_AT_MUYU" == "true" ]] && printf '  干合在沐浴位\n'
        [[ "$_HL_TAOHUA_RENGUIWITH_RIGAN" == "true" ]] && printf '  壬癸与日干同宫 — 风流\n'
        [[ "$_HL_TAOHUA_RENGUIWITH_GANHE" == "true" ]] && printf '  壬癸与干合同宫 — 风流\n'

        printf '斩桃花:\n'
        local _zt_targets="" _zt_target_palaces="" _zt_p=""
        if (( ${_HL_KW_PALACE_1:-0} > 0 )); then
            _zt_targets="${_zt_targets:+${_zt_targets},}空亡$(_hl_palace_label "$_HL_KW_PALACE_1")"
            _zt_target_palaces="${_zt_target_palaces:+${_zt_target_palaces},}${_HL_KW_PALACE_1}"
        fi
        if (( ${_HL_KW_PALACE_2:-0} > 0 )); then
            case ",${_zt_target_palaces}," in
                *,"${_HL_KW_PALACE_2}",*) ;;
                *)
                    _zt_targets="${_zt_targets:+${_zt_targets},}空亡$(_hl_palace_label "$_HL_KW_PALACE_2")"
                    _zt_target_palaces="${_zt_target_palaces:+${_zt_target_palaces},}${_HL_KW_PALACE_2}"
                    ;;
            esac
        fi
        if [[ -n "$_HL_RUMU_PALACES" ]]; then
            local IFS=','
            for _zt_p in $_HL_RUMU_PALACES; do
                [[ -n "$_zt_p" ]] || continue
                case ",${_zt_target_palaces}," in
                    *,"${_zt_p}",*) ;;
                    *)
                        _zt_targets="${_zt_targets:+${_zt_targets},}入墓$(_hl_palace_label "$_zt_p")"
                        _zt_target_palaces="${_zt_target_palaces:+${_zt_target_palaces},}${_zt_p}"
                        ;;
                esac
            done
        fi
        printf '  镇压目标宫位: %s\n' "${_zt_targets:-无}"
        printf '  镇压: 将烂桃花象放入以上宫位方位\n'
        if [[ -n "$_HL_ZHAN_SOURCES" ]]; then
            local IFS=',' _zt_src
            for _zt_src in $_HL_ZHAN_SOURCES; do
                [[ -n "$_zt_src" ]] || continue
                printf '  镇压%s: 将%s的象放入空亡/入墓宫的方位\n' "$_zt_src" "$_zt_src"
            done
        fi
        if [[ "$_HL_PIANCAI_SANQI" == "true" ]]; then
            printf '  偏财保护: %s奇(偏财)不可镇压,代表挣钱能力\n' "$_HL_PIANCAI_SANQI_STEM"
        fi
        printf '  保护干合(配偶),六合(人缘)\n'
    fi

    # --- 伏吟反吟 ---
    local _fy_has=0
    if [[ "$_HL_IS_FUYIN_JU" == "true" ]]; then
        _fy_has=1
    fi
    if [[ "$_HL_IS_FANYIN_JU" == "true" ]]; then
        _fy_has=1
    fi
    if (( _fy_has )); then
        printf '\n伏吟反吟:\n'
        if [[ "$_HL_IS_FUYIN_JU" == "true" ]]; then
            printf '  伏吟局 — 执着,难受,孤独,大器晚成,心思专一,做事认真,不懂变通,感情严肃沉重,单纯单向\n'
        fi
        if [[ "$_HL_IS_FANYIN_JU" == "true" ]]; then
            printf '  反吟局 — 折腾不断,很难长久,短期恋情,事多无暇,不稳定,朝三暮四,换来换去\n'
        fi
    fi

    # --- 空亡影响 ---
    local _kw_found=0
    [[ "$_HL_RIGAN_KW" == "true" ]] && _kw_found=1
    [[ "$_HL_GANHE_KW" == "true" ]] && _kw_found=1
    [[ "$_HL_LIUHE_KW" == "true" ]] && _kw_found=1
    if (( _kw_found )); then
        printf '\n空亡影响:\n'
        [[ "$_HL_RIGAN_KW" == "true" ]] && printf '  日干空亡 — 自己不现实，错失姻缘\n'
        [[ "$_HL_GANHE_KW" == "true" ]] && printf '  干合空亡 — 意中人一直不出现\n'
        [[ "$_HL_LIUHE_KW" == "true" ]] && printf '  六合空亡 — 互相有意愿，但没有交往的机会\n'
        # kongwang remedy
        local _kw_dz1="" _kw_dz2=""
        dl_get_v "plate_kong_wang_0_branch" 2>/dev/null || true; _kw_dz1="$_DL_RET"
        dl_get_v "plate_kong_wang_1_branch" 2>/dev/null || true; _kw_dz2="$_DL_RET"
        if [[ -n "$_kw_dz1" || -n "$_kw_dz2" ]]; then
            printf '  解空亡: 在空亡所在宫位放空亡对应的形象\n'
            if [[ -n "$_kw_dz1" ]] && (( ${_HL_KW_PALACE_1:-0} > 0 )); then
                local _kw_sx1=""
                _kw_sx1="$(_hl_dizhi_shengxiao "$_kw_dz1")"
                printf '  %s放%s(%s)的象\n' "$(_hl_palace_label "$_HL_KW_PALACE_1")" "$_kw_dz1" "$_kw_sx1"
            fi
            if [[ -n "$_kw_dz2" ]] && (( ${_HL_KW_PALACE_2:-0} > 0 )); then
                local _kw_sx2=""
                _kw_sx2="$(_hl_dizhi_shengxiao "$_kw_dz2")"
                printf '  %s放%s(%s)的象\n' "$(_hl_palace_label "$_HL_KW_PALACE_2")" "$_kw_dz2" "$_kw_sx2"
            fi
        fi
    fi

    # --- 艮坤刑迫 ---
    printf '\n艮坤刑迫:\n'
    printf '  艮宫(东北)和坤宫(西南)属土(调和)，出问题则家庭出问题\n'
    printf '  有击刑和门迫: 非常伤害感情。遇庚+白虎更甚: 受情伤，感情复杂\n'

    printf '\n  艮8宫(东北,土):\n'
    _hl_print_palace_detail 8 "    "
    if [[ -n "$_HL_GEN8_LIUHAI" ]]; then
        printf '    六害: %s\n' "$(_bz_format_liuhai_brackets "$_HL_GEN8_LIUHAI")"
    else
        printf '    六害: 无\n'
    fi

    printf '\n  坤2宫(西南,土):\n'
    _hl_print_palace_detail 2 "    "
    if [[ -n "$_HL_KUN2_LIUHAI" ]]; then
        printf '    六害: %s\n' "$(_bz_format_liuhai_brackets "$_HL_KUN2_LIUHAI")"
    else
        printf '    六害: 无\n'
    fi
    printf '  用化气阵化解\n'

    # --- 孤辰寡宿 ---
    printf '\n孤辰寡宿:\n'
    printf '  不同属相(生年地支)的孤辰和寡宿\n'
    printf '  组: %s\n' "$_HL_GC_GROUP"
    local _gc_p1="" _gc_p2=""
    dl_get_v "dizhi_palace_${_HL_GC_GUCHEN}" 2>/dev/null || true; _gc_p1="$_DL_RET"
    dl_get_v "dizhi_palace_${_HL_GC_GUASU}" 2>/dev/null || true; _gc_p2="$_DL_RET"
    printf '  孤辰: %s — %s\n' "$_HL_GC_GUCHEN" "$(_hl_palace_label "${_gc_p1:-0}")"
    printf '  寡宿: %s — %s\n' "$_HL_GC_GUASU" "$(_hl_palace_label "${_gc_p2:-0}")"
    printf '  化解孤辰: %s放%s(%s)的象\n' "$(_hl_palace_label "${_gc_p1:-0}")" "$_HL_GC_JH_DZ1" "$_HL_GC_JH_SX1"
    printf '  化解寡宿: %s放%s(%s)的象\n' "$(_hl_palace_label "${_gc_p2:-0}")" "$_HL_GC_JH_DZ2" "$_HL_GC_JH_SX2"

    # --- 增加情趣 ---
    printf '\n增加情趣:\n'
    printf '  丁(男): 器官,大小,耐久力\n'
    printf '  癸(女): 器官,大小,耐受力\n'
    printf '  催情: 男催癸,女催丁\n'
    printf '  生助丁癸,或将其放入日干宫\n'
    printf '  在丁宫放木火,生助丁\n'
    printf '  在癸宫放金水,生助癸\n'
    printf '  情趣场合: 女方看到红色,男方看到蓝色,女方多带金玉首饰,房间点蜡烛\n'

    if (( _HL_SHANGMEN_PALACE > 0 )); then
        printf '\n  伤门(刺激) — %s\n' "$(_hl_palace_label "$_HL_SHANGMEN_PALACE")"
        printf '    姿势,花样,挑逗,不满足\n'
        printf '    短期将天干和干合放入伤门所在宫方位,适用特殊性癖,切记只能短期\n'
        if (( _HL_SHANGMEN_PALACE != 5 )); then
            _hl_print_palace_detail "$_HL_SHANGMEN_PALACE" "    "
        fi
    fi

    if (( _HL_TIANPENG_PALACE > 0 )); then
        printf '\n  天蓬(性魅力) — %s\n' "$(_hl_palace_label "$_HL_TIANPENG_PALACE")"
        printf '    极致的性魅力,致命吸引力\n'
        printf '    多穿毛绒绒,女性爱毛绒,男友魅力爆棚\n'
        printf '    养猫狗也是创造情趣,情感补偿,养大狗,情趣猛\n'
        printf '    将蓝黑色带毛的东西放到日干宫\n'
        if (( _HL_TIANPENG_PALACE != 5 )); then
            _hl_print_palace_detail "$_HL_TIANPENG_PALACE" "    "
        fi
    fi

    if (( _HL_DING_PALACE > 0 )); then
        printf '\n  丁奇(男) — %s\n' "$(_hl_palace_label "$_HL_DING_PALACE")"
        if (( _HL_DING_PALACE != 5 )); then
            _hl_print_palace_detail "$_HL_DING_PALACE" "    "
        fi
    fi

    if (( _HL_GUI_PALACE > 0 )); then
        printf '\n  癸水(女) — %s\n' "$(_hl_palace_label "$_HL_GUI_PALACE")"
        if (( _HL_GUI_PALACE != 5 )); then
            _hl_print_palace_detail "$_HL_GUI_PALACE" "    "
        fi
    fi
}

_hl_palace_info_json() {
    local p="$1" fd="$2" indent="$3"
    local tg dg star gate deity state
    dl_get_v "palace_${p}_tian_gan" 2>/dev/null || true; tg="$_DL_RET"
    dl_get_v "palace_${p}_di_gan" 2>/dev/null || true; dg="$_DL_RET"
    dl_get_v "palace_${p}_star" 2>/dev/null || true; star="$_DL_RET"
    dl_get_v "palace_${p}_gate" 2>/dev/null || true; gate="$_DL_RET"
    dl_get_v "palace_${p}_deity" 2>/dev/null || true; deity="$_DL_RET"
    dl_get_v "palace_${p}_state" 2>/dev/null || true; state="$_DL_RET"
    _hl_je_v "$tg"; local j_tg="$_JE"
    _hl_je_v "$dg"; local j_dg="$_JE"
    _hl_je_v "$star"; local j_star="$_JE"
    _hl_je_v "$gate"; local j_gate="$_JE"
    _hl_je_v "$deity"; local j_deity="$_JE"
    _hl_je_v "$state"; local j_state="$_JE"
    printf '%s"palace_info": {\n' "$indent" >&"$fd"
    printf '%s  "tian_gan": "%s",\n' "$indent" "$j_tg" >&"$fd"
    printf '%s  "di_gan": "%s",\n' "$indent" "$j_dg" >&"$fd"
    printf '%s  "star": "%s",\n' "$indent" "$j_star" >&"$fd"
    printf '%s  "gate": "%s",\n' "$indent" "$j_gate" >&"$fd"
    printf '%s  "deity": "%s",\n' "$indent" "$j_deity" >&"$fd"
    printf '%s  "state": "%s"\n' "$indent" "$j_state" >&"$fd"
    printf '%s}' "$indent" >&"$fd"
}

_hl_liuhai_json_array() {
    local liuhai_csv="$1"
    if [[ -z "$liuhai_csv" ]]; then echo "[]"; return; fi
    local result="[" item="" first=1
    local IFS=','
    for item in $liuhai_csv; do
        _hl_je_v "$item"
        if (( first )); then first=0; else result+=", "; fi
        result+="\"$_JE\""
    done
    result+="]"
    echo "$result"
}

_hl_array_json() {
    local item="" first=1 out="["
    for item in "$@"; do
        _hl_je_v "$item"
        if (( first )); then first=0; else out+=", "; fi
        out+="\"$_JE\""
    done
    out+="]"
    echo "$out"
}

_hl_output_loc_json() {
    local p="$1" fd="$2" indent="$3"
    local name="" direction=""
    if (( p > 0 )); then
        dl_get_v "palace_${p}_name" 2>/dev/null || true; name="$_DL_RET"
        dl_get_v "palace_${p}_direction" 2>/dev/null || true; direction="$_DL_RET"
    fi
    _hl_je_v "$name"; local j_name="$_JE"
    _hl_je_v "$direction"; local j_dir="$_JE"
    printf '%s"palace": %s,\n' "$indent" "$p" >&"$fd"
    printf '%s"name": "%s",\n' "$indent" "$j_name" >&"$fd"
    printf '%s"direction": "%s",\n' "$indent" "$j_dir" >&"$fd"
    local trailing="${4:-}"
    if (( p > 0 )); then
        _hl_palace_info_json "$p" "$fd" "$indent"
        printf '%s\n' "$trailing" >&"$fd"
    else
        printf '%s"palace_info": null%s\n' "$indent" "$trailing" >&"$fd"
    fi
}

_hl_emit_palace_wanwu_json() {
    local fd="$1" palace_num="$2"
    [[ -n "$palace_num" && "$palace_num" != "0" ]] || return 0
    local prefix="wanwu_${palace_num}_"
    local el el_prefix el_prefix_len k v field i first_el=1 first_field
    printf ',\n      "wanwu": {' >&"$fd"
    for el in star gate deity tian_gan di_gan; do
        el_prefix="${prefix}${el}_"
        el_prefix_len=${#el_prefix}
        first_field=1
        local has_fields=0
        for ((i=0; i<${#_DL_KEYS[@]}; i++)); do
            k="${_DL_KEYS[$i]}"
            if [[ "$k" == "${el_prefix}"* ]]; then
                v="${_DL_VALS[$i]}"
                [[ -n "$v" ]] || continue
                field="${k:$el_prefix_len}"
                case "$field" in
                    五行|五行阴阳|核心描述|场所环境|身体|疾病|身体疾病|事业行为|占断适宜|占断不宜|地理|概念|身体脏腑|占断含义) continue ;;
                esac
                has_fields=1
                break
            fi
        done
        if (( has_fields )); then
            if (( first_el )); then first_el=0; else printf ',' >&"$fd"; fi
            printf '\n        "%s": {' "$el" >&"$fd"
            first_field=1
            for ((i=0; i<${#_DL_KEYS[@]}; i++)); do
                k="${_DL_KEYS[$i]}"
                if [[ "$k" == "${el_prefix}"* ]]; then
                    v="${_DL_VALS[$i]}"
                    [[ -n "$v" ]] || continue
                    field="${k:$el_prefix_len}"
                    case "$field" in
                        五行|五行阴阳|核心描述|场所环境|身体|疾病|身体疾病|事业行为|占断适宜|占断不宜|地理|概念|身体脏腑|占断含义) continue ;;
                    esac
                    _hl_je_v "$v"
                    if (( first_field )); then first_field=0; else printf ',' >&"$fd"; fi
                    printf ' "%s": "%s"' "$field" "$_JE" >&"$fd"
                fi
            done
            printf ' }' >&"$fd"
        fi
    done
    printf '\n      }' >&"$fd"
}

hl_output_json() {
    local output_path="$1"
    exec 3>"$output_path" || {
        echo "Error: cannot write JSON: $output_path" >&2
        return 1
    }

    local dt sy sm sd sh
    dl_get_v "plate_datetime"; dt="$_DL_RET"
    dl_get_v "plate_si_zhu_year"; sy="$_DL_RET"
    dl_get_v "plate_si_zhu_month"; sm="$_DL_RET"
    dl_get_v "plate_si_zhu_day"; sd="$_DL_RET"
    dl_get_v "plate_si_zhu_hour"; sh="$_DL_RET"
    _hl_je_v "$dt"; local j_dt="$_JE"
    _hl_je_v "$sy"; local j_sy="$_JE"
    _hl_je_v "$sm"; local j_sm="$_JE"
    _hl_je_v "$sd"; local j_sd="$_JE"
    _hl_je_v "$sh"; local j_sh="$_JE"

    dl_get_v "muyu_${_HL_RIGAN_STEM}"; local muyu_raw="$_DL_RET"
    local muyu_dz="${muyu_raw%%,*}" muyu_p="${muyu_raw##*,}"
    [[ -n "$muyu_p" ]] || muyu_p=0
    _hl_je_v "$muyu_dz"; local j_muyu_dz="$_JE"

    local j_taohua_rigan_sanqi j_taohua_ganhe_sanqi
    if (( ${#_HL_TAOHUA_RIGAN_SANQI[@]} > 0 )); then
        j_taohua_rigan_sanqi="$(_hl_array_json "${_HL_TAOHUA_RIGAN_SANQI[@]}")"
    else
        j_taohua_rigan_sanqi="[]"
    fi
    if (( ${#_HL_TAOHUA_GANHE_SANQI[@]} > 0 )); then
        j_taohua_ganhe_sanqi="$(_hl_array_json "${_HL_TAOHUA_GANHE_SANQI[@]}")"
    else
        j_taohua_ganhe_sanqi="[]"
    fi

    local _json_taohua_found="false"
    if (( ${#_HL_TAOHUA_RIGAN_SANQI[@]} > 0 )); then _json_taohua_found="true"; fi
    if (( ${#_HL_TAOHUA_GANHE_SANQI[@]} > 0 )); then _json_taohua_found="true"; fi
    [[ "$_HL_TAOHUA_XUANWU_RIGAN" == "true" ]] && _json_taohua_found="true"
    [[ "$_HL_TAOHUA_XUANWU_GANHE" == "true" ]] && _json_taohua_found="true"
    [[ "$_HL_TAOHUA_TAIYIN_RIGAN" == "true" ]] && _json_taohua_found="true"
    [[ "$_HL_TAOHUA_TAIYIN_GANHE" == "true" ]] && _json_taohua_found="true"
    [[ "$_HL_TAOHUA_RIGAN_AT_MUYU" == "true" ]] && _json_taohua_found="true"
    [[ "$_HL_TAOHUA_GANHE_AT_MUYU" == "true" ]] && _json_taohua_found="true"
    [[ "$_HL_TAOHUA_RENGUIWITH_RIGAN" == "true" ]] && _json_taohua_found="true"
    [[ "$_HL_TAOHUA_RENGUIWITH_GANHE" == "true" ]] && _json_taohua_found="true"

    local j_rumu_palaces="[]" j_target_palaces="[]" j_zhan_sources="[]"
    local _arr="[" _first=1 _p="" _target_csv=""
    if [[ -n "$_HL_RUMU_PALACES" ]]; then
        local IFS=','
        for _p in $_HL_RUMU_PALACES; do
            [[ -n "$_p" ]] || continue
            if (( _first )); then _first=0; else _arr+=", "; fi
            _arr+="$_p"
        done
    fi
    _arr+="]"
    j_rumu_palaces="$_arr"

    if (( ${_HL_KW_PALACE_1:-0} > 0 )); then
        _target_csv="${_target_csv:+${_target_csv},}${_HL_KW_PALACE_1}"
    fi
    if (( ${_HL_KW_PALACE_2:-0} > 0 )); then
        case ",${_target_csv}," in
            *,"${_HL_KW_PALACE_2}",*) ;;
            *) _target_csv="${_target_csv:+${_target_csv},}${_HL_KW_PALACE_2}" ;;
        esac
    fi
    if [[ -n "$_HL_RUMU_PALACES" ]]; then
        local IFS=','
        for _p in $_HL_RUMU_PALACES; do
            [[ -n "$_p" ]] || continue
            case ",${_target_csv}," in
                *,"${_p}",*) ;;
                *) _target_csv="${_target_csv:+${_target_csv},}${_p}" ;;
            esac
        done
    fi
    _arr="["; _first=1
    if [[ -n "$_target_csv" ]]; then
        local IFS=','
        for _p in $_target_csv; do
            [[ -n "$_p" ]] || continue
            if (( _first )); then _first=0; else _arr+=", "; fi
            _arr+="$_p"
        done
    fi
    _arr+="]"
    j_target_palaces="$_arr"

    if [[ -n "$_HL_ZHAN_SOURCES" ]]; then
        local _srcs=() _src
        local IFS=','
        for _src in $_HL_ZHAN_SOURCES; do
            [[ -n "$_src" ]] || continue
            _srcs+=("$_src")
        done
        if (( ${#_srcs[@]} > 0 )); then
            j_zhan_sources="$(_hl_array_json "${_srcs[@]}")"
        fi
    fi

    local j_gen8_liuhai_arr j_kun2_liuhai_arr
    j_gen8_liuhai_arr="$(_hl_liuhai_json_array "$_HL_GEN8_LIUHAI")"
    j_kun2_liuhai_arr="$(_hl_liuhai_json_array "$_HL_KUN2_LIUHAI")"

    _hl_je_v "$_HL_RIGAN_STEM"; local j_rigan_stem="$_JE"
    _hl_je_v "$_HL_GANHE_STEM"; local j_ganhe_stem="$_JE"
    _hl_je_v "$_HL_FUYIN_PALACES"; local j_fuyin_palaces="$_JE"
    _hl_je_v "$_HL_FANYIN_PALACES"; local j_fanyin_palaces="$_JE"
    _hl_je_v "$_HL_GEN8_LIUHAI"; local j_gen8_lh="$_JE"
    _hl_je_v "$_HL_KUN2_LIUHAI"; local j_kun2_lh="$_JE"
    _hl_je_v "$_HL_GC_GROUP"; local j_gc_group="$_JE"
    _hl_je_v "$_HL_GC_GUCHEN"; local j_gc_guchen="$_JE"
    _hl_je_v "$_HL_GC_GUASU"; local j_gc_guasu="$_JE"
    _hl_je_v "$_HL_GC_JH_DZ1"; local j_gc_dz1="$_JE"
    _hl_je_v "$_HL_GC_JH_DZ2"; local j_gc_dz2="$_JE"
    _hl_je_v "$_HL_GC_JH_SX1"; local j_gc_sx1="$_JE"
    _hl_je_v "$_HL_GC_JH_SX2"; local j_gc_sx2="$_JE"

    printf '{\n' >&3
    printf '  "datetime": "%s",\n' "$j_dt" >&3
    printf '  "si_zhu": { "year": "%s", "month": "%s", "day": "%s", "hour": "%s" },\n' "$j_sy" "$j_sm" "$j_sd" "$j_sh" >&3

    printf '  "ri_gan": {\n' >&3
    printf '    "stem": "%s",\n' "$j_rigan_stem" >&3
    _hl_output_loc_json "$_HL_RIGAN_PALACE" 3 "    "
    _hl_emit_palace_wanwu_json 3 "$_HL_RIGAN_PALACE"
    printf '  },\n' >&3

    printf '  "gan_he": {\n' >&3
    printf '    "stem": "%s",\n' "$j_ganhe_stem" >&3
    _hl_output_loc_json "$_HL_GANHE_PALACE" 3 "    "
    _hl_emit_palace_wanwu_json 3 "$_HL_GANHE_PALACE"
    printf '  },\n' >&3

    printf '  "liuhe": {\n' >&3
    _hl_output_loc_json "$_HL_LIUHE_PALACE" 3 "    "
    _hl_emit_palace_wanwu_json 3 "$_HL_LIUHE_PALACE"
    printf '  },\n' >&3

    printf '  "muyu": {\n' >&3
    printf '    "dizhi": "%s",\n' "$j_muyu_dz" >&3
    _hl_output_loc_json "$muyu_p" 3 "    "
    printf '  },\n' >&3

    printf '  "sanqi": {\n' >&3
    printf '    "乙": {\n' >&3
    _hl_output_loc_json "$_HL_SANQI_YI_PALACE" 3 "      " ","
    printf '      "with_ri_gan": %s,\n' "$([[ $_HL_SANQI_YI_PALACE -gt 0 && $_HL_SANQI_YI_PALACE -eq $_HL_RIGAN_PALACE ]] && echo true || echo false)" >&3
    printf '      "with_gan_he": %s\n' "$([[ $_HL_SANQI_YI_PALACE -gt 0 && $_HL_SANQI_YI_PALACE -eq $_HL_GANHE_PALACE ]] && echo true || echo false)" >&3
    printf '    },\n' >&3
    printf '    "丙": {\n' >&3
    _hl_output_loc_json "$_HL_SANQI_BING_PALACE" 3 "      " ","
    printf '      "with_ri_gan": %s,\n' "$([[ $_HL_SANQI_BING_PALACE -gt 0 && $_HL_SANQI_BING_PALACE -eq $_HL_RIGAN_PALACE ]] && echo true || echo false)" >&3
    printf '      "with_gan_he": %s\n' "$([[ $_HL_SANQI_BING_PALACE -gt 0 && $_HL_SANQI_BING_PALACE -eq $_HL_GANHE_PALACE ]] && echo true || echo false)" >&3
    printf '    },\n' >&3
    printf '    "丁": {\n' >&3
    _hl_output_loc_json "$_HL_SANQI_DING_PALACE" 3 "      " ","
    printf '      "with_ri_gan": %s,\n' "$([[ $_HL_SANQI_DING_PALACE -gt 0 && $_HL_SANQI_DING_PALACE -eq $_HL_RIGAN_PALACE ]] && echo true || echo false)" >&3
    printf '      "with_gan_he": %s\n' "$([[ $_HL_SANQI_DING_PALACE -gt 0 && $_HL_SANQI_DING_PALACE -eq $_HL_GANHE_PALACE ]] && echo true || echo false)" >&3
    printf '    }\n' >&3
    printf '  },\n' >&3

    printf '  "taohua": {\n' >&3
    printf '    "ri_gan_sanqi": %s,\n' "$j_taohua_rigan_sanqi" >&3
    printf '    "gan_he_sanqi": %s,\n' "$j_taohua_ganhe_sanqi" >&3
    printf '    "xuanwu_with_ri_gan": %s,\n' "$_HL_TAOHUA_XUANWU_RIGAN" >&3
    printf '    "xuanwu_with_gan_he": %s,\n' "$_HL_TAOHUA_XUANWU_GANHE" >&3
    printf '    "taiyin_with_ri_gan": %s,\n' "$_HL_TAOHUA_TAIYIN_RIGAN" >&3
    printf '    "taiyin_with_gan_he": %s,\n' "$_HL_TAOHUA_TAIYIN_GANHE" >&3
    printf '    "ri_gan_at_muyu": %s,\n' "$_HL_TAOHUA_RIGAN_AT_MUYU" >&3
    printf '    "gan_he_at_muyu": %s,\n' "$_HL_TAOHUA_GANHE_AT_MUYU" >&3
    printf '    "rengui_with_ri_gan": %s,\n' "$_HL_TAOHUA_RENGUIWITH_RIGAN" >&3
    printf '    "rengui_with_gan_he": %s\n' "$_HL_TAOHUA_RENGUIWITH_GANHE" >&3
    printf '  },\n' >&3

    _hl_je_v "$_HL_PIANCAI_STEM"; local j_piancai_stem="$_JE"
    _hl_je_v "$_HL_PIANCAI_SANQI_STEM"; local j_piancai_sanqi_stem="$_JE"
    printf '  "zhan_taohua": {\n' >&3
    printf '    "has_taohua": %s,\n' "$_json_taohua_found" >&3
    printf '    "rumu_palaces": %s,\n' "$j_rumu_palaces" >&3
    printf '    "target_palaces": %s,\n' "$j_target_palaces" >&3
    printf '    "sources": %s,\n' "$j_zhan_sources" >&3
    printf '    "piancai_stem": "%s",\n' "$j_piancai_stem" >&3
    printf '    "piancai_sanqi": %s,\n' "$_HL_PIANCAI_SANQI" >&3
    printf '    "piancai_sanqi_stem": "%s",\n' "$j_piancai_sanqi_stem" >&3
    printf '    "protect_ganhe": %s,\n' "$_HL_PROTECT_GANHE" >&3
    printf '    "protect_liuhe": %s\n' "$_HL_PROTECT_LIUHE" >&3
    printf '  },\n' >&3

    printf '  "fuyin_fanyin": {\n' >&3
    printf '    "fuyin_palaces": "%s",\n' "$j_fuyin_palaces" >&3
    printf '    "fanyin_palaces": "%s",\n' "$j_fanyin_palaces" >&3
    printf '    "is_fuyin_ju": %s,\n' "$_HL_IS_FUYIN_JU" >&3
    printf '    "is_fanyin_ju": %s\n' "$_HL_IS_FANYIN_JU" >&3
    printf '  },\n' >&3

    local _kw_json_dz1="" _kw_json_dz2=""
    dl_get_v "plate_kong_wang_0_branch" 2>/dev/null || true; _kw_json_dz1="$_DL_RET"
    dl_get_v "plate_kong_wang_1_branch" 2>/dev/null || true; _kw_json_dz2="$_DL_RET"
    _hl_je_v "$_kw_json_dz1"; local j_kw_dz1="$_JE"
    _hl_je_v "$_kw_json_dz2"; local j_kw_dz2="$_JE"

    printf '  "kongwang": {\n' >&3
    printf '    "palace_1": %s,\n' "${_HL_KW_PALACE_1:-0}" >&3
    printf '    "palace_2": %s,\n' "${_HL_KW_PALACE_2:-0}" >&3
    printf '    "branch_1": "%s",\n' "$j_kw_dz1" >&3
    printf '    "branch_2": "%s",\n' "$j_kw_dz2" >&3
    printf '    "ri_gan_kw": %s,\n' "$_HL_RIGAN_KW" >&3
    printf '    "gan_he_kw": %s,\n' "$_HL_GANHE_KW" >&3
    printf '    "liuhe_kw": %s\n' "$_HL_LIUHE_KW" >&3
    printf '  },\n' >&3

    printf '  "gen_kun": {\n' >&3
    printf '    "gen8": {\n' >&3
    printf '      "liuhai": "%s",\n' "$j_gen8_lh" >&3
    printf '      "liuhai_array": %s,\n' "$j_gen8_liuhai_arr" >&3
    printf '      "liuhai_count": %s,\n' "$_HL_GEN8_LIUHAI_COUNT" >&3
    printf '      "has_geng": %s,\n' "$_HL_GEN8_HAS_GENG" >&3
    printf '      "has_baihu": %s\n' "$_HL_GEN8_HAS_BAIHU" >&3
    printf '    },\n' >&3
    printf '    "kun2": {\n' >&3
    printf '      "liuhai": "%s",\n' "$j_kun2_lh" >&3
    printf '      "liuhai_array": %s,\n' "$j_kun2_liuhai_arr" >&3
    printf '      "liuhai_count": %s,\n' "$_HL_KUN2_LIUHAI_COUNT" >&3
    printf '      "has_geng": %s,\n' "$_HL_KUN2_HAS_GENG" >&3
    printf '      "has_baihu": %s\n' "$_HL_KUN2_HAS_BAIHU" >&3
    printf '    }\n' >&3
    printf '  },\n' >&3

    local _gc_json_p1="" _gc_json_p2="" _gc_json_jp1="" _gc_json_jp2=""
    dl_get_v "dizhi_palace_${_HL_GC_GUCHEN}" 2>/dev/null || true; _gc_json_p1="$_DL_RET"
    dl_get_v "dizhi_palace_${_HL_GC_GUASU}" 2>/dev/null || true; _gc_json_p2="$_DL_RET"
    dl_get_v "dizhi_palace_${_HL_GC_JH_DZ1}" 2>/dev/null || true; _gc_json_jp1="$_DL_RET"
    dl_get_v "dizhi_palace_${_HL_GC_JH_DZ2}" 2>/dev/null || true; _gc_json_jp2="$_DL_RET"

    printf '  "guchen_guasu": {\n' >&3
    printf '    "group": "%s",\n' "$j_gc_group" >&3
    printf '    "guchen": "%s",\n' "$j_gc_guchen" >&3
    printf '    "guchen_palace": %s,\n' "${_gc_json_p1:-0}" >&3
    printf '    "guasu": "%s",\n' "$j_gc_guasu" >&3
    printf '    "guasu_palace": %s,\n' "${_gc_json_p2:-0}" >&3
    printf '    "jiehua": {\n' >&3
    printf '      "dizhi_1": "%s",\n' "$j_gc_dz1" >&3
    printf '      "palace_1": %s,\n' "${_gc_json_jp1:-0}" >&3
    printf '      "shengxiao_1": "%s",\n' "$j_gc_sx1" >&3
    printf '      "dizhi_2": "%s",\n' "$j_gc_dz2" >&3
    printf '      "palace_2": %s,\n' "${_gc_json_jp2:-0}" >&3
    printf '      "shengxiao_2": "%s"\n' "$j_gc_sx2" >&3
    printf '    }\n' >&3
    printf '  },\n' >&3

    printf '  "special_positions": {\n' >&3
    printf '    "tianpeng": {\n' >&3
    _hl_output_loc_json "$_HL_TIANPENG_PALACE" 3 "      "
    printf '    },\n' >&3
    printf '    "shangmen": {\n' >&3
    _hl_output_loc_json "$_HL_SHANGMEN_PALACE" 3 "      "
    printf '    },\n' >&3
    printf '    "ding": {\n' >&3
    _hl_output_loc_json "$_HL_DING_PALACE" 3 "      "
    printf '    },\n' >&3
    printf '    "gui": {\n' >&3
    _hl_output_loc_json "$_HL_GUI_PALACE" 3 "      "
    printf '    }\n' >&3
    printf '  }\n' >&3
    printf '}\n' >&3

    exec 3>&-
}

hl_run_analysis() {
    local input_path="$1" birth_path="$2" output_path="$3"

    qa_parse_plate_json "$input_path"

    _hl_extract_birth_header "$birth_path"

    local ri_gan nian_zhi
    ri_gan="$(_hl_extract_birth_ri_gan "$birth_path")"
    nian_zhi="$(_hl_extract_birth_nian_zhi "$birth_path")"

    if [[ -z "$ri_gan" ]]; then
        echo "Error: could not extract birth day stem from $birth_path" >&2
        return 1
    fi
    if [[ -z "$nian_zhi" ]]; then
        echo "Error: could not extract birth year branch from $birth_path" >&2
        return 1
    fi

    hl_find_ri_gan "$ri_gan"
    hl_find_gan_he "$ri_gan"
    hl_find_liuhe
    hl_find_sanqi
    hl_find_tianpeng
    hl_find_shangmen
    hl_find_ding_gui

    hl_detect_taohua
    hl_compute_zhan_taohua
    hl_detect_fuyin_fanyin
    hl_check_kongwang
    hl_check_gen_kun
    hl_compute_guchen_guasu "$nian_zhi"

    # Lookup wanwu for key palaces
    (( _HL_RIGAN_PALACE > 0 )) && qa_lookup_wanwu "$_HL_RIGAN_PALACE"
    (( _HL_GANHE_PALACE > 0 )) && qa_lookup_wanwu "$_HL_GANHE_PALACE"
    (( _HL_LIUHE_PALACE > 0 )) && qa_lookup_wanwu "$_HL_LIUHE_PALACE"

    hl_output_text

    local output_dir output_base tmp_path
    output_dir="$(dirname "$output_path")"
    output_base="$(basename "$output_path")"
    tmp_path="${output_dir}/tmp.$$.${output_base}"
    trap 'rm -f "$tmp_path"' EXIT
    hl_output_json "$tmp_path"
    mv -f "$tmp_path" "$output_path"
    trap - EXIT
}
