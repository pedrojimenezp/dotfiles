" ~/.vimrc: small, plugin-free config for servers (Neovim uses nvim/ instead).

set nocompatible              " use Vim features, not strict vi behavior
syntax on                     " enable syntax highlighting
filetype plugin indent on     " per-filetype plugins and indentation
let mapleader = " "           " Space is the leader key
set encoding=utf-8            " use UTF-8 internally

set number                    " show line numbers
set relativenumber            " relative numbers: easy `5j` / `3k` jumps
set cursorline                " highlight the current line
set scrolloff=8               " keep 8 lines visible above/below the cursor
set signcolumn=yes            " always show the sign column (no text jumping)
set showcmd                   " show partial commands while typing
set wildmenu                  " menu for command-line completion
set laststatus=2              " always show the status line
if has('termguicolors')
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"  " true-color escapes: TERM=tmux-256color does not announce them
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  set termguicolors                       " true color when supported
endif

set ignorecase                " case-insensitive search...
set smartcase                 " ...unless the pattern has capitals
set incsearch                 " show matches while typing
set hlsearch                  " highlight all matches
" <leader>h clears search highlight
nnoremap <silent> <leader>h :nohlsearch<CR>

set splitbelow                " :split opens below
set splitright                " :vsplit opens to the right

set expandtab                 " Tab inserts spaces
set tabstop=2                 " a tab displays as 2 columns
set shiftwidth=2              " indent by 2 columns
set smartindent               " auto-indent new lines
set hidden                    " allow switching buffers with unsaved changes
set mouse=a                   " mouse support
set backspace=indent,eol,start " make Backspace work as expected
set updatetime=300            " faster swap/CursorHold events
set timeoutlen=500            " time to wait for a mapped key sequence
set ttimeoutlen=10            " fast Esc in terminals
set undofile                  " keep undo history across sessions
set undodir=~/.vim/undo       " where undo files live
set nobackup                  " no backup files
set noswapfile                " no swap files
if !isdirectory(expand('~/.vim/undo')) | call mkdir(expand('~/.vim/undo'), 'p') | endif
                              " create the undo directory if missing
if $SSH_TTY != '' | set clipboard= | else | set clipboard=unnamed | endif
                              " system clipboard locally; leave alone over SSH

" Mappings: comments go on the line above because a trailing " would be part of the mapping.
" jk leaves insert mode
inoremap jk <Esc>

" NUL (Ctrl-Space) in insert mode inserts the last text by default. Terminal Cmd+K sends it, so ignore it.
inoremap <C-@> <Nop>
" Ctrl-h/j/k/l move between splits; at the edge, hand off to the tmux pane there
function! s:Nav(dir) abort
  let l:win = winnr()
  execute 'wincmd ' . a:dir
  " window unchanged = no split that way; tmux uses -L/-D/-U/-R
  if winnr() == l:win && $TMUX != ''
    silent call system('tmux select-pane -' . tr(a:dir, 'hjkl', 'LDUR'))
  endif
endfunction
nnoremap <silent> <C-h> :call <SID>Nav('h')<CR>
nnoremap <silent> <C-j> :call <SID>Nav('j')<CR>
nnoremap <silent> <C-k> :call <SID>Nav('k')<CR>
nnoremap <silent> <C-l> :call <SID>Nav('l')<CR>
" <leader>w saves, <leader>q quits
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
