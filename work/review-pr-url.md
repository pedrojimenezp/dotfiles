# review-pr-url

## Goal
`review-pr` accepts a GitHub PR URL as well as a number, and puts worktrees where the layout rule says (single repo, or a submodule under its superproject's main checkout).

## Plan
1. Parse number or URL; resolve the repo (current, superproject, submodules by origin).
2. Compute the worktree path per layout; keep the rest of the flow.
3. Tests, usage/-h, docs/git.md.

## Done
- Script, tests (tests/review_pr_test.sh) and docs/git.md updated; shellcheck clean; tests/run.sh green.
- Window name: review gets --name (pr-<n> or pr-<repo>-<n>) so two PRs of one repo never share a window; --done note, docs and tests updated.
- Lookup tested read-only in a repo with ~98 submodules: ~0.1s on a hit, ~1.2s on a miss.

## Where we stopped
Finished; not pushed or merged.

## Next step
Review the diff, then /merge.

## How to test
`bash tests/review_pr_test.sh` or `bash tests/run.sh`.

## Open questions
- A superproject feature worktree uses that worktree's own initialized submodule for git operations; the folder lands under the main checkout.

Updated: 2026-11-12 by personal@Pedros-MacBook-Pro-M4
