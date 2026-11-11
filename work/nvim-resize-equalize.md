# nvim-resize-equalize

## Goal
Rebalance nvim windows in every tab when nvim is resized; `winfixwidth` windows keep their width.

## Plan
VimResized autocmd in autocmds.lua running `tabdo wincmd =`, then restore the tab. Headless test, one doc line.

## Done
Autocmd, tests/nvim_resize_test.sh, docs/nvim.md line.

## Where we stopped
Done; all tests pass. Ready for review.

## Next step
Review, then /merge.

## How to test
`bash tests/nvim_resize_test.sh`

## Open questions
None.

Updated: 2026-11-11 by personal@Pedros-MacBook-Pro-M4
