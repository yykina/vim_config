" Use Vim defaults instead of legacy Vi compatibility.
set nocompatible
set encoding=utf-8
set autoread
set autowriteall
set updatetime=500
set ttimeout
set ttimeoutlen=100
set number
set signcolumn=number
execute 'set fillchars+=eob:\ '
execute "set <M-e>=\ee"

filetype plugin indent on
syntax enable

" Use terminal OSC 52 for clipboard copies and PowerShell for WSL pastes.
if has('clipboard_provider') && !has('gui_running')
  let g:osc52_force_avail = 1
  let g:osc52_disable_paste = 1
  silent! packadd osc52
endif

function! s:Osc52ClipboardAvailable() abort
  let l:provider = get(v:clipproviders, 'osc52', {})
  return has_key(get(l:provider, 'copy', {}), '+')
endfunction

function! s:Osc52ClipboardCopy(register, type, lines) abort
  let l:provider = get(v:clipproviders, 'osc52', {})
  let l:copy = get(l:provider, 'copy', {})
  if !has_key(l:copy, a:register)
    return
  endif

  call call(l:copy[a:register], [a:register, a:type, a:lines])
endfunction

function! s:WindowsClipboardPaste(register) abort
  if !executable('powershell.exe')
    return ['', []]
  endif

  let l:command = 'powershell.exe -NoProfile -NonInteractive -Command '
        \ . '"[Console]::OutputEncoding=[System.Text.Encoding]::UTF8; '
        \ . '[Console]::Write((Get-Clipboard -Raw))"'
  let l:text = system(l:command)
  if v:shell_error != 0
    return ['', []]
  endif

  let l:text = substitute(l:text, "\r\n", "\n", 'g')
  let l:text = substitute(l:text, "\r", "\n", 'g')
  return ['', split(l:text, "\n", 1)]
endfunction

if has('clipboard_provider') && s:Osc52ClipboardAvailable()
  let v:clipproviders['wsl-windows'] = {
        \ 'available': function('<SID>Osc52ClipboardAvailable'),
        \ 'copy': {
        \   '+': function('<SID>Osc52ClipboardCopy'),
        \   '*': function('<SID>Osc52ClipboardCopy'),
        \ },
        \ 'paste': {
        \   '+': function('<SID>WindowsClipboardPaste'),
        \   '*': function('<SID>WindowsClipboardPaste'),
        \ },
        \ }
  if index(split(&clipmethod, ','), 'wsl-windows') < 0
    set clipmethod^=wsl-windows
  endif
  xnoremap <silent> y "+y
endif

" Use Tokyo Night's generated Vim theme when the package is available.
let s:tokyonight_vim_runtime = expand('<sfile>:p:h')
      \ . '/pack/vendor/start/tokyonight.nvim/extras/vim'
if exists('+termguicolors') && isdirectory(s:tokyonight_vim_runtime)
  execute 'set runtimepath^=' . fnameescape(s:tokyonight_vim_runtime)
  set termguicolors
  set background=dark
  colorscheme tokyonight-night

  " Match Vim's built-in terminal to the Tokyo Night ANSI palette.
  let g:terminal_ansi_colors = [
        \ '#15161e', '#f7768e', '#9ece6a', '#e0af68',
        \ '#7aa2f7', '#bb9af7', '#7dcfff', '#a9b1d6',
        \ '#414868', '#ff899d', '#9fe044', '#faba4a',
        \ '#8db0ff', '#c7a9ff', '#a4daff', '#c0caf5',
        \ ]
  if exists('*term_setansicolors')
    for s:buffer in getbufinfo()
      if getbufvar(s:buffer.bufnr, '&buftype') ==# 'terminal'
        call term_setansicolors(s:buffer.bufnr, g:terminal_ansi_colors)
      endif
    endfor
  endif
endif

" Avoid synchronous background work on network-backed filesystem mounts.
let s:remote_filesystem_types = [
      \ 'fuse.sshfs',
      \ 'sshfs',
      \ 'nfs',
      \ 'nfs4',
      \ 'cifs',
      \ 'smb3',
      \ 'davfs',
      \ 'davfs2',
      \ 'fuse.rclone',
      \ ]
let s:remote_filesystem_roots = []

function! s:DecodeMountPath(path) abort
  let l:path = substitute(a:path, '\\040', ' ', 'g')
  let l:path = substitute(l:path, '\\011', "\t", 'g')
  let l:path = substitute(l:path, '\\012', "\n", 'g')
  return substitute(l:path, '\\134', '\\', 'g')
endfunction

function! s:RefreshRemoteFilesystemRoots() abort
  let s:remote_filesystem_roots = []
  if !filereadable('/proc/self/mountinfo')
    return
  endif

  for l:line in readfile('/proc/self/mountinfo')
    let l:fields = split(l:line)
    let l:separator = index(l:fields, '-')
    if l:separator > 4
          \ && l:separator + 1 < len(l:fields)
          \ && index(s:remote_filesystem_types,
          \ l:fields[l:separator + 1]) >= 0
      call add(s:remote_filesystem_roots,
            \ s:DecodeMountPath(l:fields[4]))
    endif
  endfor
endfunction

function! s:IsRemoteFilesystemPath(path) abort
  if empty(a:path)
    return 0
  endif

  let l:path = fnamemodify(a:path, ':p')
  for l:root in s:remote_filesystem_roots
    let l:root = substitute(l:root, '/\+$', '', '')
    if l:path ==# l:root || stridx(l:path, l:root . '/') == 0
      return 1
    endif
  endfor
  return 0
endfunction

function! s:ConfigureFilesystemBuffer(bufnr, path) abort
  let l:is_remote = s:IsRemoteFilesystemPath(a:path)
  call setbufvar(a:bufnr, 'vim_remote_filesystem', l:is_remote)
  if !l:is_remote
    return
  endif

  let l:gitgutter = getbufvar(a:bufnr, 'gitgutter')
  if type(l:gitgutter) != type({})
    let l:gitgutter = {}
  endif
  let l:gitgutter.enabled = 0
  call setbufvar(a:bufnr, 'gitgutter', l:gitgutter)
endfunction

call s:RefreshRemoteFilesystemRoots()

augroup remote_filesystem_awareness
  autocmd!
  autocmd FocusGained * call <SID>RefreshRemoteFilesystemRoots()
  autocmd BufReadPre,BufNewFile * call <SID>RefreshRemoteFilesystemRoots()
        \ | call <SID>ConfigureFilesystemBuffer(
        \ str2nr(expand('<abuf>')), expand('<afile>:p'))
augroup END

" Apply the policy to buffers that survived re-sourcing this file.
for s:buffer in getbufinfo()
  call s:ConfigureFilesystemBuffer(s:buffer.bufnr, s:buffer.name)
endfor

augroup language_indentation
  autocmd!
  autocmd FileType c,cpp,python
        \ setlocal expandtab tabstop=4 shiftwidth=4 softtabstop=4
augroup END

" Add language intelligence for C, C++, and Python when the servers exist.
let s:lsp_tool_root = expand('~/.local/share/vim-tools/lsp')
let s:clangd_path = s:lsp_tool_root . '/bin/clangd'
if !executable(s:clangd_path)
  let s:clangd_path = exepath('clangd')
endif

let s:pyright_path =
      \ s:lsp_tool_root . '/node_modules/.bin/pyright-langserver'
if !executable(s:pyright_path)
  let s:pyright_path = exepath('pyright-langserver')
endif

let g:lsp_options = #{
      \ autoComplete: v:true,
      \ autoHighlightDiags: v:true,
      \ completionMatcher: 'fuzzy',
      \ popupBorder: v:true,
      \ semanticHighlight: v:true,
      \ showDiagInPopup: v:true,
      \ showDiagWithSign: v:true,
      \ showDiagWithVirtualText: v:false,
      \ showSignature: v:true,
      \ }
let g:lsp_servers = []

if executable(s:clangd_path)
  call add(g:lsp_servers, #{
        \ name: 'clangd',
        \ filetype: ['c', 'cpp'],
        \ path: s:clangd_path,
        \ args: ['--background-index', '--clang-tidy'],
        \ rootSearch: [
        \   'compile_commands.json',
        \   'compile_flags.txt',
        \   '.clangd',
        \   '.git/',
        \ ],
        \ })
endif

if executable(s:pyright_path)
  call add(g:lsp_servers, #{
        \ name: 'pyright',
        \ filetype: 'python',
        \ path: s:pyright_path,
        \ args: ['--stdio'],
        \ workspaceConfig: #{
        \   python: #{
        \     analysis: #{
        \       diagnosticSeverityOverrides: #{
        \         reportMissingImports: 'none',
        \         reportMissingModuleSource: 'none',
        \       },
        \     },
        \   },
        \ },
        \ rootSearch: [
        \   'pyrightconfig.json',
        \   'pyproject.toml',
        \   'setup.cfg',
        \   'setup.py',
        \   'requirements.txt',
        \   '.git/',
        \ ],
        \ })
endif

function! s:ConfigureLspBuffer() abort
  nnoremap <buffer> <silent> gd <Cmd>LspGotoDefinition<CR>
  nnoremap <buffer> <silent> gD <Cmd>LspGotoDeclaration<CR>
  nnoremap <buffer> <silent> gr <Cmd>LspShowReferences<CR>
  nnoremap <buffer> <silent> gy <Cmd>LspGotoTypeDef<CR>
  nnoremap <buffer> <silent> K <Cmd>LspHover<CR>
  nnoremap <buffer> <silent> [d <Cmd>LspDiag prev<CR>
  nnoremap <buffer> <silent> ]d <Cmd>LspDiag next<CR>
  nnoremap <buffer> <silent> <leader>rn <Cmd>LspRename<CR>
  nnoremap <buffer> <silent> <leader>ca <Cmd>LspCodeAction<CR>
  nnoremap <buffer> <silent> <leader>ds <Cmd>LspDocumentSymbol<CR>
  if index(['c', 'cpp'], &filetype) >= 0
    nnoremap <buffer> <silent> gi <Cmd>LspGotoImpl<CR>
  endif
endfunction

function! s:RemoveLspBufferMappings() abort
  silent! nunmap <buffer> gd
  silent! nunmap <buffer> gD
  silent! nunmap <buffer> gr
  silent! nunmap <buffer> gi
  silent! nunmap <buffer> gy
  silent! nunmap <buffer> K
  silent! nunmap <buffer> [d
  silent! nunmap <buffer> ]d
  silent! nunmap <buffer> <leader>rn
  silent! nunmap <buffer> <leader>ca
  silent! nunmap <buffer> <leader>ds
endfunction

augroup language_servers
  autocmd!
  autocmd User LspAttached call <SID>ConfigureLspBuffer()
  autocmd User LspDetached call <SID>RemoveLspBufferMappings()
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

function! s:CheckTimeCurrentBuffer() abort
  if &buftype !=# '' || empty(bufname('%'))
    return
  endif

  silent execute 'checktime ' . bufnr('%')
endfunction

augroup automatic_file_sync
  autocmd!
  autocmd FileChangedShell * let v:fcs_choice = 'reload'
  autocmd FocusGained,BufEnter * call <SID>CheckTimeCurrentBuffer()
  autocmd CursorHold,CursorHoldI,FocusLost *
        \ call <SID>AutoSaveCurrentBuffer()
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

" Preview Markdown in a browser only when requested.
let g:mkdp_auto_start = 0
let g:mkdp_auto_close = 1

augroup markdown_preview_keymap
  autocmd!
  autocmd FileType markdown
        \ nmap <buffer> <silent> <leader>m <Plug>MarkdownPreviewToggle
augroup END

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
let g:NERDTreeWinSizeMax = 40
let g:NERDTreeCascadeSingleChildDir = 0
let g:NERDTreeHijackNetrw = 0
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
let g:NERDTreeGitStatusGitBinPath =
      \ expand('<sfile>:p:h') . '/bin/network-aware-git'
nnoremap <silent> <C-n> :NERDTreeToggle<CR>

function! s:RenderNERDTreeWithoutHelpHint() dict abort
  call call(s:nerdtree_original_render, [], self)
  call s:RemoveNERDTreeHelpHint()
endfunction

function! s:InstallCompactNERDTreeRenderer() abort
  if !exists('g:NERDTreeUI')
        \ || get(g:, 'NERDTreeCompactHeaderInstalled', 0)
    return
  endif

  let s:nerdtree_original_render = g:NERDTreeUI.render
  let g:NERDTreeUI.render =
        \ function('<SID>RenderNERDTreeWithoutHelpHint')
  let g:NERDTreeCompactHeaderInstalled = 1
endfunction

" Treat a directory argument as a workspace with a blank editor pane.
function! s:OpenDirectoryWorkspace() abort
  if argc() != 1 || !isdirectory(argv(0))
    return
  endif

  let l:directory = fnamemodify(argv(0), ':p')
  silent! %argdelete
  enew
  setlocal nonumber norelativenumber
  execute 'NERDTree ' . fnameescape(l:directory)
endfunction

function! s:RestoreCodePaneNumbers() abort
  if &buftype ==# '' && !empty(bufname('%'))
    setlocal number signcolumn=number
  endif
endfunction

augroup nerdtree_directory_startup
  autocmd!
  autocmd VimEnter * call <SID>InstallCompactNERDTreeRenderer()
  autocmd VimEnter * call <SID>OpenDirectoryWorkspace()
augroup END

augroup code_pane_numbering
  autocmd!
  autocmd BufWinEnter * call <SID>RestoreCodePaneNumbers()
augroup END

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

" Fit the tree to its rendered nodes without crowding the code pane.
function! s:NERDTreeRenderedLineWidth(lnum) abort
  let l:text = getline(a:lnum)
  let l:width = 0
  let l:byte_column = 1

  while l:byte_column <= strlen(l:text)
    let l:character = matchstr(strpart(l:text, l:byte_column - 1), '^.')
    if empty(l:character)
      break
    endif

    let l:conceal = synconcealed(a:lnum, l:byte_column)
    if !l:conceal[0]
      let l:width += strdisplaywidth(l:character, l:width)
    elseif !empty(l:conceal[1])
      let l:width += strdisplaywidth(l:conceal[1], l:width)
    endif
    let l:byte_column += strlen(l:character)
  endwhile

  return l:width
endfunction

function! s:ResizeCurrentNERDTree() abort
  if &filetype !=# 'nerdtree'
        \ || !exists('b:NERDTree')
        \ || !has_key(b:NERDTree, 'root')
    return
  endif

  let l:content_width = 0
  let l:root_line = b:NERDTree.ui.getRootLineNum()
  if l:root_line < line('$')
    for l:line_number in range(l:root_line + 1, line('$'))
      let l:content_width = max([
            \ l:content_width,
            \ s:NERDTreeRenderedLineWidth(l:line_number),
            \ ])
    endfor
  endif

  let l:window = getwininfo(win_getid())[0]
  let l:target_width = l:content_width + l:window.textoff + 1
  let l:target_width = max([g:NERDTreeWinSize, l:target_width])
  let l:target_width = min([g:NERDTreeWinSizeMax, l:target_width])
  if winwidth(0) != l:target_width
    execute 'silent vertical resize ' . l:target_width
  endif
endfunction

function! s:ResizeNERDTreeWindow(winid, timer) abort
  if empty(getwininfo(a:winid))
    return
  endif

  call win_execute(a:winid,
        \ 'call ' . expand('<SID>') . 'ResizeCurrentNERDTree()', 1)
endfunction

function! s:ScheduleNERDTreeWidth() abort
  if &filetype !=# 'nerdtree'
    return
  endif

  let l:timer = get(b:, 'nerdtree_width_timer', -1)
  if l:timer >= 0
    call timer_stop(l:timer)
  endif
  let b:nerdtree_width_timer = timer_start(30,
        \ function('<SID>ResizeNERDTreeWindow', [win_getid()]))
endfunction

function! s:RemoveNERDTreeHelpHint() abort
  if &filetype !=# 'nerdtree'
        \ || getline(1) !=# '" Press ' . g:NERDTreeMapHelp . ' for help'
    return
  endif

  let l:last_line = getline(2) ==# '' ? 2 : 1
  setlocal noreadonly modifiable
  execute 'silent keepjumps 1,' . l:last_line . 'delete _'
  setlocal nomodified readonly nomodifiable
endfunction

augroup nerdtree_adaptive_width
  autocmd!
  autocmd User NERDTreeInit call <SID>ScheduleNERDTreeWidth()
  autocmd BufEnter,TextChanged NERD_tree_* call <SID>ScheduleNERDTreeWidth()
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
  if s:IsRemoteFilesystemPath(l:tree.root.path.str())
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
  autocmd BufWritePost,FocusGained,ShellCmdPost *
        \ call <SID>RefreshNERDTreeIfVisible(1)
  autocmd BufEnter NERD_tree_* call <SID>RefreshNERDTreeIfVisible(1)
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
    setlocal nonumber norelativenumber signcolumn=no
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
