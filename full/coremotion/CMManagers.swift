import Foundation

private final class CoreMotionStateLock {
    let lock = NSLock()

    func withLock<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }
}

public final class CMMotionManager: NSObject {
    private let state = CoreMotionStateLock()
    private var accelerometerActiveFlag = false
    private var gyroActiveFlag = false
    private var magnetometerActiveFlag = false
    private var deviceMotionActiveFlag = false
    private var storedAccelerometerInterval: TimeInterval = 0
    private var storedGyroInterval: TimeInterval = 0
    private var storedMagnetometerInterval: TimeInterval = 0
    private var storedDeviceMotionInterval: TimeInterval = 0
    private var storedReferenceFrame = CMAttitudeReferenceFrame.xArbitraryZVertical
    private var storedShowsMovement = false

    public override init() {
        super.init()
    }

    public var isAccelerometerAvailable: Bool { false }
    public var isGyroAvailable: Bool { false }
    public var isMagnetometerAvailable: Bool { false }
    public var isDeviceMotionAvailable: Bool { false }

    public var isAccelerometerActive: Bool {
        state.withLock { accelerometerActiveFlag }
    }

    public var isGyroActive: Bool {
        state.withLock { gyroActiveFlag }
    }

    public var isMagnetometerActive: Bool {
        state.withLock { magnetometerActiveFlag }
    }

    public var isDeviceMotionActive: Bool {
        state.withLock { deviceMotionActiveFlag }
    }

    public var accelerometerData: CMAccelerometerData? { nil }
    public var gyroData: CMGyroData? { nil }
    public var magnetometerData: CMMagnetometerData? { nil }
    public var deviceMotion: CMDeviceMotion? { nil }

    /// Stored interval only. The Darwin default is unobserved; Linux starts at 0.
    public var accelerometerUpdateInterval: TimeInterval {
        get { state.withLock { storedAccelerometerInterval } }
        set { state.withLock { storedAccelerometerInterval = newValue } }
    }

    public var gyroUpdateInterval: TimeInterval {
        get { state.withLock { storedGyroInterval } }
        set { state.withLock { storedGyroInterval = newValue } }
    }

    public var magnetometerUpdateInterval: TimeInterval {
        get { state.withLock { storedMagnetometerInterval } }
        set { state.withLock { storedMagnetometerInterval = newValue } }
    }

    public var deviceMotionUpdateInterval: TimeInterval {
        get { state.withLock { storedDeviceMotionInterval } }
        set { state.withLock { storedDeviceMotionInterval = newValue } }
    }

    public var attitudeReferenceFrame: CMAttitudeReferenceFrame {
        state.withLock { storedReferenceFrame }
    }

    public var showsDeviceMovementDisplay: Bool {
        get { state.withLock { storedShowsMovement } }
        set { state.withLock { storedShowsMovement = newValue } }
    }

    public class func availableAttitudeReferenceFrames() -> CMAttitudeReferenceFrame {
        []
    }

    public func startAccelerometerUpdates() {
        // Hardware unavailable: remain inactive and do not invent samples.
    }

    public func startAccelerometerUpdates(
        to queue: OperationQueue,
        withHandler handler: @escaping CMAccelerometerHandler
    ) {
        coreMotionDeliver(on: queue) {
            handler(nil, coreMotionUnavailableError())
        }
    }

    public func stopAccelerometerUpdates() {
        state.withLock { accelerometerActiveFlag = false }
    }

    public func startGyroUpdates() {}

    public func startGyroUpdates(
        to queue: OperationQueue,
        withHandler handler: @escaping CMGyroHandler
    ) {
        coreMotionDeliver(on: queue) {
            handler(nil, coreMotionUnavailableError())
        }
    }

    public func stopGyroUpdates() {
        state.withLock { gyroActiveFlag = false }
    }

    public func startMagnetometerUpdates() {}

    public func startMagnetometerUpdates(
        to queue: OperationQueue,
        withHandler handler: @escaping CMMagnetometerHandler
    ) {
        coreMotionDeliver(on: queue) {
            handler(nil, coreMotionUnavailableError())
        }
    }

    public func stopMagnetometerUpdates() {
        state.withLock { magnetometerActiveFlag = false }
    }

    public func startDeviceMotionUpdates() {}

    public func startDeviceMotionUpdates(
        to queue: OperationQueue,
        withHandler handler: @escaping CMDeviceMotionHandler
    ) {
        coreMotionDeliver(on: queue) {
            handler(nil, coreMotionUnavailableError())
        }
    }

    public func startDeviceMotionUpdates(using referenceFrame: CMAttitudeReferenceFrame) {
        state.withLock { storedReferenceFrame = referenceFrame }
    }

    public func startDeviceMotionUpdates(
        using referenceFrame: CMAttitudeReferenceFrame,
        to queue: OperationQueue,
        withHandler handler: @escaping CMDeviceMotionHandler
    ) {
        state.withLock { storedReferenceFrame = referenceFrame }
        coreMotionDeliver(on: queue) {
            handler(nil, coreMotionUnavailableError())
        }
    }

    public func stopDeviceMotionUpdates() {
        state.withLock { deviceMotionActiveFlag = false }
    }
}

public final class CMBatchedSensorManager: NSObject {
    private let state = CoreMotionStateLock()
    private var accelerometerActiveFlag = false
    private var deviceMotionActiveFlag = false

    public override init() {
        super.init()
    }

    public class var isAccelerometerSupported: Bool { false }
    public class var isDeviceMotionSupported: Bool { false }
    public class var authorizationStatus: CMAuthorizationStatus { .denied }

    public var isAccelerometerActive: Bool {
        state.withLock { accelerometerActiveFlag }
    }

    public var isDeviceMotionActive: Bool {
        state.withLock { deviceMotionActiveFlag }
    }

    public var accelerometerBatch: [CMAccelerometerData]? { nil }
    public var deviceMotionBatch: [CMDeviceMotion]? { nil }
    public var accelerometerDataFrequency: Int { 0 }
    public var deviceMotionDataFrequency: Int { 0 }

    public func startAccelerometerUpdates() {}

    public func startAccelerometerUpdates(
        handler: @escaping ([CMAccelerometerData]?, (any Error)?) -> Void
    ) {
        coreMotionDeliverPrivate {
            handler(nil, coreMotionUnavailableError())
        }
    }

    public func stopAccelerometerUpdates() {
        state.withLock { accelerometerActiveFlag = false }
    }

    public func startDeviceMotionUpdates() {}

    public func startDeviceMotionUpdates(
        handler: @escaping ([CMDeviceMotion]?, (any Error)?) -> Void
    ) {
        coreMotionDeliverPrivate {
            handler(nil, coreMotionUnavailableError())
        }
    }

    public func stopDeviceMotionUpdates() {
        state.withLock { deviceMotionActiveFlag = false }
    }
}

public final class CMAltimeter: NSObject {
    public override init() {
        super.init()
    }

    public class func authorizationStatus() -> CMAuthorizationStatus { .denied }
    public class func isRelativeAltitudeAvailable() -> Bool { false }
    public class func isAbsoluteAltitudeAvailable() -> Bool { false }

    public func startRelativeAltitudeUpdates(
        to queue: OperationQueue,
        withHandler handler: @escaping CMAltitudeHandler
    ) {
        coreMotionDeliver(on: queue) {
            handler(nil, coreMotionUnavailableError())
        }
    }

    public func stopRelativeAltitudeUpdates() {}

    public func startAbsoluteAltitudeUpdates(
        to queue: OperationQueue,
        withHandler handler: @escaping CMAbsoluteAltitudeHandler
    ) {
        coreMotionDeliver(on: queue) {
            handler(nil, coreMotionUnavailableError())
        }
    }

    public func stopAbsoluteAltitudeUpdates() {}
}

public final class CMPedometer: NSObject {
    public override init() {
        super.init()
    }

    public class func authorizationStatus() -> CMAuthorizationStatus { .denied }
    public class func isStepCountingAvailable() -> Bool { false }
    public class func isDistanceAvailable() -> Bool { false }
    public class func isFloorCountingAvailable() -> Bool { false }
    public class func isPaceAvailable() -> Bool { false }
    public class func isCadenceAvailable() -> Bool { false }
    public class func isPedometerEventTrackingAvailable() -> Bool { false }

    public func queryPedometerData(
        from start: Date,
        to end: Date,
        withHandler handler: @escaping CMPedometerHandler
    ) {
        _ = start
        _ = end
        coreMotionDeliverPrivate {
            handler(nil, coreMotionUnavailableError())
        }
    }

    public func startUpdates(
        from start: Date,
        withHandler handler: @escaping CMPedometerHandler
    ) {
        _ = start
        coreMotionDeliverPrivate {
            handler(nil, coreMotionUnavailableError())
        }
    }

    public func stopUpdates() {}

    public func startEventUpdates(handler: @escaping CMPedometerEventHandler) {
        coreMotionDeliverPrivate {
            handler(nil, coreMotionUnavailableError())
        }
    }

    public func stopEventUpdates() {}
}

public final class CMMotionActivityManager: NSObject {
    public override init() {
        super.init()
    }

    public class func authorizationStatus() -> CMAuthorizationStatus { .denied }
    public class func isActivityAvailable() -> Bool { false }

    public func queryActivityStarting(
        from start: Date,
        to end: Date,
        to queue: OperationQueue,
        withHandler handler: @escaping CMMotionActivityQueryHandler
    ) {
        _ = start
        _ = end
        coreMotionDeliver(on: queue) {
            handler(nil, coreMotionUnavailableError())
        }
    }

    public func startActivityUpdates(
        to queue: OperationQueue,
        withHandler handler: @escaping CMMotionActivityHandler
    ) {
        _ = queue
        _ = handler
        // Handler has no error channel. Do not invent an activity sample.
    }

    public func stopActivityUpdates() {}
}

public final class CMStepCounter: NSObject {
    public override init() {
        super.init()
    }

    public class func isStepCountingAvailable() -> Bool { false }

    public func queryStepCountStarting(
        from start: Date,
        to end: Date,
        to queue: OperationQueue,
        withHandler handler: @escaping CMStepQueryHandler
    ) {
        _ = start
        _ = end
        coreMotionDeliver(on: queue) {
            handler(0, coreMotionUnavailableError())
        }
    }

    public func startStepCountingUpdates(
        to queue: OperationQueue,
        updateOn stepCounts: Int,
        withHandler handler: @escaping CMStepUpdateHandler
    ) {
        _ = stepCounts
        coreMotionDeliver(on: queue) {
            handler(0, Date(), coreMotionUnavailableError())
        }
    }

    public func stopStepCountingUpdates() {}
}

public final class CMSensorRecorder: NSObject {
    public override init() {
        super.init()
    }

    public class func authorizationStatus() -> CMAuthorizationStatus { .denied }
    public class func isAccelerometerRecordingAvailable() -> Bool { false }
    public class func isAuthorizedForRecording() -> Bool { false }

    public func recordAccelerometer(forDuration duration: TimeInterval) {
        _ = duration
    }

    public func accelerometerData(from fromDate: Date, to toDate: Date) -> CMSensorDataList? {
        _ = fromDate
        _ = toDate
        return nil
    }
}

public protocol CMHeadphoneMotionManagerDelegate: NSObjectProtocol {
    func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager)
    func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager)
}

public extension CMHeadphoneMotionManagerDelegate {
    func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {}
    func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {}
}

public final class CMHeadphoneMotionManager: NSObject {
    public typealias DeviceMotionHandler = (CMDeviceMotion?, (any Error)?) -> Void

    private let state = CoreMotionStateLock()
    private weak var storedDelegate: (any CMHeadphoneMotionManagerDelegate)?
    private var deviceMotionActiveFlag = false
    private var connectionStatusActiveFlag = false

    public override init() {
        super.init()
    }

    public class func authorizationStatus() -> CMAuthorizationStatus { .denied }

    public var isDeviceMotionAvailable: Bool { false }
    public var deviceMotion: CMDeviceMotion? { nil }

    public var isDeviceMotionActive: Bool {
        state.withLock { deviceMotionActiveFlag }
    }

    public var isConnectionStatusActive: Bool {
        state.withLock { connectionStatusActiveFlag }
    }

    public weak var delegate: (any CMHeadphoneMotionManagerDelegate)? {
        get { state.withLock { storedDelegate } }
        set { state.withLock { storedDelegate = newValue } }
    }

    public func startDeviceMotionUpdates() {}

    public func startDeviceMotionUpdates(
        to queue: OperationQueue,
        withHandler handler: @escaping DeviceMotionHandler
    ) {
        coreMotionDeliver(on: queue) {
            handler(nil, coreMotionUnavailableError())
        }
    }

    public func stopDeviceMotionUpdates() {
        state.withLock { deviceMotionActiveFlag = false }
    }

    public func startConnectionStatusUpdates() {}

    public func stopConnectionStatusUpdates() {
        state.withLock { connectionStatusActiveFlag = false }
    }
}

public final class CMHeadphoneActivityManager: NSObject {
    public enum Status: Int, Sendable, Hashable {
        case disconnected = 0
        case connected = 1
    }

    public typealias ActivityHandler = (CMMotionActivity?, (any Error)?) -> Void
    public typealias StatusHandler = (CMHeadphoneActivityManager.Status, (any Error)?) -> Void

    private let state = CoreMotionStateLock()
    private var activityActiveFlag = false
    private var statusActiveFlag = false

    public override init() {
        super.init()
    }

    public class func authorizationStatus() -> CMAuthorizationStatus { .denied }

    public var isActivityAvailable: Bool { false }
    public var isStatusAvailable: Bool { false }

    public var isActivityActive: Bool {
        state.withLock { activityActiveFlag }
    }

    public var isStatusActive: Bool {
        state.withLock { statusActiveFlag }
    }

    public func startActivityUpdates(
        to queue: OperationQueue,
        withHandler handler: @escaping ActivityHandler
    ) {
        coreMotionDeliver(on: queue) {
            handler(nil, coreMotionUnavailableError())
        }
    }

    public func stopActivityUpdates() {
        state.withLock { activityActiveFlag = false }
    }

    public func startStatusUpdates(
        to queue: OperationQueue,
        withHandler handler: @escaping StatusHandler
    ) {
        coreMotionDeliver(on: queue) {
            handler(.disconnected, coreMotionUnavailableError())
        }
    }

    public func stopStatusUpdates() {
        state.withLock { statusActiveFlag = false }
    }
}

public protocol CMWaterSubmersionManagerDelegate: NSObjectProtocol {
    func manager(_ manager: CMWaterSubmersionManager, didUpdate event: CMWaterSubmersionEvent)
    func manager(
        _ manager: CMWaterSubmersionManager,
        didUpdate measurement: CMWaterSubmersionMeasurement
    )
    func manager(
        _ manager: CMWaterSubmersionManager,
        didUpdate measurement: CMWaterTemperature
    )
    func manager(_ manager: CMWaterSubmersionManager, errorOccurred error: any Error)
}

public final class CMWaterSubmersionManager: NSObject {
    private let state = CoreMotionStateLock()
    private weak var storedDelegate: (any CMWaterSubmersionManagerDelegate)?

    public override init() {
        super.init()
    }

    public class var authorizationStatus: CMAuthorizationStatus { .denied }
    public class var waterSubmersionAvailable: Bool { false }

    public var maximumDepth: Measurement<UnitLength>? { nil }

    /// Assigning the delegate does not synchronously invent a hardware error.
    public weak var delegate: (any CMWaterSubmersionManagerDelegate)? {
        get { state.withLock { storedDelegate } }
        set { state.withLock { storedDelegate = newValue } }
    }
}
