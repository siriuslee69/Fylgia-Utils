import os, strutils

type
    CurrentDir* = string

proc setCurrentDir*(cDir: var CurrentDir, dir: string): void = 
    cDir = dir

proc getAllFilesWithEnding*(cDirObj: CurrentDir = "", y: string): seq[string] =
    ## Gets all finds inside all directories with a specific ending
    ## This needs some fixing, lol, currently only works for nim files, doesnt allow any search terms
    var 
        cDir: string
        sDir: string
        paths: seq[string]= @[]

    if cDirObj == "":
        cDir = getCurrentDir()
        echo cDir
    else:
        sDir = cDirObj
    echo cDir
    echo sDir
    for file in walkDirRec(sDir, {pcFile}, {pcDir}, true, true, true):
        if file.rfind( y ) != -1:
            paths.add( file )
#            echo $paths
    for i, path in paths:
        paths[i] = path.replace("\\", "/").replace(".nim", "")
    result = paths
    echo paths


var
    currentDir: string = "/home/mmmmmh/Dokumente/Coding/siriusutils/src"
echo currentDir.getAllFilesWithEnding(".nim")