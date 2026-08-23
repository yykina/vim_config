# Contributing Guidelines

## Documentation Language and Format

- All project documentation must be written in English and use Markdown with the `.md` extension.
- Do not add documentation in formats such as `.txt` or `.rst`.
- Vim configuration, scripts, and other source files must continue to use the formats required by their respective tools.

## Changelog

- Every configuration, script, or documentation change intended for version control must update the root `CHANGELOG.md` in the same logical batch.
- Record unreleased changes under `Unreleased` and group them under categories such as `Added`, `Changed`, `Fixed`, or `Removed`.
- Write all changelog entries in English and describe observable results instead of vague actions such as "update files."
- Add one related group of entries per logical batch; do not add an entry for every save within that batch.
- A change that only corrects or reorganizes existing changelog content does not require a recursive changelog entry.

## Logical Batches

Commits are based on complete, verifiable outcomes rather than arbitrary thresholds for edit count, file count, or lines changed.

- Do not commit after every save, file, or small edit.
- Accumulate related implementation, documentation, changelog, and verification work into one logical batch before committing.
- Changes spanning several files may share one commit when they serve the same goal; unrelated goals must use separate commits.
- Each batch must be independently understandable, verifiable, and reversible.
- A small urgent fix may be committed independently when it is complete and verified.
- Avoid `WIP` commits on the main branch. Clean up fragmented commits from temporary branches before merging.

## Commit Messages

Use the Conventional Commits format with an English summary:

```text
<type>(<scope>): <concise English summary>
```

Common `type` values:

- `feat`: add a configuration or capability.
- `fix`: correct an error, conflict, or compatibility problem.
- `refactor`: restructure existing configuration without changing behavior.
- `perf`: improve startup or runtime performance.
- `docs`: change Markdown documentation only.
- `test`: add or adjust verification.
- `chore`: maintain the repository, dependencies, or tooling.
- `build`: change the build or installation workflow.
- `ci`: change continuous integration configuration.
- `revert`: revert an existing commit.

Recommended `scope` values are `core`, `plugins`, `keymaps`, `ui`, `lsp`, `docs`, and `repo`. Use `repo` when no narrower scope applies.

Examples:

```text
feat(plugins): add fuzzy finder configuration
fix(keymaps): resolve terminal mode exit conflict
docs(repo): improve configuration installation guide
chore(repo): initialize Vim configuration repository conventions
```

Keep the subject concise and state the result directly. For complex changes, use the commit body to explain the motivation, main changes, and verification performed.

## Pre-commit Checklist

Commit a logical batch only after all applicable conditions are met:

1. The feature, fix, or maintenance task is complete.
2. Related Markdown documentation and `CHANGELOG.md` are up to date.
3. `git diff`, `git diff --cached`, and `git diff --check` have been reviewed.
4. Vim startup or configuration checks appropriate to the change have passed.
5. No swap files, caches, credentials, secrets, machine-specific paths, or other private data are staged.
