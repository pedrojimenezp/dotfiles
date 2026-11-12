#!/usr/bin/env bash
# Tests bin/.local/bin/review-pr with a temp origin repo, a clone and stub gh and review on PATH.
# Run: bash tests/review_pr_test.sh. Tmux only runs on a private socket. Exits non-zero when a check fails.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" # the repo under test
PASS=0
FAIL=0
ROOT="$(cd "$(mktemp -d)" && pwd -P)" # resolved, so paths match what git prints
SOCK="$ROOT/tmux.sock"
cleanup() {
  env -u TMUX tmux -S "$SOCK" kill-server >/dev/null 2>&1 || true # only the private server of this test
  rm -rf "$ROOT"
}
trap cleanup EXIT
export GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 HOME="$ROOT/home"
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
mkdir -p "$HOME"
unset TMUX

ok() { PASS=$((PASS + 1)); echo "  ok   $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL $1"; }
check() { # check "<description>" "<expected>" "<actual>"
  if [[ "$2" == "$3" ]]; then ok "$1"; else bad "$1 (expected: $2, got: $3)"; fi
}
contains() { # contains "<description>" "<needle>" "<haystack>"
  case "$3" in *"$2"*) ok "$1" ;; *) bad "$1 (missing: $2 in: $3)" ;; esac
}

STUBS="$ROOT/stubs"
mkdir -p "$STUBS"
printf '#!/bin/sh\necho "gh $*" >>"%s/gh.log"\necho develop\n' "$ROOT" >"$STUBS/gh"
printf '#!/bin/sh\necho "review $*" >>"%s/review.log"\n' "$ROOT" >"$STUBS/review"
chmod +x "$STUBS/gh" "$STUBS/review"
SCRIPT="$SRC/bin/.local/bin/review-pr"
# run <dir> <args...>: runs review-pr from <dir>; sets $out and $rc.
run() {
  local d="$1"
  shift
  rc=0
  out="$(cd "$d" && PATH="$STUBS:$PATH" bash "$SCRIPT" "$@" 2>&1)" || rc=$?
}

ORIGIN="$ROOT/origin.git"
git init -q --bare -b main "$ORIGIN"
git init -q -b main "$ROOT/seed"
git -C "$ROOT/seed" remote add origin "$ORIGIN"
echo base >"$ROOT/seed/f.txt"
git -C "$ROOT/seed" add f.txt
git -C "$ROOT/seed" commit -q -m base
git -C "$ROOT/seed" push -q origin main
git -C "$ROOT/seed" branch develop
git -C "$ROOT/seed" push -q origin develop
# pr_commit <file> <text>: commits on a branch in seed built on main and pushes it as the PR head.
git -C "$ROOT/seed" checkout -q -b prsrc
pr_commit() {
  echo "$2" >"$ROOT/seed/$1"
  git -C "$ROOT/seed" add "$1"
  git -C "$ROOT/seed" commit -q -m "$1"
  git -C "$ROOT/seed" push -q -f origin prsrc:refs/pull/123/head
}
pr_commit one.txt 1
git clone -q "$ORIGIN" "$ROOT/clone"
CLONE="$ROOT/clone"
WT="$CLONE/worktrees/pr-123"

run "$CLONE" 
check "no args: usage, exit 2" "2" "$rc"
contains "no args: message" "usage: review-pr" "$out"
run "$CLONE" abc
check "bad number: exit 2" "2" "$rc"
run "$ROOT" 123
check "outside a repo: exit 1" "1" "$rc"

echo "first open"
run "$CLONE" 123
check "first open: exit 0" "0" "$rc"
check "first open: worktree is at the PR head" "$(git -C "$ROOT/seed" rev-parse prsrc)" "$(git -C "$WT" rev-parse HEAD)"
check "first open: branch pr-123" "pr-123" "$(git -C "$WT" branch --show-current)"
contains "first open: runs review with base and path" "review --name pr-123 develop $WT" "$(cat "$ROOT/review.log")"
contains "first open: gh asked for the base" "gh pr view 123 --json baseRefName -q .baseRefName" "$(cat "$ROOT/gh.log")"
contains "first open: dependency hint" "install the dependencies" "$out"
contains "first open: prints the path" "Worktree: $WT" "$out"
git -C "$CLONE" rev-parse --verify -q origin/develop >/dev/null && ok "first open: base fetched" || bad "first open: base fetched"

echo "rerun from another worktree of the repo, PR has a new commit"
pr_commit two.txt 2
run "$WT" 123
check "fast-forward: exit 0" "0" "$rc"
check "fast-forward: worktree moved" "$(git -C "$ROOT/seed" rev-parse prsrc)" "$(git -C "$WT" rev-parse HEAD)"
check "fast-forward: no second worktree" "2" "$(git -C "$CLONE" worktree list | wc -l | tr -d ' ')"

echo "dirty worktree"
pr_commit three.txt 3
echo edit >>"$WT/one.txt"
before="$(git -C "$WT" rev-parse HEAD)"
run "$CLONE" 123
check "dirty: exit 1" "1" "$rc"
contains "dirty: says what to do" "review-pr --done 123" "$out"
check "dirty: HEAD unchanged" "$before" "$(git -C "$WT" rev-parse HEAD)"
check "dirty: edit kept" "edit" "$(tail -1 "$WT/one.txt")"
run "$CLONE" --done 123
[[ $rc -ne 0 ]] && ok "done dirty: refuses" || bad "done dirty: refuses"
contains "done dirty: git's error passes through" "contains modified or untracked files" "$out"
[[ -d "$WT" ]] && ok "done dirty: worktree kept" || bad "done dirty: worktree kept"
git -C "$CLONE" rev-parse --verify -q pr-123 >/dev/null && ok "done dirty: branch kept" || bad "done dirty: branch kept"
git -C "$WT" checkout -q one.txt
run "$CLONE" 123
check "after cleaning: fast-forwards" "0" "$rc"

echo "force-push"
git -C "$ROOT/seed" reset -q --hard main
pr_commit other.txt x
before="$(git -C "$WT" rev-parse HEAD)"
run "$CLONE" 123
check "force-push: exit 1" "1" "$rc"
contains "force-push: says what to do" "force-pushed" "$out"
contains "force-push: points to --done" "review-pr --done 123" "$out"
check "force-push: HEAD unchanged" "$before" "$(git -C "$WT" rev-parse HEAD)"
check "force-push: work still there" "3" "$(cat "$WT/three.txt")"

echo "done"
env -u TMUX tmux -S "$SOCK" -f /dev/null new-session -d -s t -n review:pr-123 "sleep 300"
run "$CLONE" --done 123
check "done clean: exit 0" "0" "$rc"
[[ ! -d "$WT" ]] && ok "done clean: worktree removed" || bad "done clean: worktree removed"
git -C "$CLONE" rev-parse --verify -q pr-123 >/dev/null && bad "done clean: branch removed" || ok "done clean: branch removed"
check "done clean: no tmux note outside tmux" "0" "$(grep -c 'tmux window' <<<"$out")"
run "$CLONE" 123
check "reopen after done: exit 0" "0" "$rc"
check "reopen after done: at the force-pushed head" "$(git -C "$ROOT/seed" rev-parse prsrc)" "$(git -C "$WT" rev-parse HEAD)"
rc=0
out="$(cd "$CLONE" && TMUX="$SOCK,1,0" PATH="$STUBS:$PATH" bash "$SCRIPT" --done 123 2>&1)" || rc=$?
check "done in tmux: exit 0" "0" "$rc"
contains "done in tmux: mentions the open window" "review:pr-123 is still open" "$out"
check "done in tmux: window not killed" "review:pr-123" "$(env -u TMUX tmux -S "$SOCK" list-windows -F '#{window_name}')"

echo "worktree folder deleted by hand"
run "$CLONE" 123
rm -rf "$WT"
run "$CLONE" 123
check "rm -rf then rerun: exit 0" "0" "$rc"
check "rm -rf then rerun: worktree is back at the PR head" "$(git -C "$ROOT/seed" rev-parse prsrc)" "$(git -C "$WT" rev-parse HEAD)"
check "rm -rf then rerun: branch pr-123" "pr-123" "$(git -C "$WT" branch --show-current)"

echo "leftover branch behind the PR (ancestor)"
pr_commit two.txt 2
rm -rf "$WT"
run "$CLONE" 123
check "ancestor branch: exit 0" "0" "$rc"
check "ancestor branch: moved to the new PR head" "$(git -C "$ROOT/seed" rev-parse prsrc)" "$(git -C "$WT" rev-parse HEAD)"

echo "leftover branch with its own commits"
echo mine >"$WT/mine.txt"
git -C "$WT" add mine.txt
git -C "$WT" commit -q -m mine
mine="$(git -C "$WT" rev-parse HEAD)"
rm -rf "$WT"
pr_commit three.txt 3
run "$CLONE" 123
check "diverged branch: exit non-zero" "1" "$rc"
contains "diverged branch: names the branch" "branch pr-123" "$out"
contains "diverged branch: says how to resolve" "git branch -D pr-123" "$out"
check "diverged branch: branch untouched" "$mine" "$(git -C "$CLONE" rev-parse pr-123)"
check "diverged branch: no worktree created" "no" "$([[ -d "$WT" ]] && echo yes || echo no)"

echo "no leftover branch"
git -C "$CLONE" branch -q -D pr-123
run "$CLONE" 123
check "missing branch: exit 0" "0" "$rc"
check "missing branch: created at the PR head" "$(git -C "$ROOT/seed" rev-parse prsrc)" "$(git -C "$WT" rev-parse HEAD)"

# ---- URL forms and submodule layout ----
# Remotes carry github.com URLs; insteadOf (raw origin stays github.com) sends fetches to the local bare repos.
git config --global protocol.file.allow always
# gh_remote <bare repo> <url>...: makes each github.com url fetch from the local bare repo.
gh_remote() {
  local bare="$1"
  shift
  local u
  for u in "$@"; do git config --global --add "url.$bare.insteadOf" "$u"; done
}
# mk_origin <dir> <pr number>: bare repo with main, develop and a PR head; prints nothing.
mk_origin() {
  git init -q --bare -b main "$1"
  git init -q -b main "$1.seed"
  git -C "$1.seed" remote add origin "$1"
  echo x >"$1.seed/x.txt"
  git -C "$1.seed" add x.txt
  git -C "$1.seed" commit -q -m x
  git -C "$1.seed" push -q origin main
  git -C "$1.seed" push -q origin main:develop
  echo "pr$2" >"$1.seed/pr.txt"
  git -C "$1.seed" add pr.txt
  git -C "$1.seed" commit -q -m pr
  git -C "$1.seed" push -q origin "HEAD:refs/pull/$2/head"
}
SUBO="$ROOT/website.git"
SUPO="$ROOT/platform.git"
mk_origin "$SUBO" 7
mk_origin "$SUPO" 5
gh_remote "$SUBO" "git@github.com:Acme/Website.git" "ssh://git@github.com/acme/website"
gh_remote "$SUPO" "https://github.com/acme/platform.git"
gh_remote "$ORIGIN" "https://github.com/Acme/Widgets.git" "git@github.com:acme/widgets"

# A single repo whose origin is a github.com URL.
git clone -q "$ORIGIN" "$ROOT/widgets"
git -C "$ROOT/widgets" remote set-url origin "https://github.com/Acme/Widgets.git"
W="$ROOT/widgets"

# A superproject with a submodule folder named Website (origin in ssh form).
git clone -q "$SUPO" "$ROOT/super"
git -C "$ROOT/super" submodule add -q "$SUBO" Website
git -C "$ROOT/super" commit -q -m sub
git -C "$ROOT/super" remote set-url origin "https://github.com/acme/platform.git"
SUPER="$ROOT/super"
git -C "$SUPER/Website" remote set-url origin "git@github.com:Acme/Website.git"
SWT="$SUPER/worktrees/pr-website-7/Website"

echo "URL in the current repo"
run "$W" "https://github.com/acme/widgets/pull/123"
check "url: exit 0" "0" "$rc"
check "url: worktree at the PR head" "$(git -C "$ROOT/seed" rev-parse prsrc)" "$(git -C "$W/worktrees/pr-123" rev-parse HEAD)"
contains "url: gh gets -R" "gh pr view -R acme/widgets 123 --json" "$(cat "$ROOT/gh.log")"
run "$W" "https://github.com/ACME/Widgets/pull/123/files#diff-1"
check "url /files#fragment: exit 0" "0" "$rc"
contains "url /files#fragment: updates the same worktree" "Updating worktree $W/worktrees/pr-123" "$out"
run "$W" "https://github.com/acme/widgets/pull/123/commits/"
check "url /commits/: exit 0" "0" "$rc"
run "$W/worktrees/pr-123" "https://github.com/acme/widgets/pull/123/"
check "url trailing slash, from its own worktree: exit 0" "0" "$rc"
git -C "$W" remote set-url origin "git@github.com:acme/widgets"
run "$W" "https://github.com/acme/widgets/pull/123"
check "ssh origin without .git: exit 0" "0" "$rc"
run "$W" --done "https://github.com/acme/widgets/pull/123"
check "done url: exit 0" "0" "$rc"
[[ ! -d "$W/worktrees/pr-123" ]] && ok "done url: worktree removed" || bad "done url: worktree removed"

echo "URL from the superproject to its submodule"
run "$SUPER" "https://github.com/acme/website/pull/7"
check "super->sub: exit 0" "0" "$rc"
check "super->sub: worktree under the superproject" "pr-7" "$(git -C "$SWT" branch --show-current)"
check "super->sub: it is a worktree of the submodule" "$(git -C "$SUBO.seed" rev-parse HEAD)" "$(git -C "$SWT" rev-parse HEAD)"
contains "super->sub: submodule lists it" "$SWT" "$(git -C "$SUPER/Website" worktree list)"
contains "super->sub: gh gets -R" "gh pr view -R acme/website 7 --json" "$(cat "$ROOT/gh.log")"
contains "super->sub: runs review" "review --name pr-website-7 develop $SWT" "$(cat "$ROOT/review.log")"
git -C "$SUPER" config -f .gitmodules submodule.Website.url "https://github.com/Acme/Website.git" # url hint path
run "$SUPER" "https://github.com/acme/website/pull/7"
check "super->sub with a matching .gitmodules url: exit 0" "0" "$rc"
contains "super->sub with a matching .gitmodules url: same worktree" "Updating worktree $SWT" "$out"
git -C "$SUPER" checkout -q .gitmodules
run "$SUPER/Website" "https://github.com/acme/website/pull/7/files"
check "inside the submodule: exit 0" "0" "$rc"
contains "inside the submodule: same worktree" "Updating worktree $SWT" "$out"
run "$SUPER/Website" 7
check "number inside a submodule: exit 0, same worktree" "0" "$rc"
contains "number inside a submodule: same layout" "Updating worktree $SWT" "$out"
git -C "$SUPER" worktree add -q "$SUPER/feat" -b feat
git -C "$SUPER/feat" submodule update -q --init
git -C "$SUPER/feat/Website" remote set-url origin "git@github.com:Acme/Website.git"
run "$SUPER/feat" "https://github.com/acme/website/pull/7"
check "from a feature worktree of the superproject: exit 0" "0" "$rc"
contains "feature worktree: lands under the main checkout" "Updating worktree $SWT" "$out"
git -C "$SUPER" worktree remove -f -f "$SUPER/feat"

echo "two PRs of the same submodule"
git -C "$SUBO.seed" push -q origin HEAD:refs/pull/8/head
run "$SUPER" "https://github.com/acme/website/pull/8"
check "second PR: exit 0" "0" "$rc"
contains "second PR: its own window name" "review --name pr-website-8 develop $SUPER/worktrees/pr-website-8/Website" "$(cat "$ROOT/review.log")"
check "second PR: first worktree kept" "pr-7" "$(git -C "$SWT" branch --show-current)"
env -u TMUX tmux -S "$SOCK" -f /dev/null new-session -d -s u -n review:pr-website-7 "sleep 300"
env -u TMUX tmux -S "$SOCK" new-window -t u -n review:pr-website-8 "sleep 300"
rc=0
out="$(cd "$SUPER" && TMUX="$SOCK,1,0" PATH="$STUBS:$PATH" bash "$SCRIPT" --done "https://github.com/acme/website/pull/8" 2>&1)" || rc=$?
check "done second PR in tmux: exit 0" "0" "$rc"
contains "done second PR in tmux: names its window" "review:pr-website-8 is still open" "$out"
check "done second PR in tmux: other PR's name not mentioned" "0" "$(grep -c 'pr-website-7' <<<"$out")"
env -u TMUX tmux -S "$SOCK" kill-server >/dev/null 2>&1 || true

echo "URL of the superproject, run from its submodule"
run "$SUPER/Website" "https://github.com/acme/platform/pull/5"
check "sub->super: exit 0" "0" "$rc"
check "sub->super: single layout in the superproject" "pr-5" "$(git -C "$SUPER/worktrees/pr-5" branch --show-current)"
run "$SUPER" --done "https://github.com/acme/platform/pull/5"
check "done super: exit 0" "0" "$rc"

echo "no match"
before="$(find "$SUPER" -path "$SUPER/.git" -prune -o -path "$SUPER/Website/.git" -prune -o -print | sort)"
run "$SUPER" "https://github.com/acme/nothing/pull/1"
check "no match: exit 1" "1" "$rc"
contains "no match: message" "review-pr: no local clone of acme/nothing here (looked in $SUPER and its submodules)" "$out"
check "no match: nothing created" "$before" "$(find "$SUPER" -path "$SUPER/.git" -prune -o -path "$SUPER/Website/.git" -prune -o -print | sort)"
check "no match: no branch" "" "$(git -C "$SUPER" branch --list pr-1)"
run "$ROOT" "https://github.com/acme/website/pull/7"
check "url outside a repo: exit 1" "1" "$rc"

echo "bad arguments"
for a in "https://github.com/acme/website/issues/7" "https://example.com/a/b/pull/1" "https://github.com/acme/website/pull/x" "github.com/acme/website/pull/7" "7x"; do
  run "$SUPER" "$a"
  check "bad argument '$a': exit 2" "2" "$rc"
done
run "$SUPER" 7 8
check "two arguments: exit 2" "2" "$rc"

echo "done in the submodule layout"
echo edit >>"$SWT/pr.txt"
run "$SUPER" --done "https://github.com/acme/website/pull/7"
[[ $rc -ne 0 ]] && ok "done dirty (submodule layout): refuses" || bad "done dirty (submodule layout): refuses"
[[ -d "$SWT" ]] && ok "done dirty (submodule layout): worktree kept" || bad "done dirty (submodule layout): worktree kept"
git -C "$SWT" checkout -q pr.txt
run "$SUPER" --done "https://github.com/acme/website/pull/7"
check "done (submodule layout): exit 0" "0" "$rc"
[[ ! -d "$SWT" ]] && ok "done (submodule layout): worktree removed" || bad "done (submodule layout): worktree removed"
[[ ! -d "$SUPER/worktrees/pr-website-7" ]] && ok "done (submodule layout): empty folder removed" || bad "done (submodule layout): empty folder removed"
check "done (submodule layout): branch removed" "" "$(git -C "$SUPER/Website" branch --list pr-7)"

echo
echo "passed: $PASS, failed: $FAIL"
[[ $FAIL -eq 0 ]]
