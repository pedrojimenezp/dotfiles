# markdown-in-terminal

## Goal
Read Markdown rendered in the terminal (macOS, and Linux over SSH/tmux), including Mermaid diagrams: glow, render-markdown.nvim, mermaid-ascii, with docs.

## Plan
1. glow via mise.
2. render-markdown.nvim lazy spec (treesitter parsers already listed).
3. mermaid-ascii via mise.
4. Docs: tools.md, nvim.md, cheatsheet.tsv if keys.

## Done
Nothing yet.

## Where we stopped
Starting.

## Next step
Add glow to the mise config.

## How to test
`glow -s dark docs/install.md | head`, `mermaid-ascii -f x.mmd`, headless nvim with temp XDG dirs.

## Open questions
None.

Updated: 2026-10-31 by personal@Pedros-MacBook-Pro-M4
