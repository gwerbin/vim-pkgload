if exists("g:loaded_pkgload")
  finish
endif
let g:loaded_pathogen = 1

let s:plugins = {'staged': [], 'loaded': [], 'failed': []}
let g:pkgload_staged_plugins = s:plugins.staged


"'' Query plugin status ''"

function! pkgload#get_available_plugins(use_full_paths) abort
  let l:pkg_paths = globpath(&rtp, 'pack/*/opt/*', 0, 1)
  if ! a:use_full_paths
    let l:pkg_paths = map(l:pkg_paths, {idx, val -> fnamemodify(val, ':p:h:t')})
  endif
  return l:pkg_paths
endfunction

function! pkgload#plugins() abort
  s:plugins
endfunction

function! pkgload#get_staged_plugins() abort
  return s:plugins.staged
endfunction

function! pkgload#get_loaded_plugins() abort
  return s:plugins.loaded
endfunction

function! pkgload#get_failed_plugins() abort
  return s:plugins.failed
endfunction

let s:current_staging = ''
function! pkgload#get_staging() abort
  return s:current_staging
endfunction

let s:current_loading = ''
function! pkgload#get_loading() abort
  return s:current_loading
endfunction


"'' Do plugin things ''"

" Stage a plugin for loading.
function! pkgload#pkg_stage(pkg) abort
  let s:current_staging = a:pkg
  try
    doautocmd <nomodeline> User PkgStagePost
    add(s:plugins.staged, a:pkg)
    doautocmd <nomodeline> User PkgStagePre
  finally
    let s:current_staging = ''
  endtry
endfunction

" Stage a plugin for loading only if other plugins have already been loaded or staged
" This is a convenience method; it makes your startup files shorter and cleaner
function! pkgload#pkg_stage_if(pkg, ...) abort
  if ! utils#issubset(a:000, s:plugins.staged + s:plugins.loaded)
    return
  endif

  add(s:plugins.staged, a:pkg)
endfunction


" Disable filetype and syntax
function! s:ftsyn_unset() abort
  let l:ftcmd = []
  let l:syncmd = 0
  if exists('g:did_indent_on') && g:did_indent_on
    call add(l:ftcmd, 'indent')
  endif
  if exists('g:did_load_ftplugin') && g:did_indent_on
    call add(l:ftcmd, 'plugin')
  endif
  if exists('g:did_load_filetypes') && g:did_indent_on
    call add(l:ftcmd, 'on')
  endif
  if exists('g:syntax_on') && g:syntax_on
    let l:syncmd = 1
  endif

  filetype plugin indent off
  filetype off
  syntax off

  return [l:ftcmd, l:syncmd]
endfunction


" Reinstate filetype and syntax settings
function! s:ftsyn_reset(ftcmd, syncmd) abort
  if len(a:ftcmd) > 0
    execute 'filetype '.join(a:ftcmd, ' ')
  endif
  if a:syncmd
    syntax enable
  endif
endfunction


" Un-stage and load plugins one at a time.
function! pkgload#pkg_collect(force) abort
  let [l:ftcmd, l:syncmd] = s:ftsyn_unset()

  let l:force = a:force || g:pkgload_force_add

  pkgload#utils#unique_inplace(s:plugins.staged)
  
  doautocmd <nomodeline> User PkgCollectPre

  while len(s:plugins.staged)
    doautocmd <nomodeline> User PkgAddPre

    let l:pkg = remove(s:plugins.staged, 0)
    let s:current_loading = l:pkg
    
    try
      let l:failed_ix = index(s:plugins.failed, l:pkg)
      if l:failed_ix > 0
        remove(s:plugins.failed, l:failed_ix)
      endif
  
      call pkgload#pkg_add(l:pkg, l:force, 1)
      doautocmd <nomodeline> User PkgAddPost
    finally
      let s:current_loading = ''
    endtry
  endfor
  
  doautocmd <nomodeline> User PkgCollectPost

  s:ftsyn_reset(l:ftcmd, l:syncmd)
endfunction


" Load a plugin. If in a startup file, use :packadd!, otherwise use :packadd for immediate effect.
" If it succeeds, add it to s:plugins.loaded. If it fails, add it to s:plugins.failed
function! pkgload#pkg_add(pkg, force, bypass_syn) abort
  if ! a:force || ! g:pkgload_force_add || pkgload#utils#isin(a:pkg, s:plugins.loaded) || pkgload#utils#isin(a:pkg, s:plugins.failed)
    return
  endif

  if ! bypass_syn
    let [l:ftcmd, l:syncmd] = s:ftsyn_unset()
  endif

  try
    if v:vim_did_enter
      execute 'packadd '.a:pkg
    else
      execute 'packadd! '.a:pkg
    endif
    call add(s:plugins.loaded, a:pkg)
  catch /^Vim\%((\a\+)\)\=:E919/
    if ! g:pkgload_silent
      echoerr v:exception.' ('.v:throwpoint.')'
    endif
  catch
    if ! g:pkgload_silent
      call echoerr('Plugin '.a:pkg.' failed to load')
    endif
    call add(s:plugins.failed, a:pkg)
  endtry

  if ! bypass_syn
    s:ftsyn_reset(l:ftcmd, l:syncmd)
  endif
endfunction

" vim: set ft=vim sw=2 et:
