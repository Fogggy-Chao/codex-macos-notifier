#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
codex_home="${CODEX_HOME:-$HOME/.codex}"
bin_dir="$codex_home/bin"
config_file="$codex_home/config.toml"
backup_file="$config_file.bak.codex-macos-notifier.$(date +%Y%m%d%H%M%S)"

mkdir -p "$bin_dir"

install -m 0755 "$repo_dir/scripts/task-notify" "$bin_dir/task-notify"
install -m 0755 "$repo_dir/scripts/codex-turn-ended-notify" "$bin_dir/codex-turn-ended-notify"
install -m 0755 "$repo_dir/scripts/codex-permission-request-notify" "$bin_dir/codex-permission-request-notify"

if [[ ! -f "$config_file" ]]; then
  touch "$config_file"
fi

cp "$config_file" "$backup_file"

/usr/bin/python3 - "$config_file" "$codex_home" <<'PY'
from pathlib import Path
import sys

config_path = Path(sys.argv[1])
codex_home = Path(sys.argv[2])
text = config_path.read_text()

turn_hook = str(codex_home / "bin" / "codex-turn-ended-notify")
permission_hook = str(codex_home / "bin" / "codex-permission-request-notify")

lines = text.splitlines()

def upsert_top_level_notify(lines):
    notify_line = f'notify = ["{turn_hook}"]'
    for index, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith("notify ="):
            lines[index] = notify_line
            return lines
        if stripped.startswith("["):
            return lines[:index] + [notify_line, ""] + lines[index:]
    return [notify_line, ""] + lines if lines else [notify_line]

def ensure_feature(lines):
    for index, line in enumerate(lines):
        if line.strip() == "[features]":
            section_end = len(lines)
            for scan in range(index + 1, len(lines)):
                if lines[scan].strip().startswith("["):
                    section_end = scan
                    break
            for scan in range(index + 1, section_end):
                if lines[scan].strip().startswith("codex_hooks"):
                    lines[scan] = "codex_hooks = true"
                    return lines
            return lines[:index + 1] + ["codex_hooks = true"] + lines[index + 1:]
    if lines and lines[-1].strip():
        lines.append("")
    lines.extend(["[features]", "codex_hooks = true"])
    return lines

def remove_existing_permission_hook(lines):
    result = []
    index = 0
    while index < len(lines):
        stripped = lines[index].strip()
        if stripped == "[[hooks.PermissionRequest]]":
            block = [lines[index]]
            index += 1
            while index < len(lines) and not lines[index].strip().startswith("[[hooks.PermissionRequest]]"):
                block.append(lines[index])
                index += 1
                if index < len(lines) and lines[index].strip().startswith("[[") and lines[index].strip() != "[[hooks.PermissionRequest.hooks]]":
                    break
            if permission_hook in "\n".join(block):
                continue
            result.extend(block)
            continue
        result.append(lines[index])
        index += 1
    return result

lines = upsert_top_level_notify(lines)
lines = ensure_feature(lines)
lines = remove_existing_permission_hook(lines)

if lines and lines[-1].strip():
    lines.append("")
lines.extend([
    "[[hooks.PermissionRequest]]",
    'matcher = "*"',
    "",
    "[[hooks.PermissionRequest.hooks]]",
    'type = "command"',
    f'command = "{permission_hook}"',
])

config_path.write_text("\n".join(lines).rstrip() + "\n")
PY

cat <<EOF
Installed Codex macOS notifier.

Scripts:
  $bin_dir/task-notify
  $bin_dir/codex-turn-ended-notify
  $bin_dir/codex-permission-request-notify

Updated:
  $config_file

Backup:
  $backup_file

Run this to test:
  "$bin_dir/task-notify" "Codex" "Notifier installed"
EOF
