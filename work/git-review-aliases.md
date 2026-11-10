# git-review-aliases

## Goal
`git wip [-s]` and `git pr [-s] [base]`: review uncommitted or branch changes, untracked files included, in delta.

## Plan
POSIX sh script `bin/.local/bin/git-changes` (stowed onto PATH with the other scripts); two thin aliases in `git/.config/git/config`; tests; docs.

## Done
Script, aliases, `tests/git_changes_test.sh` (26 checks), `docs/git.md` section, cheatsheet rows.

## Where we stopped
Committed; `tests/run.sh` result pending review.

## Next step
Review, then `/merge`.

## How to test
`bash tests/git_changes_test.sh`, `tests/run.sh`.

## Open questions
None.

Updated: 2026-11-10 by personal@Pedros-MacBook-Pro-M4
