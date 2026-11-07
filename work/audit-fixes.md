# audit-fixes

## Goal
Apply three approved audit fixes: resilient font step, remove the old-tool cleanup, trim comments that restate code.

## Plan
1. install_font warns and continues on failure, cleans up the partial folder and temp dir.
2. Remove Step 3b2 (old tool cleanup), its tests and docs mentions.
3. Trim restating comments in zsh/.zshrc, tmux.conf, git config; dotfiles-help output must stay identical.

## Done
- Fix 1: install_font warns, removes `$dir` and the temp dir, returns 0; test added in tests/install_test.sh.
- Fix 2: removed Step 3b2, its test block, the uninstall data path and its test lines, and the doc mentions; refreshed the brew uninstall list in docs/migrate-to-mise.md.
- Fix 3: trimmed restating comments in .zshrc, tmux.conf and git config; dropped delta's default `side-by-side = false`. dotfiles-help --list, tmux show/list-keys and git config --list verified identical.

## Where we stopped
All three fixes done and committed; full test run passed.

## Next step
Review, then merge (not pushed).

## How to test
Run each `tests/*_test.sh` with bash, and `python3 -I tests/*_test.py`; shellcheck install.sh, uninstall.sh and touched tests.

## Open questions
None.

Updated: 2026-11-07 by niche@Pedros-MacBook-Pro-M4
