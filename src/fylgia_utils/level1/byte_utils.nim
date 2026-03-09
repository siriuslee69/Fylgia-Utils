# ===============================================
# | Fylgia Utils Level1 - Byte Helpers           |
# |---------------------------------------------|
# | Basic byte/string conversions and utilities.|
# ===============================================

import std/strutils

type
  ByteSeq* = seq[byte]

proc stringToBytes*(value: string): ByteSeq =
  ## Convert a string to raw bytes without encoding changes.
  var
    bs: ByteSeq = @[]
    i: int = 0
  bs.setLen(value.len)
  i = 0
  while i < value.len:
    bs[i] = uint8(ord(value[i]))
    i = i + 1
  result = bs

proc bytesToString*(value: ByteSeq): string =
  ## Convert raw bytes into a string without decoding changes.
  var
    s: string = ""
    i: int = 0
  s = newString(value.len)
  i = 0
  while i < value.len:
    s[i] = char(value[i])
    i = i + 1
  result = s

proc copyBytes*(value: ByteSeq): ByteSeq =
  ## Return a shallow copy of a byte sequence.
  var
    outSeq: ByteSeq = @[]
    i: int = 0
  outSeq.setLen(value.len)
  i = 0
  while i < value.len:
    outSeq[i] = value[i]
    i = i + 1
  result = outSeq

proc splitLinesBytes*(value: ByteSeq): seq[string] =
  ## Convert bytes to string and split into trimmed lines.
  let s0 = bytesToString(value)
  result = s0.splitLines
