import Foundation

/// Reports browser page usage to Screen Time.
///
/// Apple's type subclasses `UIViewController` and is `@MainActor`. Isolated
/// Linux compilation has Foundation only, so this is an `@MainActor` `NSObject`
/// with the published usage properties. Setting `url` does not consult a
/// blocking service: `urlIsBlocked` is always `false`.
@preconcurrency @MainActor
open class STWebpageController: NSObject {
    /// When `true`, the controller must not record usage. Local flag only.
    open var suppressUsageRecording: Bool = false

    /// The URL currently displayed. Local flag only; not reported to a daemon.
    open var url: URL?

    /// Whether the current URL is playing video. The app sets this to describe
    /// media state; Linux stores it and does not forward it.
    open var urlIsPlayingVideo: Bool = false

    /// Whether the current URL is in Picture in Picture. Local flag only.
    open var urlIsPictureInPicture: Bool = false

    /// Whether Screen Time is blocking `url`.
    ///
    /// Always `false` on Linux. There is no web-content filter agent.
    open var urlIsBlocked: Bool { false }

    /// Safari / browser profile associated with this page.
    open var profileIdentifier: STWebHistory.ProfileIdentifier?

    /// Bundle identifier last accepted by `setBundleIdentifier(_:)`.
    public private(set) var bundleIdentifier: String?

    public override init() {
        super.init()
    }

    /// Associates this controller with a browser bundle identifier.
    ///
    /// Throws `STScreenTimeError.invalidBundleIdentifier` when the string is
    /// empty or whitespace. A successful set is not a usage-reporting session.
    open func setBundleIdentifier(_ bundleIdentifier: String) throws {
        try screenTimeRequireNonemptyBundleIdentifier(bundleIdentifier)
        self.bundleIdentifier = bundleIdentifier
    }
}
