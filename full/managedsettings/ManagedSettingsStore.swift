import Foundation

// MARK: - Process-local named backing stores

/// Shared mutable settings for one `ManagedSettingsStore.Name`.
///
/// Apple persists through the Managed Settings daemon. Linux keeps a
/// process-local map so same-named stores share values for the lifetime of
/// the process only. Values never become operating-system restrictions.
private final class ManagedSettingsStoreBox: @unchecked Sendable {
    let lock = NSLock()
    var account = AccountSettings()
    var application = ApplicationSettings()
    var appStore = AppStoreSettings()
    var cellular = CellularSettings()
    var dateAndTime = DateAndTimeSettings()
    var gameCenter = GameCenterSettings()
    var media = MediaSettings()
    var passcode = PasscodeSettings()
    var safari = SafariSettings()
    var shield = ShieldSettings()
    var siri = SiriSettings()
    var webContent = WebContentSettings()

    func clear() {
        account = AccountSettings()
        application = ApplicationSettings()
        appStore = AppStoreSettings()
        cellular = CellularSettings()
        dateAndTime = DateAndTimeSettings()
        gameCenter = GameCenterSettings()
        media = MediaSettings()
        passcode = PasscodeSettings()
        safari = SafariSettings()
        shield = ShieldSettings()
        siri = SiriSettings()
        webContent = WebContentSettings()
    }
}

private enum ManagedSettingsStoreRegistry {
    private static let lock = NSLock()
    private static var boxes: [String: ManagedSettingsStoreBox] = [:]

    static func box(named name: String) -> ManagedSettingsStoreBox {
        lock.lock()
        defer { lock.unlock() }
        if let existing = boxes[name] {
            return existing
        }
        let created = ManagedSettingsStoreBox()
        boxes[name] = created
        return created
    }
}

// MARK: - Store

/// A data store that applies settings to the current user or device.
///
/// On Linux the store is an in-process named bag. `clearAllSettings()` resets
/// this name's values. Combine `ObservableObject` / `@Published` members are
/// unavailable because Combine is not a declared dependency.
public class ManagedSettingsStore {
    /// The unique name of a store.
    ///
    /// Initializing multiple stores with the same name shares settings.
    public struct Name: RawRepresentable, Equatable, Hashable {
        public typealias RawValue = String

        /// The name of the store as a `String`.
        public let rawValue: String

        /// Creates a new instance with the specified string.
        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        /// Creates a new instance with the specified string.
        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }

        /// The default store name.
        ///
        /// Apple's exact `rawValue` is unobserved; this port uses `"default"`.
        public static let `default` = Name(rawValue: "default")
    }

    private let box: ManagedSettingsStoreBox

    /// Creates a store for ``Name/default``.
    public init() {
        self.box = ManagedSettingsStoreRegistry.box(named: Name.default.rawValue)
    }

    /// Creates a store with a custom name. Same names share settings.
    public convenience init(named name: Name) {
        self.init(box: ManagedSettingsStoreRegistry.box(named: name.rawValue))
    }

    private init(box: ManagedSettingsStoreBox) {
        self.box = box
    }

    /// Settings that affect accounts.
    public var account: AccountSettings {
        get { withBox { $0.account } }
        set { withBox { $0.account = newValue } }
    }

    /// Settings that affect applications.
    public var application: ApplicationSettings {
        get { withBox { $0.application } }
        set { withBox { $0.application = newValue } }
    }

    /// Settings that affect the App Store.
    public var appStore: AppStoreSettings {
        get { withBox { $0.appStore } }
        set { withBox { $0.appStore = newValue } }
    }

    /// Settings that affect cellular networking.
    public var cellular: CellularSettings {
        get { withBox { $0.cellular } }
        set { withBox { $0.cellular = newValue } }
    }

    /// Settings that affect the date and time.
    public var dateAndTime: DateAndTimeSettings {
        get { withBox { $0.dateAndTime } }
        set { withBox { $0.dateAndTime = newValue } }
    }

    /// Settings that affect Game Center.
    public var gameCenter: GameCenterSettings {
        get { withBox { $0.gameCenter } }
        set { withBox { $0.gameCenter = newValue } }
    }

    /// Settings that affect media.
    public var media: MediaSettings {
        get { withBox { $0.media } }
        set { withBox { $0.media = newValue } }
    }

    /// Settings that affect the device passcode.
    public var passcode: PasscodeSettings {
        get { withBox { $0.passcode } }
        set { withBox { $0.passcode = newValue } }
    }

    /// Settings that affect Safari's search results and cookie policies.
    public var safari: SafariSettings {
        get { withBox { $0.safari } }
        set { withBox { $0.safari = newValue } }
    }

    /// Settings that affect what activities the system covers with a shielding view.
    public var shield: ShieldSettings {
        get { withBox { $0.shield } }
        set { withBox { $0.shield = newValue } }
    }

    /// Settings that affect Siri.
    public var siri: SiriSettings {
        get { withBox { $0.siri } }
        set { withBox { $0.siri = newValue } }
    }

    /// Settings that affect web content.
    public var webContent: WebContentSettings {
        get { withBox { $0.webContent } }
        set { withBox { $0.webContent = newValue } }
    }

    /// Clears all settings for this store.
    public func clearAllSettings() {
        box.lock.lock()
        defer { box.lock.unlock() }
        box.clear()
    }

    /// The deny-explicit-content constraint active on this device.
    ///
    /// Family Controls is absent, so no rating policy is active. Returns the
    /// documented metadata default (`false`).
    public var effectiveDenyExplicitContent: Bool {
        MediaSettings.denyExplicitContent.defaultValue
    }

    /// The movie-rating constraint active on this device.
    ///
    /// If no `maximumMovieRating` settings are active, this is the metadata
    /// default (`1000`). Linux never activates a rating policy.
    public var effectiveMaximumMovieRating: Int {
        MediaSettings.maximumMovieRating.defaultValue
    }

    /// The TV-rating constraint active on this device.
    ///
    /// If no `maximumTVShowRating` settings are active, this is the metadata
    /// default (`1000`). Linux never activates a rating policy.
    public var effectiveMaximumTVShowRating: Int {
        MediaSettings.maximumTVShowRating.defaultValue
    }

    private func withBox<T>(_ body: (ManagedSettingsStoreBox) -> T) -> T {
        box.lock.lock()
        defer { box.lock.unlock() }
        return body(box)
    }

    private func withBox(_ body: (ManagedSettingsStoreBox) -> Void) {
        box.lock.lock()
        defer { box.lock.unlock() }
        body(box)
    }
}
