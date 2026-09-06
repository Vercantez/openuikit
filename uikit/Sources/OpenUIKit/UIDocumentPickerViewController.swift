// UIDocumentPickerViewController — AN HONEST STUB. APP LADDER §4 row 12
// (10 apps / 51 uses + delegate 10/22).
//
// The iOS document picker is a remote view controller (File Provider /
// document manager). Nothing here opens files. What OpenUIKit provides:
//
//   - every initializer the iOS 26.1 header names (`forOpeningContentTypes`,
//     `forExporting`, the deprecated UTI/URL forms);
//   - stored `allowsMultipleSelection`, `shouldShowFileExtensions`,
//     `directoryURL`;
//   - a page-sheet placeholder that calls `documentPickerWasCancelled` on
//     Cancel, sheet dismiss, or the host signal `_hostCancel()`.
//
// There is no document-picker service, so a successful pick is only
// possible through the host SPI `_hostPick(urls:)`.

#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
#elseif canImport(Foundation)
import Foundation
#endif
#if canImport(Foundation)
import struct Foundation.URL
#endif

@preconcurrency @MainActor
public protocol UIDocumentPickerDelegate: AnyObject {
    func documentPicker(_ controller: UIDocumentPickerViewController,
                        didPickDocumentsAt urls: [URL])
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController)
    func documentPicker(_ controller: UIDocumentPickerViewController,
                        didPickDocumentAt url: URL)
}

extension UIDocumentPickerDelegate {
    public func documentPicker(_ controller: UIDocumentPickerViewController,
                                didPickDocumentsAt urls: [URL]) {}
    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {}
    public func documentPicker(_ controller: UIDocumentPickerViewController,
                                didPickDocumentAt url: URL) {
        documentPicker(controller, didPickDocumentsAt: [url])
    }
}

public enum UIDocumentPickerMode: UInt, Sendable {
    case `import` = 0
    case open = 1
    case exportToService = 2
    case moveToService = 3
}

@preconcurrency @MainActor
open class UIDocumentPickerViewController: UIViewController {
    public weak var delegate: UIDocumentPickerDelegate?
    public private(set) var documentPickerMode: UIDocumentPickerMode = .open
    public var allowsMultipleSelection: Bool = false
    public var shouldShowFileExtensions: Bool = false
    public var directoryURL: URL?

    public let allowedContentTypes: [UTType]
    public let asCopy: Bool
    public let exportedURLs: [URL]

    private var didFinish = false

    public init(forOpeningContentTypes contentTypes: [UTType], asCopy: Bool) {
        self.allowedContentTypes = contentTypes
        self.asCopy = asCopy
        self.exportedURLs = []
        self.documentPickerMode = asCopy ? .import : .open
        super.init()
        modalPresentationStyle = .pageSheet
    }

    public convenience init(forOpeningContentTypes contentTypes: [UTType]) {
        self.init(forOpeningContentTypes: contentTypes, asCopy: false)
    }

    public init(forExporting urls: [URL], asCopy: Bool) {
        self.allowedContentTypes = []
        self.asCopy = asCopy
        self.exportedURLs = urls
        self.documentPickerMode = asCopy ? .exportToService : .moveToService
        super.init()
        modalPresentationStyle = .pageSheet
    }

    public convenience init(forExporting urls: [URL]) {
        self.init(forExporting: urls, asCopy: false)
    }

    /// ObjC importer name (`initForExportingURLs:`). Same storage as
    /// `init(forExporting:asCopy:)`.
    public convenience init(forExportingURLs urls: [URL], asCopy: Bool) {
        self.init(forExporting: urls, asCopy: asCopy)
    }

    public convenience init(forExportingURLs urls: [URL]) {
        self.init(forExporting: urls, asCopy: false)
    }

    public init(documentTypes allowedUTIs: [String], in mode: UIDocumentPickerMode) {
        self.allowedContentTypes = allowedUTIs.map { UTType(importedAs: $0) }
        self.asCopy = mode == .import
        self.exportedURLs = []
        self.documentPickerMode = mode
        super.init()
        modalPresentationStyle = .pageSheet
    }

    public init(url: URL, in mode: UIDocumentPickerMode) {
        self.allowedContentTypes = []
        self.asCopy = mode == .exportToService
        self.exportedURLs = [url]
        self.documentPickerMode = mode
        super.init()
        modalPresentationStyle = .pageSheet
    }

    public init(urls: [URL], in mode: UIDocumentPickerMode) {
        self.allowedContentTypes = []
        self.asCopy = mode == .exportToService
        self.exportedURLs = urls
        self.documentPickerMode = mode
        super.init()
        modalPresentationStyle = .pageSheet
    }

    open override func loadView() {
        let body = _UIUnavailableSystemUIView(
            message: "Document picker is unavailable.",
            cancelTitle: "Cancel")
        body.onCancel = { [weak self] in self?._finishCancelled() }
        view = body
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if !didFinish { _finishCancelled() }
    }

    @_spi(OpenUIKitHost)
    public func _hostCancel() { _finishCancelled() }

    @_spi(OpenUIKitHost)
    public func _hostPick(urls: [URL]) {
        guard !didFinish else { return }
        didFinish = true
        delegate?.documentPicker(self, didPickDocumentsAt: urls)
        if presentingViewController != nil { dismiss(animated: true) }
    }

    private func _finishCancelled() {
        guard !didFinish else { return }
        didFinish = true
        delegate?.documentPickerWasCancelled(self)
        if presentingViewController != nil { dismiss(animated: true) }
    }
}
