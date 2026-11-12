#!/usr/bin/env bash
# Tests the nvim_light/nvim_dark keys of bin/.local/bin/theme and nvim's config/theme.lua in a
# temp HOME. Offline: themes come from a fake Ghostty folder. Run: bash tests/theme_test.sh
set -euo pipefail
unset TMUX # theme refreshes tmux clients; never reach a real server

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" # the repo under test
PASS=0
FAIL=0
ROOT="$(mktemp -d)"
trap 'rm -rf "$ROOT"' EXIT
export GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0
export HOME="$ROOT/home"
export XDG_CONFIG_HOME="$ROOT/config" XDG_STATE_HOME="$ROOT/state" XDG_DATA_HOME="$ROOT/data" XDG_CACHE_HOME="$ROOT/cache"
export THEME_NO_RELOAD=1 THEME_GHOSTTY_DIRS="$ROOT/themes"
export THEME_NVIM_LIST="$SRC/nvim/.config/nvim/themes.tsv"
mkdir -p "$HOME" "$XDG_CONFIG_HOME/theme" "$XDG_CONFIG_HOME/ghostty" "$XDG_STATE_HOME" "$THEME_GHOSTTY_DIRS"

THEME="$SRC/bin/.local/bin/theme"
CONFIG="$XDG_CONFIG_HOME/theme/config"

ok() { PASS=$((PASS + 1)); echo "  ok   $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL $1"; }
check() { # check "<description>" <test command...>
  local desc="$1"
  shift
  if "$@"; then ok "$desc"; else bad "$desc"; fi
}

for n in "Plain Light" "Plain Dark" "Other Light" "Other Dark" "GitHub Light Default" "TokyoNight Night"; do
  printf 'background = #101010\nforeground = #e0e0e0\n' >"$THEME_GHOSTTY_DIRS/$n"
done

# Runs theme; sets OUT (stdout and stderr) and RC (exit code).
run_theme() {
  RC=0
  OUT="$("$THEME" "$@" 2>&1)" || RC=$?
}
reset_config() { printf '# comment\nlight = Plain Light\ndark = Plain Dark\n' >"$CONFIG"; echo dark >"$XDG_STATE_HOME/theme"; }
has_line() { grep -qxF -- "$1" "$CONFIG"; }
out_has() { grep -qF -- "$1" <<<"$OUT"; }

echo "script"
reset_config
run_theme set nvim-light "Other Light"
check "set nvim-light saves the key" has_line "nvim_light = Other Light"
check "set nvim-light keeps the other lines" has_line "light = Plain Light"
run_theme set nvim-dark "Other Dark"
check "set nvim-dark saves the key" has_line "nvim_dark = Other Dark"
run_theme set nvim-dark "Plain Dark"
check "set nvim-dark again replaces the line" test "$(grep -c '^nvim_dark' "$CONFIG")" = 1
run_theme set nvim-dark "Other Dark"

run_theme set nvim-light "No Such Theme"
check "an unknown nvim name is refused" test "$RC" -ne 0
check "an unknown nvim name is not saved" has_line "nvim_light = Other Light"

run_theme status
check "status shows the nvim light pick" out_has "nvim light: Other Light"
check "status shows the nvim dark pick" out_has "nvim dark:  Other Dark"
check "status still shows the terminal pair" out_has "light: Plain Light"

# the terminal slots must not see the nvim keys
printf 'nvim_light = Other Light\nnvim_dark = Other Dark\nlight = Plain Light\ndark = Plain Dark\n' >"$CONFIG"
"$THEME" sync >/dev/null 2>&1 || true
check "ghostty sync ignores the nvim keys" grep -qxF "theme = light:Plain Light,dark:Plain Dark" "$XDG_CONFIG_HOME/ghostty/theme.conf"
printf 'nvim_light = Other Light\nnvim_dark = Other Dark\n' >"$CONFIG"
"$THEME" sync >/dev/null 2>&1 || true
check "only nvim keys: ghostty uses the defaults" grep -q "light:GitHub Light Default,dark:TokyoNight Night" "$XDG_CONFIG_HOME/ghostty/theme.conf"
run_theme status
check "only nvim keys: status terminal pair uses defaults" out_has "light: GitHub Light Default"

reset_config
run_theme set light "Other Light"
check "set light does not touch nvim keys" test "$(grep -c nvim "$CONFIG")" = 0
check "set light writes the light key" has_line "light = Other Light"
printf 'nvim_light = X\nlight = Plain Light\n' >"$CONFIG"
run_theme set light "Other Light"
check "set light skips the nvim_light line" has_line "nvim_light = X"
check "set light edits the light line" has_line "light = Other Light"

reset_config
"$THEME" set nvim-light "Other Light" >/dev/null 2>&1
"$THEME" set nvim-dark "Other Dark" >/dev/null 2>&1
run_theme set nvim-light --clear
check "--clear removes the key" test "$(grep -c '^nvim_light' "$CONFIG")" = 0
check "--clear leaves the other nvim key" has_line "nvim_dark = Other Dark"
check "--clear keeps the terminal pair and comments" has_line "light = Plain Light"
check "--clear keeps comments" has_line "# comment"
run_theme set nvim-light --clear
check "--clear on an unset key succeeds" test "$RC" -eq 0
run_theme set nvim-dark --clear
run_theme status
check "status hides cleared nvim picks" test "$(grep -c nvim <<<"$OUT")" = 0
run_theme set light --clear
check "--clear is refused for the terminal slots" test "$RC" -ne 0
run_theme set nvim-bogus "Other Light"
check "an unknown slot is refused" test "$RC" -ne 0

echo
echo "lua"
if ! command -v nvim >/dev/null; then
  echo "nvim not installed: lua checks skipped"
else
  # Prints "<light>|<dark>" as read_config() sees the current config.
  lua_names() {
    nvim --headless -u NONE -i NONE \
      --cmd "set rtp^=$SRC/nvim/.config/nvim" \
      -c "lua local n = require('config.theme').read_config(); io.stdout:write(n.light .. '|' .. n.dark .. '\n')" \
      -c "qa!" 2>&1 | tr -d '\r' | tail -n 1
  }
  printf 'light = Plain Light\ndark = Plain Dark\n' >"$CONFIG"
  check "read_config without nvim keys follows the terminal" test "$(lua_names)" = "Plain Light|Plain Dark"
  printf 'light = Plain Light\ndark = Plain Dark\nnvim_dark = Other Dark\n' >"$CONFIG"
  check "read_config applies nvim_dark only" test "$(lua_names)" = "Plain Light|Other Dark"
  printf 'nvim_light = Other Light\nlight = Plain Light\nnvim_dark = Other Dark\ndark = Plain Dark\n' >"$CONFIG"
  check "read_config applies both nvim keys" test "$(lua_names)" = "Other Light|Other Dark"
  printf 'nvim_light = Other Light\n' >"$CONFIG"
  check "read_config: nvim key with no terminal key" test "$(lua_names)" = "Other Light|TokyoNight Night"
  printf 'nvim_light =\nlight = Plain Light\n' >"$CONFIG"
  check "read_config ignores an empty nvim key" test "$(lua_names)" = "Plain Light|TokyoNight Night"
fi

echo "original Neovim themes"
reset_config
run_theme list nvim
check "list nvim prints the list names" out_has "Kanagawa Wave"
check "list nvim includes the Neovim-only names" out_has "Cyberdream Light"
check "list nvim prints names only" test "$(grep -c "$(printf '\t')" <<<"$OUT")" = 0
check "list nvim skips other themes" test "$(grep -c '^Plain' <<<"$OUT")" = 0
run_theme list nvim dark
check "list nvim dark has a dark theme" out_has "Catppuccin Mocha"
check "list nvim dark has Cyberdream" out_has "Cyberdream"
check "list nvim dark has no light theme" test "$(grep -cE 'Latte|Dayfox|Lotus|Light' <<<"$OUT")" = 0
run_theme list nvim light
check "list nvim light has Catppuccin Latte" out_has "Catppuccin Latte"
check "list nvim light has no dark theme" test "$(grep -cE 'Mocha|Wave|Dark|Storm|Frappe' <<<"$OUT")" = 0
run_theme list nvim blue
check "list nvim rejects another brightness" test "$RC" -ne 0
check "_list nvim-dark is list nvim dark" test "$("$THEME" _list nvim-dark)" = "$("$THEME" list nvim dark)"
run_theme set light Cyberdream
check "Cyberdream is refused for the light slot" test "$RC" -ne 0
run_theme set dark Cyberdream
check "Cyberdream is refused for the dark slot" test "$RC" -ne 0
check "a refused Cyberdream is not saved" test "$(grep -c Cyberdream "$CONFIG")" = 0
run_theme set nvim-dark Cyberdream
check "Cyberdream is accepted for nvim-dark" test "$RC" -eq 0
check "nvim-dark saves Cyberdream" has_line "nvim_dark = Cyberdream"
run_theme _swatch Cyberdream
check "the swatch of a Neovim-only theme is a note, not an error" test "$RC" -eq 0
check "the swatch says it is Neovim only" out_has "Neovim only"
run_theme sync
check "sync ignores a Neovim-only nvim pick" test "$RC" -eq 0
printf 'light = Cyberdream\ndark = Plain Dark\n' >"$CONFIG"
run_theme sync
check "a Neovim-only name in a terminal key fails sync" test "$RC" -ne 0
reset_config

echo "list by brightness"
FD="$ROOT/filter-themes" FC="$ROOT/filter-data"
mkdir -p "$FD" "$FC/theme/themes"
printf 'background = #101010\n' >"$FD/Night"
printf 'background = #fafafa\n' >"$FD/Day"
printf 'background = 808080\n' >"$FD/Gray Mid"      # luma 0.502: light; no leading #
printf 'background = #7f7f7f\n' >"$FD/Gray Low"      # luma 0.498: dark
printf 'foreground = #ffffff\n' >"$FD/No Background"
printf 'selection-background = #ffffff\nbackground = #000000\n' >"$FD/Selection First"
printf 'background = #ffffff\n' >"$FC/theme/themes/Cached Day"
printf 'background = #ffffff\n' >"$FC/theme/themes/Night" # the bundle wins over the cache
# a name with no local file comes from the cached GitHub listing (no bundle: use the cache dir only)
filter_list() { THEME_GHOSTTY_DIRS="$FD" XDG_DATA_HOME="$FC" "$THEME" "$@" 2>&1; }
names() { printf '%s\n' "$@"; }
check "list prints every theme" test "$(filter_list list)" = "$(names "Cached Day" Day "Gray Low" "Gray Mid" Night "No Background" "Selection First")"
check "list dark: dark and unclassifiable themes" test "$(filter_list list dark)" = "$(names "Gray Low" Night "No Background" "Selection First")"
check "list light: light and unclassifiable themes" test "$(filter_list list light)" = "$(names "Cached Day" Day "Gray Mid" "No Background")"
filter_fails() { ! filter_list list blue >/dev/null; }
check "list rejects another argument" filter_fails
check "_list is the same as list" test "$(filter_list _list dark)" = "$(filter_list list dark)"
check "_list without a filter lists all" test "$(filter_list _list)" = "$(filter_list list)"
# no bundle: names only in the GitHub listing show in both filtered lists; cached files are classified (Night is white here)
mkdir -p "$FC/../filter-cache/theme"
printf 'Remote Only\nCached Day\n' >"$ROOT/filter-cache/theme/list"
nobundle() { THEME_GHOSTTY_DIRS="" XDG_DATA_HOME="$FC" XDG_CACHE_HOME="$ROOT/filter-cache" "$THEME" "$@" 2>&1; }
check "no bundle: unknown name is in dark" test "$(nobundle list dark)" = "Remote Only"
check "no bundle: unknown name is in light" test "$(nobundle list light)" = "$(names "Cached Day" Night "Remote Only")"
echo

echo "passed: $PASS, failed: $FAIL"
[[ $FAIL -eq 0 ]]
