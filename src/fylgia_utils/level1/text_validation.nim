# ===============================================
# | Fylgia Utils Level1 - Text Validation        |
# |---------------------------------------------|
# | Reusable string validation helpers.          |
# ===============================================

import std/strutils

proc isBlank*(value: string): bool =
  ## Return true when the string is empty or whitespace.
  result = value.strip().len == 0

proc clampText*(value: string; maxLen: int): string =
  ## Clamp a string to maxLen characters without trimming whitespace.
  if value.len <= maxLen:
    result = value
  else:
    result = value[0 ..< maxLen]

proc ensureLength*(value: string; maxLen: int): tuple[ok: bool, reason: string] =
  ## Validate length without trimming input.
  if value.len <= maxLen:
    result = (true, "")
  else:
    result = (false, "too long")

proc ensureMinLength*(value: string; minLen: int): tuple[ok: bool, reason: string] =
  ## Validate a minimum length constraint.
  if value.len >= minLen:
    result = (true, "")
  else:
    result = (false, "too short")

proc ensureNotBlank*(value: string; label: string): tuple[ok: bool, reason: string] =
  ## Validate a non-empty string and return an error label.
  if isBlank(value):
    result = (false, label & " is blank")
  else:
    result = (true, "")

proc ensureAsciiWord*(value: string; label: string): tuple[ok: bool, reason: string] =
  ## Validate that a string only contains ASCII letters, digits, '_' or '-'.
  var
    i: int = 0
  if value.len == 0:
    return (false, label & " is blank")
  i = 0
  while i < value.len:
    let ch = value[i]
    if not (ch.isAlphaNumeric or ch == '_' or ch == '-'):
      return (false, label & " contains invalid characters")
    i = i + 1
  result = (true, "")
