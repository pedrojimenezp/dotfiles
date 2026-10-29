# Terminals: Ghostty and iTerm

Both terminals use the same font and the same colors (from [theme.md](theme.md)). The configs are in the repo, linked by `install.sh`.

| Package | File | Platform |
| --- | --- | --- |
| `ghostty` | `~/.config/ghostty/config` | macOS and Linux. Linked only if Ghostty is installed. |
| `iterm` | `~/.config/iterm/dotfiles-profile.plist` (template) | **macOS only**. |

## Font

[Monaspace](https://monaspace.githubnext.com) (GitHub Next), installed as the **Monaspice Nerd Font** (Nerd Fonts renames Monaspace). It has the icons that `eza`, starship and nvim draw.

- **Neon** for code, **Radon** (handwriting style) for italics.
- **macOS**: installed by the Brewfile cask `font-monaspice-nerd-font`.
- **Linux desktop**: `install.sh` downloads it into `~/.local/share/fonts` and runs `fc-cache`. It skips this on a headless server (your local terminal draws the font).
- **Switch fonts**: change `NERD_FONT` and `NERD_FONT_FAMILY` in `install.sh`, the cask in the `Brewfile`, `font-family` and `font-family-italic` in the Ghostty config, and `Normal Font` in the iTerm template.

## Ghostty

Docs: <https://ghostty.org/docs/config>. Handy commands: `ghostty +show-config`, `ghostty +list-fonts`, `ghostty +list-themes`, `ghostty +list-keybinds`. On macOS the `ghostty` command lives inside the app bundle; `.zshrc` adds it to `PATH`.

### What the config sets

| Setting | Value | Meaning |
| --- | --- | --- |
| `font-family` / `font-family-italic` | MonaspiceNe / MonaspiceRn Nerd Font | Code font and italic font |
| `font-size` | 14 | Points |
| `config-file` | `?theme.conf` | Includes the generated theme file (`?` = no error if missing). See [theme.md](theme.md). |
| `background-opacity` | 1 | Fully opaque |
| `window-padding-x` / `y` | 8 / 6 | Pixels around the text |
| `cursor-style` | block | Block cursor |
| `mouse-hide-while-typing` | true | Hide the pointer while you type |
| `copy-on-select` | clipboard | Selecting text copies it to the system clipboard |
| `confirm-close-surface` | false | No question when closing a finished shell |
| `macos-option-as-alt` | true | **macOS only.** `Option` works as `Alt` (Alt-j/k in nvim, tmux Alt maps). |
| `macos-titlebar-style` | tabs | **macOS only.** Native tabs in the title bar |
| `shell-integration` | zsh | Force zsh integration |
| `shell-integration-features` | cursor, sudo, title, ssh-terminfo, ssh-env | See below |

Shell integration features:

- `cursor`: cursor shape at the prompt. `title`: window title updates. `sudo`: `sudo` keeps the terminfo.
- `ssh-terminfo`: when you `ssh` to a server, Ghostty installs its terminfo there (`xterm-ghostty`). If that fails, `ssh-env` falls back to `TERM=xterm-256color`. So you need no `SetEnv TERM` in `~/.ssh/config`.

### Keybinds in the config

| Keys | What it does |
| --- | --- |
| `Cmd+D` | Split right (macOS) |
| `Cmd+Shift+D` | Split down (macOS) |
| `Cmd+Shift+Enter` | Zoom the current split (macOS) |
| `Cmd+Shift+R` | Reload the config (macOS) |
| `Cmd+K` | Clear the tmux pane in a shell (does nothing in vim/nvim): sends `Ctrl+Space`, then `Ctrl+L` (macOS) |
| `Ctrl+Shift+K` | Same as `Cmd+K` (Linux, which has no Cmd key) |

On Linux, the four `cmd+` binds do nothing useful: use Ghostty's Linux defaults instead (see `ghostty +list-keybinds --default`). `Cmd+K` works with tmux's `prefix Ctrl+L` (which ignores panes running vim or nvim); without tmux, `Ctrl+L` in zsh clears the screen and the scrollback ([zsh.md](zsh.md)).

Default Ghostty keys used in these docs (not in the config): macOS `Cmd+T` new tab, `Cmd+1`...`9` go to tab, `Cmd+Shift+,` reload config. Linux `Ctrl+Shift+T` new tab, `Alt+1`...`9` or `Ctrl+PageUp/PageDown` switch tab.

### Change something

Edit `ghostty/.config/ghostty/config` in the repo, then reload with `Cmd+Shift+R` (macOS). Do not edit `theme.conf`: `theme sync` generates it. Settings only for one machine: add a second include line `config-file = ?local.conf` to the config and keep `~/.config/ghostty/local.conf` untracked (the line is not there today).

## iTerm2 (macOS only)

The `iterm` package installs a **template**: font, Option keys, terminal type, scrollback and the `Cmd+K` mapping, with no colors. `theme sync` adds the colors of the light/dark pair and writes the real Dynamic Profile `~/Library/Application Support/iTerm2/DynamicProfiles/dotfiles.plist`, named **Dotfiles**. `theme sync` runs from `install.sh`, `theme set` and `theme pick`.

Profile settings from the template:

| Setting | Value |
| --- | --- |
| Font | `MonaspiceNeNF 14` (PostScript name; find it with `mdls -name com_apple_ats_name_postscript <font file>`) |
| Ligatures | on (needed for Monaspace texture healing) |
| Left Option | Esc+ (works as Alt) |
| Right Option | normal, to type accents (Spanish) |
| Terminal type | `xterm-256color` |
| Scrollback | unlimited |
| New session folder | home |
| `Cmd+K` | sends `Ctrl+Space` + `Ctrl+L` (clear the tmux pane; nothing in vim/nvim) |

One manual step per machine: iTerm Settings > Profiles > select **Dotfiles** > Other Actions > Set as Default. The profile keeps the same Guid, so this survives every sync.

Dynamic Profiles are **read-only** in the iTerm UI. To change something, edit the template in the repo, then run `theme sync`. iTerm reloads the profile by itself. If it misses a change, quit with `Cmd+Q` and open it again.

## SSH config tips

Keep `~/.ssh/config` out of this repo (it is private). Server setup is in [server.md](server.md). Useful for every host:

```sshconfig
# ~/.ssh/config (example, not stowed)
Host *
  # Reuse one connection for many sessions
  ControlMaster auto
  # Socket file for the shared connection
  ControlPath ~/.ssh/cm-%r@%h:%p
  # Keep it open 10 minutes after the last use
  ControlPersist 10m
  # Keepalive so idle sessions do not drop
  ServerAliveInterval 30
```

For flaky networks, install `mosh` (uncomment it in the `Brewfile`): `mosh myserver` survives sleep and IP changes. Run tmux inside it.
