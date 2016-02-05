let s:save_cpo = &cpo
set cpo&vim


function! shrinkmap#viewport#update(force) "{{{
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

  " Resize shirnkmap sidebar
  execute l:sm_win 'wincmd w'
  execute 'vertical resize' g:shrinkmap_sidebar_width
  call s:resume_context(l:context)

  " Prepare for viewport
  let l:braille_height = shrinkmap#canvas#braille_height()
  let l:view_width     = winwidth(l:sm_win)
  let l:view_height    = winheight(l:sm_win)
  let l:display_top    = line('w0')
  let l:display_bottom = line('w$')
  let l:bottom         = line('$')

  " Get source lines
  let l:src_center             = (l:display_top + l:display_bottom) / 2
  let l:src_lines_of_half_view = l:view_height * l:braille_height / 2
  let l:src_top                = l:src_center - l:src_lines_of_half_view
  let l:src_bottom             = l:src_center + l:src_lines_of_half_view
  if l:src_top < 1
    let l:src_top    = 1
    let l:src_bottom = min([l:view_height * l:braille_height, l:bottom])
  elseif l:src_bottom > l:bottom
    let l:src_top    = max([l:bottom - l:view_height * l:braille_height, 1])
    let l:src_bottom = l:bottom
  endif

  " Previous source lines
  let l:sm_buf          = bufnr(shrinkmap#buf_name_pattern())
  let l:prev_src_top    = getbufvar(l:sm_buf, 'src_top')
  let l:prev_src_bottom = getbufvar(l:sm_buf, 'src_bottom')
  call setbufvar(l:sm_buf, 'src_top',    l:src_top)
  call setbufvar(l:sm_buf, 'src_bottom', l:src_bottom)

  " Scrolled or not
  let l:scrolled = (l:src_top != l:prev_src_top || l:src_bottom != l:prev_src_bottom)

  " Get highlight lines
  let l:hilite_top     = max([(l:display_top    - l:src_top + 1) / l:braille_height, 1])
  let l:hilite_bottom  = min([(l:display_bottom - l:src_top + 1) / l:braille_height, l:view_height])


  call shrinkmap#debug(1,
    \ 'shrinkmap#viewport#update()'              .
    \ ': force = '           . a:force           .
    \ ', view_width = '      . l:view_width      .
    \ ', view_height = '     . l:view_height     .
    \ ', display_top = '     . l:display_top     .
    \ ', display_bottom = '  . l:display_bottom  .
    \ ', src_top = '         . l:src_top         .
    \ ', src_bottom = '      . l:src_bottom      .
    \ ', prev_src_top = '    . l:prev_src_top    .
    \ ', prev_src_bottom = ' . l:prev_src_bottom .
    \ ', scrolled = '        . l:scrolled        .
    \ ', hilite_top = '      . l:hilite_top      .
    \ ', hilite_bottom = '   . l:hilite_bottom
  \)

  " Init canvas
  let l:canvas = shrinkmap#canvas#init()

  if a:force || l:scrolled
    call s:draw_canvas(l:canvas, src_top, src_bottom, l:view_width)
  endif

  " Move to shrinkmap window and buffer
  execute l:sm_win 'wincmd w'
  execute 'buffer ' bufnr(shrinkmap#buf_name_pattern())

  if a:force || l:scrolled
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
    \ '\%>' . (l:hilite_top    - 1) . 'l' .
    \ '\%<' . (l:hilite_bottom + 1) . 'l' .
  \'./'

  " Move calet to topleft
  normal! gg0

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


function! s:draw_canvas(canvas, src_top, src_bottom, view_width) "{{{
  let l:x_max_dot = a:view_width * shrinkmap#canvas#braille_width() - 1
  let l:y_dot = 0
  let l:i = a:src_top
  while l:i <= a:src_bottom
    let l:indent_len = indent(l:i)
    let l:line_len   = strdisplaywidth(getline(l:i))
    let l:x_dot_start = min([l:indent_len     / g:shrinkmap_horizontal_shrink, l:x_max_dot])
    let l:x_dot_end   = min([(l:line_len - 1) / g:shrinkmap_horizontal_shrink, l:x_max_dot])

    if g:shrinkmap_debug >= 2
      call shrinkmap#debug(2,
        \ 'shrinkmap#viewport.draw_canvas()' .
        \ ': y_dot = '       . l:y_dot       .
        \ ', indent_len = '  . l:indent_len  .
        \ ', line_len = '    . l:line_len    .
        \ ', x_max_dot = '   . l:x_max_dot   .
        \ ', x_dot_start = ' . l:x_dot_start .
        \ ', x_dot_end = '   . l:x_dot_end
      \)
    endif

    if l:indent_len < l:line_len
      call shrinkmap#canvas#allocate(a:canvas, l:y_dot, l:x_dot_end)
      call shrinkmap#canvas#draw_line(a:canvas, l:y_dot, l:x_dot_start, l:x_dot_end)
    endif

    let l:i += 1
    let l:y_dot += 1
  endwhile
endfunction "}}}


function! s:resume_context(context) "{{{
  " Resume to current window
  execute a:context.cur_win 'wincmd w'

  " Resume visual mode
  if a:context.mode ==# 'v' || a:context.mode ==# 'V' || a:context.mode ==# "\<C-v>"
    normal! gv
  endif
endfunction "}}}


function! shrinkmap#viewport#jump(mouse_line) "{{{
  " Move to previous window
  wincmd p

  " Check current buffer
  if !shrinkmap#current_buffer_is_target()
    return
  endif

  let l:src_top = getbufvar(shrinkmap#buf_name_pattern(), 'src_top')
  if l:src_top !=# ''
    " Get new source top line
    let l:src_jump = (a:mouse_line - 1) * shrinkmap#canvas#braille_height()
    let l:new_src_top = l:src_top + l:src_jump

    call shrinkmap#debug(1,
      \ 'shrinkmap#viewport#jump()' .
      \ ': mouse_line = '  . a:mouse_line .
      \ ', src_top = '     . l:src_top    .
      \ ', src_jump = '    . l:src_jump   .
      \ ', new_src_top = ' . l:new_src_top
    \)

    " Jump to mouse clicked
    execute 'normal! ' . l:new_src_top . 'gg0'
  endif
endfunction " }}}


let &cpo = s:save_cpo
unlet s:save_cpo

