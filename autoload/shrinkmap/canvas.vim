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
  let l:ay = len(a:canvas)
  let l:py = a:y / s:braille_height
  let l:px = min([a:x / g:shrinkmap_horizontal_shrink / s:braille_width, a:width * g:shrinkmap_horizontal_shrink])

  call shrinkmap#debug(2, 'camvas#allocate()' .
    \': ay = ' . l:ay .
    \', py = ' . l:py .
    \', px = ' . l:px
  \)

  if l:py < l:ay
    call shrinkmap#debug(1, 'camvas#allocate(): py has already allocated')
    let l:cur_len = len(a:canvas[l:py])
    let l:i = l:cur_len
    while l:i <= l:px
      call shrinkmap#debug(2, 'camvas#allocate(): px is allocated but short: i = '. l:i)
      call add(a:canvas[l:py], s:braille_zero)
      let l:i += 1
    endwhile
  else
    call shrinkmap#debug(1, 'camvas#allocate(): py has not allocated yet')

    let l:i = l:ay
    while l:i <= l:py - 1
      call shrinkmap#debug(1, 'camvas#allocate(): Allocate blank until py')
      call add(a:canvas, [])
      let l:i += 1
    endwhile

    call shrinkmap#debug(1, 'camvas#allocate(): Allocate px on py')
    let l:row = []
    let l:i = 0
    while l:i <= l:px
      call shrinkmap#debug(2, 'camvas#allocate(): Allocate px: i = ' . l:i)
      call add(l:row, s:braille_zero)
      let l:i += 1
    endwhile
    call add(a:canvas, l:row)
  end

  return a:canvas
endfunction "}}}


function! shrinkmap#canvas#draw_line(canvas, y, x1, x2, width) "{{{
  let l:py    = a:y / s:braille_height
  let l:y_mod = a:y % s:braille_height
  let l:x1    = min([a:x1 / g:shrinkmap_horizontal_shrink, a:width * g:shrinkmap_horizontal_shrink])
  let l:x2    = min([a:x2 / g:shrinkmap_horizontal_shrink, a:width * g:shrinkmap_horizontal_shrink])

  call shrinkmap#debug(2,
  \ 'shrinkmap#canvas#draw_line()' .
  \ ': y_len = ' . len(a:canvas) .
  \ ', x_len = ' . len(a:canvas[l:py])
  \)

  let l:x = l:x1
  while l:x < l:x2
    let l:px    = l:x / s:braille_width
    let l:x_mod = l:x % s:braille_width

    call shrinkmap#debug(2,
    \ 'shrinkmap#canvas#draw_line()' .
    \ ': y = '     . a:y     .
    \ ', x = '     . l:x     .
    \ ', py = '    . l:py    .
    \ ', px = '    . l:px    .
    \ ', y_mod = ' . l:y_mod .
    \ ', x_mod = ' . l:x_mod
    \)

    let a:canvas[l:py][l:px] += s:braille_pixel_map[l:y_mod][l:x_mod]

    let l:x += 1
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

