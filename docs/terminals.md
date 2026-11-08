# Terminals

Ghostty (macOS, Linux) and iTerm2 (macOS) share the font and the [theme](theme.md).

## Font

Monaspice Nerd Font: Monaspace with Nerd Font icons; **Neon** for code, **Radon** for italics. macOS gets it from the Brewfile cask; Linux desktops from `install.sh` (into `~/.local/share/fonts`). Icons as boxes mean the terminal isn't using it.

To switch fonts, change all of these together: `NERD_FONT` and `NERD_FONT_FAMILY` in `install.sh`, the Brewfile cask, `font-family*` in the Ghostty config, and `Normal Font` in the iTerm template. iTerm wants the PostScript name (`MonaspiceNeNF`): `mdls -name com_apple_ats_name_postscript <font file>`.

## Ghostty

Config: `ghostty/.config/ghostty/config`; reload with `Cmd+Shift+R`. `ghostty +list-keybinds` and `+show-config` show the rest. Never edit `theme.conf`: `theme sync` writes it. For machine-only settings, add `config-file = ?local.conf` and keep `local.conf` untracked.

- `shell-integration-features` has `no-ssh-env` and `no-ssh-terminfo`: Ghostty's ssh wrapper left ControlMaster processes attached to tabs, which stole keystrokes and dropped sessions. So each server needs Ghostty's terminfo once ([server.md](server.md#2-on-the-server-once)).
- `Cmd+K` (Linux: `Ctrl+Shift+K`) sends `prefix Ctrl+l`, which clears the tmux pane and does nothing in vim or nvim.
- The `cmd+` binds do nothing on Linux; use Ghostty's defaults there.

## iTerm2

The `iterm` package links a profile **template** without colors. `theme sync` adds the colors and writes the Dynamic Profile **Dotfiles** to `~/Library/Application Support/iTerm2/DynamicProfiles/dotfiles.plist`.

- Once per machine: Settings > Profiles > **Dotfiles** > Other Actions > Set as Default. The Guid is fixed, so this survives syncs.
- Dynamic Profiles are read-only in the UI: edit the template, then `theme sync`. If iTerm misses it, quit with `Cmd+Q` and reopen.
- Left Option is Esc+ (Alt); right Option stays normal for accents. Ligatures are on for Monaspace texture healing.
- tmux copying needs "Applications in terminal may access clipboard" ([tmux.md](tmux.md#copying-iterm2)).

## Paste an image to a server

Claude Code on a server can't read the Mac's clipboard. Copy an image, focus a tab running `ssh`, press `Ctrl+Cmd+V`: `img-to-server` uploads it with `scp` to `/tmp/claude-img/<date>-<time>.<ext>` and pastes the path (no `Enter`). Without an image on the clipboard (text, several files, a non-image), it's a normal `Cmd+V`. macOS only; files older than a day are deleted on each upload.

### Setup, once

1. `./install.sh` installs `skhd-zig` and `pngpaste` and links `skhdrc` and the script.
2. `skhd --install-service && skhd --start-service`.
3. System Settings > Privacy & Security > **Accessibility** > turn **skhd** on (or **+** and `~/Applications/skhd.app`). Then `skhd --restart-service` if needed.
4. Delete any old **Image to server** shortcut in the Shortcuts app: it takes the same key.

### How it picks the server

1. In iTerm2, the `ssh` in the current tab (macOS asks once whether skhd may control iTerm2: **Allow**).
2. Otherwise every interactive `ssh` on the Mac, grouped by `ssh -G` host: one is used, several show a list, none shows "No ssh session found". Ghostty can't say which tab is in front, so several servers always ask.

`ssh -N/-W/-O/-f`, `ssh host cmd` without `-t`, `scp`, `git` and `mosh` don't count. The upload reuses the session's user, port, `-i`, `-J`, `-F` and ControlMaster, with `BatchMode=yes`; the host must already be in `known_hosts`.

### Troubleshooting

`img-to-server --dry-run` prints the target and commands without uploading. Logs: `~/Library/Logs/skhd.log` and `~/Library/Logs/img-to-server.log` (every command and exit code, never the clipboard).

- **Key does nothing:** `skhd --status`; check Accessibility or another app on `Ctrl+Cmd+V`.
- **Uploads but doesn't paste:** the path is on the clipboard (`Cmd+V`); re-check Accessibility and restart skhd.
- **`Permission denied (publickey)` / `Host key verification failed`:** connect once by hand.
- **Several users on one server:** `/tmp/claude-img` belongs to the first uploader; others get "Permission denied".
