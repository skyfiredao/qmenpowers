#!/usr/bin/env bash
# Copyright (C) 2025 — Licensed under GPL-3.0
# See https://www.gnu.org/licenses/gpl-3.0.html
# data_loader.sh — Generic .dat file parser
# Dual-store: ASCII-safe keys use eval'd variables (_DLV_*) for O(1);
# CJK/non-ASCII keys use indexed arrays for Bash 3.2 compat.

_DL_KEYS=()
_DL_VALS=()

_dl_is_ascii() {
    [[ "$1" == "${1//[^a-zA-Z0-9_]/}" ]]
}

dl_set() {
    local k="$1" v="$2" i
    if _dl_is_ascii "$k"; then
        eval "_DLV_${k}=\${v}"
        eval "_DLV_${k}_SET=1"
    else
        for ((i=${#_DL_KEYS[@]}-1; i>=0; i--)); do
            if [[ "${_DL_KEYS[$i]}" == "$k" ]]; then
                _DL_VALS[$i]="$v"
                return
            fi
        done
        _DL_KEYS+=("$k")
        _DL_VALS+=("$v")
    fi
}

dl_get() {
    local k="$1" i
    if _dl_is_ascii "$k"; then
        eval "i=\${_DLV_${k}_SET:-}"
        if [[ -n "$i" ]]; then
            eval "echo \"\${_DLV_${k}}\""
            return 0
        fi
        return 1
    fi
    for ((i=0; i<${#_DL_KEYS[@]}; i++)); do
        if [[ "${_DL_KEYS[$i]}" == "$k" ]]; then
            echo "${_DL_VALS[$i]}"
            return
        fi
    done
    return 1
}

_DL_RET=""
dl_get_v() {
    local k="$1" i
    if _dl_is_ascii "$k"; then
        eval "i=\${_DLV_${k}_SET:-}"
        if [[ -n "$i" ]]; then
            eval "_DL_RET=\${_DLV_${k}}"
            return 0
        fi
        _DL_RET=""
        return 1
    fi
    for ((i=0; i<${#_DL_KEYS[@]}; i++)); do
        if [[ "${_DL_KEYS[$i]}" == "$k" ]]; then
            _DL_RET="${_DL_VALS[$i]}"
            return
        fi
    done
    _DL_RET=""
    return 1
}

dl_load_file() {
    local file="$1"
    [[ -f "$file" ]] || { echo "ERROR: data file not found: $file" >&2; return 1; }

    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// /}" ]] && continue

        local key="${line%%=*}"
        local val="${line#*=}"

        if [[ "$key" != "${key//[^a-zA-Z0-9_]/}" ]]; then
            _DL_KEYS+=("$key")
            _DL_VALS+=("$val")
            continue
        fi

        if [[ "$val" == *,* ]]; then
            IFS=',' read -ra "_arr" <<< "$val"
            eval "${key}=(\"\${_arr[@]}\")"
        else
            eval "${key}=\"\${val}\""
        fi
    done < "$file"
}

dl_load_all() {
    local data_dir="$1"
    [[ -d "$data_dir" ]] || { echo "ERROR: data directory not found: $data_dir" >&2; return 1; }

    local f
    for f in "$data_dir"/*.dat; do
        [[ -f "$f" ]] && dl_load_file "$f"
    done

    JIAZI=()
    local i
    for ((i=0; i<60; i++)); do
        JIAZI+=("${TIAN_GAN[$((i % 10))]}${DI_ZHI[$((i % 12))]}")
    done
}
