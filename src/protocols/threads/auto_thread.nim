# ============================================================
# | Fylgia Auto Threader                                     |
# | -> hand it a list of jobs, it spreads them over the cores |
# ============================================================
#
# Three ways in, one engine underneath:
#
#   parallelMap(A, f)          f(A[0]), f(A[1]), ...   -> seq, in order
#   parallelRange(n, c, f)     f(c, 0), f(c, 1), ...   -> seq, in order
#   together:                  each line on its own thread
#     a = slowOne(x)
#     b = slowTwo(y)
#
# Def. 1: a *worker* is one thread taking jobs off a shared counter.
# The calling thread is always a worker too, so nothing sits idle
# waiting:
#
#     counter: 0 1 2 3 4 5 6 7 ...       <- one number per job
#               ▲   ▲     ▲
#     caller ───┘   │     │              each worker takes the next
#     worker 1 ─────┘     │              free number, runs that job,
#     worker 2 ───────────┘              and comes back for more
#
# A slow job therefore never holds up the quick ones behind it.
#
# Def. 2: the *budget* is how many threads may work at once, the
# caller included. It is shared by every call, so a `together` whose
# lines each call `parallelMap` does not start cores x cores threads:
#
#     budget 8 ── together (3 lines)   takes 2 extra  -> 5 left
#                 └─ parallelMap        takes up to 5  -> 0 left
#                    └─ parallelMap     takes 0, runs on its own thread
#
#     FYLGIA_THREADS=4    caps the budget at 4 (read once)
#     FYLGIA_THREADS=1    everything runs one job after another
#     setThreadLimit(n)   the same from code
#     -d:fylgiaNoThreads  no thread is ever started (small boards)
#     --threads:off       the same, chosen automatically
#
# ⚠ The promise a caller makes: the routine handed in only READS what
# it is given and writes only its own result. Reading one `seq` or
# `string` from many threads is safe. Two threads writing one shared
# variable is not, and neither is sharing a `ref` (its counter is not
# made for threads). The compiler is told to trust this promise, so
# it does not check it.
#
# ⚠ Starting a program (git, a compiler) from two threads at once is
# NOT safe with std/osproc: its pipes are made without close-on-exec,
# so a program started by one thread can be handed the other thread's
# pipe ends, and a reader then waits for an end that never comes. Run
# outside programs through `execCmdShared` instead of `execCmdEx`; it
# lets one through at a time, while the work around it stays parallel.
#
# A job that raises does not take the program down: every job still
# runs, and the first failure is raised again on the calling thread as
# a `ThreadJobError` naming the job.

import std/[atomics, locks, macros, os, osproc, strutils]
import runePragmas

const
  fylgiaSerial*: bool = defined(fylgiaNoThreads) or
    not compileOption("threads")
    ## true -> no thread is ever started; every job runs on the caller.

type
  ThreadJobError* = object of CatchableError
    ## A job raised. The message names the job and repeats its error.

  JobBoard {.role: truthState.} = object
    ## The counter every worker takes its next job from.
    run: proc(p: pointer, i: int) {.nimcall, gcsafe.}
    arg: pointer
    n: int
    next: Atomic[int]
    errors: ptr UncheckedArray[string]

  MapJob[T, R] {.role: preparedData.} = object
    ## parallelMap: where the items are, where the answers go.
    input: ptr UncheckedArray[T]
    output: ptr UncheckedArray[R]
    f: proc(x: T): R {.nimcall.}

  RangeJob[C, R] {.role: preparedData.} = object
    ## parallelRange: what every call is handed, where the answers go.
    ctx: ptr C
    output: ptr UncheckedArray[R]
    f: proc(c: C, i: int): R {.nimcall.}

  TogetherJob* {.role: preparedData.} = object
    ## One line of a `together` block. Built by the macro, not by hand.
    name*: string
    run*: proc() {.closure.}

when fylgiaSerial:
  type WorkerList = seq[int]
    ## no threads in this build; the list stays empty
else:
  type WorkerList = seq[Thread[ptr JobBoard]]
    ## the extra threads one call started

var
  limitNow: Atomic[int] = default(Atomic[int])
    ## the budget; 0 until it is first read
  busyNow: Atomic[int] = default(Atomic[int])
    ## extra threads alive right now, the callers not counted
  processGate: Lock
    ## held while an outside program runs; see `execCmdShared`

initLock(processGate)

# ---- the budget ------------------------------------------------------

proc setThreadLimit*(n: int) {.role: configurator, tag: "threads".} =
  ## n: how many threads may work at once, the caller included.
  ## Below 1 counts as 1, which runs everything one after another.
  limitNow.store(max(1, n))

proc threadLimit*(): int {.role: configurator, tag: "threads".} =
  ## The budget: FYLGIA_THREADS when set, else one per processor core.
  var
    t: int = limitNow.load()
  result = t
  if t > 0:
    return
  t = countProcessors()
  if existsEnv("FYLGIA_THREADS"):
    t = parseInt(getEnv("FYLGIA_THREADS").strip())
  setThreadLimit(t)
  result = limitNow.load()

proc reserve(k: int): int {.role: actor, tag: "threads".} =
  ## k: how many extra threads the caller would like.
  ## How many it may start; the rest of its jobs it runs itself.
  var
    busy: int = busyNow.load()
    got: int = 0
  result = 0
  while k > 0:
    got = clamp(threadLimit() - 1 - busy, 0, k)
    if busyNow.compareExchange(busy, busy + got):
      result = got
      return

proc release(k: int) {.role: actor, tag: "threads".} =
  ## k: threads that have finished and are handed back.
  discard busyNow.fetchSub(k)

# ---- the engine ------------------------------------------------------

proc runOne(B: ptr JobBoard, i: int) {.role: actor, tag: "threads".} =
  ## B: the board   i: the job to run. A failure is written into the
  ## job's own slot, so two failing jobs never write the same place.
  try:
    B.run(B.arg, i)
  except Exception as e:
    B.errors[i] = e.msg

proc work(B: ptr JobBoard) {.thread, role: actor, tag: "threads".} =
  ## B: the board. Takes the next free number until none is left.
  var
    i: int = B.next.fetchAdd(1)
  while i < B.n:
    runOne(B, i)
    i = B.next.fetchAdd(1)

proc runIndexed*(n: int, run: proc(p: pointer, i: int) {.nimcall, gcsafe.},
    arg: pointer): seq[string] {.role: orchestrator, tag: "threads".} =
  ## n: how many jobs   run: called once per job number, with `arg`.
  ## The error of every job, by number; "" for a job that went fine.
  ## The three ways in at the top of this file are built on this one.
  var
    board: JobBoard = JobBoard(run: run, arg: arg, n: n)
    workers: WorkerList = @[]
    extra: int = 0
    k: int = 0
  result = newSeq[string](n)
  if n == 0:
    return
  board.errors = cast[ptr UncheckedArray[string]](addr result[0])
  board.next.store(0)
  when not fylgiaSerial:
    extra = reserve(n - 1)
    workers.setLen(extra)
    while k < extra:
      createThread(workers[k], work, addr board)
      k = k + 1
  work(addr board)
  when not fylgiaSerial:
    joinThreads(workers)
    release(extra)

proc raiseFirst(E: seq[string], N: seq[string]) {.role: actor,
    tag: "threads".} =
  ## E: the errors by job   N: the job names (empty -> "job <i>").
  var
    i: int = 0
    name: string = ""
  while i < E.len:
    if E[i].len > 0:
      name = (if i < N.len: N[i] else: "job " & $i)
      raise newException(ThreadJobError, name & ": " & E[i])
    i = i + 1

# ---- way in 1: one call per item --------------------------------------

proc mapStep[T, R](p: pointer, i: int) {.nimcall, gcsafe.} =
  ## p: the MapJob   i: the item. Writes only answer slot i.
  var
    J: ptr MapJob[T, R] = cast[ptr MapJob[T, R]](p)
  {.cast(gcsafe).}:
    J.output[i] = J.f(J.input[i])

proc parallelMap*[T, R](A: openArray[T], f: proc(x: T): R {.nimcall.}):
    seq[R] {.role: orchestrator, tag: "threads".} =
  ## A: the items   f: what is done to one of them.
  ## f(A[0]), f(A[1]), ... worked out at once, answers in A's order.
  ##
  ##   proc lineCount(p: string): int = readFile(p).countLines()
  ##   var n: seq[int] = parallelMap(@["a.nim", "b.nim"], lineCount)
  var
    job: MapJob[T, R] = MapJob[T, R](f: f)
  result = newSeq[R](A.len)
  if A.len == 0:
    return
  job.input = cast[ptr UncheckedArray[T]](unsafeAddr A[0])
  job.output = cast[ptr UncheckedArray[R]](addr result[0])
  raiseFirst(runIndexed(A.len, mapStep[T, R], addr job), @[])

# ---- way in 2: one call per number -------------------------------------

proc rangeStep[C, R](p: pointer, i: int) {.nimcall, gcsafe.} =
  ## p: the RangeJob   i: the number. Writes only answer slot i.
  var
    J: ptr RangeJob[C, R] = cast[ptr RangeJob[C, R]](p)
  {.cast(gcsafe).}:
    J.output[i] = J.f(J.ctx[], i)

proc parallelRange*[C, R](n: int, c: C, f: proc(c: C, i: int): R {.nimcall.}):
    seq[R] {.role: orchestrator, tag: "threads".} =
  ## n: how many numbers   c: what every call is handed (not copied)
  ## f: the work for one number. Answers in order 0 ..< n.
  ##
  ## For work that needs more than the one item, like comparing every
  ## row against every later row:
  ##
  ##   proc pairsFrom(A: seq[int], i: int): int = ...   # row i vs i+1..
  ##   var counts: seq[int] = parallelRange(A.len, A, pairsFrom)
  var
    job: RangeJob[C, R] = RangeJob[C, R](ctx: unsafeAddr c, f: f)
  result = newSeq[R](n)
  if n <= 0:
    return
  job.output = cast[ptr UncheckedArray[R]](addr result[0])
  raiseFirst(runIndexed(n, rangeStep[C, R], addr job), @[])

# ---- way in 3: a block of independent lines ----------------------------

proc togetherStep(p: pointer, i: int) {.nimcall, gcsafe, role: actor,
    tag: "threads".} =
  ## p: the TogetherJob list   i: the line to run.
  var
    J: ptr UncheckedArray[TogetherJob] =
      cast[ptr UncheckedArray[TogetherJob]](p)
  {.cast(gcsafe).}:
    J[i].run()

proc runTogether*(J: var seq[TogetherJob]) {.role: orchestrator,
    tag: "threads".} =
  ## J: the lines of one `together` block. Returns when all are done.
  var
    names: seq[string] = @[]
  if J.len == 0:
    return
  for row in J:
    names.add(row.name)
  raiseFirst(runIndexed(J.len, togetherStep, addr J[0]), names)

proc swapResult(n: NimNode): NimNode {.compileTime, role: sanitizer,
    tag: "threads".} =
  ## n: the right-hand side of one line.
  ## Every `result` in it read through `togetherResult[]` instead,
  ## because a job cannot carry `result` itself to another thread:
  ##
  ##   result.b = g(result.a)   ->   togetherOut1[] = g(togetherResult[].a)
  ##
  ## Only a bare `result` is swapped; the field in `x.result` is not.
  if n.kind == nnkIdent and n.eqIdent("result"):
    result = newNimNode(nnkBracketExpr).add(ident("togetherResult"))
    return
  result = copyNimNode(n)
  if n.kind == nnkDotExpr:
    result.add(swapResult(n[0]), copyNimTree(n[1]))
    return
  for c in n:
    result.add(swapResult(c))

proc hasResult(n: NimNode): bool {.compileTime, role: parser,
    tag: "threads".} =
  ## n: one line of the block. Whether a bare `result` appears in it.
  result = n.kind == nnkIdent and n.eqIdent("result")
  for c in n:
    result = result or hasResult(c)

proc readSide(s: NimNode): NimNode {.compileTime, role: parser,
    tag: "threads".} =
  ## s: one line. What it reads: the right side of `a = f(x)`, or all
  ## of a plain call.
  result = s
  if s.kind == nnkAsgn:
    result = s[1]

proc togetherLine(s: NimNode, i: int): NimNode {.compileTime, role: parser,
    tag: "threads".} =
  ## s: one line of the block   i: its place.
  ## Turns `a = f(x)` into a job writing through a pointer to `a`,
  ## because the job runs on another thread and `result` cannot be
  ## carried there directly (see `swapResult` for the right side):
  ##
  ##   let togetherOut3 = addr(a)
  ##   togetherJobs.add(TogetherJob(name: "a = f(x)",
  ##     run: proc() = togetherOut3[] = f(x)))
  var
    outName: NimNode = ident("togetherOut" & $i)
    jobs: NimNode = ident("togetherJobs")
    name: NimNode = newLit(s.repr.strip())
    work: NimNode = s
  result = newStmtList()
  if s.kind == nnkAsgn:
    result.add(newLetStmt(outName, newCall(ident("addr"), s[0])))
    work = newAssignment(newNimNode(nnkBracketExpr).add(outName),
      swapResult(s[1]))
  elif s.kind notin {nnkCall, nnkCommand, nnkDiscardStmt}:
    error("together: each line must be `a = f(...)` or a call", s)
  else:
    work = swapResult(s)
  result.add(quote do:
    `jobs`.add(TogetherJob(name: `name`, run: proc() {.closure.} = `work`)))

macro together*(body: untyped): untyped {.role: orchestrator,
    tag: "threads".} =
  ## body: lines that do not depend on one another.
  ## Every line runs at once; the block ends when the last one does.
  ##
  ##   together:
  ##     result.shape = shapeReport(src, dir)
  ##     result.secrets = secretsOf(dir, files)
  ##     writeLog(dir)
  ##
  ## A line may read anything above the block, but must not read what
  ## another line of the same block writes.
  var
    jobs: NimNode = ident("togetherJobs")
    lines: NimNode = newStmtList()
    i: int = 0
    needResult: bool = false
  for s in body:
    needResult = needResult or hasResult(readSide(s))
  if needResult:
    lines.add(newVarStmt(ident("togetherResult"),
      newCall(ident("addr"), ident("result"))))
  for s in body:
    lines.add(togetherLine(s, i))
    i = i + 1
  result = quote do:
    block:
      var `jobs`: seq[TogetherJob] = @[]
      `lines`
      runTogether(`jobs`)

# ---- outside programs ------------------------------------------------

proc execCmdShared*(command: string, options: set[ProcessOption] = {
    poStdErrToStdOut, poUsePath}, workingDir: string = ""):
    tuple[output: string, exitCode: int] {.role: dataFetcher,
    tag: "threads".} =
  ## command: the whole command line   options, workingDir: as for
  ## `execCmdEx`. The same answer `execCmdEx` gives, but only one
  ## outside program runs at a time across every thread:
  ##
  ##   thread A  ── git log ──┐                 waits ── git ls-tree ──
  ##   thread B        waits  └── git ls-tree ──┘
  ##
  ## std/osproc hands every pipe it makes to every program started
  ## while that pipe is open, so two at once can leave a reader waiting
  ## forever for the end of an answer. One at a time cannot.
  result = (output: "", exitCode: 0)
  {.cast(gcsafe).}:
    withLock processGate:
      result = execCmdEx(command, options, workingDir = workingDir)
