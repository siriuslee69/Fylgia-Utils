# ===========================================
# | Fylgia Utils - Id Helpers                |
# |-----------------------------------------|
# | Small ID helpers and a generic token type.|
# ===========================================

import std/[hashes, times]
import runePragmas

type
  IdToken* = distinct string

var
  gIdCounter: int = 0

proc nextCounter(): int {.role: helper.} =
  ## Increment and return the module counter for deterministic IDs.
  gIdCounter = gIdCounter + 1
  result = gIdCounter

proc idStamp*(): string {.role: helper.} =
  ## Build a compact timestamp component for IDs.
  var
    t0: int64 = 0
  t0 = getTime().toUnix
  result = $t0

proc newId*(prefix: string): string {.role: helper.} =
  ## Create a deterministic ID with prefix, timestamp, and counter.
  var
    t0: string = ""
    t1: int = 0
  t0 = idStamp()
  t1 = nextCounter()
  if prefix.len == 0:
    result = t0 & "_" & $t1
  else:
    result = prefix & "_" & t0 & "_" & $t1

proc resetIdCounter*(): void {.role: helper.} =
  ## Reset the internal ID counter (useful for tests).
  gIdCounter = 0

proc `$`*(id: IdToken): string {.role: helper.} =
  ## Convert an id token to string.
  result = string(id)

proc hash*(id: IdToken): Hash {.role: helper.} =
  ## Hash an id token for table keys.
  result = hash(string(id))

proc `==`*(a: IdToken; b: IdToken): bool {.role: helper.} =
  ## Compare two id tokens by value.
  result = string(a) == string(b)

proc toIdToken*(raw: string): IdToken {.role: helper.} =
  ## Wrap a string as an id token.
  result = IdToken(raw)

proc newIdToken*(prefix: string): IdToken {.role: helper.} =
  ## Allocate a new id token using the shared generator.
  result = IdToken(newId(prefix))
