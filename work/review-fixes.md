# review-fixes

## Goal
Fix the 15 review findings (tests safety, uninstall, tmux, nvim, bin scripts, docs, test gaps).

## Plan
One small commit per finding group; tests/run.sh green at the end.

## Done
All 15 findings fixed (see git log); new tests: tmux_sessions, tmux_popup, dotfiles_tools; install/uninstall/review_pr tests extended; review-pr no longer drops local commits on a leftover pr-N branch (moves it only if an ancestor of the PR head, else errors).

## Where we stopped
Full suite run after the review-pr branch change.

## Next step
Report to the user.

## How to test
bash tests/run.sh

## Open questions
None.

Updated: 2026-11-11 by personal@Pedros-MacBook-Pro-M4
