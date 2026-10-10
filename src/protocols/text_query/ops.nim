## --------------------------------------------
## Text Query Ops <- reusable boolean parser
## --------------------------------------------

import std/[strutils]
import runePragmas

import ./types

proc isIdentChar(c: char): bool {.role: helper.} =
  result = c.isAlphaNumeric or c in {'_', '-', '.', '/', '\\', ':'}

proc decodeQuoted(source: string, startIdx: int): tuple[ok: bool, value: string, nextIdx: int, err: string] {.role: parser.} =
  var
    i: int = startIdx + 1
    escaped: bool = false
    buffer: string = ""
  while i < source.len:
    if escaped:
      case source[i]
      of 'n':
        buffer.add('\n')
      of 'r':
        buffer.add('\r')
      of 't':
        buffer.add('\t')
      else:
        buffer.add(source[i])
      escaped = false
      i.inc
      continue
    if source[i] == '\\':
      escaped = true
      i.inc
      continue
    if source[i] == '"':
      result = (true, buffer, i + 1, "")
      return
    buffer.add(source[i])
    i.inc
  result = (false, "", source.len, "unterminated quoted text query term")

proc tokenizeTextQuery*(source: string): tuple[ok: bool, tokens: seq[TextQueryToken], err: string] {.role: parser.} =
  var
    i: int = 0
    start: int = 0
    raw: string = ""
    quoted: tuple[ok: bool, value: string, nextIdx: int, err: string] = (false, "", 0, "")
    upper: string = ""
  while i < source.len:
    if source[i].isSpaceAscii:
      i.inc
      continue
    case source[i]
    of '(':
      result.tokens.add(TextQueryToken(kind: tqtLParen, value: "(", offset: i))
      i.inc
    of ')':
      result.tokens.add(TextQueryToken(kind: tqtRParen, value: ")", offset: i))
      i.inc
    of '"':
      quoted = decodeQuoted(source, i)
      if not quoted.ok:
        result = (false, @[], quoted.err)
        return
      result.tokens.add(TextQueryToken(kind: tqtTerm, value: quoted.value, offset: i))
      i = quoted.nextIdx
    else:
      if not isIdentChar(source[i]):
        result = (false, @[], "unexpected character in text query at offset " & $i & ": " & $source[i])
        return
      start = i
      while i < source.len and isIdentChar(source[i]):
        i.inc
      raw = source[start ..< i]
      upper = raw.toUpperAscii()
      case upper
      of "AND":
        result.tokens.add(TextQueryToken(kind: tqtAnd, value: raw, offset: start))
      of "OR":
        result.tokens.add(TextQueryToken(kind: tqtOr, value: raw, offset: start))
      of "NOT":
        result.tokens.add(TextQueryToken(kind: tqtNot, value: raw, offset: start))
      else:
        result.tokens.add(TextQueryToken(kind: tqtTerm, value: raw, offset: start))
  result.tokens.add(TextQueryToken(kind: tqtEof, value: "", offset: source.len))
  result.ok = true

proc parseOrExpr(tokens: seq[TextQueryToken], pos: var int): tuple[ok: bool, node: TextQueryNode, err: string] {.role: parser.}
proc parsePrimary(tokens: seq[TextQueryToken], pos: var int): tuple[ok: bool, node: TextQueryNode, err: string] {.role: parser.}

proc parsePrimary(tokens: seq[TextQueryToken], pos: var int): tuple[ok: bool, node: TextQueryNode, err: string] {.role: parser.} =
  var
    inner: tuple[ok: bool, node: TextQueryNode, err: string] = (false, nil, "")
  if pos >= tokens.len:
    result = (false, nil, "unexpected end of text query")
    return
  case tokens[pos].kind
  of tqtTerm:
    result = (true, TextQueryNode(kind: tqnTerm, term: tokens[pos].value), "")
    pos.inc
  of tqtLParen:
    pos.inc
    inner = parseOrExpr(tokens, pos)
    if not inner.ok:
      result = inner
      return
    if pos >= tokens.len or tokens[pos].kind != tqtRParen:
      result = (false, nil, "missing closing ')' in text query")
      return
    pos.inc
    result = inner
  of tqtNot:
    pos.inc
    inner = parsePrimary(tokens, pos)
    if not inner.ok:
      result = inner
      return
    result = (true, TextQueryNode(kind: tqnNot, left: inner.node), "")
  else:
    result = (false, nil, "unexpected token in text query near offset " & $tokens[pos].offset)

proc parseFactor(tokens: seq[TextQueryToken], pos: var int): tuple[ok: bool, node: TextQueryNode, err: string] {.role: parser.} =
  result = parsePrimary(tokens, pos)

proc parseAndExpr(tokens: seq[TextQueryToken], pos: var int): tuple[ok: bool, node: TextQueryNode, err: string] {.role: parser.} =
  var
    rhs: tuple[ok: bool, node: TextQueryNode, err: string] = (false, nil, "")
  result = parseFactor(tokens, pos)
  if not result.ok:
    return
  while pos < tokens.len and tokens[pos].kind == tqtAnd:
    pos.inc
    rhs = parseFactor(tokens, pos)
    if not rhs.ok:
      result = rhs
      return
    result.node = TextQueryNode(kind: tqnAnd, left: result.node, right: rhs.node)

proc parseOrExpr(tokens: seq[TextQueryToken], pos: var int): tuple[ok: bool, node: TextQueryNode, err: string] {.role: parser.} =
  var
    rhs: tuple[ok: bool, node: TextQueryNode, err: string] = (false, nil, "")
  result = parseAndExpr(tokens, pos)
  if not result.ok:
    return
  while pos < tokens.len and tokens[pos].kind == tqtOr:
    pos.inc
    rhs = parseAndExpr(tokens, pos)
    if not rhs.ok:
      result = rhs
      return
    result.node = TextQueryNode(kind: tqnOr, left: result.node, right: rhs.node)

proc parseTextQuery*(source: string): tuple[ok: bool, query: TextQuery, err: string] {.role: truthBuilder.} =
  var
    tokenized: tuple[ok: bool, tokens: seq[TextQueryToken], err: string] = (false, @[], "")
    pos: int = 0
    parsed: tuple[ok: bool, node: TextQueryNode, err: string] = (false, nil, "")
  tokenized = tokenizeTextQuery(source)
  if not tokenized.ok:
    result = (false, TextQuery(), tokenized.err)
    return
  parsed = parseOrExpr(tokenized.tokens, pos)
  if not parsed.ok:
    result = (false, TextQuery(), parsed.err)
    return
  if pos >= tokenized.tokens.len or tokenized.tokens[pos].kind != tqtEof:
    result = (false, TextQuery(), "unexpected trailing token in text query near offset " &
      $tokenized.tokens[pos].offset)
    return
  result.ok = true
  result.query.source = source
  result.query.root = parsed.node

proc matchesNode(node: TextQueryNode, candidate: string, caseSensitive: bool): bool {.role: actor.} =
  var
    haystack: string = ""
    needle: string = ""
  result = false
  if node.isNil:
    return
  case node.kind
  of tqnTerm:
    haystack = candidate
    needle = node.term
    if not caseSensitive:
      haystack = haystack.toLowerAscii()
      needle = needle.toLowerAscii()
    result = haystack.contains(needle)
  of tqnAnd:
    result = matchesNode(node.left, candidate, caseSensitive) and
      matchesNode(node.right, candidate, caseSensitive)
  of tqnOr:
    result = matchesNode(node.left, candidate, caseSensitive) or
      matchesNode(node.right, candidate, caseSensitive)
  of tqnNot:
    result = not matchesNode(node.left, candidate, caseSensitive)

proc matchesTextQuery*(query: TextQuery, candidate: string,
    caseSensitive: bool = false): bool {.role: actor.} =
  result = matchesNode(query.root, candidate, caseSensitive)

proc matchesTextQueryString*(source: string, candidate: string,
    caseSensitive: bool = false): tuple[ok: bool, matches: bool, err: string] {.role: orchestrator.} =
  var
    parsed: tuple[ok: bool, query: TextQuery, err: string] = (false, TextQuery(), "")
  parsed = parseTextQuery(source)
  if not parsed.ok:
    result = (false, false, parsed.err)
    return
  result = (true, matchesTextQuery(parsed.query, candidate, caseSensitive), "")
