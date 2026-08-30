// Native iOS 26.1 oracle for Notification/NotificationCenter selector and
// bridge behavior. OpenUIKit is deliberately not linked into this process.

import Darwin
import Foundation
import UIKit

private let bundleIdentifier = "com.openuikit.notificationbridgeprobe"

@MainActor
private final class Transcript {
    private var lines: [String] = []
    private var failures: [String] = []

    func check(_ key: String, _ condition: @autoclosure () -> Bool) {
        let passed = condition()
        lines.append("\(key)=\(passed ? "true" : "false")")
        if !passed { failures.append(key) }
    }

    func finish() -> Int32 {
        var output = ["ORACLE_BEGIN"]
        output.append(contentsOf: lines)
        output.append("oracle.status=\(failures.isEmpty ? "PASS" : "FAIL")")
        if !failures.isEmpty {
            output.append("oracle.failures=\(failures.joined(separator: ","))")
        }
        output.append("ORACLE_END")
        let text = output.joined(separator: "\n") + "\n"
        let documents = FileManager.default.urls(
            for: .documentDirectory, in: .userDomainMask
        )[0]
        try! text.write(
            to: documents.appendingPathComponent("notificationbridgeprobe.txt"),
            atomically: true,
            encoding: .utf8
        )
        FileHandle.standardOutput.write(Data(text.utf8))
        fflush(stdout)
        return failures.isEmpty ? 0 : 1
    }
}

@MainActor
private final class SelectorTarget: NSObject {
    let expectedObject: AnyObject
    let expectedPayload: AnyObject
    var zeroCount = 0
    var values: [Notification] = []
    var objects: [NSNotification] = []

    init(expectedObject: AnyObject, expectedPayload: AnyObject) {
        self.expectedObject = expectedObject
        self.expectedPayload = expectedPayload
    }

    @objc func zeroArgument() {
        zeroCount += 1
    }

    @objc func receiveValue(_ notification: Notification) {
        values.append(notification)
    }

    @objc func receiveObject(_ notification: NSNotification) {
        objects.append(notification)
    }
}

@MainActor
private final class CountingTarget: NSObject {
    var count = 0
    @objc func receive(_ notification: Notification) {
        _ = notification
        count += 1
    }
}

/// Foundation marks block observers `@Sendable`, while the native token
/// protocol predates Sendable. The oracle owns this box on the main thread;
/// unchecked conformance keeps the measured reentrant mutation explicit and
/// avoids attributing a compiler warning to the framework behavior.
private final class ObserverTokenBox: @unchecked Sendable {
    var value: NSObjectProtocol?
}

@MainActor
private func recordFacts(_ transcript: Transcript) {
    let name = Notification.Name("OpenUIKitNotificationOracle")
    let otherName = Notification.Name("OpenUIKitNotificationOracleOther")
    let object = NSObject()
    let otherObject = NSObject()
    let payload = NSObject()
    let center = NotificationCenter()
    let target = SelectorTarget(expectedObject: object, expectedPayload: payload)
    let secondTarget = SelectorTarget(expectedObject: object, expectedPayload: payload)

    let zeroSelector = #selector(SelectorTarget.zeroArgument)
    let valueSelector = #selector(SelectorTarget.receiveValue(_:))
    let objectSelector = #selector(SelectorTarget.receiveObject(_:))
    transcript.check("selector.respondsZero", target.responds(to: zeroSelector))
    transcript.check("selector.respondsValue", target.responds(to: valueSelector))
    transcript.check("selector.respondsObject", target.responds(to: objectSelector))

    center.addObserver(target, selector: zeroSelector, name: name, object: object)
    center.addObserver(target, selector: valueSelector, name: name, object: object)
    center.addObserver(target, selector: objectSelector, name: name, object: object)
    center.addObserver(secondTarget, selector: objectSelector,
                       name: name, object: object)
    center.post(name: name, object: object, userInfo: ["payload": payload])

    transcript.check("selector.zeroOnce", target.zeroCount == 1)
    transcript.check("selector.valueOnce", target.values.count == 1)
    transcript.check("selector.objectOnce", target.objects.count == 1)
    transcript.check("selector.secondObjectOnce", secondTarget.objects.count == 1)
    transcript.check("selector.valueName", target.values.first?.name == name)
    transcript.check("selector.valueObjectIdentity",
                     target.values.first?.object as AnyObject? === object)
    transcript.check("selector.valueUserInfoIdentity",
                     target.values.first?.userInfo?["payload"] as AnyObject? === payload)
    transcript.check("selector.objectName", target.objects.first?.name == name)
    transcript.check("selector.objectObjectIdentity",
                     target.objects.first?.object as AnyObject? === object)
    transcript.check("selector.objectUserInfoIdentity",
                     target.objects.first?.userInfo?["payload"] as AnyObject? === payload)
    transcript.check("bridge.sharedCarrier",
                     target.objects.first === secondTarget.objects.first)
    center.removeObserver(secondTarget, name: name, object: object)

    center.post(name: name, object: otherObject)
    transcript.check("filter.wrongObjectSkipped",
                     target.zeroCount == 1 && target.values.count == 1
                         && target.objects.count == 1)
    center.post(name: name, object: nil)
    transcript.check("filter.nilObjectSkipped",
                     target.zeroCount == 1 && target.values.count == 1
                         && target.objects.count == 1)

    center.removeObserver(target, name: name, object: otherObject)
    center.post(name: name, object: object)
    transcript.check("removal.wrongObjectKept",
                     target.zeroCount == 2 && target.values.count == 2
                         && target.objects.count == 2)
    center.removeObserver(target, name: name, object: object)
    center.post(name: name, object: object)
    transcript.check("removal.exactStopped",
                     target.zeroCount == 2 && target.values.count == 2
                         && target.objects.count == 2)

    var wildcardNames: [Notification.Name] = []
    let wildcard = center.addObserver(
        forName: nil, object: nil, queue: nil
    ) { wildcardNames.append($0.name) }
    center.post(name: name, object: nil)
    center.post(name: otherName, object: nil)
    transcript.check("wildcard.names", wildcardNames == [name, otherName])
    center.removeObserver(wildcard)

    let duplicate = CountingTarget()
    center.addObserver(duplicate, selector: #selector(CountingTarget.receive(_:)),
                       name: name, object: object)
    center.addObserver(duplicate, selector: #selector(CountingTarget.receive(_:)),
                       name: name, object: object)
    center.post(name: name, object: object)
    transcript.check("duplicate.eachDelivered", duplicate.count == 2)
    center.removeObserver(duplicate, name: name, object: object)
    center.post(name: name, object: object)
    transcript.check("duplicate.exactRemoval", duplicate.count == 2)

    var order: [Int] = []
    let second = ObserverTokenBox()
    let first = center.addObserver(forName: name, object: nil, queue: nil) { _ in
        order.append(1)
        if let token = second.value { center.removeObserver(token) }
    }
    second.value = center.addObserver(forName: name, object: nil, queue: nil) { _ in
        order.append(2)
    }
    center.post(name: name, object: nil)
    transcript.check("reentrant.removalSuppressesInflight", order == [1])
    center.removeObserver(first)
    if let token = second.value { center.removeObserver(token) }

    let weakCenter = NotificationCenter()
    weak var weakObserver: CountingTarget?
    autoreleasepool {
        let observer = CountingTarget()
        weakObserver = observer
        weakCenter.addObserver(
            observer, selector: #selector(CountingTarget.receive(_:)),
            name: name, object: nil
        )
        transcript.check("weak.observerBeforeRelease", weakObserver != nil)
    }
    transcript.check("weak.observerAfterRelease", weakObserver == nil)
    weakCenter.post(name: name, object: nil)
    transcript.check("weak.observerPostSafe", weakObserver == nil)

    var filteredDeliveries = 0
    weak var weakFilter: NSObject?
    var filterToken: NSObjectProtocol?
    autoreleasepool {
        let filter = NSObject()
        weakFilter = filter
        filterToken = weakCenter.addObserver(
            forName: name, object: filter, queue: nil
        ) { _ in filteredDeliveries += 1 }
        transcript.check("weak.filterBeforeRelease", weakFilter != nil)
    }
    transcript.check("weak.filterAfterRelease", weakFilter == nil)
    weakCenter.post(name: name, object: nil)
    transcript.check("weak.filterPostSkipped", filteredDeliveries == 0)
    if let filterToken { weakCenter.removeObserver(filterToken) }

    let value = Notification(
        name: name, object: object, userInfo: ["payload": payload]
    )
    let bridged = value as NSNotification
    transcript.check("bridge.isNSNotification", (value as AnyObject) is NSNotification)
    transcript.check("bridge.name", bridged.name == name)
    transcript.check("bridge.objectIdentity", bridged.object as AnyObject? === object)
    transcript.check("bridge.userInfoIdentity",
                     bridged.userInfo?["payload"] as AnyObject? === payload)
    let empty = Notification._unconditionallyBridgeFromObjectiveC(nil)
    transcript.check("bridge.nilIsEmpty",
                     empty.name.rawValue.isEmpty && empty.object == nil
                         && empty.userInfo == nil)
}

@main
@MainActor
private final class ProbeAppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        _ = application
        _ = launchOptions
        precondition(Bundle.main.bundleIdentifier == bundleIdentifier)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
        self.window = window
        DispatchQueue.main.async {
            let transcript = Transcript()
            let version = ProcessInfo.processInfo.operatingSystemVersion
            transcript.check("runtime.ios26_1",
                             version.majorVersion == 26 && version.minorVersion == 1)
            transcript.check("runtime.main", Thread.isMainThread)
            recordFacts(transcript)
            let status = transcript.finish()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                Darwin.exit(status)
            }
        }
        return true
    }
}
