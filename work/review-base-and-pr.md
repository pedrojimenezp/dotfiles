# review-base-and-pr

## Goal
`review [--print] [<base>] [<dir>]` takes a base branch; new `review-pr <n>` / `review-pr --done <n>` opens a PR in a worktree and reviews it.

## Plan
1. review base arg + tests. 2. review-pr + tests. 3. docs/git.md. 4. tests/run.sh.

## Done
- review base argument + tests (commit 1).
- review-pr script, tests/review_pr_test.sh, docs/git.md rewritten.

## Where we stopped
All implemented; full tests/run.sh then final commit.

## Next step
Report to the user; stow bin may need a re-link for review-pr.

## How to test
`bash tests/review_test.sh`, `bash tests/review_pr_test.sh`, `tests/run.sh`.

## Open questions
None.

Updated: 2026-11-10 by personal@Pedros-MacBook-Pro-M4
