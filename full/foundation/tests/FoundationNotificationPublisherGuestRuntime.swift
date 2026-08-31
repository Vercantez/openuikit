import Combine
import Foundation

private final class DemandSubscriber: Subscriber {
    typealias Input = Notification
    typealias Failure = Never

    var subscription: (any Subscription)?
    var values: [Notification] = []

    func receive(subscription: any Subscription) {
        self.subscription = subscription
        subscription.request(.max(1))
    }

    func receive(_ input: Notification) -> Subscribers.Demand {
        values.append(input)
        return .none
    }

    func receive(completion: Subscribers.Completion<Never>) {
        preconditionFailure("NotificationCenter publisher must not complete")
    }
}

private final class Sender {}

private final class RecursiveSubscriber: Subscriber {
    typealias Input = Notification
    typealias Failure = Never

    let center: NotificationCenter
    let name: Notification.Name
    let sender: Sender
    var subscription: (any Subscription)?
    var values: [Notification] = []

    init(center: NotificationCenter, name: Notification.Name, sender: Sender) {
        self.center = center
        self.name = name
        self.sender = sender
    }

    func receive(subscription: any Subscription) {
        self.subscription = subscription
        subscription.request(.unlimited)
    }

    func receive(_ input: Notification) -> Subscribers.Demand {
        values.append(input)
        if values.count == 1 {
            center.post(name: name, object: sender)
        }
        return .none
    }

    func receive(completion: Subscribers.Completion<Never>) {
        preconditionFailure("NotificationCenter publisher must not complete")
    }
}

@main
struct FoundationNotificationPublisherGuestRuntime {
    static func main() {
        let center = NotificationCenter()
        let name = Notification.Name("FoundationNotificationPublisherGuestRuntime")
        let sender = Sender()
        let other = Sender()
        let publisher = center.publisher(for: name, object: sender)

        precondition(
            publisher == NotificationCenter.Publisher(
                center: center,
                name: name,
                object: sender
            )
        )
        precondition(
            publisher != center.publisher(for: name, object: other)
        )

        let subscriber = DemandSubscriber()
        publisher.receive(subscriber: subscriber)
        precondition(center._observerCount == 1)

        // Name and sender filters are exact; values beyond demand are dropped.
        center.post(name: Notification.Name("other"), object: sender)
        center.post(name: name, object: other)
        center.post(name: name, object: sender)
        center.post(name: name, object: sender)
        precondition(subscriber.values.count == 1)
        precondition(subscriber.values[0].object as AnyObject? === sender)

        subscriber.subscription?.request(.max(1))
        center.post(name: name, object: sender)
        precondition(subscriber.values.count == 2)

        let recursive = RecursiveSubscriber(
            center: center,
            name: name,
            sender: sender
        )
        publisher.receive(subscriber: recursive)
        center.post(name: name, object: sender)
        precondition(recursive.values.count == 2)
        recursive.subscription?.cancel()

        subscriber.subscription?.cancel()
        subscriber.subscription?.cancel()
        precondition(center._observerCount == 0)
        center.post(name: name, object: sender)
        precondition(subscriber.values.count == 2)

        let suite = "OpenUIKit.FoundationNotificationPublisherGuestRuntime"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        var defaultsValues: [Notification] = []
        let cancellable = NotificationCenter.default.publisher(
            for: UserDefaults.didChangeNotification,
            object: defaults
        ).sink { defaultsValues.append($0) }
        defaults.set(7, forKey: "value")
        defaults.set(7, forKey: "value")
        defaults.removeObject(forKey: "value")
        defaults.removeObject(forKey: "value")
        defaults.register(defaults: ["registered": true])
        defaults.setPersistentDomain(["persisted": 1], forName: suite)
        defaults.removePersistentDomain(forName: suite)
        defaults.setVolatileDomain(["volatile": 2], forName: "volatile")
        defaults.removeVolatileDomain(forName: "volatile")
        precondition(defaultsValues.count == 9)
        defaults.addSuite(named: "other")
        defaults.removeSuite(named: "other")
        _ = defaults.synchronize()
        precondition(defaultsValues.count == 9)
        precondition(
            defaultsValues.allSatisfy {
                $0.object as AnyObject? === defaults
            }
        )
        precondition(
            UserDefaults.didChangeNotification.rawValue ==
                "NSUserDefaultsDidChangeNotification"
        )
        cancellable.cancel()
        defaults.set(8, forKey: "value")
        precondition(defaultsValues.count == 9)
        defaults.removePersistentDomain(forName: suite)

        print(
            "FOUNDATION_NOTIFICATION_PUBLISHER_GUEST_OK " +
                "identity=opencombine demand=bounded filters=name,object " +
                "delivery=recursive-serialized " +
                "cancel=idempotent userdefaults=synchronous,mutations-9"
        )
    }
}
