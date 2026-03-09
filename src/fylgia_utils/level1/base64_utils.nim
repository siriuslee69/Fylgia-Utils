# ===============================================
# | Fylgia Utils Level1 - Base64 Helpers         |
# |---------------------------------------------|
# | Encoding helpers for byte payloads.          |
# ===============================================

import std/base64
import ./byte_utils

proc toBase64*(value: ByteSeq): string =
  ## Encode a byte sequence as base64 text.
  result = encode(value)

proc fromBase64*(value: string): ByteSeq =
  ## Decode base64 text into a byte sequence.
  if value.len == 0:
    return @[]
  result = stringToBytes(decode(value))
