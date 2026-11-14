# Plain zsh, no framework, for a fast start. Machine settings: ~/.zshrc.local.

# --- Homebrew ---
for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  if [[ -x $brew_bin ]]; then
    eval "$($brew_bin shellenv)"
    break
  fi
done
unset brew_bin

# --- PATH ---
typeset -U path
path=("$HOME/.local/bin" $path)

# Sources the cached output of `<tool> <args>` (~30 ms saved per tool). The first
# line records the tool's resolved path, so a version change refreshes it.
_cache_init() {
  local rc=${ZDOTDIR:-$HOME}/.zshrc bin=${commands[$1]:A} first
  local f=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/$1${2:+.${(j:_:)${@[2,-1]//[^[:alnum:]]/_}}}.zsh
  [[ -r $f ]] && read -r first <$f
  if [[ ! -s $f || $first != "# bin=$bin" || $bin -nt $f || ${rc:A} -nt $f ]]; then
    mkdir -p ${f:h} && rm -f $f.<->(N) && { print -r "# bin=$bin"; "$@" } >$f.$$ 2>/dev/null && mv -f $f.$$ $f || rm -f $f.$$  # tmp + mv: never half-written
  fi
  [[ -s $f ]] && source $f
}

# Early, so mise's tools beat Homebrew's and the checks below find them.
# Not cached: its output holds a PATH snapshot that would go stale.
if (( $+commands[mise] )); then
  eval "$(mise activate zsh)"
fi

# --- Environment ---
if command -v nvim >/dev/null 2>&1; then
  export EDITOR=nvim
else
  export EDITOR=vim
fi
export VISUAL=$EDITOR
export PAGER=less
export LESS='-R -F -X'
command -v delta >/dev/null 2>&1 && export GH_PAGER="delta -s"

# --- Go ---
path+=("$HOME/go/bin")                    # after ~/.local/bin so those win

# --- OS-specific ---
case $OSTYPE in
  darwin*)
    alias o='open'                        # open files/URLs with the default app
    alias ls='ls -G'                      # list files in color (eza with icons if installed)
    for ghostty_dir in "$HOME/Applications/Ghostty.app/Contents/MacOS" /Applications/Ghostty.app/Contents/MacOS; do
      if [[ -x $ghostty_dir/ghostty ]]; then  # skip empty leftover app folders
        path+=("$ghostty_dir")
        break
      fi
    done
    unset ghostty_dir
    ;;
  linux*)
    alias o='xdg-open'                    # open files/URLs with the default app
    alias ls='ls --color=auto'            # list files in color (eza with icons if installed)
    ;;
esac

# --- History ---
HISTFILE=${HISTFILE:-$HOME/.zsh_history}
HISTSIZE=100000
SAVEHIST=100000
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt EXTENDED_HISTORY                   # timestamp on each entry
setopt HIST_FCNTL_LOCK                    # no waits on a stale .LOCK file

# --- Shell options ---
setopt AUTO_CD
setopt INTERACTIVE_COMMENTS
setopt NO_BEEP
bindkey -e
# Clears the screen and the scrollback
clear-screen-and-scrollback() {
  printf '\e[3J'
  zle clear-screen
}
zle -N clear-screen-and-scrollback
bindkey '^L' clear-screen-and-scrollback  # clear the screen and the scrollback

autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search    # earlier command that starts with the typed text
bindkey '^[OA' up-line-or-beginning-search    # application mode (tmux)
bindkey '^[[B' down-line-or-beginning-search  # later command that starts with the typed text
bindkey '^[OB' down-line-or-beginning-search  # application mode (tmux)
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line          # edit the command line in $VISUAL

# --- Completion ---
ZSH_PLUGIN_DIR=${XDG_DATA_HOME:-$HOME/.local/share}/zsh-plugins
if [[ -d $ZSH_PLUGIN_DIR/zsh-completions/src ]]; then
  fpath=("$ZSH_PLUGIN_DIR/zsh-completions/src" $fpath)
fi
autoload -Uz compinit
zcompdump=${ZDOTDIR:-$HOME}/.zcompdump
zcompfresh=( ${ZDOTDIR:-$HOME}/.zcompdump(N.mh-24) )  # dump under 24h old
if (( $#zcompfresh )); then
  compinit -C -d "$zcompdump"             # skip the security scan
else
  zmodload -F zsh/stat b:zstat
  autoload -Uz compaudit
  zcompbad=( ${(f)"$(compaudit 2>/dev/null)"} )
  zcompforeign=0                          # 1 when an insecure path belongs to someone else
  for zcompitem in $zcompbad; do
    zstat -A zcompowner -L +uid -- "$zcompitem" 2>/dev/null
    (( zcompowner == UID || zcompowner == 0 )) || zcompforeign=1
  done
  if (( $#zcompbad && ! zcompforeign )); then
    compinit -u -d "$zcompdump"           # insecure but owned by you or root: no prompt
  else
    compinit -d "$zcompdump"
  fi
  unset zcompbad zcompforeign zcompitem zcompowner
  touch "$zcompdump"                      # compinit may leave it untouched; renew its age
fi
unset zcompdump zcompfresh
zstyle ':completion:*' menu no            # fzf-tab needs the built-in menu off
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

if command -v eza >/dev/null 2>&1; then
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
fi

# --- Bell after long commands (tmux monitor-bell then flags the window) ---
zmodload zsh/datetime                     # $EPOCHSECONDS
autoload -Uz add-zsh-hook
LONG_CMD_BELL_IGNORE=${LONG_CMD_BELL_IGNORE:-"nvim vim vi less man lazygit lg lzd tmux ssh tssh claude top btop htop fzf"}
long_cmd_first_word() {                   # sets long_cmd_name to the program behind wrappers
  local -a words=(${(z)1})
  local w wrapped= skip=
  long_cmd_name=
  for w in $words; do
    if [[ -n $skip ]]; then skip=; continue; fi
    case $w in
      [A-Za-z_]*=*) ;;
      sudo|command|env|nocorrect|noglob|time|nohup) wrapped=1 ;;
      -u|-g) [[ -n $wrapped ]] && skip=1 || { long_cmd_name=$w; return; } ;;  # sudo -u USER
      -*) [[ -n $wrapped ]] || { long_cmd_name=$w; return; } ;;
      *) long_cmd_name=$w; return ;;
    esac
  done
}
long_cmd_start() {
  long_cmd_first_word "$1"
  long_cmd_t0=$EPOCHSECONDS
}
long_cmd_bell() {
  local t0=$long_cmd_t0 name=$long_cmd_name  # reset so an empty prompt never rings
  long_cmd_t0= long_cmd_name=
  [[ -n $t0 && -t 1 ]] || return
  (( EPOCHSECONDS - t0 >= ${LONG_CMD_BELL_SECONDS:-30} )) || return
  [[ " $LONG_CMD_BELL_IGNORE " == *" ${name:t} "* ]] && return
  printf '\a'
}
add-zsh-hook preexec long_cmd_start
add-zsh-hook precmd long_cmd_bell

# --- Remote tmux ---
# tssh <ssh args>: connect and attach to (or create) the remote tmux session "main".
# -lic so the remote .zshrc puts mise's tmux on PATH; single quotes so $SHELL is the server's.
tssh() { ssh -t "$@" 'exec $SHELL -lic "tmux new-session -A -s main"'; }
compdef tssh=ssh

# --- Aliases ---
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons --group-directories-first'   # list with icons
  alias ll='eza -l --icons --git --group-directories-first'  # long list with git status
  alias la='eza -la --icons --git --group-directories-first' # include hidden files
  alias lt='eza --tree --level=2 --icons'            # tree view, two levels
else
  alias ll='ls -lh'                       # long list, human sizes
  alias la='ls -lah'                      # include hidden files
fi
command -v bat >/dev/null 2>&1 && alias cat='bat --paging=never'  # highlighted cat
command -v lazygit >/dev/null 2>&1 && alias lg='lazygit'          # git UI
export LG_CONFIG_FILE="$HOME/.config/lazygit/config.yml"           # macOS reads ~/Library/Application Support otherwise
command -v lazydocker >/dev/null 2>&1 && alias lzd='lazydocker'    # docker UI
command -v docker >/dev/null 2>&1 && alias dcu='docker compose up'    # compose up
command -v docker >/dev/null 2>&1 && alias dcd='docker compose down'  # compose down
alias ..='cd ..'                          # go up one directory
alias gs='git status -sb'                 # short status
alias gd='git diff'                       # unstaged diff
alias gl='git log --oneline --graph -20'  # compact graph log
alias gp='git pull'                       # pull (rebase by default, see git config)
if command -v nvim >/dev/null 2>&1; then
  alias vim='nvim'                        # vim opens Neovim; `command vim` still runs the real Vim
  alias vi='nvim'                         # vi opens Neovim too
fi

# --- Tool integrations ---
if (( $+commands[fzf] )); then
  _cache_init fzf --zsh
fi
if (( $+commands[zoxide] )); then
  _cache_init zoxide init zsh
fi
if (( $+commands[starship] )); then
  _cache_init starship init zsh
fi
unfunction _cache_init

# --- Light/dark theme ---
alias tt='theme toggle'                   # flip between light and dark
export BAT_THEME=ansi                     # follows any terminal theme
# Re-apply a forced light/dark mode in local, non-tmux shells
if [[ -z ${SSH_CONNECTION:-}${SSH_TTY:-}${TMUX:-} && -t 1 ]] && command -v theme >/dev/null 2>&1; then
  theme_state=${XDG_STATE_HOME:-$HOME/.local/state}/theme  # read directly: no fork
  theme_mode=""
  [[ -r $theme_state ]] && read -r theme_mode <"$theme_state"
  case $theme_mode in
    dark|light)
      if [[ $OSTYPE == darwin* && ${TERM_PROGRAM:-} == ghostty ]]; then
        theme_sys=light                   # AppleInterfaceStyle exists only in dark mode
        [[ $(defaults read -g AppleInterfaceStyle 2>/dev/null) == Dark ]] && theme_sys=dark
        [[ $theme_sys == $theme_mode ]] || theme apply --no-download  # Ghostty already follows macOS
        unset theme_sys
      else
        theme apply --no-download         # never wait on curl at startup
      fi ;;
  esac
  unset theme_state theme_mode
fi

# --- Plugins: fzf-tab after compinit and fzf, before widget wrappers ---
[[ -f $ZSH_PLUGIN_DIR/fzf-tab/fzf-tab.plugin.zsh ]] &&
  source "$ZSH_PLUGIN_DIR/fzf-tab/fzf-tab.plugin.zsh"
[[ -f $ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh ]] &&
  source "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"

# --- Claude Code helpers ---
[[ -f $HOME/.config/claude-shared/claude.sh ]] && source "$HOME/.config/claude-shared/claude.sh"

# --- Local overrides: after the plugins, before syntax highlighting ---
if [[ -f $HOME/.zshrc.local ]]; then source "$HOME/.zshrc.local"; fi  # if, not [[ ]] &&: keeps $? 0
# Prompt host, over SSH only
if [[ -n ${SSH_CONNECTION:-} ]]; then export PROMPT_HOST=${HOST_LABEL:-${HOST%%.*}}; else unset PROMPT_HOST; fi

# --- Syntax highlighting: last, after every widget ---
if [[ -f $ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
