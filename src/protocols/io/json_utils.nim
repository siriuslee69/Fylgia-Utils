# ===========================================
# | Fylgia Utils - JSON Helpers              |
# |-----------------------------------------|
# | Small helpers for JSON and byte payloads.|
# ===========================================

import std/json
import runePragmas
import ./byte_utils

proc jsonToString*(node: JsonNode): string {.role: helper.} =
  ## Convert a JSON node into a string.
  result = $node

proc stringToJson*(payload: string): JsonNode {.role: parser.} =
  ## Parse a JSON node from a string.
  result = parseJson(payload)

proc jsonToBytes*(node: JsonNode): ByteSeq {.role: helper.} =
  ## Serialize a JSON node into bytes using UTF-8 string form.
  result = stringToBytes(jsonToString(node))

proc bytesToJson*(payload: ByteSeq): JsonNode {.role: parser.} =
  ## Parse a JSON node from a byte payload.
  result = stringToJson(bytesToString(payload))
