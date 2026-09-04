import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// System compose sheet for a social service.
///
/// Linux never reports a service as available and never presents Apple UI.
/// `init(forServiceType:)` therefore returns nil. Local draft-state methods
/// (`setInitialText`, `add`, `removeAll*`, `completionHandler`) are exercised
/// through `SocialHostControl.makeComposeViewController`, which does not
/// claim `isAvailable == true`.

@MainActor
open class SLComposeViewController: UIViewController {
    private let storedServiceType: String?
    private var storedInitialText: String?
    private var storedImages: [UIImage] = []
    private var storedURLs: [URL] = []
    private var storedCompletionHandler: SLComposeViewControllerCompletionHandler?
    private var presentedToHost = false

    open class func isAvailable(forServiceType serviceType: String!) -> Bool {
        _ = serviceType
        return false
    }

    public init!(forServiceType serviceType: String!) {
        guard Self.isAvailable(forServiceType: serviceType) else {
            return nil
        }
        self.storedServiceType = serviceType
        #if canImport(UIKit)
        super.init(nibName: nil, bundle: nil)
        #else
        super.init()
        #endif
    }

    init(isolatedHostServiceType serviceType: String) {
        self.storedServiceType = serviceType
        #if canImport(UIKit)
        super.init(nibName: nil, bundle: nil)
        #else
        super.init()
        #endif
    }

    #if canImport(UIKit)
    public required init?(coder: NSCoder) {
        return nil
    }
    #endif

    open var serviceType: String! { storedServiceType }

    open var completionHandler: SLComposeViewControllerCompletionHandler! {
        get { storedCompletionHandler }
        set { storedCompletionHandler = newValue }
    }

    open func setInitialText(_ text: String!) -> Bool {
        guard !presentedToHost, let text else { return false }
        storedInitialText = text
        return true
    }

    open func add(_ image: UIImage!) -> Bool {
        guard !presentedToHost, let image else { return false }
        storedImages.append(image)
        return true
    }

    open func add(_ url: URL!) -> Bool {
        guard !presentedToHost, let url else { return false }
        storedURLs.append(url)
        return true
    }

    open func removeAllImages() -> Bool {
        guard !presentedToHost else { return false }
        storedImages.removeAll()
        return true
    }

    open func removeAllURLs() -> Bool {
        guard !presentedToHost else { return false }
        storedURLs.removeAll()
        return true
    }

    func invokeCompletionHandlerForIsolatedHost(_ result: SLComposeViewControllerResult) {
        guard let handler = storedCompletionHandler else { return }
        storedCompletionHandler = nil
        handler(result)
    }
}

extension SLComposeViewController {
    @_spi(OpenUIKitHost)
    public var isolatedHostInitialText: String? { storedInitialText }

    @_spi(OpenUIKitHost)
    public var isolatedHostImageCount: Int { storedImages.count }

    @_spi(OpenUIKitHost)
    public var isolatedHostURLCount: Int { storedURLs.count }
}
