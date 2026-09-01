enum ImagePlaygroundUIKitAvailability {
    static var isLinked: Bool {
        #if canImport(UIKit)
        true
        #else
        false
        #endif
    }
}

#if canImport(UIKit)
import UIKit

/// Displays a system interface for generating images from concepts.
///
/// This is a real `UIKit.UIViewController` subclass. Linux has no Image
/// Playground generative UI, so ``isAvailable`` is `false` and the delegate is
/// never invoked from production paths. Host tests may dispatch the delegate
/// through ``_dispatchDelegateDidCreateImageAtForHostTests`` /
/// ``_dispatchDelegateDidCancelForHostTests``.
@MainActor
public class ImagePlaygroundViewController: UIViewController {
    public class var isAvailable: Bool { false }

    public weak var delegate: (any Delegate)?

    public var sourceImage: UIImage?

    public var concepts: [ImagePlaygroundConcept] = []

    public var allowedGenerationStyles: [ImagePlaygroundStyle] = ImagePlaygroundStyle.all

    public var selectedGenerationStyle: ImagePlaygroundStyle = .illustration

    public var personalizationPolicy: ImagePlaygroundPersonalizationPolicy = .automatic

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public convenience init() {
        self.init(nibName: nil, bundle: nil)
    }

    public override var modalPresentationStyle: UIModalPresentationStyle {
        get { super.modalPresentationStyle }
        set { super.modalPresentationStyle = newValue }
    }

    public override var preferredContentSize: CGSize {
        get { super.preferredContentSize }
        set { super.preferredContentSize = newValue }
    }

    public override var isModalInPresentation: Bool {
        get { super.isModalInPresentation }
        set { super.isModalInPresentation = newValue }
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        super.supportedInterfaceOrientations
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    /// Dispatches the required delegate method through an existential.
    /// Does not create or write an image file.
    @_spi(OpenUIKitHost)
    public func _dispatchDelegateDidCreateImageAtForHostTests(_ imageURL: URL) {
        let existential: (any Delegate)? = delegate
        existential?.imagePlaygroundViewController(self, didCreateImageAt: imageURL)
    }

    /// Dispatches the optional cancel method through an existential.
    @_spi(OpenUIKitHost)
    public func _dispatchDelegateDidCancelForHostTests() {
        let existential: (any Delegate)? = delegate
        existential?.imagePlaygroundViewControllerDidCancel(self)
    }
}

extension ImagePlaygroundViewController {
    /// Receives generated-image URLs and cancel events.
    ///
    /// Apple's protocol is `@objc` and inherits `NSObjectProtocol`. This
    /// starting point uses `NSObjectProtocol` with a Swift default for the
    /// optional cancel method; `@objc optional` is not used because this
    /// isolated Linux compile has no Objective-C dispatch for the requirement.
    @MainActor
    public protocol Delegate: NSObjectProtocol {
        func imagePlaygroundViewController(
            _ imagePlaygroundViewController: ImagePlaygroundViewController,
            didCreateImageAt imageURL: URL
        )

        func imagePlaygroundViewControllerDidCancel(
            _ imagePlaygroundViewController: ImagePlaygroundViewController
        )
    }
}

extension ImagePlaygroundViewController.Delegate {
    public func imagePlaygroundViewControllerDidCancel(
        _ imagePlaygroundViewController: ImagePlaygroundViewController
    ) {
        _ = imagePlaygroundViewController
    }
}
#endif
