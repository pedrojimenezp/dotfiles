# tmux-zen-mode

## Goal
`prefix Z` toggles zen mode: the window's panes are centered in a `@zen_width` (120) column between two empty pad panes.

## Plan
`bin/.local/bin/tmux-zen` (toggle, fit, unpad, cleanup) driven by hooks in tmux.conf; tests on a private tmux server.

## Done
- tmux-zen script, tmux.conf binding and hooks, docs/tmux.md section.
- tests/tmux_zen_test.sh (private socket, TMUX_TMPDIR safety net); cleanup retries once because the layout hook can run before a closed pane is gone.

## Where we stopped
Implemented and tested; waiting for the user to try it.

## Next step
Run `./install.sh` (or `stow --restow --no-folding bin`) so `~/.local/bin/tmux-zen` exists, reload tmux, press `prefix Z`.

## How to test
`bash tests/tmux_zen_test.sh`, then `bash tests/run.sh`.

## Open questions
None.

Updated: 2026-11-12 by personal@Pedros-MacBook-Pro-M4
