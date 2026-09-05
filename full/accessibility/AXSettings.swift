import Foundation

public struct AccessibilityTechnology: RawRepresentable, Hashable, Equatable, Sendable {
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let voiceOver = AccessibilityTechnology(rawValue: "AXTechnologyVoiceOver")
    public static let switchControl = AccessibilityTechnology(rawValue: "AXTechnologySwitchControl")
    public static let voiceControl = AccessibilityTechnology(rawValue: "AXTechnologyVoiceControl")
    public static let fullKeyboardAccess = AccessibilityTechnology(rawValue: "AXTechnologyFullKeyboardAccess")
    public static let speakScreen = AccessibilityTechnology(rawValue: "AXTechnologySpeakScreen")
    public static let automation = AccessibilityTechnology(rawValue: "AXTechnologyAutomation")
    public static let hoverText = AccessibilityTechnology(rawValue: "AXTechnologyHoverText")
    public static let zoom = AccessibilityTechnology(rawValue: "AXTechnologyZoom")
}

public class AccessibilityRequest: NSObject, NSCopying, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    /// No assistive technology is attached on this Linux host.
    public static var current: AccessibilityRequest? { nil }

    public let technology: AccessibilityTechnology

    public init(technology: AccessibilityTechnology) {
        self.technology = technology
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard let raw = coder.decodeObject(of: NSString.self, forKey: "technology") as String? else {
            return nil
        }
        self.technology = AccessibilityTechnology(rawValue: raw)
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(technology.rawValue as NSString, forKey: "technology")
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        AccessibilityRequest(technology: technology)
    }
}

public struct AccessibilitySettings: Equatable, Sendable {
    public enum Feature: Int, Equatable, Hashable, Sendable {
        /// Sequential NS_ENUM values from the pinned macios bindings starting at 1.
        case personalVoiceAllowAppsToRequestToUse = 1
        case allowAppsToAddAudioToCalls = 2
        case assistiveTouch = 3
        case assistiveTouchDevices = 4
        case dwellControl = 5
    }

    public init() {}

    /// Assistive Access is an iOS Guided-Access-style shell. Always false here.
    public static var isAssistiveAccessEnabled: Bool { false }

    /// System "Show Borders" preference. No AccessibilitySettings daemon.
    public static var showBordersEnabled: Bool { false }

    /// Animated-image preference. Unobserved on Linux; reported as disabled.
    public static var animatedImagesEnabled: Bool { false }

    public static var prefersHorizontalTextLayout: Bool { false }
    public static var prefersActionSliderAlternative: Bool { false }
    public static var prefersNonBlinkingTextInsertionIndicator: Bool { false }

    public static var animatedImagesEnabledDidChangeNotification: Notification.Name {
        .AXAnimatedImagesEnabledDidChange
    }

    public static var prefersHorizontalTextLayoutDidChangeNotification: Notification.Name {
        .AXPrefersHorizontalTextLayoutDidChange
    }

    public static let prefersActionSliderAlternativeDidChangeNotification = Notification.Name(
        "AXPrefersActionSliderAlternativeDidChangeNotification"
    )
    public static let prefersNonBlinkingTextInsertionIndicatorDidChangeNotification = Notification.Name(
        "AXPrefersNonBlinkingTextInsertionIndicatorDidChangeNotification"
    )
    public static let showBordersEnabledStatusDidChangeNotification = Notification.Name(
        "AXShowBordersEnabledStatusDidChangeNotification"
    )

    /// Settings.app is not present. Always fail-closed.
    public static func openSettings(for feature: Feature) async throws {
        _ = feature
        throw axFailClosedError(
            domain: "AccessibilitySettingsOpenErrorDomain",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Opening Settings is unavailable on this platform."]
        )
    }
}

extension NSNotification.Name {
    public static var AXAnimatedImagesEnabledDidChange: Notification.Name {
        Notification.Name("AXAnimatedImagesEnabledDidChangeNotification")
    }

    public static var AXPrefersHorizontalTextLayoutDidChange: Notification.Name {
        Notification.Name("AXPrefersHorizontalTextLayoutDidChangeNotification")
    }
}

public struct AXMFiHearingDevice: Equatable, Sendable {
    public struct Ear: OptionSet, Hashable, Sendable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public init() {
            self.rawValue = 0
        }

        /// Bit layout from the pinned macios `AXHearingDeviceEar` flags:
        /// `Left = 1 << 1`, `Right = 1 << 2`, `Both = Left | Right`.
        public static let left = Ear(rawValue: 1 << 1)
        public static let right = Ear(rawValue: 1 << 2)
        public static let both: Ear = [.left, .right]
    }

    public static let pairedUUIDsDidChangeNotification = Notification.Name(
        "AXMFiHearingDevicePairedUUIDsDidChangeNotification"
    )
    public static let streamingEarDidChangeNotification = Notification.Name(
        "AXMFiHearingDeviceStreamingEarDidChangeNotification"
    )

    public static func pairedDeviceIdentifiers() -> [UUID] { [] }

    public static func streamingEar() -> Ear { Ear() }

    public static func supportsBidirectionalStreaming() -> Bool { false }
}

public class AXFeatureOverrideSession: NSObject {
    public struct Options: OptionSet, Hashable, Sendable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public init() {
            self.rawValue = 0
        }

        public static let grayscale = Options(rawValue: 1 << 0)
        public static let invertColors = Options(rawValue: 1 << 1)
        public static let voiceControl = Options(rawValue: 1 << 2)
        public static let voiceOver = Options(rawValue: 1 << 3)
        public static let zoom = Options(rawValue: 1 << 4)
    }

    let enabling: Options
    let disabling: Options
    let uuid: UUID

    public override init() {
        self.enabling = []
        self.disabling = []
        self.uuid = UUID()
        super.init()
    }

    init(enabling: Options, disabling: Options) {
        self.enabling = enabling
        self.disabling = disabling
        self.uuid = UUID()
        super.init()
    }
}

public class AXFeatureOverrideSessionManager: NSObject {
    public static let sharedInstance = AXFeatureOverrideSessionManager()

    private override init() {
        super.init()
    }

    /// Feature overrides require the Accessibility entitlement and a running
    /// assistive-technology daemon. Always fail-closed with `appNotEntitled`.
    public func beginOverrideSession(
        enabling enableOptions: AXFeatureOverrideSession.Options = [],
        disabling disableOptions: AXFeatureOverrideSession.Options = []
    ) throws -> AXFeatureOverrideSession {
        _ = (enableOptions, disableOptions)
        throw AXFeatureOverrideSessionError(.appNotEntitled)
    }

    public func end(_ session: AXFeatureOverrideSession) throws {
        _ = session
        throw AXFeatureOverrideSessionError(.overrideNotFoundForUUID)
    }
}

public class AXLiveAudioGraph: NSObject {
    private static let lock = NSLock()
    private static var running = false
    private static var lastValue: Double = 0

    private override init() {
        super.init()
    }

    /// No sonification backend is present. The local started/value flags are
    /// tracked so tests can observe the state machine without inventing audio.
    public class func start() {
        lock.lock()
        running = true
        lock.unlock()
    }

    public class func stop() {
        lock.lock()
        running = false
        lastValue = 0
        lock.unlock()
    }

    public class func updateValue(_ value: Double) {
        lock.lock()
        if running {
            lastValue = value
        }
        lock.unlock()
    }

    internal class func ax_isRunning() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return running
    }

    internal class func ax_lastValue() -> Double {
        lock.lock()
        defer { lock.unlock() }
        return lastValue
    }
}
