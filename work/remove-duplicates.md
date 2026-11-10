# remove-duplicates

## Goal
One way per task: drop git aliases `st`/`lg` (zsh `gs`/`gl` stay), tmux `prefix k`, and lazygit's review hint in docs/git.md.

## Plan
Edit git config, tmux.conf and docs; clean references; run tests/run.sh and a private-socket tmux load.

## Done
All edits and reference cleanup. tmux has no default `k` in the prefix table, so no unbind. Ghostty splits/tabs line added to docs/terminals.md.

## Where we stopped
Tests pass (18 + 3 + 58), tmux config loads, aliases confirmed.

## Next step
Review and merge.

## How to test
`tests/run.sh`; `git config -f git/.config/git/config --get-regexp alias`.

## Open questions
None.

Updated: 2026-11-10 by personal@Pedros-MacBook-Pro-M4
