function! shrinkmap#viewport#update() "{{{
  " Check current buffer
  if !shrinkmap#current_buffer_is_target()
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

  " Move to shrinkmap window and buffer
  execute l:sm_win 'wincmd w'
  execute 'buffer ' bufnr(shrinkmap#buf_name_pattern())

  " Get previous buffer variables
  if exists('b:context')
    let l:prev_context       = b:context
    let l:prev_src_center    = b:src_center
    let l:prev_src_top       = b:src_top
    let l:prev_src_bottom    = b:src_bottom
    let l:prev_hilite_top    = b:hilite_top
    let l:prev_hilite_bottom = b:hilite_bottom
  else
    let l:prev_context       = -1
    let l:prev_src_center    = -1
    let l:prev_src_top       = -1
    let l:prev_src_bottom    = -1
    let l:prev_hilite_top    = -1
    let l:prev_hilite_bottom = -1
  endif

  " Set buffer variables
  let b:context       = l:context
  let b:src_center    = l:src_center
  let b:src_top       = l:src_top
  let b:src_bottom    = l:src_bottom
  let b:hilite_top    = l:hilite_top
  let b:hilite_bottom = l:hilite_bottom

  " Resume to current window
  execute l:context.cur_win 'wincmd w'

  if l:src_top != l:prev_src_top || l:src_bottom != l:prev_src_bottom
    " Init canvas
    let l:canvas = shrinkmap#canvas#init()

    " Draw line on canvas
    let l:y = 0
    let l:lines = getline(l:src_top, l:src_bottom)
    for l:line in l:lines
      let l:indent = substitute(l:line, '^\(\s*\)\S.*', '\1', '')
      let l:x1     = strdisplaywidth(l:indent) / g:shrinkmap_horizontal_shrink
      let l:x2     = strdisplaywidth(l:line)   / g:shrinkmap_horizontal_shrink

      if g:shrinkmap_debug >= 2
        call shrinkmap#debug(2,
        \ 'shrinkmap#viewport#update()' .
        \ ': y = '  . l:y  .
        \ ', x1 = ' . l:x1 .
        \ ', x2 = ' . l:x2
        \)
      endif

      call shrinkmap#canvas#allocate(l:canvas, l:y, l:x2, l:view_width)
      call shrinkmap#canvas#draw_line(l:canvas, l:y, l:x1, l:x2, l:view_width)

      let l:y += 1
    endfor
  endif

  " Move to shrinkmap window and buffer
  execute l:sm_win 'wincmd w'
  execute 'buffer ' bufnr(shrinkmap#buf_name_pattern())

  if l:src_top != l:prev_src_top || l:src_bottom != l:prev_src_bottom
    " Start modify
    setlocal modifiable

    " Delete shrinkmap buffer
    silent %delete _

    " Put canvas to shrinkmap buffer
    call append(0, shrinkmap#canvas#get_frame(l:canvas, l:view_width))

    " End modify
    setlocal nomodifiable
  endif

  " Highlight
  execute 'match ' . g:shrinkmap_highlight_name . ' /' .
    \ '\%>' . l:hilite_top          . 'l' .
    \ '\%<' . (l:hilite_bottom + 1) . 'l' .
  \'./'

  " Scroll
  normal! gg

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
  " Move to previous window
  wincmd p

  " Get current window
  if !shrinkmap#current_buffer_is_target()
    return
  endif

  " Get previous window number
  let l:prev_win = bufwinnr('%')

  " Move to shrinkmap window
  let l:sm_win = bufwinnr(shrinkmap#buf_name_pattern())
  execute l:sm_win 'wincmd w'

  if !exists('b:src_top')
    " Move to previous window to scroll
    execute l:prev_win 'wincmd w'
  else
    " Get new source top line
    let l:src_shift = (a:mouse_line - 1) * shrinkmap#canvas#braille_height()
    let l:new_src_top = b:src_top + l:src_shift

    call shrinkmap#debug(1,
    \ 'shrinkmap#viewport#scroll()' .
    \ ': mouse_line = '  . a:mouse_line .
    \ ', src_shift = '   . l:src_shift .
    \ ', new_src_top = ' . l:new_src_top
    \)

    " Move to previous window to scroll
    execute l:prev_win 'wincmd w'

    " Jump to mouse clicked
    execute 'normal! ' . l:new_src_top . 'gg'
  endif
endfunction " }}}

