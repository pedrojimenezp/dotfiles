# tmux-session-picker-groups

## Goal
`prefix s` must list sessions while a session group exists (tmux 3.7 shows an empty list without `choose-tree -G`).

## Plan
Add `-G` to the `s` binding, comment why, document the picker and how to open one session from two terminals.

## Done
- Worktree and branch created.
- Added `-G` and a comment to the `s` binding; documented it and the two-terminal view in `docs/tmux.md`.
- Parse-only check of `tmux.conf` passed on a private socket.

## Where we stopped
Ready to merge.

## Next step
Merge to master.

## How to test
In a session with a group (`tmux new-session -t '=a' -s a-view`), press `prefix s` from either: all sessions are listed.

## Open questions
None.

Updated: 2026-11-08 by personal@Pedros-MacBook-Pro-M4
