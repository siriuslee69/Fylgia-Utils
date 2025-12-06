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
when defined(test):
    import std/unittest
    
    suite "BooleanOps":
        test "rotLeft":
            const t1: uint8 = 242
            check t1.rotLeft(4) == 47'u8                
            check t1.rotLeft(4) == t1.rotLeftM(4)     
            check t1.rotLeft(12) != 0'u8             
            check t1.rotLeftM(4) == t1.rotLeftM(12)   # 47 == 47
            check t1.rotLeft(255) == t1.rotleft(255'u8 and 0b0000_0111)

            const t2: uint16 = 5423'u16
            check t2.rotLeft(9) == t2.rotLeftM(9)     
            check t2.rotLeft(9+16) != 0'u16             
            check t2.rotLeftM(9) == t2.rotLeftM(9+16)
            check t2.rotLeft(255) == t2.rotleft(255'u8 and 0b0000_1111)

            const t3: uint32 = 2344321'u32
            check t3.rotLeft(16) == t3.rotLeftM(16)     
            check t3.rotLeft(16+32) != 0'u32         
            check t3.rotLeftM(16) == t3.rotLeftM(16+32)
            check t3.rotLeft(255) == t3.rotleft(255'u8 and 0b0001_1111)

            const t4: uint64 = 7221246780923'u64
            check t4.rotLeft(16) == t4.rotLeftM(16)     
            check t4.rotLeft(16+64) != 0'u64             
            check t4.rotLeftM(16) == t4.rotLeftM(16+64)
            check t4.rotLeft(255) == t4.rotleft(255'u8 and 0b0011_1111)

