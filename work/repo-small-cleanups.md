# repo-small-cleanups

## Goal
Batch of small agreed cleanups (items 1-3, 6, 7, 11, 12, 14, 16).

## Plan
One commit per group: docs fixes, dotfiles-help rows, realpath, zsh/misc cleanups, doc deduplication.

## Done
All items done and committed; review fixes applied (HISTFILE stays plain in .zshrc, set it in ~/.zshrc.local; Internal marker is a contract). Tests pass.

## Where we stopped
Finished; ready for review and merge.

## Next step
Review the branch, then /merge.

## How to test
`bash tests/run.sh`; `bin/.local/bin/dotfiles-help --list`.

## Open questions
None.

Updated: 2026-11-14 by personal@Pedros-MacBook-Pro-M4
