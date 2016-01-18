" helpers.vim
" Maintainer: Phong Nguyen
" Version:    0.1.0

if exists('g:loaded_vim_helpers')
    finish
endif
let g:loaded_vim_helpers = 1

" Copy yanked text to clipboard
command! CopyYankedText let [@+, @*] = [@", @"]

" Grep
command! -bar -nargs=+ -complete=file Grep silent! grep! <args> | cwindow | redraw!

if executable('ag')
    " https://github.com/ggreer/the_silver_searcher
    let &grepprg = 'ag --vimgrep --smart-case --ignore ''.hg'' --ignore ''.svn'' --ignore ''.git'' --ignore ''.bzr'''
    set grepformat=%f:%l:%c:%m,%f:%l:%m
elseif executable('sift')
    " https://github.com/svent/sift
    let &grepprg = 'sift --no-color --no-group --binary-skip --git -n -i $*'
endif

" Gitk
if executable('gitk')
    command! -bar -nargs=* -complete=dir -complete=file Gitk execute "silent! !gitk <args>" | redraw!
endif

if has('win16') || has('win32') || has('win64') || has('win32unix')
    finish
endif

" Tig
if executable('tig')
    if has('nvim')
        command! -bar -nargs=* -complete=dir -complete=file Tig tabnew | call termopen("tig <args>") | startinsert
        augroup VimHelpersTig
            autocmd!
            autocmd TermClose term://*tig* tabclose
        augroup END
    elseif !has('gui_running')
        command! -nargs=* -complete=dir -complete=file Tig !tig <args>
    endif
endif

" Sudo write
command! -bang SW w<bang> !sudo tee % >/dev/null

" Clear terminal console
command! -bar Cls execute 'silent! !clear' | redraw!
