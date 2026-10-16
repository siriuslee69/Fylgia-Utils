# Progress

Commit Message: auto_thread: the process lock starts with a value, release reads as the step it is

Features (Planned):
- More reusable validation presets for additional app types.

Features (Done):
- `auto_thread`: `parallelMap`, `parallelRange` and the `together:` block,
  all drawing on one shared thread budget (FYLGIA_THREADS, setThreadLimit,
  -d:fylgiaNoThreads). Failures come home as `ThreadJobError`. Tested
  threaded, serial, with --threads:off and under -fsanitize=thread.
- `execCmdShared`: std/osproc pipes lack close-on-exec, so programs started
  from several threads at once fail (`Bad file descriptor`) or hang; this
  lets one through at a time.
- `cloudNodes` works out who is within reach of whom once (one row per
  core) instead of every round: same clumps, 3.5 s -> under 0.1 s on Tyr.
- Every routine declares a `role` (from the shared Rune-Pragmas submodule),
  every routine has a written return type, and every value is assigned to
  `result` instead of being returned implicitly.
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
- Roles: added `Rune-Pragmas` as `submodules/Rune-Pragmas` and put its
  `meta/` folder on the path from `config.nims`. Every proc and func got a
  `{.role: ...}`. Procs with no return type got `: void`. `return value`
  became `result = value` (a bare `return` is kept for early exits).
  Small `let`s in the procs touched became `var`s with defaults.
- Still open (found by Otter, not part of this change): nesting depth
  in `vector_space`, `config_io` and `ops`; file layout in `config_io`;
  `let` and `var` lines inside `test` bodies; a placeholder flag on
  `nextCounter` in `id_utils`. That routine is a real counter, so the flag
  is probably wrong, but the cause is not checked yet.
- Check: `nimble test` and `nimble runModuleTests` both pass (18 inline
  checks). Consumers of this library now need `Rune-Pragmas` on the path,
  which the submodule provides.
