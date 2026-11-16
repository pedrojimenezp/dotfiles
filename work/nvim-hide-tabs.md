# nvim-hide-tabs

## Goal
Neovim shows tabs as blank space instead of `»`; trailing spaces and nbsp stay visible.

## Plan
Set `tab = "  "` in `listchars` in `nvim/.config/nvim/lua/config/options.lua`.

## Done
Set tab = "  " in listchars; tests pass.

## Where we stopped
Change done and tested.

## Next step
Merge when the user approves.

## How to test
`bash tests/run.sh`; headless nvim prints the listchars.

## Open questions
None.

Updated: 2026-11-16 by personal@Pedros-MacBook-Pro-M4
