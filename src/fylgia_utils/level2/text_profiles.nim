# ===============================================
# | Fylgia Utils Level2 - Text Profiles          |
# |---------------------------------------------|
# | Generic string and numeric limit helpers.    |
# ===============================================

import ../level1/text_validation

type
  LengthLimit* = object
    ## Generic length bounds for string validation.
    minLen*: int
    maxLen*: int

  RangeLimit* = object
    ## Generic integer bounds for range validation.
    minValue*: int
    maxValue*: int

proc makeLengthLimit*(minLen: int; maxLen: int): LengthLimit =
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

proc makeRangeLimit*(minValue: int; maxValue: int): RangeLimit =
  ## Build a safe range limit with ordered bounds.
  var
    min0: int = minValue
    max0: int = maxValue
  if max0 < min0:
    max0 = min0
  result = RangeLimit(minValue: min0, maxValue: max0)

proc clampToLimit*(value: string; limit: LengthLimit): string =
  ## Clamp a string to the max length of a limit.
  result = clampText(value, limit.maxLen)

proc ensureLengthLimit*(value: string; limit: LengthLimit; label: string = "value";
    allowBlank: bool = false): tuple[ok: bool, reason: string] =
  ## Validate a string against a length limit.
  if value.len == 0:
    if allowBlank:
      return (true, "")
    return (false, label & " is blank")
  let t0 = ensureLength(value, limit.maxLen)
  if not t0.ok:
    result = t0
    return
  let t1 = ensureMinLength(value, limit.minLen)
  if not t1.ok:
    result = t1
    return
  result = (true, "")

proc clampInt*(value: int; limit: RangeLimit): int =
  ## Clamp an integer to the range bounds.
  if value < limit.minValue:
    return limit.minValue
  if value > limit.maxValue:
    return limit.maxValue
  result = value

proc ensureRange*(value: int; limit: RangeLimit; label: string = "value"): tuple[ok: bool, reason: string] =
  ## Validate that a value fits inside the range bounds.
  if value < limit.minValue:
    return (false, label & " too small")
  if value > limit.maxValue:
    return (false, label & " too large")
  result = (true, "")
