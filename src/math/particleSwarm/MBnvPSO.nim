import std/random, std/math, strutils
type 
    Solution = seq[uint64]
    Individual = object
        bestSolution: Solution #personal best 
        lastSolution: Solution
        newSolution: Solution
    Swarm = object
        individuals: seq[Individual] = @[]
        bestSolutions: seq[Solution] = @[] #global best, has to be ordered somewhat 
        velocity: Solution = @[]
        alphas: array[3, float64] = [0.5, 0.5, 0.5]
        A: array[3, Solution] = [@[], @[], @[]]

randomize()

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


# p = probability * 256 (0..256)
# p=0 -> always 0, p=256 -> always 1
proc bitProbability8(p: float64): uint8 =
    if p >= 1.0:
        return 0b1111_1111
    result = 0
    let
        x = rand(uint64)   # 1 call
    echo "hey"
    let
        t:uint8 = (255 * p).round().uint8()
    echo $t
    for i in 0..7:
        let u = cast[uint8](x shr (i*8))
        if u < t:      # threshold compare
            result = result or (1'u8 shl i)

proc bitProbability64(p: float64): uint64 =
    for i in 0.. 7:
        let
            rand: uint64 = cast[uint64](bitProbability8(p))
        echo $rand & "here is round number: " & $i
        result = result or (rand shl (i*8))

proc bitProbabilitySolution(solutionLenInBits: int64, p: float64): Solution =
    ## This will always do 8 calls to random() at least, to fill an entire uint64, so there is a bit of overhead. 
    ## Unless you provide solutions with exactly a multiple of 64 entries (bits),
    ## it might make more sense to create a new function to make this more efficient
    let 
        l = (solutionLenInBits/64).ceil().int64()
    echo $l
    echo $(solutionLenInBits/64)
    for i in 0.. (l-1):
        echo "Now doing round: " & $i 
        result.add(bitProbability64(p))

echo $bitProbability8(0.4)
echo $bitProbability64(0.4)
let k = bitProbabilitySolution(64, 0.3)
echo "AHA!"
echo $(k[0])

proc init(s: var Swarm, beta, alpha1: float64): void =
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


