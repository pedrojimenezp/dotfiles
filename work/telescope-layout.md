# telescope-layout

## Goal
Telescope uses more screen space: wider picker, 50/50 preview, file name shown first so long paths stay readable.

## Plan
Edit `defaults` in `nvim/.config/nvim/lua/plugins/telescope.lua`: flex layout (flip at 120 columns), width function (0.95 under 180 columns, else 0.8), height 0.95, `preview_width = 0.5`, `path_display = { "filename_first" }`.

## Done
- Implemented the config change; checked in headless nvim: width 158 -> 150, 200 -> 160, 100 -> 95 columns; flips to vertical at 100.

## Where we stopped
Checks done; ready to merge.

## Next step
Merge when approved.

## How to test
Open nvim, `<leader>sf` in a repo with long paths; resize the window across 120 and 180 columns.

## Open questions
None.

Updated: 2026-11-13 by personal@Pedros-MacBook-Pro-M4
