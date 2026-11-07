# diffview-review

## Goal
Review an agent's changes in a feature worktree from the terminal, with go-to-definition: diffview.nvim plus a `review` script (one tmux window per repo).

## Plan
1. diffview.nvim spec (lazy-loaded) with `<leader>gd/gh/gq`.
2. `bin/.local/bin/review [--print] [<dir>]`.
3. tmux `prefix R`.
4. `tests/review_test.sh`.
5. Docs: tmux.md, nvim.md, install.md, cheatsheet.tsv.

## Done
All five steps. Tests, shellcheck and a private-socket tmux run (open, then select existing window) pass.

## Where we stopped
Ready for review. Nothing pushed or merged.

## Next step
Review the branch, then /merge.

## How to test
`bash tests/review_test.sh`; in tmux, `prefix R` in a feature folder; `review --print <dir>`.

## Open questions
- lazy-lock.json is not tracked in this repo, so it was not added.

Updated: 2026-11-07 by niche@Pedros-MacBook-Pro-M4
