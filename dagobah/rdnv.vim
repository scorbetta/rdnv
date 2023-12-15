"---- GENERAL CONFIGURATION -----------------------------------------------------------------------

" Disable compatibility with vi which can cause unexpected issues
set nocompatible
" Enable type file detection. Vim will be able to try to detect the type of file in use
filetype on
" Enable plugins and load plugin for the detected file type
filetype plugin on
" Load an indent file for the detected file type
filetype indent on
" Turn syntax highlighting on
syntax on
" Add numbers to each line on the left-hand side
set number
"" Highlight cursor line underneath the cursor horizontally
"set cursorline
"" Highlight cursor line underneath the cursor vertically
"set cursorcolumn
" Set shift width to 4 spaces
set shiftwidth=4
" Set tab width to 4 columns
set tabstop=4
" Use space characters instead of tabs
set expandtab
" Do not save backup files
set nobackup
" Do not let cursor scroll below or above N number of lines when scrolling
set scrolloff=10
" Do not wrap lines. Allow long lines to extend as far as the line goes
set nowrap
" While searching though a file incrementally highlight matching characters as you type
set incsearch
" Ignore capital letters during search
set ignorecase
" Override the ignorecase option if searching for capital letters
set smartcase
" Show partial command you type in the last line of the screen
set showcmd
" Show the mode you are on the last line
set showmode
" Show matching words during a search
set showmatch
" Use highlighting when doing a search
set hlsearch
" Wide screens is the default by now
set textwidth=100


"---- STATUS BAR ----------------------------------------------------------------------------------

" Status bar is taken from  https://gist.github.com/meskarune  
" status bar colors
au InsertEnter * hi statusline guifg=black guibg=#d7afff ctermfg=black ctermbg=magenta
au InsertLeave * hi statusline guifg=black guibg=#8fbfdc ctermfg=black ctermbg=cyan
hi statusline guifg=black guibg=#8fbfdc ctermfg=black ctermbg=cyan

" Status line
" default: set statusline=%f\ %h%w%m%r\ %=%(%l,%c%V\ %=\ %P%)

" Status Line Custom
let g:currentmode={
    \ 'n'  : 'Normal',
    \ 'no' : 'Normal·Operator Pending',
    \ 'v'  : 'Visual',
    \ 'V'  : 'V·Line',
    \ '^V' : 'V·Block',
    \ 's'  : 'Select',
    \ 'S'  : 'S·Line',
    \ '^S' : 'S·Block',
    \ 'i'  : 'Insert',
    \ 'R'  : 'Replace',
    \ 'Rv' : 'V·Replace',
    \ 'c'  : 'Command',
    \ 'cv' : 'Vim Ex',
    \ 'ce' : 'Ex',
    \ 'r'  : 'Prompt',
    \ 'rm' : 'More',
    \ 'r?' : 'Confirm',
    \ '!'  : 'Shell',
    \ 't'  : 'Terminal'
    \}

set laststatus=2
set noshowmode
set statusline=
set statusline+=%0*\ %n\                                 " Buffer number
set statusline+=%1*\ %<%F%m%r%h%w\                       " File path, modified, readonly, helpfile, preview
set statusline+=%3*│                                     " Separator
set statusline+=%2*\ %Y\                                 " FileType
set statusline+=%3*│                                     " Separator
set statusline+=%2*\ %{''.(&fenc!=''?&fenc:&enc).''}     " Encoding
set statusline+=\ (%{&ff})                               " FileFormat (dos/unix..)
set statusline+=%=                                       " Right Side
set statusline+=%2*\ col:\ %02v\                         " Colomn number
set statusline+=%3*│                                     " Separator
set statusline+=%1*\ ln:\ %02l/%L\ (%3p%%)\              " Line number / total lines, percentage of document
set statusline+=%0*\ %{toupper(g:currentmode[mode()])}\  " The current mode

hi User1 ctermfg=007 ctermbg=239 guibg=#4e4e4e guifg=#adadad
hi User2 ctermfg=007 ctermbg=236 guibg=#303030 guifg=#adadad
hi User3 ctermfg=236 ctermbg=236 guibg=#303030 guifg=#303030
hi User4 ctermfg=239 ctermbg=239 guibg=#4e4e4e guifg=#4e4e4e


"---- PLUGINS -------------------------------------------------------------------------------------

" PLUGINS {{{
" Installed plugins will be added between the #begin/#end plugin pair below
call plug#begin('~/.vim/plugged')
Plug '~/work/rdnv/dagobah/rtlvim'
call plug#end()
" }}}
