vim9script noclear

" Vim plugin for RTL development
" Author: Simone Corbetta <simone.corbetta@gmail.com>
" License: This file is placed in the public domain

" With the following user can actively disable loading the plugin, and it
" manages properly loading the script twice
if exists("b:rtl_ftplugin")
    finish
endif
b:rtl_ftplugin = 1

" Load global configuration
for i in range(1, 4)
    echo $"count is {i}"
endfor

" Typing  Stamp <module_name> [ <instance_name> ]  an instance of  <module_name>  is created in the
" current buffer. The extension of the current file determines the instance syntax (i.e., either
" SystemVerilog/Verilog or VHDL
if !exists(":Stamp")
    command -buffer -nargs=+ Stamp execute ":r! " . "./get_interface_from_xml.py " .  expand("%:e") . " " . expand(&shiftwidth) . " <args>"
endif


