let s:braille_zero = 0x2800
let s:braille_pixel_map = [
\  [ 0x01, 0x08 ],
\  [ 0x02, 0x10 ],
\  [ 0x04, 0x20 ],
\  [ 0x40, 0x80 ],
\]
let s:braille_height = len(s:braille_pixel_map)
let s:braille_width  = len(s:braille_pixel_map[0])


function! shrinkmap#canvas#init() "{{{
  return []
endfunction "}}}


function! shrinkmap#canvas#braille_height() "{{{
  return s:braille_height
endfunction " }}}


function! shrinkmap#canvas#braille_width() "{{{
  return s:braille_width
endfunction " }}}


function! shrinkmap#canvas#allocate(canvas, y, x, width) "{{{
  let l:y_canvas = len(a:canvas)
  let l:y_char   = a:y / s:braille_height
  let l:x_char   = min([a:x / s:braille_width, a:width])

  call shrinkmap#debug(2, 'camvas#allocate()' .
    \': y_canvas = ' . l:y_canvas             .
    \', y_char = '   . l:y_char               .
    \', x_char = '   . l:x_char
  \)

  if l:y_char < l:y_canvas
    call shrinkmap#debug(1, 'camvas#allocate(): y_char has already allocated')
    let l:i = len(a:canvas[l:y_char])
    while l:i <= l:x_char
      call shrinkmap#debug(2, 'camvas#allocate(): x_char is allocated but short: i = '. l:i)
      call add(a:canvas[l:y_char], s:braille_zero)
      let l:i += 1
    endwhile
  else
    call shrinkmap#debug(1, 'camvas#allocate(): y_char has not allocated yet')

    let l:i = l:y_canvas
    while l:i < l:y_char
      call shrinkmap#debug(0, 'camvas#allocate(): Internal error: Allocate blank until y_char')
      call add(a:canvas, [])
      let l:i += 1
    endwhile

    call shrinkmap#debug(1, 'camvas#allocate(): Allocate x_char on y_char')
    let l:row = []
    let l:i = 0
    while l:i <= l:x_char
      call shrinkmap#debug(2, 'camvas#allocate(): Allocate x_char: i = ' . l:i)
      call add(l:row, s:braille_zero)
      let l:i += 1
    endwhile
    call add(a:canvas, l:row)
  end

  return a:canvas
endfunction "}}}


function! shrinkmap#canvas#draw_line(canvas, y, x1, x2, width) "{{{
  let l:y_char = a:y / s:braille_height
  let l:y_mod  = a:y % s:braille_height
  let l:x_dot1 = min([a:x1, a:width * s:braille_width])
  let l:x_dot2 = min([a:x2, a:width * s:braille_width])
  call shrinkmap#debug(2,
  \ 'shrinkmap#canvas#draw_line()'            .
  \ ': y_canvas = ' . len(a:canvas)           .
  \ ', x_canvas = ' . len(a:canvas[l:y_char]) .
  \ ', y  = '       . a:y                     .
  \ ', x1 = '       . a:x1                    .
  \ ', x2 = '       . a:x2                    .
  \ ', x_dot1 = '   . l:x_dot1                .
  \ ', x_dot2 = '   . l:x_dot2
  \)

  let l:x_dot = l:x_dot1
  while l:x_dot <= l:x_dot2
    let l:x_char = l:x_dot / s:braille_width
    let l:x_mod  = l:x_dot % s:braille_width

    call shrinkmap#debug(2,
    \ 'shrinkmap#canvas#draw_line()' .
    \ ': x_dot = '  . l:x_dot        .
    \ ', y_char = ' . l:y_char       .
    \ ', x_char = ' . l:x_char       .
    \ ', y_mod = '  . l:y_mod        .
    \ ', x_mod = '  . l:x_mod
    \)

    let a:canvas[l:y_char][l:x_char] += s:braille_pixel_map[l:y_mod][l:x_mod]

    let l:x_dot += 1
  endwhile
endfunction "}}}


function! shrinkmap#canvas#get_frame(canvas, fixed_width) "{{{
  let l:lines = []

  for l:canvas_row in a:canvas
    let l:line = ''

    for l:char_code in l:canvas_row
      let l:line .= nr2char(l:char_code, 1)
    endfor

    let l:i = len(l:canvas_row)
    let l:n = a:fixed_width
    while l:i <= l:n
      let l:line .= ' '
      let l:i += 1
    endwhile

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

