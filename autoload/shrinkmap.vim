let s:window_width     = 20 "chars
let s:lazy_limit_time  = 0.25 "sec
let s:lazy_limit_count = 15 "times: should be a odd number to avoid from s:on_cursor_moved()

let s:buf_name         = 'shrinkmap'
let s:reltime          = 0
let s:lazy_count       = 0

let s:debug = 1


function! shrinkmap#toggle() "{{{
  if bufwinnr(s:buf_name) < 0
    call shrinkmap#open()
  else
    call shrinkmap#close()
  endif
endfunction "}}}


function! shrinkmap#open() "{{{
  " Check shrinkmap window
  if bufwinnr(s:buf_name) > 0
    return
  endif


  " Get current window
  let l:cur_win = winnr()

  " Open window
  execute 'botright ' . s:window_width . ' vnew ' . s:buf_name

  call s:set()

  " Resume window
  execute l:cur_win . 'wincmd w'

  " Update shrinkmap
  let s:delay_count = 0
  call shrinkmap#update()
endfunction "}}}


function! s:set() "{{{
  " Temporary buffer
  setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted

  " Simple viewport
  setlocal nonumber norelativenumber nolist nowrap

  " Read only
  setlocal nomodifiable

  augroup shrinkmap_group
    autocmd!
    autocmd WinEnter <buffer>          call s:on_win_enter()
    autocmd BufWinEnter              * call s:on_buf_win_enter()
    autocmd TextChanged,TextChangedI * call s:on_text_changed()
    autocmd CursorMoved,CursorMovedI * call s:on_cursor_moved()
    autocmd InsertEnter,InsertLeave  * call s:on_insert()
    autocmd CursorHold,CursorHoldI   * call s:on_cursor_hold()
  augroup END
endfunction "}}}


function! s:unset() "{{{
  augroup shrinkmap_group
    autocmd!
  augroup END
endfunction "}}}


function! s:on_win_enter() "{{{
  if s:debug
    echom 'on_win_enter'
  endif
  " Check window count
  if winnr('$') == 1
    quit
  endif

  " TODO: FIXME: Drop shrinkmap window forcus

  " TODO: UNDERCONST: Scroll against mouse click
endfunction "}}}


function! s:on_buf_win_enter() "{{{
  if s:debug
    echom 'on_buf_win_enter'
  endif
  call shrinkmap#update()
endfunction "}}}


function! s:on_insert() "{{{
  if s:debug
    echom 'on_insert'
  endif
  call shrinkmap#update()
endfunction "}}}


function! s:on_text_changed() "{{{
  if !s:too_hot()
    if s:debug
      echom 'on_text_changed'
    endif
    call shrinkmap#update()
  endif
endfunction "}}}


function! s:on_cursor_moved() "{{{
  if !s:too_hot()
    if s:debug
      echom 'on_cursor_moved'
    endif
    call shrinkmap#update()
  endif
endfunction "}}}


function! s:on_cursor_hold() "{{{
  if s:debug
    echom 'on_cursor_hold'
  endif
  call shrinkmap#update()
endfunction "}}}


function! s:too_hot() "{{{
  let l:reltime = str2float(reltimestr(reltime()))

  if l:reltime - s:reltime > s:lazy_limit_time || s:lazy_count > s:lazy_limit_count
    let l:too_hot = 0
    let s:lazy_count = 0
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
    \l:bufname =~ '^NERDTree'
    return
  endif

  " Check shrinkmap window
  let l:sm_win = bufwinnr(s:buf_name)
  if l:sm_win < 0
    return
  endif

  " Get context
  let l:context = s:get_context()

  " Prepare for viewport
  let l:braille_height = canvas#braille_height()
  let l:view_height = winheight(bufwinnr(s:buf_name))

  " Get source lines
  let l:src_center  = (line('w0') + line('w$')) / 2
  let l:src_top     = l:src_center - l:view_height / 2 * l:braille_height
  let l:src_bottom  = l:src_center + l:view_height / 2 * l:braille_height
  let l:bottom      = line('$')
  if l:src_top < 0
    let l:src_top    = 0
    let l:src_bottom = min([l:view_height * l:braille_height, l:bottom])
  elseif l:src_bottom > l:bottom
    let l:src_top    = max([l:bottom - l:view_height * l:braille_height, 0])
    let l:src_bottom = l:bottom
  endif

  " Get highlight lines
  let l:hilite_top     = max([(line('w0') - l:src_top) / l:braille_height, 0])
  let l:hilite_bottom  = min([(line('w$') - l:src_top) / l:braille_height, l:view_height])
  if s:debug
    echom 'update(): src_top = ' . l:src_top . ', src_bottom = ' . l:src_bottom . ',
      \ hilite_top = ' . l:hilite_top . ', hilite_bottom = ' . l:hilite_bottom
  endif

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
      "if s:debug
      "  echom 'draw(): y = ' . l:y . ', x2 = ' . l:x2 . ', x1 = ' . l:x1
      "endif
      call canvas#allocate(l:canvas, l:x2, l:y, s:window_width)
      call canvas#horizontal_line(l:canvas, l:y, l:x1, l:x2, s:window_width)
    endif

    let l:y += 1
  endfor

  " Move to shrinkmap window and buffer
  execute l:sm_win . 'wincmd w'
  execute 'buffer ' . bufnr(s:buf_name)

  " Start modify
  setlocal modifiable

  " Delete shrinkmap buffer
  %delete _

  " Put canvas to shrinkmap buffer
  call append(0, canvas#get_frame(l:canvas, s:window_width))

  " Highlight
  execute 'match CursorLine /\%>' . l:hilite_top . 'l\%<' . l:hilite_bottom . 'l./'

  " Scroll
  normal! gg

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
  execute a:context.cur_win . 'wincmd w'

  " Resume visual mode
  if a:context.mode ==# 'v' || a:context.mode ==# 'V' || a:context.mode ==# "\026"
    normal! gv
  endif
endfunction "}}}


function! shrinkmap#close() "{{{
  " Check shrinkmap window
  if bufwinnr(s:buf_name) < 0
    return
  endif

  " Get current and shrinkmap window
  let l:cur_win = winnr()
  let l:sm_win  = bufwinnr(s:buf_name)

  " Move to shrinkmap window
  execute l:sm_win . 'wincmd w'

  close

  call s:unset()

  " Resume window
  if l:cur_win != l:sm_win
    execute l:cur_win . 'wincmd w'
  endif
endfunction "}}}

