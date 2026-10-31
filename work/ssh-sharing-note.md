# ssh-sharing-note

## Goal
Tell users that after `chsh`, an open SSH shared connection (ControlMaster) keeps the old login shell; `ssh -O exit <host>` fixes it.

## Plan
One-line hint in uninstall.sh and install.sh, test in tests/uninstall_test.sh, notes in docs/server.md and docs/install.md.

## Done
All edits above; checks run (see Where we stopped).

## Where we stopped
Ready for review.

## Next step
Review and merge.

## How to test
`for t in tests/*.sh; do bash "$t"; done`, `python3 tests/iterm_image_paste_test.py`, `shellcheck install.sh uninstall.sh`.

## Open questions
None.

Updated: 2026-10-31 by personal@Pedros-MacBook-Pro-M4
