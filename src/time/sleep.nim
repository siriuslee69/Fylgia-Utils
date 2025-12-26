import std/monotimes, std/os, std/math

proc sleepMono*(milsecs: int): void =
    ## Sleeps in milsecs
    ## Uses the monotimes instead of an os sleep call
    ## Margin of error is within 1500 nanoseconds or 0.0015 milliseconds
    ## More precise than the std/os sleep function
    let 
        a = getMonoTime().ticks
        b = (a + milsecs*1_000_000)
    while b >= getMonoTime().ticks:
        discard
    return

template takeTime(body: untyped): int64 =
    var 
        b: MonoTime
        c: int64
        a: MonoTime = getMonoTime()
    body
    b = getMonoTime()
    c = b.ticks - a.ticks
    c

template takeTimes(n: int64, body: untyped): seq[int64] =
    var 
        i: int64 = 0
        times: seq[int64] = @[]
    while i < n:
        times.add(takeTime(body))
        i.inc()
    times

template takeTimeAverage(n: int64, body: untyped): int64 =
    let 
        T:seq[int64] = n.takeTimes(body)
    var 
        a: int64
        i: int64 = 0
        sum: int64 = 0
    while i < n:
        sum = sum + T[i]
        i.inc()
    (sum/n).round().int64()

when defined(test):
    
    import std/unittest, ../debugging/checks
    suite "takeTime":
        let k = takeTime: discard 5+10*100
        echo $k
        let K = 5.takeTimes: discard 5+10*100
        echo $K
        let a = 10.takeTimeAverage: echo "Mep map"
        echo a

    suite "sleep":
        test "sleep + benchmark vs std/os":
            const sleeptime = 1000 #milseconds

            var q: int64 
            q = takeTime(sleepMono(sleepTime)) - (sleeptime * 1_000_000)
            echo "custom: " & $q
            check(q <= 2_000 ) 

            q = takeTime(sleep(sleepTime)) - (sleeptime * 1_000_000)
            echo "std/os: " & $q
            check(q <= 100_000_000 ) 
