# account-folders

## Goal
Follow the claude-config restructure: accounts are `~/.claude-<name>` folders, `zsh/claude.zsh` became `claude.sh`.

## Plan
1. `install.sh --claude-accounts <a,b>` passed to the Claude installer.
2. `.zshrc` sources `claude.sh`.
3. `uninstall.sh --with-claude` handles every `~/.claude-*` folder and the new rc line.
4. Tests, then docs.

## Done
- install.sh flag and tests/install_test.sh
- .zshrc source line
- uninstall.sh and its test

## Where we stopped
Docs (docs/install.md, README, zsh.md) still to do.

## Next step
Update docs, run all tests.

## How to test
`bash tests/install_test.sh && bash tests/uninstall_test.sh`

## Open questions
claude-shared's install.sh checks only ~/.zshrc.local when ~/.zshrc is a symlink, so it cannot see the dotfiles line.

Updated: 2026-10-31 by personal@mac
