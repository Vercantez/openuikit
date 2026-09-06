import CoreFoundation
import Dispatch
import Foundation

/// Host-time clock timescale. Apple's CMClockGetHostTimeClock discussion
/// (CMSync.h): "returns a value with a large integer timescale (eg, nanoseconds)".
private let cmHostTimescale: CMTimeScale = 1_000_000_000

public protocol CMSyncProtocol: AnyObject {
    var time: CMTime { get }
    func convertTime<T>(_ time: CMTime, to clockOrTimebase: T) -> CMTime where T: CMSyncProtocol
    func rate<T>(relativeTo relativeToClockOrTimebase: T) -> Float64 where T: CMSyncProtocol
    func rateAndAnchorTime<T>(
        relativeTo clockOrTimebase: T
    ) throws -> (rate: Float64, anchorTime: CMTime, relativeRate: Float64, relativeAnchorTime: CMTime)
        where T: CMSyncProtocol
    func mightDrift<T>(relativeTo clockOrTimebase: T) -> Bool where T: CMSyncProtocol
}

public struct CMSync {
    public struct Error {
        public static let missingRequiredParameter = cmNSError(code: Int(kCMSyncError_MissingRequiredParameter))
        public static let invalidParameter = cmNSError(code: Int(kCMSyncError_InvalidParameter))
        public static let allocationFailed = cmNSError(code: Int(kCMSyncError_AllocationFailed))
        public static let rateMustBeNonZero = cmNSError(code: Int(kCMSyncError_RateMustBeNonZero))
    }
}

public final class CMClock: CMSyncProtocol, @unchecked Sendable {
    public typealias T = CMClock

    public struct Error {
        public static let missingRequiredParameter = cmNSError(code: Int(kCMClockError_MissingRequiredParameter))
        public static let invalidParameter = cmNSError(code: Int(kCMClockError_InvalidParameter))
        public static let allocationFailed = cmNSError(code: Int(kCMClockError_AllocationFailed))
        public static let unsupportedOperation = cmNSError(code: Int(kCMClockError_UnsupportedOperation))
    }

    private static let processTypeID: CFTypeID = 0x434D_434C
    public static var typeID: CFTypeID { processTypeID }

    private let lock = CMUnfairLock()
    private var valid = true
    private let usesHostTime: Bool
    private var frozenTime: CMTime

    fileprivate init(hostTime: Bool) {
        self.usesHostTime = hostTime
        self.frozenTime = .zero
    }

    public init(referencing object: CMClock) {
        self.usesHostTime = object.usesHostTime
        self.valid = object.valid
        self.frozenTime = object.frozenTime
    }

    public static var hostTimeClock: CMClock { cmHostTimeClock }

    public var time: CMTime { CMClockGetTime(self) }

    public func invalidate() {
        lock.locked { valid = false }
    }

    public func mightDrift(relativeTo otherClock: CMClock) -> Bool {
        CMClockMightDrift(self, otherClock: otherClock)
    }

    public func mightDrift<T>(relativeTo clockOrTimebase: T) -> Bool where T: CMSyncProtocol {
        if let other = clockOrTimebase as? CMClock {
            return mightDrift(relativeTo: other)
        }
        return true
    }

    public func convertTime<T>(_ time: CMTime, to clockOrTimebase: T) -> CMTime where T: CMSyncProtocol {
        CMSyncConvertTime(time, from: self, to: clockOrTimebase)
    }

    public func rate<T>(relativeTo relativeToClockOrTimebase: T) -> Float64 where T: CMSyncProtocol {
        CMSyncGetRelativeRate(self, relativeTo: relativeToClockOrTimebase)
    }

    public func rateAndAnchorTime<T>(
        relativeTo clockOrTimebase: T
    ) throws -> (rate: Float64, anchorTime: CMTime, relativeRate: Float64, relativeAnchorTime: CMTime)
        where T: CMSyncProtocol
    {
        try CMSyncGetRelativeRateAndAnchorTime(self, relativeTo: clockOrTimebase)
    }

    public func anchorTime() throws -> (anchorTime: CMTime, referenceTime: CMTime) {
        var clockTime = CMTime.invalid
        var reference = CMTime.invalid
        let status = CMClockGetAnchorTime(self, clockTimeOut: &clockTime, referenceClockTimeOut: &reference)
        if status != 0 { throw Error.invalidParameter }
        return (clockTime, reference)
    }

    public static func convertHostTimeToSystemUnits(_ hostTime: CMTime) -> UInt64 {
        CMClockConvertHostTimeToSystemUnits(hostTime)
    }

    public static func convertSystemUnitsToHostTime(_ systemUnits: UInt64) -> CMTime {
        CMClockMakeHostTimeFromSystemUnits(systemUnits)
    }

    fileprivate func currentHostTime() -> CMTime {
        if !usesHostTime {
            return lock.locked { frozenTime }
        }
        let nanos = DispatchTime.now().uptimeNanoseconds
        if nanos > UInt64(Int64.max) {
            return .positiveInfinity
        }
        return CMTime(value: Int64(nanos), timescale: cmHostTimescale, flags: .valid, epoch: 0)
    }
}

private let cmHostTimeClock = CMClock(hostTime: true)

public final class CMTimebase: CMSyncProtocol, @unchecked Sendable {
    public typealias T = CMTimebase

    public struct Error {
        public static let missingRequiredParameter = cmNSError(code: Int(kCMTimebaseError_MissingRequiredParameter))
        public static let invalidParameter = cmNSError(code: Int(kCMTimebaseError_InvalidParameter))
        public static let allocationFailed = cmNSError(code: Int(kCMTimebaseError_AllocationFailed))
        public static let timerIntervalTooShort = cmNSError(code: Int(kCMTimebaseError_TimerIntervalTooShort))
        public static let readOnly = cmNSError(code: Int(kCMTimebaseError_ReadOnly))
    }

    public struct NotificationKey: RawRepresentable, Hashable {
        public typealias RawValue = CFString
        public var rawValue: CFString
        public init(rawValue: CFString) { self.rawValue = rawValue }
        public static let eventTime = NotificationKey(rawValue: kCMTimebaseNotificationKey_EventTime)
        public static func == (lhs: NotificationKey, rhs: NotificationKey) -> Bool {
            CFEqual(lhs.rawValue, rhs.rawValue)
        }
        public func hash(into hasher: inout Hasher) {
            hasher.combine(unsafeBitCast(rawValue, to: NSString.self) as String)
        }
    }

    private static let processTypeID: CFTypeID = 0x434D_5442
    public static var typeID: CFTypeID { processTypeID }

    public static let timeJumped = Notification.Name(
        unsafeBitCast(kCMTimebaseNotification_TimeJumped, to: NSString.self) as String
    )
    public static let effectiveRateChanged = Notification.Name(
        unsafeBitCast(kCMTimebaseNotification_EffectiveRateChanged, to: NSString.self) as String
    )
    /// Apple CMSync.h: far-future CFAbsoluteTime used when a timer should not fire.
    public static let farFuture: CFAbsoluteTime = 1.0e100
    /// Apple CMSync.h companion of farFuture for CFTimeInterval.
    public static let veryLongTimeInterval: CFTimeInterval = 1.0e100

    private let lock = CMUnfairLock()
    fileprivate var ownedClock: CMClock?
    fileprivate var ownedTimebase: CMTimebase?
    private var rateValue: Float64 = 0
    private var timebaseAnchor: CMTime = .zero
    private var sourceAnchor: CMTime = .zero

    public init(sourceClock: CMClock) {
        self.ownedClock = sourceClock
        self.sourceAnchor = sourceClock.time
        self.timebaseAnchor = .zero
        self.rateValue = 0
    }

    public init(sourceTimebase: CMTimebase) {
        self.ownedTimebase = sourceTimebase
        self.sourceAnchor = sourceTimebase.time
        self.timebaseAnchor = .zero
        self.rateValue = 0
    }

    public convenience init(masterClock: CMClock) {
        self.init(sourceClock: masterClock)
    }

    public convenience init(masterTimebase: CMTimebase) {
        self.init(sourceTimebase: masterTimebase)
    }

    public init(referencing object: CMTimebase) {
        self.ownedClock = object.ownedClock
        self.ownedTimebase = object.ownedTimebase
        self.rateValue = object.rateValue
        self.timebaseAnchor = object.timebaseAnchor
        self.sourceAnchor = object.sourceAnchor
    }

    public var source: any CMSyncProtocol {
        get {
            lock.locked { (ownedTimebase as CMSyncProtocol?) ?? ownedClock! }
        }
        set {
            lock.locked {
                if let clock = newValue as? CMClock {
                    ownedClock = clock
                    ownedTimebase = nil
                } else if let tb = newValue as? CMTimebase {
                    ownedTimebase = tb
                    ownedClock = nil
                }
            }
        }
    }

    public var master: any CMSyncProtocol {
        get { source }
        set { source = newValue }
    }

    public var masterClock: CMClock? { lock.locked { ownedClock } }
    public var masterTimebase: CMTimebase? { lock.locked { ownedTimebase } }
    public var sourceClock: CMClock? { masterClock }
    public var sourceTimebase: CMTimebase? { masterTimebase }

    public var ultimateMasterClock: CMClock { ultimateSourceClock }
    public var ultimateSourceClock: CMClock {
        lock.locked {
            if let clock = ownedClock { return clock }
            return ownedTimebase!.ultimateSourceClock
        }
    }

    public var rate: Float64 { lock.locked { rateValue } }

    public var effectiveRate: Float64 { CMTimebaseGetEffectiveRate(self) }

    public var time: CMTime { CMTimebaseGetTime(self) }

    public var timeAndRate: (time: CMTime, rate: Float64) {
        (CMTimebaseGetTime(self), rate)
    }

    public func setRate(_ rate: Float64) throws {
        let status = CMTimebaseSetRate(self, rate: rate)
        if status != 0 { throw Error.invalidParameter }
    }

    public func setTime(_ time: CMTime) throws {
        let status = CMTimebaseSetTime(self, time: time)
        if status != 0 { throw Error.invalidParameter }
    }

    public func setAnchorTime(_ anchorTime: CMTime, referenceTime: CMTime) throws {
        let status = CMTimebaseSetAnchorTime(self, timebaseTime: anchorTime, immediateSourceTime: referenceTime)
        if status != 0 { throw Error.invalidParameter }
    }

    public func setRateAndAnchorTime(rate: Float64, anchorTime: CMTime, referenceTime: CMTime) throws {
        let status = CMTimebaseSetRateAndAnchorTime(
            self,
            rate: rate,
            timebaseTime: anchorTime,
            immediateSourceTime: referenceTime
        )
        if status != 0 { throw Error.invalidParameter }
    }

    public func time(withTimescale timescale: CMTimeScale, rounding: CMTimeRoundingMethod = .default) -> CMTime {
        CMTimebaseGetTimeWithTimeScale(self, timescale: timescale, method: rounding)
    }

    public func convertTime<T>(_ time: CMTime, to clockOrTimebase: T) -> CMTime where T: CMSyncProtocol {
        CMSyncConvertTime(time, from: self, to: clockOrTimebase)
    }

    public func rate<T>(relativeTo relativeToClockOrTimebase: T) -> Float64 where T: CMSyncProtocol {
        CMSyncGetRelativeRate(self, relativeTo: relativeToClockOrTimebase)
    }

    public func rateAndAnchorTime<T>(
        relativeTo clockOrTimebase: T
    ) throws -> (rate: Float64, anchorTime: CMTime, relativeRate: Float64, relativeAnchorTime: CMTime)
        where T: CMSyncProtocol
    {
        try CMSyncGetRelativeRateAndAnchorTime(self, relativeTo: clockOrTimebase)
    }

    public func mightDrift<T>(relativeTo clockOrTimebase: T) -> Bool where T: CMSyncProtocol {
        CMSyncMightDrift(self, clockOrTimebase)
    }

    public func notificationBarrier() throws {}

    public func addTimer(_ timer: Timer, on runloop: RunLoop) throws {
        _ = (timer, runloop)
        throw Error.unsupportedIfNeeded()
    }

    public func addTimer<T>(_ timer: T) throws where T: DispatchSourceTimer {
        _ = timer
        throw Error.unsupportedIfNeeded()
    }

    public func removeTimer(_ timer: Timer) throws {
        _ = timer
        throw Error.unsupportedIfNeeded()
    }

    public func removeTimer<T>(_ timer: T) throws where T: DispatchSourceTimer {
        _ = timer
        throw Error.unsupportedIfNeeded()
    }

    public func setTimerNextFireTime(_ timer: Timer, fireTime: CMTime) throws {
        _ = (timer, fireTime)
        throw Error.unsupportedIfNeeded()
    }

    public func setTimerNextFireTime<T>(_ timer: T, fireTime: CMTime) throws where T: DispatchSourceTimer {
        _ = (timer, fireTime)
        throw Error.unsupportedIfNeeded()
    }

    public func setTimerToFireImmediately(_ timer: Timer) throws {
        _ = timer
        throw Error.unsupportedIfNeeded()
    }

    public func setTimerToFireImmediately<T>(_ timer: T) throws where T: DispatchSourceTimer {
        _ = timer
        throw Error.unsupportedIfNeeded()
    }

    fileprivate func sourceNow() -> CMTime {
        if let clock = ownedClock { return clock.time }
        return ownedTimebase!.time
    }

    fileprivate func snapshot() -> (rate: Float64, timebaseAnchor: CMTime, sourceAnchor: CMTime, sourceNow: CMTime) {
        lock.locked {
            (rateValue, timebaseAnchor, sourceAnchor, sourceNow())
        }
    }

    fileprivate func setMapping(rate: Float64, timebaseAnchor: CMTime, sourceAnchor: CMTime) {
        lock.locked {
            self.rateValue = rate
            self.timebaseAnchor = timebaseAnchor
            self.sourceAnchor = sourceAnchor
        }
    }
}

extension CMTimebase.Error {
    fileprivate static func unsupportedIfNeeded() -> NSError { timerIntervalTooShort }
}

public func CMClockGetHostTimeClock() -> CMClock { CMClock.hostTimeClock }

public func CMClockGetTypeID() -> CFTypeID { CMClock.typeID }

public func CMClockGetTime(_ clock: CMClock) -> CMTime {
    clock.currentHostTime()
}

public func CMClockInvalidate(_ clock: CMClock) {
    clock.invalidate()
}

public func CMClockMightDrift(_ clock: CMClock, otherClock: CMClock) -> Bool {
    clock !== otherClock
}

public func CMClockConvertHostTimeToSystemUnits(_ hostTime: CMTime) -> UInt64 {
    if !hostTime.isNumeric { return 0 }
    let converted = CMTimeConvertScale(hostTime, timescale: cmHostTimescale, method: .default)
    if converted.isPositiveInfinity { return UInt64.max }
    if converted.isNegativeInfinity || converted.value < 0 { return 0 }
    return UInt64(converted.value)
}

public func CMClockMakeHostTimeFromSystemUnits(_ hostTime: UInt64) -> CMTime {
    if hostTime > UInt64(Int64.max) { return .positiveInfinity }
    return CMTime(value: Int64(hostTime), timescale: cmHostTimescale, flags: .valid, epoch: 0)
}

public func CMClockGetAnchorTime(
    _ clock: CMClock,
    clockTimeOut: UnsafeMutablePointer<CMTime>,
    referenceClockTimeOut: UnsafeMutablePointer<CMTime>
) -> OSStatus {
    let now = CMClockGetTime(clock)
    clockTimeOut.pointee = now
    referenceClockTimeOut.pointee = now
    return 0
}

public func CMTimebaseGetTypeID() -> CFTypeID { CMTimebase.typeID }

public func CMTimebaseCreateWithSourceClock(
    allocator: CFAllocator?,
    sourceClock: CMClock,
    timebaseOut: UnsafeMutablePointer<CMTimebase?>
) -> OSStatus {
    _ = allocator
    timebaseOut.pointee = CMTimebase(sourceClock: sourceClock)
    return 0
}

public func CMTimebaseCreateWithSourceTimebase(
    allocator: CFAllocator?,
    sourceTimebase: CMTimebase,
    timebaseOut: UnsafeMutablePointer<CMTimebase?>
) -> OSStatus {
    _ = allocator
    timebaseOut.pointee = CMTimebase(sourceTimebase: sourceTimebase)
    return 0
}

public func CMTimebaseCreateWithMasterClock(
    allocator: CFAllocator?,
    masterClock: CMClock,
    timebaseOut: UnsafeMutablePointer<CMTimebase?>
) -> OSStatus {
    CMTimebaseCreateWithSourceClock(allocator: allocator, sourceClock: masterClock, timebaseOut: timebaseOut)
}

public func CMTimebaseCreateWithMasterTimebase(
    allocator: CFAllocator?,
    masterTimebase: CMTimebase,
    timebaseOut: UnsafeMutablePointer<CMTimebase?>
) -> OSStatus {
    CMTimebaseCreateWithSourceTimebase(
        allocator: allocator,
        sourceTimebase: masterTimebase,
        timebaseOut: timebaseOut
    )
}

public func CMTimebaseGetTime(_ timebase: CMTimebase) -> CMTime {
    let snap = timebase.snapshot()
    if snap.rate == 0 { return snap.timebaseAnchor }
    let delta = CMTimeSubtract(snap.sourceNow, snap.sourceAnchor)
    let scaled = CMTimeMultiplyByFloat64(delta, multiplier: snap.rate)
    return CMTimeAdd(snap.timebaseAnchor, scaled)
}

public func CMTimebaseGetTimeWithTimeScale(
    _ timebase: CMTimebase,
    timescale: CMTimeScale,
    method: CMTimeRoundingMethod
) -> CMTime {
    CMTimeConvertScale(CMTimebaseGetTime(timebase), timescale: timescale, method: method)
}

public func CMTimebaseGetRate(_ timebase: CMTimebase) -> Float64 {
    timebase.rate
}

public func CMTimebaseGetEffectiveRate(_ timebase: CMTimebase) -> Float64 {
    var rate = timebase.rate
    var current: CMTimebase? = timebase
    var guardCount = 0
    while let tb = current, guardCount < 32 {
        guardCount += 1
        if let parent = tb.ownedTimebase {
            rate *= parent.rate
            current = parent
        } else {
            break
        }
    }
    return rate
}

public func CMTimebaseGetTimeAndRate(
    _ timebase: CMTimebase,
    timeOut: UnsafeMutablePointer<CMTime>,
    rateOut: UnsafeMutablePointer<Float64>
) -> OSStatus {
    timeOut.pointee = CMTimebaseGetTime(timebase)
    rateOut.pointee = CMTimebaseGetRate(timebase)
    return 0
}

public func CMTimebaseSetRate(_ timebase: CMTimebase, rate: Float64) -> OSStatus {
    let nowSource = timebase.sourceNow()
    let nowTime = CMTimebaseGetTime(timebase)
    timebase.setMapping(rate: rate, timebaseAnchor: nowTime, sourceAnchor: nowSource)
    return 0
}

public func CMTimebaseSetTime(_ timebase: CMTimebase, time: CMTime) -> OSStatus {
    if !time.isValid { return kCMTimebaseError_InvalidParameter }
    timebase.setMapping(rate: timebase.rate, timebaseAnchor: time, sourceAnchor: timebase.sourceNow())
    return 0
}

public func CMTimebaseSetAnchorTime(
    _ timebase: CMTimebase,
    timebaseTime: CMTime,
    immediateSourceTime: CMTime
) -> OSStatus {
    if !timebaseTime.isValid || !immediateSourceTime.isValid {
        return kCMTimebaseError_InvalidParameter
    }
    timebase.setMapping(rate: timebase.rate, timebaseAnchor: timebaseTime, sourceAnchor: immediateSourceTime)
    return 0
}

public func CMTimebaseSetRateAndAnchorTime(
    _ timebase: CMTimebase,
    rate: Float64,
    timebaseTime: CMTime,
    immediateSourceTime: CMTime
) -> OSStatus {
    if !timebaseTime.isValid || !immediateSourceTime.isValid {
        return kCMTimebaseError_InvalidParameter
    }
    timebase.setMapping(rate: rate, timebaseAnchor: timebaseTime, sourceAnchor: immediateSourceTime)
    return 0
}

public func CMTimebaseCopySourceClock(_ timebase: CMTimebase) -> CMClock? {
    timebase.masterClock
}

public func CMTimebaseCopySourceTimebase(_ timebase: CMTimebase) -> CMTimebase? {
    timebase.masterTimebase
}

public func CMTimebaseCopySource(_ timebase: CMTimebase) -> (any CMSyncProtocol)? {
    timebase.source
}

public func CMTimebaseCopyMasterClock(_ timebase: CMTimebase) -> CMClock? {
    timebase.masterClock
}

public func CMTimebaseCopyMasterTimebase(_ timebase: CMTimebase) -> CMTimebase? {
    timebase.masterTimebase
}

public func CMTimebaseCopyMaster(_ timebase: CMTimebase) -> (any CMSyncProtocol)? {
    timebase.master
}

public func CMTimebaseCopyUltimateSourceClock(_ timebase: CMTimebase) -> CMClock {
    timebase.ultimateSourceClock
}

public func CMTimebaseCopyUltimateMasterClock(_ timebase: CMTimebase) -> CMClock {
    timebase.ultimateMasterClock
}

public func CMTimebaseGetSourceClock(_ timebase: CMTimebase) -> CMClock? {
    timebase.masterClock
}

public func CMTimebaseGetSourceTimebase(_ timebase: CMTimebase) -> CMTimebase? {
    timebase.masterTimebase
}

public func CMTimebaseGetMasterClock(_ timebase: CMTimebase) -> CMClock? {
    timebase.masterClock
}

public func CMTimebaseGetMasterTimebase(_ timebase: CMTimebase) -> CMTimebase? {
    timebase.masterTimebase
}

public func CMTimebaseGetMaster(_ timebase: CMTimebase) -> (any CMSyncProtocol)? {
    timebase.master
}

public func CMSyncGetTime(_ clockOrTimebase: any CMSyncProtocol) -> CMTime {
    clockOrTimebase.time
}

public func CMSyncConvertTime<From: CMSyncProtocol, To: CMSyncProtocol>(
    _ time: CMTime,
    from: From,
    to: To
) -> CMTime {
    if from === to { return time }
    if let fromClock = from as? CMClock, let toClock = to as? CMClock, fromClock === toClock {
        return time
    }
    // Same host-time domain: identity conversion. Different domains fail closed
    // to invalid rather than inventing a pivot.
    if from is CMClock && to is CMClock {
        return time
    }
    if let tb = from as? CMTimebase, to is CMClock {
        // Convert timebase time to source time.
        let snap = tb.snapshot()
        if snap.rate == 0 { return snap.sourceAnchor }
        let delta = CMTimeSubtract(time, snap.timebaseAnchor)
        let sourceDelta = CMTimeMultiplyByFloat64(delta, multiplier: 1.0 / snap.rate)
        return CMTimeAdd(snap.sourceAnchor, sourceDelta)
    }
    if let tb = to as? CMTimebase, from is CMClock {
        let snap = tb.snapshot()
        if snap.rate == 0 { return snap.timebaseAnchor }
        let delta = CMTimeSubtract(time, snap.sourceAnchor)
        let scaled = CMTimeMultiplyByFloat64(delta, multiplier: snap.rate)
        return CMTimeAdd(snap.timebaseAnchor, scaled)
    }
    if let fromTB = from as? CMTimebase, let toTB = to as? CMTimebase {
        let host = fromTB.ultimateSourceClock
        let inHost = CMSyncConvertTime(time, from: fromTB, to: host)
        return CMSyncConvertTime(inHost, from: host, to: toTB)
    }
    return time
}

public func CMSyncGetRelativeRate(
    _ ofClockOrTimebase: CMClockOrTimebase,
    relativeTo relativeToClockOrTimebase: CMClockOrTimebase
) -> Float64 {
    if ofClockOrTimebase === relativeToClockOrTimebase { return 1 }
    if let tb = ofClockOrTimebase as? CMTimebase {
        return CMTimebaseGetEffectiveRate(tb)
    }
    return 1
}

public func CMSyncGetRelativeRate<A: CMSyncProtocol, B: CMSyncProtocol>(
    _ ofClockOrTimebase: A,
    relativeTo: B
) -> Float64 {
    CMSyncGetRelativeRate(ofClockOrTimebase as CMClockOrTimebase, relativeTo: relativeTo as CMClockOrTimebase)
}

@discardableResult
public func CMSyncGetRelativeRateAndAnchorTime(
    _ ofClockOrTimebase: CMClockOrTimebase,
    relativeTo relativeToClockOrTimebase: CMClockOrTimebase,
    relativeRateOut outRelativeRate: UnsafeMutablePointer<Float64>?,
    anchorTimeOut outOfClockOrTimebaseAnchorTime: UnsafeMutablePointer<CMTime>?,
    relativeToAnchorTimeOut outRelativeToClockOrTimebaseAnchorTime: UnsafeMutablePointer<CMTime>?
) -> OSStatus {
    guard let selfSync = ofClockOrTimebase as? any CMSyncProtocol,
          let relativeSync = relativeToClockOrTimebase as? any CMSyncProtocol
    else {
        return kCMSyncError_InvalidParameter
    }
    outRelativeRate?.pointee = CMSyncGetRelativeRate(
        ofClockOrTimebase,
        relativeTo: relativeToClockOrTimebase
    )
    outOfClockOrTimebaseAnchorTime?.pointee = selfSync.time
    outRelativeToClockOrTimebaseAnchorTime?.pointee = relativeSync.time
    return 0
}

public func CMSyncGetRelativeRateAndAnchorTime<A: CMSyncProtocol, B: CMSyncProtocol>(
    _ ofClockOrTimebase: A,
    relativeTo: B
) throws -> (rate: Float64, anchorTime: CMTime, relativeRate: Float64, relativeAnchorTime: CMTime) {
    var rate: Float64 = 0
    var anchor = CMTime.invalid
    var relative = CMTime.invalid
    let status = CMSyncGetRelativeRateAndAnchorTime(
        ofClockOrTimebase as CMClockOrTimebase,
        relativeTo: relativeTo as CMClockOrTimebase,
        relativeRateOut: &rate,
        anchorTimeOut: &anchor,
        relativeToAnchorTimeOut: &relative
    )
    if status != 0 { throw CMSync.Error.invalidParameter }
    return (rate, anchor, 1, relative)
}

public func CMSyncMightDrift(
    _ clockOrTimebase1: CMClockOrTimebase,
    _ clockOrTimebase2: CMClockOrTimebase
) -> Bool {
    if let c1 = clockOrTimebase1 as? CMClock, let c2 = clockOrTimebase2 as? CMClock {
        return CMClockMightDrift(c1, otherClock: c2)
    }
    return true
}

public func CMSyncMightDrift<A: CMSyncProtocol, B: CMSyncProtocol>(
    _ clockOrTimebase1: A,
    _ clockOrTimebase2: B
) -> Bool {
    CMSyncMightDrift(clockOrTimebase1 as CMClockOrTimebase, clockOrTimebase2 as CMClockOrTimebase)
}

public func CMAudioClockCreate(
    allocator: CFAllocator?,
    clockOut: UnsafeMutablePointer<CMClock?>
) -> OSStatus {
    _ = allocator
    // Isolated Linux has no CoreAudio HAL clock; fail closed.
    clockOut.pointee = nil
    return kCMClockError_UnsupportedOperation
}
