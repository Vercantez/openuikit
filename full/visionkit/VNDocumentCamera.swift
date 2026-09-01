import Foundation

/// Delegate callbacks for the system document camera.
public protocol VNDocumentCameraViewControllerDelegate: NSObjectProtocol {
    func documentCameraViewController(
        _ controller: VNDocumentCameraViewController,
        didFailWithError error: any Error
    )
    func documentCameraViewController(
        _ controller: VNDocumentCameraViewController,
        didFinishWith scan: VNDocumentCameraScan
    )
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController)
}

extension VNDocumentCameraViewControllerDelegate {
    public func documentCameraViewController(
        _ controller: VNDocumentCameraViewController,
        didFailWithError error: any Error
    ) {
        _ = controller
        _ = error
    }

    public func documentCameraViewController(
        _ controller: VNDocumentCameraViewController,
        didFinishWith scan: VNDocumentCameraScan
    ) {
        _ = controller
        _ = scan
    }

    public func documentCameraViewControllerDidCancel(
        _ controller: VNDocumentCameraViewController
    ) {
        _ = controller
    }
}

/// Pages captured by the document camera.
///
/// This Linux port never produces a successful camera scan. Host tests may
/// construct a fixture through `@_spi(OpenUIKitHost)` to exercise storage.
open class VNDocumentCameraScan: NSObject {
    private let pageImages: [UIImage]
    private let storedTitle: String

    open var pageCount: Int { pageImages.count }
    open var title: String { storedTitle }

    @_spi(OpenUIKitHost)
    public init(title: String = "", pageImages: [UIImage] = []) {
        self.storedTitle = title
        self.pageImages = pageImages
        super.init()
    }

    open func imageOfPage(at index: Int) -> UIImage {
        pageImages[index]
    }
}

/// System document-camera interface.
///
/// There is no camera or VisionKit document-scan backend on Linux, so
/// `isSupported` is `false`. Presenting this controller must not be treated
/// as a successful scan.
@MainActor
open class VNDocumentCameraViewController: UIViewController {
    open class var isSupported: Bool { false }

    open weak var delegate: (any VNDocumentCameraViewControllerDelegate)?

    public override init() {
        super.init()
    }

    /// Hosts that still present the shell should report failure rather than a scan.
    open func failClosed() {
        delegate?.documentCameraViewController(
            self,
            didFailWithError: VisionKitAvailabilityError.documentCameraUnsupported
        )
    }

    open func cancel() {
        delegate?.documentCameraViewControllerDidCancel(self)
    }
}
