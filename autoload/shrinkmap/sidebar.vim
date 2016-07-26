let s:save_cpo = &cpo
set cpo&vim


let s:sidebar_align = g:shrinkmap_sidebar_align

function! shrinkmap#sidebar#toggle() "{{{
  if shrinkmap#win() < 0
    call shrinkmap#sidebar#open()
  else
    call shrinkmap#sidebar#close()
  endif
endfunction "}}}


function! shrinkmap#sidebar#open() "{{{
  " Check shrinkmap window
  if shrinkmap#win() > 0
    return
  endif

  " Check current buffer
  if !shrinkmap#is_current_buffer_target()
    call shrinkmap#debug(1, 'Current buffer is not a target of ShrinkMap')
    return
  endif

  " Get current window
  let cur_win = winnr()

  " Keep sidebar align
  let s:sidebar_align = g:shrinkmap_sidebar_align
  if s:sidebar_align ==# 'right'
    let align  = 'botright'
    let adjust = 0
  elseif s:sidebar_align ==# 'left'
    let align  = 'topleft'
    let adjust = 1
  else
    call shrinkmap#debug(0,
      \ 'shrinkmap#sidebar#open(): '             .
      \ 'g:shrinkmap_sidebar_align is invalid: ' .
      \ g:shrinkmap_sidebar_align
    \)
    return
  endif

  " Open window
  execute align g:shrinkmap_sidebar_width 'vnew' shrinkmap#buf_name()

  " Adjust window number
  let cur_win += adjust

  call s:set_buffer()
  call shrinkmap#handler#reset(1)

  " Resume window
  execute cur_win 'wincmd w'

  " Update shrinkmap
  call shrinkmap#viewport#update()
endfunction "}}}


function! s:set_buffer() "{{{
  " Temporary buffer
  setlocal buftype=nofile bufhidden=delete noswapfile nobuflisted

  " Simple viewport
  setlocal nonumber norelativenumber nolist nowrap

  " Read only
  setlocal readonly nomodifiable

  " Window
  setlocal winfixwidth
endfunction "}}}


function! shrinkmap#sidebar#close() "{{{
  " Check shrinkmap window
  if shrinkmap#win() < 0
    return
  endif

  " Unset handler
  call shrinkmap#handler#reset(0)

  " Close shrinkmap window
  execute 'bdelete' shrinkmap#buf()
endfunction "}}}


let &cpo = s:save_cpo
unlet s:save_cpo

