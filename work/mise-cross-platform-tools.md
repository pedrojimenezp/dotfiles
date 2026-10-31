# mise-cross-platform-tools

## Goal
Reuse as much as possible across macOS and Linux: cross-platform tools first, platform-specific only where none exists. CLI tools move from Homebrew to mise, so each Linux user installs tools in their own home with no sudo and no shared Homebrew. The admin only installs system packages with apt.

## Plan
1. CLI tools to mise (both OSes); verify each resolves with prebuilt binaries.
2. zsh plugins as git clones in `~/.local/share/zsh-plugins`.
3. Platform parts: short Brewfile on macOS; Linux needs no Homebrew, prints the apt line, installs mise per user.
4. Docs (server.md "Several users", install, tools, zsh, README) and `dotfiles-usage`.
5. Cleanup docs for macOS and Linux (migrate-to-mise).

## Done
- Branch and note created.

## Where we stopped
Starting step 1.

## Next step
Add the tools to the mise config and verify them.

## How to test
`shellcheck install.sh`, `zsh -n zsh/.zshrc`, `./install.sh --dry-run`, then an ubuntu:24.04 Docker run as a non-sudo user.

## Open questions
None yet.

Updated: 2026-10-31 by personal@Pedros-MacBook-Pro-M4
