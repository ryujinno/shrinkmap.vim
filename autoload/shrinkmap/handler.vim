let s:save_cpo = &cpo
set cpo&vim


function! shrinkmap#handler#reset(set) "{{{
  if a:set
    call s:init_lazy()
  else
    call s:stop_lazy_timer()
  end

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
      if !exists('s:timer')
        autocmd CursorHold,CursorHoldI   * call s:on_cursor_hold()
      end
    endif
  augroup END
endfunction "}}}


function! s:on_win_enter() "{{{
  call shrinkmap#debug(1, 'shrinkmap#handler.on_win_enter()')

  " Check window count
  if winnr('$') == 1
    " TODO: BUG: E173: 1 more file to edit
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
  call s:reset_lazy()
endfunction "}}}


function! s:on_text_changed() "{{{
  call shrinkmap#debug(1, 'shrinkmap#handler.on_text_changed()')
  call s:handle_lazy(1)
endfunction "}}}


function! s:on_cursor_moved() "{{{
  " TODO: FIXME: Mouse dragging bug
  call shrinkmap#debug(1, 'shrinkmap#handler.on_cursor_moved()')

  if bufname('%') !=# shrinkmap#buf_name()
    call shrinkmap#debug(1, 'shrinkmap#handler.on_cursor_moved(): Cursor moved in source buffer')

    call s:handle_lazy(0)
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
  call s:handle_lazy(1)
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
  call s:reset_lazy()
  if has('timers')
    call s:start_lazy_timer()
  endif
endfunction " }}}


function! s:start_lazy_timer() "{{{
  if !exists('s:timer')
    let timeout = float2nr(g:shrinkmap_lazy_limit_time * 1000)
    let s:timer = timer_start(timeout, function('s:lazy_update'), { 'repeat': -1 })
  endif
endfunction "}}}


function! s:stop_lazy_timer() "{{{
  if exists('s:timer')
    call timer_stop(s:timer)
    unlet s:timer
  endif
endfunction "}}}


function! s:handle_lazy(force) "{{{
  call s:set_lazy(a:force)
  if !exists('s:timer') && !s:too_hot()
    call s:lazy_update(-1)
  endif
endfunction "}}}


function! s:reset_lazy() "{{{
  let s:need_update = 0
  let s:force       = 0
endfunction "}}}


function! s:set_lazy(force) "{{{
  let s:need_update = 1
  if a:force
    let s:force = 1
  end
endfunction "}}}


let s:prev = str2float(reltimestr(reltime()))

function! s:too_hot() "{{{
  let now = str2float(reltimestr(reltime()))

  if now - s:prev > g:shrinkmap_lazy_limit_time
    let too_hot = 0
    let s:prev  = now
  else
    let too_hot = 1
  endif

  call shrinkmap#debug(1,
    \ 'shrinkmap#handler.too_hot()' .
    \ ', too_hot = ' . too_hot      .
    \ ', now = '     . printf('%f', now)
  \)

  return too_hot
endfunction " }}}


function! s:lazy_update(timer) "{{{
  call shrinkmap#debug(1,
    \ 'shrinkmap#handler.lazy_update()'    .
    \ ', a:timer = '       . a:timer       .
    \ ', s:need_update = ' . s:need_update .
    \ ', s:force = '       . s:force
  \)

  if s:need_update
    call shrinkmap#viewport#update(s:force)
    call s:reset_lazy()
  endif
endfunction "}}}


let &cpo = s:save_cpo
unlet s:save_cpo

