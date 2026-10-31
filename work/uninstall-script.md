# uninstall-script

## Goal
Add `uninstall.sh` that undoes `install.sh` on macOS (bash 3.2), Linux desktop and Linux server, with tests and docs.

## Plan
1. Write `uninstall.sh` (flags: --dry-run --yes --with-claude --keep-repo).
2. Write `tests/uninstall_test.sh` (temp HOME).
3. Rewrite "Undo or uninstall" in docs/install.md; link from docs/server.md and README.

## Done
- Worktree and branch created; install.sh and claude-shared/install.sh read.

## Where we stopped
About to write uninstall.sh.

## Next step
Write uninstall.sh.

## How to test
`/bin/bash tests/uninstall_test.sh`

## Open questions
None.

Updated: 2026-10-31 by personal@Pedros-MacBook-Pro-M4
