proc toByteSeqLE*(x: uint64): seq[uint8] =
    ## Converts a bigger uint to a byteseq in LE order
    if x < 255'u64:
        result.add( cast[uint8](x) )
    elif x < 65535'u64: #max uint16 size; also: multiplications are done at compile time (wrote them for better readability)
        result.add( cast[uint8](x shr 8*0))
        result.add( cast[uint8](x shr 8*1))
        result.add( cast[uint8](x shr 8*2))
        result.add( cast[uint8](x shr 8*3))
    elif x < 4294967295'u64: #max uint32 size
        result.add( cast[uint8](x) )
        result.add( cast[uint8](x shr 8*1))
        result.add( cast[uint8](x shr 8*2))
        result.add( cast[uint8](x shr 8*3))
        result.add( cast[uint8](x shr 8*4))
        result.add( cast[uint8](x shr 8*5))
        result.add( cast[uint8](x shr 8*6))
        result.add( cast[uint8](x shr 8*7))


when defined(test):
    
    import std/unittest, ../debugging/checks

    suite "io":
        test "Write":
            echo $toByteSeq(23'u64)
            echo $toByteSeq(235135531'u64)
            check(true == true)
