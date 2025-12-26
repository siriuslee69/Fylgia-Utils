# int64 ONLY polynomial function definitions

type
    Monomial {.packed.} = tuple 
        a: int64 = 0 #factor/coefficient
        n: int16 = 0 #exponent
    Polynomial = seq[Monomial]

template x(a: int32, n: int32): Monomial =
  Monomial(a: a, n: n)

proc init(M: openArray[Monomial]): Polynomial = 
    let 
        l: int = M.len()
    var 
        i: int = static(0)
        j: int = static(1)
        m1: Monomial
        m2: Monomial
    while i < l:
        while j < l:
            m1 = M[i]
            m2 = M[j]
            if(m1.a == 0): #coefficient = 0 -> ignore it. We dont pop it from the array/seq, would take too long
                continue
            if(m1.n == m2.n):
                m1.a = m1.a + m2.a
            j.inc()
        i.inc()
        j = i + 1

proc derivative(x: Monomial): Monomial=
    result.a = x.a * x.n
    result.n = x.n - 1

proc derivative(x: Polynomial): Polynomial =
    for monom in x:
        result.add(derivative(monom))


