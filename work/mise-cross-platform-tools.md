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
- Steps 1-3: mise config (all tools verified on macOS arm64 and Linux x64; btop is Linux-only in mise, so macOS keeps it in the Brewfile; tmux and tmux-fingers also come from mise), zsh plugin clones, install.sh and .zshrc changes, dotfiles-usage.
- Docker (ubuntu:24.04 amd64 and arm64, user without sudo) passes; missing-package message verified.
- Docs written: server.md (Several users), install.md, tools.md, zsh.md, tmux.md, nvim.md, README, migrate-to-mise.md.
- tmux-fingers limited to macos-arm64 and linux-x64 (upstream builds only those).

## Where we stopped
All steps done; waiting for review.

## Next step
Review, then /merge.

## How to test
`shellcheck install.sh`, `zsh -n zsh/.zshrc`, `./install.sh --dry-run`, then an ubuntu:24.04 Docker run as a non-sudo user.

## Open questions
- tmux now comes from mise on both OSes (not in the Brewfile as planned), since apt's tmux is older than 3.5.

Updated: 2026-10-31 by personal@Pedros-MacBook-Pro-M4
