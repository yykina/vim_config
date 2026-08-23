# Vim Configuration

This repository maintains a personal Vim configuration. Configuration is added by feature and kept understandable, verifiable, and reversible.

## Installation

Place the repository at `~/.vim`, then initialize its plugin submodules:

```sh
git submodule update --init --recursive
```

Vim loads the repository's `vimrc` entry point and plugins under `pack/vendor/start` automatically.

## Automatic File Sync

- Modified, writable file buffers are saved after half a second without keyboard input.
- Named writable buffers are also saved before quitting or switching files, and when Vim loses focus.
- Vim checks for disk changes when it regains focus, enters a buffer, or becomes idle.
- External disk content is reloaded automatically without a confirmation prompt.
- When an unsaved Vim change conflicts with an external change, the external disk version wins and the unsaved Vim change is discarded.
- Terminal, NERDTree, help, read-only, and unnamed buffers are not auto-saved.

## File Tree

[NERDTree](https://github.com/preservim/nerdtree) provides the file tree through Vim's native package mechanism. The NERDTree Git plugin adds repository status markers, and vim-devicons adds file-type icons from Nerd Fonts.

- The tree uses a fixed width of 24 columns.
- Press `Ctrl+n` in Normal mode to show or hide the tree.
- Press `Alt+e` to cycle focus through the visible code, NERDTree, and terminal regions; hidden regions are skipped.
- The `Alt+e` focus cycle works from code Insert mode and Terminal-Job mode as well as Normal mode.
- Press `?` while focused on NERDTree to display its built-in help.
- Git state is shown by coloring the file name instead of appending a status symbol: modified and dirty names are yellow, staged names are green, conflicts and deletions are red, renames are cyan, and untracked or ignored names are muted.
- A visible tree checks expanded directories every 250 milliseconds and redraws only when their contents change; this works while code or the built-in terminal has focus.
- Saving a file or returning focus to Vim also refreshes the visible tree immediately.
- Press `r` in NERDTree to refresh the selected directory manually, or `R` to refresh the root.
- Select a Nerd Font in the terminal profile; missing glyphs appear as empty boxes when the terminal font lacks them.

## Git Change Indicators

[vim-gitgutter](https://github.com/airblade/vim-gitgutter) marks added, modified, and removed lines in the sign column of each Git-tracked file. A single narrow bar shape is colored green, yellow, or red for those states, matching the visual approach used by the Neovim configuration instead of displaying textual `+`, `~`, and `_` symbols. The sign column remains visible so that indicators do not shift the code horizontally, and signs from other plugins are preserved.

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

## Indentation

C, C++, and Python use four-space indentation. Pressing Tab inserts spaces rather than a literal tab character. Existing tab characters are preserved until `:retab` is run explicitly.

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
