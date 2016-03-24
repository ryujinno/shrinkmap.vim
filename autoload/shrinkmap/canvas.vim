let s:save_cpo = &cpo
set cpo&vim


let s:braille_zero = 0x2800
let s:braille_pixel_map_single = [
  \ [ 0x01, 0x08 ],
  \ [ 0x02, 0x10 ],
  \ [ 0x04, 0x20 ],
  \ [ 0x40, 0x80 ],
\]
let s:braille_pixel_map_double = [
  \ 0x09,
  \ 0x12,
  \ 0x24,
  \ 0xc0,
\]
let s:braille_height = len(s:braille_pixel_map_single)
let s:braille_width  = len(s:braille_pixel_map_single[0])


function! shrinkmap#canvas#init() "{{{
  return []
endfunction "}}}


function! shrinkmap#canvas#braille_height() "{{{
  return s:braille_height
endfunction " }}}


function! shrinkmap#canvas#braille_width() "{{{
  return s:braille_width
endfunction " }}}


function! shrinkmap#canvas#allocate(canvas, y_dot, x_dot) "{{{
  let y_char = a:y_dot / s:braille_height
  let x_char = a:x_dot / s:braille_width

  if g:shrinkmap_debug >= 2
    call shrinkmap#debug(2,
      \ 'shrinkmap#canvas#allocate()' .
      \ ': y_dot = '  . a:y_dot       .
      \ ', x_dot = '  . a:x_dot       .
      \ ': y_char = ' . y_char        .
      \ ', x_char = ' . x_char
    \)
  endif

  " Allocate y
  let y = len(a:canvas)
  while y <= y_char
    call add(a:canvas, [])
    let y += 1
  endwhile

  " Allocate x
  let canvas_row = a:canvas[y_char]
  let i = len(canvas_row)
  while i <= x_char
    call add(canvas_row, s:braille_zero)
    let i += 1
  endwhile

endfunction "}}}

function! shrinkmap#canvas#draw_line(canvas, y_dot, x_dot_start, x_dot_end) "{{{
  let y_char     = a:y_dot / s:braille_height
  let y_mod      = a:y_dot % s:braille_height
  let canvas_row = a:canvas[y_char]

  if g:shrinkmap_debug >= 2
    call shrinkmap#debug(2,
      \ 'shrinkmap#canvas#draw_line()'       .
      \ ': y_canvas = '    . len(a:canvas)   .
      \ ', x_canvas = '    . len(canvas_row) .
      \ ', x_dot_start = ' . a:x_dot_start   .
      \ ', x_dot_end = '   . a:x_dot_end
    \)
  endif

  " Single at start
  let x_mod  = a:x_dot_start % s:braille_width
  let x_char = a:x_dot_start / s:braille_width
  if x_mod == 1
    let canvas_row[x_char] += s:braille_pixel_map_single[y_mod][x_mod]
    if g:shrinkmap_debug >= 2
      call shrinkmap#debug(2,
        \ 'shrinkmap#canvas#draw_line()' .
        \ ': y_char = ' . y_char         .
        \ ', x_char = ' . x_char         .
        \ ', y_mod = '  . y_mod          .
        \ ', x_mod = '  . x_mod          .
        \ ', char = '   . printf('0x%04x', canvas_row[x_char])
      \)
    endif
    let x_char += 1
  end

  " Double in middle
  let x_char_end = (a:x_dot_end + 1) / s:braille_width
  while x_char < x_char_end
    let canvas_row[x_char] += s:braille_pixel_map_double[y_mod]

    if g:shrinkmap_debug >= 2
      call shrinkmap#debug(2,
        \ 'shrinkmap#canvas#draw_line()' .
        \ ': y_char = ' . y_char         .
        \ ', x_char = ' . x_char         .
        \ ', y_mod = '  . y_mod          .
        \ ', x_mod = 2' .
        \ ', char = '   . printf('0x%04x', canvas_row[x_char])
      \)
    endif

    let x_char += 1
  endwhile

  " Single at end
  let x_mod = a:x_dot_end % s:braille_width
  if x_mod == 0
    let canvas_row[x_char] += s:braille_pixel_map_single[y_mod][x_mod]
    if g:shrinkmap_debug >= 2
      call shrinkmap#debug(2,
        \ 'shrinkmap#canvas#draw_line()' .
        \ ': y_char = ' . y_char         .
        \ ', x_char = ' . x_char         .
        \ ', y_mod = '  . y_mod          .
        \ ', x_mod = '  . x_mod          .
        \ ', char = '   . printf('0x%04x', canvas_row[x_char])
      \)
    endif
  end
endfunction "}}}


function! shrinkmap#canvas#get_frame(canvas, fixed_width) "{{{
  let lines = []

  for canvas_row in a:canvas
    let line = ''

    for char_code in canvas_row
      let line .= nr2char(char_code, 1)
    endfor

    let pad = a:fixed_width - len(canvas_row)
    let line .= printf('%' . pad . 's', '')

    call add(lines, line)
  endfor

  return lines
endfunction "}}}


function! shrinkmap#canvas#get_string(canvas_row) "{{{
  let line = ''

  for char_code in a:canvas_row
    let line .= nr2char(char_code, 1)
  endfor

  return line
endfunction "}}}


let &cpo = s:save_cpo
unlet s:save_cpo

