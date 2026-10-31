# server-timezone-docs

## Goal
Document setting the time zone on a server (TZ in ~/.zshrc.local) next to the server-name section.

## Plan
Add "Set the time zone" under section 4 of docs/server.md; mention it in step 3; add a line to docs/zsh.md.

## Done
- docs/server.md subsection and step 3 text; docs/zsh.md list item.
- Verified: tmux status clock ignores set-environment TZ; only a restart changes it.

## Where we stopped
Docs written and committed. No docs check exists in the repo.

## Next step
Review, then merge.

## How to test
Read docs/server.md section 4; check the anchor #set-the-time-zone from docs/zsh.md.

## Open questions
None. cheatsheet.tsv has no HOST_LABEL row, so no row added.

Updated: 2026-10-30 by personal@Pedros-MacBook-Pro-M4
