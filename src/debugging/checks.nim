proc makeEven(x: SomeInteger): SomeInteger =
    ## Increment to the next bigger integer if it's not even (will overflow the max value of an int so 255+1->0)
    return x + (x and 1)

proc echoCheck*[T](a,b: T): void =
    ## Echos the two input values and checks them also
    ## The actual value should be b, the wanted test result should be a
    when defined(debug): 
        echo "Wanted value: " & $a
        echo "Actual value: " & $b
        if (a == b): 
            echo "--- ✔ ---"
        else: 
            echo "--- ✘ ---"
    return
