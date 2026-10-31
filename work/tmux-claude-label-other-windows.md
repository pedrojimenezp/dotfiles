# tmux-claude-label-other-windows

## Goal
Show the Claude account marks in the tmux window list only on non-current windows.

## Plan
- Remove `@claude_window_label_current` and its use in `window-status-current-format`.
- Update the comment and `docs/tmux.md`.

## Done
- Note created.

## Where we stopped
Nothing changed yet.

## Next step
Make the edits, test on a private tmux server.

## How to test
Private server (`env -u TMUX tmux -S <temp socket> -f tmux.conf`), 200-column control-mode client, two windows with `@claude_account` panes; check the status line on each window.

## Open questions
None.

Updated: 2026-10-31 by personal@Pedros-MacBook-Pro-M4
