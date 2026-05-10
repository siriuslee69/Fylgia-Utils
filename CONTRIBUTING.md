# Contributing to Fylgia-Utils

## Purpose

This repo provides reusable utility modules shared by other workspace repos. Changes should improve portability, correctness, and reusability.

## What belongs here

- Generic utility helpers that are reusable across repos.
- Small parsing, validation, IO, and math helpers with clear tests.
- Minimal docs and tasks required to maintain the package.

## What does not belong here

- Repo-specific business logic tied to one downstream service.
- Generated binaries, temporary build artifacts, or editor state.
- Frontend-specific code and UI behavior.

## Important files

- `src/fylgia_utils.nim`: package surface exports.
- `src/protocols/`: utility modules grouped by concern.
- `tests/`: smoke and focused regressions.
- `fylgia_utils.nimble`: canonical tasks (`test`, `debug`, `autopush`, `find`, `smoke`).
- `README.md`: usage and issue playbook.
- `.iron/PROGRESS.md`: progress log and commit message source.

## Review checklist

1. Keep APIs deterministic and side-effect boundaries explicit.
2. Add or update tests when behavior changes.
3. Keep public module docs and README examples in sync with behavior.
4. Do not commit generated binaries or cache artifacts.
5. Keep `autopush` and progress metadata paths aligned with `.iron/PROGRESS.md`.

## Commands

```bash
nimble test
nimble test all
nimble debug <moduleName>
nimble smoke
```
