# ===========================================
# | Fylgia Utils - Base64 Helpers            |
# |-----------------------------------------|
# | Encoding helpers for byte payloads.      |
# ===========================================

import std/base64
import runePragmas
import ./byte_utils

proc toBase64*(value: ByteSeq): string {.role: helper.} =
  ## Encode a byte sequence as base64 text.
  result = encode(value)

proc fromBase64*(value: string): ByteSeq {.role: helper.} =
  ## Decode base64 text into a byte sequence.
  if value.len == 0:
    result = @[]
  else:
    result = stringToBytes(decode(value))
