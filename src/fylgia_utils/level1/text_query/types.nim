## ------------------------------------------------
## Text Query Types <- reusable boolean contains parser
## ------------------------------------------------

type
  ## TextQueryTokenKind: lexer token kinds for boolean query strings.
  TextQueryTokenKind* = enum
    tqtEof,
    tqtTerm,
    tqtAnd,
    tqtOr,
    tqtNot,
    tqtLParen,
    tqtRParen

  ## TextQueryToken: one token produced by the query lexer.
  TextQueryToken* = object
    kind*: TextQueryTokenKind
    value*: string
    offset*: int

  ## TextQueryNodeKind: parsed AST node kinds.
  TextQueryNodeKind* = enum
    tqnTerm,
    tqnAnd,
    tqnOr,
    tqnNot

  ## TextQueryNode: one parsed AST node for a text query.
  TextQueryNode* = ref object
    kind*: TextQueryNodeKind
    term*: string
    left*: TextQueryNode
    right*: TextQueryNode

  ## TextQuery: parsed boolean query expression.
  TextQuery* = object
    source*: string
    root*: TextQueryNode

