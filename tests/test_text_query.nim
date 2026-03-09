import std/unittest

import ../src/fylgia_utils
import ../src/fylgia_utils/text_query/types

suite "text query":
  test "tokenizes and parses boolean query":
    let tokenized = tokenizeTextQuery("""thisword AND thiswordy AND NOT (thiswordx) OR thiswordz""")
    let parsed = parseTextQuery("""thisword AND thiswordy AND NOT (thiswordx) OR thiswordz""")
    check tokenized.ok
    check tokenized.tokens.len >= 8
    check parsed.ok
    check not parsed.query.root.isNil

  test "matches contains expressions case-insensitively":
    let parsed = parseTextQuery("""invoice AND 2025 AND NOT draft""")
    check parsed.ok
    check matchesTextQuery(parsed.query, "Invoices/Client_2025_Final.pdf")
    check not matchesTextQuery(parsed.query, "Invoices/Client_2025_Draft.pdf")

  test "supports quoted terms and parentheses":
    let res = matchesTextQueryString("""("project alpha" AND notes) OR archive""",
      "docs/project alpha notes.txt")
    let miss = matchesTextQueryString("""("project alpha" AND notes) OR archive""",
      "docs/project beta notes.txt")
    check res.ok
    check res.matches
    check miss.ok
    check not miss.matches

  test "rejects malformed expressions":
    let parsed = parseTextQuery("""thisword AND (other OR""")
    check not parsed.ok
    check parsed.err.len > 0
