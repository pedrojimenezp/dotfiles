# Theme

`theme` recolors the terminal, tmux, Neovim, bat and delta together. `tt`, `prefix t` and `<leader>ut` toggle light/dark; `theme pick [light|dark|nvim-light|nvim-dark]` previews themes live in fzf (only themes of the slot's brightness, or for the nvim slots only the [original Neovim themes](#original-neovim-themes) of that brightness; Ctrl-A switches to all themes and back); `theme help` lists the rest.

## Two settings

- **The pair**, tracked: `theme/.config/theme/config` names one light and one dark theme (defaults `GitHub Light Default` and `TokyoNight Night`). A pick edits this file through the link: commit it so every machine gets it.
- **A Neovim pair**, optional, in the same file: `nvim_light` and `nvim_dark`. In each mode Neovim uses its `nvim_<mode>` name when set, otherwise the pair's name. Only Neovim reads these keys; the terminal, tmux and the rest ignore them. See [Neovim only](#original-neovim-themes).
- **The mode**, per machine: `auto`, `light` or `dark` in `~/.local/state/theme`. `auto` follows macOS; on Linux it means the terminal's own colors.

`dark`, `light`, `auto` and `toggle` save the mode only if applying worked. Scripts should read `theme mode` or `theme effective` (one word each), not `theme status`.

## Where themes come from

Names are from Ghostty's collection ([iTerm2-Color-Schemes](https://github.com/mbadolato/iTerm2-Color-Schemes)). Lookup: Ghostty's bundled themes, then `~/.local/share/theme/themes`, then a GitHub download (needs `curl`), so servers without Ghostty work. Without Ghostty, `theme list` uses the GitHub API (cached a day, at most 1000 names). `theme list light` and `theme list dark` keep themes whose background has a perceived brightness (Rec. 601 luma) above or below 0.5. Names with no local file or no background are in both lists.

## How each tool follows

- **Any terminal, also over SSH:** OSC codes set the palette; `auto` sends resets. Inside tmux they're wrapped in DCS passthrough. `--tty <path>` writes to another terminal (tmux's `prefix t` uses it).
- **New local shells** run `theme apply --no-download` for a saved dark or light, so an offline start never waits. They skip SSH and tmux, where the terminal is already colored.
- **Ghostty:** `theme sync` writes `~/.config/ghostty/theme.conf` (`theme = light:<a>,dark:<b>`, so Ghostty follows macOS itself), copies downloaded themes to `~/.config/ghostty/themes`, and sends SIGUSR2 to reload.
- **iTerm2:** `theme sync` writes the Dotfiles Dynamic Profile ([terminals.md](terminals.md#iterm2)).
- **tmux:** the status line uses palette color names.
- **Neovim:** a name in the [original Neovim themes](#original-neovim-themes) loads its own colorscheme; any other name loads Dayfox (light) or Nightfox (dark). Open instances update on `<leader>ut` and on focus, including after a change to the Neovim keys.
- **bat and delta:** the `ansi` theme, so they use the terminal's 16 colors.

`theme sync` runs from `install.sh`, `theme set` and `theme pick`. Its output is generated: never edit or commit it.

## Neovim only

Keep a terminal pair and give Neovim another one. Light/dark stays shared: `theme toggle`, `<leader>ut` and macOS auto switch both.

- `theme set nvim-light <name>` and `theme set nvim-dark <name>` save the key. They change Neovim only, so nothing is regenerated or recolored.
- `theme pick nvim-light` and `theme pick nvim-dark` use the same fzf picker. The preview recolors the terminal, which goes back to normal when you finish.
- `theme set nvim-light --clear` (or `nvim-dark`) removes the key, so Neovim follows the terminal again.
- `theme status` lists the Neovim picks when they are set.

### Original Neovim themes

`nvim/.config/nvim/themes.tsv` lists the themes that have their own Neovim colorscheme: TokyoNight, GitHub, the seven Nightfox names, Kanagawa (Wave, Dragon, Lotus), Rose Pine (Rose Pine, Moon, Dawn), Catppuccin (Latte, Frappe, Macchiato, Mocha) and Cyberdream. Both the script and Neovim read that one file; each line is `name`, `colorscheme`, `light|dark` and, for Neovim-only names, `nvim`. Add a theme by adding a line (and its plugin in `lua/plugins/theme.lua`).

- `theme list nvim [light|dark]` prints the names.
- **Cyberdream** and **Cyberdream Light** are not in Ghostty's collection, so only `nvim-light` and `nvim-dark` accept them; the terminal slots refuse them. The picker previews them as a note, without recoloring the terminal.
- A name not in the list (any other Ghostty theme) makes Neovim use Dayfox in light mode and Nightfox in dark mode.

## Troubleshooting

- **A window keeps old colors:** `Cmd+Shift+R` in Ghostty.
- **`theme sync` fails:** offline or an unknown name; check with `theme list | grep -i <name>`.
- **A downloaded theme looks outdated:** downloads aren't refreshed. Delete `~/.local/share/theme/themes/<name>`.
- **Toggling in a tmux inside a remote tmux** reaches only the inner one.
- **Tests:** `THEME_NO_RELOAD=1` skips the Ghostty reload; `THEME_GHOSTTY_DIRS` overrides the bundle search.
