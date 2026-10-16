# ============================================================
# | Fylgia Auto Threader Tests                               |
# | -> answers in order, failures carried home, budget kept  |
# ============================================================

import std/[atomics, os, strutils, unittest]
import runePragmas
import ../../src/protocols/threads/auto_thread

var
  peak: Atomic[int] = default(Atomic[int])
  alive: Atomic[int] = default(Atomic[int])

proc square(x: int): int {.role: math.} =
  ## x: any number. Slow enough that the threads overlap.
  sleep(2)
  result = x * x

proc countAbove(A: seq[int], i: int): int {.role: math.} =
  ## A: numbers   i: one place. How many later numbers are bigger.
  var
    j: int = i + 1
  result = 0
  while j < A.len:
    result = result + ord(A[j] > A[i])
    j = j + 1

proc failOnThree(x: int): int {.role: math.} =
  ## x: any number. Raises for 3, so the carry-home can be seen.
  result = x
  if x == 3:
    raise newException(ValueError, "three is refused")

proc track(x: int): int {.role: actor.} =
  ## x: unused. Records how many of these run at the same moment.
  var
    now: int = alive.fetchAdd(1) + 1
    seen: int = peak.load()
  while now > seen and not peak.compareExchange(seen, now):
    discard
  sleep(5)
  discard alive.fetchSub(1)
  result = x

proc nestedSum(x: int): int {.role: math.} =
  ## x: how many squares to add. A parallelMap inside a parallelMap.
  var
    A: seq[int] = @[]
    t: int = 0
  while t < x:
    A.add(t)
    t = t + 1
  result = 0
  for v in parallelMap(A, square):
    result = result + v

suite "parallelMap":
  # {.testKind: tkUnit.}
  test "answers come back in the order of the items":
    check parallelMap(@[1, 2, 3, 4, 5, 6, 7, 8], square) ==
      @[1, 4, 9, 16, 25, 36, 49, 64]

  # {.testKind: tkEdgeCase.}
  test "an empty list gives an empty list":
    check parallelMap(newSeq[int](), square).len == 0

  # {.testKind: tkEdgeCase.}
  test "a failing item is raised on the caller, naming the item":
    expect ThreadJobError:
      discard parallelMap(@[1, 2, 3, 4], failOnThree)
    try:
      discard parallelMap(@[1, 2, 3, 4], failOnThree)
    except ThreadJobError as e:
      check "job 2" in e.msg
      check "three is refused" in e.msg

suite "parallelRange":
  # {.testKind: tkUnit.}
  test "every number gets its own answer, in order":
    check parallelRange(4, @[4, 1, 3, 2], countAbove) == @[0, 2, 0, 0]

suite "budget":
  # {.testKind: tkProperty.}
  test "never more threads at once than the budget allows":
    var
      A: seq[int] = @[]
      t: int = 0
    while t < 40:
      A.add(t)
      t = t + 1
    setThreadLimit(3)
    discard parallelMap(A, track)
    check peak.load() <= 3
    setThreadLimit(32)

  # {.testKind: tkProperty.}
  test "a limit of 1 runs one job after another":
    setThreadLimit(1)
    peak.store(0)
    discard parallelMap(@[1, 2, 3, 4, 5], track)
    check peak.load() == 1
    setThreadLimit(32)

  # {.testKind: tkUnit.}
  test "nested calls give the right answer":
    check parallelMap(@[3, 4, 5], nestedSum) == @[5, 14, 30]

proc both(): tuple[a: int, b: string] {.role: orchestrator.} =
  ## Two independent lines writing two fields of `result`.
  result = (a: 0, b: "")
  together:
    result.a = square(7)
    result.b = repeat('x', square(2))

suite "together":
  # {.testKind: tkUnit.}
  test "each line lands in its own place":
    check both() == (a: 49, b: "xxxx")

  # {.testKind: tkEdgeCase.}
  test "a failing line is named by its own text":
    var
      v: int = 0
      w: int = 0
    try:
      together:
        v = square(2)
        w = failOnThree(3)
    except ThreadJobError as e:
      check "w = failOnThree(3)" in e.msg
    check v == 4

proc chained(): tuple[a: int, b: int, c: int] {.role: orchestrator.} =
  ## The second line reads `result.a`, set before the block began.
  result = (a: 3, b: 0, c: 0)
  together:
    result.b = square(2)
    result.c = square(result.a)

suite "together and result":
  # {.testKind: tkEdgeCase.}
  test "a line may read result, even on another thread":
    check chained() == (a: 3, b: 4, c: 9)

var
  topA: int = 0
  topB: int = 0
together:
  topA = square(5)
  topB = square(6)

suite "together outside a routine":
  # {.testKind: tkEdgeCase.}
  test "works where there is no result":
    check topA == 25 and topB == 36
