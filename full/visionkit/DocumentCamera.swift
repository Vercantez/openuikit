import Foundation

#if canImport(UIKit)
import UIKit
#endif

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

/// Document-camera scan. Apple does not publish a public initializer. Page
/// images require `UIImage` and are omitted on isolated Linux.
public final class VNDocumentCameraScan: NSObject, @unchecked Sendable {
    public let title: String
    public let pageCount: Int

    fileprivate init(title: String, pageCount: Int) {
        self.title = title
        self.pageCount = pageCount
        super.init()
    }

#if canImport(UIKit)
    public func imageOfPage(at index: Int) -> UIImage {
        _ = index
        return UIImage()
    }
#endif
}

extension VNDocumentCameraScan {
    /// Test-only scan. Does not claim Apple camera output.
    @_spi(OpenUIKitHost)
    public static func hostFixture(title: String, pageCount: Int) -> VNDocumentCameraScan {
        VNDocumentCameraScan(title: title, pageCount: pageCount)
    }
}

/// Document camera UI. Linux has no device camera; `isSupported` is false and
/// no scan, cancel, or fail delegate callback is invented on appear.
///
/// Apple annotates this type `@MainActor`. The isolated Linux host has no
/// UIKit run loop, so the Linux type is usable from synchronous tests.
public class VNDocumentCameraViewController: NSObject {
    public class var isSupported: Bool { false }

    public weak var delegate: (any VNDocumentCameraViewControllerDelegate)?

    public override init() {
        super.init()
    }
}
