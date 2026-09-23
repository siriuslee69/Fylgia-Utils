import std/[os, strutils]

# Package

version       = "0.1.0"
author        = "siriuslee69"
description   = "Collection of some utilities"
license       = "Unlicense"
srcDir        = "src"


# Dependencies
requires "nim >= 1.6.0"


task runModuleTests, "Run the self-tests kept at the bottom of src modules":
  ## Some modules end in a `when defined(test):` block, built with `-d:test`.
  ## `nimble runModuleTests weights` -> only modules whose path holds "weights".
  var
    filter: string = paramStr(paramCount())
  if filter == "runModuleTests":
    filter = ""
  mkDir("build")
  for path in walkDirRec("src"):
    if path.endsWith(".nim") and path.contains(filter) and
        readFile(path).contains("when defined(test):"):
      exec "nim c -d:test --path:src -o:" &
        quoteShell(joinPath("build", splitFile(path).name)) & " -r " & quoteShell(path)

task smoke, "Run smoke tests":
  mkDir("build")
  exec "nim c --path:src -o:build/test_smoke -r evaluation/tests/test_smoke.nim"

## Shared tasks (test, runTests, autopush, switch, applyNightly, find,
## updateSubmodules, …): the sibling clone wins, the submodule is the
## fallback. `nimble sharedTasks` lists them.
when fileExists(thisDir() & "/../Nimble-Tasks/src/nimbleTasks.nims"):
  include "../Nimble-Tasks/src/nimbleTasks.nims"
elif fileExists(thisDir() & "/submodules/Nimble-Tasks/src/nimbleTasks.nims"):
  include "submodules/Nimble-Tasks/src/nimbleTasks.nims"
else:
  {.error: "Nimble-Tasks not found: git submodule update --init submodules/Nimble-Tasks".}
