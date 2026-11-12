# review-pr-branch-names

## Goal
`review-pr`: for same-repo PRs, the worktree uses the PR's own branch name (not `pr-<n>`). Fork PRs keep today's behaviour.

## Plan
1. Look up headRefName, isCrossRepository, baseRefName with one `gh pr view` before creating the worktree.
2. Same-repo: local branch = head, tracking origin/<head>; folder/window = branch with `/` as `-`; reuse a worktree that already has the branch.
3. Marker `branch.<name>.reviewPr` (true = script made branch and worktree, worktree = only the worktree); `--done` honours it and refuses unpushed commits.
4. Extend tests/review_pr_test.sh; update header.

## Done
- Script rewritten (lookup, same-repo naming, reuse, markers, --done), header updated.
- tests/review_pr_test.sh extended (156 checks pass); shellcheck clean on the script.

## Where we stopped
Ready to commit and hand back.

## Next step
Review and merge.

## How to test
`bash tests/review_pr_test.sh`, `tests/run.sh`, `shellcheck bin/.local/bin/review-pr tests/review_pr_test.sh`.

## Open questions
- After a force-push on a same-repo PR, `--done` refuses (old commits are not on the new origin ref); the user resets or drops the branch by hand.
- `--done` when `gh` cannot look the PR up falls back to the fork layout (`pr-<n>`).

Updated: 2026-11-12 by niche@Pedros-MacBook-Pro-M4
