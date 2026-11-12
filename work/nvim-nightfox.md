# nvim-nightfox

## Goal
Nightfox family as the light/dark theme for terminal and Neovim, using the real nightfox.nvim colorscheme.

## Plan
Add the plugin, map the seven fox names in `plugin_scheme`, set the pair (Dawnfox/Nightfox), drop the nvim_* keys, verify headless, update docs.

## Done
- Plugin spec, name mapping, pair in `theme/.config/theme/config`, docs/theme.md.
- Verified headless in both backgrounds; tests/run.sh passes.
- diff_colors left unchanged (its tints are stronger than nightfox's own diff specs).

## Where we stopped
Ready for review.

## Next step
Eyeball `review` and `review -u` in light and dark, then `/merge`.

## How to test
`tests/run.sh`; open `review` and `review -u` on a repo with changes.

## Open questions
None.

Updated: 2026-11-12 by personal@Pedros-MacBook-Pro-M4
