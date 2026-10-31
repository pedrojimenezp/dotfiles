# show-user

## Goal
Show the current user in the starship prompt and the tmux status bar.

## Plan
Starship username module plus PROMPT_HOST as @host; tmux #{user} block locally and user@host in the SSH badge; update docs.

## Done
- starship.toml, tmux.conf and docs (tools, tmux, server) updated; tested prompt and private tmux server; link check 0 broken.

## Where we stopped
Ready for review. Root style (bold red) not tested: starship detects root by uid.

## Next step
Review, then /merge.

## How to test
starship prompt with PROMPT_HOST set/unset; private tmux server with -f tmux.conf and display -p '#{E:status-left}'.

## Open questions
None.

Updated: 2026-10-30 by personal@Pedros-MacBook-Pro-M4
