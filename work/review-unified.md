# review-unified

## Goal
`review -u [<base>] [<dir>]` opens Neovim with gitsigns' unified diff panel instead of diffview.

## Plan
1. Parse `-u` in `bin/.local/bin/review`; build the gitsigns command from the merge-base.
2. Color the unified view's gitsigns groups in `diff_colors.lua` (background only).
3. Docs: `docs/git.md`.
4. Tests in `tests/review_test.sh` and `tests/nvim_diff_colors_test.sh`.

## Done
- Verified headless: `diff(<mb>, nil, {diff='unified'})` lists committed and uncommitted files.

## Where we stopped
Starting the script change.

## Next step
Edit the script.

## How to test
`bash tests/review_test.sh`, `bash tests/nvim_diff_colors_test.sh`, then `bash tests/run.sh`.

## Open questions
None.

Updated: 2026-11-11 by personal@Pedros-MacBook-Pro-M4
