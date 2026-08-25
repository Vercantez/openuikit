// UIDevice — the device an app believes it is running on. Owner: lifecycle
// module (M12, docs/APP_COMPAT.md "App lifecycle / environment").
//
// HONESTY NOTE. Everything here is a PLAUSIBLE FIXED VALUE, not a
// measurement, and it cannot be otherwise: OpenUIKit is a portable library
// with no device to interrogate, and it may be running on Linux. The values
// were chosen to be the ones app code branches on productively:
//
//   userInterfaceIdiom  .phone      — the idiom the oracle renders in and
//                                     the one every fixture assumes
//   systemName          "iOS"
//   systemVersion       "26.1"      — the real-UIKit version the goldens
//                                     were captured from (Mac Catalyst
//                                     iOS 26.1; see UISwitch.swift)
//   model               "iPhone"
//   name                "OpenUIKit" — deliberately NOT a fake user device
//                                     name; a host may set its own.
//
// A host that knows better may overwrite any of them (they are var), which
// is why they are stored rather than computed. Battery and proximity
// monitoring do not exist: the properties report "unknown"/false, like a
// device with monitoring disabled, and enabling monitoring is a no-op.

public enum UIUserInterfaceIdiom: Int, Sendable {
    case unspecified = -1
    case phone = 0
    case pad = 1
    case tv = 2
    case carPlay = 3
    case mac = 5
    case vision = 6
}

public enum UIDeviceOrientation: Int, Sendable {
    case unknown = 0
    case portrait = 1
    case portraitUpsideDown = 2
    case landscapeLeft = 3
    case landscapeRight = 4
    case faceUp = 5
    case faceDown = 6

    public var isPortrait: Bool { self == .portrait || self == .portraitUpsideDown }
    public var isLandscape: Bool { self == .landscapeLeft || self == .landscapeRight }
    public var isFlat: Bool { self == .faceUp || self == .faceDown }
}

public enum UIDeviceBatteryState: Int, Sendable {
    case unknown = 0, unplugged = 1, charging = 2, full = 3
}

public final class UIDevice {
    public static let current = UIDevice()

    private init() {}

    /// See the file header: fixed, documented values — not probed.
    public var name: String = "OpenUIKit"
    public var systemName: String = "iOS"
    public var systemVersion: String = "26.1"
    public var model: String = "iPhone"
    public var localizedModel: String = "iPhone"
    public var userInterfaceIdiom: UIUserInterfaceIdiom = .phone

    /// OpenUIKit renders one fixed, upright surface: there is no rotation
    /// pipeline, so the orientation never changes and no notification for it
    /// is ever posted.
    public var orientation: UIDeviceOrientation = .portrait
    public var isGeneratingDeviceOrientationNotifications: Bool = false
    public func beginGeneratingDeviceOrientationNotifications() {}
    public func endGeneratingDeviceOrientationNotifications() {}

    /// No battery to read. `isBatteryMonitoringEnabled` is honored as a
    /// stored flag so app code that toggles it round-trips, but the state
    /// stays `.unknown` and the level stays -1, exactly what UIKit reports
    /// when monitoring is off.
    public var isBatteryMonitoringEnabled: Bool = false
    public var batteryState: UIDeviceBatteryState { .unknown }
    public var batteryLevel: Float { -1 }

    public var isProximityMonitoringEnabled: Bool = false
    public var proximityState: Bool { false }

    public var isMultitaskingSupported: Bool { false }
}
