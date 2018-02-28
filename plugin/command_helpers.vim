" command_helpers.vim
" Maintainer: Phong Nguyen
" Version:    0.5.0

if exists('g:loaded_vim_command_helpers')
    finish
endif

" Copy Commands {{{
    if has('clipboard')
        " Copy yanked text to clipboard
        command! CopyYankedText let [@+, @*] = [@", @"]
    endif

    " Copy path to clipboard
    function! s:copy_path_to_clipboard(path)
        let @" = a:path
        if has('clipboard')
            let [@*, @+] = [@", @"]
        endif
        echo 'Copied: ' . @"
    endfunction

    function! s:copy_path(path, line)
        let path = expand(a:path)
        if a:line
            let path .= ':' . line('.')
        endif
        call s:copy_path_to_clipboard(path)
    endfunction

    command! -bang CopyRelativePath call <SID>copy_path('%', <bang>0)
    command! -bang CopyFullPath     call <SID>copy_path('%:p', <bang>0)
    command! -bang CopyParentPath   call <SID>copy_path(<bang>0 ? '%:p:h' : '%:h', 0)

    if get(g:, 'copypath_mappings', 1)
        nnoremap <silent> yp :CopyRelativePath<CR>
        nnoremap <silent> yP :CopyRelativePath!<CR>
        nnoremap <silent> yu :CopyFullPath<CR>
        nnoremap <silent> yU :CopyFullPath!<CR>
        nnoremap <silent> yd :CopyParentPath<CR>
        nnoremap <silent> yD :CopyParentPath!<CR>
    endif
" }}}

" Highlight commands {{{
    " Highlight current line
    command! HighlightLine call matchadd('Search', '\%' . line('.') . 'l')

    " Highlight the word underneath the cursor
    command! HighlightWord call matchadd('Search', '\<\w*\%' . line('.') . 'l\%' . col('.') . 'c\w*\>')

    " Highlight the words contained in the virtual column
    command! HighlightColumns call matchadd('Search', '\<\w*\%' . virtcol('.') . 'v\w*\>')

    " Clear the permanent highlights
    command! ClearHightlights call clearmatches()

    if get(g:, 'highlight_mappings', 1)
        nnoremap <silent> <Leader>hl :HighlightLine<CR>
        nnoremap <silent> <Leader>hw :HighlightWord<CR>
        nnoremap <silent> <Leader>hv :HighlightColumns<CR>
        nnoremap <silent> <Leader>hc :ClearHightlights<CR>
    endif
" }}}

" Grep
command! -bar -nargs=+ -complete=file Grep silent! grep! <args> | cwindow | redraw!

let s:default_vcs_ignore = '--ignore ''.git'' --ignore ''.hg'' --ignore ''.svn'' --ignore ''.bzr'''
if executable('rg')
    " https://github.com/BurntSushi/ripgrep
    let &grepprg = 'rg --hidden --vimgrep --smart-case'
elseif executable('ag')
    " https://github.com/ggreer/the_silver_searcher
    let &grepprg = 'ag --hidden --vimgrep --smart-case' . s:default_vcs_ignore
elseif executable('pt')
    " https://github.com/monochromegane/the_platinum_searcher
    let &grepprg = 'pt --nocolor --hidden --nogroup --column --smart-case' . s:default_vcs_ignore
endif
set grepformat=%f:%l:%c:%m,%f:%l:%m

let s:is_windows = has('win64') || has('win32') || has('win32unix') || has('win16')

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

function! s:BuildPath(path)
    return empty(a:path) ? expand("%") : a:path
endfunction

let s:has_uniq = executable('uniq')
function! s:GitFullHistoryCommand(path)
    let cmd = 'git log --name-only --format= --follow %s'
    if s:has_uniq
        let cmd .= ' | uniq'
    endif
    let cmd = '$(' . cmd . ')'
    return printf(cmd, shellescape(a:path))
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

    function! s:GitkFile(path, bang) abort
        if s:InGitRepo()
            let path = s:BuildPath(a:path)
            if empty(path)
                return
            endif

            if a:bang
                call s:RunGitk('-- ' . s:GitFullHistoryCommand(path))
            else
                call s:RunGitk(shellescape(path))
            endif
        endif
    endfunction

    command! -nargs=? -complete=custom,<SID>ListGitBranches Gitk call <SID>Gitk(<q-args>)
    command! -nargs=? -bang -complete=file GitkFile call <SID>GitkFile(<q-args>, <bang>0)
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

    function! s:TigFile(path, bang) abort
        if s:InGitRepo()
            let path = s:BuildPath(a:path)
            if empty(path)
                return
            endif
            if a:bang
                call s:RunTig('-- ' . s:GitFullHistoryCommand(path))
            else
                call s:RunTig(shellescape(path))
            endif
        endif
    endfunction

    command! -nargs=? -complete=custom,<SID>ListGitBranches Tig call <SID>Tig(<q-args>)
    command! -nargs=? -bang -complete=file TigFile call <SID>TigFile(<q-args>, <bang>0)
endif

" Sudo write
command! -bang SW w<bang> !sudo tee >/dev/null %

" Clear terminal console
command! -bar Cls execute 'silent! !clear' | redraw!

let g:loaded_vim_command_helpers = 1
