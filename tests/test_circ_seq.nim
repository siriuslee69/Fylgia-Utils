# ==============================================
# | CircSeq Tests <- FIFO ring growth behavior |
# |--------------------------------------------|
# | Checks logical order, pop, push, and resize.|
# ==============================================

import std/unittest

import ../src/fylgia_utils

suite "CircSeq":
  test "push and index preserve logical order":
    var
      q: CircSeq[int]
    q = initCircSeq[int](3)
    q.push(10)
    q.push(11)
    q.push(12)
    check q.len == 3
    check q.capacity == 3
    check q[0] == 10
    check q[1] == 11
    check q[2] == 12

  test "pop is FIFO and wrap keeps array notation stable":
    var
      q: CircSeq[int]
      v: int = 0
    q = initCircSeq[int](3)
    q.push(1)
    q.push(2)
    q.push(3)
    check q.pop(v)
    check v == 1
    check q.pop(v)
    check v == 2
    q.push(4)
    q.push(5)
    check q.len == 3
    check q[0] == 3
    check q[1] == 4
    check q[2] == 5
    q[1] = 40
    check q[1] == 40
    check q.toSeq == @[3, 40, 5]

  test "growth preserves logical order":
    var
      q: CircSeq[int]
      v: int = 0
    q = initCircSeq[int](2)
    q.push(1)
    q.push(2)
    check q.pop(v)
    check v == 1
    q.push(3)
    q.push(4)
    check q.capacity >= 4
    check q.toSeq == @[2, 3, 4]
    q.grow(8)
    check q.capacity == 8
    check q.toSeq == @[2, 3, 4]

  test "tryPush does not grow":
    var
      q: CircSeq[int]
    q = initCircSeq[int](1)
    check q.tryPush(7)
    check not q.tryPush(8)
    check q.capacity == 1
    check q[0] == 7
