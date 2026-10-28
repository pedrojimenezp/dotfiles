# ~/.zshrc: interactive zsh config. Plain zsh, no framework, so startup stays fast.
# Secrets and machine-specific settings go in ~/.zshrc.local (sourced last, not tracked).

# --- Homebrew (macOS Apple Silicon/Intel, Linux) ---
# Find brew in the usual locations and export its PATH, MANPATH, etc.
for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
  if [[ -x $brew_bin ]]; then       # first brew that exists wins
    eval "$($brew_bin shellenv)"    # sets HOMEBREW_PREFIX and updates PATH
    break                           # stop searching
  fi
done
unset brew_bin                      # keep the shell namespace clean

# --- PATH ---
typeset -U path                     # keep PATH entries unique
path=("$HOME/.local/bin" $path)     # user scripts (tmux-sessionizer, mise)

# --- Environment ---
if command -v nvim >/dev/null 2>&1; then  # prefer Neovim when installed
  export EDITOR=nvim                      # editor for git commit, crontab, etc.
else
  export EDITOR=vim                       # fallback for servers
fi
export VISUAL=$EDITOR                     # same editor for programs that read VISUAL
export PAGER=less                         # default pager
export LESS='-R -F -X'                    # colors, quit if one screen, no screen clear

# --- Go ---
export GOPATH="$HOME/go"                  # Go workspace and `go install` target
path=("$GOPATH/bin" $path)                # make installed Go tools available

# --- OS-specific settings ---
case $OSTYPE in
  darwin*)
    alias o='open'                        # open files/URLs with the default app
    alias ls='ls -G'                      # colored ls (replaced by eza below if installed)
    for ghostty_dir in "$HOME/Applications/Ghostty.app/Contents/MacOS" /Applications/Ghostty.app/Contents/MacOS; do # new appdir first, then old
      if [[ -x $ghostty_dir/ghostty ]]; then  # skip empty leftover app folders
        path+=("$ghostty_dir")                # ghostty CLI lives inside the app bundle
        break                                 # use the first install found
      fi
    done
    unset ghostty_dir                         # keep the shell namespace clean
    ;;
  linux*)
    alias o='xdg-open'                    # open files/URLs with the default app
    alias ls='ls --color=auto'            # colored ls (replaced by eza below if installed)
    ;;
esac

# --- History ---
HISTFILE="$HOME/.zsh_history"             # history file location
HISTSIZE=100000                           # entries kept in memory
SAVEHIST=100000                           # entries saved to the file
setopt SHARE_HISTORY                      # share history between open shells (implies INC_APPEND)
setopt HIST_IGNORE_ALL_DUPS               # drop older duplicate commands
setopt HIST_IGNORE_SPACE                  # commands starting with a space are not saved
setopt HIST_REDUCE_BLANKS                 # trim extra whitespace
setopt EXTENDED_HISTORY                   # store timestamps

# --- Shell options ---
setopt AUTO_CD                            # typing a directory name cd's into it
setopt INTERACTIVE_COMMENTS               # allow # comments at the prompt
setopt NO_BEEP                            # no terminal bell
bindkey -e                                # emacs keymap (Ctrl-A, Ctrl-E, Ctrl-R, ...)

# --- Completion ---
# Extra completions from Homebrew must be on fpath before compinit.
if [[ -n ${HOMEBREW_PREFIX:-} && -d $HOMEBREW_PREFIX/share/zsh-completions ]]; then
  fpath=("$HOMEBREW_PREFIX/share/zsh-completions" $fpath)
fi
autoload -Uz compinit                     # load the completion system loader
compinit -C                               # init, skipping the security scan for speed
zstyle ':completion:*' menu select        # arrow-key menu for completions
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'  # case-insensitive matching
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}" # color completions like ls

# --- Aliases ---
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons --group-directories-first'   # eza instead of ls
  alias ll='eza -l --icons --git --group-directories-first'  # long list with git status
  alias la='eza -la --icons --git --group-directories-first' # include hidden files
  alias lt='eza --tree --level=2 --icons'            # tree view, two levels
else
  alias ll='ls -lh'                       # long list, human sizes
  alias la='ls -lah'                      # include hidden files
fi
command -v bat >/dev/null 2>&1 && alias cat='bat --paging=never'  # highlighted cat
command -v lazygit >/dev/null 2>&1 && alias lg='lazygit'          # git UI
command -v lazydocker >/dev/null 2>&1 && alias lzd='lazydocker'    # docker UI
alias ..='cd ..'                          # go up one directory
alias gs='git status -sb'                 # short status
alias gd='git diff'                       # unstaged diff
alias gl='git log --oneline --graph -20'  # compact graph log
alias gp='git pull'                       # pull (rebase by default, see git config)
if command -v nvim >/dev/null 2>&1; then  # only where Neovim exists; servers keep plain Vim and ~/.vimrc
  alias vim='nvim'                        # vim opens Neovim; `command vim` still runs the real Vim
  alias vi='nvim'                         # vi opens Neovim too
fi

# --- Tool integrations (each guarded: a missing tool never errors) ---
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)                     # Ctrl-R history, Ctrl-T files, Alt-C cd, ** completion
fi
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"               # adds `z` and `zi` jump commands
fi
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"             # per-project tool versions
elif [[ -x $HOME/.local/bin/mise ]]; then
  eval "$("$HOME/.local/bin/mise" activate zsh)"  # mise installed outside PATH
fi
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"             # prompt
fi

# --- Light/dark theme (bin/.local/bin/theme; state in ~/.local/state/theme) ---
alias tt='theme toggle'                   # flip between light and dark
export BAT_THEME=auto                     # bat picks dark or light from the terminal background
export BAT_THEME_DARK=OneHalfDark         # bat theme on a dark background
export BAT_THEME_LIGHT=GitHub             # bat theme on a light background
# Re-apply a saved dark/light choice in new local terminals. Skipped over SSH: the local
# terminal already has the colors, and a remote shell must not override them.
if [[ -z ${SSH_CONNECTION:-}${SSH_TTY:-} && -t 1 ]] && command -v theme >/dev/null 2>&1; then
  case $(theme status) in
    dark|light) theme apply ;;            # auto needs nothing: the terminal profile follows macOS
  esac
fi

# --- Plugins from Homebrew (syntax-highlighting must load last) ---
if [[ -n ${HOMEBREW_PREFIX:-} ]]; then
  [[ -f $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] &&
    source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"       # grey history suggestions
  [[ -f $HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] &&
    source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" # command coloring
fi

# --- Claude Code shared shell helpers ---
[[ -f $HOME/.config/claude-shared/zsh/claude.zsh ]] && source "$HOME/.config/claude-shared/zsh/claude.zsh"  # optional

# --- Local, untracked overrides (secrets, machine settings): keep last ---
[[ -f $HOME/.zshrc.local ]] && source "$HOME/.zshrc.local"
