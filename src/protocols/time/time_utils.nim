# ===========================================
# | Fylgia Utils - Time Helpers              |
# |-----------------------------------------|
# | Normalize timestamps and formatting.     |
# ===========================================

import std/times
import runePragmas

proc nowUtc*(): DateTime {.role: dataFetcher.} =
  ## Return the current UTC time.
  result = now().utc

proc epochSeconds*(): int64 {.role: dataFetcher.} =
  ## Return the current UTC epoch time in seconds.
  result = getTime().toUnix

proc isoTimestamp*(): string {.role: helper.} =
  ## Return an ISO-8601 timestamp string in UTC.
  var
    t0: DateTime = nowUtc()
  result = t0.format("yyyy-MM-dd'T'HH:mm:ss'Z'")
