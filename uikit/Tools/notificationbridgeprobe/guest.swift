// Literal-UIKit Foundation-hidden ARM64 Mach-O oracle. This file imports only
// UIKit; its notification names come from foundation-extension.swift, whose
// only import is the synthetic app-facing Foundation umbrella.

#if !canImport(Foundation)
#error("the app-facing guest must see the synthetic Foundation umbrella")
#endif
#if !canImport(ObjectiveC)
#error("the guest requires staged ObjectiveC interop")
#endif

import UIKit

@MainActor
private final class RuntimeTarget: UIViewController, SelectorDispatching {
    var zeroCount = 0
    var valueNotifications: [Notification] = []
    var objectNotifications: [NSNotification] = []
    var registryNames: [String] = []
    var registryNotifications: [Notification] = []

    @objc func zeroArgument() {
        zeroCount += 1
    }

    @objc func receiveValue(_ notification: Notification) {
        valueNotifications.append(notification)
    }

    @objc func receiveObject(_ notification: NSNotification) {
        objectNotifications.append(notification)
    }

    func perform(_ name: String, with sender: Any?) -> Bool {
        guard name == "portableNotification:",
              let notification = sender as? Notification else {
            registryNames.append(name)
            return false
        }
        registryNames.append(name)
        registryNotifications.append(notification)
        return true
    }
}

@MainActor
private final class RegistryTarget: SelectorDispatching {
    var notifications: [Notification] = []

    func perform(_ name: String, with sender: Any?) -> Bool {
        guard name == "portableNotification:",
              let notification = sender as? Notification else {
            return false
        }
        notifications.append(notification)
        return true
    }
}

@main
private struct NotificationGuestMain {
    @MainActor
    static func main() {
        var failures: [String] = []
        func check(_ name: String, _ condition: @autoclosure () -> Bool) {
            let passed = condition()
            print("\(name)=\(passed ? "true" : "false")")
            if !passed { failures.append(name) }
        }

        print("GUEST_BEGIN")
        let center = NotificationCenter()
        check("branch.customCenter", center._observerCount == 0)
        check("identity.notification",
              Notification.self == foundationNotificationType())
        check("identity.nsnotification",
              NSNotification.self == foundationNSNotificationType())
        check("identity.center",
              NotificationCenter.self == foundationNotificationCenterType())
        check("identity.defaultCenter",
              NotificationCenter.default === foundationDefaultNotificationCenter())
        check("identity.queue",
              OperationQueue.self == foundationOperationQueueType())
        check("extension.foundationOnlyVisible",
              Notification.Name.openUIKitGuestProbe.rawValue == "OpenUIKitGuestProbe")
        let focus = FocusGuestTarget(center: center)
        check("focus.directBothImports", focus.center === center)

        let object = UIView()
        let otherObject = UIView()
        let payload = UIView()
        let notification = Notification(
            name: .openUIKitGuestProbe,
            object: object,
            userInfo: ["payload": payload]
        )
        let box = notification._bridgeToObjectiveC()
        check("bridge.boxName", box.name == .openUIKitGuestProbe)
        check("bridge.boxObjectIdentity", box.object as AnyObject? === object)
        check("bridge.boxUserInfoIdentity",
              box.userInfo?["payload"] as AnyObject? === payload)
        let boxName: NSNotification.Name = .openUIKitGuestProbe
        check("bridge.nameSpelling", boxName == box.name)
        let constructed = NSNotification(
            name: boxName,
            object: object,
            userInfo: ["payload": payload]
        )
        check("bridge.labeledInitializer",
              constructed.name == boxName
                  && constructed.object as AnyObject? === object
                  && constructed.userInfo?["payload"] as AnyObject? === payload)

        var forced: Notification?
        Notification._forceBridgeFromObjectiveC(box, result: &forced)
        check("bridge.forceWitness",
              forced?.object as AnyObject? === object
                  && forced?.userInfo?["payload"] as AnyObject? === payload)
        var conditional: Notification?
        let didBridge = Notification._conditionallyBridgeFromObjectiveC(
            box, result: &conditional
        )
        check("bridge.conditionalWitness",
              didBridge && conditional?.name == .openUIKitGuestProbe)
        let unconditional = Notification._unconditionallyBridgeFromObjectiveC(box)
        check("bridge.unconditionalWitness",
              unconditional.object as AnyObject? === object)
        let empty = Notification._unconditionallyBridgeFromObjectiveC(nil)
        check("bridge.nilIsEmpty",
              empty.name.rawValue.isEmpty && empty.object == nil
                  && empty.userInfo == nil)

        let first = RuntimeTarget()
        let second = RuntimeTarget()
        let zeroSelector = #selector(RuntimeTarget.zeroArgument)
        let valueSelector = #selector(RuntimeTarget.receiveValue(_:))
        let objectSelector = #selector(RuntimeTarget.receiveObject(_:))
        check("runtime.respondsZero", first.responds(to: zeroSelector))
        check("runtime.respondsValue", first.responds(to: valueSelector))
        check("runtime.respondsObject", first.responds(to: objectSelector))
        let preboxedTarget = RuntimeTarget()
        let preboxedSend = SelectorDispatch.send(
            valueSelector, to: preboxedTarget, sender: constructed
        )
        check("bridge.preboxedValueThunk",
              preboxedSend && preboxedTarget.valueNotifications.count == 1
                  && preboxedTarget.valueNotifications[0].object as AnyObject? === object
                  && preboxedTarget.valueNotifications[0].userInfo?["payload"]
                      as AnyObject? === payload)

        var misses: [String] = []
        let priorMiss = SelectorDispatch.onUnresolved
        SelectorDispatch.onUnresolved = { _, name in misses.append(name) }
        center.addObserver(first, selector: zeroSelector,
                           name: .openUIKitGuestProbe, object: object)
        center.addObserver(first, selector: valueSelector,
                           name: .openUIKitGuestProbe, object: object)
        center.addObserver(first, selector: objectSelector,
                           name: .openUIKitGuestProbe, object: object)
        center.addObserver(second, selector: objectSelector,
                           name: .openUIKitGuestProbe, object: object)
        center.addObserver(focus,
                           selector: #selector(FocusGuestTarget.updateEnabledState),
                           name: .openUIKitGuestProbe, object: object)
        center.addObserver(focus,
                           selector: #selector(FocusGuestTarget.keyboardWillShow(_:)),
                           name: .openUIKitGuestProbe, object: object)
        center.post(notification)

        check("runtime.zeroOnce", first.zeroCount == 1)
        check("runtime.valueOnce", first.valueNotifications.count == 1)
        check("runtime.objectOnce",
              first.objectNotifications.count == 1
                  && second.objectNotifications.count == 1)
        check("runtime.registrySkipped", first.registryNames.isEmpty)
        check("runtime.valueName",
              first.valueNotifications.first?.name == .openUIKitGuestProbe)
        check("runtime.valueObjectIdentity",
              first.valueNotifications.first?.object as AnyObject? === object)
        check("runtime.valueUserInfoIdentity",
              first.valueNotifications.first?.userInfo?["payload"] as AnyObject?
                  === payload)
        check("runtime.objectName",
              first.objectNotifications.first?.name == .openUIKitGuestProbe)
        check("runtime.objectObjectIdentity",
              first.objectNotifications.first?.object as AnyObject? === object)
        check("runtime.objectUserInfoIdentity",
              first.objectNotifications.first?.userInfo?["payload"] as AnyObject?
                  === payload)
        check("runtime.sharedCarrier",
              first.objectNotifications.first === second.objectNotifications.first)
        check("focus.zeroOnce", focus.zeroCount == 1)
        check("focus.objectOnce", focus.notifications.count == 1)
        check("focus.objectIdentity",
              focus.notifications.first?.object as AnyObject? === object)
        check("focus.userInfoIdentity",
              focus.notifications.first?.userInfo?["payload"] as AnyObject? === payload)
        let fallback = RegistryTarget()
        center.addObserver(
            fallback,
            selector: .named("portableNotification:"),
            name: .openUIKitGuestOther,
            object: nil
        )
        center.post(name: .openUIKitGuestOther, object: object,
                    userInfo: ["payload": payload])
        check("fallback.registryOnce", fallback.notifications.count == 1)
        check("fallback.receivedValue",
              fallback.notifications.first?.object as AnyObject? === object
                  && fallback.notifications.first?.userInfo?["payload"] as AnyObject?
                      === payload)
        check("runtime.noMisses", misses.isEmpty)
        SelectorDispatch.onUnresolved = priorMiss

        let filteredCenter = NotificationCenter()
        var filtered = 0
        let filteredToken = filteredCenter.addObserver(
            forName: .openUIKitGuestProbe, object: object, queue: nil
        ) { _ in filtered += 1 }
        filteredCenter.post(name: .openUIKitGuestProbe, object: otherObject)
        filteredCenter.post(name: .openUIKitGuestProbe, object: nil)
        filteredCenter.post(name: .openUIKitGuestProbe, object: object)
        check("filter.strictIdentity", filtered == 1)
        filteredCenter.removeObserver(filteredToken)

        let wildcardCenter = NotificationCenter()
        var wildcardNames: [Notification.Name] = []
        let wildcard = wildcardCenter.addObserver(
            forName: nil, object: nil, queue: nil
        ) { wildcardNames.append($0.name) }
        wildcardCenter.post(name: .openUIKitGuestProbe, object: nil)
        wildcardCenter.post(name: .openUIKitGuestOther, object: nil)
        check("wildcard.names",
              wildcardNames == [.openUIKitGuestProbe, .openUIKitGuestOther])
        wildcardCenter.removeObserver(wildcard)

        let exactCenter = NotificationCenter()
        let duplicate = RegistryTarget()
        exactCenter.addObserver(duplicate, selector: .named("portableNotification:"),
                                name: .openUIKitGuestProbe, object: object)
        exactCenter.addObserver(duplicate, selector: .named("portableNotification:"),
                                name: .openUIKitGuestProbe, object: object)
        exactCenter.post(name: .openUIKitGuestProbe, object: object)
        check("duplicate.eachDelivered", duplicate.notifications.count == 2)
        exactCenter.removeObserver(duplicate, name: .openUIKitGuestProbe,
                                   object: otherObject)
        exactCenter.post(name: .openUIKitGuestProbe, object: object)
        check("removal.nonmatchingKept", duplicate.notifications.count == 4)
        exactCenter.removeObserver(duplicate, name: .openUIKitGuestProbe,
                                   object: object)
        exactCenter.post(name: .openUIKitGuestProbe, object: object)
        check("removal.exactStopped", duplicate.notifications.count == 4)

        let weakCenter = NotificationCenter()
        weak var weakObserver: RegistryTarget?
        func registerDisposableObserver() {
            let observer = RegistryTarget()
            weakObserver = observer
            weakCenter.addObserver(
                observer, selector: .named("portableNotification:"),
                name: .openUIKitGuestProbe, object: nil
            )
            check("weak.observerBeforeRelease", weakObserver != nil)
        }
        registerDisposableObserver()
        check("weak.observerAfterRelease", weakObserver == nil)
        weakCenter.post(name: .openUIKitGuestProbe, object: nil)
        check("weak.observerReaped",
              weakObserver == nil && weakCenter._observerCount == 0)

        var weakFilterToken: NotificationToken?
        weak var weakFilter: UIView?
        var weakFilterDeliveries = 0
        func registerDisposableFilter() {
            let filter = UIView()
            weakFilter = filter
            weakFilterToken = weakCenter.addObserver(
                forName: .openUIKitGuestProbe, object: filter, queue: nil
            ) { _ in weakFilterDeliveries += 1 }
            check("weak.filterBeforeRelease", weakFilter != nil)
        }
        registerDisposableFilter()
        check("weak.filterAfterRelease", weakFilter == nil)
        weakCenter.post(name: .openUIKitGuestProbe, object: nil)
        check("weak.filterReaped",
              weakFilterDeliveries == 0 && weakCenter._observerCount == 0)
        withExtendedLifetime(weakFilterToken) {}

        let tokenCenter = NotificationCenter()
        var tokenDeliveries = 0
        let token = tokenCenter.addObserver(
            forName: .openUIKitGuestProbe, object: nil, queue: nil
        ) { _ in tokenDeliveries += 1 }
        let protocolToken: any NSObjectProtocol = token
        tokenCenter.post(name: .openUIKitGuestProbe, object: nil)
        tokenCenter.removeObserver(protocolToken)
        tokenCenter.post(name: .openUIKitGuestProbe, object: nil)
        check("block.tokenRemoval", tokenDeliveries == 1)
        check("block.tokenNSObjectProtocol", protocolToken === token)

        var inline = false
        let queueToken = tokenCenter.addObserver(
            forName: .openUIKitGuestOther,
            object: nil,
            queue: OperationQueue.main
        ) { _ in inline = true }
        tokenCenter.post(name: .openUIKitGuestOther, object: nil)
        check("queue.inline", inline)
        tokenCenter.removeObserver(queueToken)

        let reentrantCenter = NotificationCenter()
        var removalOrder: [Int] = []
        var removalSecond: NotificationToken?
        let removalFirst = reentrantCenter.addObserver(
            forName: .openUIKitGuestProbe, object: nil, queue: nil
        ) { _ in
            removalOrder.append(1)
            if let removalSecond { reentrantCenter.removeObserver(removalSecond) }
        }
        removalSecond = reentrantCenter.addObserver(
            forName: .openUIKitGuestProbe, object: nil, queue: nil
        ) { _ in removalOrder.append(2) }
        reentrantCenter.post(name: .openUIKitGuestProbe, object: nil)
        check("reentrant.snapshotRemoval", removalOrder == [1, 2])
        reentrantCenter.removeObserver(removalFirst)

        let additionCenter = NotificationCenter()
        var additionOrder: [String] = []
        var added: NotificationToken?
        let adding = additionCenter.addObserver(
            forName: .openUIKitGuestProbe, object: nil, queue: nil
        ) { _ in
            additionOrder.append("first")
            if added == nil {
                added = additionCenter.addObserver(
                    forName: .openUIKitGuestProbe, object: nil, queue: nil
                ) { _ in additionOrder.append("second") }
            }
        }
        additionCenter.post(name: .openUIKitGuestProbe, object: nil)
        additionCenter.post(name: .openUIKitGuestProbe, object: nil)
        check("reentrant.additionDeferred",
              additionOrder == ["first", "first", "second"])
        additionCenter.removeObserver(adding)
        if let added { additionCenter.removeObserver(added) }

        center.removeObserver(first)
        center.removeObserver(second)
        center.removeObserver(focus)
        center.removeObserver(fallback)
        print("guest.status=\(failures.isEmpty ? "PASS" : "FAIL")")
        if !failures.isEmpty {
            print("guest.failures=\(failures.joined(separator: ","))")
        }
        print("GUEST_END")
        precondition(failures.isEmpty)
    }
}
