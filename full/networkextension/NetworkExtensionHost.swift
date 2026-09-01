import Foundation
#if canImport(Dispatch)
import Dispatch
#endif

/// Linux host callback scheduler for asynchronous `NetworkExtension` work.
///
/// Every completion-handler and delegate delivery that this module treats as
/// asynchronous is enqueued here, exactly once, after the calling function
/// returns. This queue is a host control. It is not Apple's
/// `nesessionmanager` queue and is not evidence of Darwin callback identity.
@_spi(OpenUIKitHost)
public enum NetworkExtensionHostCallback {
    public static let specificKey = DispatchSpecificKey<UInt8>()

    public static let queue: DispatchQueue = {
        let queue = DispatchQueue(
            label: "org.openuikit.NetworkExtension.host-callback"
        )
        queue.setSpecific(key: specificKey, value: 1)
        return queue
    }()

    public static var isCurrentQueue: Bool {
        DispatchQueue.getSpecific(key: specificKey) == 1
    }

    public static func schedule(_ body: @escaping () -> Void) {
        let work = _NEUncheckedWork(body)
        queue.async {
            work.run()
        }
    }
}

private struct _NEUncheckedWork: @unchecked Sendable {
    let body: () -> Void

    init(_ body: @escaping () -> Void) {
        self.body = body
    }

    func run() {
        body()
    }
}

/// Exactly-once box for a single asynchronous completion.
final class _NEOnceDelivery<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var handler: ((Value) -> Void)?

    init(_ handler: @escaping (Value) -> Void) {
        self.handler = handler
    }

    func schedule(_ value: Value) {
        NetworkExtensionHostCallback.schedule { [self] in
            self.deliver(value)
        }
    }

    func deliver(_ value: Value) {
        let handler: ((Value) -> Void)?
        lock.lock()
        handler = self.handler
        self.handler = nil
        lock.unlock()
        handler?(value)
    }
}

func _NEOncePair<A, B>(
    _ handler: @escaping (A, B) -> Void
) -> _NEOnceDelivery<(A, B)> {
    _NEOnceDelivery { pair in
        handler(pair.0, pair.1)
    }
}
