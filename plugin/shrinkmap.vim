if exists('g:loaded_shrinkmap')
  finish
end

let s:save_cpo = &cpo
set cpo&vim


if !exists('g:shrinkmap_sidebar_width')
  let g:shrinkmap_sidebar_width = 25 "Braille characters
  " A Braille character has 2 dots in width
endif

if !exists('g:shrinkmap_horizontal_shrink')
  let g:shrinkmap_horizontal_shrink = 2 "characters drawn as a Braille dot
  " A large number contributes drawing speed but loses expression.
endif

if !exists('g:shrinkmap_lazy_limit_time')
  let g:shrinkmap_lazy_limit_time  = 0.25 "sec
endif

if !exists('g:shrinkmap_lazy_limit_count')
  let g:shrinkmap_lazy_limit_count = 8 "times
  " Suitable value is multiplied by g:shrinkmap_horizontal_shrink.
endif

if !exists('g:shrinkmap_highlight_name')
  let g:shrinkmap_highlight_name = 'CursorLine'
  "let g:shrinkmap_highlight_name = 'Visual'
endif

if !exists('g:shrinkmap_debug')
  let g:shrinkmap_debug = 0
endif


command! ShrinkMapToggle call shrinkmap#toggle()
command! ShrinkMapOpen   call shrinkmap#open()
command! ShrinkMapClose  call shrinkmap#close()
command! ShrinkMapUpdate call shrinkmap#viewport#update()

nnoremap <silent> <Leader>ss :<C-U>ShrinkMapToggle<CR>
nnoremap <silent> <Leader>so :<C-U>ShrinkMapOpen<CR>
nnoremap <silent> <Leader>sc :<C-U>ShrinkMapClose<CR>
nnoremap <silent> <Leader>su :<C-U>ShrinkMapUpdate<CR>


let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_shrinkmap = 1

