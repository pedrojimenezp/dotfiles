# Light and dark themes

One command, `theme`, changes the colors of the terminal, tmux, Neovim, bat and delta together.

You'll use it to flip between light and dark, or to pick a color theme you like.

- [Quick start](#quick-start)
- [Pick a theme](#pick-a-theme)
- [Save your pick](#save-your-pick)
- [Troubleshooting](#troubleshooting)
- [Command reference](#command-reference)
- [How it works](#how-it-works)

## Quick start

| Do this | Where |
| --- | --- |
| `tt` | Shell: flip between light and dark |
| `prefix t` | tmux: the same toggle. `prefix` is `Ctrl+Space`, pressed and released first. |
| `<leader>ut` | Neovim: the same toggle (`Space` then `u t`) |
| `theme pick` | Shell: choose a different color theme |

Check it worked: `theme status` prints the mode and both picks, with `*` on the one in use:

```
mode:  auto (dark now)
light: Dayfox
dark:  TokyoNight Night  *
```

## Pick a theme

1. Run `theme pick`. [fzf](glossary.md#fzf) lists several hundred themes.
2. Move with the arrow keys. The terminal recolors at once, and the preview shows the 16 colors and sample code.
3. Press `Enter` to save the theme, or `Esc` to restore the old colors and save nothing.

`theme pick` changes the theme for the current mode. To choose the dark one while in light mode, run `theme pick dark`.

Without fzf, name the theme yourself:

```sh
theme set light "Flexoki Light"
```

## Save your pick

A pick is written to `~/.config/theme/config`. That file is a [link](glossary.md#link) into the repo, so your pick changes a tracked file. The pair is the same on every machine you install on.

If you forked the repo, commit it so your other machines get it too. Run this in the folder you cloned to:

```sh
git add theme/.config/theme/config
git commit -m "theme: use Dayfox for light"
```

If you did not fork, you can skip this. The pick still works on this machine.

## Troubleshooting

- **A window keeps old colors**: press `Cmd+Shift+R` in Ghostty (set in this config), or `Cmd+Shift+,` (Ghostty's default).
- **`theme sync` fails**: you are offline, or the name is unknown. The install continues; run `theme sync` later.
- **Unknown name**: check with `theme list | grep -i name`. In `theme set`, quote names with spaces, or write the words without quotes (they are joined).
- **A new window shows default colors for a moment**: the saved mode applies once the shell starts.
- **A tmux inside a remote tmux**: toggling from there reaches only the inner tmux.
- **Neovim colors differ a little from the terminal**: for themes without a native plugin, Neovim builds an approximation with `mini.base16`.
- **A downloaded theme looks outdated**: downloaded themes are not updated. Delete `~/.local/share/theme/themes/<name>` to fetch it again.

## Command reference

```sh
theme dark | light | auto   # set the mode (saved) and apply it
theme toggle                # flip light/dark. From auto: the opposite of macOS now
theme apply                 # apply the saved mode again
theme status                # print the mode and both picks
theme mode                  # print only the saved mode (dark, light or auto), for scripts
theme effective             # print the mode in effect (dark or light; auto resolved), for scripts
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

Options can go anywhere in the command:

| Option | Meaning |
| --- | --- |
| `--tty <path>` | Write the color codes to that terminal device instead of the current one. tmux uses it for `prefix t`. |
| `--print` | Write the codes to standard output (the default). It wins over `--tty`. Neovim uses it. |
| `--no-download` | For `theme file` and `theme apply`: look only in the cache and the Ghostty bundles, and fail fast if the theme is missing. Neovim and the shell startup use it. |

`dark`, `light`, `auto` and `toggle` apply the colors first and save the mode only if that worked. A theme that cannot be found leaves the saved mode unchanged, and the command exits non-zero.

For scripts, read `theme mode` (saved) or `theme effective` (dark or light, auto resolved): each prints exactly one word. The layout of `theme status` can change.

Environment variables (for tests): `THEME_NO_RELOAD=1` skips the Ghostty reload. `THEME_GHOSTTY_DIRS` overrides where bundled themes are searched.

## How it works

**Two settings.**

- **The theme pair** (tracked in the repo): `~/.config/theme/config` names one theme for light and one for dark.
- **The mode** (per machine): `auto`, `light` or `dark`, saved in `~/.local/state/theme`. In `auto` the terminal follows the macOS appearance. On Linux, `auto` means the terminal's own colors.

```
# ~/.config/theme/config
light = Dayfox
dark = TokyoNight Night
```

If a line is missing, the script uses `GitHub Light Default` (light) and `TokyoNight Night` (dark).

**Where themes come from.** Names come from Ghostty's collection, the [iTerm2-Color-Schemes](https://github.com/mbadolato/iTerm2-Color-Schemes) project. Lookup order:

1. The themes bundled with Ghostty (the macOS app, or `/usr/share/ghostty/themes` on Linux).
2. The script's cache, `~/.local/share/theme/themes`.
3. A download from GitHub into the cache.

So servers without Ghostty work too. They need `curl`. Without Ghostty, `theme list` uses the GitHub contents API (cached for a day) and returns at most 1000 names.

**How each tool follows.**

- **Any terminal, also over SSH**: `theme dark` and `theme light` send OSC escape codes that set the palette, background, foreground and cursor. `auto` sends the resets. Inside tmux they are wrapped (DCS passthrough, which needs `allow-passthrough on`, already set).
- **New local shells** run `theme apply --no-download` when the saved mode is dark or light, so an offline start never waits. They skip SSH sessions and tmux, where the terminal was already colored. The shell reads the mode straight from the state file instead of running `theme mode`. `<leader>ut` also uses `theme mode`.
- **Ghostty**: the tracked config has `config-file = ?theme.conf`. `theme sync` writes `~/.config/ghostty/theme.conf` with `theme = light:<light>,dark:<dark>`, so Ghostty switches with macOS by itself. Downloaded themes are copied to `~/.config/ghostty/themes`. `theme sync` also sends Ghostty a reload signal (SIGUSR2).
- **iTerm** (macOS only): `theme sync` writes the Dynamic Profile "Dotfiles" with light and dark colors. See [terminals.md](terminals.md).
- **tmux**: the status line uses palette color names, so it follows the terminal.
- **Neovim**: `background` picks the slot, and the slot's name picks the colorscheme. `TokyoNight ...` uses tokyonight.nvim, `GitHub ...` uses github-nvim-theme, and any other theme is built with `mini.base16` from the theme file. Open instances update on `<leader>ut` and when they get focus again.
- **bat and delta**: both use the `ansi` theme, which draws with the terminal's 16 colors. delta uses `detect-dark-light` for diff backgrounds.

**Generated files.** `theme sync` runs from `install.sh`, `theme set` and `theme pick`. Its output (`~/.config/ghostty/theme.conf`, `~/.config/ghostty/themes/`) is in `.gitignore`: never commit it.

The script is `bin/.local/bin/theme`, on `PATH` as `theme`. The pair lives in `theme/.config/theme/config`.

## Related pages

- [terminals.md](terminals.md): Ghostty and iTerm settings
- [tmux.md](tmux.md): `prefix t`
- [nvim.md](nvim.md): `<leader>ut`
- [glossary.md](glossary.md)
