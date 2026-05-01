#!/usr/bin/env bash
# Copyright (C) 2026 — Licensed under GPL-3.0
# See https://www.gnu.org/licenses/gpl-3.0.html
# qimen_yishenhuanjiang.sh — 移神换将 (化解算法核心库)
# Sourced AFTER qimen_json.sh and qimen_banmenhuaqizhen.sh

_yh_get() {
    local k="$1"
    dl_get_v "$k" 2>/dev/null && return 0
    if [[ "$k" == "${k//[^a-zA-Z0-9_]/}" ]]; then
        eval "_DL_RET=\"\${${k}:-}\""
        [[ -n "$_DL_RET" ]] && return 0
    fi
    _DL_RET=""
    return 1
}

_YH_PLATE_DATETIME=""
_YH_PLATE_SIZHU=""
_YH_DAY_STEM=""
_YH_HOUR_STEM=""
_YH_YEAR_STEM=""
_YH_PROBLEMS=()       # "palace|type|detail" per problem
_YH_RESULTS_TEXT=()   # "palace|text_block" per problem
_YH_RESULTS_PALACE=() # palace number per result (for grouping)
_YH_RESULTS_JSON=()

# --- Helper: stem wuxing ---
_yh_stem_wuxing() {
    case "$1" in
        甲|乙) echo "木";; 丙|丁) echo "火";; 戊|己) echo "土";;
        庚|辛) echo "金";; 壬|癸) echo "水";; *) echo "";;
    esac
}

# --- Helper: stem pinyin key for rules lookup ---
_yh_stem_key() {
    case "$1" in
        戊) echo "wu";; 己) echo "ji";; 庚) echo "geng";;
        辛) echo "xin";; 壬) echo "ren";; 癸) echo "gui";;
        *) echo "";;
    esac
}

# --- Helper: resolve wanwu objects from lookup field ---
# lookup format: "tiangan:乙" or "dizhi:卯" or "wuxing:金" or "deity:六合"
_yh_resolve_lookup() {
    local lookup="$1"
    [[ -z "$lookup" ]] && echo "" && return

    local type="${lookup%%:*}"
    local symbol="${lookup#*:}"
    local prefix="" result=""

    case "$type" in
        tiangan)
            _yh_get "GAN_${symbol}" || true; prefix="$_DL_RET"
            if [[ -n "$prefix" ]]; then
                _yh_get "${prefix}_器物" || true; result="$_DL_RET"
                if [[ -z "$result" ]]; then
                    _yh_get "${prefix}_概念" || true; result="$_DL_RET"
                fi
            fi
            ;;
        dizhi)
            _yh_get "ZHI_${symbol}" || true; prefix="$_DL_RET"
            if [[ -n "$prefix" ]]; then
                _yh_get "${prefix}_器物" || true; result="$_DL_RET"
            fi
            ;;
        wuxing)
            _yh_get "${symbol}_五色" || true; local color="$_DL_RET"
            _yh_get "${symbol}_天干" || true; local tg_list="$_DL_RET"
            local first_tg="${tg_list%%,*}"
            local objects=""
            if [[ -n "$first_tg" ]]; then
                _yh_get "GAN_${first_tg}" || true; prefix="$_DL_RET"
                if [[ -n "$prefix" ]]; then
                    _yh_get "${prefix}_器物" || true; objects="$_DL_RET"
                fi
            fi
            if [[ -n "$color" && -n "$objects" ]]; then
                result="${color}色物品,${objects}"
            elif [[ -n "$color" ]]; then
                result="${color}色物品"
            elif [[ -n "$objects" ]]; then
                result="$objects"
            fi
            ;;
        star)
            _yh_get "STAR_${symbol}" || true; prefix="$_DL_RET"
            if [[ -n "$prefix" ]]; then
                _yh_get "${prefix}_物品器具" || true; result="$_DL_RET"
            fi
            ;;
        gate)
            _yh_get "GATE_${symbol}" || true; prefix="$_DL_RET"
            if [[ -n "$prefix" ]]; then
                _yh_get "${prefix}_类象" || true; result="$_DL_RET"
            fi
            ;;
        deity)
            _yh_get "DEITY_${symbol}" || true; prefix="$_DL_RET"
            if [[ -n "$prefix" ]]; then
                _yh_get "${prefix}_器物物品" || true; result="$_DL_RET"
            fi
            ;;
    esac
    echo "$result"
}

# --- Helper: get override example if exists ---
_yh_get_override() {
    local key="$1"
    _yh_get "$key" 2>/dev/null || true
    echo "$_DL_RET"
}

# --- Helper: get hehua (天干化合) pair key for a given stem ---
# Returns canonical pair key: 甲己/乙庚/丙辛/丁壬/戊癸
_yh_hehua_pair_key() {
    case "$1" in
        甲|己) echo "甲己";; 乙|庚) echo "乙庚";; 丙|辛) echo "丙辛";;
        丁|壬) echo "丁壬";; 戊|癸) echo "戊癸";; *) echo "";;
    esac
}

# --- Helper: get hehua desc+objects for a stem pair ---
# Sets _YH_HEHUA_DESC and _YH_HEHUA_OBJECTS
_yh_hehua_lookup() {
    local stem="$1"
    _YH_HEHUA_DESC=""
    _YH_HEHUA_OBJECTS=""
    local pair
    pair="$(_yh_hehua_pair_key "$stem")"
    [[ -z "$pair" ]] && return
    _yh_get "hehua_${pair}_desc" 2>/dev/null || true; _YH_HEHUA_DESC="$_DL_RET"
    _yh_get "hehua_${pair}_objects" 2>/dev/null || true; _YH_HEHUA_OBJECTS="$_DL_RET"
}

# --- Phase 1: Scan plate for problems ---
yh_scan_problems() {
    _YH_PROBLEMS=()

    local p val deity gate gate_wx p_wx tg
    for p in 1 2 3 4 6 7 8 9; do
        # 击刑
        _yh_get "palace_${p}_ji_xing" 2>/dev/null || true; val="$_DL_RET"
        if [[ "$val" == "true" ]]; then
            _yh_get "palace_${p}_tian_gan" 2>/dev/null || true; tg="$_DL_RET"
            _YH_PROBLEMS+=("${p}|jixing|${tg}")
        fi

        # 入墓(干)
        _yh_get "palace_${p}_rumu_gan" 2>/dev/null || true; val="$_DL_RET"
        if [[ "$val" == "true" ]]; then
            _yh_get "palace_${p}_tian_gan" 2>/dev/null || true; tg="$_DL_RET"
            _YH_PROBLEMS+=("${p}|rumu|${tg}")
        fi

        # 门迫
        _yh_get "palace_${p}_men_po" 2>/dev/null || true; val="$_DL_RET"
        if [[ "$val" == "true" ]]; then
            _yh_get "palace_${p}_gate" 2>/dev/null || true; gate="$_DL_RET"
            _YH_PROBLEMS+=("${p}|menpo|${gate}")
        fi

        # 空亡
        _yh_get "palace_${p}_kong_wang" 2>/dev/null || true; val="$_DL_RET"
        if [[ "$val" == "true" ]]; then
            _yh_get "palace_${p}_tian_gan" 2>/dev/null || true; tg="$_DL_RET"
            _YH_PROBLEMS+=("${p}|kongwang|${tg}")
        fi

        # 庚
        _yh_get "palace_${p}_geng" 2>/dev/null || true; val="$_DL_RET"
        if [[ "$val" == "true" ]]; then
            _YH_PROBLEMS+=("${p}|geng|庚")
        fi

        # 白虎
        _yh_get "palace_${p}_deity" 2>/dev/null || true; deity="$_DL_RET"
        if [[ "$deity" == "白虎" ]]; then
            _YH_PROBLEMS+=("${p}|baihu|白虎")
        fi
    done
}

# --- Helper: generate miexiang (灭象) text and JSON for a stem ---
# Usage: _yh_build_miexiang "天干" "方位名"
# Sets: _YH_MX_TEXT, _YH_MX_JSON
_yh_build_miexiang() {
    local name="$1" dir="$2" lookup_type="${3:-tiangan}"
    local objects=""
    objects="$(_yh_resolve_lookup "${lookup_type}:${name}")"

    # Validate target palaces (7=正西, 1=正北) for六害
    local _safe7="true" _safe1="true" _p_entry
    for _p_entry in "${_YH_PROBLEMS[@]}"; do
        case "$_p_entry" in
            7\|jixing\|*|7\|menpo\|*|7\|kongwang\|*) _safe7="false" ;;
            1\|jixing\|*|1\|menpo\|*|1\|kongwang\|*) _safe1="false" ;;
        esac
    done

    local _target_text="" _target_note=""
    if [[ "$_safe7" == "true" && "$_safe1" == "true" ]]; then
        _target_text="正西或正北"
    elif [[ "$_safe7" == "true" ]]; then
        _target_text="正西"
        _target_note="（正北有六害，避开）"
    elif [[ "$_safe1" == "true" ]]; then
        _target_text="正北"
        _target_note="（正西有六害，避开）"
    else
        _target_text="正西或正北"
        _target_note="[注意]正西正北均有六害，需择较轻一方"
    fi

    _YH_MX_TEXT="灭象: 把${name}象从${dir}移走，移至${_target_text}${_target_note}"
    if [[ -n "$objects" ]]; then
        _YH_MX_TEXT="${_YH_MX_TEXT}
${name}象: ${objects}"
    fi
    _YH_MX_TEXT="${_YH_MX_TEXT}
"

    _qj_je_v "$objects"; local j_obj="$_JE"
    _qj_je_v "${_target_note}"; local j_note="$_JE"
    _YH_MX_JSON="{\"method\": \"灭象\", \"target\": \"移走${name}象\", \"action\": \"从${dir}移至${_target_text}\", \"objects\": \"${j_obj}\", \"viable\": true, \"source\": \"bmhq L221\", \"dynamic\": null, \"note\": \"${j_note}\"}"
}

# --- Phase 2: Generate化解 paths for a jixing problem ---
_yh_build_jixing_paths() {
    local palace="$1" tg="$2"
    local key
    key="$(_yh_stem_key "$tg")"
    [[ -z "$key" ]] && return

    local paths_json="" paths_text="" path_idx=1
    local method target action lookup viable source note placement override_objects

    # Miexiang first (bmhq L221: 天干的刑必须灭象)
    _yh_get "palace_${palace}_direction" 2>/dev/null || true; local mx_dir="$_DL_RET"
    _yh_build_miexiang "$tg" "${mx_dir:-?}"
    paths_text="${_YH_MX_TEXT}"
    paths_json="${_YH_MX_JSON}"

    # 贪合忘生: check if same palace also has rumu
    local _palace_has_rumu="false"
    local _p_entry
    for _p_entry in "${_YH_PROBLEMS[@]}"; do
        [[ "$_p_entry" == "${palace}|rumu|"* ]] && { _palace_has_rumu="true"; break; }
    done

    while true; do
        _yh_get "jixing_${key}_path${path_idx}_method" 2>/dev/null || true; method="$_DL_RET"
        [[ -z "$method" ]] && break

        _yh_get "jixing_${key}_path${path_idx}_target" 2>/dev/null || true; target="$_DL_RET"
        # target may be split into target_a / target_b
        if [[ -z "$target" ]]; then
            _yh_get "jixing_${key}_path${path_idx}_target_a" 2>/dev/null || true; target="$_DL_RET"
            _yh_get "jixing_${key}_path${path_idx}_target_b" 2>/dev/null || true
            [[ -n "$_DL_RET" ]] && target="${target},${_DL_RET}"
        fi

        _yh_get "jixing_${key}_path${path_idx}_action" 2>/dev/null || true; action="$_DL_RET"
        _yh_get "jixing_${key}_path${path_idx}_viable" 2>/dev/null || true; viable="$_DL_RET"
        _yh_get "jixing_${key}_path${path_idx}_source" 2>/dev/null || true; source="$_DL_RET"
        _yh_get "jixing_${key}_path${path_idx}_note" 2>/dev/null || true; note="$_DL_RET"
        _yh_get "jixing_${key}_path${path_idx}_placement" 2>/dev/null || true; placement="$_DL_RET"
        _yh_get "jixing_${key}_path${path_idx}_problem" 2>/dev/null || true; local problem_reason="$_DL_RET"

        # Resolve objects from lookup
        local objects="" _obj_label="" _obj_label_a="" _obj_label_b=""
        _yh_get "jixing_${key}_path${path_idx}_lookup" 2>/dev/null || true; lookup="$_DL_RET"
        if [[ -n "$lookup" ]]; then
            objects="$(_yh_resolve_lookup "$lookup")"
            _obj_label="${lookup#*:}"
        fi
        # Try lookup_a / lookup_b
        _yh_get "jixing_${key}_path${path_idx}_lookup_a" 2>/dev/null || true; lookup="$_DL_RET"
        if [[ -n "$lookup" ]]; then
            local obj_a
            obj_a="$(_yh_resolve_lookup "$lookup")"
            _obj_label_a="${lookup#*:}"
            [[ -n "$obj_a" ]] && objects="${objects:+${objects}|}${obj_a}"
        fi
        _yh_get "jixing_${key}_path${path_idx}_lookup_b" 2>/dev/null || true; lookup="$_DL_RET"
        if [[ -n "$lookup" ]]; then
            local obj_b
            obj_b="$(_yh_resolve_lookup "$lookup")"
            _obj_label_b="${lookup#*:}"
            [[ -n "$obj_b" ]] && objects="${objects:+${objects}|}${obj_b}"
        fi

        # Check for override examples
        if [[ "$key" == "geng" && $path_idx -eq 1 ]]; then
            override_objects="$(_yh_get_override "override_geng_high_example")"
            [[ -n "$override_objects" ]] && objects="[优先]${override_objects}"
        elif [[ "$key" == "geng" && $path_idx -eq 2 ]]; then
            override_objects="$(_yh_get_override "override_geng_low_example")"
            [[ -n "$override_objects" ]] && objects="[优先]${override_objects}"
        fi

        # Hehua lookup for 暗合 paths
        local _hehua_desc="" _hehua_objects=""
        if [[ "$method" == "暗合" && -n "$target" ]]; then
            _yh_hehua_lookup "$target"
            _hehua_desc="$_YH_HEHUA_DESC"
            _hehua_objects="$_YH_HEHUA_OBJECTS"
        fi

        # Dynamic: 泄化=true, 合法(暗合/地支合)=false
        local _dynamic="false"
        [[ "$method" == "泄化" ]] && _dynamic="true"
        [[ "$method" == "避让" ]] && _dynamic="null"

        # 贪合忘生 warning on合法 paths when same palace has rumu
        if [[ "$_palace_has_rumu" == "true" && ( "$method" == "暗合" || "$method" == "地支合" ) ]]; then
            note="${note:+${note} }[注意]同宫有入墓，合法可能加重束缚，优先用泄化"
        fi



        # Build text line
        local viable_mark=""
        [[ "$viable" == "false" ]] && viable_mark="[冲突]"
        paths_text="${paths_text}
"
        paths_text="${paths_text}${method}${viable_mark}:${action:+ ${action}}"
        if [[ -n "$problem_reason" ]]; then
            paths_text="${paths_text} ${problem_reason}"
        fi
        [[ -n "$note" ]] && paths_text="${paths_text} ${note}"
        if [[ -n "$objects" ]]; then
            local _display_obj
            if [[ "$objects" == "[优先]"* ]]; then
                local _ov_part="${objects#\[优先\]}"
                local _ov_rec="${_ov_part%%|*}"
                local _ov_gen="${_ov_part#*|}"
                _display_obj="推荐: ${_ov_rec}"
                [[ "$_ov_gen" != "$_ov_rec" ]] && _display_obj="${_display_obj}
通用: ${_ov_gen}"
            elif [[ "$objects" == *"|"* ]]; then
                local _obj_first="${objects%%|*}"
                local _obj_rest="${objects#*|}"
                _display_obj="${_obj_label_a}象: ${_obj_first}
${_obj_label_b}象: ${_obj_rest}"
            else
                _display_obj="物象: ${objects}"
            fi
            paths_text="${paths_text}
${_display_obj}"
        fi
        if [[ -n "$_hehua_desc" ]]; then
            paths_text="${paths_text}
化合: ${_hehua_desc}"
            [[ -n "$_hehua_objects" ]] && paths_text="${paths_text}
化合物: ${_hehua_objects}"
        fi
        paths_text="${paths_text}
"

        # Build JSON
        _qj_je_v "$method"; local j_method="$_JE"
        _qj_je_v "$target"; local j_target="$_JE"
        _qj_je_v "$action"; local j_action="$_JE"
        _qj_je_v "$objects"; local j_objects="$_JE"
        _qj_je_v "$viable"; local j_viable="$_JE"
        _qj_je_v "$source"; local j_source="$_JE"
        _qj_je_v "${note:-}"; local j_note="$_JE"
        _qj_je_v "${placement:-}"; local j_placement="$_JE"
        _qj_je_v "${problem_reason:-}"; local j_problem="$_JE"
        _qj_je_v "$_hehua_desc"; local j_hehua_desc="$_JE"
        _qj_je_v "$_hehua_objects"; local j_hehua_obj="$_JE"

        [[ -n "$paths_json" ]] && paths_json="${paths_json},"
        paths_json="${paths_json}
          {
            \"method\": \"${j_method}\",
            \"target\": \"${j_target}\",
            \"action\": \"${j_action}\",
            \"objects\": \"${j_objects}\",
            \"viable\": ${viable:-true},
            \"source\": \"${j_source}\",
            \"note\": \"${j_note}\",
            \"placement\": \"${j_placement}\",
            \"problem\": \"${j_problem}\",
            \"dynamic\": ${_dynamic},
            \"hehua_desc\": \"${j_hehua_desc}\",
            \"hehua_objects\": \"${j_hehua_obj}\"
          }"

        path_idx=$((path_idx + 1))
    done

    _YH_CUR_PATHS_TEXT="$paths_text"
    _YH_CUR_PATHS_JSON="[${paths_json}
        ]"
}

# --- Phase 2b: Generate化解 paths for non-jixing problems ---
_yh_build_geng_paths() {
    local palace="$1"
    local paths_json="" paths_text="" i=1
    local name desc action lookup placement source objects

    # Miexiang first (bmhq L221/L231: 庚必须灭象，可移动)
    _yh_get "palace_${palace}_direction" 2>/dev/null || true; local mx_dir="$_DL_RET"
    _yh_build_miexiang "庚" "${mx_dir:-?}"
    paths_text="${_YH_MX_TEXT}"
    paths_json="${_YH_MX_JSON}"

    while true; do
        _yh_get "geng_method_${i}_name" 2>/dev/null || true; name="$_DL_RET"
        [[ -z "$name" ]] && break

        _yh_get "geng_method_${i}_desc" 2>/dev/null || true; desc="$_DL_RET"
        _yh_get "geng_method_${i}_action" 2>/dev/null || true; action="$_DL_RET"
        _yh_get "geng_method_${i}_lookup" 2>/dev/null || true; lookup="$_DL_RET"
        _yh_get "geng_method_${i}_placement" 2>/dev/null || true; placement="$_DL_RET"
        _yh_get "geng_method_${i}_source" 2>/dev/null || true; source="$_DL_RET"

        objects=""
        local _geng_label=""
        if [[ -n "$lookup" ]]; then
            objects="$(_yh_resolve_lookup "$lookup")"
            _geng_label="${lookup#*:}"
        fi

        # Override examples for geng methods
        if [[ $i -eq 1 ]]; then
            local ov
            ov="$(_yh_get_override "override_geng_high_example")"
            [[ -n "$ov" ]] && objects="[优先]${ov}"
        elif [[ $i -eq 2 ]]; then
            local ov
            ov="$(_yh_get_override "override_geng_low_example")"
            [[ -n "$ov" ]] && objects="[优先]${ov}"
        fi

        # Hehua for合法 (desc contains "暗合")
        local _hehua_desc="" _hehua_objects=""
        if [[ "$desc" == *"暗合"* && -n "$_geng_label" ]]; then
            _yh_hehua_lookup "$_geng_label"
            _hehua_desc="$_YH_HEHUA_DESC"
            _hehua_objects="$_YH_HEHUA_OBJECTS"
        fi

        local _dynamic="false"
        [[ "$name" == "泄化" ]] && _dynamic="true"

        paths_text="${paths_text}
"
        paths_text="${paths_text}${name}（${desc}）: ${action:-}"
        if [[ -n "$objects" ]]; then
            local _display_obj
            if [[ "$objects" == "[优先]"* ]]; then
                _display_obj="推荐: ${objects#\[优先\]}"
            else
                _display_obj="${_geng_label:-物}象: ${objects}"
            fi
            paths_text="${paths_text}
${_display_obj}"
        fi
        if [[ -n "$_hehua_desc" ]]; then
            paths_text="${paths_text}
化合: ${_hehua_desc}"
            [[ -n "$_hehua_objects" ]] && paths_text="${paths_text}
化合物: ${_hehua_objects}"
        fi
        paths_text="${paths_text}
"

        _qj_je_v "$name"; local j_name="$_JE"
        _qj_je_v "$desc"; local j_desc="$_JE"
        _qj_je_v "${action:-}"; local j_action="$_JE"
        _qj_je_v "$objects"; local j_objects="$_JE"
        _qj_je_v "$source"; local j_source="$_JE"
        _qj_je_v "${placement:-}"; local j_placement="$_JE"
        _qj_je_v "$_hehua_desc"; local j_hehua_desc="$_JE"
        _qj_je_v "$_hehua_objects"; local j_hehua_obj="$_JE"

        [[ -n "$paths_json" ]] && paths_json="${paths_json},"
        paths_json="${paths_json}
          {
            \"method\": \"${j_name}\",
            \"desc\": \"${j_desc}\",
            \"action\": \"${j_action}\",
            \"objects\": \"${j_objects}\",
            \"viable\": true,
            \"source\": \"${j_source}\",
            \"placement\": \"${j_placement}\",
            \"dynamic\": ${_dynamic},
            \"hehua_desc\": \"${j_hehua_desc}\",
            \"hehua_objects\": \"${j_hehua_obj}\"
          }"

        i=$((i + 1))
    done

    _YH_CUR_PATHS_TEXT="$paths_text"
    _YH_CUR_PATHS_JSON="[${paths_json}
        ]"
}

_yh_build_rumu_paths() {
    local palace="$1" element="$2" element_wx="${3:-}" lookup_type="${4:-tiangan}"
    local paths_json="" paths_text=""

    # If wuxing not passed, derive from stem
    if [[ -z "$element_wx" ]]; then
        element_wx="$(_yh_stem_wuxing "$element")"
    fi

    # Miexiang first (bmhq L221/L230)
    _yh_get "palace_${palace}_direction" 2>/dev/null || true; local mx_dir="$_DL_RET"
    _yh_build_miexiang "$element" "${mx_dir:-?}" "$lookup_type"
    paths_text="${_YH_MX_TEXT}"
    paths_json="${_YH_MX_JSON}"

    # Determine mu (tomb) branch
    local wx_en=""
    _yh_get "wx_name_${element_wx}" 2>/dev/null || true; wx_en="$_DL_RET"
    local mu_branch=""
    if [[ -n "$wx_en" ]]; then
        _yh_get "mu_${wx_en}" 2>/dev/null || true; mu_branch="$_DL_RET"
    fi

    # Method 1: chong mu
    local chong_branch=""
    if [[ -n "$mu_branch" ]]; then
        _yh_get "liuchong_${mu_branch}" 2>/dev/null || true; chong_branch="$_DL_RET"
    fi
    local chong_objects=""
    if [[ -n "$chong_branch" ]]; then
        chong_objects="$(_yh_resolve_lookup "dizhi:${chong_branch}")"
    fi

    paths_text="${paths_text}
冲墓: 补${chong_branch:-?}象冲开${mu_branch:-?}墓"
    if [[ -n "$chong_objects" ]]; then
        paths_text="${paths_text}
物象: ${chong_objects}"
    fi
    paths_text="${paths_text}
"

    # Method 2: he chu (六合合出)
    local he_branch=""
    if [[ -n "$mu_branch" ]]; then
        _yh_get "liuhe_${mu_branch}" 2>/dev/null || true; he_branch="$_DL_RET"
    fi
    local he_objects=""
    if [[ -n "$he_branch" ]]; then
        he_objects="$(_yh_resolve_lookup "dizhi:${he_branch}")"
    fi

    paths_text="${paths_text}
合出: 补${he_branch:-?}象合出${mu_branch:-?}墓"
    if [[ -n "$he_objects" ]]; then
        paths_text="${paths_text}
物象: ${he_objects}"
    fi
    paths_text="${paths_text}
"

    # Method 3: avoid
    _yh_get "palace_${palace}_direction" 2>/dev/null || true; local dir="$_DL_RET"
    paths_text="${paths_text}
避让: 避开${dir:-?}方位活动
"

    # Build JSON
    _qj_je_v "${chong_branch:-}"; local j_cb="$_JE"
    _qj_je_v "${mu_branch:-}"; local j_mb="$_JE"
    _qj_je_v "$chong_objects"; local j_co="$_JE"
    _qj_je_v "${he_branch:-}"; local j_hb="$_JE"
    _qj_je_v "$he_objects"; local j_ho="$_JE"
    _qj_je_v "${dir:-}"; local j_dir="$_JE"

    paths_json="[
          ${_YH_MX_JSON},
          {\"method\": \"冲墓\", \"target\": \"${j_cb}冲${j_mb}\", \"objects\": \"${j_co}\", \"viable\": true, \"source\": \"参考文档\", \"dynamic\": false},
          {\"method\": \"合出\", \"target\": \"${j_hb}合${j_mb}\", \"objects\": \"${j_ho}\", \"viable\": true, \"source\": \"参考文档\", \"dynamic\": false},
          {\"method\": \"避让\", \"target\": \"避开${j_dir}\", \"objects\": \"\", \"viable\": true, \"source\": \"（推导）\", \"dynamic\": null}
        ]"

    _YH_CUR_PATHS_TEXT="$paths_text"
    _YH_CUR_PATHS_JSON="$paths_json"
}

_yh_build_menpo_paths() {
    local palace="$1" gate="$2"
    local paths_json="" paths_text=""

    # bmhq L281: "布阵压制门迫用合"
    _yh_get "palace_${palace}_tian_gan" 2>/dev/null || true; local tg="$_DL_RET"

    local anhe_target=""
    _yh_get "anhe_${tg}" 2>/dev/null || true; anhe_target="$_DL_RET"

    local he_objects=""
    [[ -n "$anhe_target" ]] && he_objects="$(_yh_resolve_lookup "tiangan:${anhe_target}")"

    local _hehua_desc="" _hehua_objects=""
    if [[ -n "$anhe_target" ]]; then
        _yh_hehua_lookup "$anhe_target"
        _hehua_desc="$_YH_HEHUA_DESC"
        _hehua_objects="$_YH_HEHUA_OBJECTS"
    fi

    paths_text="用合: 补${anhe_target:-?}象合住${tg:-?}（天干合压制门迫）"
    if [[ -n "$he_objects" ]]; then
        paths_text="${paths_text}
${anhe_target}象: ${he_objects}"
    fi
    if [[ -n "$_hehua_desc" ]]; then
        paths_text="${paths_text}
化合: ${_hehua_desc}"
        [[ -n "$_hehua_objects" ]] && paths_text="${paths_text}
化合物: ${_hehua_objects}"
    fi
    paths_text="${paths_text}
"

    _qj_je_v "$he_objects"; local j_ho="$_JE"
    _qj_je_v "${anhe_target:-}"; local j_at="$_JE"
    _qj_je_v "${tg:-}"; local j_tg="$_JE"
    _qj_je_v "$_hehua_desc"; local j_hehua_desc="$_JE"
    _qj_je_v "$_hehua_objects"; local j_hehua_obj="$_JE"

    paths_json="[
          {\"method\": \"用合\", \"target\": \"${j_at}合${j_tg}\", \"objects\": \"${j_ho}\", \"viable\": true, \"source\": \"bmhq L281\", \"dynamic\": false, \"hehua_desc\": \"${j_hehua_desc}\", \"hehua_objects\": \"${j_hehua_obj}\"}
        ]"

    _YH_CUR_PATHS_TEXT="$paths_text"
    _YH_CUR_PATHS_JSON="$paths_json"
}

_yh_build_kongwang_paths() {
    local palace="$1" tg="$2"
    local paths_text="" paths_json=""
    local objects=""

    # 补该天干的象
    objects="$(_yh_resolve_lookup "tiangan:${tg}")"

    # Check override for 戊
    if [[ "$tg" == "戊" ]]; then
        local ov
        ov="$(_yh_get_override "override_wu_kongwang_example")"
        [[ -n "$ov" ]] && objects="[优先]${ov}|${objects}"
    fi

    paths_text="补象: 补${tg}象（缺什么补什么）"
    if [[ -n "$objects" ]]; then
        local _display_obj
        if [[ "$objects" == "[优先]"* ]]; then
            local _ov_part="${objects#\[优先\]}"
            local _ov_rec="${_ov_part%%|*}"
            local _ov_gen="${_ov_part#*|}"
            _display_obj="推荐: ${_ov_rec}"
            [[ "$_ov_gen" != "$_ov_rec" ]] && _display_obj="${_display_obj}
通用: ${_ov_gen}"
            else
                _display_obj="${_obj_label:-物}象: ${objects}"
            fi
        paths_text="${paths_text}
${_display_obj}"
    fi
    paths_text="${paths_text}
"

    _qj_je_v "$objects"; local j_obj="$_JE"
    _qj_je_v "$tg"; local j_tg="$_JE"

    paths_json="[
          {\"method\": \"补象\", \"target\": \"补${j_tg}象\", \"objects\": \"${j_obj}\", \"viable\": true, \"source\": \"bmhq L292+L296\", \"dynamic\": false}
        ]"

    _YH_CUR_PATHS_TEXT="$paths_text"
    _YH_CUR_PATHS_JSON="$paths_json"
}

_yh_build_baihu_paths() {
    local palace="$1"
    local paths_text="" paths_json=""

    # bmhq L291: "布阵压制庚合白虎用乙，除了西北乙入墓不能用"
    local yi_objects=""
    yi_objects="$(_yh_resolve_lookup "tiangan:乙")"

    local viable="true"
    [[ "$palace" == "6" ]] && viable="false"

    _yh_hehua_lookup "乙"
    local _hehua_desc="$_YH_HEHUA_DESC"
    local _hehua_objects="$_YH_HEHUA_OBJECTS"

    paths_text="用乙: 补乙象压制白虎"
    [[ "$viable" == "false" ]] && paths_text="用乙[冲突]: 西北乙入墓不能用"
    if [[ -n "$yi_objects" && "$viable" == "true" ]]; then
        paths_text="${paths_text}
乙象: ${yi_objects}"
    fi
    if [[ -n "$_hehua_desc" && "$viable" == "true" ]]; then
        paths_text="${paths_text}
化合: ${_hehua_desc}"
        [[ -n "$_hehua_objects" ]] && paths_text="${paths_text}
化合物: ${_hehua_objects}"
    fi
    paths_text="${paths_text}
"

    # Method 2: 泄宫气
    _yh_get "palace_${palace}_wuxing" || true; local p_wx="$_DL_RET"
    local xie_wx_cn="" xie_objects=""
    if [[ -n "$p_wx" ]]; then
        local pw_en=""
        _yh_get "wx_name_${p_wx}" || true; pw_en="$_DL_RET"
        [[ -n "$pw_en" ]] && { _yh_get "xie_${pw_en}" || true; xie_wx_cn="$_DL_RET"; }
    fi
    [[ -n "$xie_wx_cn" ]] && xie_objects="$(_yh_resolve_lookup "wuxing:${xie_wx_cn}")"

    paths_text="${paths_text}
泄化: 补${xie_wx_cn:-?}象泄${p_wx:-?}气"
    if [[ -n "$xie_objects" ]]; then
        paths_text="${paths_text}
${xie_wx_cn}象: ${xie_objects}"
    fi
    paths_text="${paths_text}
"

    _qj_je_v "$yi_objects"; local j_yo="$_JE"
    _qj_je_v "$xie_objects"; local j_xo="$_JE"
    _qj_je_v "$_hehua_desc"; local j_hehua_desc="$_JE"
    _qj_je_v "$_hehua_objects"; local j_hehua_obj="$_JE"

    paths_json="[
          {\"method\": \"用乙\", \"target\": \"补乙象压制白虎\", \"objects\": \"${j_yo}\", \"viable\": ${viable}, \"source\": \"bmhq L291\", \"dynamic\": false, \"hehua_desc\": \"${j_hehua_desc}\", \"hehua_objects\": \"${j_hehua_obj}\"},
          {\"method\": \"泄化\", \"target\": \"泄宫${p_wx:-}气\", \"objects\": \"${j_xo}\", \"viable\": true, \"source\": \"（推导）\", \"dynamic\": true, \"hehua_desc\": \"\", \"hehua_objects\": \"\"}
        ]"

    _YH_CUR_PATHS_TEXT="$paths_text"
    _YH_CUR_PATHS_JSON="$paths_json"
}

# --- Phase 3: Process all problems and build results ---
yh_process_problems() {
    _YH_RESULTS_TEXT=()
    _YH_RESULTS_PALACE=()
    _YH_RESULTS_JSON=()

    local problem palace type detail
    for problem in "${_YH_PROBLEMS[@]}"; do
        IFS='|' read -r palace type detail <<< "$problem"

        # Get palace info
        _yh_get "palace_${palace}_name" 2>/dev/null || true; local p_name="$_DL_RET"
        _yh_get "palace_${palace}_direction" 2>/dev/null || true; local p_dir="$_DL_RET"
        _yh_get "palace_${palace}_wuxing" 2>/dev/null || true; local p_wx="$_DL_RET"

        # Get degree info
        _yh_get "gong_${palace}_degree_start" 2>/dev/null || true; local deg_s="$_DL_RET"
        _yh_get "gong_${palace}_degree_end" 2>/dev/null || true; local deg_e="$_DL_RET"

        local type_label=""
        _YH_CUR_PATHS_TEXT=""
        _YH_CUR_PATHS_JSON="[]"

        case "$type" in
            jixing)
                type_label="击刑"
                _yh_build_jixing_paths "$palace" "$detail"
                ;;
            rumu)
                type_label="干墓"
                _yh_build_rumu_paths "$palace" "$detail" "" "tiangan"
                ;;
            rumu_star)
                type_label="星墓"
                _yh_get "palace_${palace}_star_wuxing" 2>/dev/null || true; local star_wx="$_DL_RET"
                _yh_build_rumu_paths "$palace" "$detail" "$star_wx" "star"
                ;;
            rumu_gate)
                type_label="门墓"
                _yh_get "palace_${palace}_gate_wuxing" 2>/dev/null || true; local gate_wx="$_DL_RET"
                _yh_build_rumu_paths "$palace" "$detail" "$gate_wx" "gate"
                ;;
            menpo)
                type_label="门迫"
                _yh_build_menpo_paths "$palace" "$detail"
                ;;
            kongwang)
                type_label="空亡"
                _yh_build_kongwang_paths "$palace" "$detail"
                ;;
            geng)
                type_label="庚"
                _yh_build_geng_paths "$palace"
                ;;
            baihu)
                type_label="虎"
                _yh_build_baihu_paths "$palace"
                ;;
        esac

        # Build text
        local text_block="" indented_paths=""
        indented_paths="$(printf '%s' "$_YH_CUR_PATHS_TEXT" | sed 's/^/  /')"
        text_block="- ${detail}[${type_label}]
${indented_paths}"
        _YH_RESULTS_TEXT+=("${palace}|${text_block}")
        _YH_RESULTS_PALACE+=("$palace")

        # Build JSON item
        _qj_je_v "$p_name"; local j_pn="$_JE"
        _qj_je_v "$p_dir"; local j_pd="$_JE"
        _qj_je_v "$p_wx"; local j_pwx="$_JE"
        _qj_je_v "$type_label"; local j_tl="$_JE"
        _qj_je_v "$type"; local j_type="$_JE"
        _qj_je_v "$detail"; local j_detail="$_JE"

        _YH_RESULTS_JSON+=("{
      \"palace\": ${palace},
      \"palace_name\": \"${j_pn}\",
      \"direction\": \"${j_pd}\",
      \"wuxing\": \"${j_pwx}\",
      \"degree_start\": ${deg_s:-0},
      \"degree_end\": ${deg_e:-0},
      \"problem_type\": \"${j_type}\",
      \"problem_label\": \"${j_tl}\",
      \"problem_detail\": \"${j_detail}\",
      \"paths\": ${_YH_CUR_PATHS_JSON}
    }")
    done
}

# --- Phase 4: Output ---
yh_output_text() {
    printf "移神换将化解分析\n\n"
    printf "[命局信息]\n"
    printf "时间: %s\n" "$_YH_PLATE_DATETIME"
    printf "四柱: %s\n" "$_YH_PLATE_SIZHU"
    printf "生年干: %s\n日干: %s\n时干: %s\n" "$_YH_YEAR_STEM" "$_YH_DAY_STEM" "$_YH_HOUR_STEM"

    if [[ ${#_YH_PROBLEMS[@]} -eq 0 ]]; then
        printf "未检测到需要化解的问题。\n"
        return
    fi

    local i=0 last_palace=""

    for i in "${!_YH_RESULTS_TEXT[@]}"; do
        local cur_palace="${_YH_RESULTS_PALACE[$i]}"
        local entry="${_YH_RESULTS_TEXT[$i]}"
        local text_body="${entry#*|}"

        if [[ "$cur_palace" != "$last_palace" ]]; then
            _yh_get "palace_${cur_palace}_name" 2>/dev/null || true; local pn="$_DL_RET"
            _yh_get "palace_${cur_palace}_direction" 2>/dev/null || true; local pd="$_DL_RET"
            _yh_get "palace_${cur_palace}_wuxing" 2>/dev/null || true; local pw="$_DL_RET"
            printf "\n[ %s｜%s｜%s ]\n" "$pn" "$pd" "$pw"

            _yh_get "palace_${cur_palace}_dizhi" 2>/dev/null || true; local p_dz="$_DL_RET"
            _yh_get "palace_${cur_palace}_tian_gan" 2>/dev/null || true; local p_tg="$_DL_RET"
            _yh_get "palace_${cur_palace}_tian_gan_wuxing" 2>/dev/null || true; local p_tgw="$_DL_RET"
            _yh_get "palace_${cur_palace}_di_gan" 2>/dev/null || true; local p_dg="$_DL_RET"
            _yh_get "palace_${cur_palace}_di_gan_wuxing" 2>/dev/null || true; local p_dgw="$_DL_RET"
            _yh_get "palace_${cur_palace}_star" 2>/dev/null || true; local p_star="$_DL_RET"
            _yh_get "palace_${cur_palace}_star_jixi" 2>/dev/null || true; local p_star_jx="$_DL_RET"
            _yh_get "palace_${cur_palace}_gate" 2>/dev/null || true; local p_gate="$_DL_RET"
            _yh_get "palace_${cur_palace}_gate_jixi" 2>/dev/null || true; local p_gate_jx="$_DL_RET"
            _yh_get "palace_${cur_palace}_deity" 2>/dev/null || true; local p_deity="$_DL_RET"
            _yh_get "palace_${cur_palace}_state" 2>/dev/null || true; local p_state="$_DL_RET"
            _yh_get "palace_${cur_palace}_xiantian" 2>/dev/null || true; local p_xt="$_DL_RET"
            _yh_get "palace_${cur_palace}_houtian" 2>/dev/null || true; local p_ht="$_DL_RET"
            _yh_get "palace_${cur_palace}_weishu" 2>/dev/null || true; local p_ws="$_DL_RET"

            printf "  地支: %s\n" "$p_dz"
            printf "  天盘: %s(%s)\n" "$p_tg" "$p_tgw"
            printf "  地盘: %s(%s)\n" "$p_dg" "$p_dgw"
            printf "  神  : %s\n" "$p_deity"
            printf "  星  : %s(%s)\n" "$p_star" "$p_star_jx"
            printf "  门  : %s(%s)\n" "$p_gate" "$p_gate_jx"
            printf "  状态: %s\n" "$p_state"

            # 格局 line: collect markers
            local _markers=""
            _yh_get "palace_${cur_palace}_kong_wang" 2>/dev/null || true
            [[ "$_DL_RET" == "true" ]] && _markers="${_markers}[空亡] "
            _yh_get "palace_${cur_palace}_ji_xing" 2>/dev/null || true
            [[ "$_DL_RET" == "true" ]] && _markers="${_markers}[击刑] "
            _yh_get "palace_${cur_palace}_geng" 2>/dev/null || true
            [[ "$_DL_RET" == "true" ]] && _markers="${_markers}[庚] "
            _yh_get "palace_${cur_palace}_rumu_gan" 2>/dev/null || true
            [[ "$_DL_RET" == "true" ]] && _markers="${_markers}[干墓] "
            _yh_get "palace_${cur_palace}_rumu_star" 2>/dev/null || true
            [[ "$_DL_RET" == "true" ]] && _markers="${_markers}[星墓] "
            _yh_get "palace_${cur_palace}_rumu_gate" 2>/dev/null || true
            [[ "$_DL_RET" == "true" ]] && _markers="${_markers}[门墓] "
            _yh_get "palace_${cur_palace}_men_po" 2>/dev/null || true
            [[ "$_DL_RET" == "true" ]] && _markers="${_markers}[门迫] "
            _yh_get "palace_${cur_palace}_yi_ma" 2>/dev/null || true
            [[ "$_DL_RET" == "true" ]] && _markers="${_markers}[驿马] "
            _yh_get "palace_${cur_palace}_star_fan_yin" 2>/dev/null || true
            [[ "$_DL_RET" == "true" ]] && _markers="${_markers}[星反吟] "
            _yh_get "palace_${cur_palace}_gate_fan_yin" 2>/dev/null || true
            [[ "$_DL_RET" == "true" ]] && _markers="${_markers}[门反吟] "
            _yh_get "palace_${cur_palace}_star_fu_yin" 2>/dev/null || true
            [[ "$_DL_RET" == "true" ]] && _markers="${_markers}[星伏吟] "
            _yh_get "palace_${cur_palace}_gate_fu_yin" 2>/dev/null || true
            [[ "$_DL_RET" == "true" ]] && _markers="${_markers}[门伏吟] "
            [[ -n "$_markers" ]] && printf "  格局: %s\n" "${_markers% }"

            printf "  先天数: %s  后天数: %s  尾数: %s\n" "$p_xt" "$p_ht" "$p_ws"

            last_palace="$cur_palace"
        else
            printf "\n"
        fi
        printf '%s\n' "$text_body"
    done

    printf "\n"
    # Print禁忌
    printf "[禁忌]\n"
    local ji=1 jinji_val=""
    _yh_get "jinji_count" 2>/dev/null || true; local jc="$_DL_RET"
    while [[ $ji -le ${jc:-6} ]]; do
        _yh_get "jinji_${ji}" 2>/dev/null || true; jinji_val="$_DL_RET"
        [[ -n "$jinji_val" ]] && printf '%s\n' "- ${jinji_val}"
        ji=$((ji + 1))
    done

    printf "\n[时间规则]\n"
    _yh_get "timing_general" 2>/dev/null || true
    [[ -n "$_DL_RET" ]] && printf '%s\n' "- ${_DL_RET}"
    _yh_get "timing_keying" 2>/dev/null || true
    [[ -n "$_DL_RET" ]] && printf '%s\n' "- ${_DL_RET}"

    # Print引动
    printf "\n[引动方式]\n"
    local yi=1 yd_name="" yd_desc=""
    _yh_get "yindong_count" 2>/dev/null || true; local yc="$_DL_RET"
    while [[ $yi -le ${yc:-3} ]]; do
        _yh_get "yindong_${yi}_name" 2>/dev/null || true; yd_name="$_DL_RET"
        _yh_get "yindong_${yi}_desc" 2>/dev/null || true; yd_desc="$_DL_RET"
        [[ -n "$yd_name" ]] && printf '%s\n' "- ${yd_name}: ${yd_desc}"
        yi=$((yi + 1))
    done
    printf "\n"
}

yh_output_json() {
    local output_path="$1"

    _qj_je_v "$_YH_PLATE_DATETIME"; local j_dt="$_JE"
    _qj_je_v "$_YH_PLATE_SIZHU"; local j_sz="$_JE"
    _qj_je_v "$_YH_DAY_STEM"; local j_ds="$_JE"
    _qj_je_v "$_YH_HOUR_STEM"; local j_hs="$_JE"
    _qj_je_v "$_YH_YEAR_STEM"; local j_ys="$_JE"

    # Build problems array
    local problems_arr="" first=1
    for item in "${_YH_RESULTS_JSON[@]}"; do
        (( first )) || problems_arr="${problems_arr},"
        first=0
        problems_arr="${problems_arr}
    ${item}"
    done

    # Build jinji array
    local jinji_arr="" ji=1 jinji_val="" jfirst=1
    _yh_get "jinji_count" 2>/dev/null || true; local jc="$_DL_RET"
    while [[ $ji -le ${jc:-6} ]]; do
        _yh_get "jinji_${ji}" 2>/dev/null || true; jinji_val="$_DL_RET"
        if [[ -n "$jinji_val" ]]; then
            _qj_je_v "$jinji_val"; local j_jv="$_JE"
            (( jfirst )) || jinji_arr="${jinji_arr},"
            jfirst=0
            jinji_arr="${jinji_arr} \"${j_jv}\""
        fi
        ji=$((ji + 1))
    done

    # Build yindong array
    local yindong_arr="" yi=1 yd_name="" yd_desc="" yfirst=1
    _yh_get "yindong_count" 2>/dev/null || true; local yc="$_DL_RET"
    while [[ $yi -le ${yc:-3} ]]; do
        _yh_get "yindong_${yi}_name" 2>/dev/null || true; yd_name="$_DL_RET"
        _yh_get "yindong_${yi}_desc" 2>/dev/null || true; yd_desc="$_DL_RET"
        if [[ -n "$yd_name" ]]; then
            _qj_je_v "$yd_name"; local j_yn="$_JE"
            _qj_je_v "$yd_desc"; local j_yd="$_JE"
            (( yfirst )) || yindong_arr="${yindong_arr},"
            yfirst=0
            yindong_arr="${yindong_arr} {\"name\": \"${j_yn}\", \"desc\": \"${j_yd}\"}"
        fi
        yi=$((yi + 1))
    done

    # Build timing object
    _yh_get "timing_general" 2>/dev/null || true; _qj_je_v "$_DL_RET"; local j_tg="$_JE"
    _yh_get "timing_keying" 2>/dev/null || true; _qj_je_v "$_DL_RET"; local j_tk="$_JE"

    cat > "$output_path" <<ENDJSON
{
  "type": "yishenhuanjiang",
  "datetime": "${j_dt}",
  "sizhu": "${j_sz}",
  "day_stem": "${j_ds}",
  "hour_stem": "${j_hs}",
  "year_stem": "${j_ys}",
  "problem_count": ${#_YH_PROBLEMS[@]},
  "problems": [${problems_arr}
  ],
  "jinji": [${jinji_arr} ],
  "timing": {"general": "${j_tg}", "keying": "${j_tk}"},
  "yindong": [${yindong_arr} ]
}
ENDJSON
}

# --- Main entry ---
yh_run_analysis() {
    local plate_json_path="$1"
    local birth_json_path="$2"
    local output_path="$3"

    # Reset
    _YH_PLATE_DATETIME=""
    _YH_PLATE_SIZHU=""
    _YH_DAY_STEM=""
    _YH_HOUR_STEM=""
    _YH_YEAR_STEM=""
    _YH_PROBLEMS=()
    _YH_RESULTS_TEXT=()
    _YH_RESULTS_PALACE=()
    _YH_RESULTS_JSON=()

    # Parse plate
    qj_parse_plate_json "$plate_json_path"

    _yh_get "plate_datetime" 2>/dev/null || true; _YH_PLATE_DATETIME="$_DL_RET"
    _yh_get "plate_si_zhu_year" 2>/dev/null || true; local y="$_DL_RET"
    _yh_get "plate_si_zhu_month" 2>/dev/null || true; local m="$_DL_RET"
    _yh_get "plate_si_zhu_day" 2>/dev/null || true; local d="$_DL_RET"
    _yh_get "plate_si_zhu_hour" 2>/dev/null || true; local h="$_DL_RET"
    _YH_PLATE_SIZHU="${y} ${m} ${d} ${h}"
    _YH_DAY_STEM="$(_hq_extract_stem "$d")"
    _YH_HOUR_STEM="$(_hq_extract_stem "$h")"

    # Get year stem from birth plate (may differ from analysis plate)
    if [[ "$plate_json_path" != "$birth_json_path" ]]; then
        # If analyzing event plate, still need birth year stem
        local _saved_keys=() _saved_vals=()
        # Re-read birth for year stem only
        local birth_content=""
        birth_content="$(<"$birth_json_path")"
        local line=""
        while IFS= read -r line; do
            if [[ "$line" == *'"year":'* && "$line" == *'"si_zhu"'* ]] || [[ "$line" == *'"year": "'* ]]; then
                local ystem="${line#*\"year\": \"}"
                ystem="${ystem%%\"*}"
                if [[ ${#ystem} -ge 1 ]]; then
                    _YH_YEAR_STEM="${ystem:0:1}"
                    break
                fi
            fi
        done <<< "$birth_content"
    else
        _YH_YEAR_STEM="$(_hq_extract_stem "$y")"
    fi

    # Scan problems
    yh_scan_problems

    # Process and generate paths
    yh_process_problems

    # Output
    yh_output_text
    yh_output_json "$output_path"
}
