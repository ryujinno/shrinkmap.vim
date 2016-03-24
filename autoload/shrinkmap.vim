let s:save_cpo = &cpo
set cpo&vim


let s:buf_name         = '[shrinkmap]'
let s:buf_name_pattern = '\[shrinkmap\]'


function! shrinkmap#buf_name() "{{{
  return s:buf_name
endfunction "}}}


function! shrinkmap#buf_name_pattern() "{{{
  return s:buf_name_pattern
endfunction "}}}


function! shrinkmap#debug(level, msg) "{{{
  if g:shrinkmap_debug >= a:level
    echomsg a:msg
  endif
endfunction "}}}


function! shrinkmap#current_buffer_is_target() "{{{
  let buf_name = bufname('%')
  if buf_name ==# shrinkmap#buf_name() ||
    \buf_name ==# '[Command Line]'     ||
    \buf_name =~ '^vimfiler:'          ||
    \buf_name =~ '^\[unite\]'          ||
    \buf_name =~ '^NERD_tree'
    return 0
  else
    return 1
  endif
endfunction "}}}


let &cpo = s:save_cpo
unlet s:save_cpo

