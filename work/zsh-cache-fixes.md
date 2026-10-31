# zsh-cache-fixes

## Goal
Fix two bugs in the `_cache_init` shell cache in `zsh/.zshrc`: upgrades not invalidating it, and the cached `mise activate zsh` PATH snapshot.

## Plan
1. Store the tool's resolved path in the cache's first line; regenerate when it differs.
2. Stop caching mise: `eval "$(mise activate zsh)"`.
3. Fix `docs/zsh.md` and `docs/install.md`.

## Done
- `_cache_init` writes `# bin=<resolved path>` as line 1 and regenerates on mismatch (read via builtin, no fork).
- mise is no longer cached.
- Docs updated; tested in a temp HOME.

## Where we stopped
All implemented and tested; ready for review.

## Next step
Review, then merge.

## How to test
`zsh -n zsh/.zshrc`; start `zsh -i` with a temp HOME and XDG_CACHE_HOME and ZDOTDIR set to `zsh/`.

## Open questions
None.

Updated: 2026-10-31 by personal@Pedros-MacBook-Pro-M4
