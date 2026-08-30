// Focus-shaped source file: real application code commonly imports both.
// Every unqualified spelling below must remain unambiguous, while the explicit
// assignments prove that Foundation and UIKit publish one underlying type.
import Foundation
import UIKit

func proveDirectFoundationUIKitNotificationIdentities() {
    let notification: Foundation.Notification.Type = Notification.self
    let _: UIKit.Notification.Type = notification

    let name: Foundation.Notification.Name.Type = Notification.Name.self
    let _: UIKit.Notification.Name.Type = name

    let center: Foundation.NotificationCenter.Type = NotificationCenter.self
    let _: UIKit.NotificationCenter.Type = center

    let queue: Foundation.OperationQueue.Type = OperationQueue.self
    let _: UIKit.OperationQueue.Type = queue

#if canImport(ObjectiveC)
    let carrier: Foundation.NSNotification.Type = NSNotification.self
    let _: UIKit.NSNotification.Type = carrier
#endif
}
