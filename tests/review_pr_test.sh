#!/usr/bin/env bash
# Tests bin/.local/bin/review-pr with a temp origin repo, a clone and stub gh and review on PATH.
# Run: bash tests/review_pr_test.sh. Tmux only runs on a private socket. Exits non-zero when a check fails.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" # the repo under test
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


STUBS="$ROOT/stubs"
mkdir -p "$STUBS"
# gh prints head branch, cross-repo flag and base for the PR number, from $ROOT/pr-<n>.meta (default: a fork PR on develop).
cat >"$STUBS/gh" <<STUB
#!/bin/sh
echo "gh \$*" >>"$ROOT/gh.log"
shift 2
while [ \$# -gt 0 ]; do
  case "\$1" in -R) shift 2 ;; -*) shift ;; *) n="\$1"; break ;; esac
done
if [ -f "$ROOT/pr-\$n.meta" ]; then cat "$ROOT/pr-\$n.meta"; else printf 'fork-head\ntrue\ndevelop\n'; fi
STUB
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
check_eq "no args: usage, exit 2" "2" "$rc"
contains "no args: message" "usage: review-pr" "$out"
run "$CLONE" abc
check_eq "bad number: exit 2" "2" "$rc"
run "$ROOT" 123
check_eq "outside a repo: exit 1" "1" "$rc"

echo "first open"
run "$CLONE" 123
check_eq "first open: exit 0" "0" "$rc"
check_eq "first open: worktree is at the PR head" "$(git -C "$ROOT/seed" rev-parse prsrc)" "$(git -C "$WT" rev-parse HEAD)"
check_eq "first open: branch pr-123" "pr-123" "$(git -C "$WT" branch --show-current)"
contains "first open: runs review with base and path" "review --name pr-123 develop $WT" "$(cat "$ROOT/review.log")"
contains "first open: gh asked for the base" "gh pr view 123 --json headRefName,isCrossRepository,baseRefName" "$(cat "$ROOT/gh.log")"
contains "first open: dependency hint" "install the dependencies" "$out"
contains "first open: prints the path" "Worktree: $WT" "$out"
git -C "$CLONE" rev-parse --verify -q origin/develop >/dev/null && ok "first open: base fetched" || bad "first open: base fetched"

echo "rerun from another worktree of the repo, PR has a new commit"
pr_commit two.txt 2
run "$WT" 123
check_eq "fast-forward: exit 0" "0" "$rc"
check_eq "fast-forward: worktree moved" "$(git -C "$ROOT/seed" rev-parse prsrc)" "$(git -C "$WT" rev-parse HEAD)"
check_eq "fast-forward: no second worktree" "2" "$(git -C "$CLONE" worktree list | wc -l | tr -d ' ')"

echo "dirty worktree"
pr_commit three.txt 3
echo edit >>"$WT/one.txt"
before="$(git -C "$WT" rev-parse HEAD)"
run "$CLONE" 123
check_eq "dirty: exit 1" "1" "$rc"
contains "dirty: says what to do" "review-pr --done 123" "$out"
check_eq "dirty: HEAD unchanged" "$before" "$(git -C "$WT" rev-parse HEAD)"
check_eq "dirty: edit kept" "edit" "$(tail -1 "$WT/one.txt")"
run "$CLONE" --done 123
[[ $rc -ne 0 ]] && ok "done dirty: refuses" || bad "done dirty: refuses"
contains "done dirty: git's error passes through" "contains modified or untracked files" "$out"
[[ -d "$WT" ]] && ok "done dirty: worktree kept" || bad "done dirty: worktree kept"
git -C "$CLONE" rev-parse --verify -q pr-123 >/dev/null && ok "done dirty: branch kept" || bad "done dirty: branch kept"
git -C "$WT" checkout -q one.txt
run "$CLONE" 123
check_eq "after cleaning: fast-forwards" "0" "$rc"

echo "force-push"
git -C "$ROOT/seed" reset -q --hard main
pr_commit other.txt x
before="$(git -C "$WT" rev-parse HEAD)"
run "$CLONE" 123
check_eq "force-push: exit 1" "1" "$rc"
contains "force-push: says what to do" "force-pushed" "$out"
contains "force-push: points to --done" "review-pr --done 123" "$out"
check_eq "force-push: HEAD unchanged" "$before" "$(git -C "$WT" rev-parse HEAD)"
check_eq "force-push: work still there" "3" "$(cat "$WT/three.txt")"

echo "done"
env -u TMUX tmux -S "$SOCK" -f /dev/null new-session -d -s t -n review:pr-123 "sleep 300"
run "$CLONE" --done 123
check_eq "done clean: exit 0" "0" "$rc"
[[ ! -d "$WT" ]] && ok "done clean: worktree removed" || bad "done clean: worktree removed"
git -C "$CLONE" rev-parse --verify -q pr-123 >/dev/null && bad "done clean: branch removed" || ok "done clean: branch removed"
check_eq "done clean: no tmux note outside tmux" "0" "$(grep -c 'tmux window' <<<"$out")"
run "$CLONE" 123
check_eq "reopen after done: exit 0" "0" "$rc"
check_eq "reopen after done: at the force-pushed head" "$(git -C "$ROOT/seed" rev-parse prsrc)" "$(git -C "$WT" rev-parse HEAD)"
rc=0
out="$(cd "$CLONE" && TMUX="$SOCK,1,0" PATH="$STUBS:$PATH" bash "$SCRIPT" --done 123 2>&1)" || rc=$?
check_eq "done in tmux: exit 0" "0" "$rc"
contains "done in tmux: mentions the open window" "review:pr-123 is still open" "$out"
check_eq "done in tmux: window not killed" "review:pr-123" "$(env -u TMUX tmux -S "$SOCK" list-windows -F '#{window_name}')"

echo "worktree folder deleted by hand"
run "$CLONE" 123
rm -rf "$WT"
run "$CLONE" 123
check_eq "rm -rf then rerun: exit 0" "0" "$rc"
check_eq "rm -rf then rerun: worktree is back at the PR head" "$(git -C "$ROOT/seed" rev-parse prsrc)" "$(git -C "$WT" rev-parse HEAD)"
check_eq "rm -rf then rerun: branch pr-123" "pr-123" "$(git -C "$WT" branch --show-current)"

echo "leftover branch behind the PR (ancestor)"
pr_commit two.txt 2
rm -rf "$WT"
run "$CLONE" 123
check_eq "ancestor branch: exit 0" "0" "$rc"
check_eq "ancestor branch: moved to the new PR head" "$(git -C "$ROOT/seed" rev-parse prsrc)" "$(git -C "$WT" rev-parse HEAD)"

echo "leftover branch with its own commits"
echo mine >"$WT/mine.txt"
git -C "$WT" add mine.txt
git -C "$WT" commit -q -m mine
mine="$(git -C "$WT" rev-parse HEAD)"
rm -rf "$WT"
pr_commit three.txt 3
run "$CLONE" 123
check_eq "diverged branch: exit non-zero" "1" "$rc"
contains "diverged branch: names the branch" "branch pr-123" "$out"
contains "diverged branch: says how to resolve" "git branch -D pr-123" "$out"
check_eq "diverged branch: branch untouched" "$mine" "$(git -C "$CLONE" rev-parse pr-123)"
check_eq "diverged branch: no worktree created" "no" "$([[ -d "$WT" ]] && echo yes || echo no)"

echo "no leftover branch"
git -C "$CLONE" branch -q -D pr-123
run "$CLONE" 123
check_eq "missing branch: exit 0" "0" "$rc"
check_eq "missing branch: created at the PR head" "$(git -C "$ROOT/seed" rev-parse prsrc)" "$(git -C "$WT" rev-parse HEAD)"

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
check_eq "url: exit 0" "0" "$rc"
check_eq "url: worktree at the PR head" "$(git -C "$ROOT/seed" rev-parse prsrc)" "$(git -C "$W/worktrees/pr-123" rev-parse HEAD)"
contains "url: gh gets -R" "gh pr view -R acme/widgets 123 --json" "$(cat "$ROOT/gh.log")"
run "$W" "https://github.com/ACME/Widgets/pull/123/files#diff-1"
check_eq "url /files#fragment: exit 0" "0" "$rc"
contains "url /files#fragment: updates the same worktree" "Updating worktree $W/worktrees/pr-123" "$out"
run "$W" "https://github.com/acme/widgets/pull/123/commits/"
check_eq "url /commits/: exit 0" "0" "$rc"
run "$W/worktrees/pr-123" "https://github.com/acme/widgets/pull/123/"
check_eq "url trailing slash, from its own worktree: exit 0" "0" "$rc"
git -C "$W" remote set-url origin "git@github.com:acme/widgets"
run "$W" "https://github.com/acme/widgets/pull/123"
check_eq "ssh origin without .git: exit 0" "0" "$rc"
run "$W" --done "https://github.com/acme/widgets/pull/123"
check_eq "done url: exit 0" "0" "$rc"
[[ ! -d "$W/worktrees/pr-123" ]] && ok "done url: worktree removed" || bad "done url: worktree removed"

echo "URL from the superproject to its submodule"
run "$SUPER" "https://github.com/acme/website/pull/7"
check_eq "super->sub: exit 0" "0" "$rc"
check_eq "super->sub: worktree under the superproject" "pr-7" "$(git -C "$SWT" branch --show-current)"
check_eq "super->sub: it is a worktree of the submodule" "$(git -C "$SUBO.seed" rev-parse HEAD)" "$(git -C "$SWT" rev-parse HEAD)"
contains "super->sub: submodule lists it" "$SWT" "$(git -C "$SUPER/Website" worktree list)"
contains "super->sub: gh gets -R" "gh pr view -R acme/website 7 --json" "$(cat "$ROOT/gh.log")"
contains "super->sub: runs review" "review --name pr-website-7 develop $SWT" "$(cat "$ROOT/review.log")"
git -C "$SUPER" config -f .gitmodules submodule.Website.url "https://github.com/Acme/Website.git" # url hint path
run "$SUPER" "https://github.com/acme/website/pull/7"
check_eq "super->sub with a matching .gitmodules url: exit 0" "0" "$rc"
contains "super->sub with a matching .gitmodules url: same worktree" "Updating worktree $SWT" "$out"
git -C "$SUPER" checkout -q .gitmodules
run "$SUPER/Website" "https://github.com/acme/website/pull/7/files"
check_eq "inside the submodule: exit 0" "0" "$rc"
contains "inside the submodule: same worktree" "Updating worktree $SWT" "$out"
run "$SUPER/Website" 7
check_eq "number inside a submodule: exit 0, same worktree" "0" "$rc"
contains "number inside a submodule: same layout" "Updating worktree $SWT" "$out"
git -C "$SUPER" worktree add -q "$SUPER/feat" -b feat
git -C "$SUPER/feat" submodule update -q --init
git -C "$SUPER/feat/Website" remote set-url origin "git@github.com:Acme/Website.git"
run "$SUPER/feat" "https://github.com/acme/website/pull/7"
check_eq "from a feature worktree of the superproject: exit 0" "0" "$rc"
contains "feature worktree: lands under the main checkout" "Updating worktree $SWT" "$out"
git -C "$SUPER" worktree remove -f -f "$SUPER/feat"

echo "two PRs of the same submodule"
git -C "$SUBO.seed" push -q origin HEAD:refs/pull/8/head
run "$SUPER" "https://github.com/acme/website/pull/8"
check_eq "second PR: exit 0" "0" "$rc"
contains "second PR: its own window name" "review --name pr-website-8 develop $SUPER/worktrees/pr-website-8/Website" "$(cat "$ROOT/review.log")"
check_eq "second PR: first worktree kept" "pr-7" "$(git -C "$SWT" branch --show-current)"
env -u TMUX tmux -S "$SOCK" -f /dev/null new-session -d -s u -n review:pr-website-7 "sleep 300"
env -u TMUX tmux -S "$SOCK" new-window -t u -n review:pr-website-8 "sleep 300"
rc=0
out="$(cd "$SUPER" && TMUX="$SOCK,1,0" PATH="$STUBS:$PATH" bash "$SCRIPT" --done "https://github.com/acme/website/pull/8" 2>&1)" || rc=$?
check_eq "done second PR in tmux: exit 0" "0" "$rc"
contains "done second PR in tmux: names its window" "review:pr-website-8 is still open" "$out"
check_eq "done second PR in tmux: other PR's name not mentioned" "0" "$(grep -c 'pr-website-7' <<<"$out")"
env -u TMUX tmux -S "$SOCK" kill-server >/dev/null 2>&1 || true

echo "URL of the superproject, run from its submodule"
run "$SUPER/Website" "https://github.com/acme/platform/pull/5"
check_eq "sub->super: exit 0" "0" "$rc"
check_eq "sub->super: single layout in the superproject" "pr-5" "$(git -C "$SUPER/worktrees/pr-5" branch --show-current)"
run "$SUPER" --done "https://github.com/acme/platform/pull/5"
check_eq "done super: exit 0" "0" "$rc"

echo "no match"
before="$(find "$SUPER" -path "$SUPER/.git" -prune -o -path "$SUPER/Website/.git" -prune -o -print | sort)"
run "$SUPER" "https://github.com/acme/nothing/pull/1"
check_eq "no match: exit 1" "1" "$rc"
contains "no match: message" "review-pr: no local clone of acme/nothing here (looked in $SUPER and its submodules)" "$out"
check_eq "no match: nothing created" "$before" "$(find "$SUPER" -path "$SUPER/.git" -prune -o -path "$SUPER/Website/.git" -prune -o -print | sort)"
check_eq "no match: no branch" "" "$(git -C "$SUPER" branch --list pr-1)"
run "$ROOT" "https://github.com/acme/website/pull/7"
check_eq "url outside a repo: exit 1" "1" "$rc"

echo "bad arguments"
for a in "https://github.com/acme/website/issues/7" "https://example.com/a/b/pull/1" "https://github.com/acme/website/pull/x" "github.com/acme/website/pull/7" "7x"; do
  run "$SUPER" "$a"
  check_eq "bad argument '$a': exit 2" "2" "$rc"
done
run "$SUPER" 7 8
check_eq "two arguments: exit 2" "2" "$rc"

echo "done in the submodule layout"
echo edit >>"$SWT/pr.txt"
run "$SUPER" --done "https://github.com/acme/website/pull/7"
[[ $rc -ne 0 ]] && ok "done dirty (submodule layout): refuses" || bad "done dirty (submodule layout): refuses"
[[ -d "$SWT" ]] && ok "done dirty (submodule layout): worktree kept" || bad "done dirty (submodule layout): worktree kept"
git -C "$SWT" checkout -q pr.txt
run "$SUPER" --done "https://github.com/acme/website/pull/7"
check_eq "done (submodule layout): exit 0" "0" "$rc"
[[ ! -d "$SWT" ]] && ok "done (submodule layout): worktree removed" || bad "done (submodule layout): worktree removed"
[[ ! -d "$SUPER/worktrees/pr-website-7" ]] && ok "done (submodule layout): empty folder removed" || bad "done (submodule layout): empty folder removed"
check_eq "done (submodule layout): branch removed" "" "$(git -C "$SUPER/Website" branch --list pr-7)"

# ---- same-repo PRs: the worktree uses the PR's own branch ----
git clone -q "$ORIGIN" "$ROOT/seed2"
# pr_meta <n> <head branch> <cross-repo true|false> <base>: what the gh stub returns for PR <n>.
pr_meta() { printf '%s\n%s\n%s\n' "$2" "$3" "$4" >"$ROOT/pr-$1.meta"; }
# remote_commit <branch> <file> <text> [fresh]: pushes a commit to origin's <branch>; fresh rebuilds it from main (a force-push).
remote_commit() {
  local base="origin/$1"
  git -C "$ROOT/seed2" fetch -q origin
  { [[ "${4:-}" != fresh ]] && git -C "$ROOT/seed2" rev-parse -q --verify "$base" >/dev/null; } || base=origin/main
  git -C "$ROOT/seed2" checkout -q -B "$1" "$base"
  echo "$3" >"$ROOT/seed2/$2"
  git -C "$ROOT/seed2" add "$2"
  git -C "$ROOT/seed2" commit -q -m "$2"
  git -C "$ROOT/seed2" push -q -f origin "$1"
}
# local_commit <branch> <file>: commits on a local branch of the clone that is not checked out anywhere.
local_commit() {
  git -C "$CLONE" worktree add -q "$ROOT/tmpwt" "$1"
  echo local >"$ROOT/tmpwt/$2"
  git -C "$ROOT/tmpwt" add "$2"
  git -C "$ROOT/tmpwt" commit -q -m "$2"
  git -C "$CLONE" worktree remove "$ROOT/tmpwt"
}
cfg() { git -C "$CLONE" config --get "$1" || true; }

echo "fork PR keeps pr-<n> and has no upstream"
check_eq "fork: no upstream" "" "$(cfg branch.pr-123.remote)"
check_eq "fork: no marker" "" "$(cfg branch.pr-123.reviewPr)"

echo "same-repo PR, new branch"
pr_meta 201 BRAVO-1/feat false develop
remote_commit BRAVO-1/feat a.txt 1
AWT="$CLONE/worktrees/BRAVO-1-feat"
run "$CLONE" 201
check_eq "new branch: exit 0" "0" "$rc"
check_eq "new branch: local branch has the PR's name" "BRAVO-1/feat" "$(git -C "$AWT" branch --show-current)"
check_eq "new branch: at the remote tip" "$(git -C "$ROOT/seed2" rev-parse BRAVO-1/feat)" "$(git -C "$AWT" rev-parse HEAD)"
check_eq "new branch: tracks origin" "origin/BRAVO-1/feat" "$(git -C "$AWT" rev-parse --abbrev-ref '@{upstream}')"
check_eq "new branch: marked as created" "true" "$(cfg branch.BRAVO-1/feat.reviewPr)"
check_eq "new branch: no pr-201 folder" "no" "$([[ -d "$CLONE/worktrees/pr-201" ]] && echo yes || echo no)"
contains "new branch: window and path" "review --name BRAVO-1-feat develop $AWT" "$(cat "$ROOT/review.log")"
contains "new branch: one gh call with the three fields" "gh pr view 201 --json headRefName,isCrossRepository,baseRefName" "$(cat "$ROOT/gh.log")"
remote_commit BRAVO-1/feat b.txt 2
run "$CLONE" 201
check_eq "same-repo rerun: exit 0" "0" "$rc"
check_eq "same-repo rerun: fast-forwarded" "$(git -C "$ROOT/seed2" rev-parse BRAVO-1/feat)" "$(git -C "$AWT" rev-parse HEAD)"
echo edit >>"$AWT/a.txt"
run "$CLONE" 201
check_eq "same-repo dirty: exit 1" "1" "$rc"
contains "same-repo dirty: says what to do" "review-pr --done 201" "$out"
git -C "$AWT" checkout -q a.txt

echo "--done removes what the script made"
run "$CLONE" --done 201
check_eq "done marked: exit 0" "0" "$rc"
[[ ! -d "$AWT" ]] && ok "done marked: worktree removed" || bad "done marked: worktree removed"
check_eq "done marked: branch removed" "" "$(git -C "$CLONE" branch --list BRAVO-1/feat)"
run "$CLONE" 201

echo "same-repo force-push, then --done refuses the old commits"
remote_commit BRAVO-1/feat z.txt 9 fresh
before="$(git -C "$AWT" rev-parse HEAD)"
run "$CLONE" 201
check_eq "same-repo force-push: exit 1" "1" "$rc"
contains "same-repo force-push: hint is a reset" "git -C $AWT reset --hard origin/BRAVO-1/feat, then rerun review-pr 201" "$out"
check_eq "same-repo force-push: no --done hint" "0" "$(grep -c -e "--done" <<<"$out")"
check_eq "same-repo force-push: HEAD unchanged" "$before" "$(git -C "$AWT" rev-parse HEAD)"
run "$CLONE" --done 201
check_eq "done unpushed: exit 1" "1" "$rc"
contains "done unpushed: names the upstream" "not on origin/BRAVO-1/feat" "$out"
contains "done unpushed: says what to do" "git branch -D BRAVO-1/feat" "$out"
[[ -d "$AWT" ]] && ok "done unpushed: worktree kept" || bad "done unpushed: worktree kept"
check_eq "done unpushed: branch kept" "BRAVO-1/feat" "$(git -C "$CLONE" branch --list BRAVO-1/feat | tr -d ' *+')"
git -C "$AWT" reset -q --hard origin/BRAVO-1/feat
env -u TMUX tmux -S "$SOCK" -f /dev/null new-session -d -s v -n review:BRAVO-1-feat "sleep 300"
rc=0
out="$(cd "$CLONE" && TMUX="$SOCK,1,0" PATH="$STUBS:$PATH" bash "$SCRIPT" --done 201 2>&1)" || rc=$?
env -u TMUX tmux -S "$SOCK" kill-server >/dev/null 2>&1 || true
check_eq "done pushed: exit 0" "0" "$rc"
contains "done pushed: tmux window hint" "review:BRAVO-1-feat is still open" "$out"
check_eq "done pushed: branch removed" "" "$(git -C "$CLONE" branch --list BRAVO-1/feat)"

echo "branch already checked out in another worktree"
pr_meta 202 BRAVO-2/mine false develop
remote_commit BRAVO-2/mine m.txt 1
git -C "$CLONE" fetch -q origin
OWN="$ROOT/own/widgets"
git -C "$CLONE" worktree add -q -b BRAVO-2/mine "$OWN" origin/BRAVO-2/mine
echo mine >"$OWN/mine.txt"
git -C "$OWN" add mine.txt
git -C "$OWN" commit -q -m mine
echo wip >"$OWN/wip.txt"
before="$(git -C "$OWN" rev-parse HEAD)"
remote_commit BRAVO-2/mine m.txt 2
run "$CLONE" 202
check_eq "reuse: exit 0" "0" "$rc"
contains "reuse: says which worktree" "Reusing worktree $OWN" "$out"
check_eq "reuse: no second worktree" "no" "$([[ -d "$CLONE/worktrees/BRAVO-2-mine" ]] && echo yes || echo no)"
check_eq "reuse: HEAD not moved" "$before" "$(git -C "$OWN" rev-parse HEAD)"
check_eq "reuse: untracked file kept" "wip" "$(cat "$OWN/wip.txt")"
contains "reuse: review opens there" "review --name BRAVO-2-mine develop $OWN" "$(cat "$ROOT/review.log")"
check_eq "reuse: no marker" "" "$(cfg branch.BRAVO-2/mine.reviewPr)"
run "$CLONE" --done 202
check_eq "done reused: exit 0" "0" "$rc"
contains "done reused: removes nothing" "Nothing was removed" "$out"
[[ -d "$OWN" ]] && ok "done reused: worktree kept" || bad "done reused: worktree kept"
check_eq "done reused: branch kept" "BRAVO-2/mine" "$(git -C "$CLONE" branch --list BRAVO-2/mine | tr -d ' *+')"

echo "existing local branch, not checked out"
pr_meta 203 BRAVO-3/ahead false develop
remote_commit BRAVO-3/ahead c.txt 1
git -C "$CLONE" fetch -q origin
git -C "$CLONE" branch -q BRAVO-3/ahead origin/BRAVO-3/ahead
local_commit BRAVO-3/ahead l.txt
mine="$(git -C "$CLONE" rev-parse BRAVO-3/ahead)"
CWT="$CLONE/worktrees/BRAVO-3-ahead"
run "$CLONE" 203
check_eq "ahead: exit 0" "0" "$rc"
contains "ahead: says it is used as it is" "not on origin/BRAVO-3/ahead; using it as it is" "$out"
check_eq "ahead: branch not reset" "$mine" "$(git -C "$CWT" rev-parse HEAD)"
check_eq "ahead: marked worktree only" "worktree" "$(cfg branch.BRAVO-3/ahead.reviewPr)"
run "$CLONE" --done 203
check_eq "done ahead: exit 0" "0" "$rc"
[[ ! -d "$CWT" ]] && ok "done ahead: worktree removed" || bad "done ahead: worktree removed"
check_eq "done ahead: branch kept" "$mine" "$(git -C "$CLONE" rev-parse BRAVO-3/ahead)"
contains "done ahead: says the branch stays" "Keeping branch BRAVO-3/ahead" "$out"
pr_meta 204 BRAVO-4/behind false develop
remote_commit BRAVO-4/behind d.txt 1
git -C "$CLONE" fetch -q origin
git -C "$CLONE" branch -q BRAVO-4/behind origin/BRAVO-4/behind
remote_commit BRAVO-4/behind d.txt 2
run "$CLONE" 204
check_eq "behind: exit 0" "0" "$rc"
contains "behind: says it fast-forwarded" "fast-forwarded the existing branch BRAVO-4/behind" "$out"
check_eq "behind: at the remote tip" "$(git -C "$ROOT/seed2" rev-parse BRAVO-4/behind)" "$(git -C "$CLONE/worktrees/BRAVO-4-behind" rev-parse HEAD)"

echo "same-repo PR in a submodule"
pr_meta 209 BRAVO-9/sub false develop
git -C "$SUBO.seed" push -q origin HEAD:refs/heads/BRAVO-9/sub
SWT2="$SUPER/worktrees/BRAVO-9-sub/Website"
run "$SUPER" "https://github.com/acme/website/pull/209"
check_eq "submodule same-repo: exit 0" "0" "$rc"
check_eq "submodule same-repo: branch" "BRAVO-9/sub" "$(git -C "$SWT2" branch --show-current)"
contains "submodule same-repo: window and path" "review --name BRAVO-9-sub develop $SWT2" "$(cat "$ROOT/review.log")"
run "$SUPER" --done "https://github.com/acme/website/pull/209"
check_eq "submodule same-repo done: exit 0" "0" "$rc"
[[ ! -d "$SUPER/worktrees/BRAVO-9-sub" ]] && ok "submodule same-repo done: folder removed" || bad "submodule same-repo done: folder removed"
check_eq "submodule same-repo done: branch removed" "" "$(git -C "$SUPER/Website" branch --list BRAVO-9/sub)"

summary
