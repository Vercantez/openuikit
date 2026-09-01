/// Displays a system interface for generating images from concepts.
///
/// Linux has no Image Playground UI and no UIKit view-controller hierarchy
/// in this isolated compile, so this type is an `NSObject` configuration
/// object rather than a `UIViewController` subclass. ``isAvailable`` is
/// always `false`. Properties that require `UIImage`, `UIModalPresentationStyle`,
/// or `UIInterfaceOrientationMask` are omitted until UIKit can be imported.
@MainActor
public class ImagePlaygroundViewController: NSObject {
    /// Whether image generation is available on this device. Always `false`
    /// on Linux.
    public class var isAvailable: Bool { false }

    /// Delegate that would receive a generated file URL or a cancel event.
    /// Never invoked by this starting point; generation UI does not exist.
    public weak var delegate: (any Delegate)?

    /// Concepts describing the expected image contents.
    public var concepts: [ImagePlaygroundConcept] = []

    /// Allowed generation styles shown to the user. Defaults to
    /// ``ImagePlaygroundStyle/all``.
    public var allowedGenerationStyles: [ImagePlaygroundStyle] = ImagePlaygroundStyle.all

    /// Style pre-selected among ``allowedGenerationStyles``.
    public var selectedGenerationStyle: ImagePlaygroundStyle = .illustration

    /// Policy for including people in generated images.
    public var personalizationPolicy: ImagePlaygroundPersonalizationPolicy = .automatic

    /// Preferred size of the presented interface. Defaults to `.zero`
    /// because no UIKit presentation runs here.
    public var preferredContentSize: CGSize = .zero

    /// Whether the interface should prevent interactive dismiss. Defaults to
    /// `false`, matching `UIViewController`.
    public var isModalInPresentation: Bool = false

    public override init() {
        super.init()
    }

    /// Lifecycle hook. No view is loaded on Linux.
    public func viewDidLoad() {}

    /// Lifecycle hook. No view is presented on Linux.
    public func viewDidDisappear(_ animated: Bool) {
        _ = animated
    }
}

extension ImagePlaygroundViewController {
    /// Receives generated-image URLs and cancel events from the view controller.
    ///
    /// Apple's protocol is `@objc` and inherits `NSObjectProtocol`. Linux uses
    /// a Swift `AnyObject` protocol with the same required/optional methods.
    @MainActor
    public protocol Delegate: AnyObject {
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
