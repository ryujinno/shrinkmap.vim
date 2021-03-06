if exists('g:loaded_shrinkmap')
  finish
end

let s:save_cpo = &cpo
set cpo&vim


if !exists('g:shrinkmap_sidebar_align')
  " Alignment of sidebar window: "right", "left"
  " Sidebar window applies for this value when open.
  let g:shrinkmap_sidebar_align = 'right'
endif

if !exists('g:shrinkmap_sidebar_width')
  " Sidebar window width, which is max number of Braille characters in a line.
  " A Braille character has 2 dots in a width.
  " Sidebar window applies for this value when open and update.
  let g:shrinkmap_sidebar_width = 25 "Braille characters
endif

if !exists('g:shrinkmap_horizontal_shrink')
  " Characters drawn as a Braille dot.
  " A large number contributes drawing speed but loses expression.
  " ShrinkMap applies for this value when update.
  let g:shrinkmap_horizontal_shrink = 2 "characters in a Braille dot
endif

if !exists('g:shrinkmap_highlight_name')
  " Name of higilighting the current window in ShrinkMap sidebar.
  " "CursorLine", "Visual" and so on. Refer to :highlight command.
  " ShrinkMap applies for this value when update.
  let g:shrinkmap_highlight_name = 'CursorLine'
endif

if !exists('g:shrinkmap_lazy_draw_interval')
  " Interval seconds for lazy drawing. This interval should not be set 0.
  let g:shrinkmap_lazy_draw_interval  = 0.25 "second
endif

if !exists('g:shrinkmap_debug')
  let g:shrinkmap_debug = 0
endif


command! ShrinkMapToggle call shrinkmap#sidebar#toggle()
command! ShrinkMapOpen   call shrinkmap#sidebar#open()
command! ShrinkMapClose  call shrinkmap#sidebar#close()
command! ShrinkMapUpdate call shrinkmap#viewport#update()


nnoremap <silent> <Leader>ss :<C-U>ShrinkMapToggle<CR>
nnoremap <silent> <Leader>so :<C-U>ShrinkMapOpen<CR>
nnoremap <silent> <Leader>sc :<C-U>ShrinkMapClose<CR>
nnoremap <silent> <Leader>su :<C-U>ShrinkMapUpdate<CR>


let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_shrinkmap = 1

