# Shared by install.sh, uninstall.sh and tests/. Source it with $REPO set to the repo root.
# It sits at the repo root, outside every stow package, so stow never links it.

# Prints every stow package: each top-level folder except docs, tests, work notes, worktrees and hidden ones.
packages_all() {
  local d name
  for d in "$REPO"/*/; do
    name="$(basename "$d")"
    case "$name" in docs | tests | work | worktrees) continue ;; esac
    echo "$name"
  done
}

# Prints the packages that apply on this machine: iterm and skhd on macOS only, ghostty when Ghostty is installed.
packages_here() {
  local pkg app has_ghostty=0
  # GHOSTTY_APPS (space-separated app paths) overrides the default locations; Brewfile appdir first.
  for app in ${GHOSTTY_APPS:-"$HOME/Applications/Ghostty.app" /Applications/Ghostty.app}; do
    [[ -d $app ]] && has_ghostty=1
  done
  command -v ghostty >/dev/null 2>&1 && has_ghostty=1 # Linux package on PATH
  while IFS= read -r pkg; do
    case "$pkg" in
      iterm | skhd) [[ "$OSTYPE" == darwin* ]] || continue ;;
      ghostty) [[ $has_ghostty -eq 1 ]] || continue ;;
    esac
    echo "$pkg"
  done < <(packages_all)
}
