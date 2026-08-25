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
- Added C, C++, and Python language intelligence through a Vim 9 LSP client, clangd, and Pyright, with completion, diagnostics, and project navigation mappings.
- Added Nerd Font file-type icons and Git status markers to NERDTree.
- Added idle auto-save and automatic reload of externally changed files, with the disk version taking precedence on conflicts.
- Added focus-independent background directory polling and automatic refresh for a visible NERDTree.
- Added automatic delimiter pairing and paired editing through lexima.vim.
- Added vim-gitgutter indicators and hunk navigation for line-level Git changes.
- Added live browser Markdown preview with a `\m` toggle.
- Added the Tokyo Night `night` color scheme with true-color terminal support.
- Added WSL integration that copies Visual-mode yanks to the Windows clipboard and exposes explicit Windows paste operations.
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
- Adapted the NERDTree width to its rendered hierarchy between 24 and 40 columns.
- Opened directory arguments as a left-side NERDTree with an empty code pane instead of replacing the entire window.
- Displayed absolute line numbers in code panes while keeping tool windows compact.
- Moved Git change indicators into the line-number column to remove the dedicated left gutter.
- Removed NERDTree's persistent help prompt while preserving the `?` help toggle.
- Suppressed Pyright diagnostics for imports and module sources that exist only in remote Python environments.

### Fixed

- Hid the meaningless first-line number in an empty directory-workspace code pane while restoring line numbers when a file opens.
- Improved blue ANSI text contrast in Vim's built-in terminal by applying the Tokyo Night terminal palette.
- Restored focus-independent file-tree refreshes for local directories while keeping network-mounted trees on manual refresh.
- Kept WSL clipboard copying independent of the current directory by routing all copies through terminal OSC 52 support.
- Limited the implementation jump mapping to C and C++ buffers so Python navigation does not invoke a capability that Pyright does not provide.
- Prevented underscores inside Markdown identifiers from being highlighted as errors.
- Suppressed duplicate terminal buffer details when reopening the bottom terminal.
- Prevented terminal toggle key sequences and queued mode changes from leaking into subsequent input.
- Prevented immediate quit and buffer-switch commands from failing before the idle auto-save timer fires.
- Prevented a running persistent terminal from blocking `:qall`.
- Prevented terminal focus changes from shifting shell content by hiding the terminal window's sign column.
- Prevented SSHFS and other network mounts from blocking Vim through periodic directory scans, broad file checks, and background Git decoration.
- Kept file-tree hierarchy indentation stable from the first render by displaying each directory level on its own row.
