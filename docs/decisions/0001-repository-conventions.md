# ADR-0001: Repository conventions

- **Status:** Accepted
- **Date:** 2026-11-18

## Context

Before the first commit, the repository needed a few conventions that are expensive to change later: line endings, what editor files are tracked, where the project lives on disk, and how commits and changes are recorded.

## Decisions

| Decision | Choice | Reason | Alternative considered |
|---|---|---|---|
| PowerShell line endings | LF | Runs on PowerShell 7 and gives cleaner cross-platform diffs. Endings are identical everywhere, so Authenticode signatures stay valid if scripts are signed later. | CRLF, the traditional Windows format |
| `.vscode/` folder | Ignored | Editor settings are personal. | Commit `.vscode/extensions.json` to recommend extensions |
| Local project path | Keep under `My Azure lab Stuff\CloudCTRLS-Project` | Owner preference. | Move to a path without spaces, such as `C:\dev\CloudCTRLS` |
| Commit messages | Conventional Commits (`type: summary`) | Shows the kind of change at a glance and can be parsed by CI tooling later. | Free-form messages |
| Changelog | Keep a Changelog format | Widely recognized, groups changes by type. | Generated from commits; no format |

## Consequences

- The project path contains spaces, so every script, template and pipeline path must be quoted.
- Windows-only `.bat`/`.cmd` files keep CRLF because `cmd.exe` requires it.
- A `.gitignore` only protects files that were never committed, so it was put in place before the first commit.
