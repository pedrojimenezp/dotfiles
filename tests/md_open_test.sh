#!/usr/bin/env bash
# shellcheck disable=SC2016,SC1091
# Tests bin/.local/bin/md-open: page structure for Markdown, .mmd and stdin input, --name and --dir, safe embedding
# of the source, an offline page, mode 700, old-page cleanup and the symlinked command. open and xdg-open are
# stubs on PATH, so no browser starts. If Chrome or Chromium is already installed, a last section renders a sample
# page headless and checks the DOM. Run: bash tests/md_open_test.sh
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$ROOT"' EXIT
export TMPDIR="$ROOT/tmp"
mkdir -p "$TMPDIR" "$ROOT/stubs" "$ROOT/docs/img"
for s in open xdg-open; do
  printf '#!/bin/sh\necho "$1" >> "%s/opened"\n' "$ROOT" >"$ROOT/stubs/$s"
  chmod +x "$ROOT/stubs/$s"
done
export PATH="$ROOT/stubs:$PATH"
MO="$SRC/bin/.local/bin/md-open"
SHARE="$SRC/bin/.local/share/md-open"

run() { # run <args...>: stdout+stderr in $OUT, status in $RC; the page, when any, in $PAGE
  : >"$ROOT/opened"
  RC=0
  OUT="$("$MO" "$@" 2>&1 </dev/null)" || RC=$?
  PAGE="$(head -n 1 "$ROOT/opened")"
}
run_stdin() { # run_stdin <input file> <args...>
  local in="$1"
  shift
  : >"$ROOT/opened"
  RC=0
  OUT="$("$MO" "$@" 2>&1 <"$in")" || RC=$?
  PAGE="$(head -n 1 "$ROOT/opened")"
}
page() { cat "$PAGE"; }

cat >"$ROOT/docs/doc.md" <<'EOT'
# Title

| a | b |
|---|---|
| 1 | 2 |

- [x] done
- [ ] todo

~~strike~~ and https://example.org

```lua
x = 1
```

```mermaid
graph LR
A-->B
```

![pic](img/p.png)
EOT

run "$ROOT/docs/doc.md"
check_eq "markdown: exit 0" 0 "$RC"
contains "markdown: mode" 'data-mode="md"' "$(page)"
contains "markdown: title is the file name" '<title>doc.md</title>' "$(page)"
contains "markdown: source embedded, escaped" '| 1 | 2 |' "$(page)"
contains "markdown: fence body escaped" 'A--&gt;B' "$(page)"
contains "markdown: base is the file's folder" "<base href=\"file://$ROOT/docs/\">" "$(page)"
for lib in marked.umd.js purify.min.js highlight.min.js github-markdown.css github.min.css github-dark.min.css; do
  contains "markdown: references $lib" "file://$SHARE/$lib" "$(page)"
  check "$lib exists in the share folder" test -s "$SHARE/$lib"
done
contains "mermaid: script path" "data-mermaid=\"file://$SHARE/mermaid.min.js\"" "$(page)"
check "mermaid.min.js exists in the share folder" test -s "$SHARE/mermaid.min.js"
contains "markdown: width like GitHub" 'max-width: 980px' "$(page)"
contains "theme follows the system" 'prefers-color-scheme' "$(page)"
contains "highlight themes switch by scheme" 'github-dark.min.css" media="(prefers-color-scheme: dark)"' "$(page)"
contains "prints one line with the path" "md-open: $PAGE" "$OUT"
check_eq "opened the page" "$PAGE" "$(cat "$ROOT/opened")"
check "page folder is mode 700" test "$(stat -c %a "$(dirname "$PAGE")" 2>/dev/null || stat -f %Lp "$(dirname "$PAGE")")" = 700
check "page folder name" bash -c '[[ "$(basename "$(dirname "$1")")" == md-open.* ]]' _ "$PAGE"
check "only the page is written" test "$(find "$(dirname "$PAGE")" -type f | wc -l | tr -d ' ')" = 1

printf 'graph TD\n  A --> B\n' >"$ROOT/d.mmd"
run "$ROOT/d.mmd"
contains ".mmd: diagram mode" 'data-mode="diagram"' "$(page)"
contains ".mmd: title" '<title>d.mmd</title>' "$(page)"
contains ".mmd: source" 'A --&gt; B' "$(page)"
cp "$ROOT/d.mmd" "$ROOT/d.mermaid"
run "$ROOT/d.mermaid"
contains ".mermaid: diagram mode" 'data-mode="diagram"' "$(page)"

run_stdin "$ROOT/docs/doc.md"
contains "stdin with a fence: markdown" 'data-mode="md"' "$(page)"
contains "stdin: default name" '<title>stdin</title>' "$(page)"
contains "stdin: default dir is the cwd" "<base href=\"file://$PWD/\">" "$(page)"
run_stdin "$ROOT/d.mmd" -
contains "stdin without a fence: one diagram" 'data-mode="diagram"' "$(page)"
printf '# Plain\n\nno diagrams\n' >"$ROOT/plain.md"
run_stdin "$ROOT/plain.md"
contains "stdin plain markdown, no name: a diagram (fence rule)" 'data-mode="diagram"' "$(page)"
run_stdin "$ROOT/plain.md" --name notes.md
contains "stdin named .md: markdown" 'data-mode="md"' "$(page)"
run_stdin "$ROOT/d.mmd" --name x.mmd
contains "stdin named .mmd: diagram" 'data-mode="diagram"' "$(page)"
run_stdin "$ROOT/d.mmd" --name 'doc.md:12' --dir "$ROOT/docs"
contains "--name: title" '<title>doc.md:12</title>' "$(page)"
contains "--name with a block: diagram" 'data-mode="diagram"' "$(page)"
contains "--dir: base" "<base href=\"file://$ROOT/docs/\">" "$(page)"
mkdir -p "$ROOT/sp ace"
run_stdin "$ROOT/plain.md" --name p.md --dir "$ROOT/sp ace"
contains "--dir with a space is percent-encoded" "file://$ROOT/sp%20ace/" "$(page)"
run "$ROOT/docs/doc.md" --name Other --dir "$ROOT"
contains "file: --name wins" '<title>Other</title>' "$(page)"
contains "file: --dir wins" "<base href=\"file://$ROOT/\">" "$(page)"

: >"$ROOT/empty.mmd"
run "$ROOT/empty.mmd"
check_eq "empty .mmd: exit 1" 1 "$RC"
contains "empty .mmd: message" 'no diagram found' "$OUT"
check_eq "empty .mmd: nothing opened" "" "$PAGE"
run "$ROOT/missing.md"
check_eq "missing file: exit 1" 1 "$RC"
run --bogus
check_eq "unknown option: exit 1" 1 "$RC"
run --dir "$ROOT/nope" "$ROOT/d.mmd"
check_eq "missing --dir: exit 1" 1 "$RC"
check_eq "failed runs leave no folder behind" 0 "$(find "$TMPDIR" -maxdepth 1 -name 'md-open.*' -type d -newer "$ROOT/d.mmd" -empty | wc -l | tr -d ' ')"

cat >"$ROOT/evil.md" <<'EOT'
# x </script><script>alert(1)</script>

<textarea></textarea></textarea><b>x</b> & <i>
EOT
run "$ROOT/evil.md"
contains "escaping: script end tag" '&lt;/script&gt;&lt;script&gt;alert(1)&lt;/script&gt;' "$(page)"
contains "escaping: textarea end tag" '&lt;/textarea&gt;&lt;b&gt;x&lt;/b&gt; &amp; &lt;i&gt;' "$(page)"
check "escaping: only the page's own script tags" test "$(grep -o '</script>' "$PAGE" | wc -l | tr -d ' ')" = 4
check "escaping: one textarea end tag" test "$(grep -o '</textarea>' "$PAGE" | wc -l | tr -d ' ')" = 1

check "offline: no http(s) src or href" bash -c '! grep -Eqi "(src|href)=.?https?:" "$1"' _ "$PAGE"
check "offline: no http(s) url in the page" bash -c '! grep -Eqi "https?://" "$1"' _ "$PAGE"
check "offline: no @import or import()" bash -c '! grep -Eqi "@import|import\(" "$1"' _ "$PAGE"
check "offline: stylesheets are file:// links" bash -c '! grep -E "<link" "$1" | grep -qv "href=\"file://"' _ "$PAGE"
contains "offline: CSP blocks connections" "connect-src 'none'" "$(page)"

old="$TMPDIR/md-open.old123"
older="$TMPDIR/mermaid-open.old456"
keep="$TMPDIR/other-dir"
mkdir -p "$old" "$older" "$keep"
touch -t 202001010000 "$old" "$older" "$keep"
run "$ROOT/d.mmd"
check "md-open pages older than a day are removed" test ! -e "$old"
check "old mermaid-open pages are removed" test ! -e "$older"
check "other folders are left alone" test -d "$keep"
check "new page is kept" test -f "$PAGE"

mkdir -p "$ROOT/home/.local"
ln -s "$SRC/bin/.local/bin" "$ROOT/home/.local/bin"
: >"$ROOT/opened"
"$ROOT/home/.local/bin/md-open" "$ROOT/docs/doc.md" >/dev/null
PAGE="$(head -n 1 "$ROOT/opened")"
contains "works through a symlink" "file://$SHARE/marked.umd.js" "$(page)"

# Headless render: a real browser, only when one is already installed.
CHROME=""
for c in "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" "/Applications/Chromium.app/Contents/MacOS/Chromium" google-chrome chromium chromium-browser; do
  if [[ -x "$c" ]] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi
done
if [[ -n "$CHROME" ]]; then
  cat >"$ROOT/docs/render.md" <<'EOT'
# Render

| a | b |
|---|---|
| 1 | 2 |

- [x] done
- [ ] todo

```lua
local x = 1
```

![pic](img/p.png)

```mermaid
graph LR
A-->B
```

```mermaid
graph LR
A-->
```

<script>document.title = "pwned"</script>
<img src="x.png" onerror="document.title = 'pwned'">
EOT
  run "$ROOT/docs/render.md"
  dom="$("$CHROME" --headless=new --disable-gpu --no-sandbox --user-data-dir="$ROOT/chrome" \
    --virtual-time-budget=20000 --dump-dom "file://$PAGE" 2>/dev/null || true)"
  article="$(sed -n '/<main/,/<textarea/p' <<<"$dom")"
  contains "render: table" '<td>1</td>' "$article"
  contains "render: task list" '<input checked="" disabled="" type="checkbox">' "$article"
  contains "render: task list class" 'class="task-list-item"' "$article"
  contains "render: code has hljs classes" 'class="hljs-keyword"' "$article"
  contains "render: image keeps its relative src" '<img src="img/p.png"' "$article"
  contains "render: base is the source folder" "<base href=\"file://$ROOT/docs/\">" "$dom"
  check_eq "render: one diagram" 1 "$(grep -o '<svg' <<<"$article" | wc -l | tr -d ' ')"
  contains "render: broken diagram shows its error" 'class="err">' "$article"
  contains "render: the title is still the file name" '<title>render.md</title>' "$dom"
  check "render: script and onerror stripped" bash -c '! grep -Eq "<script|onerror" <<<"$1"' _ "$article"

  run "$ROOT/d.mmd"
  dom="$("$CHROME" --headless=new --disable-gpu --no-sandbox --user-data-dir="$ROOT/chrome" \
    --virtual-time-budget=20000 --dump-dom "file://$PAGE" 2>/dev/null || true)"
  contains "render: .mmd heading" '<h2>d.mmd</h2>' "$dom"
  contains "render: .mmd diagram" '<svg' "$dom"
else
  echo "  skip headless render: no Chrome or Chromium installed"
fi

summary
