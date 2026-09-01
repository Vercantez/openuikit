import Foundation

/// In-app social compose sheet.
///
/// Linux has no Twitter/Facebook/Weibo/LinkedIn account integration.
/// `isAvailable(forServiceType:)` is therefore always `false`. The
/// initializer still produces a local draft so callers can record text,
/// images, and URLs; posting those attachments to an Apple social service
/// is not implemented.
@MainActor
open class SLComposeViewController: UIViewController {
    public init?(forServiceType serviceType: String?) {
        guard let serviceType, !serviceType.isEmpty else { return nil }
        self.serviceType = serviceType
        super.init(nibName: nil, bundle: nil)
    }

    open private(set) var serviceType: String!

    open var completionHandler: SLComposeViewControllerCompletionHandler!

    /// Local draft text. Not an Apple property; exposed so hosts and tests
    /// can inspect `setInitialText(_:)` without fabricating a post.
    public private(set) var portableInitialText: String = ""

    /// Local draft images accepted by `add(_:)`.
    public private(set) var portableImages: [UIImage] = []

    /// Local draft URLs accepted by `add(_:)`.
    public private(set) var portableURLs: [URL] = []

    /// Always `false` on Linux: no Apple social account is configured.
    open class func isAvailable(forServiceType serviceType: String!) -> Bool {
        _ = serviceType
        return false
    }

    open func setInitialText(_ text: String!) -> Bool {
        guard let text else { return false }
        portableInitialText = text
        return true
    }

    open func add(_ image: UIImage!) -> Bool {
        guard let image else { return false }
        portableImages.append(image)
        return true
    }

    open func add(_ url: URL!) -> Bool {
        guard let url else { return false }
        portableURLs.append(url)
        return true
    }

    open func removeAllImages() -> Bool {
        portableImages.removeAll()
        return true
    }

    open func removeAllURLs() -> Bool {
        portableURLs.removeAll()
        return true
    }

    /// Invoke the completion handler without claiming an Apple-network post.
    /// Hosts should pass `.cancelled` unless they have independently posted.
    open func completeDraft(with result: SLComposeViewControllerResult) {
        completionHandler?(result)
    }
}
