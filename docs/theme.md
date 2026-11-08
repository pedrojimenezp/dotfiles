# Theme

`theme` recolors the terminal, tmux, Neovim, bat and delta together. `tt`, `prefix t` and `<leader>ut` toggle light/dark; `theme pick [light|dark]` previews themes live in fzf; `theme help` lists the rest.

## Two settings

- **The pair**, tracked: `theme/.config/theme/config` names one light and one dark theme (defaults `GitHub Light Default` and `TokyoNight Night`). A pick edits this file through the link: commit it so every machine gets it.
- **The mode**, per machine: `auto`, `light` or `dark` in `~/.local/state/theme`. `auto` follows macOS; on Linux it means the terminal's own colors.

`dark`, `light`, `auto` and `toggle` save the mode only if applying worked. Scripts should read `theme mode` or `theme effective` (one word each), not `theme status`.

## Where themes come from

Names are from Ghostty's collection ([iTerm2-Color-Schemes](https://github.com/mbadolato/iTerm2-Color-Schemes)). Lookup: Ghostty's bundled themes, then `~/.local/share/theme/themes`, then a GitHub download (needs `curl`), so servers without Ghostty work. Without Ghostty, `theme list` uses the GitHub API (cached a day, at most 1000 names).

## How each tool follows

- **Any terminal, also over SSH:** OSC codes set the palette; `auto` sends resets. Inside tmux they're wrapped in DCS passthrough. `--tty <path>` writes to another terminal (tmux's `prefix t` uses it).
- **New local shells** run `theme apply --no-download` for a saved dark or light, so an offline start never waits. They skip SSH and tmux, where the terminal is already colored.
- **Ghostty:** `theme sync` writes `~/.config/ghostty/theme.conf` (`theme = light:<a>,dark:<b>`, so Ghostty follows macOS itself), copies downloaded themes to `~/.config/ghostty/themes`, and sends SIGUSR2 to reload.
- **iTerm2:** `theme sync` writes the Dotfiles Dynamic Profile ([terminals.md](terminals.md#iterm2)).
- **tmux:** the status line uses palette color names.
- **Neovim:** `TokyoNight ...` uses tokyonight.nvim, `GitHub ...` github-nvim-theme, anything else is built with `mini.base16` from the theme file (close, not exact). Open instances update on `<leader>ut` and on focus.
- **bat and delta:** the `ansi` theme, so they use the terminal's 16 colors.

`theme sync` runs from `install.sh`, `theme set` and `theme pick`. Its output is generated: never edit or commit it.

## Troubleshooting

- **A window keeps old colors:** `Cmd+Shift+R` in Ghostty.
- **`theme sync` fails:** offline or an unknown name; check with `theme list | grep -i <name>`.
- **A downloaded theme looks outdated:** downloads aren't refreshed. Delete `~/.local/share/theme/themes/<name>`.
- **Toggling in a tmux inside a remote tmux** reaches only the inner one.
- **Tests:** `THEME_NO_RELOAD=1` skips the Ghostty reload; `THEME_GHOSTTY_DIRS` overrides the bundle search.
