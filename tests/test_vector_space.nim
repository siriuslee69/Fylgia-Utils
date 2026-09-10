## Tests for the vector space: things measured alike must end up near
## each other, and the numbers a chart reads must stay inside 0..1.

import std/unittest

import ../src/protocols/math/vector_space

proc sampleSpace(): VectorSpace =
  ## Five routines measured three ways. `a` and `b` are twins, `c` and
  ## `d` are a second pair, and `e` is unlike anything else.
  ##
  ##   id   loops  lines  consts
  ##   a      1      10      2
  ##   b      1      11      2     <- twin of a
  ##   c      3      90      0
  ##   d      3      88      1     <- twin of c
  ##   e      0     400      9     <- a world of its own
  result = newVectorSpace(["loops", "lines", "consts"])
  result.addPoint("a", "alpha", [1.0, 10.0, 2.0])
  result.addPoint("b", "beta", [1.0, 11.0, 2.0])
  result.addPoint("c", "gamma", [3.0, 90.0, 0.0])
  result.addPoint("d", "delta", [3.0, 88.0, 1.0])
  result.addPoint("e", "epsilon", [0.0, 400.0, 9.0])
  result.rescale()

suite "vector space":
  # {.testKind: tkUnit.}
  test "rescaling puts every dimension into 0..1":
    var
      S: VectorSpace = sampleSpace()
      i: int = 0
      j: int = 0
    while i < S.points.len:
      j = 0
      while j < S.dims.len:
        check S.points[i].values[j] >= 0.0
        check S.points[i].values[j] <= 1.0
        j = j + 1
      i = i + 1

  # {.testKind: tkUnit.}
  test "a thing measured alike is the nearest neighbour":
    var
      S: VectorSpace = sampleSpace()
      A: seq[Neighbour] = neighboursOf(S, "a", 4)
    check A.len == 4
    check A[0].id == "b"
    check A[0].closeness > 0.9

  # {.testKind: tkUnit.}
  test "closeness falls away with distance and never leaves 0..1":
    check closenessOf(0.0) == 1.0
    check closenessOf(closenessHalf) > 0.49
    check closenessOf(closenessHalf) < 0.51
    check closenessOf(4.0) >= 0.0
    check closenessOf(4.0) < 0.05

  # {.testKind: tkEdgeCase.}
  test "an empty room answers without failing":
    var
      S: VectorSpace = newVectorSpace(["a", "b"])
    S.rescale()
    check flatten(S).len == 0
    check cloudNodes(S).len == 0
    check neighboursOf(S, "nothing").len == 0

  # {.testKind: tkEdgeCase.}
  test "a dimension where everything scores the same is not divided by zero":
    var
      S: VectorSpace = newVectorSpace(["flat", "moving"])
    S.addPoint("a", "a", [7.0, 1.0])
    S.addPoint("b", "b", [7.0, 9.0])
    S.rescale()
    check S.points[0].values[0] == 0.0
    check S.points[1].values[0] == 0.0
    check S.points[1].values[1] == 1.0

  # {.testKind: tkEdgeCase.}
  test "a short measurement list is padded rather than refused":
    var
      S: VectorSpace = newVectorSpace(["a", "b", "c"])
    S.addPoint("x", "x", [1.0])
    check S.points[0].values.len == 3
    check S.points[0].values[2] == 0.0

  # {.testKind: tkUnit.}
  test "clumps gather the twins and leave the loner out":
    var
      S: VectorSpace = sampleSpace()
      A: seq[CloudNode] = cloudNodes(S, 0.30, 2)
    check A.len == 2
    check A[0].memberIds.len == 2
    check "e" notin A[0].memberIds
    check "e" notin A[1].memberIds

  # {.testKind: tkRegression.}
  test "the same clump is not reported twice from each twin":
    ## pins: every member used to be eligible to seed its own node, so
    ## a pair of twins produced two identical clumps.
    var
      S: VectorSpace = sampleSpace()
      A: seq[CloudNode] = cloudNodes(S, 0.30, 2)
      i: int = 0
      j: int = 0
    while i < A.len:
      j = i + 1
      while j < A.len:
        check A[i].memberIds != A[j].memberIds
        j = j + 1
      i = i + 1

  # {.testKind: tkUnit.}
  test "shape likeness ignores size":
    var
      a: FeatureVector = FeatureVector(id: "a", values: @[1.0, 2.0, 3.0])
      b: FeatureVector = FeatureVector(id: "b", values: @[10.0, 20.0, 30.0])
    check cosineLikeness(a, b) > 0.999

  # {.testKind: tkUnit.}
  test "flattening keeps every point on the screen":
    var
      S: VectorSpace = sampleSpace()
      A: seq[array[2, float]] = flatten(S)
    check A.len == S.points.len
    for row in A:
      check row[0] >= 0.0
      check row[0] <= 1.0
      check row[1] >= 0.0
      check row[1] <= 1.0
