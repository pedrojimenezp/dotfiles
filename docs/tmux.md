# tmux

Config: `tmux/.config/tmux/tmux.conf`. Keys: `prefix ?` (this config, plugins, tools). `prefix` is `Ctrl+Space`.

## Requirements

tmux 3.5 or newer (`extended-keys-format`), installed by mise. Never use apt's tmux: it is older and errors on unknown options. If a login still starts `/usr/bin/tmux`, switch the login shell to zsh and run `tmux kill-server`.

## Change a key or option

1. Edit `tmux.conf` in the repo. Give every new `bind` a `-N "note"` so it shows in `prefix ?`.
2. Reload with `prefix r`. Some `set -s` options need `tmux kill-server`.

Machine-only options go in `~/.config/tmux/local.conf`. It is sourced after the status settings and before the plugins, so it can override anything.

## Add a plugin

1. Add `set -g @plugin "author/name"` above the `run ".../tpm"` line. Keep `tmux-continuum` last.
2. `prefix r`, then `prefix I` to install. `prefix U` updates; `prefix Alt+u` removes unlisted ones.

## Sessions after a reboot

continuum saves every 15 minutes and restores on server start: just run `tmux`. Saves hold layouts, folders and pane text; only `ssh` is restarted. Files are in `~/.local/share/tmux/resurrect/` (`last` points to the newest).

## One session in two terminals

`tmux new-session -t '=<session>' -s <session>-view` opens a grouped session: it shares the windows but each terminal keeps its own current window. Add `\; set destroy-unattached on` and the view disappears on detach. Reattach to a kept view with `tmux attach -t '=<session>-view'`.

## Project sessions (`prefix f`)

`tmux-sessionizer` lists folders and switches to a session for the one you pick, creating it if needed. Outside tmux it attaches; `tmux-sessionizer <dir>` skips the list.

- **Features first**, as `feature  [x]`: any `<x>/worktrees/<feature>` folder (up to 4 levels deep). Then **repos**: any folder with `.git` (up to 3 levels).
- **Roots:** `SESSIONIZER_DIRS` (space separated) if set; otherwise `~/projects` plus `~/<name>` repos with `.git` and their `worktrees/*`. Add more in `~/.zshrc.local`: `export SESSIONIZER_DIRS="$HOME/projects $HOME/development"`.
- **Skipped:** the roots, hidden folders, `node_modules`, and anything inside `worktrees/`. No git calls: folder names only.
- **Names:** the folder name, with `.`, `:`, `/` and spaces turned into `-`. A folder that already has a session reuses it. A name taken by another folder gets `-<owner>` (the folder that holds `worktrees/`, else the parent).
- `SESSIONIZER_TMUX_ARGS` passes extra tmux options, such as `-L sock`.

Project missing? `tmux-sessionizer --list` prints `label<TAB>path` for every candidate. An old `~/.config/sessionizer/config`, `SESSIONIZER_EXCLUDE` or `SESSIONIZER_DEPTH` is ignored.

## Popups

`bin/.local/bin/tmux-popup` runs them. The scratch shell (`` prefix ` ``) and Claude Code (`prefix A`) keep running: the same key hides them. Each is a hidden session `_popup_shell_<session>` / `_popup_claude_<session>`.

- `prefix s`, `prefix w`, `prefix (` and `prefix )` skip `_popup_*` sessions; `tmux ls` still shows them.
- `prefix s` and `prefix w` list grouped sessions too (`choose-tree -G`); without it tmux 3.7 shows an empty list while a session group exists.
- A `client-session-changed` hook moves you off a popup session you land in after a kill.
- They store their parent's session id (`@popup_parent`). `session-closed` and resurrect's post-restore hook run `tmux-popup cleanup` to kill orphans.
- Claude runs as `$SHELL -ic claude`, so your `claude` function applies.
- The border is set to rounded blue because tmux 3.8's solid grey reads badly on light themes.

`prefix G` (`tmux-lazygit`) in a folder without `.git` that holds repos (a feature folder) opens the only repo, or asks which one.

`prefix R` (`bin/.local/bin/review`) opens the folder's changes in nvim diffview, one window per repo; see [Reviewing in Neovim](git.md#reviewing-in-neovim).

## Copying (iTerm2)

tmux copies through OSC 52, so turn on iTerm2's "Applications in terminal may access clipboard" (Settings > General > Selection). Drag, double- or triple-click copies. `Option` + drag bypasses tmux, for example across split panes.

## Status bar

| Indicator | Meaning |
| --- | --- |
| Session block yellow | Prefix pressed, waiting for a key |
| 🔔 after a window | Bell rang (Claude Code needs you); clears when you open it |
| 🔍 after a window | Zoomed pane |
| Magenta **●account** | A pane in that window runs Claude on that account; only on other windows, shortened to **●p** below 120 columns (`@claude_label_min_width`) |
| Red **SSH** badge | The tmux server runs over SSH; shows `user@host` |

- Account marks come from the `claude` shell function in the private Claude config, which sets the pane option `@claude_account`. Test by hand: `tmux set -p @claude_account niche`, clear with `tmux set -pu @claude_account`.
- The SSH badge checks `SSH_CONNECTION` when the server starts, so a server started locally keeps the local look. The host is `@host_label` (default `$HOST_LABEL`, see [Name this server](server.md#4-name-this-server)), else the short host name.
- With 2+ panes, a `window-layout-changed` hook turns on pane labels (`index: command`).
- A window named like a version number (`2.1.312`) shows as `claude`.
- `monitor-activity` stays off: it would flag every window that prints.

## Why it's built this way

- **`Ctrl+h/j/k/l`** are vim-tmux-navigator's plain bindings written into `tmux.conf`: the plugin spent over a second per reload spawning `tmux`. Plain `Ctrl+l` moves right; `prefix Ctrl+l` clears screen and scrollback (skipped in vim and nvim). The scrollback clears 0.3 s later, or the shell redraw pushes the old screen back into history.
- **`Cmd+K`** in Ghostty and iTerm (`Ctrl+Shift+K` on Linux Ghostty) sends `prefix Ctrl+l`.
- **TPM runs with `run -b`**, so `prefix r` returns at once; plugin keys appear a few seconds later.
- **Extended keys** (CSI u) let `Shift+Enter` and `Ctrl+Enter` reach Claude Code. `allow-passthrough on` lets `theme` recolor the outer terminal and chafa draw images.
- **`detach-on-destroy off`**: killing a session moves you to another one.

## Troubleshooting

- **Unknown options on start:** tmux older than 3.5, see [Requirements](#requirements).
- **A plugin is missing:** `prefix I`.
- **`Cmd+K` does nothing:** the pane runs vim or nvim, by design.
