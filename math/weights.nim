import std/unittest

type 
    WeightMap = seq[int]

proc isBetweenUI*(x,a,b: int): bool =
    ##Checks if a number is between two other numbers (upper bound/right bound included)
    return (a < x) and (x <= b) 

proc isBetweenLI*(x,a,b: int): bool =
    ##Checks if a number is between two other numbers (lower bound/left bound included)
    return (a <= x) and (x < b) 

proc isBetweenLIUI*(x,a,b: int): bool =
    ##Checks if a number is between two other numbers (both bounds included)
    return (a <= x) and (x <= b) 

proc isBetween*(x,a,b: int): bool =
    ##Checks if a number is between two other numbers (both numbers excluded)
    return (a < x) and (x < b) 

proc weightMap*(weights: openArray[int]): WeightMap =
    ##Generates a weightMap (sequence of tuples) with each tuple holding the higher bound of the indexvalue it should be mapped to
    var 
        cumulativeWeight: int = 0
        index: int = 0
 
    for weight in weights:
        cumulativeWeight = cumulativeWeight + weight
        index = index + 1
        let
            mapping = (index, cumulativeWeight)
        result.add(mapping)

proc mapValue*(weightMap: WeightMap, x: int): int =
    ## The WeightMap type is just a seq[int]. Two of these entries would define an interval with (lB, uB] 
    ## The provided x value is than mapped to the respective index in the sequence of the lower bound (if it is within this interval). 
    ## Attention: The lower bound / left value is NOT included.
    ## Example: For interval (2, 6]: x = 3, x = 4, x = 5, x = 6 will all be mapped to 3 BUT
    ## x = 2 will NOT be mapped to 3. But to whatever tuple value was before it.
    var 
        i: int = 0
        l: int = weightMap.len()

    while i < l-1: #l-1 because i+1 doesnt exist for the last mapping!
        let
            lB = weightMap[i]      #lower bound
            uB = weightMap[i+1]    #upper bound
        if x.isBetweenUI(lB, uB):
            return i
        i.inc()


#Compile and run the tests with "nim c -d:test -r weights.nim" or run all tests via "nimble test"
when defined(test):
    suite "Weights":
        test "weightMap":
            const 
                weights = [2, 3, 1, 4]
                cumulativeWeights = [2, 5, 6, 10] # 0+2 = 2, 2+3 = 5, 5+1 = 6, 6+4 = 10
                randomValues = [4, 7, 8, 1, 2, 6] # should not contain 0!!! otherwise the first weight will be its value +1, so not its actual weight
                testResult = [1,3,3,0,0,2]
            let
                weightMap = weights.weightMap()          
            for i in 0.. 3:
                check( weightMap[i][1] == cumulativeWeights[i] )
            for i in 0.. 5:
                check ( testResult[i] == weightMap.mapValue(randomValues[i]) )