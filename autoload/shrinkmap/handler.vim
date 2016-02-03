function! shrinkmap#handler#reset(set) "{{{
  augroup shrinkmap_group
    autocmd!
    if a:set
      autocmd WinEnter <buffer>          call s:on_win_enter()
      autocmd BufWinEnter              * call s:on_buf_win_enter()
      autocmd TextChanged,TextChangedI * call s:on_text_changed()
      autocmd CursorMoved              * call s:on_cursor_moved()
      autocmd CursorMovedI             * call s:on_cursor_moved_on_insert()
      autocmd InsertEnter,InsertLeave  * call s:on_insert()
      autocmd VimResized               * call s:on_resized()
      autocmd CursorHold,CursorHoldI   * call s:on_cursor_hold()
    endif
  augroup END

  call s:init_lazy()
endfunction "}}}


function! s:on_win_enter() "{{{
  call shrinkmap#debug(1, 'shrinkmap#handler.on_win_enter()')

  " Check window count
  if winnr('$') == 1
    quit
  endif
endfunction "}}}


function! s:on_buf_win_enter() "{{{
  call shrinkmap#debug(1, 'shrinkmap#handler.on_buf_win_enter()')

  call shrinkmap#viewport#update(1)
endfunction "}}}


function! s:on_insert() "{{{
  call shrinkmap#debug(1, 'shrinkmap#handler.on_insert()')

  call shrinkmap#viewport#update(1)
  call s:init_lazy()
endfunction "}}}


function! s:on_text_changed() "{{{
  call shrinkmap#debug(1, 'shrinkmap#handler.on_text_changed()')

  if !s:too_hot(1)
    call shrinkmap#viewport#update(1)
  endif
endfunction "}}}


function! s:on_cursor_moved() "{{{
  " TOOD: FIXME: Mouse dragging bug
  call shrinkmap#debug(1, 'shrinkmap#handler.on_cursor_moved()')

  if bufname('%') !=# shrinkmap#buf_name()
    call shrinkmap#debug(1, 'shrinkmap#handler.on_cursor_moved(): Cursor moved in the other buffer')

    if !s:too_hot(0)
      call shrinkmap#viewport#update(0)
    endif
  else
    let l:char       = getchar()
    let l:mouse_win  = v:mouse_win
    let l:mouse_lnum = v:mouse_lnum

    call shrinkmap#debug(1,
      \ 'shrinkmap#handler.on_cursor_moved()' .
      \ ': char = '       . l:char            .
      \ ', mouse_win = '  . l:mouse_win       .
      \ ', mouse_lnum = ' . l:mouse_lnum
    \)

    if l:mouse_win == 0
      call shrinkmap#debug(1, 'shrinkmap#handler.on_cursor_moved(): Got focus of shrinkmap window')

      " Move to previous window to drop focus
      wincmd p
    else
      call shrinkmap#debug(1, 'shrinkmap#handler.on_cursor_moved(): Mouse clicked in shrinkmap window')
      call shrinkmap#viewport#jump(l:mouse_lnum)
      call shrinkmap#viewport#update(1)
    endif
  endif
endfunction "}}}


function! s:on_cursor_moved_on_insert() "{{{
  call shrinkmap#debug(1, 'shrinkmap#handler.on_cursor_moved_on_insert()')

  if !s:too_hot(0)
    call shrinkmap#viewport#update(1)
  endif
endfunction "}}}


function! s:on_resized() "{{{
  call shrinkmap#debug(1, 'shrinkmap#handler.on_resized()')

  call shrinkmap#viewport#update(1)
endfunction "}}}


function! s:on_cursor_hold() "{{{
  call shrinkmap#debug(1, 'shrinkmap#handler.on_cursor_hold()')

  call shrinkmap#viewport#update(1)
endfunction "}}}


function! s:init_lazy() "{{{
  let s:reltime    = 0
  let s:lazy_count = 0
  let s:in_double  = 0
endfunction " }}}


function! s:too_hot(double) "{{{
  if s:in_double
    let s:in_double = 0
    let l:too_hot   = 1
  else
    let l:reltime = str2float(reltimestr(reltime()))

    if l:reltime - s:reltime > g:shrinkmap_lazy_limit_time || s:lazy_count > g:shrinkmap_lazy_limit_count
      let s:lazy_count  = 0
      let l:too_hot     = 0
    else
      let s:lazy_count += 1
      let l:too_hot     = 1
    endif

    let s:reltime = l:reltime
  endif

  if a:double
    let s:in_double = 1
  else
    let s:in_double = 0
  end

  call shrinkmap#debug(1,
    \ 'shrinkmap#handler.too_hot()'    .
    \ ': double = '     . a:double     .
    \ ', in_double = '  . s:in_double  .
    \ ', lazy_count = ' . s:lazy_count .
    \ ', too_hot = '    . l:too_hot
  \)

  return l:too_hot
endfunction " }}}

