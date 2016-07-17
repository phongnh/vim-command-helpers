" command_helpers.vim
" Maintainer: Phong Nguyen
" Version:    0.2.2

if exists('g:loaded_vim_command_helpers')
    finish
endif
let g:loaded_vim_command_helpers = 1

" Copy yanked text to clipboard
command! CopyYankedText let [@+, @*] = [@", @"]

" Grep
command! -bar -nargs=+ -complete=file Grep silent! grep! <args> | cwindow | redraw!

if executable('ag')
    " https://github.com/ggreer/the_silver_searcher
    let &grepprg = 'ag --vimgrep --smart-case --ignore ''.hg'' --ignore ''.svn'' --ignore ''.git'' --ignore ''.bzr'''
elseif executable('pt')
    " https://github.com/monochromegane/the_platinum_searcher
    let &grepprg = 'pt --nogroup --nocolor --smart-case'
elseif executable('sift')
    " https://github.com/svent/sift
    let &grepprg = 'sift --no-color --no-group --binary-skip --git -n -i $*'
endif
set grepformat=%f:%l:%c:%m,%f:%l:%m

let s:is_windows = has('win16') || has('win32') || has('win64') || has('win32unix')

" Gitk
if executable('gitk')
    command! -nargs=? -complete=custom,<SID>ListGitBranches Gitk call <SID>Gitk(<q-args>)

    let s:gitk_cmd = 'silent! !gitk %s'

    if !s:is_windows
        let s:gitk_cmd .= ' &'
    endif

    function! s:Gitk(options) abort
        if s:InGitRepo()
            call s:RunGitk(a:options)
        endif
    endfunction

    function! s:InGitRepo() abort
        let git = finddir('.git', getcwd() . ';')
        return strlen(git)
    endfunction

    function! s:RunGitk(options) abort
        execute printf(s:gitk_cmd, a:options)
        redraw!
    endfunction

    function! s:ListGitBranches(A, L, P) abort
        if s:InGitRepo() && executable('git')
            let output = system("git branch -a | cut -c 3-")
            let output = substitute(output, '\s->\s[0-9a-zA-Z_\-]\+/[0-9a-zA-Z_\-]\+', '', 'g')
            let output = substitute(output, 'remotes/', '', 'g')
            return output
        else
            return ''
        endif
    endfunction

    command! -nargs=? -complete=file GitkFile call <SID>GitkFile(<q-args>)

    function! s:GitkFile(path) abort
        if s:InGitRepo()
            let path = a:path
            if empty(path)
                let path = expand("%")
            endif
            if strlen(path)
                call s:RunGitk(shellescape(path))
            endif
        endif
    endfunction
endif

if s:is_windows
    finish
endif

" Tig
if executable('tig')
    if has('nvim')
        command! -bar -nargs=* -complete=dir -complete=file Tig tabnew | call termopen("tig <args>") | startinsert
        augroup VimCommandHelpersTig
            autocmd!
            autocmd TermClose term://*tig* tabclose
        augroup END
    elseif !has('gui_running')
        command! -nargs=* -complete=dir -complete=file Tig !tig <args>
    endif
endif

" Sudo write
command! -bang SW w<bang> !sudo tee >/dev/null %

" Clear terminal console
command! -bar Cls execute 'silent! !clear' | redraw!
