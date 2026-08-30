// Native-ELF external-client oracle. Foundation values are canonical, while
// the center deliberately remains OpenUIKit's strict selector-registry center
// because corelibs Foundation has no Objective-C selector observer API.

#if canImport(ObjectiveC)
#error("native-ELF oracle must not see ObjectiveC")
#endif

import Foundation
import UIKit

@MainActor
private final class RegistryTarget: SelectorDispatching {
    var notifications: [UIKit.Notification] = []

    func perform(_ name: String, with sender: Any?) -> Bool {
        guard name == "receive:",
              let notification = sender as? UIKit.Notification else {
            return false
        }
        notifications.append(notification)
        return true
    }
}

@main
private struct NativeELFMain {
    @MainActor
    static func main() {
        var failures: [String] = []
        func check(_ name: String, _ condition: @autoclosure () -> Bool) {
            let passed = condition()
            print("\(name)=\(passed ? "true" : "false")")
            if !passed { failures.append(name) }
        }

        print("NATIVE_ELF_BEGIN")
        check("identity.notification",
              UIKit.Notification.self == Foundation.Notification.self)
        check("identity.nsnotification",
              UIKit.NSNotification.self == Foundation.NSNotification.self)
        check("identity.queue",
              UIKit.OperationQueue.self == Foundation.OperationQueue.self)
        check("identity.centerDistinct",
              ObjectIdentifier(UIKit.NotificationCenter.self)
                  != ObjectIdentifier(Foundation.NotificationCenter.self))

        let name = UIKit.Notification.Name("OpenUIKitNativeELF")
        let otherName = UIKit.Notification.Name("OpenUIKitNativeELFOther")
        let object = UIView()
        let otherObject = UIView()
        let payload = UIView()
        let center = UIKit.NotificationCenter()
        check("branch.customCenter", center._observerCount == 0)

        let target = RegistryTarget()
        center.addObserver(target, selector: .named("receive:"),
                           name: name, object: object)
        center.post(name: name, object: object, userInfo: ["payload": payload])
        check("registry.once", target.notifications.count == 1)
        check("registry.objectIdentity",
              target.notifications.first?.object as AnyObject? === object)
        check("registry.userInfoIdentity",
              target.notifications.first?.userInfo?["payload"] as AnyObject?
                  === payload)

        center.post(name: name, object: otherObject)
        center.post(name: name, object: nil)
        check("filter.strictIdentity", target.notifications.count == 1)

        var wildcardNames: [UIKit.Notification.Name] = []
        let wildcard = center.addObserver(
            forName: nil, object: nil, queue: nil
        ) { wildcardNames.append($0.name) }
        center.post(name: name, object: nil)
        center.post(name: otherName, object: nil)
        check("wildcard.names", wildcardNames == [name, otherName])
        center.removeObserver(wildcard)

        let duplicate = RegistryTarget()
        center.addObserver(duplicate, selector: .named("receive:"),
                           name: name, object: object)
        center.addObserver(duplicate, selector: .named("receive:"),
                           name: name, object: object)
        center.post(name: name, object: object)
        check("duplicate.eachDelivered", duplicate.notifications.count == 2)
        center.removeObserver(duplicate, name: name, object: object)
        center.post(name: name, object: object)
        check("removal.exactStopped", duplicate.notifications.count == 2)

        let reentrant = UIKit.NotificationCenter()
        var order: [Int] = []
        var second: NotificationToken?
        let first = reentrant.addObserver(
            forName: name, object: nil, queue: nil
        ) { _ in
            order.append(1)
            if let second { reentrant.removeObserver(second) }
        }
        second = reentrant.addObserver(
            forName: name, object: nil, queue: nil
        ) { _ in order.append(2) }
        reentrant.post(name: name, object: nil)
        check("reentrant.snapshotRemoval", order == [1, 2])
        reentrant.removeObserver(first)

        let tokenCenter = UIKit.NotificationCenter()
        var tokenDeliveries = 0
        weak var weakToken: NotificationToken?
        func registerAndRemoveThroughProtocol() {
            let token = tokenCenter.addObserver(
                forName: name, object: nil, queue: nil
            ) { _ in tokenDeliveries += 1 }
            weakToken = token
            let protocolToken: any Foundation.NSObjectProtocol = token
            check("token.protocolIdentity",
                  (protocolToken as AnyObject) === token)
            tokenCenter.post(name: name, object: nil)
            tokenCenter.removeObserver(protocolToken)
            tokenCenter.post(name: name, object: nil)
            check("token.removalThroughProtocol", tokenDeliveries == 1)
        }
        registerAndRemoveThroughProtocol()
        check("token.weakReleased", weakToken == nil)

        let weakCenter = UIKit.NotificationCenter()
        weak var weakObserver: RegistryTarget?
        func registerDisposable() {
            let observer = RegistryTarget()
            weakObserver = observer
            weakCenter.addObserver(observer, selector: .named("receive:"),
                                   name: name, object: nil)
            check("weak.observerBeforeRelease", weakObserver != nil)
        }
        registerDisposable()
        check("weak.observerAfterRelease", weakObserver == nil)
        weakCenter.post(name: name, object: nil)
        check("weak.observerReaped",
              weakObserver == nil && weakCenter._observerCount == 0)

        center.removeObserver(target)
        print("native.status=\(failures.isEmpty ? "PASS" : "FAIL")")
        if !failures.isEmpty {
            print("native.failures=\(failures.joined(separator: ","))")
        }
        print("NATIVE_ELF_END")
        precondition(failures.isEmpty)
    }
}
