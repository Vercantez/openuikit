// Combine overlay for the canonical notification identity exported by the
// Linux-hosted Mach-O Foundation facade.
//
// OpenUIKit owns Notification and NotificationCenter because it is compiled
// while Foundation is hidden. Foundation aliases those exact declarations,
// and this file adds Apple's Foundation-owned Combine surface to that single
// identity. The publisher deliberately conforms to OpenCombine's protocols:
// the literal Combine module re-exports that module, so apps importing either
// spelling share subscriptions, operators, and AnyCancellable values.

import Darwin
import OpenCombine
import OpenUIKit

public extension NotificationCenter {
    /// A publisher that emits matching notifications synchronously on the
    /// posting thread.
    struct Publisher: OpenCombine.Publisher {
        public typealias Output = Notification
        public typealias Failure = Never

        /// The notification center this publisher observes.
        public let center: NotificationCenter

        /// The name of notifications emitted by this publisher.
        public let name: Notification.Name

        /// An optional posting object filter, matched by identity.
        public let object: AnyObject?

        public init(
            center: NotificationCenter,
            name: Notification.Name,
            object: AnyObject? = nil
        ) {
            self.center = center
            self.name = name
            self.object = object
        }

        public func receive<Downstream: OpenCombine.Subscriber>(
            subscriber: Downstream
        ) where Downstream.Input == Notification, Downstream.Failure == Never {
            let subscription = _NotificationCenterSubscription(
                center: center,
                name: name,
                object: object,
                downstream: subscriber
            )
            subscriber.receive(subscription: subscription)
        }
    }

    /// Returns a publisher that emits notifications with `name`, optionally
    /// restricted to one posting object by identity.
    func publisher(
        for name: Notification.Name,
        object: AnyObject? = nil
    ) -> Publisher {
        Publisher(center: self, name: name, object: object)
    }
}

extension NotificationCenter.Publisher: Equatable {
    public static func == (
        lhs: NotificationCenter.Publisher,
        rhs: NotificationCenter.Publisher
    ) -> Bool {
        lhs.center === rhs.center && lhs.name == rhs.name &&
            lhs.object === rhs.object
    }
}

/// Demand-aware bridge between NotificationCenter's synchronous observer API
/// and OpenCombine. Registration happens before the downstream receives the
/// subscription, matching Combine: notifications emitted before demand are
/// ignored rather than buffered. Cancellation is idempotent and immediately
/// releases the center's retained observer closure (and therefore downstream).
private final class _NotificationCenterSubscription<Downstream>:
    OpenCombine.Subscription,
    CustomStringConvertible,
    CustomReflectable,
    CustomPlaygroundDisplayConvertible
where Downstream: OpenCombine.Subscriber,
      Downstream.Input == Notification,
      Downstream.Failure == Never {
    private let lock = NSLock()
    private let downstreamLock = _FoundationRecursiveLock()
    private var demand = OpenCombine.Subscribers.Demand.none
    private var center: NotificationCenter?
    private let name: Notification.Name
    private var object: AnyObject?
    private var observation: AnyObject?

    init(
        center: NotificationCenter,
        name: Notification.Name,
        object: AnyObject?,
        downstream: Downstream
    ) {
        self.center = center
        self.name = name
        self.object = object
        observation = center.addObserver(
            forName: name,
            object: object,
            queue: nil
        ) { [weak self] notification in
            self?.receive(notification, downstream: downstream)
        }
    }

    deinit {
        cancel()
    }

    func request(_ newDemand: OpenCombine.Subscribers.Demand) {
        guard newDemand > 0 else { return }
        lock.withLock {
            guard center != nil else { return }
            demand += newDemand
        }
    }

    func cancel() {
        let registration: (NotificationCenter, AnyObject)? = lock.withLock {
            guard let center, let observation else { return nil }
            self.center = nil
            self.object = nil
            self.observation = nil
            demand = .none
            return (center, observation)
        }
        if let (center, observation) = registration {
            center.removeObserver(observation)
        }
    }

    private func receive(_ notification: Notification, downstream: Downstream) {
        let shouldDeliver = lock.withLock { () -> Bool in
            guard center != nil, demand > 0 else { return false }
            demand -= 1
            return true
        }
        guard shouldDeliver else { return }

        // Never hold the state lock across arbitrary downstream code. A sink
        // may post recursively, request more demand, or cancel itself.
        downstreamLock.withLock {
            let additionalDemand = downstream.receive(notification)
            guard additionalDemand > 0 else { return }
            // Publish returned demand before another posting thread can enter
            // downstream. Otherwise that thread could observe zero demand and
            // spuriously drop a value between `receive` and this update.
            lock.withLock {
                guard center != nil else { return }
                demand += additionalDemand
            }
        }
    }

    var description: String { "NotificationCenter Observer" }

    var customMirror: Mirror {
        lock.withLock {
            Mirror(
                self,
                children: [
                    "center": center as Any,
                    "name": name,
                    "object": object as Any,
                    "demand": demand,
                ]
            )
        }
    }

    var playgroundDescription: Any { description }
}

/// Combine serializes calls into a subscriber while allowing a subscriber to
/// post recursively on the same thread. Darwin's recursive pthread mutex is
/// the primitive beneath Foundation's native implementation; using it here
/// avoids both concurrent downstream calls and a deadlock on recursive posts.
private final class _FoundationRecursiveLock: @unchecked Sendable {
    private var mutex = pthread_mutex_t()

    init() {
        var attributes = pthread_mutexattr_t()
        precondition(pthread_mutexattr_init(&attributes) == 0)
        precondition(
            pthread_mutexattr_settype(&attributes, PTHREAD_MUTEX_RECURSIVE) == 0
        )
        precondition(pthread_mutex_init(&mutex, &attributes) == 0)
        precondition(pthread_mutexattr_destroy(&attributes) == 0)
    }

    deinit {
        precondition(pthread_mutex_destroy(&mutex) == 0)
    }

    func withLock<Result>(_ body: () throws -> Result) rethrows -> Result {
        precondition(pthread_mutex_lock(&mutex) == 0)
        defer { precondition(pthread_mutex_unlock(&mutex) == 0) }
        return try body()
    }
}
