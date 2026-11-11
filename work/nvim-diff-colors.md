# nvim-diff-colors

## Goal
Neovim diffs (diffview.nvim) look like GitHub's split view with every colorscheme: background-only tints, syntax colors kept, blank filler lines.

## Plan
- `config/diff_colors.lua`: defines background-only Diff groups after every colorscheme load.
- diffview `hooks.diff_buf_win_enter` sets a per-window `winhighlight` (old side red, new side green).
- `fillchars` diff set to a blank.
- Test in `tests/nvim_diff_colors_test.sh`; short section in `docs/git.md`.

## Done
- Worktree and note created.
- `config/diff_colors.lua`, hooked into `theme.lua` and the diffview spec; `tests/nvim_diff_colors_test.sh` passes; `docs/git.md` section; `tests/run.sh` all passed.

## Where we stopped
Implementation, docs and tests done.

## Next step
Review and merge.

## How to test
`bash tests/nvim_diff_colors_test.sh`

## Open questions
None.

Updated: 2026-11-10 by personal@Pedros-MacBook-Pro-M4
