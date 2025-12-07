import strutils

template toWords*(str: string): seq[string] =
    str.splitWhitespace()

