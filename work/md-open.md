# md-open

## Goal
Replace `mermaid-open` with `md-open`: render a whole Markdown file GitHub-style in the browser, offline, Mermaid blocks drawn as diagrams. `<leader>mo` sends the Mermaid block under the cursor, or the whole buffer.

## Plan
1. Vendor marked, DOMPurify, highlight.js, github-markdown-css and mermaid into `bin/.local/share/md-open/`.
2. Write `bin/.local/bin/md-open`, tests in `tests/md_open_test.sh`.
3. Update the nvim module, its test, docs and cheatsheet.

## Done
- Libraries vendored and verified (versions, integrity, provenance in the share README).
- `md-open` script, `tests/md_open_test.sh` (with the optional Chrome render check), nvim `open()`, docs and cheatsheet.
- `mermaid-open` removed.

## Where we stopped
All steps done; tests pass. Not pushed or merged.

## Next step
Review, then `/merge`.

## How to test
`bash tests/run.sh`; by hand: `bin/.local/bin/md-open README.md`.

## Open questions
- Stdin without `--name` and without a mermaid fence is still one diagram; nvim always passes `--name`.

Updated: 2026-11-15 by personal@Pedros-MacBook-Pro-M4
