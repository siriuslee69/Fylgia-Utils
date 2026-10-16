# Fylgia Utils

This repo is meant to be a collection of some code I often use and want to have access to.

It also contains reusable parsers and small query helpers that are intended to
be shared across other repos instead of being reimplemented locally. The first
one is the boolean text-query parser under `src/protocols/text_query/`,
which accepts queries such as:

```text
invoice AND 2025 AND NOT draft
("project alpha" AND notes) OR archive
```

The matcher is substring-based by default and is meant for lightweight path,
tag, and search filtering.

`src/protocols/containers/circ_seq.nim` provides `CircSeq`, a growable circular
FIFO sequence for inboxes and queues. It supports `push`, `pop`, runtime
capacity changes, and normal `queue[0]` array notation for logical reads
without shifting stored values on every pop.

## ⟢ Auto threader 🧵

`src/protocols/threads/auto_thread.nim` spreads independent work over
every core. There are three ways in:

```nim
import fylgia_utils/protocols/threads/auto_thread   # or the umbrella module

proc lineCount(p: string): int = readFile(p).countLines()

var
  n: seq[int] = parallelMap(@["a.nim", "b.nim", "c.nim"], lineCount)
    # one call per item, answers in the items' order

proc biggerLater(A: seq[int], i: int): int = ...      # row i against i+1 ..
var
  m: seq[int] = parallelRange(A.len, A, biggerLater)
    # one call per number 0 ..< n, every call handed the same A

together:                                             # each line at once
  report.shape = shapeReport(src, dir)
  report.secrets = secretsOf(dir, files)
```

Def. 1: the *budget* is how many threads may work at once, the calling
thread included. Every call shares it, so nested calls cannot multiply:

```
budget 8 ── together (3 lines)    takes 2 extra  -> 5 left
            └─ parallelMap         takes up to 5  -> 0 left
               └─ parallelMap      takes 0, runs on the thread it is on
```

```
setting              effect
───────────────────  ───────────────────────────────────────────
(nothing)            one thread per processor core
FYLGIA_THREADS=4     at most 4 at once (read once, at first use)
setThreadLimit(1)    everything one after another, from code
-d:fylgiaNoThreads   no thread is ever started (small boards)
--threads:off        the same, picked automatically
```

⚠ The routine handed in must only *read* what it is given and write only
its own answer. Reading one `seq` from many threads is fine; writing one
shared variable, or sharing a `ref`, is not. A job that raises does not
stop the others; the first failure comes back on the calling thread as a
`ThreadJobError` that names the job (`job 2: ...`, or the line's own text
inside `together`).

## Layout

The old `level1` / `level2` buckets have been removed. Shared modules now live
under `src/protocols/` by function instead of by abstract dependency level.

Core regression coverage lives in `evaluation/tests/`, while some modules still keep
focused inline checks behind `-d:test`.

To test everything, first, go into a folder of your choice, make sure you have git installed and:

```bash
git clone --recurse-submodules https://github.com/siriuslee69/Fylgia-Utils
```

The shared pragma repo `Rune-Pragmas` lives in `submodules/Rune-Pragmas`.
If we cloned without `--recurse-submodules`, we fill it in with:

```bash
git submodule update --init submodules/Rune-Pragmas
```

Every routine carries a `role` pragma, which comes from that repo.

Then inside this directory we can call the tests in different ways.

```bash
nimble test                     # every file in evaluation/tests/
nimble smoke                    # only the smoke test
nimble runModuleTests           # the inline `-d:test` checks inside src/ modules
nimble runModuleTests weights   # only modules whose path holds "weights"
```

Compiled test programs land in `build/`, which git ignores.

If we don't want to use nimble, we can provide the flags manually:

```bash
nim c -d:test -r src/protocols/math/weights.nim
```

## Warning

Use at your own risk. Subject to change. 

## Issue Playbook

- Symptom: `nimble autopush` falls back to the generic commit message.
- Cause: No `Commit Message:` line found in `agents/PROGRESS.md`.
- Workaround: Add or update the `Commit Message:` line in `agents/PROGRESS.md` before running `nimble autopush`.

- Symptom: Unexpected binary files appear next to sources after local test runs.
- Cause: Running `nim c -r` by hand writes the program beside the `.nim` file.
- Workaround: Run tests through nimble (they write into `build/`). `.gitignore` also ignores every file without an extension, which is what Nim programs are on Linux.

- Symptom: `nimble test` fails before compilation with a Nimble metadata write error.
- Cause: Local environment cannot write Nimble cache data in the user profile.
- Workaround: Fix local write permissions for the Nimble home/cache directory, then rerun `nimble test`.
