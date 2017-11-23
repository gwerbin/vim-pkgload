" This function is from 'vim-misc'.
" http://peterodding.com/code/vim/misc/
" MIT License, (c) 2013 Peter Odding <peter@peterodding.com>
function! pkgman#utils#unique_inplace(list) " {{{1
  call reverse(a:list)
  call filter(a:list, 'count(a:list, v:val) == 1')
  return reverse(a:list)
endfunction

function! pkgman#utils#isin(x, lst) abort
  return index(a:lst, a:x) >= 0
endfunction 

function! pkgman#utils#issubset(x, lst) abort
  for l:el in pkgmsn#utils#unique_inplace(copy(a:x))
    if ! utils#isin(l:el, a:lst)
      return 0
    endif
  endfor
  return 1
endfunction 
