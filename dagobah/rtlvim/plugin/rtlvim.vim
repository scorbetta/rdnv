" Title:        RTL design w/ VIM
" Description:  A plugin to provide utilities to RTL designers
" Maintainer:   Simone Corbetta <https://github.com/scorbetta>

" Prevents the plugin from being loaded multiple times
if exists("g:loaded_rtl_vim")
    finish
endif
let g:loaded_rtl_vim = 1

" Typing  Stamp <module_name>  creates an instance of  <module_name>  below the cursor of the
" current buffer. The extension of the current file determines the instance syntax (i.e., either
" SystemVerilog/Verilog or VHDL
command -nargs=1 Stamp call rtlvim#StampTop(expand("<args>"), 'rtlvim#CreateInstance')

" By pressing <F2> preview of the module whose basename is under the cursor is toggled
map <F2> :call rtlvim#TogglePreviewTop(expand('<cword>'))<CR>

" By pressing <F3> an instance of the module under the cursor is generated and copied in register  z  
map <F3> :call rtlvim#StampTop(expand("<cword>"), 'rtlvim#CopyInstanceToClipboard')<CR>

" By pressing <F4> the contents of register  z  are streamed under the cursor
map <F4> :execute "put z"<CR>

map <F8> :call rtlvim#Pluto()<CR>
