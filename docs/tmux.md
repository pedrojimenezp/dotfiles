# tmux

File: `tmux/.config/tmux/tmux.conf`, linked to `~/.config/tmux/tmux.conf`. It needs tmux 3.3 or newer. Every line has a comment in the file.

tmux keeps your terminal programs running when you close the terminal or lose the connection. It splits one terminal into **panes**, groups panes into **windows**, and groups windows into **sessions**.

## The prefix: `Ctrl+Space`

Most tmux keys start with the **prefix**. Press `Ctrl+Space`, release it, then press the next key. In this document `prefix c` means: `Ctrl+Space`, then `c`.

The default prefix `Ctrl+b` is removed. Press the prefix twice (`Ctrl+Space`, `Ctrl+Space`) to send a real `Ctrl+Space` to the program inside, for example a nested tmux.

## Basics

| Concept | Meaning |
| --- | --- |
| Session | A named workspace. It survives when you detach. |
| Window | A "tab" inside a session. Numbered from 1. |
| Pane | A split inside a window. Numbered from 1. |

Start tmux: `tmux`. Start or attach to a named session: `tmux new-session -A -s work`. List sessions: `tmux ls`.

## Keys from this config

Forgot one? `prefix ?` opens a searchable list of every key from this config and its plugins, plus the zsh keys and aliases, see [Help popup](#help-popup). tmux's defaults: `prefix k`.

| Keys | What it does |
| --- | --- |
| `prefix ?` | Search all shortcuts in a popup (`dotfiles-help`) |
| `prefix k` | tmux's own list of keys with notes (`list-keys -N`), the old `prefix ?` |
| `prefix \|` | Split left/right, in the current folder |
| `prefix -` | Split top/bottom, in the current folder |
| `prefix c` | New window, in the current folder |
| `prefix H` / `J` / `K` / `L` | Resize the pane 5 cells left / down / up / right. Hold the key to repeat (use `Shift`). |
| `Ctrl+h` / `j` / `k` / `l` | Move between panes (and nvim splits), **no prefix** (vim-tmux-navigator) |
| `prefix [` | Enter copy mode (vi keys). Then `v` starts a selection, `Ctrl+v` toggles a rectangle, `y` copies and leaves. |
| `prefix f` | Project session picker, see [tmux-sessionizer.md](tmux-sessionizer.md) |
| `prefix t` | Toggle light/dark theme, see [theme.md](theme.md) |
| `prefix G` | (`Shift+g`) lazygit in a popup, in the pane's folder. See [Popups](#popups) |
| `` prefix ` `` | Toggle a scratch shell popup that keeps running. See [Popups](#popups) |
| `prefix A` | (`Shift+a`) Toggle a Claude Code popup that keeps running. See [Popups](#popups) |
| `prefix Space` | Copy with hints (tmux-fingers), see [Copy with hints](#copy-with-hints). Replaces the default `next-layout` |
| `prefix s` | Pick a session from a list (popup sessions are hidden) |
| `prefix N` | (`Shift+n`) New session: asks for a name (no `.` or `:`), starts in the pane's folder and switches to it |
| `prefix X` | Kill the current session, after a `y/n` question |
| `prefix r` | Reload `tmux.conf` and show "tmux.conf reloaded" |
| `prefix Ctrl+l` | Clear the screen and the scrollback of the pane (see the note below) |
| `prefix Ctrl+s` | Save sessions now (resurrect) |
| `prefix Ctrl+r` | Restore saved sessions (resurrect) |
| `prefix I` | (`Shift+i`) Install plugins (TPM) |

Note on `Ctrl+l`: plain `Ctrl+l` belongs to vim-tmux-navigator (move to the right pane; inside vim, nvim or fzf it is sent to the program). The plugin also sets `prefix Ctrl+l` to a plain clear screen, so `tmux.conf` defines `prefix Ctrl+l` again at the very end, after TPM, as "clear screen and scrollback". The scrollback is cleared 0.3 seconds after the screen, because the shell redraw would otherwise push the old screen back into the history.

### Default keys you will use often

These are tmux defaults, not set in this config.

| Keys | What it does |
| --- | --- |
| `prefix d` | Detach (everything keeps running) |
| `prefix x` | Close the current pane (asks first) |
| `prefix &` | Close the current window (asks first) |
| `prefix z` | Zoom the pane to full window, press again to restore |
| `prefix 1` ... `9` | Go to window number |
| `prefix n` / `p` | Next / previous window |
| `prefix ,` | Rename the window |
| `prefix $` | Rename the session |
| `prefix (` / `)` | Previous / next session (popup sessions skipped) |
| `prefix w` | Pick a window from a tree |
| `prefix /` | Describe one key: press it and tmux shows its note |
| `prefix :` | tmux command prompt (vi keys) |
| `prefix ]` | Paste the tmux buffer |

The mouse is on: click a pane or window name, drag a border to resize, scroll the wheel to enter copy mode.

## Help popup

`prefix ?` runs `bin/.local/bin/dotfiles-help` (linked to `~/.local/bin/dotfiles-help`) in a popup of 80% of the window. Type to filter (fuzzy; start a word with `'` for an exact match), `Esc` closes. The bottom pane shows the selected entry and the doc to read.

The list is read from the repo at every open, so nothing has to be kept in sync by hand:

| Area | Source |
| --- | --- |
| `tmux` | The `bind -N "..."` lines of `tmux.conf` (no tmux server needed) |
| `zsh key`, `zsh alias`, `zsh function` | End-of-line comments of `bindkey` and `alias` lines in `zsh/.zshrc`, and the comment above each function |
| `command` | Line 2 and the `# Usage:` lines of each script in `bin/.local/bin` |
| `tmux plugin`, `zsh tool`, `terminal`, `nvim`, `theme` | [cheatsheet.tsv](cheatsheet.tsv): keys that no config file states |

tmux's own default keys are not in the list: `prefix k` shows them (and `prefix /` describes one key). Keys are shown readable: `C-l` becomes `Ctrl+l`, an uppercase letter becomes `Shift+A`. The script finds the repo by following its own symlink, so it works wherever the repo is cloned.

Outside tmux run `dotfiles-help` (the same list, without the popup) or `dotfiles-help --list` (a plain table: `area`, `keys`, `description`, `doc`, separated by tabs).

**Rule for new keys**: every `bind` in `tmux.conf` gets `-N "short description"`. Plugin keys cannot carry a note (the plugins bind them), so they go in `docs/cheatsheet.tsv`. Check with `grep -E '^\s*bind' tmux/.config/tmux/tmux.conf | grep -v -- ' -N '` (no output means every binding has a note).

**Why `prefix k` for the raw list**: `prefix ?` is the help popup now. `Shift+?` is no separate key on a US keyboard (`?` already needs `Shift`), `prefix /` stays tmux's "describe one key", and `k` (keys) is free in the defaults.

## Behavior settings

- **Numbers start at 1** for windows and panes. Windows are renumbered when one closes.
- **Scrollback**: 50000 lines per pane.
- **Escape delay** is 10 ms, so `Esc` is fast in vim.
- **Colors**: `tmux-256color` plus true color (RGB). Focus events are passed to nvim.
- **Extended keys** are on (CSI u format) and the outer `xterm*` terminal is marked as supporting them. This lets `Shift+Enter` and `Ctrl+Enter` reach programs such as Claude Code.
- **Clipboard**: `set-clipboard on` uses OSC 52, so copying in tmux also reaches your local clipboard over SSH. `allow-passthrough on` lets programs (and the `theme` script) send escape sequences through tmux.
- **`detach-on-destroy off`**: when you kill a session (`prefix X`), tmux moves you to another session. It exits only when no session is left.
- **Window names** follow the running command. A name that looks like a version number (for example `2.1.312`) is shown as `claude`.

## Status bar

Left: the session name in a blue block. Right: the git branch of the current pane (with a branch icon, hidden outside a repo), the host name and the time (`HH:MM`). The bar uses the terminal's own colors, so it works in light and dark themes. It updates every 5 seconds. The active window is shown as a reversed block, others as plain `1:name`.

**Indicators**

| Indicator | Meaning |
| --- | --- |
| Session block turns **yellow** | The prefix key was pressed and tmux waits for the next key |
| 🔔 after a window name, and the label turns a yellow block | A program in that window rang the bell (Claude Code does this when it needs you). It clears when you open the window |
| 🔍 after a window name | The pane in that window is zoomed (`prefix z`) |
| `<branch icon> name` on the right | Git branch of the current pane's folder |

Bells from any window are flagged (`monitor-bell on`, `bell-action any`) and no message is shown (`visual-bell off`). `monitor-activity` stays off: it would flag every window that prints anything, which is too noisy.

**Command prompt and messages**: `prefix :` opens the command prompt, and messages such as "tmux.conf reloaded" use the same look. They take over the whole status line as a blue block (`message-style` and `message-command-style`). `fill=blue` paints the rest of the line, because tmux otherwise draws the prompt only over its own text and the right side of the bar stays visible.

**On a remote machine** (the tmux server was started from an SSH session) the look is different so you never mix it up with your local tmux: the left side starts with a red **SSH** badge that holds the host label (for example ` 󰣀 SSH dev-ec2 `), followed by the usual session block (blue, yellow while the prefix is pressed, the same as locally), and the right side shows the branch and the time without the host name. The badge is enough, so the rest of the bar keeps the terminal colors (a tinted bar would hurt readability in the light theme). A server first started locally and later used over SSH keeps the local look.

**Host label and per-machine settings**: the label defaults to the short host name (`#h`). To change it on one machine, create `~/.config/tmux/local.conf`. It is not part of the dotfiles (untracked, not stowed) and tmux loads it if present, after the status settings and before the plugins, so it can override anything:

```tmux
set -g @host_label "dev-box"
```

Reload with `prefix r`.

## Popups

Popups float over the current window. They use the script `bin/.local/bin/tmux-popup` (linked to `~/.local/bin/tmux-popup`).

Look: popups use the terminal's own background and text colors with a rounded blue border (`popup-style`, `popup-border-style`); tmux 3.8's default is a solid grey that reads badly on light themes.

| Keys | Popup | Persists? |
| --- | --- | --- |
| `prefix G` | lazygit in the pane's folder (90% of the window) | No: quitting lazygit (`q`) closes it. Without lazygit installed you get the message "lazygit is not installed". |
| `` prefix ` `` | Scratch shell (85%) | Yes |
| `prefix A` | Claude Code, `claude` (85%) | Yes |

**Persistent popups** (shell and Claude Code): each one is a hidden session named `_popup_shell_<session>` or `_popup_claude_<session>`, one per normal session. The first press creates it in the pane's folder; later presses show the same shell or Claude Code again, with its history and running programs. The popup has no status bar of its own.

- **Close it**: press the same key again (`` prefix ` `` or `prefix A`; inside any persistent popup either key closes it), or `prefix d`. Both detach the popup; the program keeps running.
- **Program exits** (you type `exit`, or quit Claude Code): the hidden session ends and the popup closes. The next press starts a fresh one.
- **Claude Code** runs as `$SHELL -ic claude`, so a `claude` alias or shell function from your shell config applies.

**Hidden from lists**: `prefix s` filters out every session whose name starts with `_popup_`. `tmux ls` still shows them. `prefix (` / `)` skip them too (`tmux-popup prev|next`), stepping through the normal sessions in `tmux ls` order.

**Never landed in by mistake**: with `detach-on-destroy off`, killing a session moves you to another one, which could be a popup session. A `client-session-changed` hook catches that and switches you to the next normal session in `tmux ls` order (the popup's own client is left alone).

**Cleanup**: popup sessions remember their parent session (`@popup_parent`, the session id, so renaming the parent is fine). A `session-closed` hook runs `tmux-popup cleanup`, which kills every popup session whose parent is gone. So `prefix X` on a session also removes its popups.

**resurrect and continuum**: saves include popup sessions, and a restore brings them back without their parent mark. `@resurrect-hook-post-restore-all` runs the same cleanup after every restore, so they disappear right away and the next press starts fresh ones. This is simpler than filtering the save file, and a running Claude Code is not restored anyway.

## Copy with hints

`prefix Space` ([tmux-fingers](https://github.com/Morantron/tmux-fingers)) highlights URLs, file paths, git hashes, IPs, UUIDs, numbers (4+ digits) and similar in the visible pane, each with a letter hint. Press the hint's letter(s) to copy that match; no mouse and no copy mode.

| Keys (in hint mode) | What it does |
| --- | --- |
| `a`-`z` | Copy the match |
| `Ctrl` + letter | Copy and open it (`:open:`, e.g. a URL in the browser) |
| `Shift` + letter | Copy and paste it into the pane |
| `Tab` | Multi mode: pick several matches, `Tab` again copies them all |
| `q`, `Esc` | Leave |

- **Clipboard**: the copy goes to the tmux buffer and the system clipboard (`pbcopy` on macOS, `wl-copy`/`xclip`/`xsel` on Linux with a display) and, through `set-clipboard on` (OSC 52), to your local clipboard even over SSH. One config works everywhere; there is no custom `@fingers-main-action`.
- **`next-layout` is gone**: `prefix Space` used to cycle layouts. It is not rebound elsewhere; use `prefix : select-layout tiled` (or `even-horizontal`, ...) when you need a layout.
- **The binary**: the plugin is a thin wrapper around a `tmux-fingers` binary (Crystal). Full install (`brew bundle`) installs it from the `tmux-fingers` formula before tmux first loads the plugin. `./install.sh` only clones the plugin (`install_plugins`); it never starts the plugin's wizard.
- **Binary missing**: if the binary is not installed (the Brewfile installs it), the first time tmux loads the plugin it shows an install menu (wizard). Pick "Download standalone binary" (Linux x86_64 and macOS arm64) or build from source (needs Crystal). Until then `prefix Space` does nothing. Options for patterns and styles: see the plugin's README (`@fingers-pattern-N`, `@fingers-hint-style`, ...).

## Pane labels

When a window has 2 or more panes, each pane gets a label row at its top border: `index: command`. The active pane's label is a blue block, and arrows mark the active border. Borders are heavy lines. With one pane, the label row is hidden.

## Sessions survive restarts: resurrect and continuum

- **tmux-resurrect** saves sessions, windows, panes, their folders and (here) the visible text of each pane (`@resurrect-capture-pane-contents on`). Panes running `ssh` run it again after a restore (`@resurrect-processes "ssh"`).
- **tmux-continuum** saves automatically **every 15 minutes** (`@continuum-save-interval`) and restores the last save when the tmux server starts (`@continuum-restore on`). So after a reboot or `tmux kill-server`, starting `tmux` brings your sessions back.
- **Manual**: `prefix Ctrl+s` saves, `prefix Ctrl+r` restores.
- **Where the files are**: the plugin default, `~/.local/share/tmux/resurrect/` (or `~/.tmux/resurrect/` if that folder already exists). The newest save is the file the symlink `last` points to.
- Programs other than `ssh` are not restarted, only their panes and folders come back.
- Popup sessions are removed after a restore, see [Popups](#popups).

## Clear the pane: `Cmd+K`

In Ghostty (macOS) and iTerm, `Cmd+K` sends `Ctrl+Space`, then `Ctrl+L`, so it clears the tmux pane, scrollback included. Ghostty on Linux uses `Ctrl+Shift+K`. See [terminals.md](terminals.md).

## Plugins and TPM

Plugins are managed by [TPM](https://github.com/tmux-plugins/tpm), cloned by `install.sh` into `~/.config/tmux/plugins/tpm`.

| Plugin | What it does |
| --- | --- |
| `tmux-plugins/tpm` | The plugin manager |
| `christoomey/vim-tmux-navigator` | `Ctrl+h/j/k/l` between tmux panes and nvim splits |
| `Morantron/tmux-fingers` | Hint-based copy (`prefix Space`), see [Copy with hints](#copy-with-hints) |
| `tmux-plugins/tmux-resurrect` | Save and restore sessions |
| `tmux-plugins/tmux-continuum` | Auto-save every 15 minutes and auto-restore |

Add a plugin:

1. Add a line `set -g @plugin "author/name"` above the `run ".../tpm"` line in `tmux.conf`. Keep `tmux-continuum` last in the plugin list.
2. Reload with `prefix r`.
3. Install with `prefix I` (`Ctrl+Space`, then `Shift+i`).

Other TPM keys (defaults): `prefix U` updates plugins, `prefix Alt+u` removes plugins not in the file.

## Reload the config

`prefix r`, or from a shell: `tmux source-file ~/.config/tmux/tmux.conf`. Settings that are set at server start (some `set -s` options) may need `tmux kill-server`; continuum restores your sessions.

## Change a key or option

Edit `tmux/.config/tmux/tmux.conf` in the repo (the link points there), then `prefix r`. Give every new binding a note, `bind -N "what it does" key command`, so it shows in `prefix ?`. For options only for this machine, add `source-file -q ~/.config/tmux/local.conf` at the end of the file yourself, and keep that file untracked (this line is not in the config today).

## Related

- Project sessions: [tmux-sessionizer.md](tmux-sessionizer.md)
- Remote use: `tssh` in [zsh.md](zsh.md) and [server.md](server.md)
- Theme toggle: [theme.md](theme.md)

## Notes

- Bindings that must override a plugin key go after the `run` line of TPM at the end of `tmux.conf`. `prefix Ctrl+l` is one: it clears the screen and the scrollback, and `Cmd+K` uses it.
