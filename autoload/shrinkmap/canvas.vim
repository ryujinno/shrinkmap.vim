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
  let l:y_char = a:y_dot / s:braille_height
  let l:x_char = a:x_dot / s:braille_width

  if g:shrinkmap_debug >= 2
    call shrinkmap#debug(2,
      \ 'shrinkmap#canvas#allocate()' .
      \ ': y_dot = '  . a:y_dot       .
      \ ', x_dot = '  . a:x_dot       .
      \ ': y_char = ' . l:y_char      .
      \ ', x_char = ' . l:x_char
    \)
  endif

  " Allocate y
  let l:y = len(a:canvas)
  while l:y <= l:y_char
    call add(a:canvas, [])
    let l:y += 1
  endwhile

  " Allocate x
  let l:canvas_row = a:canvas[l:y_char]
  let l:i = len(l:canvas_row)
  while l:i <= l:x_char
    call add(l:canvas_row, s:braille_zero)
    let l:i += 1
  endwhile

endfunction "}}}

function! shrinkmap#canvas#draw_line(canvas, y_dot, x_dot_start, x_dot_end) "{{{
  let l:y_char     = a:y_dot / s:braille_height
  let l:y_mod      = a:y_dot % s:braille_height
  let l:canvas_row = a:canvas[l:y_char]

  if g:shrinkmap_debug >= 2
    call shrinkmap#debug(2,
      \ 'shrinkmap#canvas#draw_line()'         .
      \ ': y_canvas = '    . len(a:canvas)     .
      \ ', x_canvas = '    . len(l:canvas_row) .
      \ ', x_dot_start = ' . a:x_dot_start     .
      \ ', x_dot_end = '   . a:x_dot_end
    \)
  endif

  " Single at start
  let l:x_mod  = a:x_dot_start % s:braille_width
  let l:x_char = a:x_dot_start / s:braille_width
  if l:x_mod == 1
    let l:canvas_row[l:x_char] += s:braille_pixel_map_single[l:y_mod][l:x_mod]
    if g:shrinkmap_debug >= 2
      call shrinkmap#debug(2,
        \ 'shrinkmap#canvas#draw_line()' .
        \ ': y_char = ' . l:y_char       .
        \ ', x_char = ' . l:x_char       .
        \ ', y_mod = '  . l:y_mod        .
        \ ', x_mod = '  . l:x_mod        .
        \ ', char = '   . printf('0x%04x', l:canvas_row[l:x_char])
      \)
    endif
    let l:x_char += 1
  end

  " Double in middle
  let l:x_char_end = (a:x_dot_end + 1) / s:braille_width
  while l:x_char < l:x_char_end
    let l:canvas_row[l:x_char] += s:braille_pixel_map_double[l:y_mod]

    if g:shrinkmap_debug >= 2
      call shrinkmap#debug(2,
        \ 'shrinkmap#canvas#draw_line()' .
        \ ': y_char = ' . l:y_char       .
        \ ', x_char = ' . l:x_char       .
        \ ', y_mod = '  . l:y_mod        .
        \ ', x_mod = 2' .
        \ ', char = '   . printf('0x%04x', l:canvas_row[l:x_char])
      \)
    endif

    let l:x_char += 1
  endwhile

  " Single at end
  let l:x_mod = a:x_dot_end % s:braille_width
  if l:x_mod == 0
    let l:canvas_row[l:x_char] += s:braille_pixel_map_single[l:y_mod][l:x_mod]
    if g:shrinkmap_debug >= 2
      call shrinkmap#debug(2,
        \ 'shrinkmap#canvas#draw_line()' .
        \ ': y_char = ' . l:y_char       .
        \ ', x_char = ' . l:x_char       .
        \ ', y_mod = '  . l:y_mod        .
        \ ', x_mod = '  . l:x_mod        .
        \ ', char = '   . printf('0x%04x', l:canvas_row[l:x_char])
      \)
    endif
  end
endfunction "}}}


function! shrinkmap#canvas#get_frame(canvas, fixed_width) "{{{
  let l:lines = []

  for l:canvas_row in a:canvas
    let l:line = ''

    for l:char_code in l:canvas_row
      let l:line .= nr2char(l:char_code, 1)
    endfor

    let l:pad = a:fixed_width - len(l:canvas_row)
    let l:line .= printf('%' . l:pad . 's', '')

    call add(l:lines, l:line)
  endfor

  return l:lines
endfunction "}}}


function! shrinkmap#canvas#get_string(canvas_row) "{{{
  let l:line = ''

  for l:char_code in a:canvas_row
    let l:line .= nr2char(l:char_code, 1)
  endfor

  return l:line
endfunction "}}}


let &cpo = s:save_cpo
unlet s:save_cpo

