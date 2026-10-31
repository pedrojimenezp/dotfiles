# ~/.zshrc: interactive zsh config. Plain zsh, no framework, so startup stays fast.
# Secrets and machine-specific settings go in ~/.zshrc.local (sourced just before syntax highlighting, not tracked).

# --- Homebrew (macOS; skipped where brew is absent) ---
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
path=("$HOME/.local/bin" $path)     # user scripts and the mise binary

# Sources the cached output of `<tool> <args>`; forking each tool on every start costs ~30 ms.
_cache_init() {
  local rc=${ZDOTDIR:-$HOME}/.zshrc bin=${commands[$1]:A}      # resolve symlinks so upgrades count
  local f=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/$1${2:+.${(j:_:)${@[2,-1]//[^[:alnum:]]/_}}}.zsh  # args are in the name
  if [[ ! -s $f || $bin -nt $f || ${rc:A} -nt $f ]]; then      # missing, tool upgraded or .zshrc edited
    mkdir -p ${f:h} && "$@" >$f.$$ 2>/dev/null && mv -f $f.$$ $f || rm -f $f.$$  # tmp + mv: never half-written
  fi
  [[ -s $f ]] && source $f
}

# mise puts its tools ahead of Homebrew's on PATH. Activate it here so the checks below find those tools.
if (( $+commands[mise] )); then
  _cache_init mise activate zsh           # tool versions per project, global defaults from ~/.config/mise/config.toml
fi

# --- Environment ---
if command -v nvim >/dev/null 2>&1; then  # prefer Neovim when installed
  export EDITOR=nvim                      # editor for git commit, crontab, etc.
else
  export EDITOR=vim                       # fallback for servers
fi
export VISUAL=$EDITOR                     # same editor for programs that read VISUAL
export PAGER=less                         # default pager
export LESS='-R -F -X'                    # colors, quit if one screen, no screen clear
command -v delta >/dev/null 2>&1 && export GH_PAGER="delta -s"  # gh diffs side by side with delta

# --- Go ---
export GOPATH="$HOME/go"                  # Go workspace and `go install` target
path+=("$GOPATH/bin")                    # Go tools, after ~/.local/bin so those win

# --- OS-specific settings ---
case $OSTYPE in
  darwin*)
    alias o='open'                        # open files/URLs with the default app
    alias ls='ls -G'                      # list files in color (eza with icons if installed)
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
    alias ls='ls --color=auto'            # list files in color (eza with icons if installed)
    ;;
esac

# --- History ---
HISTFILE="$HOME/.zsh_history"             # history file location
HISTSIZE=100000                           # entries kept in memory
SAVEHIST=100000                           # entries saved to the file
setopt SHARE_HISTORY                      # share history between open shells (implies INC_APPEND)
setopt HIST_IGNORE_ALL_DUPS               # drop older duplicate commands
setopt HIST_FIND_NO_DUPS                  # skip duplicate entries while searching history
setopt HIST_IGNORE_SPACE                  # commands starting with a space are not saved
setopt HIST_REDUCE_BLANKS                 # trim extra whitespace
setopt EXTENDED_HISTORY                   # store timestamps

# --- Shell options ---
setopt AUTO_CD                            # typing a directory name cd's into it
setopt INTERACTIVE_COMMENTS               # allow # comments at the prompt
setopt NO_BEEP                            # no terminal bell
bindkey -e                                # emacs keymap (Ctrl-A, Ctrl-E, Ctrl-R, ...)
# Ctrl-L also wipes the scrollback (CSI 3 J), like a full clear; Cmd-K relies on this outside tmux
clear-screen-and-scrollback() {
  printf '\e[3J'                           # ask the terminal to erase its scrollback
  zle clear-screen                          # then the normal clear + prompt redraw
}
zle -N clear-screen-and-scrollback        # register the function as a widget
bindkey '^L' clear-screen-and-scrollback  # clear the screen and the scrollback

autoload -Uz up-line-or-beginning-search down-line-or-beginning-search  # built-in widgets: match history by typed prefix
zle -N up-line-or-beginning-search        # register the widget
zle -N down-line-or-beginning-search      # register the widget
bindkey '^[[A' up-line-or-beginning-search    # without atuin: earlier command that starts with the typed text (normal cursor mode)
bindkey '^[OA' up-line-or-beginning-search    # Up, application mode (tmux, after smkx)
bindkey '^[[B' down-line-or-beginning-search  # later command that starts with the typed text (normal cursor mode)
bindkey '^[OB' down-line-or-beginning-search  # Down, application mode (tmux, after smkx)
autoload -Uz edit-command-line            # built-in widget: edit the current line in $VISUAL
zle -N edit-command-line                  # register the widget
bindkey '^X^E' edit-command-line          # edit the command line in $VISUAL

# --- Completion ---
ZSH_PLUGIN_DIR=${XDG_DATA_HOME:-$HOME/.local/share}/zsh-plugins  # git clones made by install.sh
# Extra completions (cloned by install.sh) must be on fpath before compinit.
if [[ -d $ZSH_PLUGIN_DIR/zsh-completions/src ]]; then
  fpath=("$ZSH_PLUGIN_DIR/zsh-completions/src" $fpath)
fi
autoload -Uz compinit                     # load the completion system loader
zcompdump=${ZDOTDIR:-$HOME}/.zcompdump   # where compinit keeps its cache
zcompfresh=( ${ZDOTDIR:-$HOME}/.zcompdump(N.mh-24) )  # matches only if the dump exists and is under 24h old
if (( $#zcompfresh )); then
  compinit -C -d "$zcompdump"             # reuse it, skipping the security scan for speed
else
  zmodload -F zsh/stat b:zstat            # owner lookup without forking
  autoload -Uz compaudit                  # lists the dirs and files compinit considers insecure
  zcompbad=( ${(f)"$(compaudit 2>/dev/null)"} )  # empty when everything is secure
  zcompforeign=0                          # 1 when an insecure path belongs to someone else
  for zcompitem in $zcompbad; do
    zstat -A zcompowner -L +uid -- "$zcompitem" 2>/dev/null
    (( zcompowner == UID || zcompowner == 0 )) || zcompforeign=1
  done
  if (( $#zcompbad && ! zcompforeign )); then
    compinit -u -d "$zcompdump"           # insecure but owned by you or root: use without the prompt
  else
    compinit -d "$zcompdump"              # missing or stale: full scan, prompts about foreign-owned dirs
  fi
  unset zcompbad zcompforeign zcompitem zcompowner
  touch "$zcompdump"                      # compinit leaves the dump untouched when nothing changed, so renew its age here
fi
unset zcompdump zcompfresh
zstyle ':completion:*' menu no            # fzf-tab needs the built-in menu off
zstyle ':completion:*:descriptions' format '[%d]'  # group headers, shown by fzf-tab
zstyle ':fzf-tab:*' switch-group ',' '.'  # move between groups with , and .
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'  # case-insensitive matching
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}" # color completions like ls

if command -v eza >/dev/null 2>&1; then
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'  # list the folder while choosing
fi

# --- Bell after long commands (tmux monitor-bell then flags the window) ---
zmodload zsh/datetime                     # provides $EPOCHSECONDS
autoload -Uz add-zsh-hook                 # safe way to add preexec/precmd hooks
LONG_CMD_BELL_IGNORE=${LONG_CMD_BELL_IGNORE:-"nvim vim vi less man lazygit lg lzd tmux ssh tssh claude top btop htop fzf"}  # long by nature; override in ~/.zshrc.local
long_cmd_first_word() {                   # sets long_cmd_name to the real program of a command line (no fork)
  local -a words=(${(z)1})                # split like the shell would (one word stays an array)
  local w wrapped= skip=
  long_cmd_name=
  for w in $words; do
    if [[ -n $skip ]]; then skip=; continue; fi  # value of -u/-g
    case $w in
      [A-Za-z_]*=*) ;;                    # assignments hide the program
      sudo|command|env|nocorrect|noglob|time|nohup) wrapped=1 ;;  # wrappers hide the program
      -u|-g) [[ -n $wrapped ]] && skip=1 || { long_cmd_name=$w; return; } ;;  # sudo -u USER: skip the value too
      -*) [[ -n $wrapped ]] || { long_cmd_name=$w; return; } ;;   # wrapper options (-E, -i)
      *) long_cmd_name=$w; return ;;
    esac
  done
}
long_cmd_start() {
  long_cmd_first_word "$1"                # program name, matched against the ignore list later
  long_cmd_t0=$EPOCHSECONDS               # start time in seconds
}
long_cmd_bell() {
  local t0=$long_cmd_t0 name=$long_cmd_name  # copy, then reset so an empty prompt never rings
  long_cmd_t0= long_cmd_name=             # forget this command
  [[ -n $t0 && -t 1 ]] || return          # nothing ran, or output is not a terminal
  (( EPOCHSECONDS - t0 >= ${LONG_CMD_BELL_SECONDS:-30} )) || return  # too quick to bother
  [[ " $LONG_CMD_BELL_IGNORE " == *" ${name:t} "* ]] && return       # skip full-screen programs
  printf '\a'                             # ring the terminal bell
}
add-zsh-hook preexec long_cmd_start       # runs just before each command
add-zsh-hook precmd long_cmd_bell         # runs just before each prompt

# --- Remote tmux ---
# tssh <ssh args>: connect and attach to (or create) the remote tmux session "main".
# -t forces a tty for tmux; the remote shell is interactive login (-lic) so .zshrc puts mise's tmux on PATH.
# The single-quoted command is expanded by the remote shell, so $SHELL is the server's.
tssh() { ssh -t "$@" 'exec $SHELL -lic "tmux new-session -A -s main"'; }
compdef tssh=ssh                          # complete hosts and options like ssh

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
export LG_CONFIG_FILE="$HOME/.config/lazygit/config.yml"           # macOS would read ~/Library/Application Support/lazygit
command -v lazydocker >/dev/null 2>&1 && alias lzd='lazydocker'    # docker UI
command -v docker >/dev/null 2>&1 && alias dcu='docker compose up'    # compose up
command -v docker >/dev/null 2>&1 && alias dcd='docker compose down'  # compose down
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
# mise is activated earlier (PATH section); _cache_init is defined there too.
if (( $+commands[fzf] )); then
  _cache_init fzf --zsh                   # Ctrl-R history, Ctrl-T files, Alt-C cd, ** completion
fi
# atuin comes after fzf (so its Ctrl-R wins) and after our Up/Down bindkeys (so its Up wins).
# Down stays ours (atuin does not bind it). Without atuin, the prefix search above remains.
if (( $+commands[atuin] )); then
  # ATUIN_NO_UP=1 (set in ~/.zshenv, which loads before this file) keeps Up on prefix search
  _cache_init atuin init zsh ${ATUIN_NO_UP:+--disable-up-arrow}  # history search on Ctrl-R and Up
fi
if (( $+commands[zoxide] )); then
  _cache_init zoxide init zsh             # adds `z` and `zi` jump commands
fi
if (( $+commands[starship] )); then
  _cache_init starship init zsh           # prompt
fi
unfunction _cache_init                    # keep the shell namespace clean

# --- Light/dark theme (bin/.local/bin/theme; pair in ~/.config/theme/config, mode in ~/.local/state/theme) ---
alias tt='theme toggle'                   # flip between light and dark
export BAT_THEME=ansi                     # bat uses the terminal's 16 colors, so it follows any theme
# Re-apply a saved dark/light choice in new local terminals. Skipped over SSH (the local terminal
# already has the colors, a remote shell must not override them) and inside tmux (the outer
# terminal was colored by the shell that started tmux, so every pane would repeat the work).
# Also skipped in Ghostty on macOS when the saved mode equals the macOS appearance: Ghostty already
# shows that theme by itself (`theme = light:X,dark:Y`), so only a forced opposite mode needs it.
# Other terminals (iTerm) and Linux always apply.
if [[ -z ${SSH_CONNECTION:-}${SSH_TTY:-}${TMUX:-} && -t 1 ]] && command -v theme >/dev/null 2>&1; then
  theme_state=${XDG_STATE_HOME:-$HOME/.local/state}/theme  # same file as bin/.local/bin/theme; no process spawned
  theme_mode=""                           # stays empty (auto) when the file is missing
  [[ -r $theme_state ]] && read -r theme_mode <"$theme_state"  # first line only
  case $theme_mode in
    dark|light)
      if [[ $OSTYPE == darwin* && ${TERM_PROGRAM:-} == ghostty ]]; then
        theme_sys=light                   # AppleInterfaceStyle exists only in dark mode
        [[ $(defaults read -g AppleInterfaceStyle 2>/dev/null) == Dark ]] && theme_sys=dark
        [[ $theme_sys == $theme_mode ]] || theme apply --no-download  # forced opposite of macOS
        unset theme_sys
      else
        theme apply --no-download         # never wait on curl at startup
      fi ;;                               # auto needs nothing (the profile follows macOS)
  esac
  unset theme_state theme_mode
fi

# --- Plugins (fzf-tab after compinit and fzf, before the widget wrappers; syntax-highlighting is at the end of the file) ---
[[ -f $ZSH_PLUGIN_DIR/fzf-tab/fzf-tab.plugin.zsh ]] &&
  source "$ZSH_PLUGIN_DIR/fzf-tab/fzf-tab.plugin.zsh"                                # Tab completion through fzf
[[ -f $ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh ]] &&
  source "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"               # grey history suggestions

# --- Claude Code shared shell helpers ---
[[ -f $HOME/.config/claude-shared/zsh/claude.zsh ]] && source "$HOME/.config/claude-shared/zsh/claude.zsh"  # optional

# --- Local, untracked overrides (secrets, machine settings): keep it after the plugins, before syntax highlighting ---
if [[ -f $HOME/.zshrc.local ]]; then source "$HOME/.zshrc.local"; fi  # an if keeps $? at 0 when the file is missing (a failed [[ ]] would turn the prompt red)
# Host shown in the prompt over SSH only: HOST_LABEL (set in .zshrc.local), else the short hostname
if [[ -n ${SSH_CONNECTION:-} ]]; then export PROMPT_HOST=${HOST_LABEL:-${HOST%%.*}}; else unset PROMPT_HOST; fi

# --- Syntax highlighting: must load after everything that defines widgets, so keep it last ---
if [[ -f $ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"  # command coloring
fi
