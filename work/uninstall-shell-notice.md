# uninstall-shell-notice

## Goal
After `uninstall.sh`, tell the user the open terminal still runs removed hooks (`exec bash`), and warn about zsh's new-user menu when `~/.zshrc` is gone.

## Plan
1. Add a final notice and a zsh-menu line to the summary in `uninstall.sh`.
2. Update `docs/install.md` and `tests/uninstall_test.sh`.
3. Run all tests and shellcheck.

## Done
- Notice, menu line, docs and tests written; tests and shellcheck pass.

## Where we stopped
Ready for review.

## Next step
Review, then merge.

## How to test
`for t in tests/*.sh; do bash "$t"; done; python3 tests/iterm_image_paste_test.py; shellcheck uninstall.sh`

## Open questions
None.

Updated: 2026-10-31 by personal@Pedros-MacBook-Pro-M4
