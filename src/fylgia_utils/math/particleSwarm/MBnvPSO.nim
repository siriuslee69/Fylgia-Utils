import std/random, std/math, strutils

randomize()

template multipleOf8(bits: static uint64): static uint64 =
    ##rounds up to multiple of 8
    (bits + 7) shr 3 

template multipleOf64(bits: static uint64): static uint64 =
    ##rounds up to multiple of 64
    (bits + 63) shr 6 


type 
    S8 = uint8
    S16 = uint16
    S32 = uint32
    S64 = uint64
    SS = seq[uint64]
    SomeSolution = S8|S16|S32|S64|SS

    Individual[T: S8|S16|S32|S64|SS] = object
        bestSolution: T  #personal best 
        lastSolution: T
        currentSolution: T

    Swarm[T: S8|S16|S32|S64|SS] = object
        individuals: seq[Individual[T]]
        bestSolutions: seq[T] #global best, has to be ordered somewhat 
        velocity: T
        alphas: array[3, float64]
        A: array[3, T] 


# ---- Boolean Funcs for the SS type / seq[uint8] ---- #

proc `not`(X: SS): SS =
    var 
        i = 0
        l = X.len()
    while i < l:
        result.add(not X[i])
        i.inc()
    
proc `and`(X, Y: SS): SS =
    echo "Trying to AND SSs failed. SSs/seq[uint8]  must be the same length!"
    var 
        i = 0
        l = X.len()
    while i < l:
        result.add( X[i] and Y[i] )
        i.inc()
        
proc `or`(X,Y: SS): SS =
    if X.len() != Y.len():
        echo "Trying to OR SSs failed. SSs/seq[uint8] must be the same length!"
        return
    var 
        i = 0
        l = X.len()
    while i < l:
        result.add( X[i] or Y[i] )
        i.inc()
      
# ---- Efficient functions for generating bytes with certain bit probabilities ---- 


template SSLen(sol: SomeSolution): uint64 =
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

proc randomS8(p: float64): uint8 =
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

proc randomS16(p: float64): uint16 =
    ## Returns an uint16 with each bit having the probability p of being 1
    var 
        rand8bit: uint16
    for i in 0.. 1: #cast and shift in 2 uint8 into an uint64 
        rand8bit = cast[uint16](randomS8(p)) 
        result = result or (rand8bit shl (i*8))

proc randomS32(p: float64): uint32 =
    ## Returns an uint32 with each bit having the probability p of being 1
    var 
        rand8bit: uint32
    for i in 0.. 3: #cast and shift in 4 uint8 into an uint64 
        rand8bit = cast[uint32](randomS8(p)) 
        result = result or (rand8bit shl (i*8))

proc randomS64(p: float64): uint64 =
    ## Returns an uint64 with each bit having the probability p of being 1
    var 
        rand8bit: uint64
    for i in 0.. 7: #cast and shift in 8 uint8 into an uint64 
        rand8bit = cast[uint64](randomS8(p)) 
        result = result or (rand8bit shl (i*8))

proc randomSS(sol: SomeSolution, p: float64): SS =
    ## solBitLen = bit length of the SS
    ## This will always do 8 calls to random() at least, to fill an entire uint64, so there is a bit of overhead. 
    ## Unless you provide SSs with exactly a multiple of 64 entries (bits),
    ## it might make more sense to create a new function to make this more efficient
    let l = (SSLen(sol)/8).ceil().int64()
    case typeOf(sol)
    of uint8:
        result = randomS8(p)
    of uint16:
        result = randomS16(p)
    of uint32:
        result = randomS32(p)
    of uint64:
        result = randomS64(p)
    else:
        for u64 in sol:
            result.add( randomS64(p) )

proc createSwarm[T: S8|S16|S32|S64|SS](): Swarm[T] =
    var 
        swarm: Swarm[T]
    swarm.individuals = @[]
    swarm.bestSolutions = @[]
    swarm.alphas = [0.5, 0.5, 0.5] 
    swarm.velocity = 0.T()
    swarm.A =  [0.T(), 0.T(), 0.T()]
    result = swarm
    return result

proc init(s: var Swarm, beta: float64, alpha1: float64 ): void =
    ## alpha0: Chance that a bit is taken from the NEGATION of the last personal SS of the individual
    ## alpha1: Chance that a bit is taken from the last SS / particle stays at current position
    ## alpha2: Chance that a bit is taken from the personal best vs being taken from the global best instead
    ## Chances don't translate 1:1 since the actual update function is nested
    s.alphas[0] = beta
    s.alphas[1] = alpha1 
    s.alphas[2] = 1 - alpha1

proc add[T: SomeSolution](swarm: var Swarm[T], ind: Individual[T]): void =
    swarm.individuals.add(ind)

proc addIndividual[T: SomeSolution](swarm: var Swarm[T]): void =
    swarm.individuals.add(Individual[T](bestSolution: 4.T(), currentSolution: 0.T(), lastSolution: 0.T()))

proc add[T: SomeSolution](swarm: var Swarm[T], best: T): void =
    swarm.bestSolutions.add(best)

proc update(s: var Swarm): void =
    let
        b = s.A[0]
        a1 = s.A[1]
        a2 = s.A[2]
    for individual in s.individuals:
        let
            g = s.bestSolutions[0]
            p = individual.bestSolutions
            x = individual.bestSolutions

            w = a2 and p or (not a2) and g
            v = a1 and x or (not a1) and w
            u = b and (not x) or (not b) and v

echo $8.toBin(8)

proc `$`(sol: SomeSolution): string =
    result = ""
    when sol is S8:
        return toBin(sol.BiggestInt(), 8)
    elif sol is S16:
        return toBin(sol.BiggestInt(), 16)
    elif sol is S32:
        return toBin(sol.BiggestInt(), 32)
    elif sol is S64:
        return toBin(sol.BiggestInt(), 64)
    elif sol is SS:
        var 
            i = 0
            l = sol.len()
        while i < l:
            result.add( toBin(sol[i].BiggestInt(), 64) )
            i.inc()


proc `$`[T: SomeSolution](swarm: Swarm[T]): string =
    var 
        i = 0
        l = swarm.individuals.len()
    while i < l:
        let
            individual = swarm.individuals[i]
        let msg = 
            "Individual " & $i & " : " & 
            $individual.currentSolution & ", " & 
            $individual.lastSolution & ", " & 
            $individual.bestSolution & " \n "
        result.add(msg)
        i.inc()

when defined(test):
    import unittest
    suite "ParticleSwarm":
        test "Some tests":
            echo "hey"
            echo $randomS8(0.4)
            echo $randomS16(0.4)
            echo $randomS32(0.4)
            echo $randomS64(0.4)

            var 
                swarm = createSwarm[S16]()
            echo $swarm.velocity
            echo $swarm.velocity.typeOf()

            swarm.add(0b0111_0000.S16())
            swarm.add(0b0111_0000.S16())
            swarm.addIndividual()
            echo $swarm 
