#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="${HOME}/.config/opencode/skills"

mkdir -p "$SKILLS_DIR"

# Install each qmen_* sub-skill as an independent symlink
count=0
for skill_dir in "$SCRIPT_DIR"/skills/qmen_*/; do
    [ -d "$skill_dir" ] || continue
    skill_name="$(basename "$skill_dir")"
    ln -sfn "$skill_dir" "$SKILLS_DIR/$skill_name"
    echo "Installed: $skill_name → $SKILLS_DIR/$skill_name"
    count=$((count + 1))
done

if [ "$count" -eq 0 ]; then
    echo "No qmen_* skills found in $SCRIPT_DIR/skills/"
    exit 1
fi

cli_count=0
for bin_file in "$SCRIPT_DIR"/tools/bin/qimen*.sh; do
    [ -f "$bin_file" ] || continue
    chmod +x "$bin_file"
    echo "CLI: $bin_file"
    cli_count=$((cli_count + 1))
done
echo ""
echo "Installed $count skill(s), $cli_count CLI script(s). Restart OpenCode to load."
