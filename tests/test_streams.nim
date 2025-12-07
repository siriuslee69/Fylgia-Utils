
when defined(test):
    
    import std/unittest, ../debugging/checks, ../streams/write

    suite "io":
        test "Write":
            echo $toByteSeq(23'u64)
            echo $toByteSeq(235135531'u64)
            check(true == true)
