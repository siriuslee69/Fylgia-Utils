proc isEven*(x: SomeInteger): bool =
    ## Returns true if its even, false if it is not
    return (x and 1).bool

proc makeEven*(x: SomeInteger): int =
    ## Increment to the next bigger integer if it's not even (will overflow the max value of an int so 255+1->0)
    return x + (x and 1)