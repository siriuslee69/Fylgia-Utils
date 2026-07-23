# =========================================
# | Fylgia Config IO Tests                 |
# |---------------------------------------|
# | TOML and JSON config root regression. |
# =========================================

import std/[json, os, unittest]
import ../src/fylgia_utils

proc tempConfigPath(name: string): string =
  result = joinPath(getTempDir(), name)

suite "Fylgia config io":
  test "TOML parser handles nested tables and array tables":
    var
      raw: string
      node: JsonNode
    raw = """
title = "demo"

[runtime]
profileId = "profile-a"
tcpPort = 5050

[[contacts]]
userId = "alice"
alias = "A"

[[contacts]]
userId = "bob"
alias = "B"
"""
    node = parseTomlNode(raw)
    check node["title"].getStr() == "demo"
    check node["runtime"]["profileId"].getStr() == "profile-a"
    check node["runtime"]["tcpPort"].getInt() == 5050
    check node["contacts"].len == 2
    check node["contacts"][1]["userId"].getStr() == "bob"

  test "TOML render roundtrips nested object arrays":
    var
      node: JsonNode = newJObject()
      rendered: string
      reparsed: JsonNode
      owner: JsonNode
    node["profileId"] = %"default"
    node["owners"] = newJArray()
    owner = newJObject()
    owner["ownerId"] = %"owner-a"
    owner["displayName"] = %"Owner A"
    owner["twoFactor"] = %* {
      "enabled": true,
      "algo": "tfaBlake3",
      "digits": 6
    }
    node["owners"].add(owner)
    rendered = renderTomlNode(node)
    reparsed = parseTomlNode(rendered)
    check reparsed["profileId"].getStr() == "default"
    check reparsed["owners"].len == 1
    check reparsed["owners"][0]["twoFactor"]["algo"].getStr() == "tfaBlake3"

  test "generic config writer respects TOML extension":
    var
      p: string = tempConfigPath("fylgia_config_io_test.toml")
      node: JsonNode = %* {"mode": "toml", "retry": 3}
      loaded: JsonNode
    if fileExists(p):
      removeFile(p)
    writeConfigNode(p, node)
    loaded = readConfigNode(p)
    check loaded["mode"].getStr() == "toml"
    check loaded["retry"].getInt() == 3
    if fileExists(p):
      removeFile(p)

  test "TOML parser rejects unterminated quoted table paths":
    expect ValueError:
      discard parseTomlNode("""
[runtime."broken]
tcpPort = 5050
""")

  test "TOML parser rejects empty dotted table path segments":
    expect ValueError:
      discard parseTomlNode("""
[runtime..broken]
tcpPort = 5050
""")
    expect ValueError:
      discard parseTomlNode("""
[]
tcpPort = 5050
""")

  test "TOML parser rejects duplicate keys instead of overwriting":
    expect ValueError:
      discard parseTomlNode("""
title = "first"
title = "second"
""")

  test "JSON config parser rejects duplicate keys instead of overwriting":
    expect ValueError:
      discard parseConfigText("""{"mode":"first","mode":"second"}""", cfgJson)
