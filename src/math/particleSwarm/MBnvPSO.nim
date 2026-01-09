import std/random, std/math, strutils

randomize()

template multipleOf8(bits: static uint64): static uint64 =
    ##rounds up to multiple of 8
    (bits + 7) shr 3 

template multipleOf64(bits: static uint64): static uint64 =
    ##rounds up to multiple of 64
    (bits + 63) shr 6 


type 
    Solution8 = uint8
    Solution16 = uint16
    Solution32 = uint32
    Solution64 = uint64
    Solution = seq[uint64]
    SomeSolution = Solution8|Solution16|Solution32|Solution64|Solution

    Individual[T: Solution8|Solution16|Solution32|Solution64|Solution] = object
        bestSolution: T #personal best 
        lastSolution: T
        newSolution: T

    Swarm[T: Solution8|Solution16|Solution32|Solution64|Solution] = object
        individuals: seq[Individual[T]]
        bestSolutions: seq[T] #global best, has to be ordered somewhat 
        velocity: T
        alphas: array[3, float64]
        A: array[3, T] 


# ---- Boolean Funcs for the Solution type / seq[uint8] ---- #

proc `not`(X: Solution): Solution =
    var 
        i = 0
        l = X.len()
    while i < l:
        result.add(not X[i])
        i.inc()
    
proc `and`(X, Y: Solution): Solution =
    echo "Trying to AND solutions failed. Solutions/seq[uint8]  must be the same length!"
    var 
        i = 0
        l = X.len()
    while i < l:
        result.add( X[i] and Y[i] )
        i.inc()
        
proc `or`(X,Y: Solution): Solution =
    if X.len() != Y.len():
        echo "Trying to OR solutions failed. Solutions/seq[uint8] must be the same length!"
        return
    var 
        i = 0
        l = X.len()
    while i < l:
        result.add( X[i] or Y[i] )
        i.inc()
      
# ---- Efficient functions for generating bytes with certain bit probabilities ---- 


template solutionLen(sol: SomeSolution): uint64 =
    case typeOf(sol)
    of uint8:   
        8
    of uint16:
        16
    of uint32:
        32
    of uint64:
        64
    else:
        sol.len()

proc randomSolution8(p: float64): uint8 =
    ## Returns an uint8 with each bit having the probability p of being 1
    if p >= 1.0:
        return 0b1111_1111
    else:
        var 
            x: uint64 = rand(uint64) # 1 call for an uint64 rand will yield one uint8 number
            t: uint8 = (255 * p).round().uint8() #threshold which we compare x against
            u: uint8 
        for i in 0..7:
            u = cast[uint8](x shr (i*8))
            if u < t:      # threshold comparison - adds 1 bit to the result if u was within the threshold, else keeps 0
                result = result or (1'u8 shl i) # add the bit

proc randomSolution16(p: float64): uint16 =
    ## Returns an uint16 with each bit having the probability p of being 1
    var 
        rand8bit: uint16
    for i in 0.. 1: #cast and shift in 2 uint8 into an uint64 
        rand8bit = cast[uint16](randomSolution8(p)) 
        result = result or (rand8bit shl (i*8))

proc randomSolution32(p: float64): uint32 =
    ## Returns an uint32 with each bit having the probability p of being 1
    var 
        rand8bit: uint32
    for i in 0.. 3: #cast and shift in 4 uint8 into an uint64 
        rand8bit = cast[uint32](randomSolution8(p)) 
        result = result or (rand8bit shl (i*8))

proc randomSolution64(p: float64): uint64 =
    ## Returns an uint64 with each bit having the probability p of being 1
    var 
        rand8bit: uint64
    for i in 0.. 7: #cast and shift in 8 uint8 into an uint64 
        rand8bit = cast[uint64](randomSolution8(p)) 
        result = result or (rand8bit shl (i*8))

proc randomSolution(sol: SomeSolution, p: float64): Solution =
    ## solBitLen = bit length of the solution
    ## This will always do 8 calls to random() at least, to fill an entire uint64, so there is a bit of overhead. 
    ## Unless you provide solutions with exactly a multiple of 64 entries (bits),
    ## it might make more sense to create a new function to make this more efficient
    let l = (solutionLen(sol)/8).ceil().int64()
    case typeOf(sol)
    of uint8:
        result = randomSolution8(p)
    of uint16:
        result = randomSolution16(p)
    of uint32:
        result = randomSolution32(p)
    of uint64:
        result = randomSolution64(p)
    else:
        for u64 in sol:
            result.add( randomSolution64(p) )


proc init(s: var Swarm, beta: float64, alpha1: float64 ): void =
    ## alpha0: Chance that a bit is taken from the NEGATION of the last personal solution of the individual
    ## alpha1: Chance that a bit is taken from the last solution / particle stays at current position
    ## alpha2: Chance that a bit is taken from the personal best vs being taken from the global best instead
    ## Chances don't translate 1:1 since the actual update function is nested
    s.alphas[0] = beta
    s.alphas[1] = alpha1 
    s.alphas[2] = 1 - alpha1

proc update(s: var Swarm): void =
    let
        b = s.A[0]
        a1 = s.A[1]
        a2 = s.A[2]
    for individual in s.individuals:
        let
            g = s.bestSolutions[0]
            p = individual.bestSolution
            x = individual.lastSolution

            w = a2 and p or (not a2) and g
            v = a1 and x or (not a1) and w
            u = b and (not x) or (not b) and v



when defined(test):
    import unittest
    suite "ParticleSwarm":
        test "Some tests":
            echo "hey"
            echo $randomSolution8(0.4)
            echo $randomSolution16(0.4)
            echo $randomSolution32(0.4)
            echo $randomSolution64(0.4)

            
