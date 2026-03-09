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
  DefaultIdMin* = 1
  DefaultIdMax* = 128
  DefaultIdSlugMax* = 64

let
  IdLimit* = makeLengthLimit(DefaultIdMin, DefaultIdMax)
  IdSlugLimit* = makeLengthLimit(DefaultIdMin, DefaultIdSlugMax)

const
  DefaultFileNameMax* = 255
  DefaultPathSegmentMax* = 255
  DefaultPathMax* = 4096

let
  FileNameLimit* = makeLengthLimit(1, DefaultFileNameMax)
  PathSegmentLimit* = makeLengthLimit(1, DefaultPathSegmentMax)
  PathLimit* = makeLengthLimit(1, DefaultPathMax)

const
  DefaultPercentMin* = 0
  DefaultPercentMax* = 100
  DefaultScoreMin* = 0
  DefaultScoreMax* = 1000
  DefaultPageSizeMin* = 1
  DefaultPageSizeMax* = 200
  DefaultPageIndexMin* = 0
  DefaultPageIndexMax* = 100000
  DefaultPageSize* = 50

let
  PercentRange* = makeRangeLimit(DefaultPercentMin, DefaultPercentMax)
  ScoreRange* = makeRangeLimit(DefaultScoreMin, DefaultScoreMax)
  PageSizeRange* = makeRangeLimit(DefaultPageSizeMin, DefaultPageSizeMax)
  PageIndexRange* = makeRangeLimit(DefaultPageIndexMin, DefaultPageIndexMax)
