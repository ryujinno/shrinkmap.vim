function! shrinkmap#viewport#update() "{{{
  " Check current buffer
  let l:bufname = bufname('%')
  if l:bufname ==# shrinkmap#buf_name() ||
    \l:bufname ==# '[Command Line]'     ||
    \l:bufname =~ '^vimfiler:'          ||
    \l:bufname =~ '^\[Unite\]'          ||
    \l:bufname =~ '^NERD_tree'
    return
  endif

  " Check shrinkmap buffer
  if l:bufname ==# shrinkmap#buf_name()
    return
  endif

  " Check shrinkmap window
  let l:sm_win = bufwinnr(shrinkmap#buf_name_pattern())
  if l:sm_win < 0
    return
  endif

  " Get context
  let l:context = s:get_context()

  " Prepare for viewport
  let l:braille_height = shrinkmap#canvas#braille_height()
  let l:view_width     = winwidth(l:sm_win)
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
  call shrinkmap#debug(1,
      \ 'shrinkmap#viewport#update()' .
      \ ': view_width = '    . l:view_width  .
      \ ', view_height = '   . l:view_height .
      \ ', src_top = '       . l:src_top     .
      \ ', src_bottom = '    . l:src_bottom  .
      \ ', hilite_top = '    . l:hilite_top  .
      \ ', hilite_bottom = ' . l:hilite_bottom
  \)

  " Init canvas
  let l:canvas = shrinkmap#canvas#init()

  " Draw line on canvas
  let l:y = 0
  let l:lines = getline(l:src_top, l:src_bottom)
  for l:line in l:lines
    let l:indent = substitute(l:line, '^\(\s*\)\S.*', '\1', '')
    let l:x1     = strdisplaywidth(l:indent)
    let l:x2     = strdisplaywidth(l:line)

    if l:x1 < l:x2
      call shrinkmap#debug(2,
      \ 'shrinkmap#viewport#update()' .
      \ ': y = '  . l:y  .
      \ ', x1 = ' . l:x1 .
      \ ', x2 = ' . l:x2
      \)

      call shrinkmap#canvas#allocate(l:canvas, l:y, l:x2, l:view_width)
      call shrinkmap#canvas#draw_line(l:canvas, l:y, l:x1, l:x2, l:view_width)
    endif

    let l:y += 1
  endfor

  " Move to shrinkmap window and buffer
  execute l:sm_win 'wincmd w'
  execute 'buffer ' bufnr(shrinkmap#buf_name_pattern())

  " Start modify
  setlocal modifiable

  " Delete shrinkmap buffer
  silent %delete _

  " Put canvas to shrinkmap buffer
  call append(0, shrinkmap#canvas#get_frame(l:canvas, l:view_width))

  " Highlight
  execute 'match CursorLine /\%>' . l:hilite_top . 'l\%<' . (l:hilite_bottom + 1) . 'l./'

  " Scroll
  normal! gg

  " Set buffer variables for mouse click at on_cursor_moved()
  let b:context       = l:context
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

function! shrinkmap#viewport#scroll(mouse_line) "{{{
  call shrinkmap#debug(1, 'shrinkmap#viewport#scroll(): Mouse clicked in shrinkmap window')
  if exists('b:hilite_top')
    call shrinkmap#debug(1, 'shrinkmap#viewport#scroll(): Jump to mouse clicked')

    " Get new source top line
    let l:src_shift = (a:mouse_line - 1) * shrinkmap#canvas#braille_height()
    let l:new_src_top = b:src_top + l:src_shift

    call shrinkmap#debug(1,
    \ 'shrinkmap#viewport#scroll()' .
    \ ': mouse_line = ' . a:mouse_line .
    \ ', src_shift = ' . l:src_shift .
    \ ', new_src_top = ' . l:new_src_top
    \)

    " Move to previous window to scroll
    wincmd p

    " Jump to mouse clicked
    execute 'normal! ' . l:new_src_top . 'gg'
  endif
endfunction " }}}

