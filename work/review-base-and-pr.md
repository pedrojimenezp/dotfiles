# review-base-and-pr

## Goal
`review [--print] [<base>] [<dir>]` takes a base branch; new `review-pr <n>` / `review-pr --done <n>` opens a PR in a worktree and reviews it.

## Plan
1. review base arg + tests. 2. review-pr + tests. 3. docs/git.md. 4. tests/run.sh.

## Done
- review: base argument implemented.

## Where we stopped
Writing review tests.

## Next step
review_test.sh additions, then review-pr.

## How to test
`bash tests/review_test.sh`, `bash tests/review_pr_test.sh`, `tests/run.sh`.

## Open questions
None.

Updated: 2026-11-10 by personal@Pedros-MacBook-Pro-M4
