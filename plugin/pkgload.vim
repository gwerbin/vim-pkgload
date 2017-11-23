if exists("g:loaded_pkgman_plugin")
  finish
endif
let g:loaded_pkgman_plugin = 1

let g:pkgman_force_reload = 0
let g:pkgman_silent = 1

command! -nargs=1 PkgAdd      call pkgman#pkg_stage(<f-args)
command! -nargs=+ PkgAddIf    call pkgman#pkg_stage_if(<f-args>)
command!          PkgCollect  call pkgman#pkg_collect()

command! PkgAvailabke echo join(pkgman#get_available_plugins(0), "\n")
command! PkgLoaded    echo join(pkgman#get_loaded_plugins(), "\n")
command! PkgFailed    echo join(pkgman#get_failed_plugins(), "\n")
