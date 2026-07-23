# ==========================================================
# | CircSeq <- growable circular sequence for FIFO inboxes |
# |--------------------------------------------------------|
# | Stores values in logical order without shifting on pop.|
# ==========================================================

const
  defaultCircSeqCapacity* = 64

type
  ## CircSeq: growable circular FIFO with array-like logical indexing.
  CircSeq*[T] = object
    items: seq[T]
    head: int
    tail: int
    count: int

proc initCircSeq*[T](capacity: int = defaultCircSeqCapacity): CircSeq[T] =
  ## capacity: initial storage size; zero creates an empty buffer.
  if capacity < 0:
    raise newException(ValueError, "CircSeq capacity must not be negative")
  result.items = newSeq[T](capacity)
  result.head = 0
  result.tail = 0
  result.count = 0

proc len*[T](S: CircSeq[T]): int =
  ## S: circular sequence to inspect.
  result = S.count

proc capacity*[T](S: CircSeq[T]): int =
  ## S: circular sequence to inspect.
  result = S.items.len

proc isEmpty*[T](S: CircSeq[T]): bool =
  ## S: circular sequence to inspect.
  result = S.count == 0

proc isFull*[T](S: CircSeq[T]): bool =
  ## S: circular sequence to inspect.
  result = S.count == S.items.len

proc physicalIndex[T](S: CircSeq[T], i: int): int =
  ## S: circular sequence to index.
  ## i: logical index from oldest to newest.
  if i < 0 or i >= S.count:
    raise newException(IndexDefect, "CircSeq index out of bounds")
  if S.items.len == 0:
    raise newException(IndexDefect, "CircSeq index out of bounds")
  result = (S.head + i) mod S.items.len

proc `[]`*[T](S: CircSeq[T], i: int): T =
  ## S: circular sequence to read.
  ## i: logical index from oldest to newest.
  result = S.items[physicalIndex(S, i)]

proc `[]=`*[T](S: var CircSeq[T], i: int, value: T) =
  ## S: circular sequence to mutate.
  ## i: logical index from oldest to newest.
  ## value: replacement value.
  S.items[physicalIndex(S, i)] = value

proc clear*[T](S: var CircSeq[T]) =
  ## S: circular sequence to clear while retaining capacity.
  S.head = 0
  S.tail = 0
  S.count = 0

proc grow*[T](S: var CircSeq[T], newCapacity: int) =
  ## S: circular sequence to resize.
  ## newCapacity: new capacity; must fit existing values.
  var
    next: seq[T] = @[]
    i: int = 0
  if newCapacity < S.count:
    raise newException(ValueError, "CircSeq new capacity is smaller than length")
  if newCapacity < 0:
    raise newException(ValueError, "CircSeq capacity must not be negative")
  if newCapacity == S.items.len:
    return
  next = newSeq[T](newCapacity)
  while i < S.count:
    next[i] = S[i]
    i = i + 1
  S.items = next
  S.head = 0
  S.tail = S.count
  if S.items.len > 0:
    S.tail = S.tail mod S.items.len

proc ensureCapacity*[T](S: var CircSeq[T], wanted: int) =
  ## S: circular sequence to reserve.
  ## wanted: minimum capacity.
  var
    newCapacity: int = 0
  if wanted < 0:
    raise newException(ValueError, "CircSeq wanted capacity must not be negative")
  if wanted <= S.items.len:
    return
  newCapacity = S.items.len
  if newCapacity <= 0:
    newCapacity = defaultCircSeqCapacity
  while newCapacity < wanted:
    newCapacity = newCapacity * 2
  grow(S, newCapacity)

proc reserve*[T](S: var CircSeq[T], wanted: int) =
  ## S: circular sequence to reserve.
  ## wanted: minimum capacity.
  ensureCapacity(S, wanted)

proc push*[T](S: var CircSeq[T], value: T) =
  ## S: circular sequence to append to the newest end.
  ## value: value to append.
  ensureCapacity(S, S.count + 1)
  S.items[S.tail] = value
  S.tail = (S.tail + 1) mod S.items.len
  S.count = S.count + 1

proc tryPush*[T](S: var CircSeq[T], value: T): bool =
  ## S: circular sequence to append without growing.
  ## value: value to append.
  if S.items.len == 0 or S.count == S.items.len:
    return false
  S.items[S.tail] = value
  S.tail = (S.tail + 1) mod S.items.len
  S.count = S.count + 1
  result = true

proc peek*[T](S: CircSeq[T], value: var T): bool =
  ## S: circular sequence to inspect.
  ## value: receives the oldest value when present.
  if S.count == 0:
    return false
  value = S.items[S.head]
  result = true

proc peek*[T](S: CircSeq[T]): T =
  ## S: circular sequence to inspect.
  if S.count == 0:
    raise newException(IndexDefect, "CircSeq is empty")
  result = S.items[S.head]

proc pop*[T](S: var CircSeq[T], value: var T): bool =
  ## S: circular sequence to pop from the oldest end.
  ## value: receives the popped value when present.
  if S.count == 0:
    return false
  value = S.items[S.head]
  S.items[S.head] = default(T)
  S.head = (S.head + 1) mod S.items.len
  S.count = S.count - 1
  if S.count == 0:
    S.head = 0
    S.tail = 0
  result = true

proc pop*[T](S: var CircSeq[T]): T =
  ## S: circular sequence to pop from the oldest end.
  if not pop(S, result):
    raise newException(IndexDefect, "CircSeq is empty")

proc toSeq*[T](S: CircSeq[T]): seq[T] =
  ## S: circular sequence to copy in logical order.
  var
    i: int = 0
  result = newSeq[T](S.count)
  while i < S.count:
    result[i] = S[i]
    i = i + 1
