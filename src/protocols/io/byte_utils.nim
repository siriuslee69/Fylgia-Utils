# ===========================================
# | Fylgia Utils - Byte Helpers              |
# |-----------------------------------------|
# | Basic byte/string conversions and tools.|
# ===========================================

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

proc appendU16Le*(bs: var ByteSeq, v: uint16) =
  ## Append a uint16 in little-endian order.
  var
    b0: uint8 = 0
    b1: uint8 = 0
  b0 = uint8(v and 0xff'u16)
  b1 = uint8((v shr 8) and 0xff'u16)
  bs.add(b0)
  bs.add(b1)

proc appendU32Le*(bs: var ByteSeq, v: uint32) =
  ## Append a uint32 in little-endian order.
  var
    b0: uint8 = 0
    b1: uint8 = 0
    b2: uint8 = 0
    b3: uint8 = 0
  b0 = uint8(v and 0xff'u32)
  b1 = uint8((v shr 8) and 0xff'u32)
  b2 = uint8((v shr 16) and 0xff'u32)
  b3 = uint8((v shr 24) and 0xff'u32)
  bs.add(b0)
  bs.add(b1)
  bs.add(b2)
  bs.add(b3)

proc appendU64Le*(bs: var ByteSeq, v: uint64) =
  ## Append a uint64 in little-endian order.
  var
    t: uint64 = v
    shift: int = 0
  while shift < 64:
    bs.add(uint8(t and 0xff'u64))
    t = t shr 8
    shift = shift + 8

proc appendBytes*(bs: var ByteSeq, A: openArray[byte]) =
  ## Append raw bytes from an open array.
  var
    i: int = 0
  while i < A.len:
    bs.add(A[i])
    i = i + 1

proc appendLabel*(bs: var ByteSeq, s: string) =
  ## Append an ASCII label prefixed by its uint32 little-endian length.
  var
    i: int = 0
  appendU32Le(bs, uint32(s.len))
  while i < s.len:
    bs.add(uint8(ord(s[i])))
    i = i + 1
