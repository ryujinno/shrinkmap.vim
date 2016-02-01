let s:buf_name         = '[shrinkmap]'
let s:buf_name_pattern = '\[shrinkmap\]'
let s:sidebar_align    = g:shrinkmap_sidebar_align

function! shrinkmap#buf_name() "{{{
  return s:buf_name
endfunction "}}}


function! shrinkmap#buf_name_pattern() "{{{
  return s:buf_name_pattern
endfunction "}}}


function! shrinkmap#toggle() "{{{
  if bufwinnr(s:buf_name_pattern) < 0
    call shrinkmap#open()
  else
    call shrinkmap#close()
  endif
endfunction "}}}


function! shrinkmap#open() "{{{
  " Check shrinkmap window
  if bufwinnr(s:buf_name_pattern) > 0
    return
  endif

  " Get current window
  let l:cur_win = winnr()

  " Keep sidebar align
  let s:sidebar_align = g:shrinkmap_sidebar_align
  if s:sidebar_align ==# 'right'
    let l:align  = 'botright'
    let l:adjust = 0
  elseif s:sidebar_align ==# 'left'
    let l:align  = 'topleft'
    let l:adjust = 1
  else
    shrinkmap#debug(0, 'g:shrinkmap_sidebar_align is invalid: ' . g:shrinkmap_sidebar_align)
    return
  endif

  " Open window
  execute l:align g:shrinkmap_sidebar_width 'vnew' s:buf_name

  " Adjust window number
  let l:cur_win += l:adjust

  " Resize already open window
  execute 'vertical resize' g:shrinkmap_sidebar_width

  call s:set_buffer()
  call shrinkmap#handler#reset(1)

  " Resume window
  execute l:cur_win 'wincmd w'

  " Update shrinkmap
  call shrinkmap#viewport#update()
endfunction "}}}


function! s:set_buffer() "{{{
  " Temporary buffer
  setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted

  " Simple viewport
  setlocal nonumber norelativenumber nolist nowrap

  " Read only
  setlocal nomodifiable

  " Window
  setlocal winfixwidth
endfunction "}}}


function! shrinkmap#close() "{{{
  " Check shrinkmap window
  let l:sm_win = bufwinnr(s:buf_name_pattern)
  if l:sm_win < 0
    return
  endif

  " Get current and shrinkmap window
  let l:cur_win = winnr()

  " Move to shrinkmap window
  execute l:sm_win 'wincmd w'

  " Get adjustment of window number
  if s:sidebar_align ==# 'right'
    let l:adjust = 0
  elseif s:sidebar_align ==# 'left'
    let l:adjust = -1
  else
    shrinkmap#debug(0, 'Internal error: Unknown sidebar align: ' . s:sidebar_align)
    return
  endif

  close

  call shrinkmap#handler#reset(0)

  " Adjust current window number
  let l:cur_win += l:adjust

  " Resume window
  if l:cur_win != l:sm_win
    execute l:cur_win 'wincmd w'
  endif
endfunction "}}}


function! shrinkmap#debug(level, msg) "{{{
  if g:shrinkmap_debug >= a:level
    echom a:msg
  endif
endfunction "}}}

