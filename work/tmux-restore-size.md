# tmux-restore-size

## Goal
After tmux-resurrect restores, every window follows the terminal size again.

## Plan
Post-restore hook runs `tmux-fit-windows` after the popup cleanup.

## Done
- Root cause found: windows in a session with no attached client keep the saved layout size (140x78) while the client is 282x79; they resize only when selected.
- `resize-window -A` alone is wrong there (resets to the session default size); `set -wu window-size` alone changes nothing.
- `bin/.local/bin/tmux-fit-windows`: sizes every window to the latest client's session window size, then unsets window-size. No-op without a client.
- Hook in tmux.conf, line in docs/tmux.md, tests/tmux_fit_windows_test.sh.

## Where we stopped
Finished; waiting for review.

## Next step
Review and merge.

## How to test
`bash tests/tmux_fit_windows_test.sh`, `bash tests/run.sh`

## Open questions
None.

Updated: 2026-11-12 by personal@Pedros-MacBook-Pro-M4
