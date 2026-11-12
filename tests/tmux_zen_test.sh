#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034
# Tests tmux-zen and its hooks from tmux.conf on a private tmux server (300x50) with TMUX unset and a temp HOME.
# Every tmux call here names the private socket; tmux-zen's own plain tmux calls reach it through TMUX, as under run-shell.
# TMUX_TMPDIR points into the temp dir, so a call without -S can never reach another server. Run: bash tests/tmux_zen_test.sh
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" # the repo under test
PASS=0
FAIL=0
ROOT="$(cd "$(mktemp -d)" && pwd -P)"
SOCK="$ROOT/tmux.sock"
cleanup() {
  T kill-server >/dev/null 2>&1 || true # only the private server of this test
  rm -rf "$ROOT"
}
trap cleanup EXIT
export GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 HOME="$ROOT/home"
mkdir -p "$HOME/.local/bin"
export TMUX_TMPDIR="$ROOT"
unset TMUX

ok() { PASS=$((PASS + 1)); echo "  ok   $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL $1"; }
check() { # check "<description>" "<expected>" "<actual>"
  if [[ "$2" == "$3" ]]; then ok "$1"; else bad "$1 (expected: $2, got: $3)"; fi
}

ln -s "$SRC/bin/.local/bin/tmux-zen" "$HOME/.local/bin/tmux-zen" # the hooks call ~/.local/bin/tmux-zen
T() { env -u TMUX TMUX_TMPDIR="$ROOT" tmux -S "$SOCK" "$@"; }
# Runs tmux-zen the way run-shell does: TMUX names the private server
zen() { TMUX="$SOCK,$(T display-message -p '#{pid}'),0" bash "$SRC/bin/.local/bin/tmux-zen" "$@"; }

# Hooks run in the background: wait up to 5s for a condition (a command string)
wait_for() { local i; for i in $(seq 50); do if eval "$1"; then return 0; fi; sleep 0.1; done; return 1; }
panes() { T list-panes -t "$1" -F '#{pane_id}'; }
pads() { T list-panes -t "$1" -F '#{pane_id} #{@zen_pad}' | awk '$2 == 1 { print $1 }'; }
widths() { T list-panes -t "$1" -F '#{pane_left}:#{pane_width}' | sort -n | tr '\n' ' '; }
active() { T display-message -p -t "$1" '#{pane_id}'; }
opt() { T display-message -p -t "$1" "#{$2}"; }

# The real tmux.conf, minus the plugins (the missing tpm path only prints an error)
T -f "$SRC/tmux/.config/tmux/tmux.conf" new-session -d -x 300 -y 50 -s z -c "$ROOT" >/dev/null 2>&1 || true
T has-session -t z
W="$(T display-message -p -t z '#{window_id}')"
real="$(active "$W")"

echo "== binding"
check "prefix Z runs tmux-zen toggle" "1" "$(T list-keys -T prefix | grep -c 'prefix  *Z .*tmux-zen toggle')"
check "prefix Z has a note" "1" "$(T list-keys -N -T prefix | grep -c ' Z ')"
check "@zen_width defaults to 120" "120" "$(T show -gv @zen_width)"

echo "== too narrow"
T resize-window -t "$W" -x 130
zen toggle "$W"
check "130 columns: no pads" "0" "$(pads "$W" | wc -l | tr -d ' ')"
check "130 columns: window unmarked" "" "$(opt "$W" @zen)"
check "130 columns: one pane" "1" "$(panes "$W" | wc -l | tr -d ' ')"
T resize-window -t "$W" -x 300

echo "== toggle on"
zen toggle "$W"
check "window marked" "1" "$(opt "$W" @zen)"
check "two pads" "2" "$(pads "$W" | wc -l | tr -d ' ')"
check "three panes" "3" "$(panes "$W" | wc -l | tr -d ' ')"
# (300 - 120 - 2 borders) / 2 = 89 per pad; the column is 211 - 90 - 1 = 120 wide
check "pad and column widths" "0:89 90:120 211:89 " "$(widths "$W")"
check "focus stays on the real pane" "$real" "$(active "$W")"
check "pads are full height" "50 50 50 " "$(T list-panes -t "$W" -F '#{pane_height}' | tr '\n' ' ')"
check "pad input is disabled" "1 1" "$(for p in $(pads "$W"); do T display-message -p -t "$p" '#{pane_input_off}'; done | tr '\n' ' ' | sed 's/ $//')"
check "border lines off" "spaces" "$(T show-options -wv -t "$W" pane-border-lines)"
check "border status off" "off" "$(T show-options -wv -t "$W" pane-border-status)"
check "border indicators off" "off" "$(T show-options -wv -t "$W" pane-border-indicators)"
sleep 0.5
check "layout hook leaves the borders off" "off" "$(T show-options -wv -t "$W" pane-border-status)"

echo "== zoom"
T select-pane -t "$real"
T resize-pane -Z -t "$real"
check "zoom works" "1" "$(opt "$W" window_zoomed_flag)"
T resize-pane -Z -t "$real"
check "unzoom works" "0" "$(opt "$W" window_zoomed_flag)"

echo "== toggle off"
zen toggle "$W"
check "window unmarked" "" "$(opt "$W" @zen)"
check "only the real pane is left" "$real" "$(panes "$W" | tr '\n' ' ' | sed 's/ $//')"
check "pane fills the window" "0:300 " "$(widths "$W")"
check "no window-level border lines" "" "$(T show-options -w -t "$W" pane-border-lines)"
sleep 0.5
check "layout hook sets the labels for one pane" "off" "$(T show-options -wv -t "$W" pane-border-status)"
check "no window-level border indicators" "" "$(T show-options -w -t "$W" pane-border-indicators)"
check "global border lines apply" "heavy" "$(T show-options -wgv pane-border-lines)"

echo "== an existing split stays in the column"
T split-window -t "$W" -v -d
zen toggle "$W"
check "four panes" "4" "$(panes "$W" | wc -l | tr -d ' ')"
check "pads are still full height" "50 50 " "$(for p in $(pads "$W"); do T display-message -p -t "$p" '#{pane_height}'; done | tr '\n' ' ')"
check "real panes sit between the pads" "90 90 " "$(T list-panes -t "$W" -F '#{pane_left} #{?#{@zen_pad},1,0}' | awk '$2 != 1 { print $1 }' | tr '\n' ' ')"
check "real panes are 120 wide" "120 120 " "$(T list-panes -t "$W" -F '#{pane_width} #{?#{@zen_pad},1,0}' | awk '$2 != 1 { print $1 }' | tr '\n' ' ')"

echo "== resize refits"
T resize-window -t "$W" -x 260
wait_for '[[ "$(widths "$W")" == "0:69 70:120 70:120 191:69 " ]]' || true
check "pads match the new size" "0:69 70:120 70:120 191:69 " "$(widths "$W")"
T resize-window -t "$W" -x 300
wait_for '[[ "$(widths "$W")" == "0:89 90:120 90:120 211:89 " ]]' || true
check "pads match the size again" "0:89 90:120 90:120 211:89 " "$(widths "$W")"
T set -g @zen_width 100
zen fit "$W"
check "@zen_width changes the column" "0:99 100:100 100:100 201:99 " "$(widths "$W")"
T set -g @zen_width 120
zen fit "$W"

echo "== pads can't keep focus"
left="$(T list-panes -t "$W" -F '#{pane_id} #{?#{@zen_pad},1,0} #{pane_left}' | awk '$2 == 1 && $3 == 0 { print $1 }')"
firstreal="$(T list-panes -t "$W" -F '#{pane_id} #{?#{@zen_pad},1,0} #{pane_left} #{pane_top}' | awk '$2 != 1 && $4 == 0 { print $1 }')"
T select-pane -t "$firstreal"
T select-pane -t "$left" # what a mouse click and Ctrl-h do
wait_for '[[ "$(opt "$W" @zen_pad)" != 1 ]]' || true
check "selecting the left pad returns to the previous pane" "$firstreal" "$(active "$W")"
T select-pane -t "$firstreal"
T select-pane -L
wait_for '[[ "$(opt "$W" @zen_pad)" != 1 ]]' || true
check "select-pane -L from the edge does not stay in the pad" "" "$(opt "$W" @zen_pad)"
right="$(pads "$W" | grep -vx "$left")"
T select-pane -t "$right"
wait_for '[[ "$(opt "$W" @zen_pad)" != 1 ]]' || true
check "selecting the right pad leaves it" "" "$(opt "$W" @zen_pad)"
secondreal="$(T list-panes -t "$W" -F '#{pane_id} #{?#{@zen_pad},1,0} #{pane_top}' | awk '$2 != 1 && $3 != 0 { print $1 }')"
T kill-pane -t "$secondreal"
wait_for '[[ "$(panes "$W" | wc -l | tr -d " ")" == 3 ]]' || true
sleep 0.5
check "after closing a real pane, focus is on a real pane" "" "$(opt "$W" @zen_pad)"
check "closing one of two real panes keeps the pads" "2" "$(pads "$W" | wc -l | tr -d ' ')"

echo "== closing the last real pane removes the pads"
T new-window -d -t z: -c "$ROOT" # keeps the session alive
W2="$(T list-windows -t z -F '#{window_id}' | tail -1)"
zen toggle "$W2"
check "second window has pads" "2" "$(pads "$W2" | wc -l | tr -d ' ')"
r2="$(T list-panes -t "$W2" -F '#{pane_id} #{@zen_pad}' | awk '$2 != 1 { print $1 }')"
T kill-pane -t "$r2"
wait_for '! T list-windows -t z -F "#{window_id}" | grep -qx "$W2"' || true
check "window with only pads is closed" "0" "$(T list-windows -t z -F '#{window_id}' | grep -cx "$W2" || true)"

echo "== without zen the layout hook labels panes"
zen toggle "$W"
T split-window -t "$W" -h -d
sleep 0.5
check "pane labels still turn on" "top" "$(T show-options -wv -t "$W" pane-border-status 2>/dev/null || echo none)"

echo "== usage errors"
rc=0
zen bogus "$W" >/dev/null 2>&1 || rc=$?
check "unknown command: exit 2" "2" "$rc"
rc=0
zen toggle >/dev/null 2>&1 || rc=$?
check "toggle without a window: exit 2" "2" "$rc"

echo
echo "passed: $PASS, failed: $FAIL"
[[ $FAIL -eq 0 ]]
