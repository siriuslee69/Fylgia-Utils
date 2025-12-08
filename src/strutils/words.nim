import strutils

template toWords*(str: string): seq[string] =
    str.splitWhitespace()


when defined(test):
    
    import std/unittest, ../debugging/checks

    suite "strutils":
        test "toWords":
            let a = "somebody once told me . the world is gonna roll me - + ".toWords()
            let b = @["somebody", "once", "told", "me", ".", "the", "world", "is", "gonna", "roll", "me", "-", "+"]
            echoCheck(a, b)
            check (a == b)

