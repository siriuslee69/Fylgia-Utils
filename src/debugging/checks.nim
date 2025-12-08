proc toEven(x: SomeInteger): SomeInteger =
    ## Increment to the next bigger integer if it's not even 
    ## (will overflow the max value of an int. E.g.: max uint8 = 255 +1 -> 0)
    return x + (x and 1)

proc echoCheck*[T](a,b: T): void =
    ## Only compiles if the debug flag is provided via "nim c -d:debug -r fileName.nim"
    ## Echos the two input values and "asserts" them. 
    ## Prints a "✔" if they are equal, a "✘" otherwise
    ## The actual value of a test is b, the wanted test result is a
    when defined(debug): 
        echo "Wanted value: " & $a
        echo "Actual value: " & $b
        if (a == b): 
            echo "--- ✔ ---"
        else: 
            echo "--- ✘ ---"
    return
