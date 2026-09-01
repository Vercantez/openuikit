open class CMMotionManager: NSObject, @unchecked Sendable {
    private let lock = NSLock()

    private var _accelerometerUpdateInterval = CoreMotionHostBoundary.defaultUpdateInterval
    private var _gyroUpdateInterval = CoreMotionHostBoundary.defaultUpdateInterval
    private var _magnetometerUpdateInterval = CoreMotionHostBoundary.defaultUpdateInterval
    private var _deviceMotionUpdateInterval = CoreMotionHostBoundary.defaultUpdateInterval
    private var _showsDeviceMovementDisplay = false
    private var _attitudeReferenceFrame = CMAttitudeReferenceFrame()

    public var isAccelerometerAvailable: Bool { false }
    public var isGyroAvailable: Bool { false }
    public var isMagnetometerAvailable: Bool { false }
    public var isDeviceMotionAvailable: Bool { false }

    public var accelerometerData: CMAccelerometerData? { nil }
    public var gyroData: CMGyroData? { nil }
    public var magnetometerData: CMMagnetometerData? { nil }
    public var deviceMotion: CMDeviceMotion? { nil }

    public var isAccelerometerActive: Bool { false }
    public var isGyroActive: Bool { false }
    public var isMagnetometerActive: Bool { false }
    public var isDeviceMotionActive: Bool { false }

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

    public func startAccelerometerUpdates() {}

    public func startAccelerometerUpdates(
        to queue: OperationQueue,
        withHandler handler: @escaping CMAccelerometerHandler
    ) {
        CoreMotionHostBoundary.deliverUnavailable(to: queue, handler: handler)
    }

    public func stopAccelerometerUpdates() {}

    public func startGyroUpdates() {}

    public func startGyroUpdates(
        to queue: OperationQueue,
        withHandler handler: @escaping CMGyroHandler
    ) {
        CoreMotionHostBoundary.deliverUnavailable(to: queue, handler: handler)
    }

    public func stopGyroUpdates() {}

    public func startMagnetometerUpdates() {}

    public func startMagnetometerUpdates(
        to queue: OperationQueue,
        withHandler handler: @escaping CMMagnetometerHandler
    ) {
        CoreMotionHostBoundary.deliverUnavailable(to: queue, handler: handler)
    }

    public func stopMagnetometerUpdates() {}

    public func startDeviceMotionUpdates() {}

    public func startDeviceMotionUpdates(
        to queue: OperationQueue,
        withHandler handler: @escaping CMDeviceMotionHandler
    ) {
        CoreMotionHostBoundary.deliverUnavailable(to: queue, handler: handler)
    }

    public func startDeviceMotionUpdates(using referenceFrame: CMAttitudeReferenceFrame) {
        _ = referenceFrame
    }

    public func startDeviceMotionUpdates(
        using referenceFrame: CMAttitudeReferenceFrame,
        to queue: OperationQueue,
        withHandler handler: @escaping CMDeviceMotionHandler
    ) {
        _ = referenceFrame
        CoreMotionHostBoundary.deliverUnavailable(to: queue, handler: handler)
    }

    public func stopDeviceMotionUpdates() {}
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
    public class var isAccelerometerSupported: Bool { false }
    public class var isDeviceMotionSupported: Bool { false }
    public class var authorizationStatus: CMAuthorizationStatus {
        CoreMotionHostBoundary.authorization
    }

    public var accelerometerDataFrequency: Int { 0 }
    public var deviceMotionDataFrequency: Int { 0 }
    public var accelerometerBatch: [CMAccelerometerData]? { nil }
    public var deviceMotionBatch: [CMDeviceMotion]? { nil }

    public var isAccelerometerActive: Bool { false }
    public var isDeviceMotionActive: Bool { false }

    public func startAccelerometerUpdates() {}

    public func startAccelerometerUpdates(
        handler: @escaping ([CMAccelerometerData]?, (any Error)?) -> Void
    ) {
        handler(nil, CoreMotionHostBoundary.unavailable)
    }

    public func stopAccelerometerUpdates() {}

    public func startDeviceMotionUpdates() {}

    public func startDeviceMotionUpdates(
        handler: @escaping ([CMDeviceMotion]?, (any Error)?) -> Void
    ) {
        handler(nil, CoreMotionHostBoundary.unavailable)
    }

    public func stopDeviceMotionUpdates() {}
}
