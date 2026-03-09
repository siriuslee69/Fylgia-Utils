proc isEven*[T: uint8|uint16|uint32|uint64|int8|int16|int32|int64](x: T): bool =
    ## Returns true if its even, false if it is not
    return not ((x and 1).bool)

proc toEvenDec*[T: uint8|uint16|uint32|uint64|int8|int16|int32|int64](x: T): T =
    ## Will cut off the uneven bit if there is one, results in a lower number
    ## Will not cause overflow issues but might result in a 0
    ## Equivalent to decrementing the absolute value |x| by one 
    let
        uneven: T = x and 1.T
        decremented: T = x and not uneven
    return decremented

proc toEvenInc*[T: uint8|uint16|uint32|uint64|int8|int16|int32|int64](x: T): T = 
    ## Increment to the next bigger integer if it's not even 
    ## Max values will overflow, e.g. an uint8 255 +1 -> 0
    let 
        uneven: T = x and 1
        incremented: T = x + uneven
    return incremented 

# proc toEvenAbsInc*[T: int8|int16|int32|int64](x: T): T = 
#     ## Increment to the next bigger integer if it's not even 
#     ## Max values will overflow, e.g. an uint8 255 +1 -> 0
#     const 
#         signMask: T = not((not 0) shr 1)
#     let
#         uneven: T = x and 1
#         isNegative: T = 
#         sign: T = 
#         delta: T = uneven * 
#         incremented: T = x - delta
#     return incremented 


# proc toEvenAbsDec*[T: int8|int16|int32|int64](x: T): T = 
#     ## Increment to the next bigger integer if it's not even 
#     ## Max values will overflow, e.g. an uint8 255 +1 -> 0
#     let 
#         uneven: T = x and 1
#         incremented: T = x + uneven
#     return incremented 


when defined(test):

    import std/unittest, ../debugging/checks
    
    suite "Even":
        test "isEven":
            var 
                A: seq[bool] = @[]
                B: seq[bool] = @[true, false, true, false, true]
            A.add -122.isEven()
            A.add -13.isEven()
            A.add 0.isEven()
            A.add 53.isEven()
            A.add 134.isEven()

            for i in 0.. A.len()-1:
                echoCheck(A[i], B[i])
                check(A[i] == B[i])

        test "toEvenDec":
            var
                A: seq[int64] = @[]
                B: seq[int64] = @[234, 234, -1244, -1246, 0]
            A.add 234.toEvenDec().int64
            A.add 235.toEvenDec().int64
            A.add -1244.toEvenDec().int64
            A.add -1245.toEvenDec().int64
            A.add 0.toEvenDec().int64

            for i in 0.. A.len()-1:
                echoCheck(A[i], B[i])
                check(A[i] == B[i])

        test "toEvenInc":
            var
                a: uint8 = 255'u8.toEvenInc()
                b: uint8 = 0
                A: seq[int] = @[]
                B: seq[int] = @[234, 236, -1244, -1244, 0]
            A.add 234.toEvenInc()
            A.add 235.toEvenInc()
            A.add -1244.toEvenInc()
            A.add -1245.toEvenInc()
            A.add 0.toEvenInc()

            for i in 0.. A.len()-1:
                echoCheck(A[i], B[i])
                check(A[i] == B[i])
            echoCheck(a, b)
            check(a == b)