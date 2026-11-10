# tmux-window-picker-groups

## Goal
`prefix w` must list windows while a session group exists, and hide `_popup_*` sessions, like `prefix s`.

## Plan
Add an explicit `w` binding (`choose-tree -GZw -O name` with the popup filter) and update `docs/tmux.md`.

## Done
- Worktree and branch created.
- Added the `w` binding and updated the comment and docs.
- Verified on a private socket; `tests/run.sh` passes.

## Where we stopped
Ready to merge.

## Next step
Merge to master.

## How to test
With a group (`tmux new-session -t '=a' -s a-view`), `prefix w` lists all windows and no `_popup_*` session.

## Open questions
None.

Updated: 2026-11-10 by personal@Pedros-MacBook-Pro-M4
