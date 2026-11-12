#!/usr/bin/env bash
# shellcheck disable=SC2016
# Tests tmux-fit-windows on a private tmux server with TMUX unset. Control-mode clients stand in for terminals.
# Every tmux call names the private socket; the script's own plain tmux calls reach it through TMUX.
# TMUX_TMPDIR points into the temp dir, so a call without -S can never reach another server. Run: bash tests/tmux_fit_windows_test.sh
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0
ROOT="$(cd "$(mktemp -d)" && pwd -P)"
SOCK="$ROOT/tmux.sock"
FIFO="$ROOT/client.fifo"
cleanup() {
  { echo detach >&3; } 2>/dev/null || true
  T kill-server >/dev/null 2>&1 || true # only the private server of this test
  rm -rf "$ROOT"
}
trap cleanup EXIT
export GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 TMUX_TMPDIR="$ROOT"
unset TMUX

ok() { PASS=$((PASS + 1)); echo "  ok   $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL $1"; }
check() { # check "<description>" "<expected>" "<actual>"
  if [[ "$2" == "$3" ]]; then ok "$1"; else bad "$1 (expected: $2, got: $3)"; fi
}

T() { env -u TMUX TMUX_TMPDIR="$ROOT" tmux -S "$SOCK" "$@"; }
fit() { TMUX="$SOCK,$(T display-message -p '#{pid}'),0" bash "$SRC/bin/.local/bin/tmux-fit-windows"; }
size() { T display-message -p -t "$1" '#{window_width}x#{window_height}'; }
wsize() { # the window's own window-size setting, or "global" when it has none
  local v
  v="$(T show-options -w -t "$1" window-size)"
  echo "${v:+local}${v:-global}"
}

# Checksum of a layout body, as tmux computes it
layout() {
  local s="$1" c=0 i ch
  for ((i = 0; i < ${#s}; i++)); do
    printf -v ch '%d' "'${s:i:1}"
    c=$((((c >> 1) + ((c & 1) << 15)) & 0xffff))
    c=$(((c + ch) & 0xffff))
  done
  printf '%04x,%s' "$c" "$s"
}
# Sizes a window the way a restore leaves it: while a client of that size shows its session, then the client goes
saved_layout() { # saved_layout <window> <WxH>
  T select-layout -t "$1" "$(layout "$2,0,0,$(T list-panes -t "$1" -F '#{pane_id}' | tr -d %)")"
}
attach() { # attach <session> <WxH>: a control-mode client that stays until detach()
  exec 3<>"$FIFO"
  T -C attach -t "$1" <&3 >/dev/null 2>&1 &
  sleep 1
  echo "refresh-client -C $2" >&3
  sleep 1
}
detach() { echo detach >&3; exec 3>&-; sleep 1; }

mkfifo "$FIFO"
T -f /dev/null new-session -d -s a -x 200 -y 50
T new-session -d -s b -x 200 -y 50
T new-window -d -t a
W=@2 # a window of a, not shown
attach a 140x78
saved_layout "$W" 140x78
check "layout sets the window to the saved size" 140x78 "$(size "$W")"
echo "switch-client -t b" >&3
sleep 1
echo "refresh-client -C 282x79" >&3
sleep 1

echo "Bug: a window in a session without a client keeps the saved size"
check "window stays at the saved size" 140x78 "$(size "$W")"

echo "Fix"
fit
check "window follows the client" 282x79 "$(size "$W")"
check "window-size is back to the global value" global "$(wsize "$W")"
check "global value is latest" latest "$(T display-message -p -t "$W" '#{window-size}')"
check "every window has the client size" "282x79 282x79 282x79" "$(T list-windows -a -F '#{window_width}x#{window_height}' | tr '\n' ' ' | sed 's/ $//')"

echo "Client resize"
echo "switch-client -t a" >&3
sleep 1
echo "refresh-client -C 200x79" >&3
sleep 1
check "window follows a smaller client" 200x79 "$(size "$W")"

echo "Client that attaches after the fix ran"
detach
echo "  (no client)"
before="$(size "$W")"
fit # no client: must change nothing and succeed
check "no client: window keeps its size" "$before" "$(size "$W")"
attach a 282x79
check "late client: window follows" 282x79 "$(size "$W")"
detach

echo
echo "tmux_fit_windows_test: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]]
