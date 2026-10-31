# Docs audit

## Goal
Make README.md and docs/*.md complete, up to date with the code, and well
organized (accurate index, one source per topic, working links and anchors).

## Plan
1. Check every page against install.sh, Brewfile, mise config, zsh, tmux, bin, nvim, git.
2. Fix stale statements; add what is missing (mise upgrade, mise self-update, tssh, completions, zsh cache).
3. Fix README index, TOCs, duplicated instructions, links and anchors.

## Done
- Work note created.
- install.md: Update section covers `mise upgrade`, mise itself (brew / self-update), zsh cache; xz-utils on desktops; installer claims accurate.
- zsh.md: completions for mise tools, tssh detach and plain ssh, cache refresh note, TOC.
- server.md: daily use (detach ends SSH, plain ssh), updates link to install.md#update.
- tools, tmux, nvim, git, glossary, migrate, terminals, sessionizer: stale or narrated lines fixed, TOCs complete.
- README index descriptions updated, cheatsheet.tsv listed.
- Link check: 0 broken links, every TOC matches its H2 headings.

## Where we stopped
Audit done; ready for review.

## Next step
Review the branch, then merge (or drop this note before merging).

## How to test
- Link check: every relative link target exists and every `#anchor` matches a heading.
- `grep -rn -i brew README.md docs/` and review each hit.

## Open questions
- None yet.

Updated: 2026-10-31 by personal@Pedros-MacBook-Pro-M4
