import Foundation
@preconcurrency import Dispatch

open class CXCall: NSObject, @unchecked Sendable {
    public let uuid: UUID
    public private(set) var isOutgoing: Bool
    public private(set) var isOnHold: Bool
    public private(set) var hasConnected: Bool
    public private(set) var hasEnded: Bool

    init(uuid: UUID, outgoing: Bool) {
        self.uuid = uuid
        self.isOutgoing = outgoing
        self.isOnHold = false
        self.hasConnected = false
        self.hasEnded = false
        super.init()
    }

    func apply(_ update: CXCallUpdate) {
        _ = update
    }

    func markOutgoingConnecting() {
        isOutgoing = true
    }

    func markConnected() {
        hasConnected = true
    }

    func setOnHold(_ onHold: Bool) {
        isOnHold = onHold
    }

    func markEnded() {
        hasEnded = true
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? CXCall else { return false }
        return uuid == other.uuid
    }

    open override var hash: Int { uuid.hashValue }
}

open class CXCallUpdate: NSObject, NSCopying, @unchecked Sendable {
    public var remoteHandle: CXHandle? {
        didSet { remoteHandle = remoteHandle.flatMap { ($0.copy() as? CXHandle) ?? $0 } }
    }
    public var localizedCallerName: String?
    public var hasVideo: Bool = false
    public var supportsHolding: Bool = true
    public var supportsGrouping: Bool = true
    public var supportsUngrouping: Bool = true
    public var supportsDTMF: Bool = true

    public override init() {
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = CXCallUpdate()
        copy.remoteHandle = remoteHandle
        copy.localizedCallerName = localizedCallerName
        copy.hasVideo = hasVideo
        copy.supportsHolding = supportsHolding
        copy.supportsGrouping = supportsGrouping
        copy.supportsUngrouping = supportsUngrouping
        copy.supportsDTMF = supportsDTMF
        return copy
    }
}

public protocol CXCallObserverDelegate: NSObjectProtocol {
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall)
}

open class CXCallObserver: NSObject, @unchecked Sendable {
    private let stateLock = NSLock()
    private weak var delegate: (any CXCallObserverDelegate)?
    private var delegateQueue: DispatchQueue?

    public var calls: [CXCall] {
        CXCallKitRuntime.currentCalls()
    }

    public override init() {
        super.init()
        CXCallKitRuntime.addObserver(self)
    }

    open func setDelegate(
        _ delegate: (any CXCallObserverDelegate)?,
        queue: DispatchQueue?
    ) {
        stateLock.lock()
        self.delegate = delegate
        self.delegateQueue = queue
        stateLock.unlock()
    }

    func portableCallChanged(_ call: CXCall) {
        stateLock.lock()
        let delegate = self.delegate
        let queue = CXCallKitCallbackQueue(self.delegateQueue)
        stateLock.unlock()
        guard let delegate else { return }
        queue.async {
            delegate.callObserver(self, callChanged: call)
        }
    }
}
