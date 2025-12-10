import os, strutils

proc getAllFilesWithEnding*(x, y: string): seq[string] =
    ## Gets all finds inside all directories with a specific ending
    var paths: seq[string]= @[]
    let 
        cDir = getCurrentDir()
        sDir: string = cDir & "\\" & x
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
#echo $"".getAllFilesWithEnding(".nim")