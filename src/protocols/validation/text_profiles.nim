# ===========================================
# | Fylgia Utils - Text Profiles             |
# |-----------------------------------------|
# | Generic string and numeric limit helpers.|
# ===========================================

import ./text_validation
import runePragmas

type
  LengthLimit* = object
    ## Generic length bounds for string validation.
    minLen*: int
    maxLen*: int

  RangeLimit* = object
    ## Generic integer bounds for range validation.
    minValue*: int
    maxValue*: int

proc makeLengthLimit*(minLen: int; maxLen: int): LengthLimit {.role: configurator.} =
  ## Build a safe length limit with non-negative bounds.
  var
    min0: int = minLen
    max0: int = maxLen
  if min0 < 0:
    min0 = 0
  if max0 < 0:
    max0 = 0
  if max0 < min0:
    max0 = min0
  result = LengthLimit(minLen: min0, maxLen: max0)

proc makeRangeLimit*(minValue: int; maxValue: int): RangeLimit {.role: configurator.} =
  ## Build a safe range limit with ordered bounds.
  var
    min0: int = minValue
    max0: int = maxValue
  if max0 < min0:
    max0 = min0
  result = RangeLimit(minValue: min0, maxValue: max0)

proc clampToLimit*(value: string; limit: LengthLimit): string {.role: sanitizer.} =
  ## Clamp a string to the max length of a limit.
  result = clampText(value, limit.maxLen)

proc ensureLengthLimit*(value: string; limit: LengthLimit; label: string = "value";
    allowBlank: bool = false): tuple[ok: bool, reason: string] {.role: parser.} =
  ## Validate a string against a length limit.
  var
    t0: tuple[ok: bool, reason: string] = (false, "")
    t1: tuple[ok: bool, reason: string] = (false, "")
  if value.len == 0:
    if allowBlank:
      result = (true, "")
    else:
      result = (false, label & " is blank")
    return
  t0 = ensureLength(value, limit.maxLen)
  if not t0.ok:
    result = t0
    return
  t1 = ensureMinLength(value, limit.minLen)
  if not t1.ok:
    result = t1
    return
  result = (true, "")

proc clampInt*(value: int; limit: RangeLimit): int {.role: sanitizer.} =
  ## Clamp an integer to the range bounds.
  result = value
  if value < limit.minValue:
    result = limit.minValue
  elif value > limit.maxValue:
    result = limit.maxValue

proc ensureRange*(value: int; limit: RangeLimit; label: string = "value"): tuple[ok: bool, reason: string] {.role: parser.} =
  ## Validate that a value fits inside the range bounds.
  if value < limit.minValue:
    result = (false, label & " too small")
  elif value > limit.maxValue:
    result = (false, label & " too large")
  else:
    result = (true, "")
