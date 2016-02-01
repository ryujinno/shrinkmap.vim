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
    echom a:msg
  endif
endfunction "}}}

