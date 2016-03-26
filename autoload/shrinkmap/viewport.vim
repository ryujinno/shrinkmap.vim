let s:save_cpo = &cpo
set cpo&vim


function! shrinkmap#viewport#update(force) "{{{
  " Check current buffer
  if !shrinkmap#is_current_buffer_target()
    return
  endif

  " Check shrinkmap window
  let sm_win = shrinkmap#win()
  if sm_win < 0
    return
  endif

  " Get context
  let context = s:get_context()

  " Resize shrinkmap sidebar
  execute sm_win 'wincmd w'
  execute 'vertical resize' g:shrinkmap_sidebar_width
  call s:resume_context(context)

  " Prepare for viewport
  let braille_height = shrinkmap#canvas#braille_height()
  let view_width     = winwidth(sm_win)
  let view_height    = winheight(sm_win)
  let display_top    = line('w0')
  let display_bottom = line('w$')
  let bottom         = line('$')

  " Get source lines
  let src_center             = (display_top + display_bottom) / 2
  let src_lines_of_half_view = view_height * braille_height / 2
  let src_top                = src_center - src_lines_of_half_view
  let src_bottom             = src_center + src_lines_of_half_view
  if src_top < 1
    let src_top    = 1
    let src_bottom = min([view_height * braille_height, bottom])
  elseif src_bottom > bottom
    let src_top    = max([bottom - view_height * braille_height, 1])
    let src_bottom = bottom
  endif

  " Get previous source lines
  let sm_buf           = shrinkmap#buf()
  let prev_src_top     = getbufvar(sm_buf, 'src_top')
  let prev_src_bottom  = getbufvar(sm_buf, 'src_bottom')
  let prev_view_height = getbufvar(sm_buf, 'view_height')
  let prev_view_width  = getbufvar(sm_buf, 'view_width')

  " Set new source lines
  call setbufvar(sm_buf, 'src_top',     src_top)
  call setbufvar(sm_buf, 'src_bottom',  src_bottom)
  call setbufvar(sm_buf, 'view_height', view_height)
  call setbufvar(sm_buf, 'view_width',  view_width)

  " Set source buffer number
  call setbufvar(sm_buf, 'src_buf', context.src_buf)

  " Scrolled or not
  let scrolled = (src_top != prev_src_top || src_bottom != prev_src_bottom)

  " Resized or not
  let resized  = (view_height != prev_view_height || view_width != prev_view_width)

  " Get highlight lines
  let hilite_top     = max([(display_top    - src_top + 1) / braille_height, 1])
  let hilite_bottom  = min([(display_bottom - src_top + 1) / braille_height, view_height])


  call shrinkmap#debug(1,
    \ 'shrinkmap#viewport#update()'            .
    \ ': force = '           . a:force         .
    \ ', view_width = '      . view_width      .
    \ ', view_height = '     . view_height     .
    \ ', display_top = '     . display_top     .
    \ ', display_bottom = '  . display_bottom  .
    \ ', src_top = '         . src_top         .
    \ ', src_bottom = '      . src_bottom      .
    \ ', prev_src_top = '    . prev_src_top    .
    \ ', prev_src_bottom = ' . prev_src_bottom .
    \ ', scrolled = '        . scrolled        .
    \ ', hilite_top = '      . hilite_top      .
    \ ', hilite_bottom = '   . hilite_bottom
  \)

  " Init canvas
  let canvas = shrinkmap#canvas#init()

  if a:force || scrolled || resized
    call s:draw_canvas(canvas, src_top, src_bottom, view_width)
  endif

  " Move to shrinkmap window and buffer
  execute sm_win 'wincmd w'
  execute 'buffer ' shrinkmap#buf()

  if a:force || scrolled || resized
    " Start edit
    setlocal noreadonly modifiable

    " Delete shrinkmap buffer
    silent %delete _

    " Put canvas to shrinkmap buffer
    call append(0, shrinkmap#canvas#get_frame(canvas, view_width))

    " End edit
    setlocal readonly nomodifiable
  endif

  " Highlight
  execute 'match ' . g:shrinkmap_highlight_name . ' /' .
    \ '\%>' . (hilite_top    - 1) . 'l' .
    \ '\%<' . (hilite_bottom + 1) . 'l' .
  \'./'

  " Move calet to topleft
  normal! gg0

  " Resume context
  call s:resume_context(context)
endfunction "}}}


function! s:get_context() "{{{
  let context = {}

  " Get mode
  let context.mode = mode()

  " Get current window
  let context.cur_win = winnr()

  " Get source buffer
  let context.src_buf = bufnr('%')

  return context
endfunction "}}}


function! s:draw_canvas(canvas, src_top, src_bottom, view_width) "{{{
  let x_max_dot = a:view_width * shrinkmap#canvas#braille_width() - 1
  let y_dot = 0
  let i = a:src_top
  while i <= a:src_bottom
    let indent_len = indent(i)
    let line_len   = strdisplaywidth(getline(i))
    let x_dot_start = min([indent_len     / g:shrinkmap_horizontal_shrink, x_max_dot])
    let x_dot_end   = min([(line_len - 1) / g:shrinkmap_horizontal_shrink, x_max_dot])

    if g:shrinkmap_debug >= 2
      call shrinkmap#debug(2,
        \ 'shrinkmap#viewport.draw_canvas()' .
        \ ': y_dot = '       . y_dot         .
        \ ', indent_len = '  . indent_len    .
        \ ', line_len = '    . line_len      .
        \ ', x_max_dot = '   . x_max_dot     .
        \ ', x_dot_start = ' . x_dot_start   .
        \ ', x_dot_end = '   . x_dot_end
      \)
    endif

    if indent_len < line_len
      call shrinkmap#canvas#allocate(a:canvas, y_dot, x_dot_end)
      call shrinkmap#canvas#draw_line(a:canvas, y_dot, x_dot_start, x_dot_end)
    endif

    let i += 1
    let y_dot += 1
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
  if !shrinkmap#is_current_buffer_target()
    return
  endif

  let src_top = getbufvar(shrinkmap#buf(), 'src_top')
  if src_top !=# ''
    " Get new source top line
    let src_jump = (a:mouse_line - 1) * shrinkmap#canvas#braille_height()
    let new_src_top = src_top + src_jump

    call shrinkmap#debug(1,
      \ 'shrinkmap#viewport#jump()' .
      \ ': mouse_line = '  . a:mouse_line .
      \ ', src_top = '     . src_top      .
      \ ', src_jump = '    . src_jump     .
      \ ', new_src_top = ' . new_src_top
    \)

    " Jump to mouse clicked
    execute 'normal! ' . new_src_top . 'gg0'
  endif
endfunction " }}}


let &cpo = s:save_cpo
unlet s:save_cpo

