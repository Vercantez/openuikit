import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(OpenUIKit)
import OpenUIKit
#else
#error("SafariServices requires UIKit or OpenUIKit")
#endif

public struct SafariServicesPortableError: Error, Equatable, Sendable,
    CustomStringConvertible
{
    public enum Code: Int, Sendable {
        case browserServiceUnavailable = 1
        case contentBlockerServiceUnavailable = 2
    }

    public let code: Code
    public let description: String

    public init(_ code: Code) {
        self.code = code
        switch code {
        case .browserServiceUnavailable:
            description = "Safari browsing service is unavailable on this host"
        case .contentBlockerServiceUnavailable:
            description = "Safari content-blocker service is unavailable on this host"
        }
    }
}

public final class SFContentBlockerState {
    public let isEnabled: Bool

    public init(isEnabled: Bool) {
        self.isEnabled = isEnabled
    }
}

public enum SFContentBlockerManager {
    public static func getStateOfContentBlocker(
        withIdentifier identifier: String,
        completionHandler: @escaping (SFContentBlockerState?, Error?) -> Void
    ) {
        completionHandler(
            nil,
            SafariServicesPortableError(.contentBlockerServiceUnavailable)
        )
    }

    public static func reloadContentBlocker(
        withIdentifier identifier: String,
        completionHandler: @escaping (Error?) -> Void
    ) {
        completionHandler(
            SafariServicesPortableError(.contentBlockerServiceUnavailable)
        )
    }
}

public final class SFSafariViewControllerConfiguration {
    public var entersReaderIfAvailable = false
    public var barCollapsingEnabled = true

    public init() {}

    public func copy() -> SFSafariViewControllerConfiguration {
        let copy = SFSafariViewControllerConfiguration()
        copy.entersReaderIfAvailable = entersReaderIfAvailable
        copy.barCollapsingEnabled = barCollapsingEnabled
        return copy
    }
}

@MainActor
public protocol SFSafariViewControllerDelegate: AnyObject {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController)
    func safariViewController(
        _ controller: SFSafariViewController,
        didCompleteInitialLoad didLoadSuccessfully: Bool
    )
    func safariViewController(
        _ controller: SFSafariViewController,
        activityItemsFor URL: URL,
        title: String?
    ) -> [Any]
}

public extension SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {}

    func safariViewController(
        _ controller: SFSafariViewController,
        didCompleteInitialLoad didLoadSuccessfully: Bool
    ) {}

    func safariViewController(
        _ controller: SFSafariViewController,
        activityItemsFor URL: URL,
        title: String?
    ) -> [Any] { [] }
}

/// A constructible presentation shell. It preserves the requested URL and
/// copied configuration but deliberately never claims that Safari loaded it.
@MainActor
open class SFSafariViewController: UIViewController {
    public typealias Configuration = SFSafariViewControllerConfiguration

    public let initialURL: URL
    public let configuration: Configuration
    public weak var delegate: SFSafariViewControllerDelegate?
    public var preferredBarTintColor: UIColor?
    public var preferredControlTintColor: UIColor?
    public var dismissButtonStyle: DismissButtonStyle = .done
    public let portableError = SafariServicesPortableError(
        .browserServiceUnavailable
    )

    public enum DismissButtonStyle: Int, Sendable {
        case done = 0
        case close = 1
        case cancel = 2
    }

    public init(url URL: URL) {
        initialURL = URL
        configuration = Configuration()
        super.init(nibName: nil, bundle: nil)
    }

    public convenience init(url URL: URL, entersReaderIfAvailable: Bool) {
        let configuration = Configuration()
        configuration.entersReaderIfAvailable = entersReaderIfAvailable
        self.init(url: URL, configuration: configuration)
    }

    public init(url URL: URL, configuration: Configuration) {
        initialURL = URL
        self.configuration = configuration.copy()
        super.init(nibName: nil, bundle: nil)
    }

    public override init() {
        initialURL = URL(string: "about:blank")!
        configuration = Configuration()
        super.init()
    }

    /// Hosts call this when presentation begins. The callback is explicitly a
    /// failed initial load; no network request or renderer is started.
    public func reportPortableInitialLoadFailure() {
        delegate?.safariViewController(self, didCompleteInitialLoad: false)
    }
}
