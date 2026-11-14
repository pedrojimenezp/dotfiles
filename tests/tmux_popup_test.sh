#!/usr/bin/env bash
# shellcheck disable=SC2016
# Tests tmux-popup (cleanup, next/prev) on a private tmux socket with TMUX unset and a temp HOME. A tmux wrapper
# on PATH sends every call to that server and fakes the client: display-message -c reads the current session
# from a file and switch-client writes it. Run: bash tests/tmux_popup_test.sh
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" # the repo under test
ROOT="$(cd "$(mktemp -d)" && pwd -P)"
SOCK="$ROOT/tmux.sock"
cleanup() {
  env -u TMUX tmux -S "$SOCK" kill-server >/dev/null 2>&1 || true # only the private server of this test
  rm -rf "$ROOT"
}
trap cleanup EXIT
export GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 HOME="$ROOT/home"
mkdir -p "$HOME"
unset TMUX


CUR="$ROOT/current-session"
STUBS="$ROOT/stubs"
mkdir -p "$STUBS"
REAL_TMUX="$(command -v tmux)"
cat >"$STUBS/tmux" <<S
#!/bin/bash
unset TMUX
args=("\$@")
if [[ \${args[0]} == display-message && " \$* " == *" -c "* && \${args[*]} == *session_name* ]]; then
  cat "$CUR"
elif [[ \${args[0]} == switch-client ]]; then
  t="\${args[*]}"; t="\${t##*-t =}"; echo "\$t" >"$CUR"
else
  exec "$REAL_TMUX" -S "$SOCK" "\$@"
fi
S
chmod +x "$STUBS/tmux"
T() { env -u TMUX "$REAL_TMUX" -S "$SOCK" "$@"; }
POPUP="$SRC/bin/.local/bin/tmux-popup"
pop() { env HOME="$HOME" PATH="$STUBS:$PATH" bash "$POPUP" "$@"; }
names() { T list-sessions -F '#{session_name}' | sort | tr '\n' ' '; }

T -f /dev/null new-session -d -s alpha -c "$ROOT"
T new-session -d -s beta -c "$ROOT"
T new-session -d -s gamma -c "$ROOT"
alpha_id="$(T display-message -p -t =alpha: '#{session_id}')"

echo "== cleanup"
mk_popup() { # mk_popup <name> [parent id]: a popup session, with a parent mark when given
  T new-session -d -s "$1" -c "$ROOT"
  if [[ -n "${2:-}" ]]; then T set -t "=$1:" @popup_parent "$2"; T set -t "=$1:" @popup_kind shell; fi
}
mk_popup _popup_shell_alpha "$alpha_id"
mk_popup _popup_shell_orphan '$99'
mk_popup _popup_shell_restored
pop cleanup
check_eq "cleanup: popup with a live parent stays" "1" "$(T list-sessions -F '#{session_name}' | grep -cx _popup_shell_alpha)"
check_eq "cleanup: popup whose parent is gone is killed" "0" "$(T list-sessions -F '#{session_name}' | grep -cx _popup_shell_orphan)"
check_eq "cleanup: popup without a parent mark is killed" "0" "$(T list-sessions -F '#{session_name}' | grep -cx _popup_shell_restored)"
check_eq "cleanup: normal sessions untouched" "alpha beta gamma " "$(names | tr ' ' '\n' | grep -v '^_popup_' | tr '\n' ' ')"
T kill-session -t beta
pop cleanup
check_eq "cleanup: parent killed later takes nothing else" "1" "$(T list-sessions -F '#{session_name}' | grep -cx _popup_shell_alpha)"
T new-session -d -s beta -c "$ROOT"

echo "== next and prev skip popup sessions"
first="$(T list-sessions -F '#{session_name}' | grep -v '^_popup_' | head -1)"
last="$(T list-sessions -F '#{session_name}' | grep -v '^_popup_' | tail -1)"
echo "$first" >"$CUR"
pop next client
nxt="$(cat "$CUR")"
check_eq "next: moves to another normal session" "0" "$([[ "$nxt" != "$first" && "$nxt" != _popup_* ]] && echo 0 || echo 1)"
echo "$last" >"$CUR"
pop next client
check_eq "next: wraps to the first normal session" "$first" "$(cat "$CUR")"
echo "$first" >"$CUR"
pop prev client
check_eq "prev: wraps to the last normal session" "$last" "$(cat "$CUR")"
# put a popup session between two normal ones in list order and step across it
T new-session -d -s _popup_shell_mid -c "$ROOT"
for s in $(T list-sessions -F '#{session_name}'); do
  echo "$s" >"$CUR"
  [[ $s == _popup_* ]] && continue
  pop next client
  case "$(cat "$CUR")" in _popup_*) bad "next from $s landed in a popup session" ;; *) ok "next from $s skips popup sessions" ;; esac
  echo "$s" >"$CUR"
  pop prev client
  case "$(cat "$CUR")" in _popup_*) bad "prev from $s landed in a popup session" ;; *) ok "prev from $s skips popup sessions" ;; esac
done
echo _popup_shell_mid >"$CUR"
pop next client
case "$(cat "$CUR")" in _popup_*) bad "next from a popup lands on a normal session" ;; *) ok "next from a popup lands on a normal session" ;; esac

echo "== only popup sessions are left"
for s in alpha beta gamma; do T kill-session -t "$s" 2>/dev/null || true; done
echo _popup_shell_alpha >"$CUR"
pop next client
check_eq "no normal session: next stays" "_popup_shell_alpha" "$(cat "$CUR")"

echo "== usage errors"
rc=0
pop bogus >/dev/null 2>&1 || rc=$?
check_eq "unknown command: exit 2" "2" "$rc"
rc=0
pop next >/dev/null 2>&1 || rc=$?
check_eq "next without a client: exit 2" "2" "$rc"

summary
