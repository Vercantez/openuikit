// UIDocumentBrowserViewController — fail-closed. Document manager is
// remote UI. Delegate creation/pick paths fire only through host SPI.

#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
#elseif canImport(Foundation)
import Foundation
#endif
#if canImport(Foundation)
import Foundation
import class Foundation.NSObject
#elseif canImport(ObjectiveC)
import class ObjectiveC.NSObject
#endif

public let UIDocumentBrowserErrorDomain: String = "UIDocumentBrowserErrorDomain"

/// NS_ERROR_ENUM(UIDocumentBrowserErrorDomain, UIDocumentBrowserErrorCode)
/// SwiftName: UIDocumentBrowserViewController.Error (UIKit.apinotes).
public enum UIDocumentBrowserErrorCode: Int, Error, Sendable {
    case generic = 1
    case noLocationAvailable = 2
}

public typealias UIDocumentCreationIntent = String

@preconcurrency @MainActor
public protocol UIDocumentBrowserViewControllerDelegate: AnyObject {
    func documentBrowser(_ controller: UIDocumentBrowserViewController,
                         didPickDocumentsAt documentURLs: [URL])
    func documentBrowser(_ controller: UIDocumentBrowserViewController,
                         didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void)
    func documentBrowser(_ controller: UIDocumentBrowserViewController,
                         didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL)
    func documentBrowser(_ controller: UIDocumentBrowserViewController,
                         failedToImportDocumentAt documentURL: URL, error: Error?)
    func documentBrowser(_ controller: UIDocumentBrowserViewController,
                         applicationActivitiesForDocumentURLs documentURLs: [URL]) -> [UIActivity]
    func documentBrowser(_ controller: UIDocumentBrowserViewController,
                         willPresent activityViewController: UIActivityViewController)
}

extension UIDocumentBrowserViewControllerDelegate {
    public func documentBrowser(_ controller: UIDocumentBrowserViewController,
                                didPickDocumentsAt documentURLs: [URL]) {}
    public func documentBrowser(_ controller: UIDocumentBrowserViewController,
                                didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
        importHandler(nil, .none)
    }
    public func documentBrowser(_ controller: UIDocumentBrowserViewController,
                                didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {}
    public func documentBrowser(_ controller: UIDocumentBrowserViewController,
                                failedToImportDocumentAt documentURL: URL, error: Error?) {}
    public func documentBrowser(_ controller: UIDocumentBrowserViewController,
                                applicationActivitiesForDocumentURLs documentURLs: [URL]) -> [UIActivity] { [] }
    public func documentBrowser(_ controller: UIDocumentBrowserViewController,
                                willPresent activityViewController: UIActivityViewController) {}
}

@preconcurrency @MainActor
open class UIDocumentBrowserViewController: UIViewController {
    public enum ImportMode: UInt, Sendable {
        case none = 0
        case copy = 1
        case move = 2
    }

    public enum BrowserUserInterfaceStyle: UInt, Sendable {
        case white = 0
        case light = 1
        case dark = 2
    }

    public weak var delegate: UIDocumentBrowserViewControllerDelegate?
    public var allowsDocumentCreation: Bool = true
    public var allowsPickingMultipleItems: Bool = false
    public var shouldShowFileExtensions: Bool = false
    public var additionalLeadingNavigationBarButtonItems: [UIBarButtonItem] = []
    public var additionalTrailingNavigationBarButtonItems: [UIBarButtonItem] = []
    public var customActions: [UIDocumentBrowserAction] = []
    public var browserUserInterfaceStyle: BrowserUserInterfaceStyle = .white
    public var localizedCreateDocumentActionTitle: String = "Create Document"
    public var defaultDocumentAspectRatio: CGFloat = 2.0 / 3.0
    public private(set) var allowedContentTypes: [String] = []
    public private(set) var contentTypesForRecentDocuments: [UTType]
    public var recentDocumentsContentTypes: [String] { allowedContentTypes }
    public var activeDocumentCreationIntent: UIDocumentCreationIntent? { nil }

    public init(forOpening contentTypes: [UTType]?) {
        let types = contentTypes ?? []
        self.contentTypesForRecentDocuments = types
        self.allowedContentTypes = types.map(\.identifier)
        super.init()
        modalPresentationStyle = .fullScreen
    }

    public convenience init(forOpeningFilesWithContentTypes allowedContentTypes: [String]?) {
        self.init(forOpening: allowedContentTypes?.map { UTType(importedAs: $0) })
    }

    open override func loadView() {
        let body = _UIUnavailableSystemUIView(
            message: "Document browser is unavailable.",
            cancelTitle: "Done")
        body.onCancel = { [weak self] in self?.dismiss(animated: true) }
        view = body
    }

    public func revealDocument(at url: URL, importIfNeeded: Bool,
                               completion: ((URL?, Error?) -> Void)?) {
        completion?(nil, NSError(domain: UIDocumentBrowserErrorDomain,
                                  code: UIDocumentBrowserErrorCode.noLocationAvailable.rawValue,
                                  userInfo: nil))
    }

    public func importDocument(at documentURL: URL, nextToDocumentAt neighbourURL: URL,
                               mode: ImportMode, completionHandler: @escaping (URL?, Error?) -> Void) {
        completionHandler(nil, NSError(domain: UIDocumentBrowserErrorDomain,
                                        code: UIDocumentBrowserErrorCode.generic.rawValue,
                                        userInfo: nil))
    }

    public func renameDocument(at documentURL: URL, proposedName: String,
                               completionHandler: @escaping (URL?, Error?) -> Void) {
        completionHandler(nil, NSError(domain: UIDocumentBrowserErrorDomain,
                                        code: UIDocumentBrowserErrorCode.generic.rawValue,
                                        userInfo: nil))
    }

    public func transitionController(forDocumentAt documentURL: URL) -> UIDocumentBrowserTransitionController {
        UIDocumentBrowserTransitionController(documentURL: documentURL)
    }

    @_spi(OpenUIKitHost)
    public func _hostPick(urls: [URL]) {
        delegate?.documentBrowser(self, didPickDocumentsAt: urls)
    }
}

@preconcurrency @MainActor
open class UIDocumentBrowserAction: NSObject {
    public typealias Identifier = String
    public enum Availability: UInt, Sendable {
        case menu = 1
        case navigationBar = 2
    }

    public let identifier: Identifier
    public var title: String
    public var image: UIImage?
    public var supportedContentTypes: [String] = []
    public var supportsMultipleSelection: Bool = false
    public var availability: Availability = .menu
    public var handler: (([URL]) -> Void)?

    public init(identifier: Identifier, localizedTitle: String,
                availability: Availability, handler: @escaping ([URL]) -> Void) {
        self.identifier = identifier
        self.title = localizedTitle
        self.availability = availability
        self.handler = handler
        super.init()
    }
}

@preconcurrency @MainActor
open class UIDocumentBrowserTransitionController: NSObject, UIViewControllerAnimatedTransitioning {
    public var loadingProgress: Progress?
    public weak var targetView: UIView?

    init(documentURL: URL) {
        _ = documentURL
        super.init()
    }

    public func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?
    ) -> TimeInterval { 0 }

    public func animateTransition(
        using transitionContext: UIViewControllerContextTransitioning
    ) {
        transitionContext.completeTransition(true)
    }
}
