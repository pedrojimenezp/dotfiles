#!/usr/bin/env bash
# Tests the nvim_light/nvim_dark keys of bin/.local/bin/theme and nvim's config/theme.lua in a
# temp HOME. Offline: themes come from a fake Ghostty folder. Run: bash tests/theme_test.sh
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
unset TMUX # theme refreshes tmux clients; never reach a real server

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" # the repo under test
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

echo "tmux status tint"
# Real colors of Rose Pine (dark) and GitHub Light Default; blends checked by hand: 8% and 6% toward the foreground
printf 'background = #191724\nforeground = #e0def4\n' >"$THEME_GHOSTTY_DIRS/Tint Dark"
printf 'background = #ffffff\nforeground = #1f2328\n' >"$THEME_GHOSTTY_DIRS/Tint Light"
TINT_FILE="$XDG_STATE_HOME/theme-tmux.conf"
printf 'light = Tint Light\ndark = Tint Dark\n' >"$CONFIG"
"$THEME" dark >/dev/null 2>&1
check "dark theme: saved tint is 8% toward the foreground" grep -qxF 'set -g status-style "bg=#292735,fg=default"' "$TINT_FILE"
"$THEME" light >/dev/null 2>&1
check "light theme: saved tint is 6% toward the foreground" grep -qxF 'set -g status-style "bg=#f2f2f2,fg=default"' "$TINT_FILE"
"$THEME" toggle >/dev/null 2>&1
check "toggle updates the tint" grep -qxF 'set -g status-style "bg=#292735,fg=default"' "$TINT_FILE"
"$THEME" auto >/dev/null 2>&1
check "auto removes the tint" test ! -e "$TINT_FILE"
"$THEME" dark >/dev/null 2>&1
"$THEME" apply >/dev/null 2>&1
check "apply keeps the tint" test -e "$TINT_FILE"

# A private tmux server: theme updates the server named by TMUX; tmux.conf reads the saved file
if command -v tmux >/dev/null; then
  REAL_TMUX="$(command -v tmux)"
  TD="$(mktemp -d /tmp/tx.XXXX)"
  trap 'env -u TMUX "$REAL_TMUX" -S "$TD/s" kill-server 2>/dev/null || true; rm -rf "$ROOT" "$TD"' EXIT
  SOCK="$TD/s"
  T() { env -u TMUX "$REAL_TMUX" -S "$SOCK" "$@"; }
  mkdir -p "$TD/bin" "$HOME/.local"
  ln -s "$XDG_STATE_HOME" "$HOME/.local/state" # tmux.conf reads ~/.local/state
  printf '#!/bin/sh\nexec env -u TMUX "%s" -S "%s" "$@"\n' "$REAL_TMUX" "$SOCK" >"$TD/bin/tmux" # theme's own tmux calls reach only the private server
  chmod +x "$TD/bin/tmux"
  CONF="$SRC/tmux/.config/tmux/tmux.conf"
  start_server() { T kill-server 2>/dev/null || true; T -f "$CONF" new-session -d -x 80 -y 24 -s t >/dev/null 2>&1 || true; }

  "$THEME" dark >/dev/null 2>&1
  start_server
  check_eq "tmux.conf applies the saved tint" "bg=#292735,fg=default" "$(T show -gv status-style)"
  "$THEME" light >/dev/null 2>&1
  check_eq "theme alone leaves a running server as it was" "bg=#292735,fg=default" "$(T show -gv status-style)"
  TMUX="$SOCK,0,0" PATH="$TD/bin:$PATH" "$THEME" light >/dev/null 2>&1
  check_eq "theme inside tmux updates that server" "bg=#f2f2f2,fg=default" "$(T show -gv status-style)"
  TMUX="$SOCK,0,0" PATH="$TD/bin:$PATH" "$THEME" auto >/dev/null 2>&1
  check_eq "auto inside tmux resets the bar" "bg=default,fg=default" "$(T show -gv status-style)"
  rm -f "$TINT_FILE"
  start_server
  check_eq "no saved tint: bg=default" "bg=default,fg=default" "$(T show -gv status-style)"
  T kill-server 2>/dev/null || true
fi

summary
