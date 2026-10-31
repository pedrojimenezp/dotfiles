# docs-apt-line-one-place

## Goal
Keep the apt install line in two places only: `docs/server.md` section 3 (servers) and `docs/install.md` (Linux desktop, with `xz-utils`). Link to section 3 everywhere else.

## Plan
1. Check both lines against `install.sh` (NEEDED list and printed apt line).
2. Replace the copies in `server.md` section 7 and `migrate-to-mise.md` with a link.
3. Add the "install.sh is the source of truth" sentence.

## Done
Both lines match `install.sh`. Copies in server.md section 7 and migrate-to-mise.md now link to server.md section 3. Added the source-of-truth sentence to server.md section 3 and install.md.

## Where we stopped
Docs done, checks run.

## Next step
Review, then /merge.

## How to test
`grep -rn "apt-get install" README.md docs/` shows only the two places; run the link checker (0 broken).

## Open questions
None.

Updated: 2026-10-31 by personal@Pedros-MacBook-Pro-M4
