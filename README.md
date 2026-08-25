# Vim Configuration

This repository maintains a personal Vim configuration. Configuration is added by feature and kept understandable, verifiable, and reversible.

## Installation

Place the repository at `~/.vim`, then initialize its plugin submodules:

```sh
git submodule update --init --recursive
```

Vim loads the repository's `vimrc` entry point and plugins under `pack/vendor/start` automatically.

After initializing the submodules on a new machine, open Vim and run
`:call mkdp#util#install()` once to install the Markdown preview helper.

## Appearance

[Tokyo Night](https://github.com/folke/tokyonight.nvim) provides the dark
`tokyonight-night` color scheme through its generated Vim runtime files. Vim
enables 24-bit terminal colors before loading the theme. Builds without
`+termguicolors`, or installations where the theme submodule is unavailable,
continue to start with Vim's default colors.

The custom GitGutter and NERDTree Git colors are applied after the main color
scheme so their narrow green, yellow, red, cyan, and muted indicators remain
consistent with the rest of the Tokyo Night palette.

Named file panes display absolute line numbers. The empty code pane shown for a
directory workspace, NERDTree, and terminal windows omit them so unused and
tool-window content stays compact.

## Windows Clipboard

On WSL, all clipboard copies use OSC 52 through the terminal. Select text in
Character, Line, or Block Visual mode and press `y` to copy it directly to the
Windows clipboard, regardless of whether Vim's current directory is local or
on an SSHFS or another remote mount. Normal-mode yanks continue to use Vim's
internal registers; use `"+yy` to copy a complete line to Windows.

PowerShell handles explicit `"+p` paste operations. OSC 52 paste queries are
disabled to avoid blocking in terminals that do not support them, so explicit
Windows paste remains limited to ordinary WSL directories. Delete and change
operations do not overwrite the Windows clipboard.

## Automatic File Sync

- Modified, writable file buffers are saved after half a second without keyboard input.
- Named writable buffers are also saved before quitting or switching files, and when Vim loses focus.
- Vim checks the current ordinary file for disk changes when it regains focus or enters that buffer. Tool-window events never scan every loaded buffer.
- External disk content is reloaded automatically without a confirmation prompt.
- When an unsaved Vim change conflicts with an external change, the external disk version wins and the unsaved Vim change is discarded.
- Terminal, NERDTree, help, read-only, and unnamed buffers are not auto-saved.

## File Tree

[NERDTree](https://github.com/preservim/nerdtree) provides the file tree through Vim's native package mechanism. The NERDTree Git plugin adds repository status markers, and vim-devicons adds file-type icons from Nerd Fonts.

- The tree fits the currently rendered hierarchy between 24 and 40 columns. Expanding or collapsing a directory recalculates the width, while names that exceed the upper limit remain clipped.
- Every directory level uses its own indented row; single-child directory chains are never collapsed onto one line.
- Starting Vim with a directory opens the tree on the left and a completely blank, numberless code pane on the right, with focus in the tree. Line numbers appear after a file is opened.
- Press `Ctrl+n` in Normal mode to show or hide the tree.
- Press `Alt+e` to cycle focus through the visible code, NERDTree, and terminal regions; hidden regions are skipped.
- The `Alt+e` focus cycle works from code Insert mode and Terminal-Job mode as well as Normal mode.
- The persistent help prompt is hidden; press `?` while focused on NERDTree to display the full built-in help.
- Git state is shown by coloring the file name instead of appending a status symbol: modified and dirty names are yellow, staged names are green, conflicts and deletions are red, renames are cyan, and untracked or ignored names are muted.
- A visible local tree checks its open directories every 250 milliseconds and redraws only when their entries change, even while focus remains in a code or terminal window. File saves, external Vim shell commands, and returning focus to Vim also trigger an immediate refresh.
- Trees rooted on SSHFS, NFS, CIFS, WebDAV, or rclone mounts use manual refresh so network latency cannot block unrelated editing or terminal input.
- Press `r` in NERDTree to refresh the selected directory manually, or `R` to refresh the root.
- Select a Nerd Font in the terminal profile; missing glyphs appear as empty boxes when the terminal font lacks them.

## Git Change Indicators

[vim-gitgutter](https://github.com/airblade/vim-gitgutter) marks added, modified, and removed lines in the line-number column of each Git-tracked file. A single narrow bar shape is colored green, yellow, or red for those states, matching the visual approach used by the Neovim configuration instead of displaying textual `+`, `~`, and `_` symbols. Sharing the line-number column removes the otherwise empty gutter to its left without shifting the code horizontally, and signs from other plugins are preserved.

Background Git decoration is disabled for files and NERDTree roots on recognized network mounts. Git commands remain available from the terminal, but slow remote repository scans cannot accumulate behind ordinary window changes.

- Press `]c` or `[c` to jump to the next or previous changed block.
- Press `\hp` to preview the changed block under the cursor.
- Press `\hs` to stage that changed block.
- Press `\hu` to discard that changed block from the working file.
- Run `:GitGutterToggle` to show or hide the indicators globally.

## Terminal

Vim's built-in terminal is exposed as one reusable shell in a 12-line split below the code area. When NERDTree is open, the tree keeps the full height of the left side while the terminal occupies only the lower-right area.

- Press `Ctrl+/` or `Ctrl+_` in Normal, Insert, or Terminal-Job mode to show or hide the terminal.
- Press `Ctrl+n` in Terminal-Job mode to enter Terminal-Normal mode.
- Run `:ToggleTerminal` when a command is more convenient than a key mapping.
- Type `exit` in the shell to end the terminal job; the next toggle starts a fresh shell.
- `:qall` terminates the running terminal job and exits Vim without requiring `:qall!`.
- The terminal status line uses the compact label `Terminal` instead of showing the shell path, host, and working directory.
- Terminal windows hide line numbers and the sign column so switching between Terminal-Normal and Terminal-Job modes does not move shell content horizontally.
- ANSI colors use the Tokyo Night terminal palette, including a readable blue for shell prompts and command output.

## Indentation

C, C++, and Python use four-space indentation. Pressing Tab inserts spaces rather than a literal tab character. Existing tab characters are preserved until `:retab` is run explicitly.

## Language Intelligence

[LSP](https://microsoft.github.io/language-server-protocol/) connects Vim to
language-specific analysis processes. The Vim 9 LSP client uses clangd for C
and C++, and Pyright for Python. Completion, diagnostics, semantic highlighting,
hover documentation, cross-file navigation, references, renaming, and code
actions are enabled when the corresponding server is available.

- Press `gd` on a symbol to jump to its definition, or `gD` for its declaration.
- Press `gr` to list references, or `gy` for a type definition.
- In C and C++ buffers, press `gi` to jump to an implementation. Pyright does not provide this operation; use `gd` to reach a Python function or class definition.
- Press `Ctrl+t` to return after an LSP jump.
- Press `K` to display documentation for the symbol under the cursor.
- Press `[d` or `]d` to visit the previous or next diagnostic.
- Press `\rn` to rename a symbol across the project, `\ca` for a code action, or `\ds` to choose a symbol from the current file.
- Run `:LspShowAllServers` to inspect registered server status.

The configuration first checks the isolated user tool directory, then falls
back to executables in `PATH`. Install the servers on a new machine with:

```sh
sudo apt install clangd
npm install --prefix ~/.local/share/vim-tools/lsp pyright
```

For accurate C and C++ results, keep `compile_commands.json` or
`compile_flags.txt` at the project root. CMake can generate the former with
`-DCMAKE_EXPORT_COMPILE_COMMANDS=ON`. Pyright discovers common Python project
files automatically; use `pyrightconfig.json` when a project needs an explicit
virtual environment or analysis policy. Missing-import and missing-module-source
diagnostics are hidden because dependencies that exist only in a remote Python
environment are not visible to the local Pyright process; all other diagnostics
remain enabled.

## Code Formatting

[Neoformat](https://github.com/sbdchd/neoformat) formats the current buffer on demand. C and C++ use clang-format; Python uses Black.

- Press `\f` in Normal mode to format the current buffer. The default leader key is `\`.
- Run `:Neoformat` when a command is more convenient.
- Formatting is manual and does not run automatically when a file is saved.

The formatter executables are kept in an isolated user environment. Create it on a new machine with:

```sh
python3 -m venv ~/.local/share/vim-tools/formatters
~/.local/share/vim-tools/formatters/bin/python -m pip install black clang-format
```

## Markdown Preview

[markdown-preview.nvim](https://github.com/iamcco/markdown-preview.nvim) renders
the current Markdown buffer in the default browser and refreshes it while the
file is edited.

- Press `\m` in a Markdown buffer to open the preview; press it again from Vim
  to stop the preview server and close the generated browser tab.
- Press `Ctrl+w` in the browser to close only the preview tab, or `Alt+Tab` to
  return to Vim while leaving the preview open.
- Run `:MarkdownPreview`, `:MarkdownPreviewStop`, or
  `:MarkdownPreviewToggle` when a command is more convenient.
- Technical identifiers containing underscores are not highlighted as
  Markdown errors.

## Paired Editing

[lexima.vim](https://github.com/cohama/lexima.vim) inserts and edits matching delimiters in Insert mode.

- Typing `(`, `[`, `{`, single quotes, or double quotes inserts the matching closing character and leaves the cursor between the pair.
- Typing an existing closing character moves past it instead of inserting a duplicate.
- Pressing Backspace inside an empty pair removes both characters.
- Pressing Enter inside a pair creates an indented line between the delimiters.

## Project Conventions

- All project documentation must be written in English and use Markdown (`.md`).
- Every change intended for version control must also be recorded in `CHANGELOG.md`.
- Git commits must represent complete logical batches, not individual saves, files, or small edits.
- Commit messages must follow the Conventional Commits format and be written in English.

See [CONTRIBUTING.md](CONTRIBUTING.md) for the complete workflow. Automated contributors must also follow [AGENTS.md](AGENTS.md).

## Documentation

- [CONTRIBUTING.md](CONTRIBUTING.md): development workflow, commit conventions, and pre-commit checklist.
- [CHANGELOG.md](CHANGELOG.md): project change log.
- [AGENTS.md](AGENTS.md): repository-wide rules for automated contributors.
- [Initial workspace code review](docs/reviews/2026-08-24-integrated-workspace.md): prioritized findings preserved for follow-up work.
