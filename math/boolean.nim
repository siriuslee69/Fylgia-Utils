proc rotLeft*[T: uint8|uint16|uint32|uint64|int8|int16|int32|int64](a: T, k: uint8): T =
    ## Uses a bit mask with a bool AND operation, cost is approx. 3 cycles to set up p
    # when-statements are evaluated at compile time (during the creation of the exectubale, not after. Same goes for const definitions)
    const bitLen: uint8 =
        when sizeof(T) == 1: 8'u8
        elif sizeof(T) == 2: 16'u8
        elif sizeof(T) == 4: 32'u8
        elif sizeof(T) == 8: 64'u8
        else: static: doAssert false, "Unsupported integer size"
    let 
        p: uint8 = k and (bitLen - 1) #results in bits like 0b00111111 or 0b00001111 with 1s at the end as an alternative to the modulo operation for clamping k
        q: uint8 = bitLen - p
    return (a shl p or a shr q)


proc rotLeftM*[T: uint8|uint16|uint32|uint64|int8|int16|int32|int64](a: T, k: uint8): T =
    ## Modulo / wrapping version, where k can be bigger than max bit count of a's type, but this might be a tad slower (20-90cycles for p)
    const bitLen: uint8 =
        when sizeof(T) == 1: 8'u8
        elif sizeof(T) == 2: 16'u8
        elif sizeof(T) == 4: 32'u8
        elif sizeof(T) == 8: 64'u8
        else: static: doAssert false, "Unsupported integer size"
    let 
        p: uint8 = k mod bitLen
        q: uint8 = bitlen - p
    return (a shl p or a shr q)


#Compile and run the tests with "nim c -d:test -r boolean.nim" or run all tests via "nimble test"


