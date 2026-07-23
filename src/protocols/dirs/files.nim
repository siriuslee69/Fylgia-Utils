import os, strutils

type
    CurrentDir* = string

proc setCurrentDir*(cDir: var CurrentDir, dir: string): void =
    ## Update a CurrentDir with a new directory value.
    cDir = dir

proc getAllFilesWithEnding*(cDirObj: CurrentDir = "", y: string): seq[string] =
    ## Get all file paths inside a directory with a specific ending.
    var
        searchDir: string
        paths: seq[string] = @[]
        i: int = 0

    if cDirObj == "":
        searchDir = getCurrentDir()
    else:
        searchDir = cDirObj

    for file in walkDirRec(searchDir, {pcFile}, {pcDir}, true, true, true):
        if file.endsWith(y):
            paths.add(file)

    i = 0
    while i < paths.len:
        paths[i] = paths[i].replace("\\", "/").replace(y, "")
        i = i + 1
    result = paths

when defined(test):
    import std/unittest

    suite "dirs":
        test "collects files":
            let paths = getAllFilesWithEnding(getCurrentDir(), ".nim")
            check(paths.len >= 0)
