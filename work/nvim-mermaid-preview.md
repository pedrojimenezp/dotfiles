# nvim-mermaid-preview

## Goal
`<leader>md` in a Markdown buffer renders the ```mermaid block under the cursor as text in a float, using `mermaid-ascii`.

## Plan
1. `lua/config/mermaid.lua`: block lookup by scanning fences, float, preview.
2. Key in `lua/plugins/markdown.lua`; which-key group `m` in `editor.lua`.
3. Test in `tests/nvim_mermaid_test.sh`; docs in `docs/nvim.md` and `docs/cheatsheet.tsv`.

## Done
All three steps. The new test passes.

## Where we stopped
Committed on the branch, not pushed or merged.

## Next step
Try `<leader>md` by hand in a real nvim, then `/merge`.

## How to test
`bash tests/nvim_mermaid_test.sh`, then `tests/run.sh`. By hand: open a `.md` with a mermaid block, press `<leader>md` on a fence line and inside it.

## Open questions
None.

Updated: 2026-11-15 by personal@Pedros-MacBook-Pro-M4
