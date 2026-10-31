# docs-existing-server-checklist

## Goal
Add an "Existing server" checklist to `docs/migrate-to-mise.md`, fix the shell-cache order, add `exec zsh` after removing Homebrew, and link it from `docs/server.md` section 7.

## Plan
1. Add the section and table of contents entry.
2. Move the cache clear before `exec zsh` and `which`.
3. Add the `exec zsh` step to macOS and Linux.
4. Link from server.md.

## Done
Added the Existing server section, moved the cache clear before `exec zsh`, added `exec zsh` after removal (macOS and Linux), linked from server.md. Anchors checked.

## Where we stopped
Docs done, ready for review.

## Next step
Review, then merge.

## How to test
Grep the headings and check every anchor resolves; read the page top to bottom.

## Open questions
None.

Updated: 2026-10-31 by personal@Pedros-MacBook-Pro-M4
