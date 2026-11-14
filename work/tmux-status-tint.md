# tmux-status-tint

## Goal
Soft theme-aware tmux status bar: terminal bg blended toward fg (8% dark, 6% light), recomputed by `theme` on every apply.

## Plan
- `theme`: blend, save `~/.local/state/theme-tmux.conf`, `tmux set -g status-style` on $TMUX server.
- `tmux.conf`: `source-file -q` the file after the default status-style.
- Docs and tests.

## Done
- Blend + persistence in `apply_state`; tmux.conf sourcing; docs/theme.md, docs/tmux.md; tests (blend values, file, private server).

## Where we stopped
Implemented and tested; waiting for review.

## Next step
Review, then `/merge`.

## How to test
`bash tests/run.sh`; `bash tests/theme_test.sh`.

## Open questions
- `auto` removes the tint (terminal colors unknown); macOS auto could use the system appearance instead.

Updated: 2026-11-14 by personal@Pedros-MacBook-Pro-M4
