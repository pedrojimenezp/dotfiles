#!/usr/bin/env bash
# shellcheck disable=SC2016,SC1091
# Tests bin/.local/bin/mermaid-open: block extraction, .mmd and stdin input, no blocks, HTML escaping, an
# offline page, old-page cleanup and the symlinked command. open and xdg-open are stubs on PATH, so no browser
# starts. If Google Chrome is already installed, one check renders the page headless. Run: bash tests/mermaid_open_test.sh
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$ROOT"' EXIT
export TMPDIR="$ROOT/tmp"
mkdir -p "$TMPDIR" "$ROOT/stubs"
for s in open xdg-open; do
  printf '#!/bin/sh\necho "$1" >> "%s/opened"\n' "$ROOT" >"$ROOT/stubs/$s"
  chmod +x "$ROOT/stubs/$s"
done
export PATH="$ROOT/stubs:$PATH"
MO="$SRC/bin/.local/bin/mermaid-open"

run() { # run <args...>: stdout+stderr in $OUT, status in $RC; the page, when any, in $PAGE
  : >"$ROOT/opened"
  RC=0
  OUT="$("$MO" "$@" 2>&1)" || RC=$?
  PAGE="$(head -n 1 "$ROOT/opened")"
}
sections() { grep -c '^<section>' "$PAGE"; }

cat >"$ROOT/doc.md" <<'EOT'
# Title
```mermaid
graph LR
A-->B
```
text
```lua
x = 1
```
  ```mermaid
  sequenceDiagram
  A->>B: hi
  ```
~~~mermaid
not a mermaid fence
~~~
```mermaid
unclosed
EOT

run "$ROOT/doc.md"
check_eq "markdown: exit 0" 0 "$RC"
check_eq "markdown: two blocks" 2 "$(sections)"
contains "markdown: first block line" '<h2>doc.md:2</h2>' "$(cat "$PAGE")"
contains "markdown: indented block line" '<h2>doc.md:10</h2>' "$(cat "$PAGE")"
contains "markdown: body kept" 'graph LR
A--&gt;B</pre>' "$(cat "$PAGE")"
check "markdown: non-mermaid fence ignored" bash -c '! grep -q "x = 1" "$1"' _ "$PAGE"
check "markdown: unclosed block ignored" bash -c '! grep -q unclosed "$1"' _ "$PAGE"
contains "prints one line with the path" "mermaid-open: $PAGE" "$OUT"
check_eq "opened the page" "$PAGE" "$(cat "$ROOT/opened")"
check "page folder is mode 700" test "$(stat -c %a "$(dirname "$PAGE")" 2>/dev/null || stat -f %Lp "$(dirname "$PAGE")")" = 700
check "mermaid.min.js copied next to the page" cmp -s "$SRC/bin/.local/share/mermaid-open/mermaid.min.js" "$(dirname "$PAGE")/mermaid.min.js"

printf 'graph TD\n  A --> B\n' >"$ROOT/d.mmd"
run "$ROOT/d.mmd"
check_eq ".mmd: one diagram" 1 "$(sections)"
contains ".mmd: heading" '<h2>d.mmd:1</h2>' "$(cat "$PAGE")"
cp "$ROOT/d.mmd" "$ROOT/d.mermaid"
run "$ROOT/d.mermaid"
check_eq ".mermaid: one diagram" 1 "$(sections)"

RC=0
: >"$ROOT/opened"
OUT="$("$MO" <"$ROOT/doc.md" 2>&1)" || RC=$?
PAGE="$(head -n 1 "$ROOT/opened")"
check_eq "stdin markdown: two blocks" 2 "$(sections)"
contains "stdin: heading" '<h2>stdin:2</h2>' "$(cat "$PAGE")"
: >"$ROOT/opened"
"$MO" - <"$ROOT/d.mmd" >/dev/null
PAGE="$(head -n 1 "$ROOT/opened")"
check_eq "stdin bare diagram: one" 1 "$(sections)"
contains "stdin bare diagram: heading" '<h2>stdin:1</h2>' "$(cat "$PAGE")"

printf '# nothing\n```lua\nx\n```\n' >"$ROOT/none.md"
run "$ROOT/none.md"
check_eq "no blocks: exit 1" 1 "$RC"
contains "no blocks: message" 'no mermaid diagrams found' "$OUT"
check_eq "no blocks: nothing opened" "" "$PAGE"
: >"$ROOT/empty.mmd"
run "$ROOT/empty.mmd"
check_eq "empty .mmd: exit 1" 1 "$RC"
run "$ROOT/missing.md"
check_eq "missing file: exit 1" 1 "$RC"
check_eq "failed runs leave no folder behind" 0 "$(find "$TMPDIR" -maxdepth 1 -name 'mermaid-open.*' -newer "$ROOT/none.md" -type d | wc -l | tr -d ' ')"

cat >"$ROOT/evil.md" <<'EOT'
```mermaid
graph LR
A["</script><b>x</b>"] --> B
```
EOT
run "$ROOT/evil.md"
html="$(cat "$PAGE")"
contains "escaping: script end tag" '&lt;/script&gt;&lt;b&gt;x&lt;/b&gt;' "$html"
check "escaping: page has only its own two script tags" test "$(grep -o '</script>' "$PAGE" | wc -l | tr -d ' ')" = 2
check "escaping: no raw <b>" bash -c '! grep -q "<b>" "$1"' _ "$PAGE"

check "offline: no http(s) src or href" bash -c '! grep -Eqi "(src|href)=.?https?:" "$1"' _ "$PAGE"
check "offline: no http(s) url in the page" bash -c '! grep -Eqi "https?://" "$1"' _ "$PAGE"
check "offline: no stylesheet or import" bash -c '! grep -Eqi "<link|@import|import\(" "$1"' _ "$PAGE"
contains "theme follows the system" 'prefers-color-scheme' "$html"

old="$TMPDIR/mermaid-open.old123"
keep="$TMPDIR/other-dir"
mkdir -p "$old" "$keep"
touch -t 202001010000 "$old" "$keep"
run "$ROOT/d.mmd"
check "pages older than a day are removed" test ! -e "$old"
check "other folders are left alone" test -d "$keep"
check "new page is kept" test -f "$PAGE"

mkdir -p "$ROOT/home/.local"
ln -s "$SRC/bin/.local/bin" "$ROOT/home/.local/bin"
run_link="$ROOT/home/.local/bin/mermaid-open"
: >"$ROOT/opened"
"$run_link" "$ROOT/d.mmd" >/dev/null
PAGE="$(head -n 1 "$ROOT/opened")"
check "works through a symlink" test -f "$(dirname "$PAGE")/mermaid.min.js"

CHROME=""
for c in "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome chromium chromium-browser; do
  if [[ -x "$c" ]] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi
done
if [[ -n "$CHROME" ]]; then
  run "$ROOT/doc.md"
  dom="$("$CHROME" --headless=new --disable-gpu --no-sandbox --user-data-dir="$ROOT/chrome" \
    --virtual-time-budget=15000 --dump-dom "file://$PAGE" 2>/dev/null || true)"
  check "headless Chrome renders an <svg>" bash -c 'grep -q "<svg" <<<"$1"' _ "$dom"
else
  echo "  skip headless render: no Chrome or Chromium installed"
fi

summary
