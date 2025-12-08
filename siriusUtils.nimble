# Package

version       = "0.1.0"
author        = "SiriusLee69"
description   = "Collection of some utilities"
license       = "Unlicense"
srcDir        = "."


# Dependencies

requires "nim >= 2.2.4"

import src/dirs/files

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
  if userParam.len() == 0:
    echo "Please provide the name of the file you'd like to test."
    return
  else:
    let shortenedFileName = userParam.replace(".nim", "") #if the filename has an ending, remove it. The paths are all saved without one too. And need to be, for searching
    var paths = "src".getAllFilesWithEnding(".nim")
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
