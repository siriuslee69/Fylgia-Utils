# ==================================================
# | Fylgia Utils - Config IO                       |
# |------------------------------------------------|
# | Parse/render JSON and TOML config root nodes.  |
# ==================================================

import std/[json, os, strutils]

type
  ConfigFormat* = enum
    cfgJson,
    cfgToml

proc detectConfigFormat*(p: string): ConfigFormat =
  ## p: config file path used to infer the format.
  var
    ext: string = splitFile(p).ext.toLowerAscii()
  if ext == ".toml":
    result = cfgToml
  else:
    result = cfgJson

proc quoteTomlString(v: string): string =
  var
    t: string = v
  t = t.replace("\\", "\\\\")
  t = t.replace("\"", "\\\"")
  t = t.replace("\b", "\\b")
  t = t.replace("\f", "\\f")
  t = t.replace("\n", "\\n")
  t = t.replace("\r", "\\r")
  t = t.replace("\t", "\\t")
  result = "\"" & t & "\""

proc isBareTomlKeyPart(v: string): bool =
  var
    i: int = 0
    ch: char
  if v.len == 0:
    return false
  i = 0
  while i < v.len:
    ch = v[i]
    if not ((ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z') or
        (ch >= '0' and ch <= '9') or ch == '-' or ch == '_'):
      return false
    i = i + 1
  result = true

proc formatTomlKeyPart(v: string): string =
  if isBareTomlKeyPart(v):
    result = v
  else:
    result = quoteTomlString(v)

proc formatTomlPath(parts: seq[string]): string =
  var
    i: int = 0
    outParts: seq[string] = @[]
  i = 0
  while i < parts.len:
    outParts.add(formatTomlKeyPart(parts[i]))
    i = i + 1
  result = outParts.join(".")

proc stripTomlComment(line: string): string =
  var
    i: int = 0
    inDouble: bool = false
    inSingle: bool = false
    escapeNext: bool = false
  i = 0
  while i < line.len:
    if escapeNext:
      escapeNext = false
      i = i + 1
      continue
    if inDouble:
      if line[i] == '\\':
        escapeNext = true
      elif line[i] == '"':
        inDouble = false
      i = i + 1
      continue
    if inSingle:
      if line[i] == '\'':
        inSingle = false
      i = i + 1
      continue
    if line[i] == '"':
      inDouble = true
    elif line[i] == '\'':
      inSingle = true
    elif line[i] == '#':
      return line[0 ..< i]
    i = i + 1
  result = line

proc splitDottedTomlPath(raw: string): seq[string] =
  var
    i: int = 0
    start: int = 0
    inDouble: bool = false
    inSingle: bool = false
    escapeNext: bool = false
    part: string
    t: string = raw.strip()
  if t.len == 0:
    return @[]
  i = 0
  while i <= t.len:
    if i == t.len or (t[i] == '.' and not inDouble and not inSingle):
      part = t[start ..< i].strip()
      if part.len > 0:
        if part.len >= 2 and ((part[0] == '"' and part[^1] == '"') or
            (part[0] == '\'' and part[^1] == '\'')):
          part = part[1 .. ^2]
        result.add(part)
      start = i + 1
      i = i + 1
      continue
    if escapeNext:
      escapeNext = false
      i = i + 1
      continue
    if inDouble:
      if t[i] == '\\':
        escapeNext = true
      elif t[i] == '"':
        inDouble = false
      i = i + 1
      continue
    if inSingle:
      if t[i] == '\'':
        inSingle = false
      i = i + 1
      continue
    if t[i] == '"':
      inDouble = true
    elif t[i] == '\'':
      inSingle = true
    i = i + 1

proc lastArrayObject(n: JsonNode): JsonNode =
  if n.kind != JArray:
    raise newException(ValueError, "expected array while resolving TOML table")
  if n.len == 0 or n[n.len - 1].kind != JObject:
    n.add(newJObject())
  result = n[n.len - 1]

proc ensureTomlTable(root: JsonNode; parts: seq[string];
    arrayTable: bool): JsonNode =
  var
    cur: JsonNode = root
    i: int = 0
    key: string
  if root.kind != JObject:
    raise newException(ValueError, "TOML root must be an object")
  if parts.len == 0:
    return root
  i = 0
  while i < parts.len:
    key = parts[i]
    if cur.kind != JObject:
      raise newException(ValueError, "invalid TOML table path: " & parts.join("."))
    if i == parts.len - 1 and arrayTable:
      if not cur.hasKey(key):
        cur[key] = newJArray()
      elif cur[key].kind != JArray:
        raise newException(ValueError, "TOML table path conflicts with non-array table: " & parts.join("."))
      cur[key].add(newJObject())
      return cur[key][cur[key].len - 1]
    if not cur.hasKey(key):
      cur[key] = newJObject()
    elif cur[key].kind == JArray:
      cur = lastArrayObject(cur[key])
      i = i + 1
      continue
    elif cur[key].kind != JObject:
      raise newException(ValueError, "TOML table path conflicts with scalar value: " & parts.join("."))
    cur = cur[key]
    i = i + 1
  result = cur

proc assignTomlValue(cur: JsonNode; parts: seq[string]; value: JsonNode) =
  var
    node: JsonNode = cur
    i: int = 0
    key: string
  if parts.len == 0:
    raise newException(ValueError, "empty TOML key path")
  i = 0
  while i < parts.len - 1:
    key = parts[i]
    if node.kind != JObject:
      raise newException(ValueError, "invalid TOML key path: " & parts.join("."))
    if not node.hasKey(key):
      node[key] = newJObject()
    elif node[key].kind == JArray:
      node = lastArrayObject(node[key])
      i = i + 1
      continue
    elif node[key].kind != JObject:
      raise newException(ValueError, "TOML key path conflicts with scalar value: " & parts.join("."))
    node = node[key]
    i = i + 1
  if node.kind != JObject:
    raise newException(ValueError, "invalid TOML assignment target")
  node[parts[^1]] = value

proc skipTomlWhitespace(raw: string; pos: var int) =
  while pos < raw.len and raw[pos] in {' ', '\t', '\r', '\n'}:
    pos = pos + 1

proc parseTomlStringLiteral(raw: string; pos: var int): string =
  var
    quote: char
    ch: char
  if pos >= raw.len or (raw[pos] != '"' and raw[pos] != '\''):
    raise newException(ValueError, "expected TOML string")
  quote = raw[pos]
  pos = pos + 1
  while pos < raw.len:
    ch = raw[pos]
    if quote == '"' and ch == '\\':
      pos = pos + 1
      if pos >= raw.len:
        raise newException(ValueError, "unterminated TOML escape sequence")
      case raw[pos]
      of '"':
        result.add('"')
      of '\\':
        result.add('\\')
      of 'b':
        result.add('\b')
      of 'f':
        result.add('\f')
      of 'n':
        result.add('\n')
      of 'r':
        result.add('\r')
      of 't':
        result.add('\t')
      else:
        result.add(raw[pos])
      pos = pos + 1
      continue
    if ch == quote:
      pos = pos + 1
      return
    result.add(ch)
    pos = pos + 1
  raise newException(ValueError, "unterminated TOML string")

proc parseTomlValueRaw(raw: string; pos: var int): JsonNode

proc parseTomlArray(raw: string; pos: var int): JsonNode =
  var
    value: JsonNode
  if pos >= raw.len or raw[pos] != '[':
    raise newException(ValueError, "expected TOML array")
  result = newJArray()
  pos = pos + 1
  skipTomlWhitespace(raw, pos)
  if pos < raw.len and raw[pos] == ']':
    pos = pos + 1
    return
  while pos < raw.len:
    value = parseTomlValueRaw(raw, pos)
    result.add(value)
    skipTomlWhitespace(raw, pos)
    if pos >= raw.len:
      break
    if raw[pos] == ',':
      pos = pos + 1
      skipTomlWhitespace(raw, pos)
      continue
    if raw[pos] == ']':
      pos = pos + 1
      return
    raise newException(ValueError, "invalid TOML array separator")
  raise newException(ValueError, "unterminated TOML array")

proc parseTomlScalar(raw: string; pos: var int): JsonNode =
  var
    start: int = pos
    token: string
    i64: BiggestInt
    f64: float
  while pos < raw.len and raw[pos] notin {' ', '\t', '\r', '\n', ',', ']'}:
    pos = pos + 1
  token = raw[start ..< pos].strip()
  if token.len == 0:
    raise newException(ValueError, "empty TOML value")
  if token == "true":
    return newJBool(true)
  if token == "false":
    return newJBool(false)
  try:
    i64 = parseBiggestInt(token)
    return newJInt(i64)
  except ValueError:
    discard
  try:
    f64 = parseFloat(token)
    return newJFloat(f64)
  except ValueError:
    discard
  raise newException(ValueError, "unsupported TOML scalar: " & token)

proc parseTomlValueRaw(raw: string; pos: var int): JsonNode =
  skipTomlWhitespace(raw, pos)
  if pos >= raw.len:
    raise newException(ValueError, "missing TOML value")
  if raw[pos] == '"' or raw[pos] == '\'':
    result = newJString(parseTomlStringLiteral(raw, pos))
  elif raw[pos] == '[':
    result = parseTomlArray(raw, pos)
  else:
    result = parseTomlScalar(raw, pos)

proc parseTomlValue(raw: string): JsonNode =
  var
    pos: int = 0
  result = parseTomlValueRaw(raw, pos)
  skipTomlWhitespace(raw, pos)
  if pos < raw.len:
    raise newException(ValueError, "unexpected trailing TOML value content")

proc splitTomlKeyValue(raw: string): tuple[ok: bool, key: string, value: string] =
  var
    i: int = 0
    inDouble: bool = false
    inSingle: bool = false
    escapeNext: bool = false
    line: string = stripTomlComment(raw).strip()
  if line.len == 0:
    return (false, "", "")
  i = 0
  while i < line.len:
    if escapeNext:
      escapeNext = false
      i = i + 1
      continue
    if inDouble:
      if line[i] == '\\':
        escapeNext = true
      elif line[i] == '"':
        inDouble = false
      i = i + 1
      continue
    if inSingle:
      if line[i] == '\'':
        inSingle = false
      i = i + 1
      continue
    if line[i] == '"':
      inDouble = true
    elif line[i] == '\'':
      inSingle = true
    elif line[i] == '=':
      return (true, line[0 ..< i].strip(), line[i + 1 .. ^1].strip())
    i = i + 1
  result = (false, "", "")

proc parseTomlNode*(raw: string): JsonNode =
  var
    root: JsonNode = newJObject()
    cur: JsonNode = root
    lines: seq[string] = raw.splitLines()
    i: int = 0
    line: string
    body: string
    parts: seq[string]
    kv: tuple[ok: bool, key: string, value: string]
  i = 0
  while i < lines.len:
    line = stripTomlComment(lines[i]).strip()
    if line.len == 0:
      i = i + 1
      continue
    if line.startsWith("[[") and line.endsWith("]]"):
      body = line[2 .. ^3].strip()
      parts = splitDottedTomlPath(body)
      cur = ensureTomlTable(root, parts, true)
      i = i + 1
      continue
    if line.startsWith("[") and line.endsWith("]"):
      body = line[1 .. ^2].strip()
      parts = splitDottedTomlPath(body)
      cur = ensureTomlTable(root, parts, false)
      i = i + 1
      continue
    kv = splitTomlKeyValue(lines[i])
    if not kv.ok:
      raise newException(ValueError, "invalid TOML line: " & lines[i])
    parts = splitDottedTomlPath(kv.key)
    assignTomlValue(cur, parts, parseTomlValue(kv.value))
    i = i + 1
  result = root

proc isTomlArrayOfTables(n: JsonNode): bool =
  var
    i: int = 0
  if n.kind != JArray or n.len == 0:
    return false
  i = 0
  while i < n.len:
    if n[i].kind != JObject:
      return false
    i = i + 1
  result = true

proc renderTomlValue(n: JsonNode): string =
  var
    i: int = 0
    parts: seq[string] = @[]
  case n.kind
  of JString:
    result = quoteTomlString(n.getStr())
  of JInt:
    result = $n.getBiggestInt()
  of JFloat:
    result = $n.getFloat()
  of JBool:
    if n.getBool():
      result = "true"
    else:
      result = "false"
  of JArray:
    if isTomlArrayOfTables(n):
      raise newException(ValueError, "array-of-table values must be rendered as TOML sections")
    i = 0
    while i < n.len:
      parts.add(renderTomlValue(n[i]))
      i = i + 1
    result = "[" & parts.join(", ") & "]"
  of JObject:
    raise newException(ValueError, "object values must be rendered as TOML tables")
  of JNull:
    raise newException(ValueError, "null values are not supported in TOML config output")

proc emitTomlObject(path: seq[string]; node: JsonNode; lines: var seq[string];
    emitHeader: bool)

proc appendBlankLine(lines: var seq[string]) =
  if lines.len > 0 and lines[^1].len > 0:
    lines.add("")

proc emitTomlArrayTable(path: seq[string]; node: JsonNode; lines: var seq[string]) =
  var
    i: int = 0
  i = 0
  while i < node.len:
    appendBlankLine(lines)
    lines.add("[[" & formatTomlPath(path) & "]]")
    emitTomlObject(path, node[i], lines, false)
    i = i + 1

proc emitTomlObject(path: seq[string]; node: JsonNode; lines: var seq[string];
    emitHeader: bool) =
  var
    scalarKeys: seq[string] = @[]
    objectKeys: seq[string] = @[]
    arrayTableKeys: seq[string] = @[]
    key: string
    value: JsonNode
  if node.kind != JObject:
    raise newException(ValueError, "TOML output root must be a JSON object")
  if emitHeader:
    appendBlankLine(lines)
    lines.add("[" & formatTomlPath(path) & "]")
  for key, value in node:
    if value.kind == JObject:
      objectKeys.add(key)
    elif isTomlArrayOfTables(value):
      arrayTableKeys.add(key)
    else:
      scalarKeys.add(key)
  for key in scalarKeys:
    lines.add(formatTomlKeyPart(key) & " = " & renderTomlValue(node[key]))
  for key in objectKeys:
    emitTomlObject(path & @[key], node[key], lines, true)
  for key in arrayTableKeys:
    emitTomlArrayTable(path & @[key], node[key], lines)

proc renderTomlNode*(node: JsonNode): string =
  var
    lines: seq[string] = @[]
  emitTomlObject(@[], node, lines, false)
  if lines.len == 0:
    return ""
  result = lines.join("\n") & "\n"

proc parseConfigText*(raw: string; format: ConfigFormat): JsonNode =
  case format
  of cfgJson:
    result = parseJson(raw)
  of cfgToml:
    result = parseTomlNode(raw)

proc parseConfigText*(raw: string; p: string): JsonNode =
  result = parseConfigText(raw, detectConfigFormat(p))

proc renderConfigText*(node: JsonNode; format: ConfigFormat): string =
  case format
  of cfgJson:
    result = $node
  of cfgToml:
    result = renderTomlNode(node)

proc renderConfigText*(node: JsonNode; p: string): string =
  result = renderConfigText(node, detectConfigFormat(p))

proc readConfigNode*(p: string): JsonNode =
  result = parseConfigText(readFile(p), p)

proc writeConfigNode*(p: string; node: JsonNode) =
  writeFile(p, renderConfigText(node, p))
