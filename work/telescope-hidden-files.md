# telescope-hidden-files

## Goal
Telescope `find_files` (`<leader>sf`) lists hidden files, so dot-folders show up.

## Plan
Add `pickers = { find_files = { hidden = true } }` to the telescope setup.

## Done
Setting added in `nvim/.config/nvim/lua/plugins/telescope.lua`.

## Where we stopped
Verified: nvim tests pass, headless check shows pickers.find_files.hidden = true.

## Next step
Merge.

## How to test
Open nvim in the repo, `<leader>sf`, search for a file under `nvim/.config/nvim/`.

## Open questions
None.

Updated: 2026-11-13 by personal@Pedros-MacBook-Pro-M4
