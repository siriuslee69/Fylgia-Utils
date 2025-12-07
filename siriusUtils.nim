import io/responses
import math/even
import math/weights
import math/genetic
import math/boolean
import strutils/words
import streams/write

export responses, boolean, weights, genetic, words, write

when defined(test):
    import tests/[test_io, test_math, test_strutils, test_write]
    
