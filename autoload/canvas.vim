let s:shrink = 2
let s:braille_char_offset = 0x2800
let s:pixel_map = [
\  [ 0x01, 0x08 ],
\  [ 0x02, 0x10 ],
\  [ 0x04, 0x20 ],
\  [ 0x40, 0x80 ],
\]

let s:braille_height   = len(s:pixel_map)
let s:braille_width    = len(s:pixel_map[0])
let s:braille_char_len = len(nr2char(s:braille_char_offset, 1))

let s:debug = 0


function! canvas#braille_height() "{{{
  return s:braille_height
endfunction " }}}


function! canvas#braille_width() "{{{
  return s:braille_width
endfunction " }}}


function! canvas#get_string(canvas_row) "{{{
  let l:line = ''

  for l:char_code in a:canvas_row
    let l:line .= nr2char(l:char_code, 1)
  endfor

  return l:line
endfunction "}}}


function! canvas#get_frame(canvas, fixed_width) "{{{
  let l:lines = []

  for l:canvas_row in a:canvas
    let l:line = ''

    for l:char_code in l:canvas_row
      let l:line .= nr2char(l:char_code, 1)
    endfor

    let l:i = strlen(l:line) / s:braille_char_len
    while l:i < a:fixed_width
      let l:line .= ' '
      let l:i += 1
    endwhile

    call add(l:lines, l:line)
  endfor

  return l:lines
endfunction "}}}


function! canvas#init() "{{{
  return []
endfunction "}}}


function! canvas#allocate(canvas, x, y, width) "{{{
  let l:px = min([a:x / s:shrink / s:braille_width, a:width * s:shrink])
  let l:py = a:y / s:braille_height
  let l:canvas_len = len(a:canvas)

  if l:py < l:canvas_len
    " py has already allocated
    if s:debug
      echom 'py has already allocated'
    endif
    let l:cur_len = len(a:canvas[l:py])
    let l:i = l:cur_len
    while l:i <= l:px
      " px is allocated but short
      call add(a:canvas[l:py], s:braille_char_offset)
      let l:i += 1
    endwhile
  else
    " py has not allocated yet
    if s:debug
      echom 'py has not allocated yet'
    endif

    let l:i = l:canvas_len
    while l:i <= l:py - 1
      " Allocate blank until py
      if s:debug
        echom 'Allocate blank until py'
      endif
      call add(a:canvas, [])
      let l:i += 1
    endwhile

    " Allocate px on py
    let l:row = []
    let l:i = 0
    while l:i <= l:px
      call add(l:row, s:braille_char_offset)
      let l:i += 1
    endwhile
    call add(a:canvas, l:row)
  end

  return a:canvas
endfunction "}}}


function! canvas#horizontal_line(canvas, y, x1, x2, width) "{{{
  let l:py    = a:y / s:braille_height
  let l:y_mod = a:y % s:braille_height
  let l:x1    = min([a:x1 / s:shrink / s:braille_width, a:width * s:shrink])
  let l:x2    = min([a:x2 / s:shrink / s:braille_width, a:width * s:shrink])

  let l:x = l:x1
  while l:x < l:x2
    let l:px    = l:x / s:braille_width
    let l:x_mod = l:x % s:braille_width

    "if s:debug
    "  echom 'hl(): y = ' . a:y . ', x = ' . l:x . ', py = ' . l:py . ', px =' . l:px
    "endif

    let a:canvas[l:py][l:px] += s:pixel_map[l:y_mod][l:x_mod]

    let l:x += 1
  endwhile
endfunction "}}}


