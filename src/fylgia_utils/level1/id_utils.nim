# ===============================================
# | Fylgia Utils Level1 - Id Helpers             |
# |---------------------------------------------|
# | Small ID helpers and a generic token type.   |
# ===============================================

import std/[hashes, times]

type
  IdToken* = distinct string

var
  gIdCounter: int = 0

proc nextCounter(): int =
  ## Increment and return the module counter for deterministic IDs.
  gIdCounter = gIdCounter + 1
  result = gIdCounter

proc idStamp*(): string =
  ## Build a compact timestamp component for IDs.
  let t0 = getTime().toUnix
  result = $t0

proc newId*(prefix: string): string =
  ## Create a deterministic ID with prefix, timestamp, and counter.
  let t0 = idStamp()
  let t1 = nextCounter()
  if prefix.len == 0:
    result = t0 & "_" & $t1
  else:
    result = prefix & "_" & t0 & "_" & $t1

proc resetIdCounter*() =
  ## Reset the internal ID counter (useful for tests).
  gIdCounter = 0

proc `$`*(id: IdToken): string =
  ## Convert an id token to string.
  result = string(id)

proc hash*(id: IdToken): Hash =
  ## Hash an id token for table keys.
  result = hash(string(id))

proc `==`*(a: IdToken; b: IdToken): bool =
  ## Compare two id tokens by value.
  result = string(a) == string(b)

proc toIdToken*(raw: string): IdToken =
  ## Wrap a string as an id token.
  result = IdToken(raw)

proc newIdToken*(prefix: string): IdToken =
  ## Allocate a new id token using the shared generator.
  result = IdToken(newId(prefix))
