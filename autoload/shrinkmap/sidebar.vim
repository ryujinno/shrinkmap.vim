let s:sidebar_align    = g:shrinkmap_sidebar_align

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
    shrinkmap#debug(0,
    \ 'shrinkmap#sidebar#open(): '             .
    \ 'g:shrinkmap_sidebar_align is invalid: ' .
    \ g:shrinkmap_sidebar_align
    \)
    return
  endif

  " Open window
  execute l:align g:shrinkmap_sidebar_width 'vnew' shrinkmap#buf_name()

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


function! shrinkmap#sidebar#close() "{{{
  " Check shrinkmap window
  let l:sm_win = bufwinnr(shrinkmap#buf_name_pattern())
  if l:sm_win < 0
    return
  endif

  " Get current and shrinkmap window
  let l:cur_win = winnr()

  " Move to shrinkmap window
  execute l:sm_win 'wincmd w'

  " Unset handler
  call shrinkmap#handler#reset(0)

  " Close shrinkmap window
  close

  " Adjust current window number
  if s:sidebar_align ==# 'right'
    let l:adjust = 0
  elseif s:sidebar_align ==# 'left'
    let l:adjust = -1
  else
    shrinkmap#debug(0,
    \ 'shrinkmap#sidebar#close(): ' .
    \ 'Unknown sidebar align: '     .
    \ s:sidebar_align
    \)
    return
  endif
  let l:cur_win += l:adjust

  " Resume window
  if l:cur_win != l:sm_win
    execute l:cur_win 'wincmd w'
  endif
endfunction "}}}

