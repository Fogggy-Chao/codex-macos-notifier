#!/usr/bin/env bash
set -euo pipefail

codex_home="${CODEX_HOME:-$HOME/.codex}"
bin_dir="$codex_home/bin"
config_file="$codex_home/config.toml"
backup_file="$config_file.bak.codex-macos-notifier-uninstall.$(date +%Y%m%d%H%M%S)"

if [[ -f "$config_file" ]]; then
  cp "$config_file" "$backup_file"
  /usr/bin/python3 - "$config_file" "$codex_home" <<'PY'
from pathlib import Path
import sys

config_path = Path(sys.argv[1])
codex_home = Path(sys.argv[2])
text = config_path.read_text()
permission_hook = str(codex_home / "bin" / "codex-permission-request-notify")
turn_hook = str(codex_home / "bin" / "codex-turn-ended-notify")

lines = text.splitlines()
result = []
index = 0
while index < len(lines):
    line = lines[index]
    stripped = line.strip()

    if stripped == f'notify = ["{turn_hook}"]':
        index += 1
        if index < len(lines) and not lines[index].strip():
            index += 1
        continue

    if stripped == "[[hooks.PermissionRequest]]":
        block = [line]
        index += 1
        while index < len(lines):
            next_line = lines[index]
            next_stripped = next_line.strip()
            if next_stripped.startswith("[[") and next_stripped != "[[hooks.PermissionRequest.hooks]]":
                break
            block.append(next_line)
            index += 1
        if permission_hook in "\n".join(block):
            continue
        result.extend(block)
        continue

    result.append(line)
    index += 1

config_path.write_text("\n".join(result).rstrip() + "\n")
PY
fi

rm -f \
  "$bin_dir/task-notify" \
  "$bin_dir/codex-turn-ended-notify" \
  "$bin_dir/codex-permission-request-notify"

cat <<EOF
Uninstalled Codex macOS notifier.

Backup:
  $backup_file
EOF
