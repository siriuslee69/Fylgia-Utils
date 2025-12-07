type 
    WeightMap* = seq[int]

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
    ## Generates a weightMap (sequence of ints) with each tuple holding the higher bound of the indexvalue it should be mapped to
    # Cumulative is just a different word for "sum" or "summed up" (= addition / +)
    var 
        cumulativeWeight: int = 0
    result.add(0) # needs a 0 at the beginning, so the first interval can start from 0 -> (0,4] for example.
    for weight in weights:
        cumulativeWeight = cumulativeWeight + weight
        result.add(cumulativeWeight)

proc mapValue*(weightMap: WeightMap, x: int): int =
    ## The WeightMap type is just a seq[int]. Two of these entries would define an interval with (lB, uB] 
    ## The provided x value is then mapped to the respective index in the sequence of the lower bound (if it is within this interval). 
    ## Attention: The lower bound / left value is NOT included.
    ## Example: For interval (2, 6]: x = 3, x = 4, x = 5, x = 6 will all be mapped to 3 BUT
    ## x = 2 will NOT be mapped to 3. But to whatever tuple value was before it.
    var 
        i: int = 0
        l: int = weightMap.len()

    while i < l-1: #l-1 because i+1 doesnt exist for the last mapping!
        let
            lB = weightMap[i]   #lower bound
            uB = weightMap[i+1]   #upper bound
        if x.isBetweenUI(lB, uB):
            return i
        i.inc()

