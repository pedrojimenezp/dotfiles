# remove-dead-code

## Goal
Fix bugs and remove dead code in the dotfiles repo (audit-approved), with matching docs updates.

## Plan
1. tmux claude account label generic. 2. server.md login fix. 3. drop iTerm image paste. 4. drop stow fallback. 5. drop migration leftovers. 6. simplify uninstall.sh + test. 7. dotfiles-usage log calls + dedupe resolve loop. 8. small cleanups. 9. test runner.

## Done
Changes 1-7 done and committed (tmux labels, server.md, iTerm paste, stow fallback, migration leftovers, uninstall rewrite, usage log calls + `dotfiles-log --root`).

## Where we stopped
Change 7 committed.

## Next step
Changes 8 and 9.

## How to test
`tests/run.sh` (once added), shellcheck, bash -n.

## Open questions
None.

Updated: 2026-11-07 by personal@Pedros-MacBook-Pro-M4
