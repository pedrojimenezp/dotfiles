#!/usr/bin/env bash
# shellcheck disable=SC2016
# Tests bin/.local/bin/note and notes with a temp NOTES_DIR and HOME, and stub fzf and nvim on PATH.
# The stub fzf answers each call from a queue ("rc|output", \n for newlines; empty queue: Esc, status 130);
# the stub nvim appends its arguments to a log. Run: bash tests/notes_test.sh
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" # the repo under test
ROOT="$(mktemp -d)"
trap 'rm -rf "$ROOT"' EXIT
export GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 HOME="$ROOT/home" NOTES_DIR="$ROOT/notes"
mkdir -p "$HOME"
unset TMUX
NOTE="$SRC/bin/.local/bin/note"
NOTES="$SRC/bin/.local/bin/notes"

STUBS="$ROOT/stubs"
mkdir -p "$STUBS"
cat >"$STUBS/fzf" <<S
#!/bin/bash
cat >/dev/null
q="$ROOT/fzf-queue"
[[ -s \$q ]] || exit 130
first="\$(head -n1 "\$q")"; sed -i.bak 1d "\$q"
printf '%b\n' "\${first#*|}"
exit "\${first%%|*}"
S
cat >"$STUBS/nvim" <<S
#!/bin/bash
echo "nvim \$*" >>"$ROOT/nvim.log"
S
chmod +x "$STUBS"/*
export PATH="$STUBS:$PATH"
queue() { : >"$ROOT/fzf-queue"; [[ $# -eq 0 ]] || printf '%s\n' "$@" >"$ROOT/fzf-queue"; : >"$ROOT/nvim.log"; }

echo "== note capture"
out="$(bash "$NOTE" "first secret" 2>&1)"
check_eq "note: prints one line" "saved to inbox.md" "$out"
echo "second line" | bash "$NOTE" >/dev/null
inbox="$NOTES_DIR/inbox.md"
check_eq "note: two headings" "2" "$(grep -cE '^## [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}$' "$inbox")"
contains "note: argument text saved" "first secret" "$(cat "$inbox")"
contains "note: stdin text saved" "second line" "$(cat "$inbox")"
check_eq "note: folder mode 700" "700" "$(stat -f %Lp "$NOTES_DIR" 2>/dev/null || stat -c %a "$NOTES_DIR")"
check_eq "note: file mode 600" "600" "$(stat -f %Lp "$inbox" 2>/dev/null || stat -c %a "$inbox")"
check "note: empty text fails" bash -c '! bash "$0" "   " 2>/dev/null' "$NOTE"

echo "== name validation"
check_eq "name: adds .md" "idea.md" "$(bash "$NOTES" name idea)"
check_eq "name: keeps .md" "idea.md" "$(bash "$NOTES" name idea.md)"
check_eq "name: trims and keeps spaces" "my idea.md" "$(bash "$NOTES" name "  my idea ")"
check "name: slash rejected" bash -c '! bash "$0" name a/b 2>/dev/null' "$NOTES"
check "name: .. rejected" bash -c '! bash "$0" name ../x 2>/dev/null' "$NOTES"
check "name: .. inside rejected" bash -c '! bash "$0" name a..b 2>/dev/null' "$NOTES"
check "name: empty rejected" bash -c '! bash "$0" name "  " 2>/dev/null' "$NOTES"
check "name: bare .md rejected" bash -c '! bash "$0" name .md 2>/dev/null' "$NOTES"

echo "== list and search"
cd "$NOTES_DIR"
printf 'alpha text\nneedle here\n' >old.md
printf 'beta\n' >new.md
touch -t 202001010000 old.md
touch -t 202401010000 inbox.md
check_eq "list: newest first" "new.md inbox.md old.md" "$(bash "$NOTES" list | tr '\n' ' ' | sed 's/ $//')"
check_eq "grep: file:line:text" "old.md:2:needle here" "$(bash "$NOTES" grep needle)"
check_eq "grep: empty pattern lists nothing" "" "$(bash "$NOTES" grep '')"
check_eq "grep: invalid regex lists nothing" "" "$(bash "$NOTES" grep '(' )"
contains "preview: shows the note" "needle here" "$(bash "$NOTES" preview old.md)"
contains "preview: grep line shows the note" "alpha text" "$(bash "$NOTES" preview old.md:2:needle)"
cd "$ROOT"

echo "== picker"
queue "0|\nold.md"
bash "$NOTES" </dev/null
contains "open: existing note" "-- old.md" "$(cat "$ROOT/nvim.log")"
contains "open: no swap, shada or undo files" "-n -i NONE -c set noundofile noswapfile" "$(cat "$ROOT/nvim.log")"
queue "0|\nold.md:2:needle here"
bash "$NOTES" </dev/null
contains "open: grep match at its line" "+2 -- old.md" "$(cat "$ROOT/nvim.log")"
queue "1|fresh idea"
bash "$NOTES" </dev/null
contains "create: opens <name>.md" "-- fresh idea.md" "$(cat "$ROOT/nvim.log")"
queue "1|../evil" "0|\nnew.md"
bash "$NOTES" </dev/null >"$ROOT/out" 2>&1 || true
check_eq "create: .. rejected, nothing outside the folder" "0" "$(find "$ROOT" -name 'evil*' | wc -l | tr -d ' ')"
contains "create: rejection is explained" "cannot contain" "$(cat "$ROOT/out")"
queue "0|\nnew.md" "0|\nold.md"
bash "$NOTES" </dev/null
check_eq "loop: picker shows again after nvim" "2" "$(grep -c '^nvim' "$ROOT/nvim.log")"
queue
check "esc outside a popup quits" bash "$NOTES" </dev/null

echo "== degrade"
check "missing fzf is reported" bash -c 'out="$(PATH=/usr/bin:/bin bash "$0" </dev/null 2>&1)"; [[ $out == *"fzf is not installed"* ]]' "$NOTES"
summary
