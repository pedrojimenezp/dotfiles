# audit-fixes

## Goal
Apply three approved audit fixes: resilient font step, remove the atuin cleanup, trim comments that restate code.

## Plan
1. install_font warns and continues on failure, cleans up the partial folder and temp dir.
2. Remove Step 3b2 (atuin), its tests and docs mentions.
3. Trim restating comments in zsh/.zshrc, tmux.conf, git config; dotfiles-help output must stay identical.

## Done
- Fix 1: install_font warns, removes `$dir` and the temp dir, returns 0; test added in tests/install_test.sh.

## Where we stopped
Fix 1 committed. Fix 2 next.

## Next step
Fix 2, then fix 3, then the full test run.

## How to test
Run each `tests/*_test.sh` with bash, and `python3 -I tests/*_test.py`; shellcheck install.sh, uninstall.sh and touched tests.

## Open questions
None.

Updated: 2026-11-07 by niche@Pedros-MacBook-Pro-M4
