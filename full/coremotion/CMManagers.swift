open class CMMotionManager: NSObject, @unchecked Sendable {
    private let lock = NSLock()

    private var _accelerometerUpdateInterval = CoreMotionHostBoundary.defaultUpdateInterval
    private var _gyroUpdateInterval = CoreMotionHostBoundary.defaultUpdateInterval
    private var _magnetometerUpdateInterval = CoreMotionHostBoundary.defaultUpdateInterval
    private var _deviceMotionUpdateInterval = CoreMotionHostBoundary.defaultUpdateInterval
    private var _showsDeviceMovementDisplay = false
    private var _attitudeReferenceFrame = CMAttitudeReferenceFrame.xArbitraryZVertical
    private var _accelerometerActive = false
    private var _gyroActive = false
    private var _magnetometerActive = false
    private var _deviceMotionActive = false

    public var isAccelerometerAvailable: Bool { false }
    public var isGyroAvailable: Bool { false }
    public var isMagnetometerAvailable: Bool { false }
    public var isDeviceMotionAvailable: Bool { false }

    public var accelerometerData: CMAccelerometerData? { nil }
    public var gyroData: CMGyroData? { nil }
    public var magnetometerData: CMMagnetometerData? { nil }
    public var deviceMotion: CMDeviceMotion? { nil }

    public var isAccelerometerActive: Bool {
        lock.withLock { _accelerometerActive }
    }

    public var isGyroActive: Bool {
        lock.withLock { _gyroActive }
    }

    public var isMagnetometerActive: Bool {
        lock.withLock { _magnetometerActive }
    }

    public var isDeviceMotionActive: Bool {
        lock.withLock { _deviceMotionActive }
    }

    public var accelerometerUpdateInterval: TimeInterval {
        get { lock.withLock { _accelerometerUpdateInterval } }
        set { lock.withLock { _accelerometerUpdateInterval = newValue } }
    }

    public var gyroUpdateInterval: TimeInterval {
        get { lock.withLock { _gyroUpdateInterval } }
        set { lock.withLock { _gyroUpdateInterval = newValue } }
    }

    public var magnetometerUpdateInterval: TimeInterval {
        get { lock.withLock { _magnetometerUpdateInterval } }
        set { lock.withLock { _magnetometerUpdateInterval = newValue } }
    }

    public var deviceMotionUpdateInterval: TimeInterval {
        get { lock.withLock { _deviceMotionUpdateInterval } }
        set { lock.withLock { _deviceMotionUpdateInterval = newValue } }
    }

    public var showsDeviceMovementDisplay: Bool {
        get { lock.withLock { _showsDeviceMovementDisplay } }
        set { lock.withLock { _showsDeviceMovementDisplay = newValue } }
    }

    public var attitudeReferenceFrame: CMAttitudeReferenceFrame {
        lock.withLock { _attitudeReferenceFrame }
    }

    public class func availableAttitudeReferenceFrames() -> CMAttitudeReferenceFrame {
        []
    }

    public func startAccelerometerUpdates() {
        lock.withLock { _accelerometerActive = true }
    }

    public func startAccelerometerUpdates(
        to queue: OperationQueue,
        withHandler handler: @escaping CMAccelerometerHandler
    ) {
        lock.withLock { _accelerometerActive = true }
        CoreMotionHostBoundary.deliverUnavailable(to: queue, handler: handler)
    }

    public func stopAccelerometerUpdates() {
        lock.withLock { _accelerometerActive = false }
    }

    public func startGyroUpdates() {
        lock.withLock { _gyroActive = true }
    }

    public func startGyroUpdates(
        to queue: OperationQueue,
        withHandler handler: @escaping CMGyroHandler
    ) {
        lock.withLock { _gyroActive = true }
        CoreMotionHostBoundary.deliverUnavailable(to: queue, handler: handler)
    }

    public func stopGyroUpdates() {
        lock.withLock { _gyroActive = false }
    }

    public func startMagnetometerUpdates() {
        lock.withLock { _magnetometerActive = true }
    }

    public func startMagnetometerUpdates(
        to queue: OperationQueue,
        withHandler handler: @escaping CMMagnetometerHandler
    ) {
        lock.withLock { _magnetometerActive = true }
        CoreMotionHostBoundary.deliverUnavailable(to: queue, handler: handler)
    }

    public func stopMagnetometerUpdates() {
        lock.withLock { _magnetometerActive = false }
    }

    public func startDeviceMotionUpdates() {
        lock.withLock {
            _deviceMotionActive = true
            _attitudeReferenceFrame = .xArbitraryZVertical
        }
    }

    public func startDeviceMotionUpdates(
        to queue: OperationQueue,
        withHandler handler: @escaping CMDeviceMotionHandler
    ) {
        startDeviceMotionUpdates()
        CoreMotionHostBoundary.deliverUnavailable(to: queue, handler: handler)
    }

    public func startDeviceMotionUpdates(using referenceFrame: CMAttitudeReferenceFrame) {
        lock.withLock {
            _deviceMotionActive = true
            _attitudeReferenceFrame = referenceFrame
        }
    }

    public func startDeviceMotionUpdates(
        using referenceFrame: CMAttitudeReferenceFrame,
        to queue: OperationQueue,
        withHandler handler: @escaping CMDeviceMotionHandler
    ) {
        startDeviceMotionUpdates(using: referenceFrame)
        CoreMotionHostBoundary.deliverUnavailable(to: queue, handler: handler)
    }

    public func stopDeviceMotionUpdates() {
        lock.withLock { _deviceMotionActive = false }
    }
}

open class CMAltimeter: NSObject, @unchecked Sendable {
    public class func isRelativeAltitudeAvailable() -> Bool { false }
    public class func isAbsoluteAltitudeAvailable() -> Bool { false }
    public class func authorizationStatus() -> CMAuthorizationStatus {
        CoreMotionHostBoundary.authorization
    }

    public func startRelativeAltitudeUpdates(
        to queue: OperationQueue,
        withHandler handler: @escaping CMAltitudeHandler
    ) {
        CoreMotionHostBoundary.deliverUnavailable(to: queue, handler: handler)
    }

    public func stopRelativeAltitudeUpdates() {}

    public func startAbsoluteAltitudeUpdates(
        to queue: OperationQueue,
        withHandler handler: @escaping CMAbsoluteAltitudeHandler
    ) {
        CoreMotionHostBoundary.deliverUnavailable(to: queue, handler: handler)
    }

    public func stopAbsoluteAltitudeUpdates() {}
}

open class CMMotionActivityManager: NSObject, @unchecked Sendable {
    public class func isActivityAvailable() -> Bool { false }
    public class func authorizationStatus() -> CMAuthorizationStatus {
        CoreMotionHostBoundary.authorization
    }

    public func queryActivityStarting(
        from start: Date,
        to end: Date,
        to queue: OperationQueue,
        withHandler handler: @escaping CMMotionActivityQueryHandler
    ) {
        _ = start
        _ = end
        CoreMotionHostBoundary.deliverUnavailable(to: queue, handler: handler)
    }

    public func startActivityUpdates(
        to queue: OperationQueue,
        withHandler handler: @escaping CMMotionActivityHandler
    ) {
        _ = queue
        _ = handler
    }

    public func stopActivityUpdates() {}
}

open class CMPedometer: NSObject, @unchecked Sendable {
    public class func isStepCountingAvailable() -> Bool { false }
    public class func isDistanceAvailable() -> Bool { false }
    public class func isFloorCountingAvailable() -> Bool { false }
    public class func isPaceAvailable() -> Bool { false }
    public class func isCadenceAvailable() -> Bool { false }
    public class func isPedometerEventTrackingAvailable() -> Bool { false }
    public class func authorizationStatus() -> CMAuthorizationStatus {
        CoreMotionHostBoundary.authorization
    }

    public func queryPedometerData(
        from start: Date,
        to end: Date,
        withHandler handler: @escaping CMPedometerHandler
    ) {
        _ = start
        _ = end
        handler(nil, CoreMotionHostBoundary.unavailable)
    }

    public func startUpdates(from start: Date, withHandler handler: @escaping CMPedometerHandler) {
        _ = start
        handler(nil, CoreMotionHostBoundary.unavailable)
    }

    public func stopUpdates() {}

    public func startEventUpdates(handler: @escaping CMPedometerEventHandler) {
        handler(nil, CoreMotionHostBoundary.unavailable)
    }

    public func stopEventUpdates() {}
}

open class CMStepCounter: NSObject, @unchecked Sendable {
    public class func isStepCountingAvailable() -> Bool { false }

    public func queryStepCountStarting(
        from start: Date,
        to end: Date,
        to queue: OperationQueue,
        withHandler handler: @escaping CMStepQueryHandler
    ) {
        _ = start
        _ = end
        queue.addOperation {
            handler(0, CoreMotionHostBoundary.unavailable)
        }
    }

    public func startStepCountingUpdates(
        to queue: OperationQueue,
        updateOn stepCounts: Int,
        withHandler handler: @escaping CMStepUpdateHandler
    ) {
        _ = stepCounts
        queue.addOperation {
            handler(0, Date(), CoreMotionHostBoundary.unavailable)
        }
    }

    public func stopStepCountingUpdates() {}
}

open class CMSensorRecorder: NSObject {
    public class func isAccelerometerRecordingAvailable() -> Bool { false }
    public class func isAuthorizedForRecording() -> Bool { false }
    public class func authorizationStatus() -> CMAuthorizationStatus {
        CoreMotionHostBoundary.authorization
    }

    public func recordAccelerometer(forDuration duration: TimeInterval) {
        _ = duration
    }

    public func accelerometerData(from fromDate: Date, to toDate: Date) -> CMSensorDataList? {
        _ = fromDate
        _ = toDate
        return nil
    }
}

open class CMBatchedSensorManager: NSObject, @unchecked Sendable {
    private let lock = NSLock()
    private var accelerometerActive = false
    private var deviceMotionActive = false

    public class var isAccelerometerSupported: Bool { false }
    public class var isDeviceMotionSupported: Bool { false }
    public class var authorizationStatus: CMAuthorizationStatus {
        CoreMotionHostBoundary.authorization
    }

    public var accelerometerDataFrequency: Int { 0 }
    public var deviceMotionDataFrequency: Int { 0 }
    public var accelerometerBatch: [CMAccelerometerData]? { nil }
    public var deviceMotionBatch: [CMDeviceMotion]? { nil }

    public var isAccelerometerActive: Bool {
        lock.withLock { accelerometerActive }
    }

    public var isDeviceMotionActive: Bool {
        lock.withLock { deviceMotionActive }
    }

    public func startAccelerometerUpdates() {
        lock.withLock { accelerometerActive = true }
    }

    public func startAccelerometerUpdates(
        handler: @escaping ([CMAccelerometerData]?, (any Error)?) -> Void
    ) {
        lock.withLock { accelerometerActive = true }
        handler(nil, CoreMotionHostBoundary.unavailable)
    }

    public func stopAccelerometerUpdates() {
        lock.withLock { accelerometerActive = false }
    }

    public func startDeviceMotionUpdates() {
        lock.withLock { deviceMotionActive = true }
    }

    public func startDeviceMotionUpdates(
        handler: @escaping ([CMDeviceMotion]?, (any Error)?) -> Void
    ) {
        lock.withLock { deviceMotionActive = true }
        handler(nil, CoreMotionHostBoundary.unavailable)
    }

    public func stopDeviceMotionUpdates() {
        lock.withLock { deviceMotionActive = false }
    }
}
