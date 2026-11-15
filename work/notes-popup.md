# notes-popup

## Goal
Terminal notes workflow: `prefix m` popup with an fzf picker over `~/notes` (`$NOTES_DIR`), and `note` quick capture.

## Plan
1. `notes` script (picker, search, create, nvim without swap/undo) and `note` capture.
2. `notes` kind in `tmux-popup`, `prefix m` bind with `-N`.
3. Tests, docs in docs/tmux.md.

## Done
- notes picker, note capture, notes popup kind, tests, docs.
- One global `_popup_notes` session (cleanup keeps it, a second open detaches the first with attach -d).
- Picker refreshes on reattach: client-attached hook sends F5 only while @notes_view is picker.

## Where we stopped
Ready for review. Not checked in a real tmux client with display-popup.

## Next step
Review, then `/merge`. Remove this note before merging if the repo should not keep it.

## How to test
`bash tests/notes_test.sh`, `tests/run.sh`; by hand: `prefix m`, Esc, `prefix m` again.

## Open questions
- None.

Updated: 2026-11-14 by personal@Pedros-MacBook-Pro-M4
