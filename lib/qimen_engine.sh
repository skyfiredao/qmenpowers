#!/usr/bin/env bash
# Copyright (C) 2025 — Licensed under GPL-3.0
# See https://www.gnu.org/licenses/gpl-3.0.html
# qimen_engine.sh — unified Qi Men Dun Jia engine (calendar + solar terms + plate computation)

###############################################################################
# Part A — Calendar functions (transplanted from calendar.sh)
###############################################################################

# Algorithm reference constants
_CAL_REF_JDN=2415051  # 1900-01-31
_CAL_REF_GZ=40        # 甲辰 index

_cal_mod() {
    local n="$1" m="$2"
    local r=$((n % m))
    if (( r < 0 )); then
        r=$((r + m))
    fi
    echo "$r"
}

# cal_gregorian_to_jdn year month day -> JDN
cal_gregorian_to_jdn() {
    local year="$1" month="$2" day="$3"
    local a=$(((14 - month) / 12))
    local y=$((year + 4800 - a))
    local m=$((month + 12 * a - 3))

    local jdn=$((day + (153 * m + 2) / 5 + 365 * y + y / 4 - y / 100 + y / 400 - 32045))
    echo "$jdn"
}

# cal_jdn_to_gregorian jdn -> "YYYY MM DD"
cal_jdn_to_gregorian() {
    local jdn="$1"
    local a=$((jdn + 32044))
    local b=$(((4 * a + 3) / 146097))
    local c=$((a - (146097 * b) / 4))
    local d=$(((4 * c + 3) / 1461))
    local e=$((c - (1461 * d) / 4))
    local m=$(((5 * e + 2) / 153))

    local day=$((e - (153 * m + 2) / 5 + 1))
    local month=$((m + 3 - 12 * (m / 10)))
    local year=$((100 * b + d - 4800 + (m / 10)))

    printf "%04d %02d %02d\n" "$year" "$month" "$day"
}

# cal_day_ganzhi_index year month day -> 0..59
cal_day_ganzhi_index() {
    local year="$1" month="$2" day="$3"
    local jdn
    jdn=$(cal_gregorian_to_jdn "$year" "$month" "$day")
    local delta=$((jdn - _CAL_REF_JDN))
    local idx=$((_CAL_REF_GZ + delta))
    _cal_mod "$idx" 60
}

# cal_year_ganzhi_index year -> 0..59
cal_year_ganzhi_index() {
    local year="$1"
    _cal_mod $((year - 4)) 60
}

# cal_month_ganzhi_index year_stem month_num -> 0..59
# year_stem: 0..9, month_num: 1..12 (1=寅月 ... 12=丑月)
cal_month_ganzhi_index() {
    local year_stem="$1" month_num="$2"

    # 年干定寅月干：甲己2, 乙庚4, 丙辛6, 丁壬8, 戊癸0
    local yin_stem=$((((year_stem % 5) * 2 + 2) % 10))
    local stem=$(((yin_stem + month_num - 1) % 10))
    local branch=$(((month_num + 1) % 12))

    local i
    for ((i=0; i<60; i++)); do
        if (( i % 10 == stem && i % 12 == branch )); then
            echo "$i"
            return 0
        fi
    done

    echo "ERROR: unable to resolve month GanZhi index for stem=$stem branch=$branch" >&2
    return 1
}

# cal_hour_ganzhi_index day_gz_index hour_24 -> 0..59
# 子时: 23:00-00:59 => branch 0
cal_hour_ganzhi_index() {
    local day_gz_index="$1" hour_24="$2"
    local day_stem=$((day_gz_index % 10))
    local zi_base=$(((day_stem % 5) * 12))
    local hour_branch=$((((hour_24 + 1) / 2) % 12))
    echo $(((zi_base + hour_branch) % 60))
}

# cal_ganzhi_name index -> name (e.g. 甲子)
cal_ganzhi_name() {
    local idx
    idx=$(_cal_mod "$1" 60)

    if (( ${#JIAZI[@]} >= 60 )); then
        echo "${JIAZI[$idx]}"
        return 0
    fi

    # Fallback if JIAZI table is not loaded
    echo "${TIAN_GAN[$((idx % 10))]}${DI_ZHI[$((idx % 12))]}"
}

# cal_xun_shou gz_index -> 旬首 index (0,10,20,30,40,50)
cal_xun_shou() {
    local idx
    idx=$(_cal_mod "$1" 60)
    echo $(((idx / 10) * 10))
}

# cal_xun_shou_liuyi gz_index -> 六仪 index (0..5)
cal_xun_shou_liuyi() {
    local idx
    idx=$(_cal_mod "$1" 60)
    echo $((idx / 10))
}

###############################################################################
# Part B — Solar term query functions
###############################################################################

_st_floor_div() {
    local a="$1" b="$2"
    local q=$((a / b))
    local r=$((a % b))
    if (( r != 0 && ((r < 0) != (b < 0)) )); then
        q=$((q - 1))
    fi
    echo "$q"
}

_st_term_timestamp() {
    local year="$1" term_index="$2"
    local key
    key=$(printf 'JQ_%s_%02d' "$year" "$term_index")
    local val
    eval "val=\${$key:-}"
    [[ -n "$val" ]] || return 1
    echo "$val"
}

# st_datetime_to_timestamp year month day hour min -> unix timestamp
st_datetime_to_timestamp() {
    local year="$1" month="$2" day="$3" hour="$4" min="$5"
    local jdn
    jdn=$(cal_gregorian_to_jdn "$year" "$month" "$day")
    echo $(( (jdn - 2440588) * 86400 + hour * 3600 + min * 60 ))
}

# st_jieqi_timestamp year term_index -> unix timestamp
st_jieqi_timestamp() {
    local year="$1" term_index="$2"
    local key val
    key=$(printf 'JQ_%s_%02d' "$year" "$term_index")
    eval "val=\${$key:-}"
    if [[ -z "$val" ]]; then
        echo "ERROR: no jieqi data for year=$year term=$term_index (key=$key)" >&2
        exit 1
    fi
    echo "$val"
}

# st_is_jie term_index -> 1 if 节, otherwise 0
st_is_jie() {
    local term_index="$1"
    if (( term_index % 2 == 0 )); then
        echo 1
    else
        echo 0
    fi
}

_st_current_term_with_year() {
    local year="$1" month="$2" day="$3" hour="$4" min="$5"
    local ts
    ts=$(st_datetime_to_timestamp "$year" "$month" "$day" "$hour" "$min")

    local t0
    t0=$(_st_term_timestamp "$year" 0) || return 1

    local i ti tnext
    if (( ts < t0 )); then
        local py=$((year - 1))
        for ((i=23; i>=0; i--)); do
            ti=$(_st_term_timestamp "$py" "$i") || continue
            if (( ts >= ti )); then
                echo "$py $i"
                return 0
            fi
        done
        echo "$py 23"
        return 0
    fi

    for ((i=0; i<23; i++)); do
        ti=$(_st_term_timestamp "$year" "$i") || continue
        tnext=$(_st_term_timestamp "$year" $((i + 1))) || continue
        if (( ts >= ti && ts < tnext )); then
            echo "$year $i"
            return 0
        fi
    done

    echo "$year 23"
}

# st_current_jieqi year month day hour min -> term_index (0-23)
st_current_jieqi() {
    local year term_index
    read -r year term_index <<< "$(_st_current_term_with_year "$1" "$2" "$3" "$4" "$5")"
    echo "$term_index"
}

# st_current_jie year month day hour min -> jie_term_index
st_current_jie() {
    local tyear tidx
    read -r tyear tidx <<< "$(_st_current_term_with_year "$1" "$2" "$3" "$4" "$5")"

    if (( tidx % 2 == 0 )); then
        echo "$tidx"
    elif (( tidx == 23 )); then
        echo 22
    else
        echo $((tidx - 1))
    fi
}

# st_prev_jie year month day hour min -> "year term_index"
st_prev_jie() {
    local year="$1" month="$2" day="$3" hour="$4" min="$5"
    local ts
    ts=$(st_datetime_to_timestamp "$year" "$month" "$day" "$hour" "$min")

    local i ti
    for ((i=22; i>=0; i-=2)); do
        ti=$(_st_term_timestamp "$year" "$i") || continue
        if (( ts >= ti )); then
            echo "$year $i"
            return 0
        fi
    done

    local py=$((year - 1))
    for ((i=22; i>=0; i-=2)); do
        ti=$(_st_term_timestamp "$py" "$i") || continue
        if (( ts >= ti )); then
            echo "$py $i"
            return 0
        fi
    done

    echo "$py 22"
}

# st_next_jie year month day hour min -> "year term_index"
st_next_jie() {
    local year="$1" month="$2" day="$3" hour="$4" min="$5"
    local ts
    ts=$(st_datetime_to_timestamp "$year" "$month" "$day" "$hour" "$min")

    local i ti
    for ((i=0; i<=22; i+=2)); do
        ti=$(_st_term_timestamp "$year" "$i") || continue
        if (( ts < ti )); then
            echo "$year $i"
            return 0
        fi
    done

    local ny=$((year + 1))
    for ((i=0; i<=22; i+=2)); do
        ti=$(_st_term_timestamp "$ny" "$i") || continue
        if (( ts < ti )); then
            echo "$ny $i"
            return 0
        fi
    done

    echo "$ny 0"
}

###############################################################################
# Part C — Plate computation functions
###############################################################################

QM_YEAR_GZ=0
QM_MONTH_GZ=0
QM_DAY_GZ=0
QM_HOUR_GZ=0

QM_JU_TYPE=""
QM_JU_NUM=0
QM_YUAN=""
QM_IS_RUN=0

QM_ZHIFU_ORIG_PALACE=0
QM_ZHIFU_TARGET_PALACE=0
QM_ZHIFU_STAR=""
QM_ZHIFU_STAR_INDEX=-1
QM_ZHISHI_GATE=""
QM_ZHISHI_GATE_INDEX=-1

QM_KONGWANG_1=-1
QM_KONGWANG_2=-1
QM_YIMA=-1

QM_TIANQIN_FOLLOW_PALACE=0

QM_EARTH=()
QM_EARTH_STEM_INDEX=()
QM_HEAVEN=()
QM_HEAVEN_STEM=()
QM_HUMAN=()
QM_DEITY=()
QM_STATES=()
QM_JIXING=()

_QM_FULL_LUOSHU_9=()
_QM_YIMA_MAP=()

_qm_reset_arrays() {
    local p
    QM_EARTH=()
    QM_EARTH_STEM_INDEX=()
    QM_HEAVEN=()
    QM_HEAVEN_STEM=()
    QM_HUMAN=()
    QM_DEITY=()
    QM_STATES=()
    QM_JIXING=()
    QM_GENG=()
    QM_RUMU_GAN=()
    QM_RUMU_STAR=()
    QM_RUMU_GATE=()
    QM_MENPO=()
    QM_STAR_FANYIN=()
    QM_GATE_FANYIN=()
    QM_STAR_FUYIN=()
    QM_GATE_FUYIN=()
    QM_GAN_FANYIN=()
    QM_GAN_FUYIN=()

    for ((p=1; p<=9; p++)); do
        QM_EARTH[$p]=""
        QM_EARTH_STEM_INDEX[$p]=-1
        QM_HEAVEN[$p]=-1
        QM_HEAVEN_STEM[$p]=""
        QM_HUMAN[$p]=-1
        QM_DEITY[$p]=-1
        QM_STATES[$p]=""
        QM_JIXING[$p]=0
        QM_GENG[$p]=0
        QM_RUMU_GAN[$p]=0
        QM_RUMU_STAR[$p]=0
        QM_RUMU_GATE[$p]=0
        QM_MENPO[$p]=0
        QM_STAR_FANYIN[$p]=0
        QM_GATE_FANYIN[$p]=0
        QM_STAR_FUYIN[$p]=0
        QM_GATE_FUYIN[$p]=0
        QM_GAN_FANYIN[$p]=0
        QM_GAN_FUYIN[$p]=0
    done

    QM_TIANQIN_FOLLOW_PALACE=0
}

_qm_palace_pos_luoshu8() {
    local palace="$1"
    local i
    for ((i=0; i<${#LUOSHU_ORDER[@]}; i++)); do
        if (( LUOSHU_ORDER[i] == palace )); then
            echo "$i"
            return 0
        fi
    done
    return 1
}

_qm_palace_pos_luoshu9() {
    local palace="$1"
    local i
    for ((i=0; i<${#_QM_FULL_LUOSHU_9[@]}; i++)); do
        if (( _QM_FULL_LUOSHU_9[i] == palace )); then
            echo "$i"
            return 0
        fi
    done
    return 1
}

_qm_branch_index_by_char() {
    local ch="$1"
    local i
    for ((i=0; i<${#DI_ZHI[@]}; i++)); do
        if [[ "${DI_ZHI[i]}" == "$ch" ]]; then
            echo "$i"
            return 0
        fi
    done
    return 1
}

_qm_stem_index_by_char() {
    local ch="$1"
    local i
    for ((i=0; i<${#TIAN_GAN[@]}; i++)); do
        if [[ "${TIAN_GAN[i]}" == "$ch" ]]; then
            echo "$i"
            return 0
        fi
    done
    return 1
}

_qm_init_yima_map() {
    if (( ${#_QM_YIMA_MAP[@]} == 12 )); then
        return 0
    fi

    local i
    _QM_YIMA_MAP=()
    for ((i=0; i<12; i++)); do
        _QM_YIMA_MAP[i]=-1
    done

    local i key group yima_char b1 b2 b3 yima_idx bidx
    for ((i=0; i<${#_DL_KEYS[@]}; i++)); do
        key="${_DL_KEYS[$i]}"
        [[ "$key" == YIMA_* ]] || continue
        group="${key#YIMA_}"
        [[ ${#group} -ge 3 ]] || continue

        yima_char=$(dl_get "$key") || continue
        yima_idx=$(_qm_branch_index_by_char "$yima_char") || continue

        b1=${group:0:1}
        b2=${group:1:1}
        b3=${group:2:1}

        bidx=$(_qm_branch_index_by_char "$b1") && _QM_YIMA_MAP[$bidx]="$yima_idx"
        bidx=$(_qm_branch_index_by_char "$b2") && _QM_YIMA_MAP[$bidx]="$yima_idx"
        bidx=$(_qm_branch_index_by_char "$b3") && _QM_YIMA_MAP[$bidx]="$yima_idx"
    done
}

_qm_build_luoshu9() {
    if (( ${#_QM_FULL_LUOSHU_9[@]} == 9 )); then
        return 0
    fi

    _QM_FULL_LUOSHU_9=()
    local i p
    for ((i=0; i<${#LUOSHU_ORDER[@]}; i++)); do
        p=${LUOSHU_ORDER[$i]}
        _QM_FULL_LUOSHU_9+=("$p")
        if (( p == 4 )); then
            _QM_FULL_LUOSHU_9+=(5)
        fi
    done
}

# _qm_find_upper_yuan_futou_offset gz_index
# Search backwards from a day干支 to find the nearest 上元符头
# 上元符头: 甲子(0), 己卯(15), 甲午(30), 己酉(45)
# Returns: number of days backwards (0-14)
_qm_find_upper_yuan_futou_offset() {
    local gz="$1"
    local offset gz_check
    for ((offset=0; offset<15; offset++)); do
        gz_check=$(( (gz - offset + 600) % 60 ))
        if (( gz_check == 0 || gz_check == 15 || gz_check == 30 || gz_check == 45 )); then
            echo "$offset"
            return 0
        fi
    done
    # Should never reach here (period is 15, always found)
    echo "0"
}

# _qm_next_term_after year term_index -> "year term_index"
# Returns the next 节气 (all 24) after the given one
_qm_next_term_after() {
    local y="$1" idx="$2"
    if (( idx >= 23 )); then
        echo "$((y + 1)) 0"
    else
        echo "$y $((idx + 1))"
    fi
}

# _qm_is_yang_dun term_index -> 0(yang) or 1(yin)
# 冬至(23) through 芒种(10) = 阳遁, indices: 23,0,1,2,3,4,5,6,7,8,9,10
# 夏至(11) through 大雪(22) = 阴遁, indices: 11,12,13,14,15,16,17,18,19,20,21,22
_qm_is_yang_dun() {
    local idx="$1"
    if (( idx >= 11 && idx <= 22 )); then
        return 1  # yin
    fi
    return 0  # yang
}

# _qm_jieqi_jdn year term_index -> JDN of the 节气交节日
# Uses Beijing time (UTC+8) for calendar date determination
_qm_jieqi_jdn() {
    local y="$1" idx="$2"
    local ts
    ts=$(st_jieqi_timestamp "$y" "$idx")
    if [[ -z "$ts" ]]; then
        return 1
    fi
    # Convert to Beijing time: add 8 hours (28800 seconds) before floor-dividing by 86400
    echo $(( ( (ts + 28800) / 86400 ) + 2440588 ))
}

# _qm_jdn_to_gz jdn -> gz_index (0-59)
_qm_jdn_to_gz() {
    local jdn="$1"
    _cal_mod $((jdn - _CAL_REF_JDN + _CAL_REF_GZ)) 60
}

# qm_determine_ju year month day hour min
# Implements 置闰法定局 (Zhi Run / Intercalation method) ONLY.
# Yuan (上中下元) is determined by futou offset, NOT by 旬首地支 lookup (拆补法).
# Algorithm based on bigfishmarquis-qimen/zhirun.ts
qm_determine_ju() {
    local year="$1" month="$2" day="$3" hour="$4" min="$5"

    # Step 0: Get current 节气 (all 24) and its timestamp
    local term_year term_index
    read -r term_year term_index <<< "$(_st_current_term_with_year "$year" "$month" "$day" "$hour" "$min")"

    # Step 1: Get 节气交节日 JDN and day干支
    local jdn_jieqi gz_jieqi
    jdn_jieqi=$(_qm_jieqi_jdn "$term_year" "$term_index") || {
        echo "ERROR: cannot get JDN for jieqi year=$term_year index=$term_index" >&2
        return 1
    }
    gz_jieqi=$(_qm_jdn_to_gz "$jdn_jieqi")

    # Step 2: Find 上元符头 offset (days before 节气)
    local chaoshen_days
    chaoshen_days=$(_qm_find_upper_yuan_futou_offset "$gz_jieqi")

    # Step 3: Calculate days from 符头 to today
    local jdn_now days_since_jieqi days_since_futou
    jdn_now=$(cal_gregorian_to_jdn "$year" "$month" "$day")
    days_since_jieqi=$((jdn_now - jdn_jieqi))
    days_since_futou=$((days_since_jieqi + chaoshen_days))

    # Step 4: 置闰 check — only at 芒种(10) or 大雪(22)
    local total_cycle_days=15
    QM_IS_RUN=0
    if (( chaoshen_days > 9 )); then
        if (( term_index == 10 || term_index == 22 )); then
            total_cycle_days=30  # 六元 (two full 三元 cycles)
            QM_IS_RUN=1
        fi
    fi

    # Step 5: Handle overflow to next 节气
    local effective_term_year="$term_year"
    local effective_term_index="$term_index"
    local effective_days="$days_since_futou"

    if (( days_since_futou >= total_cycle_days )); then
        # Check if the next 节气 has actually started before jumping
        local next_ty next_ti
        read -r next_ty next_ti <<< "$(_qm_next_term_after "$term_year" "$term_index")"
        local jdn_next_jieqi
        jdn_next_jieqi=$(_qm_jieqi_jdn "$next_ty" "$next_ti") 2>/dev/null
        if [[ -n "$jdn_next_jieqi" ]] && (( jdn_now >= jdn_next_jieqi )); then
            # Next 节气 has started -> use it
            effective_term_year="$next_ty"
            effective_term_index="$next_ti"
            effective_days=$((days_since_futou - total_cycle_days))
        fi
        # Otherwise: next 节气 hasn't arrived yet, stay with current term
        # and keep effective_days = days_since_futou (will wrap via % 15 in yuan calc)
    fi

    # Also handle: if previous 节气 had 置闰 that extends into current period
    # This is the "isPrevTermZhiRun" case from bigfishmarquis
    # Check if we need to look at the previous term's 置闰 state
    if (( days_since_futou < total_cycle_days )); then
        # Check if previous term was 芒种/大雪 with 超神>9
        local prev_term_year prev_term_index
        if (( term_index == 0 )); then
            prev_term_year=$((term_year - 1))
            prev_term_index=23
        else
            prev_term_year="$term_year"
            prev_term_index=$((term_index - 1))
        fi

        if (( prev_term_index == 10 || prev_term_index == 22 )); then
            # Previous term was 芒种/大雪. Check its 超神 days
            local jdn_prev_jieqi gz_prev_jieqi prev_chaoshen
            jdn_prev_jieqi=$(_qm_jieqi_jdn "$prev_term_year" "$prev_term_index") 2>/dev/null
            if [[ -n "$jdn_prev_jieqi" ]]; then
                gz_prev_jieqi=$(_qm_jdn_to_gz "$jdn_prev_jieqi")
                prev_chaoshen=$(_qm_find_upper_yuan_futou_offset "$gz_prev_jieqi")
                if (( prev_chaoshen > 9 )); then
                    # Previous 芒种/大雪 had 置闰, its 30-day cycle may still be active
                    local prev_futou_jdn=$((jdn_prev_jieqi - prev_chaoshen))
                    local days_from_prev_futou=$((jdn_now - prev_futou_jdn))
                    if (( days_from_prev_futou < 30 )); then
                        # Still within previous term's 置闰 extended cycle
                        effective_term_year="$prev_term_year"
                        effective_term_index="$prev_term_index"
                        effective_days="$days_from_prev_futou"
                        total_cycle_days=30
                        QM_IS_RUN=1
                    fi
                fi
            fi
        fi
    fi

    # Step 6: Determine 上元/中元/下元
    local yuan_day yuan_index
    yuan_day=$((effective_days % 15))
    if (( yuan_day < 5 )); then
        yuan_index=0
        QM_YUAN="上元"
    elif (( yuan_day < 10 )); then
        yuan_index=1
        QM_YUAN="中元"
    else
        yuan_index=2
        QM_YUAN="下元"
    fi

    # Step 7: Determine 阳遁/阴遁 and look up 局数
    local ju_key ju_val
    if _qm_is_yang_dun "$effective_term_index"; then
        QM_JU_TYPE="阳遁"
        ju_key=$(printf 'YANG_%d_%d' "$effective_term_index" "$yuan_index")
    else
        QM_JU_TYPE="阴遁"
        ju_key=$(printf 'YIN_%d_%d' "$effective_term_index" "$yuan_index")
    fi

    eval "ju_val=\${$ju_key:-}"
    if [[ -z "$ju_val" ]]; then
        echo "ERROR: missing ju map value: $ju_key (effective term=$effective_term_index yuan=$yuan_index)" >&2
        return 1
    fi

    QM_JU_NUM="$ju_val"

    # Debug info (to stderr when QM_DEBUG is set)
    if [[ -n "${QM_DEBUG:-}" ]]; then
        echo "DEBUG determine_ju: current_term=${term_year}/${term_index} jdn_jieqi=${jdn_jieqi} gz_jieqi=${gz_jieqi}" >&2
        echo "DEBUG determine_ju: chaoshen=${chaoshen_days} days_since_futou=${days_since_futou} total_cycle=${total_cycle_days}" >&2
        echo "DEBUG determine_ju: effective_term=${effective_term_year}/${effective_term_index} effective_days=${effective_days}" >&2
        echo "DEBUG determine_ju: yuan_day=${yuan_day} yuan=${QM_YUAN} type=${QM_JU_TYPE} ju=${QM_JU_NUM} is_run=${QM_IS_RUN}" >&2
    fi
}

# qm_lay_earth_plate — palace number increment (阳遁) / decrement (阴遁)
qm_lay_earth_plate() {
    local palace="$QM_JU_NUM"
    local step=1
    [[ "$QM_JU_TYPE" != "阳遁" ]] && step=-1

    local k
    for ((k=0; k<9; k++)); do
        QM_EARTH[$palace]="${SANQI_ORDER[$k]}"
        QM_EARTH_STEM_INDEX[$palace]=$k
        palace=$((palace + step))
        if (( palace > 9 )); then palace=1; fi
        if (( palace < 1 )); then palace=9; fi
    done
}

# qm_find_zhifu_zhishi hour_gz_index
qm_find_zhifu_zhishi() {
    local hour_gz="$1"

    local xun_shou liuyi_index liuyi_stem p
    xun_shou=$(cal_xun_shou "$hour_gz")
    liuyi_index=$(cal_xun_shou_liuyi "$hour_gz")
    liuyi_stem="${XUNSHOU_LIUYI[$liuyi_index]}"

    QM_ZHIFU_ORIG_PALACE=0
    for ((p=1; p<=9; p++)); do
        if [[ "${QM_EARTH[$p]}" == "$liuyi_stem" ]]; then
            QM_ZHIFU_ORIG_PALACE=$p
            break
        fi
    done

    if (( QM_ZHIFU_ORIG_PALACE == 0 )); then
        echo "ERROR: failed to locate xunshou liuyi on earth plate: $liuyi_stem" >&2
        return 1
    fi

    QM_ZHIFU_STAR_INDEX=$((QM_ZHIFU_ORIG_PALACE - 1))
    QM_ZHIFU_STAR="${STAR_NAMES[$QM_ZHIFU_STAR_INDEX]}"

    # When zhifu lands on palace 5 (天禽), use palace 2 (坤) for gate lookup
    # because palace 5 has no gate
    local gate_palace="$QM_ZHIFU_ORIG_PALACE"
    if (( gate_palace == 5 )); then gate_palace=2; fi
    QM_ZHISHI_GATE_INDEX=$((gate_palace - 1))
    QM_ZHISHI_GATE="${GATE_NAMES[$QM_ZHISHI_GATE_INDEX]}"

    : "$xun_shou"
}

# qm_rotate_heaven hour_gz_index
qm_rotate_heaven() {
    local hour_gz="$1"

    local hour_stem_char
    hour_stem_char="${TIAN_GAN[$((hour_gz % 10))]}"
    if [[ "$hour_stem_char" == "甲" ]]; then
        hour_stem_char="${XUNSHOU_LIUYI[$((hour_gz / 10))]}"
    fi

    local target_palace=0 p
    for ((p=1; p<=9; p++)); do
        if [[ "${QM_EARTH[$p]}" == "$hour_stem_char" ]]; then
            target_palace=$p
            break
        fi
    done

    if (( target_palace == 0 )); then
        echo "ERROR: failed to locate hour stem on earth plate: $hour_stem_char" >&2
        return 1
    fi
    QM_ZHIFU_TARGET_PALACE=$target_palace

    local orig_for_rot="$QM_ZHIFU_ORIG_PALACE"
    local target_for_rot="$target_palace"
    if (( orig_for_rot == 5 )); then
        orig_for_rot=2
    fi
    if (( target_for_rot == 5 )); then
        target_for_rot=2
    fi

    local orig_pos target_pos offset
    orig_pos=$(_qm_palace_pos_luoshu8 "$orig_for_rot") || return 1
    target_pos=$(_qm_palace_pos_luoshu8 "$target_for_rot") || return 1
    offset=$((target_pos - orig_pos))

    local s default_palace dp_pos new_pos new_palace
    for ((s=0; s<=8; s++)); do
        if (( s == 4 )); then
            continue
        fi

        default_palace=$((s + 1))
        dp_pos=$(_qm_palace_pos_luoshu8 "$default_palace") || continue
        new_pos=$(((dp_pos + offset + 8) % 8))
        new_palace=${LUOSHU_ORDER[$new_pos]}

        QM_HEAVEN[$new_palace]=$s
        QM_HEAVEN_STEM[$new_palace]="${QM_EARTH[$default_palace]}"
    done

    local tianqin_palace=0
    local mode="${QM_TIANQIN_MODE:-jikun}"

    if (( QM_ZHIFU_STAR_INDEX == 4 )); then
        QM_HEAVEN[$target_for_rot]=4
        QM_HEAVEN_STEM[$target_for_rot]="${QM_EARTH[5]}"
        tianqin_palace=$target_for_rot
    else
        case "$mode" in
            jikun)
                tianqin_palace=2
                ;;
            follow-zhifu)
                tianqin_palace=$target_for_rot
                ;;
            *)
                local _tp
                for ((_tp=1; _tp<=9; _tp++)); do
                    if (( _tp != 5 && QM_HEAVEN[_tp] == 1 )); then
                        tianqin_palace=$_tp
                        break
                    fi
                done
                if (( tianqin_palace == 0 )); then tianqin_palace=2; fi
                ;;
        esac
    fi
    QM_TIANQIN_FOLLOW_PALACE=$tianqin_palace
}

# qm_rotate_human — gate rotation by earthly-branch step counting
qm_rotate_human() {
    local hour_gz="$QM_HOUR_GZ"
    local xun_shou
    xun_shou=$(cal_xun_shou "$hour_gz")

    local branch_steps=$(( (hour_gz % 12) - (xun_shou % 12) ))
    if (( branch_steps < 0 )); then
        branch_steps=$((branch_steps + 12))
    fi

    local gate_palace="$QM_ZHIFU_ORIG_PALACE"
    if (( gate_palace == 5 )); then gate_palace=2; fi

    local step_dir=1
    [[ "$QM_JU_TYPE" != "阳遁" ]] && step_dir=-1

    local s
    for ((s=0; s<branch_steps; s++)); do
        gate_palace=$((gate_palace + step_dir))
        if (( gate_palace > 9 )); then gate_palace=1; fi
        if (( gate_palace < 1 )); then gate_palace=9; fi
        if (( gate_palace == 5 )); then gate_palace=$((gate_palace + step_dir)); fi
        if (( gate_palace > 9 )); then gate_palace=1; fi
        if (( gate_palace < 1 )); then gate_palace=9; fi
    done

    QM_ZHISHI_TARGET_PALACE=$gate_palace

    local orig_ring_pos gate_ring_pos ring_offset
    local orig_for_gate="$QM_ZHIFU_ORIG_PALACE"
    if (( orig_for_gate == 5 )); then orig_for_gate=2; fi
    orig_ring_pos=$(_qm_palace_pos_luoshu8 "$orig_for_gate") || return 1
    gate_ring_pos=$(_qm_palace_pos_luoshu8 "$gate_palace") || {
        echo "ERROR: invalid gate target palace: $gate_palace" >&2
        return 1
    }
    ring_offset=$((gate_ring_pos - orig_ring_pos))

    local g dp gp np
    for ((g=0; g<8; g++)); do
        dp=${LUOSHU_ORDER[$g]}
        gp=$(((g + ring_offset + 8) % 8))
        np=${LUOSHU_ORDER[$gp]}
        QM_HUMAN[$np]=$((dp - 1))
    done
}

# qm_lay_deities
qm_lay_deities() {
    local start_palace="$QM_ZHIFU_TARGET_PALACE"
    if (( start_palace == 5 )); then
        start_palace=2
    fi

    local start_pos
    start_pos=$(_qm_palace_pos_luoshu8 "$start_palace") || {
        echo "ERROR: invalid deity start palace: $start_palace" >&2
        return 1
    }

    local i pos palace
    QM_DEITY[$start_palace]=0

    for ((i=1; i<=7; i++)); do
        pos=$(((start_pos + i) % 8))
        palace=${LUOSHU_ORDER[$pos]}
        QM_DEITY[$palace]=$i
    done
}

# qm_calc_kongwang hour_gz_index
qm_calc_kongwang() {
    local hour_gz_index="$1"
    local xun=$((hour_gz_index - (hour_gz_index % 10)))
    local xun_branch=$((xun % 12))
    QM_KONGWANG_1=$(((xun_branch + 10) % 12))
    QM_KONGWANG_2=$(((xun_branch + 11) % 12))
}

# qm_calc_yima hour_gz_index
qm_calc_yima() {
    local hour_gz_index="$1"
    local hour_branch=$((hour_gz_index % 12))

    _qm_init_yima_map
    QM_YIMA=${_QM_YIMA_MAP[$hour_branch]}
    if [[ -z "$QM_YIMA" || "$QM_YIMA" == "-1" ]]; then
        echo "ERROR: failed to determine 驿马 for hour branch index=$hour_branch" >&2
        return 1
    fi
}

# qm_calc_twelve_states
qm_calc_twelve_states() {
    local p
    for ((p=1; p<=9; p++)); do
        if (( p == 5 )); then
            QM_STATES[$p]=""
            continue
        fi

        local tian_stem
        tian_stem="${QM_HEAVEN_STEM[$p]}"
        if [[ -z "$tian_stem" ]]; then
            QM_STATES[$p]=""
            continue
        fi

        local start_data
        start_data=$(dl_get "START_${tian_stem}") || {
            QM_STATES[$p]=""
            continue
        }

        local start_branch direction
        IFS=',' read -r start_branch direction <<< "$start_data"

        local palace_dizhi primary_branch palace_branch_index
        palace_dizhi="${PALACE_DIZHI[$((p - 1))]}"
        primary_branch="${palace_dizhi:0:1}"
        palace_branch_index=$(_qm_branch_index_by_char "$primary_branch") || {
            QM_STATES[$p]=""
            continue
        }

        local dist
        if (( direction == 1 )); then
            dist=$(((palace_branch_index - start_branch + 12) % 12))
        else
            dist=$(((start_branch - palace_branch_index + 12) % 12))
        fi
        QM_STATES[$p]="${STATE_NAMES[$dist]}"
    done
}

# qm_calc_liuyi_jixing — 六仪击刑
# 戊→震3(子刑卯) 己→坤2(戌刑未) 庚→艮8(申刑寅)
# 辛→离9(午自刑) 壬→巽4(辰自刑) 癸→巽4(寅刑巳)
qm_calc_liuyi_jixing() {
    local p stem
    for ((p=1; p<=9; p++)); do
        if (( p == 5 )); then continue; fi
        stem="${QM_HEAVEN_STEM[$p]}"
        QM_JIXING[$p]=0
        if { [[ "$stem" == "戊" ]] && (( p == 3 )); } ||
           { [[ "$stem" == "己" ]] && (( p == 2 )); } ||
           { [[ "$stem" == "庚" ]] && (( p == 8 )); } ||
           { [[ "$stem" == "辛" ]] && (( p == 9 )); } ||
           { [[ "$stem" == "壬" ]] && (( p == 4 )); } ||
           { [[ "$stem" == "癸" ]] && (( p == 4 )); }; then
            QM_JIXING[$p]=1
        fi
    done
}

# qm_calc_patterns — 格局标记 (庚/入墓/门迫/反吟/伏吟)
# Populates: QM_GENG, QM_RUMU_GAN, QM_RUMU_STAR, QM_RUMU_GATE,
#            QM_MENPO, QM_STAR_FANYIN, QM_GATE_FANYIN,
#            QM_STAR_FUYIN, QM_GATE_FUYIN

_qm_grave_palace() {
    # 五行→墓宫: 火→乾6, 水→巽4, 金→艮8, 木→坤2, 土→巽4
    case "$1" in
        火) echo 6 ;; 水) echo 4 ;; 金) echo 8 ;; 木) echo 2 ;; 土) echo 4 ;; *) echo 0 ;;
    esac
}

_qm_wx_ke_target() {
    # 五行克关系: key克→被克target
    case "$1" in
        金) echo 木 ;; 木) echo 土 ;; 土) echo 水 ;; 水) echo 火 ;; 火) echo 金 ;; *) echo "" ;;
    esac
}

_qm_opposite_palace() {
    case "$1" in
        1) echo 9 ;; 9) echo 1 ;; 2) echo 8 ;; 8) echo 2 ;;
        3) echo 7 ;; 7) echo 3 ;; 4) echo 6 ;; 6) echo 4 ;; *) echo 0 ;;
    esac
}

qm_calc_patterns() {
    local p
    for ((p=1; p<=9; p++)); do
        if (( p == 5 )); then continue; fi

        local star_idx=${QM_HEAVEN[$p]}
        local gate_idx=${QM_HUMAN[$p]}
        local tian_gan="${QM_HEAVEN_STEM[$p]}"

        if [[ "$tian_gan" == "庚" ]]; then
            QM_GENG[$p]=1
        fi

        local stem_wx grave_p
        stem_wx=$(_qm_stem_wuxing "$tian_gan")
        if [[ -n "$stem_wx" ]]; then
            grave_p=$(_qm_grave_palace "$stem_wx")
            if (( grave_p > 0 && grave_p == p )); then
                QM_RUMU_GAN[$p]=1
            fi
        fi

        if (( star_idx >= 0 && star_idx <= 8 )); then
            local star_wx="${STAR_WUXING[$star_idx]}"
            if [[ -n "$star_wx" ]]; then
                grave_p=$(_qm_grave_palace "$star_wx")
                if (( grave_p > 0 && grave_p == p )); then
                    QM_RUMU_STAR[$p]=1
                fi
            fi
        fi

        if (( gate_idx >= 0 && gate_idx <= 8 )); then
            local gate_wx="${GATE_WUXING[$gate_idx]}"
            if [[ -n "$gate_wx" ]]; then
                grave_p=$(_qm_grave_palace "$gate_wx")
                if (( grave_p > 0 && grave_p == p )); then
                    QM_RUMU_GATE[$p]=1
                fi
            fi
        fi

        if (( gate_idx >= 0 && gate_idx <= 8 )); then
            local g_wx="${GATE_WUXING[$gate_idx]}"
            local p_wx="${PALACE_WUXING[$((p - 1))]}"
            if [[ -n "$g_wx" ]] && [[ -n "$p_wx" ]]; then
                local ke_target
                ke_target=$(_qm_wx_ke_target "$g_wx")
                if [[ "$ke_target" == "$p_wx" ]]; then
                    QM_MENPO[$p]=1
                fi
            fi
        fi

        if (( star_idx >= 0 && star_idx <= 8 )); then
            local star_home=${STAR_DEFAULT_PALACE[$star_idx]}
            local opp
            opp=$(_qm_opposite_palace "$star_home")
            if (( opp > 0 && opp == p )); then
                QM_STAR_FANYIN[$p]=1
            fi
            if (( star_home == p )); then
                QM_STAR_FUYIN[$p]=1
            fi
        fi

        if (( gate_idx >= 0 && gate_idx <= 8 )); then
            local gate_home=${GATE_DEFAULT_PALACE[$gate_idx]}
            local opp_g
            opp_g=$(_qm_opposite_palace "$gate_home")
            if (( opp_g > 0 && opp_g == p )); then
                QM_GATE_FANYIN[$p]=1
            fi
            if (( gate_home == p )); then
                QM_GATE_FUYIN[$p]=1
            fi
        fi

        # --- 干反吟 / 干伏吟 ---
        local di_gan="${QM_EARTH[$p]}"
        if [[ -n "$tian_gan" && -n "$di_gan" ]]; then
            if [[ "$tian_gan" == "$di_gan" ]]; then
                QM_GAN_FUYIN[$p]=1
            fi
        fi
        local opp_gan
        opp_gan=$(_qm_opposite_palace "$p")
        if (( opp_gan > 0 )); then
            local opp_di_gan="${QM_EARTH[$opp_gan]}"
            if [[ -n "$tian_gan" && -n "$opp_di_gan" && "$tian_gan" == "$opp_di_gan" ]]; then
                QM_GAN_FANYIN[$p]=1
            fi
        fi
    done
}

_qm_month_num_from_jie() {
    local jie_index="$1"
    if (( jie_index == 0 )); then
        echo 12
    else
        echo $((jie_index / 2))
    fi
}

# qm_compute_plate year month day hour min
qm_compute_plate() {
    local year="$1" month="$2" day="$3" hour="$4" min="$5"

    _qm_reset_arrays

    local day_gz hour_gz
    day_gz=$(cal_day_ganzhi_index "$year" "$month" "$day")
    hour_gz=$(cal_hour_ganzhi_index "$day_gz" "$hour")

    local ts_now ts_lichun use_year
    ts_now=$(st_datetime_to_timestamp "$year" "$month" "$day" "$hour" "$min")
    ts_lichun=$(st_jieqi_timestamp "$year" 2)
    use_year="$year"
    if [[ -n "$ts_lichun" ]] && (( ts_now < ts_lichun )); then
        use_year=$((year - 1))
    fi

    local year_gz
    year_gz=$(cal_year_ganzhi_index "$use_year")

    local jie_year jie_index month_num
    read -r jie_year jie_index <<< "$(st_prev_jie "$year" "$month" "$day" "$hour" "$min")"
    month_num=$(_qm_month_num_from_jie "$jie_index")

    local month_gz
    month_gz=$(cal_month_ganzhi_index "$((year_gz % 10))" "$month_num")

    QM_YEAR_GZ="$year_gz"
    QM_MONTH_GZ="$month_gz"
    QM_DAY_GZ="$day_gz"
    QM_HOUR_GZ="$hour_gz"

    qm_determine_ju "$year" "$month" "$day" "$hour" "$min" || return 1
    qm_lay_earth_plate || return 1
    qm_find_zhifu_zhishi "$hour_gz" || return 1
    qm_rotate_heaven "$hour_gz" || return 1
    qm_rotate_human || return 1
    qm_lay_deities || return 1
    qm_calc_twelve_states || return 1
    qm_calc_liuyi_jixing || return 1
    qm_calc_kongwang "$hour_gz" || return 1
    qm_calc_yima "$hour_gz" || return 1
    qm_calc_patterns || return 1
}
