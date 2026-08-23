# Changelog

This file records changes intended for version control. New work is recorded under `Unreleased` and moved to a versioned, dated section when released.

## Unreleased

### Added

- Initialized the Vim configuration project overview, contributing guidelines, and automated contributor instructions.
- Established logical-batch commits, Conventional Commits, and mandatory changelog updates.
- Added Git ignore rules for Vim temporary files, machine-local state, and local assistant data.
- Added the Vim configuration entry point and NERDTree file explorer with a `Ctrl+n` toggle.
- Added an `Alt+e` focus cycle among visible code, NERDTree, and terminal regions from Normal, Insert, and Terminal-Job modes.
- Added a reusable bottom terminal with `Ctrl+/` and `Ctrl+_` toggles and a `Ctrl+n` Terminal-Normal shortcut.
- Added on-demand C, C++, and Python formatting through Neoformat, clang-format, and Black with a `\f` mapping.
- Added Nerd Font file-type icons and Git status markers to NERDTree.
- Added idle auto-save and automatic reload of externally changed files, with the disk version taking precedence on conflicts.
- Added focus-independent background directory polling and automatic refresh for a visible NERDTree.
- Added automatic delimiter pairing and paired editing through lexima.vim.
- Added vim-gitgutter indicators and hunk navigation for line-level Git changes.
- Added a dated code review report that preserves prioritized follow-up work for the integrated Vim workspace.

### Changed

- Standardized all project documentation and future commit messages in English.
- Replaced vim-gitgutter's textual markers with color-coded narrow bars matching the Neovim configuration.
- Replaced NERDTree Git status glyphs with status-colored file names matching Snacks Explorer.
- Hid Vim's end-of-buffer tildes in unused screen lines.
- Replaced verbose terminal buffer details in the status line with a compact `Terminal` label.
- Standardized C, C++, and Python indentation on four spaces with soft tabs.
- Reduced the idle file synchronization delay from two seconds to half a second.
- Kept NERDTree full-height on the left by constraining the terminal split to the code area.
- Reduced the NERDTree width by 25 percent, from 32 columns to 24.

### Fixed

- Suppressed duplicate terminal buffer details when reopening the bottom terminal.
- Prevented terminal toggle key sequences and queued mode changes from leaking into subsequent input.
- Prevented immediate quit and buffer-switch commands from failing before the idle auto-save timer fires.
- Prevented a running persistent terminal from blocking `:qall`.
