if exists('g:loaded_shrinkmap')
  finish
end

let s:save_cpo = &cpo
set cpo&vim


if !exists('g:shrinkmap_window_width')
  let g:shrinkmap_window_width = 20 "chars
endif

if !exists('g:shrinkmap_lazy_limit_time')
  let g:shrinkmap_lazy_limit_time  = 0.25 "sec
endif

if !exists('g:shrinkmap_lazy_limit_count')
  let g:shrinkmap_lazy_limit_count = 8 "times: Suitable value is multiplied by 4
endif

if !exists('g:shrinkmap_debug')
  let g:shrinkmap_debug = 2
endif


command! ShrinkMapToggle call shrinkmap#toggle()
command! ShrinkMapOpen   call shrinkmap#open()
command! ShrinkMapClose  call shrinkmap#close()
command! ShrinkMapUpdate call shrinkmap#update()

nnoremap <silent> <Leader>ss :<C-U>ShrinkMapToggle<CR>
nnoremap <silent> <Leader>so :<C-U>ShrinkMapOpen<CR>
nnoremap <silent> <Leader>sc :<C-U>ShrinkMapClose<CR>
nnoremap <silent> <Leader>su :<C-U>ShrinkMapUpdate<CR>


let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_shrinkmap = 1

