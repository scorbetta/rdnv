"---- ENV-SPECIFIC CONFIGURATION {{{1

" Configure preview window
set splitbelow
set previewheight=15


"---- GLOBAL CONTEXT {{{1

" Set RTL database to the search path
let evars = environ()
let g:DAGOBAH_ROOT = evars['DAGOBAH_ROOT']
let g:RTL_SEARCH_PATH = evars['TATOOINE_ROOT'] . '/library'

" Global context for filtering
let g:FileList = []

" Out-of-reset initialization
if exists("g:TogglePreview_loaded")
    unlet g:TogglePreview_loaded
endif


"---- ADDONS/GetFilesList {{{1

" Get the list of files with a given basename, searching beneath the database search path and
" considering RTL files only
function! rtlvim#GetFilesList(search_path, basename, suffices)
    let file_list = []
    for suffix in a:suffices
        "@DEPRECATEDcall extend(file_list, findfile(a:basename . "." . suffix, a:search_path . "/**", -1))
        call extend(file_list, globpath(a:search_path . "/**", a:basename . "." . suffix, 0, 1))
    endfor

    return file_list
endfunction


"---- ADDONS/TogglePreview {{{1

" Open a preview of the selected file. The  file_index  comes from the popup menu, and it starts
" counting from 1, not 0!
function! rtlvim#OpenPreview(unused, file_index)
    if a:file_index != -1
        execute "pedit " . g:FileList[a:file_index - 1]
        let g:TogglePreview_loaded = 1
    endif
endfunction

" Toggle the preview window of the module whose basename is  basename  . The module is searched
" beneath the database. If multiple matches are found, then a popup menu is created for the user to
" choose
function! rtlvim#TogglePreviewTop(basename)
    if exists("g:TogglePreview_loaded")
        " A preview is already open, close it
        pclose
        unlet g:TogglePreview_loaded
    else
        # Search first
        let g:FileList = rtlvim#GetFilesList(g:RTL_SEARCH_PATH, a:basename, [ 'sv', 'svh', 'v', 'vh', 'vhd' ])

        # If no match is found, or if empty string is used, search for all modules
        if strlen(a:basename) == 0 || len(g:FileList) == 0
            let g:FileList = rtlvim#GetFilesList(g:RTL_SEARCH_PATH, 'rtl/**/*', [ 'sv', 'v', 'vhd' ])
        endif

        # Either open preview or open menu 
        if len(g:FileList) == 1
            call rtlvim#OpenPreview('', 1)
        else
            call popup_create(g:FileList, #{
                \ line: 'cursor+1',
                \ col: 'cursor',
                \ wrap: 'false',
                \ drag: 'false' ,
                \ filter: 'popup_filter_menu',
                \ callback: 'rtlvim#OpenPreview',
                \ cursorline: 1
            \ })
        endif
    endif
endfunction


"---- ADDON/Stamp {{{1

" Write out RTL instance
function! rtlvim#CreateInstance(unused, file_index)
    if a:file_index != -1
        execute ":r! " . g:DAGOBAH_ROOT . "/get_interface_from_json.py " . expand("%:e") . " " . expand(&shiftwidth) . " " . g:FileList[a:file_index - 1]
    endif
endfunction

" Copy RTL instance to clipboard
function! rtlvim#CopyInstanceToClipboard(unused, file_index)
    if a:file_index != -1
        echo g:FileList[a:file_index - 1]
        " Write output of command to register  z  
        let @z = system(g:DAGOBAH_ROOT . "/get_interface_from_json.py " . expand("%:e") . " " . expand(&shiftwidth) . " " . g:FileList[a:file_index - 1])
    endif
endfunction

" Create an instance of the selected module, by looking at the interface description returned by
" Modelsim (the XML must exist therefore)
function! rtlvim#StampTop(module_name, callback_function)
    " Get a list of files matching the required one
    let g:FileList = rtlvim#GetFilesList(g:RTL_SEARCH_PATH, a:module_name, [ 'json' ])
    if len(g:FileList) == 1
        execute "call " . a:callback_function . "('', 1)"
    elseif len(g:FileList) > 1
        " Let the user decide in case multiple files are found
        call popup_create(g:FileList, #{
            \ line: 'cursor+1',
            \ col: 'cursor',
            \ wrap: 'false',
            \ drag: 'false' ,
            \ filter: 'popup_filter_menu',
            \ callback: a:callback_function,
            \ cursorline: 1
        \ })
    endif
endfunction

function! rtlvim#Pluto()
    let cursor_pos = getcurpos()
    echo cursor_pos[1] . " " . cursor_pos[2]
endfunction
