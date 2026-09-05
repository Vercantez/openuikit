// Literal downstream-module gate. The Foundation-only extension lives in a
// separate file, while this file reaches Notification and NotificationCenter
// through public `UIKit`, matching unchanged Reminder source.

import Foundation
import XCTest
import UIKit

#if !os(Linux)
@MainActor
#endif
final class NotificationSourceCompatibilityTests: XCTestCase {
    func testLiteralUIKitPublishesTheIntendedIdentities() {
        XCTAssertTrue(Notification.self == Foundation.Notification.self)
        XCTAssertTrue(NSNotification.self == Foundation.NSNotification.self)
        XCTAssertTrue(OperationQueue.self == Foundation.OperationQueue.self)

#if canImport(Foundation) && canImport(ObjectiveC)
        XCTAssertTrue(NotificationCenter.self == Foundation.NotificationCenter.self)
        XCTAssertTrue(NotificationCenter.default === Foundation.NotificationCenter.default)
        // This test file sees Foundation through XCTest. The declarations are
        // nevertheless identical, rather than two equal-precedence centers.
        // The UIKit-only companion source separately proves Reminder's exact
        // import topology and unqualified spelling.
        _ = NotificationCenter()
#else
        // Corelibs Foundation has no selector-observer API. Native ELF keeps
        // the strict OpenUIKit center and callers that also import Foundation
        // qualify it; the UIKit-only external gate remains unqualified.
        let center = UIKit.NotificationCenter()
        XCTAssertEqual(center._observerCount, 0)
#endif

        // Declared in the Foundation-only companion file.
        XCTAssertEqual(
            Notification.Name.openUIKitFoundationOnlyProbe.rawValue,
            "OpenUIKitFoundationOnlyProbe"
        )
    }

#if canImport(Foundation) && canImport(ObjectiveC)
    func testUIKitOnlyConsumerUsesNativeCenterAndBridgesExactlyOnce() {
        let center = NotificationCenter()
        let target = NotificationUIKitOnlyConsumerProbe(center: center)
        let object = UIView()
        let payload = UIView()
        let selector = #selector(NotificationUIKitOnlyConsumerProbe.receiveNotification(_:))
        XCTAssertTrue(target.responds(to: selector))

        target.startObserving(object: object)
        center.post(
            name: .openUIKitFoundationOnlyProbe,
            object: object,
            userInfo: ["payload": payload]
        )

        XCTAssertEqual(target.runtimeNotifications.count, 1)
        XCTAssertEqual(target.objectNotifications.count, 1)
        XCTAssertEqual(target.zeroArgumentCount, 1)
        XCTAssertEqual(target.runtimeNotifications[0].name,
                       .openUIKitFoundationOnlyProbe)
        XCTAssertTrue(target.runtimeNotifications[0].object as AnyObject === object)
        XCTAssertTrue(target.runtimeNotifications[0].userInfo?["payload"]
                        as AnyObject === payload)
        XCTAssertEqual(target.objectNotifications[0].name,
                       .openUIKitFoundationOnlyProbe)
        XCTAssertTrue(target.objectNotifications[0].object as AnyObject === object)
        XCTAssertTrue(target.objectNotifications[0].userInfo?["payload"]
                        as AnyObject === payload)

        let bridged = target.runtimeNotifications[0] as AnyObject
        XCTAssertTrue(bridged is NSNotification,
                      "Foundation.Notification bridges through NSNotification")
        target.stopObserving(object: object)
    }
#endif
}
