import Foundation

#if canImport(UIKit)
import UIKit
#endif

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
#if canImport(UIKit)
    private let pageImages: [UIImage]
#endif
    private let storedTitle: String
    private let storedPageCount: Int

    open var pageCount: Int { storedPageCount }
    open var title: String { storedTitle }

#if canImport(UIKit)
    @_spi(OpenUIKitHost)
    public init(title: String = "", pageImages: [UIImage] = []) {
        self.storedTitle = title
        self.pageImages = pageImages
        self.storedPageCount = pageImages.count
        super.init()
    }

    open func imageOfPage(at index: Int) -> UIImage {
        pageImages[index]
    }
#else
    @_spi(OpenUIKitHost)
    public init(title: String = "", pageCount: Int = 0) {
        self.storedTitle = title
        self.storedPageCount = pageCount
        super.init()
    }
#endif
}

/// System document-camera interface.
///
/// There is no camera or VisionKit document-scan backend on Linux, so
/// `isSupported` is `false`. Presenting this controller must not be treated
/// as a successful scan.
#if canImport(UIKit)
public typealias VisionKitHostDocumentCameraBase = UIViewController
#else
public typealias VisionKitHostDocumentCameraBase = NSObject
#endif

@MainActor
open class VNDocumentCameraViewController: VisionKitHostDocumentCameraBase {
    open class var isSupported: Bool { false }

    open weak var delegate: (any VNDocumentCameraViewControllerDelegate)?

#if canImport(UIKit)
    public override init() {
        super.init(nibName: nil, bundle: nil)
    }
#else
    public override init() {
        super.init()
    }
#endif

    @_spi(OpenUIKitHost)
    open func failClosed() {
        delegate?.documentCameraViewController(
            self,
            didFailWithError: VisionKitHostError.documentCameraUnsupported
        )
    }

    @_spi(OpenUIKitHost)
    open func cancel() {
        delegate?.documentCameraViewControllerDidCancel(self)
    }
}
