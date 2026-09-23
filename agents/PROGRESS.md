# Progress

Commit Message: Move tests under evaluation/, progress under agents/, and the git tasks onto the template

Features (Planned):
- Declare a `role` on every routine (import `runePragmas` from the shared
  Rune-Pragmas repo); none of the modules carry one yet.
- More reusable validation presets for additional app types.

Features (Done):
- Helpers for bytes/base64, time, ids, JSON payloads and text validation.
- Generic limit helpers for strings and ranges.
- Config TOML reader/writer that refuses ambiguous input.
- `vector_space`: the room-and-distance maths Otter imports.
- Tests in `evaluation/tests/`, compiled into `build/`.
- `autopush`, `switch`, and `applyNightly` copied from Proto-RepoTemplate.

Features (In Progress):
- None.

Notes:
- Last change/problem: the repo still used the removed `.iron/` layout -
  `tests/` at the root, `autopush` reading `.iron/PROGRESS.md`, and a
  nimble file that required owlkettle and illwill although no module
  imports either.
- Fix: moved `tests/` to `evaluation/tests/`, progress to `agents/`,
  copied the template git tasks, dropped the two unused requirements,
  and ran `nimble test`, `nimble smoke` and `nimble runModuleTests` - all pass.
- Commit history older than one month was squashed into a single
  starting commit on 2026-09-23.
