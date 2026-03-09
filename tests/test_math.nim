import std/unittest

import ../src/fylgia_utils/math/analysis/polynomials
import ../src/fylgia_utils/math/genetic/genetic
import ../src/fylgia_utils/math/particleSwarm/MBnvPSO
import ../src/fylgia_utils/math/weights

suite "polynomials":
  test "normalizes like terms and differentiates":
    let poly = initPolynomial([
      x(3, 3),
      x(5, 3),
      x(-2, 1),
      x(7, 0),
      x(-3, 0),
      x(0, 9),
    ])
    check poly.len == 3
    check poly[0].coefficient == 8
    check poly[0].exponent == 3
    check poly[1].coefficient == -2
    check poly[1].exponent == 1
    check poly[2].coefficient == 4
    check poly[2].exponent == 0

    let derived = derivative(poly)
    check derived.len == 2
    check derived[0].coefficient == 24
    check derived[0].exponent == 2
    check derived[1].coefficient == -2
    check derived[1].exponent == 0
    check evaluate(poly, 2) == 64
    check evaluate(derived, 2) == 94

suite "weights":
  test "maps cumulative ranges and rejects out-of-range values":
    let wm = weightMap([2, 3, 1, 4])
    check wm == @[0, 2, 5, 6, 10]
    check mapValue(wm, 2) == 0
    check mapValue(wm, 5) == 1
    check mapValue(wm, 6) == 2
    check mapValue(wm, 10) == 3
    check mapValue(wm, 0) == -1
    check mapValue(wm, 11) == -1

suite "genetic":
  test "supports registering custom operations":
    var customOps: seq[Op[int, int]] = @[]
    add(customOps, proc(x, y: int): int = x + y, "sum", 2)
    check customOps.len == 1
    check customOps[0].n == "sum"
    check customOps[0].w == 2
    check customOps[0].p(4, 5) == 9

  test "builtin div op handles zero denominators":
    check ops[^1].p(8, 0) == 8
    check ops[^1].p(8, 2) == 4

suite "particle swarm":
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
