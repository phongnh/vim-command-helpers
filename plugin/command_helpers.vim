" command_helpers.vim
" Maintainer: Phong Nguyen
" Version:    0.4.2

if exists('g:loaded_vim_command_helpers')
    finish
endif

" Copy yanked text to clipboard
command! CopyYankedText let [@+, @*] = [@", @"]

" Grep
command! -bar -nargs=+ -complete=file Grep silent! grep! <args> | cwindow | redraw!

if executable('rg')
    " https://github.com/BurntSushi/ripgrep
    let &grepprg = 'rg --hidden -H --no-heading --vimgrep --smart-case'
elseif executable('ag')
    " https://github.com/ggreer/the_silver_searcher
    let &grepprg = 'ag --hidden --vimgrep --smart-case --ignore ''.hg'' --ignore ''.svn'' --ignore ''.git'' --ignore ''.bzr'''
elseif executable('pt')
    " https://github.com/monochromegane/the_platinum_searcher
    let &grepprg = 'pt --nocolor --hidden --nogroup --column --smart-case'
endif
set grepformat=%f:%l:%c:%m,%f:%l:%m

let s:is_windows = has('win16') || has('win32') || has('win64') || has('win32unix')

" Git helpers
function! s:InGitRepo() abort
    let git = finddir('.git', getcwd() . ';')
    return strlen(git)
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

" Gitk
if executable('gitk')
    let s:gitk_cmd = 'silent! !gitk %s'

    if !s:is_windows
        let s:gitk_cmd .= ' &'
    endif

    function! s:RunGitk(options) abort
        execute printf(s:gitk_cmd, a:options)
        redraw!
    endfunction

    function! s:Gitk(options) abort
        if s:InGitRepo()
            call s:RunGitk(a:options)
        endif
    endfunction

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

    command! -nargs=? -complete=custom,<SID>ListGitBranches Gitk call <SID>Gitk(<q-args>)
    command! -nargs=? -complete=file GitkFile call <SID>GitkFile(<q-args>)
endif

if s:is_windows
    finish
endif

" Tig
if executable('tig')
    if has('nvim')
        augroup VimCommandHelpersTig
            autocmd!
            autocmd TermClose term://*tig* tabclose
        augroup END

        function! s:RunTig(options) abort
            let cmd = printf('tig %s', a:options)
            tabnew
            call termopen(cmd)
            startinsert
        endfunction
    elseif !has('gui_running')
        function! s:RunTig(options) abort
            execute printf('silent! !tig %s', a:options)
            redraw!
        endfunction
    else
        function! s:RunTig(options) abort
        endfunction
    endif

    function! s:Tig(options) abort
        if s:InGitRepo()
            call s:RunTig(a:options)
        endif
    endfunction

    function! s:TigFile(path) abort
        if s:InGitRepo()
            let path = a:path
            if empty(path)
                let path = expand("%")
            endif
            if strlen(path)
                call s:RunTig(shellescape(path))
            endif
        endif
    endfunction

    command! -nargs=? -complete=custom,<SID>ListGitBranches Tig call <SID>Tig(<q-args>)
    command! -nargs=? -complete=file TigFile call <SID>TigFile(<q-args>)
endif

" Sudo write
command! -bang SW w<bang> !sudo tee >/dev/null %

" Clear terminal console
command! -bar Cls execute 'silent! !clear' | redraw!

let g:loaded_vim_command_helpers = 1
