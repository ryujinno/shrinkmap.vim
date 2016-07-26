let s:save_cpo = &cpo
set cpo&vim


function! shrinkmap#handler#reset(set) "{{{
  if a:set
    call s:init_timer()
  else
    call s:stop_timer()
  end

  augroup shrinkmap_group
    autocmd!
    if a:set
      autocmd WinEnter <buffer>          call s:on_win_enter()
      autocmd BufWinEnter              * call s:on_buf_win_enter()
      autocmd CursorMoved              * call s:on_cursor_moved()
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
  if winnr('$') > 1
    return
  end

  " Get previous source buffer
  let sm_buf = shrinkmap#buf()
  let prev_src_buf = getbufvar(sm_buf, 'src_buf')

  " Get next buffers
  let buffers = filter(range(1, bufnr('$')),
    \ 'v:val > prev_src_buf && shrinkmap#is_buffer_target(bufname(v:val))'
  \)
  call shrinkmap#debug(1, 'prev_src_buf = ' . prev_src_buf)
  for num in buffers
    call shrinkmap#debug(1, 'bufnr = ' . num . ', bufname = ' . bufname(num))
  endfor

  if len(buffers) >= 1
    " Switch to next buffer
    execute 'silent buffer' buffers[0]
    filetype detect
    call shrinkmap#sidebar#open()
  else
    quit
  endif
endfunction "}}}


function! s:on_buf_win_enter() "{{{
  call shrinkmap#debug(1, 'shrinkmap#handler.on_buf_win_enter()')
  call shrinkmap#viewport#update()
endfunction "}}}


function! s:on_insert() "{{{
  call shrinkmap#debug(1, 'shrinkmap#handler.on_insert()')
  call shrinkmap#viewport#update()
endfunction "}}}


function! s:on_cursor_moved() "{{{
  " Mouse support
  " TODO: FIXME: Mouse dragging bug
  call shrinkmap#debug(1, 'shrinkmap#handler.on_cursor_moved()')

  if bufname('%') ==# shrinkmap#buf_name()
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
      call shrinkmap#viewport#update()
    endif
  endif
endfunction "}}}


function! s:on_resized() "{{{
  call shrinkmap#debug(1, 'shrinkmap#handler.on_resized()')
  call shrinkmap#viewport#update()
endfunction "}}}


function! s:on_cursor_hold() "{{{
  call shrinkmap#debug(1, 'shrinkmap#handler.on_cursor_hold()')
  call shrinkmap#viewport#update()
endfunction "}}}


function! s:init_timer() "{{{
  if has('timers')
    if !exists('s:timer')
      let timeout = float2nr(g:shrinkmap_lazy_draw_interval * 1000)
      if timeout > 0
        let s:timer = timer_start(timeout, function('s:lazy_update'), { 'repeat': -1 })
      endif
    endif
  endif
endfunction "}}}


function! s:lazy_update(timer_id) "{{{
  call shrinkmap#debug(2,
    \ 'shrinkmap#handler.lazy_update()'
  \)

  call shrinkmap#viewport#update()
endfunction "}}}


function! s:stop_timer() "{{{
  if exists('s:timer')
    call timer_stop(s:timer)
    unlet s:timer
  endif
endfunction "}}}


let &cpo = s:save_cpo
unlet s:save_cpo

