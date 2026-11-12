# review-pr-branch-names

## Goal
`review-pr`: for same-repo PRs, the worktree uses the PR's own branch name (not `pr-<n>`). Fork PRs keep today's behaviour.

## Plan
1. Look up headRefName, isCrossRepository, baseRefName with one `gh pr view` before creating the worktree.
2. Same-repo: local branch = head, tracking origin/<head>; folder/window = branch with `/` as `-`; reuse a worktree that already has the branch.
3. Marker `branch.<name>.reviewPr` (true = script made branch and worktree, worktree = only the worktree); `--done` honours it and refuses unpushed commits.
4. Extend tests/review_pr_test.sh; update header.

## Done
- Worktree and branch created.

## Where we stopped
Starting the script change.

## Next step
Edit bin/.local/bin/review-pr, then the tests.

## How to test
`bash tests/review_pr_test.sh`, `tests/run.sh`, `shellcheck bin/.local/bin/review-pr tests/review_pr_test.sh`.

## Open questions
- `--done` when `gh` cannot look the PR up falls back to the fork layout (`pr-<n>`).

Updated: 2026-11-12 by niche@Pedros-MacBook-Pro-M4
