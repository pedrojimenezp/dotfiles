# docs-rewrite

## Goal

Every docs topic lives in exactly one page (its owner), with short links everywhere else. Facts match master's code.

## Plan

1. Merge master; keep the rewritten docs and carry master's facts (install.sh is the source of truth).
2. One home per topic (map below): move duplicates into the owner, leave a sentence + link.
3. server.md gets "Name this server" (HOST_LABEL).
4. Check every relative link and anchor; add "Related pages" where useful.

Topic → owner:

| Topic | Owner |
| --- | --- |
| What the repo is, reading path, doc index | README.md |
| Install on macOS / Linux desktop, flags, what install.sh does, update, undo, restore a backup, per-machine files, install troubleshooting | install.md |
| Everything server-specific: laptop SSH config and tips, key forwarding, server install, naming (HOST_LABEL), daily use with tssh, updating, server troubleshooting | server.md |
| First-day tour (links only) | first-day.md |
| tmux keys, status bar, popups, plugins, SSH badge internals | tmux.md |
| Project picker | tmux-sessionizer.md |
| Shell: aliases, keys, atuin, zoxide, tssh function, ~/.zshrc.local | zsh.md |
| Neovim / Vim | nvim.md / vim.md |
| Git config, aliases, delta in lazygit/gh, ~/.config/git/local | git.md |
| Brewfile tools, starship prompt, mise, dotfiles-usage | tools.md |
| theme command and light/dark | theme.md |
| Ghostty, iTerm, font, terminal keys | terminals.md |
| Term definitions | glossary.md |
| Changing the repo: help-list notes, cheatsheet.tsv, how dotfiles-help reads sources | contributing.md |

## Done

- Merged master (conflicts resolved by keeping the rewritten pages and adding master's facts).

## Where we stopped

Merge committed; starting the dedup.

## Next step

server.md "Name this server", then dedup per area, then the link check.

## How to test

- Run the link checker (relative links and GitHub anchors in README.md and docs/*.md): 0 broken.
- `grep -rn HOST_LABEL README.md docs/`: full text only in server.md.

## Open questions

None yet.

Updated: 2026-10-30 by personal@Pedros-MacBook-Pro-M4
