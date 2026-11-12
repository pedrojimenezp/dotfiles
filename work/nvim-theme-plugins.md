# nvim-theme-plugins

## Goal
Add Kanagawa, Cyberdream, Rose Pine and Catppuccin to Neovim, with one list of original Neovim themes (nvim/.config/nvim/themes.tsv) read by the `theme` script and config/theme.lua. No mini.base16: unlisted names use Dayfox/Nightfox.

## Plan
Plugins, list file, theme.lua mapping, script (list nvim, pick, Neovim-only names), tests, docs.

## Done
All of the above; tests/run.sh passes (except unrelated skips).

## Where we stopped
Ready for review.

## Next step
Review, then /merge.

## How to test
`tests/run.sh`; nvim tests need plugins installed under XDG_DATA_HOME (`nvim --headless "+Lazy! install" +qa` in a temp XDG).

## Open questions
None.

Updated: 2026-11-12 by personal@Pedros-MacBook-Pro-M4
