import std/[algorithm, tables]

type
  Monomial* {.packed.} = object
    coefficient*: int64
    exponent*: int16

  Polynomial* = seq[Monomial]

proc monomial*(coefficient: SomeInteger; exponent: SomeInteger): Monomial =
  ## Build a single polynomial term.
  if exponent < 0:
    raise newException(ValueError, "negative exponents are not supported")
  result.coefficient = coefficient.int64
  result.exponent = exponent.int16

template x*(coefficient, exponent: SomeInteger): Monomial =
  monomial(coefficient, exponent)

proc initPolynomial*(terms: openArray[Monomial]): Polynomial =
  ## Normalize a polynomial by combining like terms, dropping zeroes,
  ## and ordering the result by descending exponent.
  var coefficientsByExponent = initTable[int16, int64]()
  var exponents: seq[int16] = @[]

  for term in terms:
    if term.coefficient == 0:
      continue
    if not coefficientsByExponent.hasKey(term.exponent):
      exponents.add(term.exponent)
    coefficientsByExponent[term.exponent] =
      coefficientsByExponent.getOrDefault(term.exponent) + term.coefficient

  sort(exponents, proc(a, b: int16): int = cmp(b, a))

  for exponent in exponents:
    let coefficient = coefficientsByExponent[exponent]
    if coefficient != 0:
      result.add(Monomial(coefficient: coefficient, exponent: exponent))

proc derivative*(term: Monomial): Monomial =
  ## Differentiate a single term.
  if term.coefficient == 0 or term.exponent == 0:
    return Monomial(coefficient: 0, exponent: 0)
  result.coefficient = term.coefficient * int64(term.exponent)
  result.exponent = term.exponent - 1

proc derivative*(poly: Polynomial): Polynomial =
  ## Differentiate a full polynomial and normalize the result.
  var derivedTerms: seq[Monomial] = @[]
  for term in poly:
    let derived = derivative(term)
    if derived.coefficient != 0:
      derivedTerms.add(derived)
  result = initPolynomial(derivedTerms)

proc powInt(base: int64; exponent: int16): int64 =
  var remaining = exponent
  result = 1
  while remaining > 0:
    result = result * base
    remaining.dec

proc evaluate*(poly: Polynomial; at: int64): int64 =
  ## Evaluate a polynomial at an integer point.
  for term in poly:
    result = result + term.coefficient * powInt(at, term.exponent)

when defined(test):
  import std/unittest

  suite "Polynomials":
    test "combines like terms and evaluates":
      let poly = initPolynomial([
        x(3, 3),
        x(5, 3),
        x(-2, 1),
        x(7, 0),
        x(-3, 0),
      ])
      check poly.len == 3
      check poly[0].coefficient == 8
      check poly[0].exponent == 3
      check poly[1].coefficient == -2
      check poly[1].exponent == 1
      check poly[2].coefficient == 4
      check poly[2].exponent == 0
      check evaluate(poly, 2) == 64

    test "derivative drops constants":
      let derived = derivative(initPolynomial([x(2, 3), x(-4, 1), x(7, 0)]))
      check derived.len == 2
      check derived[0].coefficient == 6
      check derived[0].exponent == 2
      check derived[1].coefficient == -4
      check derived[1].exponent == 0


