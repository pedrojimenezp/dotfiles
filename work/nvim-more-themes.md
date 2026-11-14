# nvim-more-themes

## Goal
Add four Neovim colorscheme plugins (Xcode, OneDark, Nova, 734) to the original Neovim themes list.

## Plan
Plugins in lua/plugins/theme.lua, rows in themes.tsv, onedark and nova setup in config/theme.lua plugin_scheme, docs and tests.

## Done
- Plugins, 20 themes.tsv rows, plugin_scheme cases, docs/theme.md, tests/nvim_themes_test.sh (new plugins plus a style-differs check).
- Headless load of every new row passes; `theme` script handles the new rows.

## Where we stopped
Ready for review and merge.

## Next step
Review, then /merge.

## How to test
`bash tests/run.sh`; plugin checks need `:Lazy! sync` first.

## Open questions
None.

Updated: 2026-11-14 by personal@Pedros-MacBook-Pro-M4
