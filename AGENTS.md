# Repository Guidelines

## Scope

This file applies to the repository root and every subdirectory.

## Project Purpose

This repository maintains a Vim configuration. Changes should prioritize clear configuration, reliable startup, and a focused scope.

## Working Requirements

- Before editing, inspect the relevant configuration, existing documentation, and working tree. Preserve unrelated user changes.
- Write all project documentation and commit messages in English. Documentation must use Markdown (`.md`); configuration source must remain in a format Vim can read.
- Every change intended for version control must update the `Unreleased` section of `CHANGELOG.md` in the same logical batch.
- Record changelog entries per complete logical batch, not for every small edit within that batch.
- A change that only corrects the changelog does not require a recursive changelog entry.
- Never commit Vim temporary files, machine-local state, credentials, secrets, or private local paths.

## Git Requirements

- Follow the Conventional Commits rules in [CONTRIBUTING.md](CONTRIBUTING.md).
- Do not commit after every save, small edit, or individual file change.
- Accumulate implementation, documentation, changelog, and verification work that serves one goal into a complete, verifiable, and reversible logical batch before committing.
- Do not mix unrelated work merely to increase the batch size; separate different goals into different commits.
- Before committing, review working-tree and staged changes and run `git diff --check`.
- Unless explicitly requested, do not rewrite existing history or run destructive Git operations.

## Verification Requirements

- Perform the smallest set of checks that adequately covers the change.
- When a Vim configuration entry point changes, perform at least one non-interactive startup check. For feature-specific work, also verify the relevant command, mapping, or plugin behavior.
- If environmental constraints prevent verification, state the unverified item and the reason in the handoff.
