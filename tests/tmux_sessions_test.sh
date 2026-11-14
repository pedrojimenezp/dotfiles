#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2088
# Tests tmux-sessionizer on a private tmux socket with TMUX unset, a temp HOME and a stub
# fzf. Run: bash tests/tmux_sessions_test.sh. Exits non-zero when a check fails.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" # the repo under test
ROOT="$(cd "$(mktemp -d)" && pwd -P)" # resolved, so paths match what the scripts print
SOCK="$ROOT/tmux.sock"
cleanup() {
  env -u TMUX tmux -S "$SOCK" kill-server >/dev/null 2>&1 || true # only the private server of this test
  rm -rf "$ROOT"
}
trap cleanup EXIT
export GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 HOME="$ROOT/home"
mkdir -p "$HOME"
unset TMUX


BIN="$SRC/bin/.local/bin"
STUBS="$ROOT/stubs"
mkdir -p "$STUBS"
# tmux wrapper: every call of the scripts goes to the private server
printf '#!/bin/sh\nunset TMUX\nexec "%s" -S "%s" "$@"\n' "$(command -v tmux)" "$SOCK" >"$STUBS/tmux"
# fzf stub: prints the query line (empty), then $FZF_PICK, like --print-query
printf '#!/bin/sh\ncat >/dev/null\n[ -n "${FZF_QUERY+x}" ] && echo "$FZF_QUERY" || echo\n[ -n "${FZF_PICK:-}" ] && echo "$FZF_PICK"\nexit 0\n' >"$STUBS/fzf"
chmod +x "$STUBS"/*
T() { env -u TMUX tmux -S "$SOCK" "$@"; }
# Panes run sleep, not a shell: a shell writes its history into $HOME while the server dies, which can
# race with the rm in cleanup ("Directory not empty").
T -f /dev/null new-session -d -s keeper -c "$ROOT" 'exec sleep 3600' # keeps the server alive
T set -g default-command 'exec sleep 3600'

# sessionizer <dir>: TMUX is faked so it creates the session detached; switch-client then fails, which is fine.
sess() {
  env HOME="$HOME" TMUX=fake SESSIONIZER_TMUX_ARGS="-S $SOCK" SESSIONIZER_DIRS="$ROOT/none" PATH="$STUBS:$PATH" bash "$BIN/tmux-sessionizer" "$1" >/dev/null 2>&1 || true
}
path_of() { # the folder of session $1, or "missing"
  T list-sessions -F '#{session_name}'$'\t''#{session_path}' | awk -F'\t' -v n="$1" '$1 == n { print $2; f = 1 } END { if (!f) print "missing" }'
}

echo "== tmux-sessionizer names"
mkdir -p "$ROOT/a/x/web" "$ROOT/b/x/web" "$ROOT/c/x/web" "$ROOT/d.e/my app"
sess "$ROOT/a/x/web"
check_eq "first folder: named after its basename" "$ROOT/a/x/web" "$(path_of web)"
sess "$ROOT/a/x/web"
check_eq "same folder again: reuses the session" "2" "$(T list-sessions | wc -l | tr -d ' ')"
sess "$ROOT/b/x/web"
check_eq "same basename: adds the parent folder" "$ROOT/b/x/web" "$(path_of web-x)"
sess "$ROOT/c/x/web"
check_eq "second collision: counter keeps it apart" "$ROOT/c/x/web" "$(path_of web-x-2)"
check_eq "second collision: earlier sessions untouched" "$ROOT/b/x/web" "$(path_of web-x)"
sess "$ROOT/c/x/web"
check_eq "collision folder again: reuses its session" "4" "$(T list-sessions | wc -l | tr -d ' ')"
sess "$ROOT/d.e/my app"
check_eq "dots and spaces become dashes" "$ROOT/d.e/my app" "$(path_of my-app)"

echo "== tmux-sessionizer --list"
mkdir -p "$ROOT/proj/repo1/.git" "$ROOT/proj/repo1/worktrees/feat-a" "$ROOT/proj/parent/worktrees/feat-b/svc" "$ROOT/proj/.hidden/.git" "$ROOT/proj/node_modules/pkg/.git"
list="$(env HOME="$HOME" SESSIONIZER_DIRS="$ROOT/proj" bash "$BIN/tmux-sessionizer" --list)"
check_eq "list: repo with its path" "1" "$(grep -cF "$ROOT/proj/repo1"$'\t'"$ROOT/proj/repo1" <<<"$list")"
check_eq "list: feature labelled with its owner" "1" "$(grep -cF "feat-a  [repo1]"$'\t'"$ROOT/proj/repo1/worktrees/feat-a" <<<"$list")"
check_eq "list: parent-level feature" "1" "$(grep -cF "feat-b  [parent]"$'\t'"$ROOT/proj/parent/worktrees/feat-b" <<<"$list")"
check_eq "list: hidden and node_modules skipped" "0" "$(grep -cE 'hidden|node_modules' <<<"$list")"
check_eq "list: features come before repos" "feat" "$(head -1 <<<"$list" | cut -c1-4)"

mkdir -p "$ROOT/proj/aaa-empty/.git" "$ROOT/proj/aaa-empty/worktrees"
elist="$(env HOME="$HOME" SESSIONIZER_DIRS="$ROOT/proj" bash "$BIN/tmux-sessionizer" --list)"
check_eq "list: empty worktrees/ does not cut the list" "1" "$(grep -cF "$ROOT/proj/repo1"$'\t' <<<"$elist")"
check_eq "list: repo with an empty worktrees/ is listed" "1" "$(grep -cF "$ROOT/proj/aaa-empty"$'\t' <<<"$elist")"

echo "== tmux-sessionizer zoxide entries"
mkdir -p "$ROOT/here" "$HOME/zdir"
printf '#!/bin/sh\nprintf "%%s\\n" "%s" "%s" "%s" "%s" "%s"\n' "$ROOT/proj/repo1" "$ROOT/here" "$ROOT/nope" "$HOME/zdir" "$HOME" >"$STUBS/zoxide"
chmod +x "$STUBS/zoxide"
ZPATH="$STUBS:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin" # the Homebrew dirs are listed so the script adds nothing ahead of the stubs
zlist="$(env HOME="$HOME" PATH="$ZPATH" SESSIONIZER_DIRS="$ROOT/proj" bash "$BIN/tmux-sessionizer" --list)"
check_eq "zoxide: folder listed with its path" "1" "$(grep -cF "$ROOT/here"$'\t'"$ROOT/here" <<<"$zlist")"
check_eq "zoxide: folder under HOME shown with ~" "1" "$(grep -cF '~/zdir'$'\t'"$HOME/zdir" <<<"$zlist")"
check_eq "zoxide: repo already listed is not repeated" "1" "$(grep -cxF "$ROOT/proj/repo1"$'\t'"$ROOT/proj/repo1" <<<"$zlist")"
check_eq "zoxide: missing folder dropped" "0" "$(grep -c nope <<<"$zlist")"
check_eq "zoxide: entries come after repos" "$HOME/zdir" "$(tail -1 <<<"$zlist" | cut -f2)"
check_eq "list: every line is label<TAB>path" "0" "$(awk -F'\t' 'NF != 2' <<<"$zlist" | wc -l | tr -d ' ')"
nolist="$(env HOME="$HOME" PATH="/usr/bin:/bin" SESSIONIZER_DIRS="$ROOT/proj" bash "$BIN/tmux-sessionizer" --list)"
check_eq "home: listed once as ~, even when zoxide returns it" "1" "$(grep -cxF '~'$'\t'"$HOME" <<<"$zlist")"
check_eq "home: after repos, before zoxide rows" "$ROOT/proj/repo1,~,$ROOT/here" "$(awk -F'\t' -v r="$ROOT/proj/repo1" '$2==r||$1=="~"||$2==h {printf "%s%s", s, ($1=="~"?"~":$2); s=","}' h="$ROOT/here" <<<"$zlist")"
check_eq "no zoxide: list has no zoxide entries" "0" "$(grep -c zdir <<<"$nolist")"

echo "== tmux-sessionizer picker"
# pick <fzf pick line> [fzf query]: runs the picker with TMUX faked; fzf stub prints the query, then the pick
pick() {
  env HOME="$HOME" TMUX=fake SESSIONIZER_TMUX_ARGS="-S $SOCK" SESSIONIZER_DIRS="$ROOT/none" PATH="$ZPATH" FZF_PICK="$1" ${2+FZF_QUERY="$2"} bash "$BIN/tmux-sessionizer" >/dev/null 2>&1 || true
}
pick "~/zdir"$'\t'"$HOME/zdir" >/dev/null
check_eq "picked zoxide entry: session in that folder" "$HOME/zdir" "$(path_of zdir)"
mkdir -p "$ROOT/typed1"
pick "" "$ROOT/typed1" >/dev/null
check_eq "typed existing path: used as typed" "$ROOT/typed1" "$(path_of typed1)"
pick "" "~/zdir" >/dev/null
check_eq "typed ~ path: expanded, session reused" "1" "$(T list-sessions -F '#{session_name}' | grep -cx zdir)"
mkdir -p "$ROOT/typed2" "$ROOT/row2"
pick "row2"$'\t'"$ROOT/row2" "$ROOT/typed2" >/dev/null
check_eq "typed folder beats a selected row" "$ROOT/typed2" "$(path_of typed2)"
check_eq "typed folder beats a selected row: row not opened" "missing" "$(path_of row2)"
pick "~/zdir"$'\t'"$HOME/zdir" "~" >/dev/null
check_eq "typed ~ beats a selected row" "$HOME" "$(path_of "$(basename "$HOME")")"
pick "row2"$'\t'"$ROOT/row2" "row" >/dev/null
check_eq "plain text query: selected row wins" "$ROOT/row2" "$(path_of row2)"
pick "" "$ROOT/nonexistent" >/dev/null
check_eq "typed missing folder: no session" "missing" "$(path_of nonexistent)"
msg="$(env HOME="$HOME" SESSIONIZER_DIRS="$ROOT/none" PATH="$ZPATH" FZF_PICK="" FZF_QUERY="$ROOT/nonexistent" bash "$BIN/tmux-sessionizer" 2>&1 >/dev/null || true)"
check_eq "typed missing folder outside tmux: message on stderr" "no such folder: $ROOT/nonexistent" "$msg"

echo "== tmux-sessionizer --name"
# named <name> [dir]: --name run with TMUX faked; without a dir the picker stub answers
named() {
  env HOME="$HOME" TMUX=fake SESSIONIZER_TMUX_ARGS="-S $SOCK" SESSIONIZER_DIRS="$ROOT/none" PATH="$ZPATH" FZF_PICK="${FZF_PICK:-}" ${FZF_QUERY+FZF_QUERY="$FZF_QUERY"} bash "$BIN/tmux-sessionizer" --name "$@" >/dev/null 2>&1 || true
}
mkdir -p "$ROOT/shared"
sess "$ROOT/shared"
FZF_PICK="shared"$'\t'"$ROOT/shared" named "my-name"
check_eq "name: new session in the picked folder" "$ROOT/shared" "$(path_of my-name)"
check_eq "name: session already on that folder untouched" "$ROOT/shared" "$(path_of shared)"
before="$(T list-sessions | wc -l | tr -d ' ')"
FZF_PICK="row2"$'\t'"$ROOT/row2" named "my-name"
check_eq "name: existing name creates nothing" "$before" "$(T list-sessions | wc -l | tr -d ' ')"
check_eq "name: existing name keeps its folder" "$ROOT/shared" "$(path_of my-name)"
msg="$(env HOME="$HOME" SESSIONIZER_TMUX_ARGS="-S $SOCK" SESSIONIZER_DIRS="$ROOT/none" PATH="$ZPATH" bash "$BIN/tmux-sessionizer" --name my-name "$ROOT/shared" 2>&1 </dev/null >/dev/null || true)"
check_eq "name: existing name outside tmux: message on stderr" "session my-name already exists" "$(head -1 <<<"$msg")"
named "it's a name.x:y" "$ROOT/row2"
check_eq "name: quote kept, spaces dots and colons become dashes" "$ROOT/row2" "$(path_of "it's-a-name-x-y")"
named "dir arg" "$ROOT/typed1"
check_eq "name: dir argument skips the picker" "$ROOT/typed1" "$(path_of dir-arg)"
before="$(T list-sessions | wc -l | tr -d ' ')"
named ""
named "   "
check_eq "name: empty name exits without a session" "$before" "$(T list-sessions | wc -l | tr -d ' ')"
FZF_PICK="" FZF_QUERY="" named "nothing-picked"
check_eq "name: nothing picked creates nothing" "missing" "$(path_of nothing-picked)"

echo "== tmux.conf binding"
CONF="$SRC/tmux/.config/tmux/tmux.conf"
check_eq "prefix N: bound with a note" "1" "$(grep -cE '^bind -N "[^"]+" N command-prompt' "$CONF")"
check_eq "prefix N: runs the sessionizer with --name" "1" "$(grep -c 'tmux-sessionizer --name' "$CONF")"

summary
