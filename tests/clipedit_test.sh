#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2001,SC1091
# Tests bin/.local/bin/clipedit and its mask.pl / clipedit.lua. The clipboard round trip uses stub pbpaste, pbcopy
# and nvim on PATH (the clipboard is a file), so the real clipboard is never touched; the <leader>m check runs the
# real nvim headless with -u NONE. Every secret is fake and built by concatenation. Run: bash tests/clipedit_test.sh
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" # the repo under test
ROOT="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$ROOT"' EXIT
export GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 HOME="$ROOT/home" TMPDIR="$ROOT/tmp"
mkdir -p "$HOME" "$TMPDIR"
unset TMUX
CLIPEDIT="$SRC/bin/.local/bin/clipedit"
SHARE="$SRC/bin/.local/share/clipedit"
REAL_NVIM="$(command -v nvim)"

mask() { printf '%s' "$1" | perl "$SHARE/mask.pl"; }

# Fake secrets, assembled so no literal token is in this file.
rep() { printf "%${2}s" '' | tr ' ' "$1"; }
GH="gh""p_$(rep a 36)"
GHO="gh""o_$(rep b 36)"
GHS="gh""s_$(rep c 36)"
GHU="gh""u_$(rep d 36)"
PAT="github""_pat_$(rep E 30)_$(rep f 20)"
SK="s""k-$(rep 1 40)"
SKANT="s""k-ant-api03-$(rep x 30)9"
AKIA="AK""IA$(rep Q 16)"
ASIA="AS""IA$(rep Z 16)"
XOX="xo""xb-$(rep 7 12)-$(rep 8 12)"
JWT="ey""Jhbgci.$(rep p 20).$(rep s 20)"

echo "== mask: patterns"
check_eq "github ghp" "token ghp_***" "$(mask "token $GH")"
check_eq "github gho" "gho_***" "$(mask "$GHO")"
check_eq "github ghs" "gho_*** and ghs_***" "$(mask "$GHO and $GHS")"
check_eq "github ghu" "ghu_***" "$(mask "$GHU")"
check_eq "github_pat" "github_pat_***" "$(mask "$PAT")"
check_eq "sk key" "key s""k-***" "$(mask "key $SK")"
check_eq "sk-ant key" "s""k-ant-***" "$(mask "$SKANT")"
check_eq "aws AKIA" "AK""IA***" "$(mask "$AKIA")"
check_eq "aws ASIA" "AS""IA***" "$(mask "$ASIA")"
check_eq "slack" "xo""xb-***" "$(mask "$XOX")"
check_eq "jwt" "t: eyJ***" "$(mask "t: $JWT")"
check_eq "bearer" "Bearer ***" "$(mask "Bearer $(rep k 24)")"
check_eq "authorization keeps scheme" "Authorization: Bearer ***" "$(mask "Authorization: Bearer $(rep k 24)")"
check_eq "authorization other" "authorization: ***" "$(mask "authorization: $(rep k 24)")"
check_eq "authorization in curl" "curl -H 'Authorization: Basic ***'" "$(mask "curl -H 'Authorization: Basic dXNlcjpwYXNz'")"
check_eq "password=" "password=***" "$(mask "password=hunter2")"
check_eq "PASSWORD: case" "DB_PASSWORD: ***" "$(mask "DB_PASSWORD: hunter2")"
check_eq "passwd" "passwd = ***" "$(mask "passwd = hunter2")"
check_eq "secret" "client_secret=***&x=1" "$(mask "client_secret=abc123&x=1")"
check_eq "token" "token: ***" "$(mask "token: abc123")"
check_eq "api_key" "api_key=***" "$(mask "api_key=abc123")"
check_eq "apikey any case" "ApiKey=***" "$(mask "ApiKey=x")"
check_eq "apikey lower" "apikey=***" "$(mask "apikey=abc123")"
check_eq "access_key" "ACCESS_KEY=***" "$(mask "ACCESS_KEY=abc123")"
check_eq "private_key" "private_key=***" "$(mask "private_key=abc123")"
check_eq "json quoted" '{"password": "***", "n": 1}' "$(mask '{"password": "my pass phrase", "n": 1}')"
check_eq "single quoted" "secret: '***'" "$(mask "secret: 'a b c'")"
pem="$(printf -- '-----BEGIN RSA PRIVATE KEY-----\nAAAA\nBBBB\n-----END RSA PRIVATE KEY-----\nafter\n')"
check_eq "pem block" "$(printf -- '-----BEGIN RSA PRIVATE KEY-----\n***\n-----END RSA PRIVATE KEY-----\nafter\n')" "$(mask "$pem")"
check_eq "pem without END masks to the end" "$(printf -- '-----BEGIN PRIVATE KEY-----\n***')" "$(mask "$(printf -- '-----BEGIN PRIVATE KEY-----\nAAAA\nBBBB')")"

echo "== mask: left alone"
for t in "Just a normal sentence, with the word token in it." \
  "the sk-learn library and a sk- prefix" "use sk-learn-compat-extension-library here" \
  "ghp_short and AKIAshort" "a bearer of bad news" "Bearer is a word" "password=" \
  "email me at a@b.com, see https://example.com/a?b=c" "risk-averse-and-task-oriented-teams" \
  "password=***" "Bearer ***"; do
  check_eq "unchanged: $t" "$t" "$(mask "$t")"
done
check_eq "newline kept" "$(printf 'a\npassword=***\n')" "$(printf 'a\npassword=x\n' | perl "$SHARE/mask.pl")"
check_eq "no final newline kept" "password=***" "$(printf 'password=x' | perl "$SHARE/mask.pl")"
check "no trailing newline added" bash -c '[[ "$(printf "password=x" | perl "$0/mask.pl" | od -An -c | tr -d " ")" == "password=***" ]]' "$SHARE"
printf '' | perl "$SHARE/mask.pl" >"$ROOT/empty.out"
check "empty input gives empty output" test ! -s "$ROOT/empty.out"

echo "== <leader>m in the real nvim (headless)"
printf 'name=x\npassword=hunter2\ntok %s\nend\n' "$GH" >"$ROOT/buf.txt"
msgs="$("$REAL_NVIM" --headless -u NONE -n -i NONE -c "luafile $SHARE/clipedit.lua" -c 'lua Clipedit.mask()' -c 'wq' "$ROOT/buf.txt" 2>&1)"
contains "message counts lines" "masked 2 lines" "$msgs"
check_eq "file content" "name=x|password=***|tok ghp_***|end" "$(tr '\n' '|' <"$ROOT/buf.txt" | sed 's/|$//')"
check_eq "final newline kept" "10" "$(tail -c1 "$ROOT/buf.txt" | od -An -tu1 | tr -d ' ')"
printf 'nothing here' >"$ROOT/plain.txt"
msgs="$("$REAL_NVIM" --headless -u NONE -n -i NONE -c 'set nofixeol' -c "luafile $SHARE/clipedit.lua" -c 'lua Clipedit.mask()' -c 'wq' "$ROOT/plain.txt" 2>&1)"
contains "message when nothing to mask" "nothing to mask" "$msgs"
check_eq "untouched text stays without newline" "nothing here" "$(cat "$ROOT/plain.txt")"
printf 'password=a' >"$ROOT/nonl.txt"
"$REAL_NVIM" --headless -u NONE -n -i NONE -c 'set nofixeol' -c "luafile $SHARE/clipedit.lua" -c 'lua Clipedit.mask()' -c 'wq' "$ROOT/nonl.txt" >/dev/null 2>&1
check_eq "missing final newline stays missing" "password=***" "$(cat "$ROOT/nonl.txt")"
printf 'a\npassword=x\n' >"$ROOT/undo.txt"
out="$("$REAL_NVIM" --headless -u NONE -n -i NONE -c "luafile $SHARE/clipedit.lua" -c 'lua Clipedit.mask()' -c 'silent undo' -c 'lua io.stdout:write("[" .. table.concat(vim.api.nvim_buf_get_lines(0,0,-1,false), "|") .. "]")' -c 'qa!' "$ROOT/undo.txt" 2>&1)"
contains "undo restores the text" "[a|password=x]" "$out"
out="$("$REAL_NVIM" --headless -u NONE -n -i NONE -c "luafile $SHARE/clipedit.lua" -c 'lua io.stdout:write("[" .. vim.fn.maparg("<leader>m", "n") .. "]")' -c 'enew' -c 'lua io.stdout:write("[" .. vim.fn.maparg("<leader>m", "n") .. "]")' -c 'qa!' 2>&1)"
check_eq "the key is mapped in the first buffer only" "[<Lua>][]" "$(sed 's/<Lua [^>]*>/<Lua>/' <<<"$out")"

echo "== clipboard round trip (stubs)"
STUBS="$ROOT/stubs"
mkdir -p "$STUBS"
CLIP="$ROOT/clipboard"
cat >"$STUBS/pbpaste" <<S
#!/bin/bash
cat "$CLIP"
S
cat >"$STUBS/pbcopy" <<S
#!/bin/bash
cat >"$CLIP"
echo copied >>"$ROOT/pbcopy.log"
S
# NVIM_MODE: save = append a line, quit = leave it unchanged, cq = change it and exit 1.
cat >"$STUBS/nvim" <<S
#!/bin/bash
file="\${!#}"
{ echo "args: \$*"; echo "dir: \$(dirname "\$file")"
  echo "dirmode: \$(stat -f %Lp "\$(dirname "\$file")" 2>/dev/null || stat -c %a "\$(dirname "\$file")")"
  echo "filemode: \$(stat -f %Lp "\$file" 2>/dev/null || stat -c %a "\$file")"; } >"$ROOT/nvim.log"
case "\$NVIM_MODE" in
  save) printf 'EDITED' >>"\$file" ;;
  cq) printf 'EDITED' >>"\$file"; exit 1 ;;
esac
S
chmod +x "$STUBS"/*
export PATH="$STUBS:$PATH"
run() { # run <mode> <clipboard text>
  printf '%s' "$2" >"$CLIP"
  : >"$ROOT/pbcopy.log"
  NVIM_MODE="$1" bash "$CLIPEDIT"
}
left() { find "$TMPDIR" -mindepth 1 -maxdepth 1 -name "tmp.*" | wc -l | tr -d ' '; }

out="$(run save $'line one\nline two\n' 2>&1)"
check_eq "saved: prints nothing" "" "$out"
check_eq "saved: clipboard has the edit" $'line one\nline two\nEDITED' "$(cat "$CLIP")"
check_eq "saved: temp dir removed" "0" "$(left)"
log="$(cat "$ROOT/nvim.log")"
contains "nvim: no swap, undo, backup or shada" "-n -i NONE -c set noundofile noswapfile nobackup nowritebackup" "$log"
contains "nvim: dir mode 700" "dirmode: 700" "$log"
contains "nvim: file mode 600" "filemode: 600" "$log"
contains "nvim: loads the mask key" "clipedit.lua" "$log"

run quit $'keep me\n' >/dev/null
check_eq "unchanged: clipboard untouched" "keep me|" "$(tr '\n' '|' <"$CLIP")"
check_eq "unchanged: not copied" "" "$(cat "$ROOT/pbcopy.log")"
check_eq "unchanged: temp dir removed" "0" "$(left)"

run cq 'abc' >/dev/null || true
check_eq ":cq: not copied" "" "$(cat "$ROOT/pbcopy.log")"
check_eq ":cq: temp dir removed" "0" "$(left)"

printf 'no newline' >"$CLIP"
NVIM_MODE=quit bash "$CLIPEDIT" >/dev/null
check_eq "unchanged text without final newline stays as is" "no newline" "$(cat "$CLIP")"
run save '' >/dev/null
check_eq "empty clipboard opens an empty file and saves" "EDITED" "$(cat "$CLIP")"

echo "== trailing newline with the real nvim"
mkdir -p "$ROOT/realbin"
# Edits the buffer (add a character, delete it) and writes it, then quits: the file must come out byte for byte the same.
cat >"$ROOT/realbin/nvim" <<S
#!/bin/bash
exec "$REAL_NVIM" --headless -u NONE "\${@:1:\$#-2}" -c 'normal! Ax' -c 'normal! x' -c 'write' -c 'qa!' "\${!#}"
S
chmod +x "$ROOT/realbin/nvim"
for text in $'with newline\n' 'without newline' $'two\n\n'; do
  printf '%s' "$text" >"$CLIP"
  : >"$ROOT/pbcopy.log"
  PATH="$ROOT/realbin:$PATH" bash "$CLIPEDIT" >/dev/null 2>&1
  check_eq "real nvim rewrite is not a change: ${text//$'\n'/\\n}" "" "$(cat "$ROOT/pbcopy.log")"
done

echo "== a signal removes the temp dir"
# The stub nvim sends TERM to clipedit, as a killed popup would.
cat >"$STUBS/nvim" <<S
#!/bin/bash
kill -TERM \$PPID
sleep 1
S
printf 'x' >"$CLIP"
bash "$CLIPEDIT" >/dev/null 2>&1 || true
check_eq "TERM: temp dir removed" "0" "$(left)"

summary
