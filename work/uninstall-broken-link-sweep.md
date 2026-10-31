# uninstall-broken-link-sweep

## Goal
After the clone is deleted, `uninstall.sh` removes every broken symlink whose target text is inside the clone.

## Plan
Record package paths during `scan_links`; add `sweep_broken_links` after the clone is removed; test; document.

## Done
- `raw_link_target`, `sweep_link`, `sweep_broken_links` and step 7 in `uninstall.sh`.
- Three test groups in `tests/uninstall_test.sh` (sweep, dry run, kept clone); one line in `docs/install.md`.
- Tests, `bash -n` and shellcheck pass.

## Where we stopped
Ready to merge.

## Next step
Merge with /merge.

## How to test
`/bin/bash tests/uninstall_test.sh`

## Open questions
None.

Updated: 2026-10-31 by personal@Pedros-MacBook-Pro-M4
