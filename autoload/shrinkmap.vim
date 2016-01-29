let s:buf_name         = '[shrinkmap]'
let s:buf_name_pattern = '\[shrinkmap\]'

let s:reltime          = 0
let s:lazy_count       = 0
let s:text_processed   = 0


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

  " Open window
  execute 'botright ' g:shrinkmap_window_width ' vnew ' s:buf_name

  call s:set_buffer()
  call s:handler(1)

  " Resume window
  execute l:cur_win 'wincmd w'

  " Update shrinkmap
  let s:delay_count = 0
  call shrinkmap#update()
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

function! s:handler(set) "{{{
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
endfunction "}}}


function! s:unset() "{{{
  augroup shrinkmap_group
    autocmd!
  augroup END
endfunction "}}}


function! s:on_win_enter() "{{{
  call shrinkmap#debug_message(1, 'shrinkmap: on_win_enter()')

  " Check window count
  if winnr('$') == 1
    quit
  endif

  " TODO: UNDERCONST: Scroll against mouse click
endfunction "}}}


function! s:on_buf_win_enter() "{{{
  call shrinkmap#debug_message(1, 'shrinkmap: on_buf_win_enter()')

  call shrinkmap#update()
endfunction "}}}


function! s:on_insert() "{{{
  call shrinkmap#debug_message(1, 'shrinkmap: on_insert()')

  call shrinkmap#update()
  let s:text_processed = 0
endfunction "}}}


function! s:on_text_changed() "{{{
  call shrinkmap#debug_message(1, 'shrinkmap: on_text_changed()')

  if !s:too_hot()
    call shrinkmap#update()
    let s:text_processed = 1
    let s:lazy_count += 1
  else
    let s:text_processed = 0
  endif
endfunction "}}}


function! s:on_cursor_moved() "{{{
  call shrinkmap#debug_message(1, 'shrinkmap: on_cursor_moved()')

  if bufname('%') !=# s:buf_name
    call shrinkmap#debug_message(2, 'Cursor moved in the other buffer')

    if !s:too_hot()
      call shrinkmap#update()
    endif
  else
    let l:mouse      = getchar()
    let l:mouse_win  = v:mouse_win
    let l:mouse_lnum = v:mouse_lnum

    if l:mouse_win == 0
      call shrinkmap#debug_message(1, 'Got focus of shrinkmap window')

      " Move to previous window to drop focus
      wincmd p
    else
      call shrinkmap#debug_message(1, 'Mouse clicked in shrinkmap window')
      if exists('b:hilite_top')
        call shrinkmap#debug_message(1, 'Jump to mouse clicked')

        " Get new source top line
        let l:src_shift = (l:mouse_lnum - 1) * canvas#braille_height()
        let l:new_src_top = b:src_top + l:src_shift

        call shrinkmap#debug_message(1,
        \ 'mouse = ' . l:mouse . ', mouse_win = ' . l:mouse_win . ', mouse_lnum = ' . l:mouse_lnum .
        \ ', src_shift = ' . l:src_shift . ', new_src_top = ' . l:new_src_top
        \)

        " Move to previous window to scroll
        wincmd p

        " Jump to mouse clicked
        execute 'normal! ' . l:new_src_top . 'gg'
      endif

      call shrinkmap#update()
    endif
  endif
endfunction "}}}


function! s:on_cursor_moved_on_insert() "{{{
  call shrinkmap#debug_message(1, 'shrinkmap: on_cursor_moved_on_insert()')

  if !s:too_hot()
    call shrinkmap#update()
  endif
endfunction "}}}


function! s:on_resized() "{{{
  call shrinkmap#debug_message(1, 'shrinkmap: on_resized()')

  call shrinkmap#update()
endfunction "}}}


function! s:on_cursor_hold() "{{{
  call shrinkmap#debug_message(1, 'shrinkmap: on_cursor_hold()')

  call shrinkmap#update()
endfunction "}}}


function! s:too_hot() "{{{
  let l:reltime = str2float(reltimestr(reltime()))

  if l:reltime - s:reltime > g:shrinkmap_lazy_limit_time || s:lazy_count > g:shrinkmap_lazy_limit_count
    let l:too_hot = 0
    let s:lazy_count = 0
  elseif s:text_processed
    let l:too_hot = 1
  else
    let l:too_hot = 1
    let s:lazy_count += 1
  endif

  let s:reltime = l:reltime

  return l:too_hot
endfunction " }}}


function! shrinkmap#update() "{{{
  " Check current buffer
  let l:bufname = bufname('%')
  if l:bufname ==# s:buf_name       ||
    \l:bufname ==# '[Command Line]' ||
    \l:bufname =~ '^vimfiler:'      ||
    \l:bufname =~ '^\[Unite\]'      ||
    \l:bufname =~ '^NERD_tree'
    return
  endif

  " Check shrinkmap buffer
  if l:bufname ==# s:buf_name
    return
  endif

  " Check shrinkmap window
  let l:sm_win = bufwinnr(s:buf_name_pattern)
  if l:sm_win < 0
    return
  endif

  " Get context
  let l:context = s:get_context()

  " Prepare for viewport
  let l:braille_height = canvas#braille_height()
  let l:view_height    = winheight(l:sm_win)
  let l:bottom         = line('$')

  " Get source lines
  let l:src_center  = (line('w0') + line('w$')) / 2
  let l:src_top     = l:src_center - l:view_height / 2 * l:braille_height
  let l:src_bottom  = l:src_center + l:view_height / 2 * l:braille_height
  if l:src_top < 0
    let l:src_top    = 0
    let l:src_bottom = min([l:view_height * l:braille_height, l:bottom])
  elseif l:src_bottom > l:bottom
    let l:src_top    = max([l:bottom - l:view_height * l:braille_height, 0])
    let l:src_bottom = l:bottom
  endif

  " Get highlight lines
  let l:hilite_top     = max([(line('w0') - l:src_top) / l:braille_height, 0])
  let l:hilite_bottom  = min([(line('w$') - l:src_top) / l:braille_height + 1, l:view_height])
  call shrinkmap#debug_message(1,
      \ 'shrinkmap#update(): src_top = ' . l:src_top . ', src_bottom = ' . l:src_bottom .
      \ ', hilite_top = ' . l:hilite_top . ', hilite_bottom = ' . l:hilite_bottom
  \)

  " Init canvas
  let l:canvas = canvas#init()

  " Draw line on canvas
  let l:y = 0
  let l:lines = getline(l:src_top, l:src_bottom)
  for l:line in l:lines
    let l:indent = substitute(l:line, '^\(\s*\)\S.*', '\1', '')
    let l:x1     = strdisplaywidth(l:indent)
    let l:x2     = strdisplaywidth(l:line)

    if l:x1 < l:x2
      call shrinkmap#debug_message(2,
      \ 'shrinkmap#update(): y = ' . l:y . ', x2 = ' . l:x2 . ', x1 = ' . l:x1
      \)

      call canvas#allocate(l:canvas, l:x2, l:y, g:shrinkmap_window_width)
      call canvas#draw_line(l:canvas, l:y, l:x1, l:x2, g:shrinkmap_window_width)
    endif

    let l:y += 1
  endfor

  " Move to shrinkmap window and buffer
  execute l:sm_win 'wincmd w'
  execute 'buffer ' bufnr(s:buf_name_pattern)

  " Start modify
  setlocal modifiable

  " Delete shrinkmap buffer
  silent %delete _

  " Put canvas to shrinkmap buffer
  call append(0, canvas#get_frame(l:canvas, g:shrinkmap_window_width))

  " Highlight
  execute 'match CursorLine /\%>' . l:hilite_top . 'l\%<' . (l:hilite_bottom + 1) . 'l./'

  " Scroll
  normal! gg

  " Set buffer variables for mouse click at on_cursor_moved()
  let b:src_center    = l:src_center
  let b:src_top       = l:src_top
  let b:src_bottom    = l:src_bottom
  let b:hilite_top    = l:hilite_top
  let b:hilite_bottom = l:hilite_bottom

  " End modify
  setlocal nomodifiable

  " Resume context
  call s:resume_context(l:context)
endfunction "}}}


function! s:get_context() "{{{
  let l:context = {}

  " Get mode
  let l:context.mode = mode()

  " Get current window
  let l:context.cur_win = winnr()

  return l:context
endfunction "}}}


function! s:resume_context(context) "{{{
  " Resume to current window
  execute a:context.cur_win 'wincmd w'

  " Resume visual mode
  if a:context.mode ==# 'v' || a:context.mode ==# 'V' || a:context.mode ==# "\026"
    normal! gv
  endif
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

  close

  call s:handler(0)

  " Resume window
  if l:cur_win != l:sm_win
    execute l:cur_win 'wincmd w'
  endif
endfunction "}}}


function! shrinkmap#debug_message(level, msg) "{{{
  if g:shrinkmap_debug >= a:level
    echom a:msg
  endif
endfunction "}}}
