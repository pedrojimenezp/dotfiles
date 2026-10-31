# nvim-neo-tree

## Goal
Add a neo-tree sidebar (`Space f e`) to the nvim config. Oil and Telescope stay as they are.

## Plan
1. Add neo-tree to `lua/plugins/editor.lua` with `<leader>fe` and a Files which-key group.
2. Document it in `docs/nvim.md`.
3. Install headless, check for errors, run the repo tests.

## Done
- Worktree and branch created.

## Where we stopped
Starting the plugin spec.

## Next step
Add the spec, then test.

## How to test
Headless: symlink the config into a temp XDG_CONFIG_HOME, run `Lazy! sync`, `Neotree show`, `checkhealth neo-tree`; then `bash tests/install_test.sh` and `bash tests/uninstall_test.sh`.

## Open questions
None.

Updated: 2026-10-31 by personal@Pedros-MacBook-Pro-M4
