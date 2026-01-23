import std/[os, strutils]

# Package

version       = "0.1.0"
author        = "SiriusLee69"
description   = "Collection of some utilities"
license       = "Unlicense"
srcDir        = "src"


# Dependencies
requires "nim >= 1.6.0", "owlkettle >= 3.0.0", "illwill >= 0.4.0"

when not defined(nimscript):
  import src/siriusUtils/dirs/files
else:
  proc getAllFilesWithEnding*(sDir: string, y: string): seq[string] =
    result = @[]
    for file in walkDirRec(sDir, relative = true):
      if file.endsWith(y):
        result.add(file.replace("\\", "/").replace(y, ""))

# This is such bullshit honestly, even ChatGPT couldn't solve this. 
# To get the last provided user argument from "nimble test someFile" (in this case 'someFile')
# I have to grab the argument at the LAST position of the paramStr.
# What Nim doesn't initially tell you is that paramStr is full of other
# provided parameters internally already by Nim. So if I do paramStr(3) for example,
# I get "--verbosity:0" which I never provided, nor do I know what it does.
# I had to go through paramStr(10) ... paramStr(15) till I finally noticed 
# that the user provided arguments are all the way in the back. 
# Please learn from my mistakes.
task test, "Run tests":
  let userParam = paramStr(paramCount()) #Grabs the parameter at the last position - in this case, the provided file name
  if userParam.len() == 0 or userParam == "test":
    exec "nim c -r tests/test_smoke.nim"
    return
  if (userParam == "all"):
    let 
      shortenedFileName = userParam.replace(".nim", "") #if the filename has an ending, remove it. The paths are all saved without one too. And need to be, for searching
      paths = "src".getAllFilesWithEnding(".nim")
    for file in paths:
        exec "nim c -d:test -d:release -r src/" & file & ".nim"  
  else:
    let 
      shortenedFileName = userParam.replace(".nim", "") #if the filename has an ending, remove it. The paths are all saved without one too. And need to be, for searching
      paths = "src".getAllFilesWithEnding(".nim")
    for file in paths:
      if file.rfind(shortenedFileName) != -1:
        exec "nim c -d:test -r src/" & file & ".nim"

task debug, "Run tests":
  let userParam = paramStr(paramCount()) #Grabs the parameter at the last position - in this case, the provided file name
  if userParam.len() == 0:
    echo "Please provide the name of the file you'd like to test."
    return
  else:
    let shortenedFileName = userParam.replace(".nim", "") #if the filename has an ending, remove it. The paths are all saved without one too. And need to be, for searching
    var paths = "src".getAllFilesWithEnding(".nim")
    for file in paths:
      if file.rfind(shortenedFileName) != -1:
        exec "nim c -d:test -d:debug -r src/" & file & ".nim"

task autopush, "Add, commit, and push with message from progress.md":
  let path = "progress.md"
  var msg = ""
  if fileExists(path):
    let content = readFile(path)
    for line in content.splitLines:
      if line.startsWith("Commit Message:"):
        msg = line["Commit Message:".len .. ^1].strip()
        break
  if msg.len == 0:
    msg = "No specific commit message given."
  exec "git add -A ."
  exec "git commit -m \" " & msg & "\""
  exec "git push"
task find, "Use local clones for submodules in parent folder":
  let modulesPath = ".gitmodules"
  if not fileExists(modulesPath):
    echo "No .gitmodules found."
  else:
    let root = parentDir(getCurrentDir())
    var current = ""
    for line in readFile(modulesPath).splitLines:
      let s = line.strip()
      if s.startsWith("[submodule"):
        let start = s.find('"')
        let stop = s.rfind('"')
        if start >= 0 and stop > start:
          current = s[start + 1 .. stop - 1]
      elif current.len > 0 and s.startsWith("path"):
        let parts = s.split("=", maxsplit = 1)
        if parts.len == 2:
          let subPath = parts[1].strip()
          let tail = splitPath(subPath).tail
          let localDir = joinPath(root, tail)
          if dirExists(localDir):
            let localUrl = localDir.replace('\\', '/')
            exec "git config -f .gitmodules submodule." & current & ".url " & localUrl
            exec "git config submodule." & current & ".url " & localUrl
    exec "git submodule sync --recursive"



