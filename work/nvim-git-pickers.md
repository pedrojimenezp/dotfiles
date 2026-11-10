# nvim-git-pickers

## Goal
Remove the telescope `<leader>gc` / `<leader>gb` keymaps (lazygit and diffview cover them); document why oil and neo-tree coexist; document `tt` / `lg`.

## Plan
1. Remove the two keymaps and any references.
2. Extend the oil/neo-tree bullet in docs/nvim.md.
3. Add a `tt` / `lg` line to docs/zsh.md.
4. Run tests and an nvim headless load.

## Done
All three changes made; no other references to the keymaps existed.

## Where we stopped
Tests pass.

## Next step
Review, then merge.

## How to test
`tests/run.sh`; `XDG_CONFIG_HOME=<worktree>/nvim/.config nvim --headless "+lua require('lazy').load({plugins={'telescope.nvim'}})" +qa`

## Open questions
None.

Updated: 2026-11-10 by personal@Pedros-MacBook-Pro-M4
