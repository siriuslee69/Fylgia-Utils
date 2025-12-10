import std/monotimes, std/os

proc sleepMono*(milsecs: int): void =
    ## Sleeps in milsecs
    ## Uses the monotimes instead of an os sleep call
    ## Margin of error is within 300_000 nanoseconds or 0.3 milliseconds
    ## More precise than the std/os sleep function
    let 
        a = getMonoTime().ticks
        b = (a + milsecs*1_000_000)
    while b >= getMonoTime().ticks:
        discard
    return

when defined(test):
    
    import std/unittest, ../debugging/checks

    suite "sleep":
        test "sleep + benchmark vs std/os":
            const sleeptime = 1000 #milseconds
            var 
                a: MonoTime 
                b: MonoTime
                q: int
            a = getMonoTime()
            sleepMono(sleeptime)
            b = getMonoTime()
            q = (b.ticks - (a.ticks + sleeptime*1_000_000)) 
            echo a.ticks
            echo b.ticks
            echo "custom: " & $q
            check(q <= 1500 ) #difference should be within 1500 nanoseconds or 0.0015 milliseconds
            a = getMonoTime()
            sleep(sleeptime)
            b = getMonoTime()
            q = (b.ticks - (a.ticks + sleeptime*1_000_000))
            echo "std/os: " & $ q
            check(q <= 100_000_000 ) 
