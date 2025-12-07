
when defined(test):

    import std/unittest, ../debugging/checks, ../math/genetic

    suite "Genetic":
        test "op template":
            var 
                res: int
            for op in ops:
                res = op.p(1,3)
                echo $res

when defined(test):

    import std/unittest, ../debugging/checks, ../math/boolean
    
    suite "Boolean":
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

when defined(test):
    
    import std/unittest, ../debugging/checks, ../math/weights

    suite "Weights":
        test "weightMap":
            const 
                weights = [2, 3, 1, 4]
                cumulativeWeights = [0, 2, 5, 6, 10] # 0 <- first value needs to be 0 for loop-index reasons.  0+2 = 2, 2+3 = 5, 5+1 = 6, 6+4 = 10
                randomValues = [4, 7, 8, 1, 2, 6] # should not contain 0!!! otherwise the first weight will be its value +1, so not its actual weight
                testResult = [1,3,3,0,0,2]
            let
                weightMap = weights.weightMap()          
            echo $cumulativeWeights
            echo $weightMap
            echo $testResult
            for i in 0.. 3:
                let 
                    a = weightMap[i]
                    b = cumulativeWeights[i]
                echoCheck(a, b) #does nothing, unless debug flag is defined
                check( a == b )
    
            for i in 0.. 5:
                let
                    a = testResult[i]
                    b = weightMap.mapValue(randomValues[i]) 
                echoCheck(a, b)
                check (a == b)