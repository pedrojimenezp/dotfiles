# nvim-no-italics

## Goal
Neovim shows no italics in any colorscheme, except groups for italic document text (names containing "italic" or "emphasis").

## Plan
1. Rule in `config/theme.lua`: a ColorScheme autocmd plus a call after `M.load()`.
2. Remove the rose-pine `opts` block from `plugins/theme.lua`.
3. Check in `tests/nvim_themes_test.sh`; one line in `docs/theme.md`.

## Done
- Worktree and note created.
- Rule in config/theme.lua, rose-pine opts removed, test check, docs line.
- Test fails without the rule; tests/run.sh passes with it.

## Where we stopped
All done; ready for review.

## Next step
Review and merge.

## How to test
`bash tests/run.sh`

## Open questions
None.

Updated: 2026-11-16 by personal@Pedros-MacBook-Pro-M4
