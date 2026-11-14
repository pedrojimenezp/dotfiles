#!/usr/bin/env bash
# Tests the F12 nested-tmux toggle from tmux.conf on a private tmux server with a temp HOME.
# Every tmux call names the private socket. Run: bash tests/tmux_nested_test.sh
set -euo pipefail
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" # the repo under test
ROOT="$(cd "$(mktemp -d /tmp/tx.XXXX)" && pwd -P)"
SOCK="$ROOT/t.sock"
T() { env -u TMUX TMUX_TMPDIR="$ROOT" tmux -S "$SOCK" "$@"; }
cleanup() {
  T kill-server >/dev/null 2>&1 || true # only the private server of this test
  rm -rf "$ROOT"
}
trap cleanup EXIT
export GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 HOME="$ROOT/home"
mkdir -p "$HOME"
unset TMUX

T -f "$SRC/tmux/.config/tmux/tmux.conf" new-session -d -x 80 -y 24 -s n >/dev/null 2>&1 || true
T has-session -t n
T set -g default-command "exec sleep 3600"
T respawn-pane -k -t n >/dev/null 2>&1 || true

# Runs what a key is bound to, minus refresh-client (the test has no client)
press() { T run-shell -C -t n "$(T list-keys | sed -n "s/^bind-key  *-T  *$1  *F12  *//p" | sed 's/ \\; / ; /g; s/; refresh-client -S//')"; }
style() { T show -Av -t n status-style; }
global_style="$(T show -gv status-style)"

echo "== binding"
check_eq "F12 in root has a note" "1" "$(T list-keys -N | grep -c ' F12 ')"
check_eq "F12 is bound in the off table" "1" "$(T list-keys | grep -c -- '-T off  *F12 ')"
check_eq "prefix C-Space still sends the prefix on" "1" "$(T list-keys -T prefix | grep -c 'prefix  *C-Space send-prefix')"

echo "== keys off"
press root
check_eq "key-table is off" "off" "$(T show -Av -t n key-table)"
check_eq "prefix is None" "None" "$(T show -Av -t n prefix)"
check "status style is dimmed" test "$(style)" != "$global_style"
check_eq "global status style untouched" "$global_style" "$(T show -gv status-style)"
check_eq "global prefix untouched" "C-Space" "$(T show -gv prefix)"

echo "== keys on"
press off
check_eq "key-table is root" "root" "$(T show -Av -t n key-table)"
check_eq "prefix is C-Space" "C-Space" "$(T show -Av -t n prefix)"
check_eq "status style is back to the global value" "$global_style" "$(style)"
check_eq "no session-level key-table override" "0" "$(T show -t n | grep -c '^key-table')"

summary
