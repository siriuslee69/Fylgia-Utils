
when defined(test):
    
    import std/unittest, ../debugging/checks, ../strutils/words

    suite "strutils":
        test "toWords":
            let a = "somebody once told me . the world is gonna roll me - + ".toWords()
            let b = @["somebody", "once", "told", "me", ".", "the", "world", "is", "gonna", "roll", "me", "-", "+"]
            echoCheck(a, b)
            check (a == b)

