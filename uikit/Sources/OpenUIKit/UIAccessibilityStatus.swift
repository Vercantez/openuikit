// UIAccessibility — the namespace of system accessibility settings.
// Owner: accessibility.
//
// UIKit exposes these as static members of `UIAccessibility`. OpenUIKit has
// no Settings app and no assistive technology, so each one reports the value
// a default iPhone reports. Only members measured on the oracle are declared.

/// UIKit's `UIAccessibility` namespace.
public enum UIAccessibility {
    /// iOS 26.1, default iPhone 16 simulator (iososswallsprobe
    /// `misc.isBoldTextEnabled`): false.
    public static var isBoldTextEnabled: Bool { false }

    /// MEASURED iOS 26.1 (Tools/oracle2/cellconfigprobe/transcript-ios26.1.txt): false on the default simulator.
    public static var isVoiceOverRunning: Bool { false }

    /// UIKit's accessibility notifications. MEASURED raw value:
    /// announcement 1008.
    public struct Notification: RawRepresentable, Hashable, Sendable {
        public let rawValue: UInt32
        public init(rawValue: UInt32) { self.rawValue = rawValue }
        public static let announcement = Notification(rawValue: 1008)
    }

    /// Delivered to assistive technologies. The port has none (VoiceOver
    /// is not running), so nothing receives it.
    public static func post(notification: Notification, argument: Any?) {
        _ = (notification, argument)
    }
}
