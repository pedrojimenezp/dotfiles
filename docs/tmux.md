# tmux

tmux keeps your terminal programs running when you close the terminal or lose the connection. It splits one terminal into [panes](glossary.md#pane), groups panes into [windows](glossary.md#window), and groups windows into [sessions](glossary.md#session).

You'll use it for splits, tabs, project sessions, popups, and work that survives a disconnect.

- [Requirements](#requirements)
- [Quick start](#quick-start)
- [Key reference](#key-reference)
- [How-to](#how-to)
- [Troubleshooting](#troubleshooting)
- [How it works](#how-it-works)
- [Related pages](#related-pages)

## Requirements

tmux 3.5 or newer. The `Brewfile` installs a current version.

**macOS:** `brew bundle` (run by `install.sh`) installs it.

**Linux:** use Homebrew's tmux, as in [install.md](install.md). The tmux in apt is too old and prints errors for options it does not know.

The config is `tmux/.config/tmux/tmux.conf`, linked to `~/.config/tmux/tmux.conf`. Every line has a comment.

## Quick start

Most keys start with the [prefix](glossary.md#prefix) (the key that tells tmux a command follows). Here `prefix` means `Ctrl+Space`, pressed and released before the next key.

Start tmux with `tmux`, or attach to a named session (creating it if needed) with `tmux new-session -A -s work`. Then learn these keys:

| Keys | What it does |
| --- | --- |
| `prefix ?` | Search every shortcut in a popup |
| `prefix \|` and `prefix -` | Split left/right and top/bottom |
| `prefix c` | New window |
| `Ctrl+h` / `j` / `k` / `l` | Move between panes, no prefix |
| `prefix f` | Pick a project session ([tmux-sessionizer.md](tmux-sessionizer.md)) |
| `prefix z` | Zoom a pane to the full window, again to restore |
| `prefix d` | Detach: everything keeps running |
| `prefix [` | Copy mode (vi keys) |

New to all this? [first-day.md](first-day.md) tours the keys you'll use most.

## Key reference

Keys from this config. The mouse is on: click a pane or window name, drag a border to resize, scroll the wheel to enter copy mode.

| Keys | What it does |
| --- | --- |
| `prefix ?` | Search all shortcuts in a popup (`dotfiles-help`) |
| `prefix k` | tmux's own key list with notes (`list-keys -N`) |
| `prefix \|` / `prefix -` | Split left/right / top/bottom, in the current folder |
| `prefix c` | New window, in the current folder |
| `prefix H` / `J` / `K` / `L` | Resize the pane by 5 cells. Hold the key to repeat. |
| `Ctrl+h` / `j` / `k` / `l` | Move between panes and nvim splits, no prefix (vim-tmux-navigator) |
| `prefix [` | Copy mode. Then `v` selects, `Ctrl+v` toggles a rectangle, `y` copies and leaves. |
| `prefix f` | Project session picker |
| `prefix t` | Toggle light/dark theme ([theme.md](theme.md)) |
| `prefix G` | lazygit in a popup, in the pane's folder |
| `` prefix ` `` | Scratch shell popup that keeps running |
| `prefix A` | Claude Code popup that keeps running |
| `prefix Space` | Copy with hints (tmux-fingers). Replaces the default `next-layout`. |
| `prefix j` | Jump mode (tmux-fingers): hints move the copy-mode cursor to a match, see [Copy with hints](#copy-with-hints) |
| `prefix s` | Pick a session from a list sorted by name (`O` in the picker changes the sort order; popup sessions are hidden) |
| `prefix N` | New session: asks for a name (anything but letters, digits, `_` and `-` becomes `-`, so `my.app` is `my-app`; empty uses the folder's name), then opens an fzf popup to pick the folder: this pane's path first, then zoxide's folders, then the `prefix f` projects. Type a path that is not in the list and press `Enter` to use it (`~` works). An existing session with that name is just switched to; `Esc` cancels |
| `prefix (` / `prefix )` | Previous / next session (popup sessions skipped) |
| `prefix X` | Kill the current session, after a `y/n` question |
| `prefix r` | Reload `tmux.conf` |
| `prefix Ctrl+l` | Clear the screen and the scrollback (does nothing in vim or nvim) |
| `prefix Ctrl+s` / `prefix Ctrl+r` | Save / restore sessions (resurrect) |
| `prefix I` | Install plugins (TPM). Press `Shift+i`. |
| `prefix Ctrl+Space` | Send a real `Ctrl+Space` to the program inside, such as a nested tmux |

`prefix` itself is `Ctrl+Space`: the default `Ctrl+b` is removed.

tmux defaults you will use often (not set in this config):

| Keys | What it does |
| --- | --- |
| `prefix x` / `prefix &` | Close the pane / window (asks first) |
| `prefix 1` ... `9` | Go to window number |
| `prefix n` / `prefix p` | Next / previous window |
| `prefix ,` / `prefix $` | Rename the window / session |
| `prefix w` | Pick a window from a tree |
| `prefix /` | Describe one key: press it and tmux shows its note |
| `prefix :` | tmux command prompt (vi keys) |
| `prefix ]` | Paste the tmux buffer |

### Popups

A [popup](glossary.md#popup) floats over the current window.

| Keys | Popup | Keeps running? |
| --- | --- | --- |
| `prefix G` | lazygit, in the pane's folder | No: `q` closes it. Without lazygit you see "lazygit is not installed". |
| `` prefix ` `` | Scratch shell | Yes |
| `prefix A` | Claude Code | Yes |

Press the same key again to hide a persistent popup (either key works inside any of them), or use `prefix d`. The program keeps running. If the program exits, the popup closes and the next press starts a fresh one.

### Copy with hints

`prefix Space` ([tmux-fingers](https://github.com/Morantron/tmux-fingers)) highlights URLs, file paths, git hashes, IPs, UUIDs and numbers (4+ digits) in the visible pane, each with a letter hint.

| Keys (in hint mode) | What it does |
| --- | --- |
| `a`-`z` | Copy the match |
| `Ctrl` + letter | Copy and open it (for example a URL in the browser) |
| `Shift` + letter | Copy and paste it into the pane |
| `Tab` | Multi mode: pick several matches, `Tab` again copies them all |
| `q` or `Esc` | Leave |

`prefix j` starts jump mode instead: pick a hint and copy mode opens with the cursor on that match. The plugin default is `prefix J`, which would replace the pane resize, so `@fingers-jump-key` is set to `j`.

The copy goes to the tmux buffer, the system clipboard and, through [OSC 52](glossary.md#osc-52), your local clipboard even over SSH.

### Status bar and pane labels

The left side is the user in a purple block, then the session name in a blue block. The right side shows the git branch of the current pane (hidden outside a repo), the host name and the time. The active window is a reversed block.

| Indicator | Meaning |
| --- | --- |
| Session block turns **yellow** | You pressed the prefix and tmux waits for the next key |
| 🔔 after a window name, label turns yellow | A program in that window rang the bell (Claude Code does this when it needs you). It clears when you open the window. |
| 🔍 after a window name | The pane is zoomed (`prefix z`) |
| Red **SSH** badge on the left | The tmux server runs on a remote machine. It shows `user@host` (the server's name, see [Name this server](server.md#4-name-this-server)) and replaces the purple user block |

With 2 or more panes in a window, each pane gets a label row at its top border: `index: command`. The active label is a blue block.

Other defaults: windows and panes are numbered from 1, scrollback is 50000 lines per pane, and `Esc` has a 10 ms delay so it is fast in vim. A window named like a version number (for example `2.1.312`) is shown as `claude`.

## How-to

### Find a key you forgot

1. Press `prefix ?`.
2. Type to filter. Start a word with `'` for an exact match.
3. Press `Esc` to close.

The list covers tmux, zsh keys and aliases, and tool keys. Outside tmux run `dotfiles-help`, or `dotfiles-help --list` for a plain table. For tmux's own defaults, press `prefix k`.

### Clear the pane with `Cmd+K`

**macOS:** in Ghostty and iTerm, `Cmd+K` clears the tmux pane, scrollback included. It sends `Ctrl+Space`, then `Ctrl+L`.

**Linux:** in Ghostty, use `Ctrl+Shift+K`.

In a pane running vim or nvim, nothing happens. See [terminals.md](terminals.md).

### Set a host label for the SSH badge

See [Name this server](server.md#4-name-this-server) in server.md.

### Add a plugin

1. Add `set -g @plugin "author/name"` above the `run ".../tpm"` line in `tmux.conf`. Keep `tmux-continuum` last in the plugin list.
2. Reload with `prefix r`.
3. Install with `prefix I`.

Check it worked: the plugin's folder appears in `~/.config/tmux/plugins/`.

Undo: remove the line, reload, and press `prefix Alt+u` to delete plugins no longer listed.

Other TPM keys: `prefix U` updates plugins.

| Plugin | What it does |
| --- | --- |
| `tmux-plugins/tpm` | The plugin manager |
| `christoomey/vim-tmux-navigator` | `Ctrl+h/j/k/l` between tmux panes and nvim splits |
| `Morantron/tmux-fingers` | Copy with hints |
| `tmux-plugins/tmux-resurrect` | Save and restore sessions |
| `tmux-plugins/tmux-continuum` | Auto-save every 15 minutes, auto-restore |

### Change a key or option

1. Edit `tmux/.config/tmux/tmux.conf` in the repo (the link points there).
2. Give every new binding a note: `bind -N "what it does" key command`. It then shows in `prefix ?`.
3. Reload with `prefix r`, or run `tmux source-file ~/.config/tmux/tmux.conf`.

Settings applied at server start (some `set -s` options) may need `tmux kill-server`.

For options on one machine only, use `~/.config/tmux/local.conf`. See [contributing.md](contributing.md) for how notes feed the help.

### Restore sessions after a reboot

Nothing to do: start `tmux`. continuum saves every 15 minutes and restores the last save when the server starts. For a manual save or restore, use `prefix Ctrl+s` or `prefix Ctrl+r`.

Saves hold sessions, windows, panes, their folders and the visible text of each pane. Panes running `ssh` run it again. Other programs are not restarted.

## Troubleshooting

- **Errors about unknown options on start**: your tmux is older than 3.5. See [Requirements](#requirements).
- **`prefix Space` does nothing**: the `tmux-fingers` binary is missing. Run `brew bundle`. Otherwise the first load shows an install menu: pick "Download standalone binary" (Linux x86_64 and macOS arm64) or build from source (needs Crystal).
- **A plugin is missing**: press `prefix I`.
- **`Cmd+K` does nothing**: the pane runs vim or nvim, by design. Or you are not in Ghostty or iTerm.
- **You need a layout**: `prefix Space` no longer cycles layouts. Use `prefix :` then `select-layout tiled` (or `even-horizontal`).
- **Colors look wrong in the bar**: the bar uses your terminal's colors. Check your terminal theme ([theme.md](theme.md)).

## How it works

**Prefix.** `unbind C-b`, `set -g prefix C-Space`, and a `send-prefix` binding on `Ctrl+Space`.

**Why `prefix k` shows raw keys.** `prefix ?` is the help popup now. `Shift+?` is no separate key on a US keyboard, and `prefix /` stays tmux's "describe one key". `k` is free in the defaults.

**Help popup.** `prefix ?` runs `dotfiles-help` (`bin/.local/bin/dotfiles-help`) in a popup of 80% of the window. It reads the repo at every open, so nothing is synced by hand. Where each row comes from (`bind -N` notes, `.zshrc` comments, script headers, [cheatsheet.tsv](cheatsheet.tsv)) is in [contributing.md](contributing.md#how-it-works).

**Order of `prefix Ctrl+l`.** vim-tmux-navigator owns plain `Ctrl+l` (move right) and also sets `prefix Ctrl+l` to a plain clear. So `tmux.conf` defines `prefix Ctrl+l` again at the very end, after TPM runs. Bindings that must override a plugin key go there. The scrollback clears 0.3 seconds after the screen, because the shell redraw would otherwise push the old screen back into history. In vim or nvim the binding is skipped, because the `Ctrl+l` would reach the editor and move focus.

**Escape sequences.** `set-clipboard on` uses [OSC 52](glossary.md#osc-52). `allow-passthrough on` lets programs, and the `theme` script, send escape sequences through tmux. Extended keys are on (CSI u format), and `xterm*` terminals are marked as supporting them. This lets `Shift+Enter` and `Ctrl+Enter` reach programs such as Claude Code. Colors are `tmux-256color` plus true color.

**`detach-on-destroy off`.** Killing a session moves you to another one. tmux exits only when no session is left.

**Popups.** `bin/.local/bin/tmux-popup` runs them. Each persistent popup is a hidden session named `_popup_shell_<session>` or `_popup_claude_<session>`, one per normal session. Claude Code runs as `$SHELL -ic claude`, so your `claude` alias or function applies.

- **Hidden from lists.** `prefix s` filters out sessions whose name starts with `_popup_`. `tmux ls` still shows them. `prefix (` and `prefix )` skip them (`tmux-popup prev|next`).
- **Never landed in by mistake.** A `client-session-changed` hook moves you to the next normal session if killing a session lands you in a popup session.
- **Cleanup.** Popup sessions remember their parent (`@popup_parent`, the session id, so renaming is fine). A `session-closed` hook runs `tmux-popup cleanup`, which kills popups whose parent is gone.
- **Resurrect.** Saves include popup sessions, and a restore brings them back without the parent mark. `@resurrect-hook-post-restore-all` runs the same cleanup after every restore. A running Claude Code is not restored anyway.
- **Look.** Popups use the terminal's colors with a rounded blue border. tmux 3.8's default is a solid grey that reads badly on light themes.

**Status bar.** It refreshes every 5 seconds and uses the terminal's own colors, so it works in light and dark themes. Bells use `monitor-bell on` and `bell-action any`, with `visual-bell off`. `monitor-activity` stays off: it would flag every window that prints anything. Messages and the command prompt (`prefix :`) take over the status line as a blue block. `fill=blue` paints the rest of the line, because tmux otherwise draws the prompt only over its own text.

**Remote SSH badge.** At load, `if-shell '[ -n "$SSH_CONNECTION" ]'` runs in the server's environment, so it sees the `SSH_CONNECTION` of the shell that started the server. If set, `status-left` starts with a red `SSH` badge holding `user@host`: `@host_label`, or the short host name when empty. The user is `#{user}`, the account that runs the tmux server (a tmux format, no shell call). The right side drops the host name. A server first started locally and used over SSH later keeps the local look. `@host_label` defaults to `$HOST_LABEL`, read when the server starts, and `local.conf` can override it ([Name this server](server.md#4-name-this-server)). `local.conf` is sourced after the status settings and before the plugins, so it can override anything.

**Pane labels.** A `window-layout-changed` hook sets `pane-border-status top` when a window has 2 or more panes, and `off` otherwise. It runs on split, close, layout change and session restore.

**Plugins.** `install.sh` clones TPM into `~/.config/tmux/plugins/tpm` and installs the plugins. It never starts tmux-fingers' wizard. tmux-fingers is a wrapper around a `tmux-fingers` binary (Crystal), installed by the `tmux-fingers` formula before tmux first loads the plugin. For patterns and styles see its README (`@fingers-pattern-N`, `@fingers-hint-style`).

**Sessions survive restarts.** resurrect saves with `@resurrect-capture-pane-contents on` and `@resurrect-processes "ssh"`. continuum uses `@continuum-save-interval` 15 and `@continuum-restore on`. Files live in `~/.local/share/tmux/resurrect/` (or `~/.tmux/resurrect/` if that folder exists). The newest save is the file the `last` link points to.

## Related pages

- [tmux-sessionizer.md](tmux-sessionizer.md): project sessions
- [theme.md](theme.md): light and dark toggle
- [terminals.md](terminals.md): Ghostty and iTerm
- [server.md](server.md): remote use with `tssh`
- [glossary.md](glossary.md): terms used here
