# tmux-three-columns

## Goal
`prefix T` adds a full-height shell pane on each side of the window; the center keeps `@zen_width`.

## Plan
`columns` command in `tmux-zen` (reuses `zen_width` and `pad_width`), bind in tmux.conf, docs, tests.

## Done
- `tmux-zen columns <window id>`, `prefix T` bind, docs/tmux.md section, tests in tests/tmux_zen_test.sh.
- tests/run.sh passes.

## Where we stopped
Implementation complete; not merged.

## Next step
Review, then `/merge`.

## How to test
`bash tests/tmux_zen_test.sh` and `bash tests/run.sh`. By hand: window of 240+ columns, `prefix T`.

## Open questions
None.

Updated: 2026-11-14 by personal@Pedros-MacBook-Pro-M4
