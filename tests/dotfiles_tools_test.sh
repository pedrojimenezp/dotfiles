#!/usr/bin/env bash
# shellcheck disable=SC2016
# Tests dotfiles-usage (period math, alias mapping, skip list, log counting) and dotfiles-help --list parsing
# against a small fake repo in a temp dir and temp HOME. Run: bash tests/dotfiles_tools_test.sh
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" # the repo under test
PASS=0
FAIL=0
ROOT="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$ROOT"' EXIT
export GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 HOME="$ROOT/home"
export XDG_STATE_HOME="$ROOT/state"
mkdir -p "$HOME" "$XDG_STATE_HOME"
unset TMUX

ok() { PASS=$((PASS + 1)); echo "  ok   $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL $1"; }
check() { # check "<description>" "<expected>" "<actual>"
  if [[ "$2" == "$3" ]]; then ok "$1"; else bad "$1 (expected: $2, got: $3)"; fi
}

# The fake repo: the real scripts plus small data files.
FAKE="$ROOT/repo"
mkdir -p "$FAKE/bin/.local/bin" "$FAKE/mise/.config/mise" "$FAKE/zsh" "$FAKE/tmux/.config/tmux" "$FAKE/docs"
cp "$SRC/bin/.local/bin/dotfiles-log" "$SRC/bin/.local/bin/dotfiles-usage" "$SRC/bin/.local/bin/dotfiles-help" "$FAKE/bin/.local/bin/"
printf '#!/usr/bin/env bash\n# mykey: a key-launched tool\n# Usage: mykey [x]  (does the thing)\n"$(dirname "$0")/dotfiles-log" mykey\n' >"$FAKE/bin/.local/bin/mykey"
printf '#!/usr/bin/env bash\n# plain: no log call\n' >"$FAKE/bin/.local/bin/plain"
cat >"$FAKE/Brewfile" <<'B'
brew "ripgrep"
brew "pngpaste"
brew "stow"
brew "zsh-extra" # not a command
cask "ghostty"
B
cat >"$FAKE/mise/.config/mise/config.toml" <<'B'
[tools]
neovim = "latest"
eza = "latest"
tree-sitter = "latest"
shellcheck = "latest"
shfmt = "latest"
golangci-lint = "latest"
git-lfs = "latest"
tealdeer = "latest"
"github:x/y" = "latest"

[settings]
foo = 1
B
cat >"$FAKE/zsh/.zshrc" <<'B'
alias ll='eza -l'  # long list
alias v='nvim'
alias g='git status'
bindkey '^R' fzf-history  # history search
bindkey -v
# --- Helpers ---
# mkcd dir: make a folder and enter it
mkcd() { mkdir -p "$1" && cd "$1"; }
undocumented() { :; }
B
cat >"$FAKE/tmux/.config/tmux/tmux.conf" <<'B'
bind -N "split right" v split-window -h
bind -r -N "resize" C-l resize-pane -R
bind -T copy-mode-vi -N "copy it" y send -X copy-selection
bind -n -N "no prefix" M-x kill-pane
bind -N "shifted" N new-window
bind v split-window
B
printf '# header\ntmux plugin\tprefix Ctrl+s\tsave\tdocs/tmux.md\n' >"$FAKE/docs/cheatsheet.tsv"

now="$(date +%s)"
day=86400
hist="$ROOT/hist"
{
  echo ": $((now - day)):0;rg foo | nvim"        # yesterday: rg, nvim
  echo ": $((now - 2 * day)):0;FOO=1 sudo ll"   # alias ll -> eza, after env var and sudo
  echo ": $((now - 10 * day)):0;stow zsh"       # 10 days ago
  echo ": $((now - 20 * day)):0;v file && tldr x" # v -> nvim; tldr (tealdeer)
  echo ": $((now - 40 * day)):0;rg old"          # outside every period
  echo ": $((now - day)):0;mykey"                # key-launched: history ignored
  echo ": $((now - day)):0;/usr/bin/plain"       # path stripped
  echo ": $((now - day)):0;g"                    # alias of a non-tool
  echo ": $((now - day)):0;shellcheck x"         # skipped tool
} >"$hist"
mkdir -p "$XDG_STATE_HOME/dotfiles"
printf '%s mykey\n%s mykey\n%s mykey\n' "$now" "$now" "$((now - 20 * day))" >"$XDG_STATE_HOME/dotfiles/usage.log"

usage() { env DOTFILES_USAGE_HISTFILE="$hist" bash "$FAKE/bin/.local/bin/dotfiles-usage" "$@"; }
count() { # count <output> <tool>: the uses column of a tool
  awk -v n="$2" '$1 == n { print $2 }' <<<"$1"
}

echo "== dotfiles-usage periods"
w="$(usage)"
check "week: rg used once" "1" "$(count "$w" rg)"
check "week: nvim counted from the pipe" "1" "$(count "$w" nvim)"
check "week: alias ll counts for eza (after env and sudo)" "1" "$(count "$w" eza)"
check "week: 10 days ago is out" "0" "$(count "$w" stow)"
check "week: a path is stripped" "1" "$(count "$w" plain)"
check "week: tool shown as yesterday" "1" "$(grep -c '^rg .*yesterday' <<<"$w")"
check "week: unused tool marked" "1" "$(grep -c '^stow .*unused' <<<"$w")"
check "week: key-launched tool counted from the log only" "2" "$(count "$w" mykey)"
two="$(usage 2weeks)"
check "2weeks: stow now counted" "1" "$(count "$two" stow)"
check "2weeks: tldr (20 days) still out" "0" "$(count "$two" tldr)"
m="$(usage month)"
check "month: rg counted once, not the 40 day entry" "1" "$(count "$m" rg)"
check "month: nvim via pipe and alias v" "2" "$(count "$m" nvim)"
check "month: tealdeer counted under its command tldr" "1" "$(count "$m" tldr)"
check "month: log entries 20 days old counted" "3" "$(count "$m" mykey)"
rc=0
usage forever >/dev/null 2>&1 || rc=$?
check "unknown period: exit 2" "2" "$rc"

echo "== dotfiles-usage tool list"
check "ripgrep listed as rg" "1" "$(grep -c '^rg ' <<<"$w")"
check "neovim listed as nvim" "1" "$(grep -c '^nvim ' <<<"$w")"
for skipped in tree-sitter shellcheck shfmt golangci-lint git-lfs pngpaste dotfiles-log; do
  check "skipped, never listed: $skipped" "0" "$(grep -c "^$skipped " <<<"$w")"
done
check "tssh always listed" "1" "$(grep -c '^tssh ' <<<"$w")"
check "scripts of bin/ listed" "1" "$(grep -c '^mykey ' <<<"$w")"
check "github: backend keys not listed" "0" "$(grep -c 'github' <<<"$w")"
check "casks are not listed" "0" "$(grep -c '^ghostty ' <<<"$w")"

echo "== dotfiles-help --list"
h="$(env bash "$FAKE/bin/.local/bin/dotfiles-help" --list)"
check "every row has 4 tab-separated fields" "0" "$(awk -F'\t' 'NF != 4' <<<"$h" | wc -l | tr -d ' ')"
has() { grep -qF -- "$1" <<<"$h" && echo 1 || echo 0; }
check "tmux: plain key" "1" "$(has $'tmux\tprefix v\tsplit right\tdocs/tmux.md')"
check "tmux: -r flag skipped, Ctrl+" "1" "$(has $'tmux\tprefix Ctrl+l\tresize\tdocs/tmux.md')"
check "tmux: copy mode table" "1" "$(has $'tmux\tcopy mode: y\tcopy it\tdocs/tmux.md')"
check "tmux: -n means no prefix, Alt+" "1" "$(has $'tmux\tAlt+x\tno prefix\tdocs/tmux.md')"
check "tmux: uppercase letter is Shift+" "1" "$(has $'tmux\tprefix Shift+N\tshifted\tdocs/tmux.md')"
check "tmux: bind without -N not listed" "1" "$(grep -c $'tmux\tprefix v\t' <<<"$h")"
check "zsh: alias with comment" "1" "$(has $'zsh alias\tll\tlong list\tdocs/zsh.md')"
check "zsh: alias without comment not listed" "0" "$(grep -c $'zsh alias\tv\t' <<<"$h")"
check "zsh: bindkey with comment" "1" "$(has $'zsh key\tCtrl+R\thistory search\tdocs/zsh.md')"
check "zsh: documented function" "1" "$(has $'zsh function\tmkcd dir\tmake a folder and enter it\tdocs/zsh.md')"
check "zsh: undocumented function not listed" "0" "$(grep -c undocumented <<<"$h")"
check "command: line 2 description" "1" "$(has $'command\tmykey\ta key-launched tool\tbin/.local/bin/mykey')"
check "command: Usage line with parentheses" "1" "$(has $'command\tmykey [x]\tdoes the thing\tbin/.local/bin/mykey')"
check "cheatsheet: rows pass through, comments skipped" "1" "$(has $'tmux plugin\tprefix Ctrl+s\tsave\tdocs/tmux.md')"
check "cheatsheet: header comment skipped" "0" "$(grep -c '^# header' <<<"$h")"
rc=0
bash "$FAKE/bin/.local/bin/dotfiles-help" --bogus >/dev/null 2>&1 || rc=$?
check "unknown option: exit 2" "2" "$rc"
real="$(bash "$SRC/bin/.local/bin/dotfiles-help" --list)"
check "real repo: every row has 4 fields" "0" "$(awk -F'\t' 'NF != 4' <<<"$real" | wc -l | tr -d ' ')"

echo
echo "passed: $PASS, failed: $FAIL"
[[ $FAIL -eq 0 ]]
