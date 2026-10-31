# account-folders

## Goal
Follow the restructure of the Claude config repo: accounts are `~/.claude-<name>` folders, `zsh/claude.zsh` became `claude.sh`.

## Plan
1. `install.sh --claude-accounts <a,b>` passed to the Claude installer.
2. `.zshrc` sources `claude.sh`.
3. `uninstall.sh --with-claude` handles every `~/.claude-*` folder and the new rc line.
4. Tests, then docs.

## Done
- install.sh flag and tests/install_test.sh
- .zshrc source line
- uninstall.sh and its test
- docs (install.md, zsh.md, server.md)

## Where we stopped
All steps done; no link to the private repo in the docs; only review left.

## Next step
Review, then /merge.

## How to test
`bash tests/install_test.sh && bash tests/uninstall_test.sh`

## Open questions
claude-shared's install.sh checks only ~/.zshrc.local when ~/.zshrc is a symlink, so it cannot see the dotfiles line.

Updated: 2026-10-31 by personal@mac
