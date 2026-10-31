# nvim-neo-tree

## Goal
Add a neo-tree sidebar (`Space f e`) to the nvim config. Oil and Telescope stay as they are.

## Plan
1. Add neo-tree to `lua/plugins/editor.lua` with `<leader>fe` and a Files which-key group.
2. Document it in `docs/nvim.md`.
3. Install headless, check for errors, run the repo tests.

## Done
- Worktree and branch created.
- Neo-tree spec, `<leader>fe`, Files which-key group, docs, lazy-lock.json (later removed: the live lockfile is not in the repo).
- Unmapped `<space>` in the tree window so Space stays the leader.
- Headless checks, checkhealth and repo tests pass.

## Where we stopped
Implementation done and committed; waiting for review.

## Next step
Review in a real terminal, then `/merge`.

## How to test
Headless: symlink the config into a temp XDG_CONFIG_HOME, run `Lazy! sync`, `Neotree show`, `checkhealth neo-tree`; then `bash tests/install_test.sh` and `bash tests/uninstall_test.sh`.

## Open questions
None.

Updated: 2026-10-31 by personal@Pedros-MacBook-Pro-M4
