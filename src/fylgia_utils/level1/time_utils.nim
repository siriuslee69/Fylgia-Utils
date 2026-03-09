# ===============================================
# | Fylgia Utils Level1 - Time Helpers           |
# |---------------------------------------------|
# | Normalize timestamps and formatting.         |
# ===============================================

import std/times

proc nowUtc*(): DateTime =
  ## Return the current UTC time.
  result = now().utc

proc epochSeconds*(): int64 =
  ## Return the current UTC epoch time in seconds.
  result = getTime().toUnix

proc isoTimestamp*(): string =
  ## Return an ISO-8601 timestamp string in UTC.
  let t0 = nowUtc()
  result = t0.format("yyyy-MM-dd'T'HH:mm:ss'Z'")
