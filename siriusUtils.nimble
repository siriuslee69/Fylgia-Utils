# Package

version       = "0.1.0"
author        = "SiriusLee69"
description   = "Collection of some utilities"
license       = "Unlicense"
srcDir        = "."


# Dependencies

requires "nim >= 2.2.4"

import os, std/strutils

task debug, "Run tests with messages":
  exec "nim c -d:test -d:debug -r siriusUtils.nim"

task test, "Run tests":
  var paths: seq[string]= @[]
  for y in walkDir("tests", true, true, true):
      if y[1].rfind(".nim") != -1:
        paths.add( y[1] )
        echo $paths
  for file in paths:
    exec "nim c -d:test -r tests/" & file
  
