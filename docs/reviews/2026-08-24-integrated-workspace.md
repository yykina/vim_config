# Code Review Report: Integrated Vim Workspace

## Review Context

- Date: 2026-08-24
- Scope: uncommitted workspace changes later captured by commit `088f819`
- Result: one P1 finding and six P2 findings
- Current status: six open findings and one resolved repository-hygiene finding

This document preserves the automated review output as a project record. A
finding is a concrete hypothesis to reproduce and verify before changing the
configuration; it is not, by itself, proof that a defect occurs in every
environment.

## Findings Summary

| ID | Priority | Status | Location | Finding |
| --- | --- | --- | --- | --- |
| CR-001 | P1 | Open | `vimrc:39` | Save modified code before focusing tool windows |
| CR-002 | P2 | Open | `README.md:13` | Document the higher-priority `~/.vimrc` startup file |
| CR-003 | P2 | Open | `vimrc:178` | Refresh Git status from the terminal-side poll |
| CR-004 | P2 | Open | `vimrc:159` | Handle a removed NERDTree root without killing the timer |
| CR-005 | P2 | Open | `vimrc:193` | Preserve the managed terminal across vimrc reloads |
| CR-006 | P2 | Open | `vimrc:79` | Enable ignored status before assigning its color |
| CR-007 | P2 | Resolved | `.gitignore:7` | Exclude the generated Neovim log |

## Detailed Findings

### CR-001: Save Modified Code Before Focusing Tool Windows

When a modified code window moves to an already visible NERDTree or terminal
before the 500 millisecond timeout, subsequent `CursorHold` and `FocusLost`
events run in that special buffer. `AutoSaveCurrentBuffer()` then returns
without saving the code buffer, so terminal commands can observe stale content
on disk.

This applies specifically when focus leaves the code window before the idle
save occurs. `autowriteall` does not cover an ordinary change of window focus.

The proposed direction is to save the ordinary buffer on `WinLeave`, or to
iterate over modified ordinary buffers instead of considering only the current
buffer.

### CR-002: Document the Higher-Priority `~/.vimrc` Startup File

The installation guide states that Vim loads `~/.vim/vimrc`. If `~/.vimrc`
already exists and does not source the repository entry point, Vim uses that
startup file and the configuration in this repository remains inactive.

The current machine does not have a conflicting `~/.vimrc`, so this is a
portability problem in the installation instructions rather than a local
startup failure.

The guide should explain that an existing `~/.vimrc` must be removed, linked to
this repository's `vimrc`, or changed to source it.

### CR-003: Refresh Git Status From the Terminal-Side Poll

While the built-in terminal has focus, nerdtree-git-plugin's `CursorHold`
handler does not refresh status because the current buffer is special. The
custom timer refreshes NERDTree's directory structure, but it does not rerun
the plugin's Git-status update.

As a result, terminal-side file changes can appear in the tree while their Git
color remains stale until focus returns to an ordinary buffer and idles.
`BufWritePost` refreshes still work; terminal or external changes made while a
special buffer has focus are the affected path.

### CR-004: Handle a Removed NERDTree Root Without Killing the Timer

`NERDTreeDirectoryState()` catches a failed `readdir()`, but the later
`b:NERDTree.root.refresh()` call is not protected. If the displayed root is
renamed or deleted externally, that call can raise
`NERDTree.InvalidArgumentsError` from the repeating timer callback. Vim cancels
a repeating timer after three consecutive callback errors, leaving automatic
refresh inactive.

The refresh operation should catch this condition and keep the timer alive so
the tree can recover when the path becomes available again.

### CR-005: Preserve the Managed Terminal Across vimrc Reloads

Running `:source ~/.vim/vimrc` while the managed terminal is alive resets
`s:terminal_bufnr` to `-1`. The existing terminal can survive the reload, but
the next `:ToggleTerminal` may create another shell because the configuration
no longer recognizes the first one.

The terminal buffer number should survive reloads, or the configuration should
rediscover the existing managed terminal buffer.

This behavior was reproduced during the report audit: `term_list()` changed
from one terminal buffer to two after re-sourcing the vimrc and toggling the
terminal.

### CR-006: Enable Ignored Status Before Assigning Its Color

The configuration defines an ignored marker and color, and the README promises
that ignored names are muted. However, nerdtree-git-plugin defaults
`g:NERDTreeGitStatusShowIgnored` to `0`, so it does not emit the ignored marker.

Ignored-status reporting should be enabled before the plugin loads, or the
README and unused color rule should stop advertising that state.
Enabling ignored-file scanning has a performance cost, so removing the promise
is also a valid resolution if refresh speed is preferred.

### CR-007: Exclude the Generated Neovim Log

The generated `nvim.log` file was untracked and could have entered a broad
`git add -A` operation, contrary to the repository rule against committing
machine-local state.

This finding was resolved before commit `088f819` by adding `nvim.log` to
`.gitignore`. The local log remains available but is not tracked.

## Follow-Up

Address open findings in priority order and verify each with the smallest
reproduction that covers its trigger. After the fixes, run a non-interactive
Vim startup check, targeted feature checks, and another code review of the
uncommitted changes before committing the remediation batch.
