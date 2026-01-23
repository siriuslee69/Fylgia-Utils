# =========================================
# | Fylgia Utils Smoke Tests                   |
# |---------------------------------------|
# | Minimal compile/runtime checks.       |
# =========================================

import std/unittest
import ../src/siriusUtils

suite "Fylgia Utils":
  test "root module compiles":
    check SiriusUtilsVersion.len > 0
