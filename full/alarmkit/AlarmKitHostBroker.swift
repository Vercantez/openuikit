import Foundation

/// Broadcasts snapshots to independently cancellable AsyncStream subscribers.
/// Finish is only called from the owning manager's deallocation path.
/// Values are yielded to waiting iterators; there is no separate callback queue.
final class AlarmKitUpdateBroker<Element: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var latest: Element
    private var subscribers: [UUID: AsyncStream<Element>.Continuation] = [:]
    private var finished = false

    init(initial: Element) {
        latest = initial
    }

    func subscribe() -> AsyncStream<Element> {
        AsyncStream { continuation in
            let id = UUID()
            continuation.onTermination = { [weak self] _ in
                guard let self else { return }
                self.lock.lock()
                self.subscribers.removeValue(forKey: id)
                self.lock.unlock()
            }
            self.lock.lock()
            if self.finished {
                self.lock.unlock()
                continuation.finish()
                return
            }
            self.subscribers[id] = continuation
            let snapshot = self.latest
            self.lock.unlock()
            continuation.yield(snapshot)
        }
    }

    func publish(_ value: Element) {
        lock.lock()
        latest = value
        let targets = Array(subscribers.values)
        lock.unlock()
        for continuation in targets {
            continuation.yield(value)
        }
    }

    func finish() {
        lock.lock()
        finished = true
        let targets = Array(subscribers.values)
        subscribers.removeAll()
        lock.unlock()
        for continuation in targets {
            continuation.finish()
        }
    }
}
