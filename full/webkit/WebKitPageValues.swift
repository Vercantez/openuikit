import Foundation

extension WebPage {
    /// In-process navigation policy values; setting these does not enable a
    /// renderer, HTTPS service, or system Lockdown Mode on the Linux host.
    public struct NavigationPreferences: Sendable {
        public enum ContentMode: Hashable, Sendable {
            case recommended
            case mobile
            case desktop
        }

        public enum UpgradeToHTTPSPolicy: Hashable, Sendable {
            case keepAsRequested
            case automaticFallbackToHTTP
            case userMediatedFallbackToHTTP
            case errorOnFailure
        }

        // Private iPhone 17 Pro / iOS 26.1, fw-webkit-c value probe:
        // recommended, true, keepAsRequested, false. Copy mutation preserves
        // the original preferences, including through Configuration copies.
        public var preferredContentMode: ContentMode = .recommended
        public var allowsContentJavaScript = true
        public var preferredHTTPSNavigationPolicy: UpgradeToHTTPSPolicy = .keepAsRequested
        public var isLockdownModeEnabled = false

        public init() {}
    }

    public enum JavaScriptConfirmResult: Hashable, Sendable {
        case ok
        case cancel
    }

    public enum JavaScriptPromptResult: Hashable, Sendable {
        case ok(String)
        case cancel
    }

    public enum FileInputPromptResult: Hashable, Sendable {
        case selected([URL])
        case cancel
    }

    public enum FullscreenState: Hashable, Sendable {
        case notInFullscreen
        case enteringFullscreen
        case inFullscreen
        case exitingFullscreen
    }

    public enum NavigationError: Error {
        // iOS 26.1 NSError bridge: failed=0, pageClosed=1,
        // processTerminated=2, invalidURL=3 (fw-webkit-c error probe).
        case failedProvisionalNavigation(any Error)
        case pageClosed
        case webContentProcessTerminated
        case invalidURL
    }
}
