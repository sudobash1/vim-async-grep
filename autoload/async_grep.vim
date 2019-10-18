" Asynchronous grep plugin based on neovim's job control.
" Maintainer:	Stephen Robinson <sblazerobinson@gmail.com>
" License:	This file is placed in the public domain.

let s:job_id = 0

" Default to setqflist(), but may set to setloclist() based on
" g:async_grep_llist
let s:setqflist = function("setqflist")
let s:getqflist = function("getqflist")

" What the current query is
let s:query = ""

" Last partial result line seen
let s:result_line_buffer = ""

" Valid directions
let s:valid_dirs = [
      \ "vertical", "vert",
      \ "lefta", "leftabove", "abo", "aboveleft",
      \ "rightb", "rightbelow", "bel", "belowright",
      \ "to", "topleft",
      \ "bo", "botright"
      \ ]

" Handler to load the grep results into the list.
function! s:grep_job_handler(job_id, data, event)
  if a:job_id != s:job_id
    " Results coming in from previous search
    return
  endif

  if a:event == 'stdout'
    let l:lines = [s:result_line_buffer . a:data[0]]
    call extend(l:lines, a:data[1:-2])
    let s:result_line_buffer = a:data[-1]
    call s:setqflist([], 'a', {"efm": &grepformat, "lines": l:lines})
  elseif a:event == 'exit'
    call s:setqflist([], 'a', {"title": "Search results for " . s:query})
    let s:job_id = 0
  endif
endfunction

function! async_grep#grep(query, ...)
  call async_grep#internal_grep(-1, get(a:, 1, ""), a:query)
endfunction
function! async_grep#lgrep(query, ...)
  call async_grep#internal_grep(1, get(a:, 1, ""), a:query)
endfunction
function! async_grep#cgrep(query, ...)
  call async_grep#internal_grep(0, get(a:, 1, ""), a:query)
endfunction

function! async_grep#abort()
  if jobwait([s:job_id], 0)[0] == -1
    let l:old_job_id = s:job_id
    let s:job_id = 0
    call jobstop(l:old_job_id)
    call jobwait([l:old_job_id], 200)
    call s:setqflist([], 'a', {"title": "Searching canceled for " . s:query})
  else
    echoerr "No search to abort"
  endif
endfunction

function! async_grep#internal_grep(use_local, flags, ...)
  let s:query = join(a:000, ' ')

  if s:query ==# ""
    echoerr "Search string must not be empty"
    return
  endif

  if s:job_id != 0
    let l:old_job_id = s:job_id
    let s:job_id = 0
    call jobstop(l:old_job_id)
    call jobwait([l:old_job_id], 200)
  endif

  if a:use_local == 1 || a:use_local == -1 && g:async_grep_llist
    let s:setqflist = function("setloclist")
    let s:getqflist = function("getloclist")
  else
    let s:setqflist = function("setqflist")
    let s:getqflist = function("getqflist")
  endif

  call s:setqflist([], 'r')
  call s:setqflist([], 'r', { "title": "Searching for " . s:query . "..." })
  let s:result_line_buffer = ""

  let s:job_id = jobstart(
        \ &grepprg . ' ' . a:flags . ' ' . shellescape(s:query),
        \ {
        \   'on_stdout': function('s:grep_job_handler'),
        \   'on_stderr': function('s:grep_job_handler'),
        \   'on_exit': function('s:grep_job_handler')
        \ })

  if ! s:job_id
    call s:setqflist([], 'r', {"title": "Search failed"})
    throw "async_grep: Failed to start search with command: " . &grepprg
  endif
  echo "Searching for: " . s:query

  if g:async_grep_auto_open
    if g:async_grep_open_dir != ""
      " Check that g:async_grep_auto_open_dir is valid
      if index(s:valid_dirs, g:async_grep_open_dir) == -1
        throw "async_grep: Invalid direction " . g:async_grep_open_dir
      endif
    endif
    if g:async_grep_llist
      execute g:async_grep_open_dir . ' lopen'
    else
      execute g:async_grep_open_dir . ' copen'
    endif
  endif
endfunction
