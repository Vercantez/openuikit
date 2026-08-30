// Mirrors Reminder's model-side file: it imports Foundation only and extends
// Notification.Name without knowing that the UI layer is OpenUIKit-backed.

import Foundation

extension Notification.Name {
    static let openUIKitFoundationOnlyProbe =
        Notification.Name("OpenUIKitFoundationOnlyProbe")
}
