" Use Vim defaults instead of legacy Vi compatibility.
set nocompatible
set encoding=utf-8
set autoread
set autowriteall
set updatetime=500
set ttimeout
set ttimeoutlen=100
set signcolumn=yes
execute 'set fillchars+=eob:\ '
execute "set <M-e>=\ee"

filetype plugin indent on
syntax enable

augroup language_indentation
  autocmd!
  autocmd FileType c,cpp,python
        \ setlocal expandtab tabstop=4 shiftwidth=4 softtabstop=4
augroup END

" Save ordinary files after an idle pause and prefer external disk changes.
function! s:AutoSaveCurrentBuffer() abort
  if &buftype !=# ''
        \ || !&modifiable
        \ || &readonly
        \ || empty(bufname('%'))
        \ || !&modified
    return
  endif

  silent update
endfunction

augroup automatic_file_sync
  autocmd!
  autocmd FileChangedShell * let v:fcs_choice = 'reload'
  autocmd FocusGained,BufEnter,CursorHold,CursorHoldI * silent checktime
  autocmd CursorHold,CursorHoldI,FocusLost * call <SID>AutoSaveCurrentBuffer()
augroup END

" Format C, C++, and Python buffers on demand with isolated user tools.
let s:formatter_bin_dir = expand('~/.local/share/vim-tools/formatters/bin')
if isdirectory(s:formatter_bin_dir)
  let $PATH = s:formatter_bin_dir . ':' . $PATH
endif

let g:neoformat_enabled_c = ['clangformat']
let g:neoformat_enabled_cpp = ['clangformat']
let g:neoformat_enabled_python = ['black']
let g:neoformat_only_msg_on_error = 1
nnoremap <silent> <leader>f :Neoformat<CR>

" Show line-level Git changes as a narrow colored bar, like LazyVim.
let g:gitgutter_sign_allow_clobber = 0
let g:gitgutter_sign_added = '▎'
let g:gitgutter_sign_modified = '▎'
let g:gitgutter_sign_removed = '▎'
let g:gitgutter_sign_removed_first_line = '▎'
let g:gitgutter_sign_removed_above_and_below = '▎'
let g:gitgutter_sign_modified_removed = '▎'

highlight SignColumn ctermbg=NONE guibg=NONE
highlight GitGutterAdd ctermfg=2 ctermbg=NONE guifg=#9ece6a guibg=NONE
highlight GitGutterChange ctermfg=3 ctermbg=NONE guifg=#e0af68 guibg=NONE
highlight GitGutterDelete ctermfg=1 ctermbg=NONE guifg=#f7768e guibg=NONE
highlight GitGutterChangeDelete ctermfg=3 ctermbg=NONE guifg=#e0af68 guibg=NONE

" Toggle the NERDTree file explorer from Normal mode.
let g:NERDTreeWinSize = 24
let g:NERDTreeGitStatusIndicatorMapCustom = {
      \ 'Modified': 'm',
      \ 'Staged': 's',
      \ 'Untracked': 'u',
      \ 'Renamed': 'r',
      \ 'Unmerged': 'c',
      \ 'Deleted': 'd',
      \ 'Dirty': 'x',
      \ 'Ignored': 'i',
      \ 'Clean': 'k',
      \ 'Unknown': 'q',
      \ }
nnoremap <silent> <C-n> :NERDTreeToggle<CR>

" Color NERDTree file names by Git state and conceal the internal markers.
let s:nerdtree_git_file_colors = [
      \ ['Modified', 'm', 3, '#e0af68'],
      \ ['Staged', 's', 2, '#9ece6a'],
      \ ['Untracked', 'u', 8, '#565f89'],
      \ ['Renamed', 'r', 6, '#7dcfff'],
      \ ['Unmerged', 'c', 1, '#f7768e'],
      \ ['Deleted', 'd', 1, '#f7768e'],
      \ ['Dirty', 'x', 3, '#e0af68'],
      \ ['Ignored', 'i', 8, '#565f89'],
      \ ['Clean', 'k', 2, '#9ece6a'],
      \ ['Unknown', 'q', 8, '#565f89'],
      \ ]

function! s:UseNERDTreeGitFileColors() abort
  let l:delimiter = '\%d' . char2nr(g:NERDTreeNodeDelimiter)

  for l:color in s:nerdtree_git_file_colors
    let l:status = l:color[0]
    let l:marker = l:color[1]
    let l:file_group = 'NERDTreeGitFile' . l:status
    let l:marker_group = 'NERDTreeGitMarker' . l:status

    execute 'silent! syntax region ' . l:file_group
          \ . ' start=#\m\C^.*\[[^]]*' . l:marker . '[^]]*\]'
          \ . l:delimiter . '#hs=e+1 end=#$# oneline keepend'
          \ . ' contains=NERDTreeFlags,NERDTreeOpenable,NERDTreeClosable'
    execute 'silent! syntax match ' . l:marker_group
          \ . ' #\m\C' . l:marker
          \ . '# contained conceal containedin=NERDTreeFlags'
    execute 'highlight ' . l:file_group
          \ . ' cterm=NONE ctermfg=' . l:color[2] . ' ctermbg=NONE'
          \ . ' gui=NONE guifg=' . l:color[3] . ' guibg=NONE'
  endfor

  setlocal conceallevel=3 concealcursor=nvic
endfunction

augroup nerdtree_git_file_colors
  autocmd!
  autocmd FileType nerdtree call <SID>UseNERDTreeGitFileColors()
augroup END

function! s:NERDTreeDirectoryState(node) abort
  let l:path = a:node.path.str()
  try
    let l:entries = sort(readdir(l:path))
  catch
    let l:entries = []
  endtry

  let l:state = [l:path, string(l:entries)]
  for l:child in a:node.children
    if get(l:child.path, 'isDirectory', 0) && get(l:child, 'isOpen', 0)
      call extend(l:state, s:NERDTreeDirectoryState(l:child))
    endif
  endfor
  return l:state
endfunction

function! s:RefreshNERDTreeWindow(window, force) abort
  let l:tree = getbufvar(a:window.bufnr, 'NERDTree', {})
  if empty(l:tree) || !has_key(l:tree, 'root')
    return
  endif

  let l:state = s:NERDTreeDirectoryState(l:tree.root)
  let l:previous_state = getbufvar(
        \ a:window.bufnr, 'nerdtree_directory_state', [])
  if !a:force && l:state ==# l:previous_state
    return
  endif

  call win_execute(a:window.winid,
        \ 'silent call b:NERDTree.root.refresh() | silent call b:NERDTree.render()',
        \ 1)
  let l:tree = getbufvar(a:window.bufnr, 'NERDTree', {})
  if !empty(l:tree) && has_key(l:tree, 'root')
    call setbufvar(a:window.bufnr, 'nerdtree_directory_state',
          \ s:NERDTreeDirectoryState(l:tree.root))
  endif
endfunction

function! s:RefreshNERDTreeIfVisible(force) abort
  for l:window in getwininfo()
    if l:window.tabnr == tabpagenr()
          \ && getbufvar(l:window.bufnr, '&filetype') ==# 'nerdtree'
      call s:RefreshNERDTreeWindow(l:window, a:force)
    endif
  endfor
endfunction

function! s:PollNERDTree(timer) abort
  call s:RefreshNERDTreeIfVisible(0)
endfunction

augroup nerdtree_auto_refresh
  autocmd!
  autocmd BufWritePost,FocusGained * call <SID>RefreshNERDTreeIfVisible(1)
augroup END

if exists('g:nerdtree_auto_refresh_timer')
  call timer_stop(g:nerdtree_auto_refresh_timer)
endif
let g:nerdtree_auto_refresh_timer = timer_start(
      \ 250, function('<SID>PollNERDTree'), {'repeat': -1})

" Reuse one persistent shell in a bottom split.
let s:terminal_bufnr = -1
let s:terminal_height = 12

function! s:UseCompactTerminalStatusline() abort
  if &buftype ==# 'terminal'
    let &l:statusline = ' Terminal'
  endif
endfunction

function! s:AllowTerminalToClose(bufnr) abort
  if getbufvar(a:bufnr, '&buftype') ==# 'terminal'
    call term_setkill(a:bufnr, 'kill')
  endif
endfunction

augroup compact_terminal_statusline
  autocmd!
  autocmd TerminalOpen * call <SID>AllowTerminalToClose(
        \ str2nr(expand('<abuf>')))
  autocmd TerminalWinOpen,BufWinEnter * call <SID>UseCompactTerminalStatusline()
augroup END


" Apply the close policy to terminals that survived re-sourcing this file.
for s:buffer in getbufinfo()
  call s:AllowTerminalToClose(s:buffer.bufnr)
endfor

function! s:TerminalRunning() abort
  return s:terminal_bufnr > 0
        \ && bufexists(s:terminal_bufnr)
        \ && getbufvar(s:terminal_bufnr, '&buftype') ==# 'terminal'
        \ && term_getstatus(s:terminal_bufnr) =~# 'running'
endfunction

function! s:HideTerminal() abort
  if winnr('$') == 1
    hide enew
  else
    hide
  endif
endfunction

function! s:StartTerminalInput() abort
  if s:TerminalRunning() && bufnr('%') == s:terminal_bufnr
    silent! normal! i
  endif
endfunction

function! s:WorkspaceRegion(bufnr) abort
  if getbufvar(a:bufnr, '&filetype') ==# 'nerdtree'
    return 'tree'
  endif
  if getbufvar(a:bufnr, '&buftype') ==# 'terminal'
    return 'terminal'
  endif
  if getbufvar(a:bufnr, '&buftype') ==# ''
    return 'code'
  endif
  return ''
endfunction

function! s:RememberCodeWindow() abort
  if s:WorkspaceRegion(bufnr('%')) ==# 'code'
    let t:last_code_winid = win_getid()
  endif
endfunction

function! s:FindWorkspaceWindow(region) abort
  let l:fallback_winid = -1
  for l:window in getwininfo()
    if l:window.tabnr != tabpagenr()
          \ || s:WorkspaceRegion(l:window.bufnr) !=# a:region
      continue
    endif
    if a:region ==# 'code'
          \ && get(t:, 'last_code_winid', -1) == l:window.winid
      return l:window.winid
    endif
    if a:region ==# 'terminal' && l:window.bufnr == s:terminal_bufnr
      return l:window.winid
    endif
    if l:fallback_winid == -1
      let l:fallback_winid = l:window.winid
    endif
  endfor
  return l:fallback_winid
endfunction

function! s:CycleWorkspaceFocus() abort
  call s:RememberCodeWindow()
  let l:regions = ['code', 'tree', 'terminal']
  let l:start = index(l:regions, s:WorkspaceRegion(bufnr('%')))

  for l:offset in range(1, len(l:regions))
    let l:region = l:regions[(l:start + l:offset) % len(l:regions)]
    let l:winid = s:FindWorkspaceWindow(l:region)
    if l:winid != -1 && l:winid != win_getid()
      call win_gotoid(l:winid)
      if l:region ==# 'terminal'
        call s:StartTerminalInput()
      endif
      return
    endif
  endfor
endfunction

augroup workspace_focus_memory
  autocmd!
  autocmd WinEnter,BufEnter * call <SID>RememberCodeWindow()
augroup END

command! CycleWorkspaceFocus call <SID>CycleWorkspaceFocus()
nnoremap <silent> <M-e> :CycleWorkspaceFocus<CR>
inoremap <silent> <M-e> <Esc>:CycleWorkspaceFocus<CR>
tnoremap <silent> <M-e> <C-\><C-n>:CycleWorkspaceFocus<CR>

function! s:FocusCodeWindow() abort
  if &buftype ==# '' && &filetype !=# 'nerdtree'
    return
  endif

  let l:previous_winnr = winnr('#')
  if l:previous_winnr > 0
    let l:previous_bufnr = winbufnr(l:previous_winnr)
    if getbufvar(l:previous_bufnr, '&buftype') ==# ''
          \ && getbufvar(l:previous_bufnr, '&filetype') !=# 'nerdtree'
      call win_gotoid(win_getid(l:previous_winnr))
      return
    endif
  endif

  for l:window in getwininfo()
    if l:window.tabnr == tabpagenr()
          \ && getbufvar(l:window.bufnr, '&buftype') ==# ''
          \ && getbufvar(l:window.bufnr, '&filetype') !=# 'nerdtree'
      call win_gotoid(l:window.winid)
      return
    endif
  endfor

  rightbelow vnew
endfunction

function! s:ToggleTerminal() abort
  if !has('terminal')
    echoerr 'This Vim was built without +terminal support'
    return
  endif

  if s:TerminalRunning()
    let l:terminal_winid = bufwinid(s:terminal_bufnr)
    if l:terminal_winid == win_getid()
      call s:HideTerminal()
    elseif l:terminal_winid != -1
      call win_gotoid(l:terminal_winid)
      call s:StartTerminalInput()
    else
      call s:FocusCodeWindow()
      silent execute 'belowright sbuffer ' . s:terminal_bufnr
      silent execute 'resize ' . s:terminal_height
      redraw!
      call s:StartTerminalInput()
    endif
    return
  endif

  if s:terminal_bufnr > 0 && bufexists(s:terminal_bufnr)
    execute 'bwipeout! ' . s:terminal_bufnr
  endif

  call s:FocusCodeWindow()
  execute 'belowright terminal ++kill=kill ++rows=' . s:terminal_height
  let s:terminal_bufnr = bufnr('%')
  setlocal bufhidden=hide
endfunction

command! ToggleTerminal call <SID>ToggleTerminal()

nnoremap <silent> <C-/> :ToggleTerminal<CR>
nnoremap <silent> <C-_> :ToggleTerminal<CR>
inoremap <silent> <C-/> <C-o>:ToggleTerminal<CR>
inoremap <silent> <C-_> <C-o>:ToggleTerminal<CR>
tnoremap <silent> <C-/> <C-\><C-n>:ToggleTerminal<CR>
tnoremap <silent> <C-_> <C-\><C-n>:ToggleTerminal<CR>
tnoremap <silent> <C-n> <C-\><C-n>
