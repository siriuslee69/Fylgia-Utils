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

## Layout

The old `level1` / `level2` buckets have been removed. Shared modules now live
under `src/protocols/` by function instead of by abstract dependency level.

Core regression coverage lives in `evaluation/tests/`, while some modules still keep
focused inline checks behind `-d:test`.

To test everything, first, go into a folder of your choice, make sure you have git installed and:

```bash
git clone https://github.com/siriuslee69/Fylgia-Utils
```

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
