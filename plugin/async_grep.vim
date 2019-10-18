" Asynchronous grep plugin based on neovim's job control.
" Maintainer:	Stephen Robinson <sblazerobinson@gmail.com>
" License:	This file is placed in the public domain.

if exists("g:loaded_async_grep")
  finish
endif
let g:loaded_async_grep = 1

if !has('nvim')
  echoerr "Requires NeoVim"
endif

let g:async_grep_llist = get(g:, "async_grep_llist", 0)
let g:async_grep_auto_open = get(g:, "async_grep_auto_open", 1)
let g:async_grep_open_dir = get(g:, "async_grep_open_dir", "")

command! -nargs=* -complete=dir Grep call async_grep#internal_grep(-1, "", <f-args>)
command! -nargs=* -complete=dir CGrep call async_grep#internal_grep(1, "", <f-args>)
command! -nargs=* -complete=dir LGrep call async_grep#internal_grep(0, "", <f-args>)
command! -nargs=0 GrepAbort call async_grep#abort()
