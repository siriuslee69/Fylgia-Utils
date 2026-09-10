## ==============================================================
## | vector_space.nim  <-  things placed near things like them  |
## |------------------------------------------------------------|
## | This file knows nothing about code, files or repositories.  |
## | It only knows how to take a list of measurements about a    |
## | thing and place that thing in a room, so that two things    |
## | measured alike end up standing next to each other.          |
## |                                                             |
## | The idea in one picture. Say we measure two things about    |
## | every routine: how many loops it has, and how long it is.   |
## | Then every routine is a dot on a sheet of paper:            |
## |                                                             |
## |     loops                                                   |
## |       ^                                                     |
## |     3 |        d                                            |
## |     2 |   a b        e                                      |
## |     1 |   c                                                 |
## |       +---------------------> length                        |
## |                                                             |
## | `a` and `b` sit almost on top of each other, so whatever    |
## | they are, they are the same shape of thing. `e` stands      |
## | alone. That closeness is the whole point of this file.      |
## |                                                             |
## | Three words used throughout, defined once here:             |
## |                                                             |
## |   dimension   one thing we measured (for example "loops")   |
## |   vector      one thing's full list of measurements         |
## |   distance    how far apart two such lists are              |
## |                                                             |
## | Distance is turned into a plain 0..1 closeness at the end,  |
## | because "0.87 alike" is something a person can read and     |
## | a chart can draw, and "3.2 units apart" is not.             |
## ==============================================================

import std/[algorithm, math, strutils]

type
  FeatureVector* = object
    ## One thing, and everything measured about it.
    ##
    ##   values  one number per dimension, in the space's dim order
    id*: string
    label*: string
    values*: seq[float]

  VectorSpace* = object
    ## The room every thing is placed in.
    ##
    ##   dims    the name of each measurement, in order
    ##   lo, hi  the smallest and largest value seen per dimension,
    ##           filled in by `rescale`. They are what lets a count of
    ##           loops (0..4) and a line count (0..800) be compared
    ##           without the line count drowning out the loops.
    dims*: seq[string]
    points*: seq[FeatureVector]
    lo*: seq[float]
    hi*: seq[float]
    scaled*: bool

  Neighbour* = object
    ## One thing found near another, and how near.
    ##
    ##   closeness  1.0 is the same spot, 0.0 is the far side of the
    ##              room. This is the number to show a person.
    id*: string
    label*: string
    distance*: float
    closeness*: float

  CloudNode* = object
    ## One clump in the point cloud.
    ##
    ## A thing may belong to several clumps at once when it sits in
    ## the overlap between them, which is on purpose: a routine that
    ## is half parser and half helper should show up under both.
    ##
    ##   centre    the middle of the clump, one number per dimension
    ##   x, y      where to draw it on a flat screen
    ##   radius    how far out members were gathered from
    id*: string
    label*: string
    centre*: seq[float]
    memberIds*: seq[string]
    x*: float
    y*: float
    radius*: float

const
  closenessHalf*: float = 0.35
    ## The distance at which two things read as half alike. Distances
    ## here run 0..1 after rescaling, so a third of the room apart is
    ## already only a faint resemblance.
  minSpan*: float = 0.000001
    ## A dimension where everything scored the same is treated as one
    ## flat line rather than being divided by zero.

proc newVectorSpace*(D: openArray[string]): VectorSpace =
  ## D <- the name of each measurement, in the order the values come.
  result = VectorSpace(dims: @[], points: @[], lo: @[], hi: @[],
    scaled: false)
  for name in D:
    result.dims.add(name)

proc addPoint*(S: var VectorSpace, id, label: string,
    V: openArray[float]) =
  ## S <- the room being filled   V <- one thing's measurements
  ##
  ## A short list is padded with zeroes and a long one is cut, so one
  ## miscounted dimension cannot corrupt the whole room.
  var
    row: FeatureVector = FeatureVector(id: id, label: label, values: @[])
    i: int = 0
  while i < S.dims.len:
    if i < V.len:
      row.values.add(V[i])
    else:
      row.values.add(0.0)
    i = i + 1
  S.points.add(row)
  S.scaled = false

proc rescale*(S: var VectorSpace) =
  ## S <- the room, with every dimension squeezed into 0..1.
  ##
  ## Without this a dimension that happens to be counted in hundreds
  ## decides everything and a dimension counted in ones is ignored.
  ## After it, every dimension gets an equal say.
  var
    i: int = 0
    j: int = 0
    span: float = 0.0
  S.lo = @[]
  S.hi = @[]
  while i < S.dims.len:
    S.lo.add(0.0)
    S.hi.add(0.0)
    i = i + 1
  if S.points.len == 0:
    S.scaled = true
    return
  i = 0
  while i < S.dims.len:
    S.lo[i] = S.points[0].values[i]
    S.hi[i] = S.points[0].values[i]
    i = i + 1
  j = 1
  while j < S.points.len:
    i = 0
    while i < S.dims.len:
      S.lo[i] = min(S.lo[i], S.points[j].values[i])
      S.hi[i] = max(S.hi[i], S.points[j].values[i])
      i = i + 1
    j = j + 1
  j = 0
  while j < S.points.len:
    i = 0
    while i < S.dims.len:
      span = S.hi[i] - S.lo[i]
      if span < minSpan:
        S.points[j].values[i] = 0.0
      else:
        S.points[j].values[i] = (S.points[j].values[i] - S.lo[i]) / span
      i = i + 1
    j = j + 1
  S.scaled = true

proc distance*(a, b: FeatureVector): float =
  ## a, b <- two things. Straight-line distance between them, the same
  ## way a ruler measures across a sheet of paper, only in as many
  ## directions as there are dimensions.
  var
    t: float = 0.0
    d: float = 0.0
    i: int = 0
    n: int = min(a.values.len, b.values.len)
  while i < n:
    d = a.values[i] - b.values[i]
    t = t + d * d
    i = i + 1
  result = sqrt(t)

proc cosineLikeness*(a, b: FeatureVector): float =
  ## a, b <- two things. How alike their *shape* is, ignoring size:
  ## a short routine and a long one built the same way score high.
  ## 1.0 is the same shape, 0.0 is nothing in common.
  var
    dot: float = 0.0
    na: float = 0.0
    nb: float = 0.0
    i: int = 0
    n: int = min(a.values.len, b.values.len)
  while i < n:
    dot = dot + a.values[i] * b.values[i]
    na = na + a.values[i] * a.values[i]
    nb = nb + b.values[i] * b.values[i]
    i = i + 1
  result = 0.0
  if na <= 0.0 or nb <= 0.0:
    return
  result = dot / (sqrt(na) * sqrt(nb))
  if result < 0.0:
    result = 0.0

proc closenessOf*(d: float, half: float = closenessHalf): float =
  ## d <- a distance   half <- the distance that should read as 0.5
  ##
  ## Turns a distance into a 0..1 number that behaves like a chance:
  ## right on top of each other is 1.0, and it falls away smoothly
  ## rather than stopping dead at some cut-off.
  ##
  ##   1.0 |*
  ##       |  *
  ##   0.5 |     *
  ##       |         *  *
  ##   0.0 +----------------*---> distance
  ##             half
  var
    h: float = half
  if h < minSpan:
    h = closenessHalf
  result = pow(0.5, d / h)

proc likeness*(a, b: FeatureVector, half: float = closenessHalf): float =
  ## a, b <- two things. Their distance read straight as a 0..1 number.
  result = closenessOf(distance(a, b), half)

proc indexOf*(S: VectorSpace, id: string): int =
  ## S <- the room   id <- the thing wanted. -1 when it is not there.
  result = -1
  var
    i: int = 0
  while i < S.points.len:
    if S.points[i].id == id:
      result = i
      return
    i = i + 1

proc byCloseness(a, b: Neighbour): int =
  ## a, b <- two neighbours, nearest first.
  result = cmp(a.distance, b.distance)
  if result == 0:
    result = cmp(a.id, b.id)

proc neighboursOf*(S: VectorSpace, id: string, n: int = 8,
    floor: float = 0.0, half: float = closenessHalf): seq[Neighbour] =
  ## S <- the room   id <- the thing to look around
  ## n <- how many to bring back   floor <- ignore anything less alike
  ##
  ## The thing itself is never returned as its own neighbour.
  var
    A: seq[Neighbour] = @[]
    at: int = indexOf(S, id)
    d: float = 0.0
    c: float = 0.0
    i: int = 0
  result = @[]
  if at < 0:
    return
  while i < S.points.len:
    if i == at:
      i = i + 1
      continue
    d = distance(S.points[at], S.points[i])
    c = closenessOf(d, half)
    if c >= floor:
      A.add(Neighbour(id: S.points[i].id, label: S.points[i].label,
        distance: d, closeness: c))
    i = i + 1
  A.sort(byCloseness)
  if A.len > n:
    A.setLen(n)
  result = A

proc centreOf*(S: VectorSpace, A: openArray[int]): seq[float] =
  ## S <- the room   A <- which points belong together
  ## The middle of those points, one number per dimension.
  var
    i: int = 0
    j: int = 0
  result = @[]
  while i < S.dims.len:
    result.add(0.0)
    i = i + 1
  if A.len == 0:
    return
  for at in A:
    j = 0
    while j < S.dims.len:
      result[j] = result[j] + S.points[at].values[j]
      j = j + 1
  j = 0
  while j < S.dims.len:
    result[j] = result[j] / A.len.float
    j = j + 1

proc spreadOf*(S: VectorSpace, i: int): float =
  ## S <- the room   i <- one dimension
  ## How widely the things are spread along that one measurement.
  ## A dimension where everyone scores alike tells us nothing and
  ## comes back near zero.
  var
    mean: float = 0.0
    t: float = 0.0
    d: float = 0.0
    j: int = 0
  result = 0.0
  if S.points.len < 2 or i < 0 or i >= S.dims.len:
    return
  while j < S.points.len:
    mean = mean + S.points[j].values[i]
    j = j + 1
  mean = mean / S.points.len.float
  j = 0
  while j < S.points.len:
    d = S.points[j].values[i] - mean
    t = t + d * d
    j = j + 1
  result = sqrt(t / S.points.len.float)

proc dominantAxis*(S: VectorSpace, skip: int): int =
  ## S <- the room   skip <- an axis already used, or -1
  ## The dimension along which the things differ most. That is the
  ## most informative direction to draw, because it is the one that
  ## actually tells the things apart.
  var
    best: float = -1.0
    v: float = 0.0
    i: int = 0
  result = 0
  while i < S.dims.len:
    if i != skip:
      v = spreadOf(S, i)
      if v > best:
        best = v
        result = i
    i = i + 1

proc flatten*(S: VectorSpace): seq[array[2, float]] =
  ## S <- the room. Where to draw each thing on a flat screen, 0..1.
  ##
  ## A screen has two directions and the room has many, so two have
  ## to be chosen. The two picked are the two along which the things
  ## differ most, which keeps apart on screen the things that are
  ## genuinely apart. Everything else is folded in gently so that two
  ## things alike in the two drawn dimensions but different in the
  ## rest do not land exactly on top of one another.
  var
    ax: int = 0
    ay: int = 0
    x: float = 0.0
    y: float = 0.0
    nudge: float = 0.0
    i: int = 0
    j: int = 0
  result = @[]
  if S.points.len == 0 or S.dims.len == 0:
    return
  ax = dominantAxis(S, -1)
  ay = dominantAxis(S, ax)
  while i < S.points.len:
    x = S.points[i].values[ax]
    y = S.points[i].values[ay]
    nudge = 0.0
    j = 0
    while j < S.dims.len:
      if j != ax and j != ay:
        nudge = nudge + S.points[i].values[j]
      j = j + 1
    if S.dims.len > 2:
      nudge = nudge / (S.dims.len - 2).float
      x = x * 0.88 + nudge * 0.12
      y = y * 0.88 + (1.0 - nudge) * 0.12
    result.add([clamp(x, 0.0, 1.0), clamp(y, 0.0, 1.0)])
    i = i + 1

proc cloudNodes*(S: VectorSpace, radius: float = 0.28,
    minMembers: int = 2): seq[CloudNode] =
  ## S <- the room   radius <- how far a clump reaches
  ## minMembers <- a clump smaller than this is not worth a node
  ##
  ## Clumps are grown greedily: the thing with the most neighbours
  ## within reach starts a node and pulls them all in, then the next
  ## busiest spot that is not already the middle of a node does the
  ## same. A thing is *not* removed when it joins a node, so a thing
  ## sitting between two clumps ends up listed under both:
  ##
  ##       ( node A )
  ##          o o o
  ##            o x o          <- x belongs to A and to B
  ##             o o o
  ##          ( node B )
  var
    flat: seq[array[2, float]] = @[]
    used: seq[bool] = @[]
    counts: seq[int] = @[]
    members: seq[int] = @[]
    centres: seq[int] = @[]
    best: int = 0
    bestN: int = 0
    i: int = 0
    j: int = 0
    rounds: int = 0
  result = @[]
  if S.points.len == 0:
    return
  flat = flatten(S)
  while i < S.points.len:
    used.add(false)
    counts.add(0)
    i = i + 1
  rounds = 0
  while rounds < S.points.len:
    i = 0
    while i < S.points.len:
      counts[i] = 0
      if not used[i]:
        j = 0
        while j < S.points.len:
          if distance(S.points[i], S.points[j]) <= radius:
            counts[i] = counts[i] + 1
          j = j + 1
      i = i + 1
    best = -1
    bestN = minMembers - 1
    i = 0
    while i < S.points.len:
      if counts[i] > bestN:
        bestN = counts[i]
        best = i
      i = i + 1
    if best < 0:
      break
    members = @[]
    j = 0
    while j < S.points.len:
      if distance(S.points[best], S.points[j]) <= radius:
        members.add(j)
      j = j + 1
    centres.add(best)
    # Everything pulled into this clump stops being a candidate for
    # *starting* another one, or the same clump would be found again
    # from its neighbour's point of view. Being pulled into a later
    # clump as a member is still allowed, which is what lets a thing
    # sit in two clumps at once.
    for at in members:
      used[at] = true
    result.add(CloudNode(id: "cloud-" & $result.len,
      label: S.points[best].label, centre: centreOf(S, members),
      memberIds: @[], x: flat[best][0], y: flat[best][1],
      radius: radius))
    for at in members:
      result[^1].memberIds.add(S.points[at].id)
    rounds = rounds + 1

proc dimReport*(S: VectorSpace): seq[string] =
  ## S <- the room. One readable line per dimension saying what range
  ## it covered, for a person checking that a measurement is sane.
  var
    i: int = 0
  result = @[]
  while i < S.dims.len:
    if i < S.lo.len and i < S.hi.len:
      result.add(S.dims[i] & ": " & formatFloat(S.lo[i], ffDecimal, 2) &
        " .. " & formatFloat(S.hi[i], ffDecimal, 2))
    i = i + 1
