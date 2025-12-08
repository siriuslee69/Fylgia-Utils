import strutils

template toWords*(str: string): seq[string] =
    str.splitWhitespace()

template whereIs*(str: string, findMe: string): int =
    str.find(findMe)

template has*(str: string, fineMe: string): bool =
    str.find(findMe) != -1

when defined(test):
    
    import std/unittest, ../debugging/checks

    suite "strutils":
        test "toWords":
            let
                a = "somebody once told me . the world is gonna roll me - + ".toWords()
                b = @["somebody", "once", "told", "me", ".", "the", "world", "is", "gonna", "roll", "me", "-", "+"]
            echoCheck(a, b)
            check (a == b)

        test "whereIs":
            var 
                A: seq[int] = @[]
                B: seq[int] = @[0,4,23,-1]

            A.add "avadacadavra afsdlacad ✔✔x".whereIs("avada")
            A.add "avadacadavra afsdlacad ✔✔x".whereIs("acad")
            A.add "avadacadavra afsdlacad ✔✔x".whereIs("✔✔x")
            A.add "avadacadavra afsdlacad ✔✔x".whereIs("aa") 
   
            for i in 0..3:
                echoCheck(A[i], B[i])
                check (A[i] == B[i])
