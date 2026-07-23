# =========================================
# | Fylgia Utils Smoke Tests                   |
# |---------------------------------------|
# | Minimal compile/runtime checks.       |
# =========================================

import std/unittest
import ../src/fylgia_utils

suite "Fylgia Utils":
  test "root module compiles":
    check FylgiaUtilsVersion.len > 0
