let s:save_cpo = &cpo
set cpo&vim


let s:sidebar_align = g:shrinkmap_sidebar_align

function! shrinkmap#sidebar#toggle() "{{{
  if bufwinnr(shrinkmap#buf_name_pattern()) < 0
    call shrinkmap#sidebar#open()
  else
    call shrinkmap#sidebar#close()
  endif
endfunction "}}}


function! shrinkmap#sidebar#open() "{{{
  " Check shrinkmap window
  if bufwinnr(shrinkmap#buf_name_pattern()) > 0
    return
  endif

  " Check current buffer
  if !shrinkmap#current_buffer_is_target()
    call shrinkmap#debug(0, 'Current buffer is not a target of ShrinkMap')
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

  " Resize already open window
  execute 'vertical resize' g:shrinkmap_sidebar_width

  call s:set_buffer()
  call shrinkmap#handler#reset(1)

  " Resume window
  execute cur_win 'wincmd w'

  " Update shrinkmap
  call shrinkmap#viewport#update(1)
endfunction "}}}


function! s:set_buffer() "{{{
  " Temporary buffer
  setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted

  " Simple viewport
  setlocal nonumber norelativenumber nolist nowrap

  " Read only
  setlocal readonly nomodifiable

  " Window
  setlocal winfixwidth
endfunction "}}}


function! shrinkmap#sidebar#close() "{{{
  " Check shrinkmap window
  let sm_win = bufwinnr(shrinkmap#buf_name_pattern())
  if sm_win < 0
    return
  endif

  " Get current and shrinkmap window
  let cur_win = winnr()

  " Move to shrinkmap window
  execute sm_win 'wincmd w'

  " Unset handler
  call shrinkmap#handler#reset(0)

  " Close shrinkmap window
  close

  " Adjust current window number
  if s:sidebar_align ==# 'right'
    let adjust = 0
  elseif s:sidebar_align ==# 'left'
    let adjust = -1
  else
    call shrinkmap#debug(0,
      \ 'shrinkmap#sidebar#close(): ' .
      \ 'Unknown sidebar align: '     .
      \ s:sidebar_align
    \)
    return
  endif
  let cur_win += adjust

  " Resume window
  if cur_win != sm_win
    execute cur_win 'wincmd w'
  endif
endfunction "}}}


let &cpo = s:save_cpo
unlet s:save_cpo

