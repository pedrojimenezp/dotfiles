# nvim-audit-cleanup

## Goal
Apply the agreed Neovim audit changes: built-in gr* LSP keys, gopls staticcheck off, neo-tree replaces oil, one Mason list, dead settings removed, key moves, more parsers, jsonls and yamlls with SchemaStore.

## Plan
Edit lsp.lua, editor.lua, options.lua, keymaps.lua, treesitter.lua and docs/nvim.md; test headless; run tests/run.sh.

## Done
All edits and docs; headless checks and tests/run.sh pass.

## Where we stopped
Finished; ready for review.

## Next step
Review and merge.

## How to test
Headless nvim with XDG_CONFIG_HOME pointing at a symlink to nvim/.config/nvim; `bash tests/run.sh`.

## Open questions
None.

Updated: 2026-11-13 by personal@Pedros-MacBook-Pro-M4
