# markdown-in-terminal

## Goal
Read Markdown rendered in the terminal (macOS, and Linux over SSH/tmux), including Mermaid diagrams: glow, render-markdown.nvim, mermaid-ascii, with docs.

## Plan
1. glow via mise.
2. render-markdown.nvim lazy spec (treesitter parsers already listed).
3. mermaid-ascii via mise.
4. Docs: tools.md, nvim.md, cheatsheet.tsv if keys.

## Done
- glow and mermaid-ascii in the mise config (aqua backend, all platforms), tested.
- nvim/lua/plugins/markdown.lua (render-markdown.nvim, `<leader>um`), headless test OK.
- Docs: tools.md, nvim.md, cheatsheet.tsv.

## Where we stopped
All steps done; waiting for review.

## Next step
Review, then /merge.

## How to test
`glow -s dark docs/install.md | head`, `mermaid-ascii -f x.mmd`, headless nvim with temp XDG dirs.

## Open questions
None.

Updated: 2026-10-31 by personal@Pedros-MacBook-Pro-M4
