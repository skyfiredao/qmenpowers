#!/usr/bin/env bash
# Copyright (C) 2025 — Licensed under GPL-3.0
# See https://www.gnu.org/licenses/gpl-3.0.html
# qimen_zhanduan.sh — DSL evaluator for zhanduan (divination judgment) system.
# Sourced AFTER data_loader.sh and qimen_json.sh.
# All functions use _zd_ prefix.

# --- Global state ---
_ZD_PALACE=""
_ZD_ROLE_NAMES=()
_ZD_ROLE_DEFS=()
_ZD_JUDGE_CONDS=()
_ZD_JUDGE_RESULTS=()
_ZD_TOPIC_LABEL=""
_ZD_TOPIC_SOURCE=""
_ZD_RP_NAMES=()
_ZD_RP_VALS=()
_ZD_RP_WUXING=()
_ZD_MATCHED_CONDS=()
_ZD_MATCHED_RESULTS=()
_ZD_RP=""
_ZD_RP_WX=""

# --- 1. Stem to Wuxing ---
_zd_stem_wuxing() {
    local stem="$1"
    case "$stem" in
        甲|乙) echo "木" ;;
        丙|丁) echo "火" ;;
        戊|己) echo "土" ;;
        庚|辛) echo "金" ;;
        壬|癸) echo "水" ;;
        *) echo "" ;;
    esac
}

# --- 2. Palace Wuxing ---
_zd_palace_wuxing() {
    local pnum="$1"
    dl_get "palace_${pnum}_wuxing"
}

# --- 3. Wuxing relation ---
_zd_wuxing_relation() {
    local a="$1" b="$2"
    if [[ "$a" == "$b" ]]; then
        echo "bihe"
        return
    fi
    # sheng: a generates b
    local sheng=0
    case "${a}${b}" in
        木火|火土|土金|金水|水木) sheng=1 ;;
    esac
    if (( sheng == 1 )); then
        echo "sheng"
        return
    fi
    # bei_sheng: b generates a
    local bei_sheng=0
    case "${b}${a}" in
        木火|火土|土金|金水|水木) bei_sheng=1 ;;
    esac
    if (( bei_sheng == 1 )); then
        echo "bei_sheng"
        return
    fi
    # ke: a overcomes b
    local ke=0
    case "${a}${b}" in
        木土|土水|水火|火金|金木) ke=1 ;;
    esac
    if (( ke == 1 )); then
        echo "ke"
        return
    fi
    # bei_ke: b overcomes a
    echo "bei_ke"
}

# --- 4. Locate role ---
_zd_locate_role() {
    local role_def="$1"
    local rtype rval p tmp_v stem
    _ZD_PALACE=""

    rtype="${role_def%%:*}"
    rval="${role_def#*:}"

    case "$rtype" in
        stem)
            for p in 1 2 3 4 5 6 7 8 9; do
                dl_get_v "palace_${p}_di_gan" 2>/dev/null || true
                if [[ "$_DL_RET" == "$rval" ]]; then
                    _ZD_PALACE="$p"
                    return 0
                fi
            done
            return 1
            ;;
        star)
            for p in 1 2 3 4 5 6 7 8 9; do
                dl_get_v "palace_${p}_star" 2>/dev/null || true
                if [[ "$_DL_RET" == "$rval" ]]; then
                    _ZD_PALACE="$p"
                    return 0
                fi
            done
            return 1
            ;;
        gate)
            for p in 1 2 3 4 5 6 7 8 9; do
                dl_get_v "palace_${p}_gate" 2>/dev/null || true
                if [[ "$_DL_RET" == "$rval" ]]; then
                    _ZD_PALACE="$p"
                    return 0
                fi
            done
            return 1
            ;;
        deity)
            for p in 1 2 3 4 5 6 7 8 9; do
                dl_get_v "palace_${p}_deity" 2>/dev/null || true
                if [[ "$_DL_RET" == "$rval" ]]; then
                    _ZD_PALACE="$p"
                    return 0
                fi
            done
            return 1
            ;;
        ref)
            case "$rval" in
                日干)
                    dl_get_v "ri_gan_palace" 2>/dev/null || true
                    _ZD_PALACE="$_DL_RET"
                    [[ -n "$_ZD_PALACE" ]] && return 0
                    return 1
                    ;;
                时干)
                    dl_get_v "shi_gan_palace" 2>/dev/null || true
                    _ZD_PALACE="$_DL_RET"
                    [[ -n "$_ZD_PALACE" ]] && return 0
                    return 1
                    ;;
                值符)
                    dl_get_v "plate_zhi_fu_palace" 2>/dev/null || true
                    _ZD_PALACE="$_DL_RET"
                    [[ -n "$_ZD_PALACE" ]] && return 0
                    return 1
                    ;;
                值使)
                    dl_get_v "plate_zhi_shi_palace" 2>/dev/null || true
                    _ZD_PALACE="$_DL_RET"
                    [[ -n "$_ZD_PALACE" ]] && return 0
                    return 1
                    ;;
                岁干|年干)
                    dl_get_v "plate_si_zhu_year" 2>/dev/null || true
                    tmp_v="$_DL_RET"
                    stem="$(_qj_extract_stem "$tmp_v")"
                    [[ -n "$stem" ]] || return 1
                    for p in 1 2 3 4 5 6 7 8 9; do
                        dl_get_v "palace_${p}_di_gan" 2>/dev/null || true
                        if [[ "$_DL_RET" == "$stem" ]]; then
                            _ZD_PALACE="$p"
                            return 0
                        fi
                    done
                    return 1
                    ;;
                月干)
                    dl_get_v "plate_si_zhu_month" 2>/dev/null || true
                    tmp_v="$_DL_RET"
                    stem="$(_qj_extract_stem "$tmp_v")"
                    [[ -n "$stem" ]] || return 1
                    for p in 1 2 3 4 5 6 7 8 9; do
                        dl_get_v "palace_${p}_di_gan" 2>/dev/null || true
                        if [[ "$_DL_RET" == "$stem" ]]; then
                            _ZD_PALACE="$p"
                            return 0
                        fi
                    done
                    return 1
                    ;;
                *)
                    return 1
                    ;;
            esac
            ;;
        palace)
            _ZD_PALACE="$rval"
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# --- 5. Load topic ---
_zd_load_topic() {
    local topic_key="$1"
    local i k v part

    _ZD_ROLE_NAMES=()
    _ZD_ROLE_DEFS=()
    _ZD_JUDGE_CONDS=()
    _ZD_JUDGE_RESULTS=()
    _ZD_TOPIC_LABEL=""
    _ZD_TOPIC_SOURCE=""

    # Label and source
    dl_get_v "${topic_key}_label" 2>/dev/null || true
    _ZD_TOPIC_LABEL="$_DL_RET"
    dl_get_v "${topic_key}_source" 2>/dev/null || true
    _ZD_TOPIC_SOURCE="$_DL_RET"

    # Scan _DL_KEYS for roles and judges
    local prefix_role="${topic_key}_role_"
    local prefix_judge="${topic_key}_judge_"
    local prl=${#prefix_role}
    local pjl=${#prefix_judge}

    for ((i=0; i<${#_DL_KEYS[@]}; i++)); do
        k="${_DL_KEYS[$i]}"
        v="${_DL_VALS[$i]}"

        # Check role prefix
        if [[ "${k}" == "${prefix_role}"* ]]; then
            part="${k:$prl}"
            _ZD_ROLE_NAMES+=("$part")
            _ZD_ROLE_DEFS+=("$v")
            continue
        fi

        if [[ "${k}" == "${prefix_judge}"* ]]; then
            local cond="${v%%=>*}"
            local concl="${v#*=>}"
            _ZD_JUDGE_CONDS+=("$cond")
            _ZD_JUDGE_RESULTS+=("$concl")
            continue
        fi
    done

    return 0
}

# --- Helper: get role palace from parallel arrays ---
_zd_get_role_palace() {
    local name="$1" i
    _ZD_RP=""
    for ((i=0; i<${#_ZD_RP_NAMES[@]}; i++)); do
        if [[ "${_ZD_RP_NAMES[$i]}" == "$name" ]]; then
            _ZD_RP="${_ZD_RP_VALS[$i]}"
            return 0
        fi
    done
    return 1
}

# --- Helper: get role wuxing from parallel arrays ---
_zd_get_role_wuxing() {
    local name="$1" i
    _ZD_RP_WX=""
    for ((i=0; i<${#_ZD_RP_NAMES[@]}; i++)); do
        if [[ "${_ZD_RP_NAMES[$i]}" == "$name" ]]; then
            _ZD_RP_WX="${_ZD_RP_WUXING[$i]}"
            return 0
        fi
    done
    return 1
}

# --- Helper: compute role wuxing from role_def and palace ---
_zd_compute_role_wuxing() {
    local role_def="$1" palace="$2"
    local rtype rval
    rtype="${role_def%%:*}"
    rval="${role_def#*:}"
    case "$rtype" in
        stem)
            _zd_stem_wuxing "$rval"
            ;;
        star)
            dl_get_v "palace_${palace}_star_wuxing" 2>/dev/null || true
            echo "$_DL_RET"
            ;;
        gate)
            dl_get_v "palace_${palace}_gate_wuxing" 2>/dev/null || true
            echo "$_DL_RET"
            ;;
        deity)
            # Fallback: use palace wuxing for deities
            dl_get_v "palace_${palace}_wuxing" 2>/dev/null || true
            echo "$_DL_RET"
            ;;
        ref)
            case "$rval" in
                日干|时干|岁干|年干|月干)
                    # These are stems located via di_gan
                    dl_get_v "palace_${palace}_di_gan_wuxing" 2>/dev/null || true
                    echo "$_DL_RET"
                    ;;
                值符)
                    # 值符 = duty star, use star's wuxing
                    dl_get_v "palace_${palace}_star_wuxing" 2>/dev/null || true
                    echo "$_DL_RET"
                    ;;
                值使)
                    # 值使 = duty gate, use gate's wuxing
                    dl_get_v "palace_${palace}_gate_wuxing" 2>/dev/null || true
                    echo "$_DL_RET"
                    ;;
                *)
                    dl_get_v "palace_${palace}_wuxing" 2>/dev/null || true
                    echo "$_DL_RET"
                    ;;
            esac
            ;;
        *)
            dl_get_v "palace_${palace}_wuxing" 2>/dev/null || true
            echo "$_DL_RET"
            ;;
    esac
}

# --- Helper: tomb palace for given wuxing ---
_zd_tomb_palace() {
    local wx="$1"
    case "$wx" in
        木) echo "2" ;;   # 未
        火) echo "6" ;;   # 戌
        土) echo "6" ;;   # 戌
        金) echo "8" ;;   # 丑
        水) echo "4" ;;   # 辰
        *) echo "" ;;
    esac
}

# --- 6. Eval atom ---
_zd_eval_atom() {
    local atom="$1"
    local role_a role_b op palace_a palace_b wx_a wx_b rel
    local state tg gate val p

    # State atoms: A?STATE
    if [[ "$atom" == *"?"* ]]; then
        role_a="${atom%%\?*}"
        local stest="${atom#*\?}"
        _zd_get_role_palace "$role_a" || return 1
        palace_a="$_ZD_RP"

        case "$stest" in
            旺)
                _zd_get_role_wuxing "$role_a" || return 1
                local role_wx="$_ZD_RP_WX"
                local pal_wx
                pal_wx="$(_zd_palace_wuxing "$palace_a")"
                local rel
                rel="$(_zd_wuxing_relation "$role_wx" "$pal_wx")"
                case "$rel" in
                    bihe|bei_sheng) return 0 ;;
                    *) return 1 ;;
                esac
                ;;
            囚)
                _zd_get_role_wuxing "$role_a" || return 1
                local role_wx2="$_ZD_RP_WX"
                local pal_wx2
                pal_wx2="$(_zd_palace_wuxing "$palace_a")"
                local rel2
                rel2="$(_zd_wuxing_relation "$role_wx2" "$pal_wx2")"
                case "$rel2" in
                    bei_ke) return 0 ;;
                    *) return 1 ;;
                esac
                ;;
            奇)
                dl_get_v "palace_${palace_a}_tian_gan" 2>/dev/null || true
                tg="$_DL_RET"
                case "$tg" in
                    乙|丙|丁) return 0 ;;
                    *) return 1 ;;
                esac
                ;;
            吉门)
                dl_get_v "palace_${palace_a}_gate" 2>/dev/null || true
                gate="$_DL_RET"
                case "$gate" in
                    开门|休门|生门) return 0 ;;
                    *) return 1 ;;
                esac
                ;;
            凶门)
                dl_get_v "palace_${palace_a}_gate" 2>/dev/null || true
                gate="$_DL_RET"
                case "$gate" in
                    死门|惊门|伤门) return 0 ;;
                    *) return 1 ;;
                esac
                ;;
            吉格)
                dl_get_v "palace_${palace_a}_ji_xing" 2>/dev/null || true
                [[ "$_DL_RET" == "true" ]] && return 1
                dl_get_v "palace_${palace_a}_geng" 2>/dev/null || true
                [[ "$_DL_RET" == "true" ]] && return 1
                dl_get_v "palace_${palace_a}_rumu_gan" 2>/dev/null || true
                [[ "$_DL_RET" == "true" ]] && return 1
                dl_get_v "palace_${palace_a}_men_po" 2>/dev/null || true
                [[ "$_DL_RET" == "true" ]] && return 1
                return 0
                ;;
            凶格)
                dl_get_v "palace_${palace_a}_ji_xing" 2>/dev/null || true
                [[ "$_DL_RET" == "true" ]] && return 0
                dl_get_v "palace_${palace_a}_geng" 2>/dev/null || true
                [[ "$_DL_RET" == "true" ]] && return 0
                dl_get_v "palace_${palace_a}_rumu_gan" 2>/dev/null || true
                [[ "$_DL_RET" == "true" ]] && return 0
                dl_get_v "palace_${palace_a}_men_po" 2>/dev/null || true
                [[ "$_DL_RET" == "true" ]] && return 0
                return 1
                ;;
            空)
                dl_get_v "palace_${palace_a}_kong_wang" 2>/dev/null || true
                [[ "$_DL_RET" == "true" ]] && return 0
                return 1
                ;;
            墓)
                _zd_get_role_wuxing "$role_a" || return 1
                local role_wx3="$_ZD_RP_WX"
                local tomb_p
                tomb_p="$(_zd_tomb_palace "$role_wx3")"
                [[ -n "$tomb_p" && "$tomb_p" == "$palace_a" ]] && return 0
                return 1
                ;;
            返)
                dl_get_v "palace_${palace_a}_star_fan_yin" 2>/dev/null || true
                [[ "$_DL_RET" == "true" ]] && return 0
                dl_get_v "palace_${palace_a}_gate_fan_yin" 2>/dev/null || true
                [[ "$_DL_RET" == "true" ]] && return 0
                return 1
                ;;
            伏)
                dl_get_v "palace_${palace_a}_star_fu_yin" 2>/dev/null || true
                [[ "$_DL_RET" == "true" ]] && return 0
                dl_get_v "palace_${palace_a}_gate_fu_yin" 2>/dev/null || true
                [[ "$_DL_RET" == "true" ]] && return 0
                return 1
                ;;
            内)
                dl_get_v "plate_ju_type" 2>/dev/null || true
                local jtype="$_DL_RET"
                if [[ "$jtype" == "阳遁" ]]; then
                    case "$palace_a" in
                        1|8|3|4) return 0 ;;
                        *) return 1 ;;
                    esac
                else
                    case "$palace_a" in
                        9|2|7|6) return 0 ;;
                        *) return 1 ;;
                    esac
                fi
                ;;
            外)
                dl_get_v "plate_ju_type" 2>/dev/null || true
                local jtype2="$_DL_RET"
                if [[ "$jtype2" == "阳遁" ]]; then
                    case "$palace_a" in
                        9|2|7|6) return 0 ;;
                        *) return 1 ;;
                    esac
                else
                    case "$palace_a" in
                        1|8|3|4) return 0 ;;
                        *) return 1 ;;
                    esac
                fi
                ;;
            *)
                return 1
                ;;
        esac
    fi

    # Relationship atoms: find operator
    local found_op="" pos=0 ch=""
    local alen=${#atom}
    # We need to find single-char operators between role names
    # Operators: > < ! ^ = @
    # Strategy: try each operator
    for op in ">" "<" "!" "^" "=" "@"; do
        if [[ "$atom" == *"${op}"* ]]; then
            role_a="${atom%%${op}*}"
            role_b="${atom#*${op}}"
            # Validate both roles exist
            _zd_get_role_palace "$role_a" || continue
            palace_a="$_ZD_RP"
            _zd_get_role_palace "$role_b" || continue
            palace_b="$_ZD_RP"
            found_op="$op"
            break
        fi
    done

    [[ -n "$found_op" ]] || return 1

    case "$found_op" in
        "@")
            [[ "$palace_a" == "$palace_b" ]] && return 0
            return 1
            ;;
        ">"|"<"|"!"|"^"|"=")
            wx_a="$(_zd_palace_wuxing "$palace_a")"
            wx_b="$(_zd_palace_wuxing "$palace_b")"
            rel="$(_zd_wuxing_relation "$wx_a" "$wx_b")"
            case "$found_op" in
                ">") [[ "$rel" == "sheng" ]] && return 0; return 1 ;;
                "<") [[ "$rel" == "bei_sheng" ]] && return 0; return 1 ;;
                "!") [[ "$rel" == "ke" ]] && return 0; return 1 ;;
                "^") [[ "$rel" == "bei_ke" ]] && return 0; return 1 ;;
                "=") [[ "$rel" == "bihe" ]] && return 0; return 1 ;;
            esac
            ;;
    esac
    return 1
}

# --- 7. Check Geng Ge ---
_zd_check_geng_ge() {
    local type="$1"
    local geng_palace="" p target_stem="" target_palace="" gz=""

    # Find palace where tian_gan is 庚
    for p in 1 2 3 4 5 6 7 8 9; do
        dl_get_v "palace_${p}_tian_gan" 2>/dev/null || true
        if [[ "$_DL_RET" == "庚" ]]; then
            geng_palace="$p"
            break
        fi
    done
    [[ -n "$geng_palace" ]] || return 1

    # Find target stem based on type
    case "$type" in
        年)
            dl_get_v "plate_si_zhu_year" 2>/dev/null || true
            gz="$_DL_RET"
            target_stem="$(_qj_extract_stem "$gz")"
            ;;
        月)
            dl_get_v "plate_si_zhu_month" 2>/dev/null || true
            gz="$_DL_RET"
            target_stem="$(_qj_extract_stem "$gz")"
            ;;
        日)
            dl_get_v "ri_gan_palace" 2>/dev/null || true
            target_palace="$_DL_RET"
            # Check if geng is on that palace's tian_gan
            [[ -n "$target_palace" ]] || return 1
            dl_get_v "palace_${target_palace}_tian_gan" 2>/dev/null || true
            [[ "$_DL_RET" == "庚" ]] && return 0
            return 1
            ;;
        时)
            dl_get_v "shi_gan_palace" 2>/dev/null || true
            target_palace="$_DL_RET"
            [[ -n "$target_palace" ]] || return 1
            dl_get_v "palace_${target_palace}_tian_gan" 2>/dev/null || true
            [[ "$_DL_RET" == "庚" ]] && return 0
            return 1
            ;;
        *)
            return 1
            ;;
    esac

    # For year/month: find target stem on di_gan, check if that palace has 庚 on tian_gan
    [[ -n "$target_stem" ]] || return 1
    for p in 1 2 3 4 5 6 7 8 9; do
        dl_get_v "palace_${p}_di_gan" 2>/dev/null || true
        if [[ "$_DL_RET" == "$target_stem" ]]; then
            target_palace="$p"
            break
        fi
    done
    [[ -n "$target_palace" ]] || return 1
    dl_get_v "palace_${target_palace}_tian_gan" 2>/dev/null || true
    [[ "$_DL_RET" == "庚" ]] && return 0
    return 1
}

# --- 8. Eval condition ---
_zd_eval_condition() {
    local full_expr="$1"
    local parts part result negated a_result

    # Handle 庚格 special
    if [[ "$full_expr" == "!庚格" ]]; then
        # True if NO geng-ge matches any pillar
        _zd_check_geng_ge "年" && return 1
        _zd_check_geng_ge "月" && return 1
        _zd_check_geng_ge "日" && return 1
        _zd_check_geng_ge "时" && return 1
        return 0
    fi

    if [[ "$full_expr" == 庚格:* ]]; then
        local gtype="${full_expr#庚格:}"
        _zd_check_geng_ge "$gtype"
        return $?
    fi

    # OR logic (split by |)
    if [[ "$full_expr" == *"|"* ]]; then
        local IFS_OLD="$IFS"
        local or_parts=()
        local tmp_expr="$full_expr"
        while [[ "$tmp_expr" == *"|"* ]]; do
            or_parts+=("${tmp_expr%%|*}")
            tmp_expr="${tmp_expr#*|}"
        done
        or_parts+=("$tmp_expr")
        IFS="$IFS_OLD"

        for part in "${or_parts[@]}"; do
            _zd_eval_single_atom "$part" && return 0
        done
        return 1
    fi

    # AND logic (split by +)
    if [[ "$full_expr" == *"+"* ]]; then
        local and_parts=()
        local tmp_expr="$full_expr"
        while [[ "$tmp_expr" == *"+"* ]]; do
            and_parts+=("${tmp_expr%%+*}")
            tmp_expr="${tmp_expr#*+}"
        done
        and_parts+=("$tmp_expr")

        for part in "${and_parts[@]}"; do
            _zd_eval_single_atom "$part" || return 1
        done
        return 0
    fi

    # Single atom
    _zd_eval_single_atom "$full_expr"
    return $?
}

# Helper for evaluating a single atom (with possible ! prefix or geng-ge)
_zd_eval_single_atom() {
    local atom="$1"

    # Geng-ge within compound expression
    if [[ "$atom" == 庚格:* ]]; then
        local gtype="${atom#庚格:}"
        _zd_check_geng_ge "$gtype"
        return $?
    fi

    # Negation
    if [[ "$atom" == "!"* ]]; then
        local inner="${atom#!}"
        if [[ "$inner" == 庚格:* ]]; then
            local gtype="${inner#庚格:}"
            _zd_check_geng_ge "$gtype" && return 1
            return 0
        fi
        if [[ "$inner" == "庚格" ]]; then
            _zd_check_geng_ge "年" && return 1
            _zd_check_geng_ge "月" && return 1
            _zd_check_geng_ge "日" && return 1
            _zd_check_geng_ge "时" && return 1
            return 0
        fi
        _zd_eval_atom "$inner" && return 1
        return 0
    fi

    _zd_eval_atom "$atom"
    return $?
}

# --- 9. Run topic ---
_zd_run_topic() {
    local topic_key="$1"
    local i

    # Load topic data
    _zd_load_topic "$topic_key"

    # Build role-palace mapping
    _ZD_RP_NAMES=()
    _ZD_RP_VALS=()
    _ZD_RP_WUXING=()
    for ((i=0; i<${#_ZD_ROLE_NAMES[@]}; i++)); do
        if _zd_locate_role "${_ZD_ROLE_DEFS[$i]}"; then
            _ZD_RP_NAMES+=("${_ZD_ROLE_NAMES[$i]}")
            _ZD_RP_VALS+=("$_ZD_PALACE")
            _ZD_RP_WUXING+=("$(_zd_compute_role_wuxing "${_ZD_ROLE_DEFS[$i]}" "$_ZD_PALACE")")
        fi
    done

    # Evaluate all judge conditions
    _ZD_MATCHED_CONDS=()
    _ZD_MATCHED_RESULTS=()
    for ((i=0; i<${#_ZD_JUDGE_CONDS[@]}; i++)); do
        if _zd_eval_condition "${_ZD_JUDGE_CONDS[$i]}"; then
            _ZD_MATCHED_CONDS+=("${_ZD_JUDGE_CONDS[$i]}")
            _ZD_MATCHED_RESULTS+=("${_ZD_JUDGE_RESULTS[$i]}")
        fi
    done

    return 0
}

# --- 10. Output text ---
_zd_output_text() {
    local i wx pnum rname rdef_val j

    dl_get_v "plate_datetime" 2>/dev/null || true; local _dt="$_DL_RET"
    dl_get_v "plate_si_zhu_year" 2>/dev/null || true; local _sz_y="$_DL_RET"
    dl_get_v "plate_si_zhu_month" 2>/dev/null || true; local _sz_m="$_DL_RET"
    dl_get_v "plate_si_zhu_day" 2>/dev/null || true; local _sz_d="$_DL_RET"
    dl_get_v "plate_si_zhu_hour" 2>/dev/null || true; local _sz_h="$_DL_RET"
    dl_get_v "plate_ju_type" 2>/dev/null || true; local _jt="$_DL_RET"
    dl_get_v "plate_ju_number" 2>/dev/null || true; local _jn="$_DL_RET"
    dl_get_v "plate_ju_yuan" 2>/dev/null || true; local _jy="$_DL_RET"

    echo "占断: ${_ZD_TOPIC_LABEL}"
    echo "出处: ${_ZD_TOPIC_SOURCE}"
    echo "时间: ${_dt}"
    echo "四柱: ${_sz_y} ${_sz_m} ${_sz_d} ${_sz_h}"
    echo "局:   ${_jt}${_jn}局 (${_jy})"
    echo "─────────────────────"
    echo "[角色定位]"
    for ((i=0; i<${#_ZD_RP_NAMES[@]}; i++)); do
        rname="${_ZD_RP_NAMES[$i]}"
        pnum="${_ZD_RP_VALS[$i]}"
        rdef_val=""
        for ((j=0; j<${#_ZD_ROLE_NAMES[@]}; j++)); do
            if [[ "${_ZD_ROLE_NAMES[$j]}" == "$rname" ]]; then
                rdef_val="${_ZD_ROLE_DEFS[$j]}"
                break
            fi
        done
        local display_name="${rdef_val#*:}"
        wx="$(_zd_palace_wuxing "$pnum")"
        local _pn_idx=$((pnum - 1))
        local pname="${PALACE_NAMES[$_pn_idx]}"
        local pdir="${PALACE_DIRECTION[$_pn_idx]}"
        echo "  ${display_name} -> ${pname} (${pdir}, ${wx})"
    done
    echo "─────────────────────"
    if (( ${#_ZD_MATCHED_RESULTS[@]} == 0 )); then
        echo "(无匹配判断)"
    else
        for ((i=0; i<${#_ZD_MATCHED_RESULTS[@]}; i++)); do
            echo "  ${_ZD_MATCHED_RESULTS[$i]}"
        done
    fi
}

# --- 11. Output JSON ---
_zd_output_json() {
    local output_path="$1"
    local i j pnum wx rname rdef_val matched

    _qj_je_v "$_ZD_TOPIC_LABEL"; local j_label="$_JE"
    _qj_je_v "$_ZD_TOPIC_SOURCE"; local j_source="$_JE"

    {
        echo "{"
        echo "  \"topic\": \"${j_label}\","
        echo "  \"source\": \"${j_source}\","
        echo "  \"roles\": {"

        for ((i=0; i<${#_ZD_RP_NAMES[@]}; i++)); do
            rname="${_ZD_RP_NAMES[$i]}"
            pnum="${_ZD_RP_VALS[$i]}"
            rdef_val=""
            for ((j=0; j<${#_ZD_ROLE_NAMES[@]}; j++)); do
                if [[ "${_ZD_ROLE_NAMES[$j]}" == "$rname" ]]; then
                    rdef_val="${_ZD_ROLE_DEFS[$j]}"
                    break
                fi
            done
            wx="$(_zd_palace_wuxing "$pnum")"
            _qj_je_v "$rname"; local j_rname="$_JE"
            _qj_je_v "$rdef_val"; local j_rdef="$_JE"
            _qj_je_v "$wx"; local j_wx="$_JE"
            local comma=","
            if (( i == ${#_ZD_RP_NAMES[@]} - 1 )); then
                comma=""
            fi
            echo "    \"${j_rname}\": { \"definition\": \"${j_rdef}\", \"palace\": ${pnum}, \"wuxing\": \"${j_wx}\" }${comma}"
        done

        echo "  },"
        echo "  \"judgments\": ["

        # Output ALL judge rules (matched and unmatched)
        for ((i=0; i<${#_ZD_JUDGE_CONDS[@]}; i++)); do
            matched="false"
            for ((j=0; j<${#_ZD_MATCHED_CONDS[@]}; j++)); do
                if [[ "${_ZD_MATCHED_CONDS[$j]}" == "${_ZD_JUDGE_CONDS[$i]}" && "${_ZD_MATCHED_RESULTS[$j]}" == "${_ZD_JUDGE_RESULTS[$i]}" ]]; then
                    matched="true"
                    break
                fi
            done
            _qj_je_v "${_ZD_JUDGE_CONDS[$i]}"; local j_cond="$_JE"
            _qj_je_v "${_ZD_JUDGE_RESULTS[$i]}"; local j_res="$_JE"
            local comma=","
            if (( i == ${#_ZD_JUDGE_CONDS[@]} - 1 )); then
                comma=""
            fi
            echo "    { \"condition\": \"${j_cond}\", \"matched\": ${matched}, \"conclusion\": \"${j_res}\" }${comma}"
        done

        echo "  ],"

        # Summary
        local summary=""
        for ((i=0; i<${#_ZD_MATCHED_RESULTS[@]}; i++)); do
            if [[ -n "$summary" ]]; then
                summary="${summary}。${_ZD_MATCHED_RESULTS[$i]}"
            else
                summary="${_ZD_MATCHED_RESULTS[$i]}"
            fi
        done
        _qj_je_v "$summary"; local j_summary="$_JE"
        echo "  \"summary\": \"${j_summary}\""
        echo "}"
    } > "$output_path"
}
