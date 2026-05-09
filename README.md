# Codex macOS Notifier

macOS Notification Center banners for Codex CLI.

This adds two notifications:

- `Codex` / `Task finished` when a Codex turn completes.
- `Codex needs review` when Codex needs human approval for a command, file edit, network access, or permission change.
- Clicking a notification opens your terminal app again when `terminal-notifier` is available.

It does not auto-approve anything. Approval notifications only tell you to come back and review the prompt in Codex.

## Requirements

- macOS
- Codex CLI with `~/.codex/config.toml`
- `/usr/bin/python3`
- `terminal-notifier` recommended

If `terminal-notifier` is not installed, the helper falls back to macOS `osascript`.

Install `terminal-notifier` with Homebrew:

```sh
brew install terminal-notifier
```

## Install

Clone the repo, then run:

```sh
git clone https://github.com/YOUR_USERNAME/codex-macos-notifier.git
cd codex-macos-notifier
./install.sh
```

The installer copies scripts into:

```text
~/.codex/bin
```

It updates:

```text
~/.codex/config.toml
```

It also creates a timestamped backup before editing the config.

## What It Adds

The installer sets the legacy Codex completion notifier:

```toml
notify = ["/Users/you/.codex/bin/codex-turn-ended-notify"]
```

It also enables Codex hooks and registers a permission request hook:

```toml
[features]
codex_hooks = true

[[hooks.PermissionRequest]]
matcher = "*"

[[hooks.PermissionRequest.hooks]]
type = "command"
command = "/Users/you/.codex/bin/codex-permission-request-notify"
```

## Test

After installing, run:

```sh
~/.codex/bin/task-notify "Codex" "Notifier installed"
```

You should see a macOS notification.

Click the notification banner to return to the terminal app that sent it.

You can also test the permission-request hook:

```sh
printf '%s\n' '{"tool_name":"Bash"}' | ~/.codex/bin/codex-permission-request-notify
```

## Banner Style

macOS decides whether notifications appear as banners or alerts.

To make them banners:

1. Open **System Settings**.
2. Go to **Notifications**.
3. Select **terminal-notifier**, Terminal, or iTerm depending on what sends the notification.
4. Enable notifications.
5. Set alert style to **Banners**.

## Click To Focus

Click-to-focus uses `terminal-notifier`'s app activation support. The helper detects common terminal apps from `TERM_PROGRAM` and terminal-specific environment variables:

- Terminal: `com.apple.Terminal`
- iTerm2: `com.googlecode.iterm2`
- WezTerm: `com.github.wez.wezterm`
- Warp: `dev.warp.Warp-Stable`
- VS Code integrated terminal: `com.microsoft.VSCode`
- Cursor integrated terminal: `com.todesktop.230313mzl4w4u92`
- Ghostty: `com.mitchellh.ghostty`
- Kitty: `net.kovidgoyal.kitty`
- Alacritty: `org.alacritty`
- Tabby: `org.tabby`
- Hyper: `co.zeit.hyper`
- Rio: `com.raphaelamorim.rio`

This covers the mainstream macOS terminal apps. If a terminal changes its bundle id or reports a nonstandard environment, set the bundle id explicitly:

```sh
TASK_NOTIFY_ACTIVATE_APP=com.example.Terminal ~/.codex/bin/task-notify "Codex" "Task finished"
```

You can find a bundle id with:

```sh
osascript -e 'id of app "Terminal"'
```

## Uninstall

Run:

```sh
./uninstall.sh
```

The uninstaller removes the installed scripts and removes the config entries it added. It also creates a timestamped backup of `~/.codex/config.toml`.

## Scripts

- `scripts/task-notify`: small Notification Center helper.
- `scripts/codex-turn-ended-notify`: Codex turn-complete notification hook.
- `scripts/codex-permission-request-notify`: Codex permission-request hook.

## Notes

The permission hook intentionally returns no approval decision. It only sends a notification, then Codex continues to wait for the user to approve or deny the action.
