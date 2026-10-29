# Light and dark themes

One command, `theme`, changes the colors of the terminal, tmux, Neovim, bat and delta together. Script: `bin/.local/bin/theme` (on `PATH` as `theme`). Config: `theme/.config/theme/config`.

## Two settings

- **The theme pair** (tracked in the repo): `~/.config/theme/config` names one theme for light and one for dark. Every machine gets the same pair.
- **The mode** (per machine): `auto`, `light` or `dark`, saved in `~/.local/state/theme`. In `auto` the terminal follows the macOS appearance. On Linux, `auto` means the terminal's own colors.

```
# ~/.config/theme/config
light = Dayfox
dark = TokyoNight Night
```

If a line is missing, the script uses `GitHub Light Default` (light) and `TokyoNight Night` (dark).

Theme names come from Ghostty's collection (several hundred themes, the [iTerm2-Color-Schemes](https://github.com/mbadolato/iTerm2-Color-Schemes) project). Lookup order: the script's cache (`~/.local/share/theme/themes`), the themes bundled with Ghostty (the macOS app, or `/usr/share/ghostty/themes` on Linux), then a download from GitHub into the cache. So servers without Ghostty work too (they need `curl`).

## Commands

```sh
theme dark | light | auto   # set the mode (saved) and apply it
theme toggle                # flip light/dark. From auto: the opposite of macOS now
theme apply                 # apply the saved mode again
theme status                # print the mode and both picks
theme mode                  # print only the saved mode (dark, light or auto), for scripts
theme pick                  # choose a theme for the current mode (fzf, live preview)
theme pick dark             # choose the dark theme, even in light mode
theme set light "Flexoki Light"   # save a theme without fzf, then sync and apply
theme list                  # print every theme name
theme file "Nord"           # print the path of a theme file (downloads it if needed)
theme file --no-download "Nord"   # same, but only cache and Ghostty bundles: fails fast offline
theme sync                  # rewrite the Ghostty and iTerm files from the pair
theme help                  # usage (also -h, --help)
tt                          # shell alias for: theme toggle
```

Options (can go anywhere in the command):

- `--tty <path>`: write the color codes to that terminal device instead of the current one. tmux uses it for `prefix t`.
- `--print`: write the codes to standard output (the default). It wins over `--tty`. Neovim uses it.
- `--no-download`: for `theme file` and `theme apply`, look only in the cache and the Ghostty bundles and fail fast when the theme is missing, instead of waiting on curl. Neovim and the shell startup use it; if the theme is not there yet, it falls back as for an unknown theme until `theme set`, `pick` or `sync` downloads it.

`dark`, `light`, `auto` and `toggle` apply the colors first and save the mode only if that worked, so a theme that cannot be found leaves the saved mode unchanged (and the command exits non-zero).

Scripts should read `theme mode`: it prints exactly one word. `theme status` is for people and its layout can change. `<leader>ut` uses `theme mode`; the shell startup reads the state file directly to save a process.

`theme status` looks like this (`*` marks the one in use):

```
mode:  auto (dark now)
light: Dayfox
dark:  TokyoNight Night  *
```

Keys: `prefix t` in tmux and `<leader>ut` in Neovim (`Space u t`) toggle the mode.

## Pick a theme

1. Run `theme pick`. fzf lists all themes.
2. Move with the arrow keys. The terminal recolors at once, and the preview shows the 16 colors and sample code.
3. `Enter` saves the name in `~/.config/theme/config`, runs `theme sync` and applies it. `Esc` restores the old colors and saves nothing.

Without fzf, use `theme set light NAME` or `theme set dark NAME`.

**Commit your pick.** `~/.config/theme/config` is a link into the repo, so a pick changes a tracked file:

```sh
cd ~/projects/personal/dotfiles
git add theme/.config/theme/config
git commit -m "theme: use Dayfox for light"
```

## How each tool follows

- **Any terminal, also over SSH**: `theme dark` / `light` send OSC escape codes that set the palette, background, foreground and cursor from the theme file. `auto` sends the resets. Inside tmux they are wrapped (DCS passthrough, needs `allow-passthrough on`, already set). New local shells run `theme apply --no-download` (so an offline start never waits) when the saved mode is dark or light (not over SSH, and not inside tmux: the terminal that started tmux was already colored). The shell reads the mode straight from the state file, without running `theme mode`.
- **Ghostty**: the tracked config has `config-file = ?theme.conf`. `theme sync` writes `~/.config/ghostty/theme.conf` with `theme = light:<light>,dark:<dark>`, so Ghostty switches with macOS by itself. Downloaded themes are copied to `~/.config/ghostty/themes`. `theme sync` also sends Ghostty a reload signal (SIGUSR2). If a window keeps old colors: `Cmd+Shift+R` (set in this config) or `Cmd+Shift+,` (default).
- **iTerm** (macOS only): `theme sync` writes the Dynamic Profile "Dotfiles" with light and dark colors. See [terminals.md](terminals.md).
- **tmux**: the status line uses palette color names, so it follows the terminal.
- **Neovim**: `background` picks the slot, and the slot's name picks the colorscheme: `TokyoNight ...` uses tokyonight.nvim, `GitHub ...` uses github-nvim-theme, any other theme is built with `mini.base16` from the theme file. Open instances update on `<leader>ut` and when they get focus again.
- **bat and delta**: both use the `ansi` theme, which draws with the terminal's 16 colors. delta uses `detect-dark-light` for diff backgrounds.

`theme sync` runs in `install.sh`, `theme set` and `theme pick`. The generated files (`~/.config/ghostty/theme.conf`, `~/.config/ghostty/themes/`) are in `.gitignore`: never commit them.

## Limits and troubleshooting

- A new window shows the terminal's default colors for a moment before the saved mode applies.
- A tmux inside a remote tmux is not wrapped twice, so toggling from there reaches only the inner tmux.
- `theme list` without Ghostty uses the GitHub contents API (cached for a day) and returns at most 1000 names.
- Downloaded themes are not updated. Delete `~/.local/share/theme/themes/<name>` to fetch again.
- Neovim's `mini.base16` fallback is an approximation of the terminal theme.
- `theme sync` fails offline or with an unknown name. The install continues; run `theme sync` later.
- Unknown name: check with `theme list | grep -i name`. Names with spaces need quotes in `theme set`, or you can write the words without quotes (they are joined).
- Environment variables (for tests): `THEME_NO_RELOAD=1` skips the Ghostty reload; `THEME_GHOSTTY_DIRS` overrides where bundled themes are searched.
