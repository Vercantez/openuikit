// Pinned Focus source imports Foundation and UIKit in the same file. These
// unqualified declarations must therefore resolve to one shared identity.

import Foundation
import UIKit

@MainActor
final class FocusGuestTarget: UIViewController {
    let center: NotificationCenter
    var zeroCount = 0
    var notifications: [NSNotification] = []

    init(center: NotificationCenter) {
        self.center = center
        super.init(nibName: nil, bundle: nil)
    }

    @objc func updateEnabledState() {
        zeroCount += 1
    }

    @objc func keyboardWillShow(_ notification: NSNotification) {
        notifications.append(notification)
    }
}
