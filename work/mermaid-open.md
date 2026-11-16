# mermaid-open

## Goal
`mermaid-open` opens Mermaid diagrams in the browser, offline; `<leader>mo` in nvim uses it. Replaces the mermaid-cli (mmdc) mise entry.

## Plan
1. Remove mermaid-cli from mise. 2. Vendor mermaid.min.js. 3. `mermaid-open` script. 4. `<leader>mo`. 5. Docs, tests.

## Done
All five steps, with tests (tests/mermaid_open_test.sh, tests/nvim_mermaid_test.sh). Mermaid 12.3.0, integrity verified, provenance present.

## Where we stopped
Implemented and committed on branch `mermaid-open`; not merged.

## Next step
Review, then `/merge`.

## How to test
`bash tests/mermaid_open_test.sh && bash tests/nvim_mermaid_test.sh`, or `tests/run.sh`.

## Open questions
Pages from `<leader>mo` are headed `stdin:<line>` (the buffer name is not passed).

Updated: 2026-11-15 by personal@Pedros-MacBook-Pro-M4
