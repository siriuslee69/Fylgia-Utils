type 
    Op*[T, Q : SomeNumber] = tuple #T is the input type and Q the return type of each proc/op
        n: string #name
        w: int    #weight
        p: proc(x, y: T): Q 


proc add*[T, Q: SomeNumber](operations: var seq[Op[T, Q]],
    op: proc(x, y: T): Q, name: string, weight: int) =
    operations.add((name, weight, op))

const 
    ops*: array[8, Op[int, int]] = [
        ( "and", 1, proc(x,y: int): int = x and y),
        ( "xor", 1, proc(x,y: int): int = x xor y),
        ( "or", 1, proc(x,y: int): int = x or y),
        ( "not", 1, proc(x,y: int): int = not x),
        ( "sub", 1, proc(x,y: int): int = x - y ),
        ( "add", 1, proc(x,y: int): int = x + y),
        ( "mul", 1, proc(x,y: int): int = x * y),
        ( "div", 1, proc(x,y: int): int = 
            if y == 0: 
                return x
            else: 
                return x div y)
        ]

when defined(test):

    import std/unittest

    suite "Genetic":
        test "registers custom operations":
            var customOps: seq[Op[int, int]] = @[]
            add(customOps, proc(x, y: int): int = x + y, "sum", 2)
            check customOps.len == 1
            check customOps[0].n == "sum"
            check customOps[0].w == 2
            check customOps[0].p(4, 5) == 9

        test "builtin div op guards zero":
            check ops[^1].p(9, 0) == 9
            check ops[^1].p(9, 3) == 3

