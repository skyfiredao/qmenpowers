#!/usr/bin/env bash
# Copyright (C) 2025 — Licensed under GPL-3.0
# See https://www.gnu.org/licenses/gpl-3.0.html
set -euo pipefail

_resolve_link() {
  local f="$1"
  while [[ -L "$f" ]]; do
    local dir="$(cd "$(dirname "$f")" && pwd)"
    f="$(readlink "$f")"
    [[ "$f" != /* ]] && f="$dir/$f"
  done
  echo "$f"
}

SCRIPT_DIR="$(cd "$(dirname "$(_resolve_link "${BASH_SOURCE[0]}")")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

BIRTH_JSON_PATH="./qmen_birth.json"
_SHOW_WANWU=""

show_help() {
  cat <<'HELP'
用法: qimen_xingge.sh [选项]

出生局性格分析 — 内在 外在性格取象

选项:
  --wanwu                 文本输出中显示万物类象
  -h, --help              显示帮助

依赖: ./qmen_birth.json（由 qimen_qiju.sh --type=birth "YYYY-MM-DD HH:MM" 生成）
HELP
}

while (( $# > 0 )); do
  case "$1" in
    --wanwu)              _SHOW_WANWU="true"; shift ;;
    -h|--help)            show_help; exit 0 ;;
    *)                    echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ ! -f "$BIRTH_JSON_PATH" ]]; then
  echo "Error: birth plate not found: $BIRTH_JSON_PATH" >&2
  echo "Generate it first: qimen_qiju.sh --type=birth \"YYYY-MM-DD HH:MM\"" >&2
  exit 1
fi

source "$BASE_DIR/lib/data_loader.sh"

# 先加载输入盘面 JSON（供默认键读取），再加载性格类象数据文件。
dl_load_file "$BIRTH_JSON_PATH"
dl_load_file "$BASE_DIR/data/wanwu_huaqizhen.dat"

source "$BASE_DIR/lib/qimen_xingge.sh"

HUAQIZHEN_PATH="./qmen_huaqizhen.json"
if [[ ! -f "$HUAQIZHEN_PATH" ]]; then
  "$BASE_DIR/bin/qimen_huaqizhen.sh" >/dev/null 2>&1 || true
fi

xg_run_analysis "$BIRTH_JSON_PATH" "./qmen_xingge.json" "$HUAQIZHEN_PATH"
echo "性格分析已写入: ./qmen_xingge.json" >&2
