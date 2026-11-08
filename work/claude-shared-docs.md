# claude-shared-docs

## Goal
Remove stale claude-shared references (legacy ~/.claude, pi links) and shorten claude-shared detail in the docs.

## Plan
Edit uninstall.sh, its test and docs/install.md. Remove --claude-accounts.

## Done
- uninstall.sh and tests/uninstall_test.sh no longer handle ~/.claude or ~/.pi/agent.
- Removed --claude-accounts (install.sh, test, install.md, server.md).
- docs/install.md: flags and uninstall step 4 shortened.

## Where we stopped
Install, uninstall and zshrc tests pass (temp HOME).

## Next step
Review and merge.

## How to test
GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 bash tests/uninstall_test.sh (also install_test.sh, zshrc_test.sh)

## Open questions
None.

Updated: 2026-11-07 by niche@Pedros-MacBook-Pro-M4
