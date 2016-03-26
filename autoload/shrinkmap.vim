let s:save_cpo = &cpo
set cpo&vim


let s:buf_name         = '[shrinkmap]'
let s:buf_name_pattern = '\[shrinkmap\]'


function! shrinkmap#buf_name() "{{{
  return s:buf_name
endfunction "}}}


function! shrinkmap#buf() "{{{
  return bufnr(s:buf_name_pattern)
endfunction "}}}


function! shrinkmap#win() "{{{
  return bufwinnr(s:buf_name_pattern)
endfunction "}}}


function! shrinkmap#debug(level, msg) "{{{
  if g:shrinkmap_debug >= a:level
    echomsg a:msg
  endif
endfunction "}}}


function! shrinkmap#is_current_buffer_target() "{{{
  let buf_name = bufname('%')
  return shrinkmap#is_buffer_target(buf_name)
endfunction "}}}


function! shrinkmap#is_buffer_target(buf_name) "{{{
  if a:buf_name ==# s:buf_name       ||
    \a:buf_name ==# '[Command Line]' ||
    \a:buf_name =~ '^vimfiler:'      ||
    \a:buf_name =~ '^\[unite\]'      ||
    \a:buf_name =~ '^NERD_tree'
    return 0
  else
    return 1
  endif
endfunction "}}}


let &cpo = s:save_cpo
unlet s:save_cpo

