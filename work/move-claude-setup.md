# move-claude-setup

## Goal
Claude setup logic lives in claude-config; dotfiles only clones it and calls its scripts.

## Plan
1. uninstall.sh calls claude-shared/install.sh --uninstall.
2. install.sh --with-claude: clone if missing, run pull.sh --install.
3. Drop CLAUDE_SHARED_DIR.
4. Docs and tests follow.

## Done
- Worktree and branch created.

## Where we stopped
Starting.

## Next step
Implement the plan.

## How to test
bash tests/run.sh; shellcheck install.sh uninstall.sh

## Open questions
None.

Updated: 2026-11-07 by personal@Pedros-MacBook-Pro-M4
