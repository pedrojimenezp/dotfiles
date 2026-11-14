" Plugin-free config for servers without Neovim.
syntax on
filetype plugin indent on
let mapleader = " "
set encoding=utf-8

set number
set relativenumber
set cursorline
set scrolloff=8
set signcolumn=yes
set showcmd
set wildmenu
set laststatus=2
if has('termguicolors')
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"  " TERM=tmux-256color does not announce true color
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  set termguicolors
endif

set ignorecase
set smartcase
set incsearch
set hlsearch
nnoremap <silent> <leader>h :nohlsearch<CR>

set splitbelow
set splitright

set expandtab
set tabstop=2
set shiftwidth=2
set smartindent
set hidden
set mouse=a
set backspace=indent,eol,start
set updatetime=300
set timeoutlen=500
set ttimeoutlen=10  " fast Esc
set undofile
set undodir=~/.vim/undo
set nobackup
set noswapfile
if !isdirectory(expand('~/.vim/undo')) | call mkdir(expand('~/.vim/undo'), 'p') | endif
" Over SSH, leave the clipboard alone
if $SSH_TTY != '' | set clipboard= | else | set clipboard=unnamed,unnamedplus | endif

" Comments go above mappings: a trailing " would be part of the mapping.
inoremap jk <Esc>

" Cmd+K sends NUL, which in insert mode would insert the last text.
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
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
