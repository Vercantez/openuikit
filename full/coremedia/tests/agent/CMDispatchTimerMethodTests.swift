import CoreFoundation
import CoreMedia
import Dispatch
import Foundation

/// Focused behavioral evidence for the four generic `CMTimebase` timer
/// overloads constrained to `DispatchSourceTimer`. Registration is
/// fail-closed on this Linux port: every overload throws
/// `kCMTimebaseError_TimerIntervalTooShort` without touching the source.
/// Each test arms a real timer source with the same resume+cancel discipline
/// as `testCMTimebaseDispatchSourceTimersFailClosed` (a resumed source that
/// is cancelled before release never trips libdispatch), passes it through
/// the generic method (not the C entry point), and asserts the throw.
/// Everything runs synchronously in memory with no waiting.

private func cmDispatchMethodTestTimebase() -> CMTimebase {
    var timebase: CMTimebase?
    precondition(
        CMTimebaseCreateWithSourceClock(
            allocator: nil,
            sourceClock: CMClockGetHostTimeClock(),
            timebaseOut: &timebase
        ) == 0
    )
    return timebase!
}

private func cmDispatchMethodArmedTimerSource() -> DispatchSourceTimer {
    let source = DispatchSource.makeTimerSource()
    source.setEventHandler {}
    source.schedule(deadline: DispatchTime.distantFuture)
    source.resume()
    return source
}

func testCMTimebaseAddDispatchTimerMethodFailClosed() {
    let timebase = cmDispatchMethodTestTimebase()
    let source = cmDispatchMethodArmedTimerSource()
    defer { source.cancel() }
    do {
        try timebase.addTimer(source)
        preconditionFailure("addTimer must refuse dispatch-source timers")
    } catch let error as NSError {
        precondition(error.code == Int(kCMTimebaseError_TimerIntervalTooShort))
    }
}

func testCMTimebaseRemoveDispatchTimerMethodFailClosed() {
    let timebase = cmDispatchMethodTestTimebase()
    let source = cmDispatchMethodArmedTimerSource()
    defer { source.cancel() }
    do {
        try timebase.removeTimer(source)
        preconditionFailure("removeTimer must refuse dispatch-source timers")
    } catch let error as NSError {
        precondition(error.code == Int(kCMTimebaseError_TimerIntervalTooShort))
    }
}

func testCMTimebaseSetDispatchTimerNextFireTimeMethodFailClosed() {
    let timebase = cmDispatchMethodTestTimebase()
    let source = cmDispatchMethodArmedTimerSource()
    defer { source.cancel() }
    do {
        try timebase.setTimerNextFireTime(source, fireTime: CMTime(value: 5, timescale: 1))
        preconditionFailure("setTimerNextFireTime must refuse dispatch-source timers")
    } catch let error as NSError {
        precondition(error.code == Int(kCMTimebaseError_TimerIntervalTooShort))
    }
}

func testCMTimebaseSetDispatchTimerFireImmediatelyMethodFailClosed() {
    let timebase = cmDispatchMethodTestTimebase()
    let source = cmDispatchMethodArmedTimerSource()
    defer { source.cancel() }
    do {
        try timebase.setTimerToFireImmediately(source)
        preconditionFailure("setTimerToFireImmediately must refuse dispatch-source timers")
    } catch let error as NSError {
        precondition(error.code == Int(kCMTimebaseError_TimerIntervalTooShort))
    }
}
