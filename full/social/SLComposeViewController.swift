import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// In-app social compose sheet.
///
/// Linux has no Twitter/Facebook/Weibo/LinkedIn account integration.
/// `isAvailable(forServiceType:)` is always `false`. The initializer still
/// produces a local draft so callers can record text, images, and URLs.
@MainActor
open class SLComposeViewController: UIViewController {
    public init!(forServiceType serviceType: String!) {
        guard let serviceType, !serviceType.isEmpty else { return nil }
        self.serviceType = serviceType
        super.init(nibName: nil, bundle: nil)
    }

    open private(set) var serviceType: String!

    open var completionHandler: SLComposeViewControllerCompletionHandler!

    @_spi(OpenUIKitHost)
    public private(set) var hostInitialText: String = ""

    @_spi(OpenUIKitHost)
    public private(set) var hostImages: [UIImage] = []

    @_spi(OpenUIKitHost)
    public private(set) var hostURLs: [URL] = []

    /// Always `false` on Linux: no Apple social account is configured.
    open class func isAvailable(forServiceType serviceType: String!) -> Bool {
        _ = serviceType
        return false
    }

    open func setInitialText(_ text: String!) -> Bool {
        guard let text else { return false }
        hostInitialText = text
        return true
    }

    open func add(_ image: UIImage!) -> Bool {
        guard let image else { return false }
        hostImages.append(image)
        return true
    }

    open func add(_ url: URL!) -> Bool {
        guard let url else { return false }
        hostURLs.append(url)
        return true
    }

    open func removeAllImages() -> Bool {
        hostImages.removeAll()
        return true
    }

    open func removeAllURLs() -> Bool {
        hostURLs.removeAll()
        return true
    }

    /// Invoke and clear the completion handler. Does not post to a network.
    @_spi(OpenUIKitHost)
    open func completeDraft(with result: SLComposeViewControllerResult) {
        let handler = completionHandler
        completionHandler = nil
        handler?(result)
    }
}
