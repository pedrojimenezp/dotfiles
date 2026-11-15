# clipedit

## Goal
Edit the clipboard text in nvim before pasting (`prefix e`, or `clipedit`), with a manual `<leader>m` key that masks secrets.

## Plan
1. `bin/.local/bin/clipedit`: temp dir (700) with the clipboard in a 600 file, nvim without swap/undo/shada, `:wq` copies back with pbcopy, `:q!` leaves the clipboard.
2. Masking in `bin/.local/share/clipedit/mask.pl` (perl, stdin to stdout) and `clipedit.lua` (the buffer-local key and the line count).
3. `prefix e` popup in tmux.conf, docs/tmux.md section, tests/clipedit_test.sh.

## Done
- Script, mask.pl, clipedit.lua, tmux bind, docs, tests (70 checks) all written and passing.

## Where we stopped
Ready for review. Not tried in a real tmux client.

## Next step
Review, then merge. After merge run install.sh/stow so `clipedit` and `~/.local/share/clipedit` are linked.

## How to test
`bash tests/clipedit_test.sh` and `tests/run.sh`. By hand: copy a line with `password=x`, `prefix e`, `<space>m`, `:wq`, paste.

## Open questions
- The first word of an unquoted `key: value` is masked, not the rest of the line.

Updated: 2026-11-14 by personal@Pedros-MacBook-Pro-M4
