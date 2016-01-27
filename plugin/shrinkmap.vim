if exists('g:loaded_shrinkmap')
  finish
end

let s:save_cpo = &cpo
set cpo&vim

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

