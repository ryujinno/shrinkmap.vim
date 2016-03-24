let s:save_cpo = &cpo
set cpo&vim


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
  " TODO: FIXME: Mouse dragging bug
  call shrinkmap#debug(1, 'shrinkmap#handler.on_cursor_moved()')

  if bufname('%') !=# shrinkmap#buf_name()
    call shrinkmap#debug(1, 'shrinkmap#handler.on_cursor_moved(): Cursor moved in source buffer')

    if !s:too_hot(0)
      call shrinkmap#viewport#update(0)
    endif
  else
    let pos    = getpos('.')
    let line   = pos[1]
    let column = pos[2]
    call shrinkmap#debug(1,
      \ 'shrinkmap#handler.on_cursor_moved()' .
      \ ': bufnum = ' . pos[0] .
      \ ', line = '   . line   .
      \ ', column = ' . column .
      \ ', off = '    . pos[3]
    \)

    if line == 1 && column == 1
      call shrinkmap#debug(1, 'shrinkmap#handler.on_cursor_moved(): Got focus of shrinkmap window')

      " Move to previous window to drop focus
      wincmd p
    else
      call shrinkmap#debug(1, 'shrinkmap#handler.on_cursor_moved(): Mouse clicked in shrinkmap window')
      call shrinkmap#viewport#jump(line)
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
    let too_hot = 1
  else
    let reltime = str2float(reltimestr(reltime()))

    if reltime - s:reltime > g:shrinkmap_lazy_limit_time || s:lazy_count > g:shrinkmap_lazy_limit_count
      let s:lazy_count = 0
      let too_hot      = 0
    else
      let s:lazy_count += 1
      let too_hot       = 1
    endif

    let s:reltime = reltime
  endif

  let s:in_double = a:double

  call shrinkmap#debug(1,
    \ 'shrinkmap#handler.too_hot()'    .
    \ ': double = '     . a:double     .
    \ ', lazy_count = ' . s:lazy_count .
    \ ', too_hot = '    . too_hot
  \)

  return too_hot
endfunction " }}}


let &cpo = s:save_cpo
unlet s:save_cpo

