import std/[random, strutils]

randomize()

type 
    S8* = uint8
    S16* = uint16
    S32* = uint32
    S64* = uint64
    SS* = seq[uint64]
    SomeSolution* = S8 | S16 | S32 | S64 | SS

    Individual*[T: SomeSolution] = object
        bestSolution*: T
        lastSolution*: T
        currentSolution*: T

    Swarm*[T: SomeSolution] = object
        individuals*: seq[Individual[T]]
        bestSolutions*: seq[T]
        velocity*: T
        alphas*: array[3, float64]
        masks*: array[3, T]

proc clampProbability(value: float64): float64 =
    if value < 0.0:
        return 0.0
    if value > 1.0:
        return 1.0
    result = value

proc ensureSameLength(X, Y: SS) =
    if X.len() != Y.len():
        raise newException(ValueError, "SS operands must have the same length")

proc `not`(X: SS): SS =
    result = newSeq[uint64](X.len())
    for i, value in X:
        result[i] = not value

proc `and`(X, Y: SS): SS =
    ensureSameLength(X, Y)
    result = newSeq[uint64](X.len())
    for i in 0 ..< X.len():
        result[i] = X[i] and Y[i]

proc `or`(X, Y: SS): SS =
    ensureSameLength(X, Y)
    result = newSeq[uint64](X.len())
    for i in 0 ..< X.len():
        result[i] = X[i] or Y[i]

proc randomMask[T: SomeInteger](p: float64): T =
    let probability = clampProbability(p)
    if probability <= 0.0:
        return default(T)
    if probability >= 1.0:
        return not default(T)
    for bit in 0 ..< sizeof(T) * 8:
        if rand(1.0) < probability:
            result = result or (1.T shl bit)

proc randomS8*(p: float64): uint8 =
    randomMask[uint8](p)

proc randomS16*(p: float64): uint16 =
    randomMask[uint16](p)

proc randomS32*(p: float64): uint32 =
    randomMask[uint32](p)

proc randomS64*(p: float64): uint64 =
    randomMask[uint64](p)

proc randomSS*(wordCount: Natural, p: float64): SS =
    result = newSeq[uint64](wordCount)
    for i in 0 ..< wordCount:
        result[i] = randomS64(p)

proc randomLike[T: SomeSolution](sample: T, p: float64): T =
    when T is S8:
        result = randomS8(p)
    elif T is S16:
        result = randomS16(p)
    elif T is S32:
        result = randomS32(p)
    elif T is S64:
        result = randomS64(p)
    elif T is SS:
        result = randomSS(sample.len(), p)

proc createSwarm*[T: SomeSolution](): Swarm[T] =
    result.individuals = @[]
    result.bestSolutions = @[]
    result.alphas = [0.5, 0.5, 0.5]
    result.velocity = default(T)
    result.masks = [default(T), default(T), default(T)]

proc init*[T: SomeSolution](s: var Swarm[T], beta: float64, alpha1: float64) =
    ## alpha0: Chance that a bit is taken from the negation of the current solution.
    ## alpha1: Chance that a bit is taken from the current solution instead of w.
    ## alpha2: Chance that w takes a bit from the personal best instead of the global best.
    let clampedBeta = clampProbability(beta)
    let clampedAlpha1 = clampProbability(alpha1)
    s.alphas[0] = clampedBeta
    s.alphas[1] = clampedAlpha1
    s.alphas[2] = 1.0 - clampedAlpha1

proc add*[T: SomeSolution](swarm: var Swarm[T], ind: Individual[T]) =
    swarm.individuals.add(ind)

proc addIndividual*[T: SomeSolution](swarm: var Swarm[T], initial: T = default(T)) =
    swarm.individuals.add(Individual[T](
        bestSolution: initial,
        currentSolution: initial,
        lastSolution: initial,
    ))

proc addGlobalBest*[T: SomeSolution](swarm: var Swarm[T], best: T) =
    swarm.bestSolutions.add(best)

proc add*[T: SomeSolution](swarm: var Swarm[T], best: T) =
    swarm.addGlobalBest(best)

proc update*[T: SomeSolution](s: var Swarm[T]) =
    if s.bestSolutions.len() == 0:
        return

    for i in 0 ..< s.individuals.len():
        let
            g = s.bestSolutions[0]
            p = s.individuals[i].bestSolution
            x = s.individuals[i].currentSolution
            betaMask = randomLike(x, s.alphas[0])
            alpha1Mask = randomLike(x, s.alphas[1])
            alpha2Mask = randomLike(x, s.alphas[2])
            w = (alpha2Mask and p) or ((not alpha2Mask) and g)
            v = (alpha1Mask and x) or ((not alpha1Mask) and w)
            u = (betaMask and (not x)) or ((not betaMask) and v)

        s.masks = [betaMask, alpha1Mask, alpha2Mask]
        s.individuals[i].lastSolution = x
        s.individuals[i].currentSolution = u
        s.velocity = v

proc `$`*[T: SomeSolution](sol: T): string =
    result = ""
    when T is S8:
        return toBin(cast[BiggestInt](sol), 8)
    elif T is S16:
        return toBin(cast[BiggestInt](sol), 16)
    elif T is S32:
        return toBin(cast[BiggestInt](sol), 32)
    elif T is S64:
        return toBin(cast[BiggestInt](sol), 64)
    elif T is SS:
        for value in sol:
            result.add(toBin(cast[BiggestInt](value), 64))

proc `$`*[T: SomeSolution](swarm: Swarm[T]): string =
    for i, individual in swarm.individuals:
        result.add(
            "Individual " & $i & " : " &
            $individual.currentSolution & ", " &
            $individual.lastSolution & ", " &
            $individual.bestSolution & "\n"
        )

when defined(test):
    import std/unittest

    suite "ParticleSwarm":
        test "random masks respect extreme probabilities":
            check randomS8(0.0) == 0'u8
            check randomS8(1.0) == 0xFF'u8

        test "update keeps bookkeeping consistent":
            var swarm = createSwarm[S16]()
            swarm.init(0.25, 0.75)
            swarm.addGlobalBest(0b1111_0000'u16)
            swarm.addIndividual(0b0000_1111'u16)

            let before = swarm.individuals[0].currentSolution
            swarm.update()

            check swarm.individuals.len == 1
            check swarm.bestSolutions.len == 1
            check swarm.individuals[0].lastSolution == before
