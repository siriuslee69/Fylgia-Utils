# ===============================================
# | Fylgia Utils Level2 - Limit Defaults         |
# |---------------------------------------------|
# | Shared generic limits (not app-specific).    |
# ===============================================

import ./text_profiles

const
  DefaultTinyTextMax* = 32
  DefaultShortTextMax* = 64
  DefaultMediumTextMax* = 256
  DefaultLongTextMax* = 1024
  DefaultXLTextMax* = 4096

let
  TinyTextLimit* = makeLengthLimit(0, DefaultTinyTextMax)
  ShortTextLimit* = makeLengthLimit(0, DefaultShortTextMax)
  MediumTextLimit* = makeLengthLimit(0, DefaultMediumTextMax)
  LongTextLimit* = makeLengthLimit(0, DefaultLongTextMax)
  XLTextLimit* = makeLengthLimit(0, DefaultXLTextMax)

const
  DefaultPercentMin* = 0
  DefaultPercentMax* = 100
  DefaultScoreMin* = 0
  DefaultScoreMax* = 1000

let
  PercentRange* = makeRangeLimit(DefaultPercentMin, DefaultPercentMax)
  ScoreRange* = makeRangeLimit(DefaultScoreMin, DefaultScoreMax)
