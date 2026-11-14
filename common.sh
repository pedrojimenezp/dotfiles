# shellcheck shell=bash
# Shared by install.sh, uninstall.sh and tests/. Source it with $REPO set to the repo root.
# It sits at the repo root, outside every stow package, so stow never links it.

# Prints every stow package: each top-level folder except docs, tests, work notes, worktrees and hidden ones.
packages_all() {
  local d name
  for d in "$REPO"/*/; do
    name="$(basename "$d")"
    case "$name" in docs | tests | work | worktrees) continue ;; esac
    echo "$name"
  done
}

# Prints the packages that apply on this machine: iterm and skhd on macOS only, ghostty when Ghostty is installed.
packages_here() {
  local pkg app has_ghostty=0
  # GHOSTTY_APPS (space-separated app paths) overrides the default locations; Brewfile appdir first.
  for app in ${GHOSTTY_APPS:-"$HOME/Applications/Ghostty.app" /Applications/Ghostty.app}; do
    [[ -d $app ]] && has_ghostty=1
  done
  command -v ghostty >/dev/null 2>&1 && has_ghostty=1 # Linux package on PATH
  while IFS= read -r pkg; do
    case "$pkg" in
      iterm | skhd) [[ "$OSTYPE" == darwin* ]] || continue ;;
      ghostty) [[ $has_ghostty -eq 1 ]] || continue ;;
    esac
    echo "$pkg"
  done < <(packages_all)
}

# Output like apt: step "what starts", the tool's own output, finish "result", then a blank line.
# A preview (DRY=1) marks the result line, since nothing happened.
step() { echo "==> $*"; }
finish() {
  if [[ ${DRY:-0} -eq 1 ]]; then echo "[dry-run] $*"; else echo "$*"; fi
  echo
}

# Runs a command and prints "still running (10s)", then every 10s, until it ends; returns its status.
# For steps that can stay silent for a long time. HEARTBEAT_INTERVAL (seconds) overrides the 10.
with_heartbeat() {
  local rc=0 pid
  if [[ ${DRY:-0} -eq 1 ]]; then "$@"; return; fi
  (
    trap 'kill "${sleeper:-}" 2>/dev/null; exit 0' TERM
    waited=0
    while :; do
      sleep "${HEARTBEAT_INTERVAL:-10}" &
      sleeper=$!
      wait "$sleeper"
      waited=$((waited + ${HEARTBEAT_INTERVAL:-10}))
      echo "still running (${waited}s)"
    done
  ) </dev/null &
  pid=$!
  "$@" || rc=$?
  kill "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
  return "$rc"
}
