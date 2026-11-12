#!/usr/bin/env bash
# Tests that config/theme.lua loads every theme in nvim's themes.tsv with its own colorscheme and
# 'background', that repeated loads and the other background keep the variant, and that an
# unlisted name falls back to Dayfox/Nightfox. Plugins come from the installed lazy folder;
# a theme whose plugin is missing is skipped. Run: bash tests/nvim_themes_test.sh
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REAL_LAZY="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy"
LIST="$SRC/nvim/.config/nvim/themes.tsv"
PASS=0
FAIL=0
ROOT="$(mktemp -d)"
trap 'rm -rf "$ROOT"' EXIT
export GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0
export HOME="$ROOT/home"
export XDG_CONFIG_HOME="$ROOT/config" XDG_STATE_HOME="$ROOT/state" XDG_DATA_HOME="$ROOT/data" XDG_CACHE_HOME="$ROOT/cache"
mkdir -p "$HOME" "$XDG_CONFIG_HOME/theme" "$XDG_STATE_HOME"

ok() { PASS=$((PASS + 1)); echo "  ok   $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL $1"; }

if ! command -v nvim >/dev/null; then
  echo "nvim not installed: skipped"
  exit 0
fi

# Plugin folder for a colorscheme name.
plugin_for() {
  case $1 in
    tokyonight-*) echo tokyonight.nvim ;;
    github_*) echo github-nvim-theme ;;
    nightfox | dayfox | dawnfox | duskfox | nordfox | terafox | carbonfox) echo nightfox.nvim ;;
    kanagawa-*) echo kanagawa.nvim ;;
    rose-pine*) echo rose-pine ;;
    catppuccin-*) echo catppuccin ;;
    cyberdream*) echo cyberdream.nvim ;;
  esac
}

RTP="$SRC/nvim/.config/nvim"
for d in tokyonight.nvim github-nvim-theme nightfox.nvim kanagawa.nvim rose-pine catppuccin cyberdream.nvim; do
  [[ -d "$REAL_LAZY/$d" ]] && RTP="$RTP,$REAL_LAZY/$d"
done

# Runs config.theme.load() twice for a name with the config in both slots: first in `bg`, then in
# the other background. Prints "ok" or the problem. A scheme that forces 'background' is checked
# against its listed brightness.
LUA_LOAD='
local want, bg = vim.env.WANT_SCHEME, vim.env.WANT_BG
local seen = {}
vim.api.nvim_create_autocmd("ColorScheme", { callback = function(a) seen[#seen + 1] = a.match end })
local theme = require("config.theme")
local function normal() return vim.api.nvim_get_hl(0, { name = "Normal" }).bg end
vim.o.background = bg
theme.load()
local first = normal()
local bg_after = vim.o.background
vim.o.background = bg == "light" and "dark" or "light"
theme.load()
local problems = {}
if seen[1] ~= want then table.insert(problems, "loaded " .. tostring(seen[1])) end
if bg_after ~= bg then table.insert(problems, "background became " .. bg_after) end
if normal() ~= first then table.insert(problems, "variant changed with the other background") end
io.stdout:write(#problems == 0 and "ok" or table.concat(problems, "; "))
'

# run_load <name> <scheme> <bg>: prints the Lua result.
run_load() {
  printf 'nvim_light = %s\nnvim_dark = %s\n' "$1" "$1" >"$XDG_CONFIG_HOME/theme/config"
  WANT_SCHEME="$2" WANT_BG="$3" nvim --headless -u NONE -i NONE --cmd "set rtp^=$RTP" \
    -c "lua $LUA_LOAD" -c "qa!" 2>&1 | tr -d '\r' | tail -n 1
}

echo "listed themes"
while IFS=$'\t' read -r name scheme bg _; do
  [[ -z $name || $name == \#* ]] && continue
  plugin="$(plugin_for "$scheme")"
  if [[ ! -d "$REAL_LAZY/$plugin" ]]; then echo "  skip $name ($plugin not installed)"; continue; fi
  out="$(run_load "$name" "$scheme" "$bg")"
  if [[ $out == ok ]]; then ok "$name -> $scheme ($bg)"; else bad "$name -> $scheme ($bg): $out"; fi
done <"$LIST"

# Unlisted name: Dayfox in light, Nightfox in dark.
echo "unlisted names"
LUA_UNLISTED='
local seen
vim.api.nvim_create_autocmd("ColorScheme", { callback = function(a) seen = seen or a.match end })
vim.o.background = vim.env.WANT_BG
require("config.theme").load()
io.stdout:write(seen or "none")
'
if [[ ! -d "$REAL_LAZY/nightfox.nvim" ]]; then
  echo "  skip (nightfox.nvim not installed)"
else
  printf 'nvim_light = Sublette\nnvim_dark = Sublette\n' >"$XDG_CONFIG_HOME/theme/config"
  for pair in "light dayfox" "dark nightfox"; do
    read -r bg scheme <<<"$pair"
    out="$(WANT_BG="$bg" nvim --headless -u NONE -i NONE --cmd "set rtp^=$RTP" -c "lua $LUA_UNLISTED" -c "qa!" 2>&1 | tr -d '\r' | tail -n 1)"
    if [[ $out == "$scheme" ]]; then ok "Sublette in $bg loads $scheme"; else bad "Sublette in $bg loads $out, want $scheme"; fi
  done
fi

echo
echo "passed: $PASS, failed: $FAIL"
[[ $FAIL -eq 0 ]]
