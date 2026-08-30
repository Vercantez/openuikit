// This file deliberately imports only UIKit. It is the source-level shape of
// Reminder's view controller: the notification-name extension is declared by
// a different file that imports only Foundation, while every type below is
// spelled unqualified through UIKit.

import UIKit

/// Compile-only identity surface shared by every capability branch. Keeping
/// this outside the Objective-C guard makes the ordinary Linux test build
/// prove that a UIKit-only file resolves all four names unqualified too.
@MainActor
func makeNotificationUIKitOnlySurfaceProbe() -> NotificationCenter {
    _ = Notification.self
    _ = NSNotification.self
    _ = NotificationCenter.self
    _ = OperationQueue.self
    _ = Notification.Name.openUIKitFoundationOnlyProbe
    let center = NotificationCenter()
#if !canImport(ObjectiveC)
    // Foundation.NotificationCenter does not expose this project-only
    // counter, so native ELF proves UIKit selected the custom center rather
    // than merely resolving some re-exported declaration with the same name.
    _ = center._observerCount
#endif
    return center
}

#if canImport(ObjectiveC)

@MainActor
final class NotificationUIKitOnlyConsumerProbe: UIViewController {
    let center: NotificationCenter
    var runtimeNotifications: [Notification] = []
    var objectNotifications: [NSNotification] = []
    var zeroArgumentCount = 0

    init(center: NotificationCenter) {
        self.center = center
        super.init(nibName: nil, bundle: nil)
    }

    @objc func receiveNotification(_ notification: Notification) {
        runtimeNotifications.append(notification)
    }

    // Pinned Focus's keyboard helpers spell the bridged class explicitly.
    @objc func receiveObjectNotification(_ notification: NSNotification) {
        objectNotifications.append(notification)
    }

    // Pinned Focus uses four zero-argument notification selectors.
    @objc func focusStyleZeroArgument() {
        zeroArgumentCount += 1
    }

    func startObserving(object: AnyObject) {
        center.addObserver(
            self,
            selector: #selector(receiveNotification(_:)),
            name: .openUIKitFoundationOnlyProbe,
            object: object
        )
        center.addObserver(
            self,
            selector: #selector(receiveObjectNotification(_:)),
            name: .openUIKitFoundationOnlyProbe,
            object: object
        )
        center.addObserver(
            self,
            selector: #selector(focusStyleZeroArgument),
            name: .openUIKitFoundationOnlyProbe,
            object: object
        )
    }

    func stopObserving(object: AnyObject) {
        center.removeObserver(
            self,
            name: .openUIKitFoundationOnlyProbe,
            object: object
        )
    }
}

#endif
