# move-claude-setup

## Goal
Claude setup logic lives in claude-config; dotfiles only clones it and calls its scripts.

## Plan
1. uninstall.sh calls claude-shared/install.sh --uninstall.
2. install.sh --with-claude: clone if missing, run pull.sh --install.
3. Drop CLAUDE_SHARED_DIR.
4. Docs and tests follow.

## Done
- uninstall.sh calls claude-shared/install.sh --uninstall; old undo code removed.
- install.sh --with-claude: clone if missing, then pull.sh --install; SSH probe removed.
- CLAUDE_SHARED_DIR removed.
- Docs and tests updated.

## Where we stopped
Done and tested.

## Next step
Review.

## How to test
bash tests/run.sh; shellcheck install.sh uninstall.sh

## Open questions
None.

Updated: 2026-11-07 by personal@Pedros-MacBook-Pro-M4
