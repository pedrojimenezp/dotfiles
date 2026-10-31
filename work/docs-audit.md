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

## Where we stopped
Starting the audit.

## Next step
Read the code and the docs; fix page by page.

## How to test
- Link check: every relative link target exists and every `#anchor` matches a heading.
- `grep -rn -i brew README.md docs/` and review each hit.

## Open questions
- None yet.

Updated: 2026-10-31 by personal@Pedros-MacBook-Pro-M4
