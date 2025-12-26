type 
    Op*[T, Q : SomeNumber] = tuple #T is the input type and Q the return type of each proc/op
        n: string #name
        w: int    #weight
        p: proc(x, y: T): Q 

const 
    ops*: array[8, Op[int, int]] = [
        ( "and", 1, proc(x,y: int): int = x and y),
        ( "xor", 1, proc(x,y: int): int = x xor y),
        ( "or", 1, proc(x,y: int): int = x or y),
        ( "not", 1, proc(x,y: int): int = not x),
        ( "sub", 1, proc(x,y:int): int = x - y ),
        ("add", 1, proc(x,y: int): int = x + y),
        ( "mul", 1, proc(x,y:int): int = x * y),
        ( "div", 1, proc(x,y:int): int = 
            if y == 0: return x
            else: return (x / y).toInt())
        ]

when defined(test):

    import std/unittest, ../../debugging/checks

    suite "Genetic":
        test "op template":
            var 
                res: int
            for op in ops:
                res = op.p(1,3)
                echo $res

