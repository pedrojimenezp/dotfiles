#!/usr/bin/env bash
# Tests nvim's config/diff_colors.lua in a temp HOME: with each colorscheme the Diff groups have a
# background and no foreground, and diffview sets a winhighlight per side. Offline: the
# base16 theme comes from a fake Ghostty folder; plugin schemes are skipped when not installed.
# Run: bash tests/nvim_diff_colors_test.sh
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REAL_LAZY="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy"
PASS=0
FAIL=0
ROOT="$(mktemp -d)"
trap 'rm -rf "$ROOT"' EXIT
export GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0
export HOME="$ROOT/home"
export XDG_CONFIG_HOME="$ROOT/config" XDG_STATE_HOME="$ROOT/state" XDG_DATA_HOME="$ROOT/data" XDG_CACHE_HOME="$ROOT/cache"
export THEME_GHOSTTY_DIRS="$ROOT/themes"
mkdir -p "$HOME" "$XDG_CONFIG_HOME/theme" "$XDG_STATE_HOME" "$THEME_GHOSTTY_DIRS"
printf 'background = #fafafa\nforeground = #383a42\npalette = 1=#e45649\npalette = 2=#50a14f\n' >"$THEME_GHOSTTY_DIRS/Fake Light"
printf 'background = #282c34\nforeground = #dcdfe4\npalette = 1=#e06c75\npalette = 2=#98c379\n' >"$THEME_GHOSTTY_DIRS/Fake Dark"

ok() { PASS=$((PASS + 1)); echo "  ok   $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL $1"; }

if ! command -v nvim >/dev/null; then
  echo "nvim not installed: skipped"
  exit 0
fi

# Loads the scheme through config.theme and checks the groups. Prints "ok" or the problem.
LUA_GROUPS='
local names = { "DiffAdd", "DiffAddOld", "DiffChange", "DiffChangeOld", "DiffChangeNew", "DiffText", "DiffTextOld", "DiffTextNew", "DiffDelete", "GitSignsAddPreview", "GitSignsDeleteVirtLn", "GitSignsAddInline", "GitSignsChangeInline", "GitSignsDeleteInline", "GitSignsDeleteVirtLnInLine" }
local function get(n) return vim.api.nvim_get_hl(0, { name = n, link = false }) end
local theme = require("config.theme")
theme.load()
local normal = get("Normal").bg
local rgb = function(n) return math.floor(n / 65536), math.floor(n / 256) % 256, n % 256 end
local problems = {}
for _, n in ipairs(names) do
  local h = get(n)
  if h.fg then table.insert(problems, n .. " has fg") end
  if not h.bg then table.insert(problems, n .. " has no bg") elseif h.bg == normal then table.insert(problems, n .. " bg equals Normal") end
end
local r1, g1 = rgb(get("DiffAddOld").bg)
local r2, g2 = rgb(get("DiffAdd").bg)
if not (r1 > g1) then table.insert(problems, "old side line is not reddish") end
if not (g2 > r2) then table.insert(problems, "new side line is not greenish") end
if get("GitSignsDeleteVirtLnInLine").bg == get("GitSignsDeleteVirtLn").bg then table.insert(problems, "gitsigns deleted words match the line tint") end
if get("GitSignsAddInline").bg == get("GitSignsAddPreview").bg then table.insert(problems, "gitsigns added words match the line tint") end
if get("DiffTextOld").bg == get("DiffChangeOld").bg then table.insert(problems, "changed words match the line tint") end
if vim.o.fillchars:find("diff: ", 1, true) == nil then table.insert(problems, "fillchars diff is not blank") end
io.stdout:write(#problems == 0 and "ok" or table.concat(problems, "; "))
'

# check_scheme <label> <light|dark> <nvim theme name> [plugin dir under lazy]
check_scheme() {
  local label="$1" mode="$2" name="$3" plugin="${4:-}" out rtp="$SRC/nvim/.config/nvim"
  if [[ -n "$plugin" ]]; then
    if [[ ! -d "$REAL_LAZY/$plugin" ]]; then echo "  skip $label ($plugin not installed)"; return; fi
    rtp="$rtp,$REAL_LAZY/$plugin"
  fi
  printf 'nvim_%s = %s\n' "$mode" "$name" >"$XDG_CONFIG_HOME/theme/config"
  echo "$mode" >"$XDG_STATE_HOME/theme"
  out="$(nvim --headless -u NONE -i NONE --cmd "set rtp^=$rtp" --cmd "set background=$mode" \
    -c "lua require('config.diff_colors').setup()" -c "lua $LUA_GROUPS" -c "qa!" 2>&1 | tr -d '\r' | tail -n 1)"
  if [[ "$out" == ok ]]; then ok "$label: background-only groups"; else bad "$label: $out"; fi
}

echo "groups"
check_scheme "github_light_default" light "GitHub Light Default" github-nvim-theme
check_scheme "tokyonight-night" dark "TokyoNight Night" tokyonight.nvim
check_scheme "tokyonight-day" light "TokyoNight Day" tokyonight.nvim
check_scheme "base16 light" light "Fake Light"
check_scheme "base16 dark" dark "Fake Dark"

echo "diffview"
if [[ ! -d "$REAL_LAZY/diffview.nvim" ]]; then
  echo "  skip (diffview.nvim not installed)"
else
  repo="$ROOT/repo"
  mkdir -p "$repo"
  git -C "$repo" init -q
  git -C "$repo" config user.email t@example.com
  git -C "$repo" config user.name t
  printf 'one\ntwo\nthree\n' >"$repo/f.txt"
  git -C "$repo" add f.txt
  git -C "$repo" commit -qm init
  printf 'one\nTWO\nthree\nfour\n' >"$repo/f.txt"
  out="$(cd "$repo" && nvim --headless -u NONE -i NONE \
    --cmd "set rtp^=$SRC/nvim/.config/nvim,$REAL_LAZY/diffview.nvim" \
    -c "lua require('config.diff_colors').setup(); require('diffview').setup(dofile('$SRC/nvim/.config/nvim/lua/plugins/git.lua')[1].opts)" \
    -c "lua require('diffview').open({})" \
    -c "lua vim.wait(5000, function() local n = 0 for _, w in ipairs(vim.api.nvim_list_wins()) do if vim.wo[w].diff then n = n + 1 end end return n == 2 end, 50); local r = {} for _, w in ipairs(vim.api.nvim_list_wins()) do if vim.wo[w].diff then table.insert(r, vim.wo[w].winhighlight) end end table.sort(r); io.stdout:write(table.concat(r, ' | '))" \
    -c "qa!" 2>&1 | tr -d '\r' | tail -n 1)"
  old="DiffAdd:DiffAddOld,DiffChange:DiffChangeOld,DiffText:DiffTextOld"
  new="DiffChange:DiffChangeNew,DiffText:DiffTextNew"
  if [[ "$out" == *"$old"* && "$out" == *"$new"* ]]; then ok "each side gets its winhighlight"; else bad "winhighlight: $out"; fi
fi

echo "gitsigns unified"
if [[ ! -d "$REAL_LAZY/gitsigns.nvim" ]]; then
  echo "  skip (gitsigns.nvim not installed)"
else
  repo="$ROOT/grepo"
  mkdir -p "$repo"
  git -C "$repo" init -q -b main
  git -C "$repo" config user.email t@example.com
  git -C "$repo" config user.name t
  printf 'one\ntwo\n' >"$repo/f.txt"
  printf 'x\n' >"$repo/g.txt"
  git -C "$repo" add .
  git -C "$repo" commit -qm init
  rev="$(git -C "$repo" rev-parse HEAD)"
  printf 'one\nTWO\n' >"$repo/f.txt"
  git -C "$repo" commit -qam committed
  printf 'x\ny\n' >"$repo/g.txt"
  printf 'new\n' >"$repo/h.txt"
  out="$(cd "$repo" && nvim --headless -u NONE -i NONE \
    --cmd "set rtp^=$SRC/nvim/.config/nvim,$REAL_LAZY/gitsigns.nvim" \
    -c "lua require('config.diff_colors').setup(); require('gitsigns').setup({}); local ok, err = pcall(require('gitsigns').diff, '$rev', nil, { diff = 'unified' }); if not ok then io.stdout:write('error: ' .. tostring(err)); return end; local panel; vim.wait(5000, function() for _, b in ipairs(vim.api.nvim_list_bufs()) do if vim.bo[b].filetype == 'gitsigns-diff' then local t = table.concat(vim.api.nvim_buf_get_lines(b, 0, -1, false), ' '); if t:find('f.txt', 1, true) and t:find('g.txt', 1, true) and t:find('h.txt', 1, true) then panel = t return true end end end end, 50); for _, n in ipairs({ 'GitSignsAddPreview', 'GitSignsDeleteVirtLn', 'GitSignsAddInline', 'GitSignsChangeInline', 'GitSignsDeleteInline', 'GitSignsDeleteVirtLnInLine' }) do local h = vim.api.nvim_get_hl(0, { name = n, link = false }); if h.fg or not h.bg then io.stdout:write(n .. ' has fg or no bg; ') end end; io.stdout:write(panel and 'ok' or 'panel missing files')" \
    -c "qa!" 2>&1 | tr -d '\r' | tail -n 1)"
  if [[ "$out" == *ok ]]; then ok "unified panel lists committed, uncommitted and untracked files; groups are background-only"; else bad "gitsigns unified: $out"; fi
fi

echo
echo "passed: $PASS, failed: $FAIL"
[[ $FAIL -eq 0 ]]
