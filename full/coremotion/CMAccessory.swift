public protocol CMHeadphoneMotionManagerDelegate: NSObjectProtocol {
    func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager)
    func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager)
}

public extension CMHeadphoneMotionManagerDelegate {
    func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        _ = manager
    }

    func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        _ = manager
    }
}

open class CMHeadphoneMotionManager: NSObject, @unchecked Sendable {
    public typealias DeviceMotionHandler = (CMDeviceMotion?, (any Error)?) -> Void

    private let lock = NSLock()
    private weak var _delegate: CMHeadphoneMotionManagerDelegate?
    private var deviceMotionActive = false
    private var connectionStatusActive = false

    public class func authorizationStatus() -> CMAuthorizationStatus {
        CoreMotionHostBoundary.authorization
    }

    public var isDeviceMotionAvailable: Bool { false }
    public var deviceMotion: CMDeviceMotion? { nil }

    public var delegate: (any CMHeadphoneMotionManagerDelegate)? {
        get { lock.withLock { _delegate } }
        set { lock.withLock { _delegate = newValue } }
    }

    public var isDeviceMotionActive: Bool {
        lock.withLock { deviceMotionActive }
    }

    public var isConnectionStatusActive: Bool {
        lock.withLock { connectionStatusActive }
    }

    public func startDeviceMotionUpdates() {
        lock.withLock { deviceMotionActive = true }
    }

    public func startDeviceMotionUpdates(
        to queue: OperationQueue,
        withHandler handler: @escaping DeviceMotionHandler
    ) {
        lock.withLock { deviceMotionActive = true }
        CoreMotionHostBoundary.deliverUnavailable(to: queue, handler: handler)
    }

    public func stopDeviceMotionUpdates() {
        lock.withLock { deviceMotionActive = false }
    }

    public func startConnectionStatusUpdates() {
        lock.withLock { connectionStatusActive = true }
    }

    public func stopConnectionStatusUpdates() {
        lock.withLock { connectionStatusActive = false }
    }
}

open class CMHeadphoneActivityManager: NSObject, @unchecked Sendable {
    public enum Status: Int, Sendable, Hashable, BitwiseCopyable {
        case disconnected = 0
        case connected = 1
    }

    public typealias ActivityHandler = (CMMotionActivity?, (any Error)?) -> Void
    public typealias StatusHandler = (CMHeadphoneActivityManager.Status, (any Error)?) -> Void

    private let lock = NSLock()
    private var activityActive = false
    private var statusActive = false

    public class func authorizationStatus() -> CMAuthorizationStatus {
        CoreMotionHostBoundary.authorization
    }

    public var isActivityAvailable: Bool { false }
    public var isStatusAvailable: Bool { false }

    public var isActivityActive: Bool {
        lock.withLock { activityActive }
    }

    public var isStatusActive: Bool {
        lock.withLock { statusActive }
    }

    public func startActivityUpdates(
        to queue: OperationQueue,
        withHandler handler: @escaping ActivityHandler
    ) {
        lock.withLock { activityActive = true }
        CoreMotionHostBoundary.deliverUnavailable(to: queue, handler: handler)
    }

    public func stopActivityUpdates() {
        lock.withLock { activityActive = false }
    }

    public func startStatusUpdates(
        to queue: OperationQueue,
        withHandler handler: @escaping StatusHandler
    ) {
        lock.withLock { statusActive = true }
        queue.addOperation {
            handler(.disconnected, CoreMotionHostBoundary.unavailable)
        }
    }

    public func stopStatusUpdates() {
        lock.withLock { statusActive = false }
    }
}

public protocol CMWaterSubmersionManagerDelegate: NSObjectProtocol {
    func manager(_ manager: CMWaterSubmersionManager, didUpdate event: CMWaterSubmersionEvent)
    func manager(
        _ manager: CMWaterSubmersionManager,
        didUpdate measurement: CMWaterSubmersionMeasurement
    )
    func manager(_ manager: CMWaterSubmersionManager, didUpdate measurement: CMWaterTemperature)
    func manager(_ manager: CMWaterSubmersionManager, errorOccurred error: any Error)
}

open class CMWaterSubmersionManager: NSObject, @unchecked Sendable {
    private let lock = NSLock()
    private weak var _delegate: CMWaterSubmersionManagerDelegate?

    public class var authorizationStatus: CMAuthorizationStatus {
        CoreMotionHostBoundary.authorization
    }

    public class var waterSubmersionAvailable: Bool { false }

    public var maximumDepth: Measurement<UnitLength>? { nil }

    public var delegate: (any CMWaterSubmersionManagerDelegate)? {
        get { lock.withLock { _delegate } }
        set {
            let previous: (any CMWaterSubmersionManagerDelegate)?
            lock.lock()
            previous = _delegate
            _delegate = newValue
            lock.unlock()
            if newValue != nil, previous == nil {
                newValue?.manager(self, errorOccurred: CoreMotionHostBoundary.unavailable)
            }
        }
    }
}
