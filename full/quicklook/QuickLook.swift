import Foundation

#if canImport(UIKit)
import UIKit
#endif
#if canImport(PDFKit)
import PDFKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif

/// The item contract consumed by `QLPreviewController`.
///
/// Objective-C optional requirements are expressed with protocol defaults on
/// the portable runtime so ordinary Swift conformers can implement the same
/// source surface while Objective-C interoperability is disabled.
public protocol QLPreviewItem: NSObjectProtocol {
  var previewItemURL: URL? { get }
  var previewItemTitle: String? { get }
}

public extension QLPreviewItem {
  var previewItemTitle: String? { nil }
}

extension NSURL: QLPreviewItem {
  public var previewItemURL: URL? { self as URL }
}

public enum QLPreviewItemEditingMode: Int, Sendable {
  case disabled = 0
  case updateContents = 1
  case createCopy = 2
}

public final class ARQuickLookPreviewItem: NSObject, QLPreviewItem {
  public let previewItemURL: URL?
  public var previewItemTitle: String? { nil }
  public var canonicalWebPageURL: URL?
  public var allowsContentScaling = true

  public init(fileAt url: URL) {
    previewItemURL = url
    super.init()
  }

  public convenience init(fileAtURL url: URL) {
    self.init(fileAt: url)
  }
}

/// Observable boundary between Quick Look's source-facing API and a host.
///
/// OpenUIKit includes a local image/PDF/text controller when UIKit is present.
/// Embedders can replace that presenter through the SPI without claiming an
/// Apple Quick Look daemon or support for proprietary preview generators.
@MainActor
public enum QuickLookPortable {
  public enum PresentationCapability: String, Sendable {
    case localImageAndMetadata
    case hostDriven
    case unavailable
  }

  public enum Event: Equatable, Sendable {
    case present(urls: [URL], selectedIndex: Int)
    case dismiss
  }

  #if canImport(UIKit)
  public static let defaultCapability =
    PresentationCapability.localImageAndMetadata
  #else
  public static let defaultCapability = PresentationCapability.unavailable
  #endif

  public static let supportsProprietaryPreviewGenerators = false
  public static let supportsEditing = false

  private static var eventHandler: ((Event) -> Void)?
  private static var selectionSink: ((URL?) -> Void)?
  private static var active = false

  #if canImport(UIKit)
  private static weak var activeController: QLPreviewController?
  #endif

  @_spi(OpenUIKitHost)
  public static func _installEventHandler(
    _ handler: ((Event) -> Void)?
  ) {
    eventHandler = handler
  }

  @_spi(OpenUIKitHost)
  @discardableResult
  public static func _requestPresentation(
    urls: [URL],
    selectedURL: URL,
    selectionDidChange: @escaping (URL?) -> Void
  ) -> Bool {
    guard
      let selectedIndex = urls.firstIndex(of: selectedURL),
      selectedURL.isFileURL
    else {
      return false
    }

    selectionSink = selectionDidChange
    active = true
    if let eventHandler {
      eventHandler(.present(urls: urls, selectedIndex: selectedIndex))
      return true
    }

    #if canImport(UIKit)
    guard let presenter = _topPresenter() else {
      active = false
      selectionSink = nil
      return false
    }
    let controller = QLPreviewController()
    controller._setPortableURLs(urls, selectedIndex: selectedIndex) {
      _hostDidDismiss()
    }
    activeController = controller
    let nav = UINavigationController(rootViewController: controller)
    presenter.present(nav, animated: true)
    return true
    #else
    active = false
    selectionSink = nil
    return false
    #endif
  }

  @_spi(OpenUIKitHost)
  public static func _dismissPresentation() {
    guard active else { return }
    active = false
    selectionSink = nil
    eventHandler?(.dismiss)
    #if canImport(UIKit)
    activeController?.dismiss(animated: true)
    activeController = nil
    #endif
  }

  @_spi(OpenUIKitHost)
  public static func _hostDidSelect(_ url: URL?) {
    guard active else { return }
    selectionSink?(url)
  }

  @_spi(OpenUIKitHost)
  public static func _hostDidDismiss() {
    guard active else { return }
    let sink = selectionSink
    active = false
    selectionSink = nil
    #if canImport(UIKit)
    activeController = nil
    #endif
    eventHandler?(.dismiss)
    sink?(nil)
  }

  @_spi(OpenUIKitHost)
  public static func _reset() {
    active = false
    eventHandler = nil
    selectionSink = nil
    #if canImport(UIKit)
    activeController = nil
    #endif
  }

  #if canImport(UIKit)
  private static func _topPresenter() -> UIViewController? {
    var controller = UIApplication.shared.keyWindow?.rootViewController
    while let presented = controller?.presentedViewController {
      controller = presented
    }
    return controller
  }
  #endif
}

/// System-created file-preview request. Apple does not publish a public
/// initializer; the isolated host constructs instances through the OpenUIKit
/// SPI so `fileURL` can be exercised without inventing a second public identity.
open class QLFilePreviewRequest: NSObject {
  public let fileURL: URL

  @_spi(OpenUIKitHost)
  public init(fileURL: URL) {
    self.fileURL = fileURL
    super.init()
  }
}

/// Reply returned by a `QLPreviewingController`. Drawing, typed-data, and PDF
/// initializers store their arguments and never invoke the supplied generators
/// on this host: there is no Quick Look preview pipeline.
open class QLPreviewReply: NSObject {
  public var stringEncoding: String.Encoding = .utf8
  public var attachments: [String: QLPreviewReplyAttachment] = [:]
  public var title: String = ""

  private let sourceFileURL: URL?
  private let storedContextSize: CGSize?
  private let storedIsBitmap: Bool?
  private let storedContentType: UTType?
  private let storedContentSize: CGSize?
  private let storedPDFPageSize: CGSize?
  private let drawUsing:
    ((CGContext, QLPreviewReply) throws -> Void)?
  private let createDataUsing: ((QLPreviewReply) throws -> Data)?
  private let createDocumentUsing: ((QLPreviewReply) throws -> PDFDocument)?

  public init(fileURL: URL) {
    sourceFileURL = fileURL
    storedContextSize = nil
    storedIsBitmap = nil
    storedContentType = nil
    storedContentSize = nil
    storedPDFPageSize = nil
    drawUsing = nil
    createDataUsing = nil
    createDocumentUsing = nil
    super.init()
  }

  public convenience init(
    contextSize: CGSize,
    isBitmap: Bool,
    drawUsing closure: @escaping (CGContext, QLPreviewReply) throws -> Void
  ) {
    self.init(
      fileURL: nil,
      contextSize: contextSize,
      isBitmap: isBitmap,
      contentType: nil,
      contentSize: nil,
      pdfPageSize: nil,
      drawUsing: closure,
      createDataUsing: nil,
      createDocumentUsing: nil
    )
  }

  public convenience init(
    dataOfContentType contentType: UTType,
    contentSize: CGSize,
    createDataUsing closure: @escaping (QLPreviewReply) throws -> Data
  ) {
    self.init(
      fileURL: nil,
      contextSize: nil,
      isBitmap: nil,
      contentType: contentType,
      contentSize: contentSize,
      pdfPageSize: nil,
      drawUsing: nil,
      createDataUsing: closure,
      createDocumentUsing: nil
    )
  }

  public convenience init(
    forPDFWithPageSize defaultPageSize: CGSize,
    createDocumentUsing closure: @escaping (QLPreviewReply) throws -> PDFDocument
  ) {
    self.init(
      fileURL: nil,
      contextSize: nil,
      isBitmap: nil,
      contentType: nil,
      contentSize: nil,
      pdfPageSize: defaultPageSize,
      drawUsing: nil,
      createDataUsing: nil,
      createDocumentUsing: closure
    )
  }

  private init(
    fileURL: URL?,
    contextSize: CGSize?,
    isBitmap: Bool?,
    contentType: UTType?,
    contentSize: CGSize?,
    pdfPageSize: CGSize?,
    drawUsing: ((CGContext, QLPreviewReply) throws -> Void)?,
    createDataUsing: ((QLPreviewReply) throws -> Data)?,
    createDocumentUsing: ((QLPreviewReply) throws -> PDFDocument)?
  ) {
    sourceFileURL = fileURL
    storedContextSize = contextSize
    storedIsBitmap = isBitmap
    storedContentType = contentType
    storedContentSize = contentSize
    storedPDFPageSize = pdfPageSize
    self.drawUsing = drawUsing
    self.createDataUsing = createDataUsing
    self.createDocumentUsing = createDocumentUsing
    super.init()
  }

  @_spi(OpenUIKitHost)
  public var _fileURL: URL? { sourceFileURL }

  @_spi(OpenUIKitHost)
  public var _contextSize: CGSize? { storedContextSize }

  @_spi(OpenUIKitHost)
  public var _isBitmap: Bool? { storedIsBitmap }

  @_spi(OpenUIKitHost)
  public var _contentType: UTType? { storedContentType }

  @_spi(OpenUIKitHost)
  public var _contentSize: CGSize? { storedContentSize }

  @_spi(OpenUIKitHost)
  public var _pdfPageSize: CGSize? { storedPDFPageSize }
}

/// Attachment payload. `contentType` is UniformTypeIdentifiers.UTType when that
/// module is importable; otherwise the host-local stand-in of the same name.
open class QLPreviewReplyAttachment: NSObject {
  public let data: Data
  public let contentType: UTType

  public init(data: Data, contentType: UTType) {
    self.data = data
    self.contentType = contentType
    super.init()
  }
}

/// Extension-hosted preview provider. Apple instantiates this from the
/// extension principal class; the isolated host only needs the type identity.
open class QLPreviewProvider: NSObject {}

/// Scene-activation options for Quick Look. The Apple type inherits
/// `UIWindowSceneActivationConfiguration`; the Foundation host is `NSObject`.
open class QLPreviewSceneActivationConfiguration: NSObject {
  public final class Options: NSObject {
    public var initialPreviewIndex: Int = 0
  }

  private let itemURLs: [URL]
  private let sceneOptions: Options?

  public init(itemsAt urls: [URL], options: Options?) {
    itemURLs = urls
    sceneOptions = options
    super.init()
  }

  public convenience init(itemsAtURLs urls: [URL], options: Options?) {
    self.init(itemsAt: urls, options: options)
  }

  @_spi(OpenUIKitHost)
  public var _itemURLs: [URL] { itemURLs }

  @_spi(OpenUIKitHost)
  public var _sceneOptions: Options? { sceneOptions }
}

/// Fail-closed preview-generation contract. Optional Apple methods become
/// throwing defaults; the isolated host never claims a generator or Spotlight
/// preview pipeline. Defaults throw `CocoaError.featureUnsupported` rather than
/// inventing an unobserved Quick Look error payload.
public protocol QLPreviewingController: NSObjectProtocol {
  func preparePreviewOfFile(at url: URL) async throws
  func preparePreviewOfSearchableItem(
    identifier: String,
    queryString: String?
  ) async throws
  func providePreview(for request: QLFilePreviewRequest) async throws
    -> QLPreviewReply
}

public extension QLPreviewingController {
  func preparePreviewOfFile(at url: URL) async throws {
    _ = url
    throw CocoaError(.featureUnsupported)
  }

  func preparePreviewOfSearchableItem(
    identifier: String,
    queryString: String?
  ) async throws {
    _ = identifier
    _ = queryString
    throw CocoaError(.featureUnsupported)
  }

  func providePreview(for request: QLFilePreviewRequest) async throws
    -> QLPreviewReply
  {
    _ = request
    throw CocoaError(.featureUnsupported)
  }
}

@MainActor
public protocol QLPreviewControllerDataSource: AnyObject {
  func numberOfPreviewItems(in controller: QLPreviewController) -> Int
  func previewController(
    _ controller: QLPreviewController,
    previewItemAt index: Int
  ) -> any QLPreviewItem
}

@MainActor
public protocol QLPreviewControllerDelegate: AnyObject {
  func previewControllerWillDismiss(_ controller: QLPreviewController)
  func previewControllerDidDismiss(_ controller: QLPreviewController)
  func previewController(
    _ controller: QLPreviewController,
    shouldOpen url: URL,
    for item: any QLPreviewItem
  ) -> Bool
  func previewController(
    _ controller: QLPreviewController,
    editingModeFor previewItem: any QLPreviewItem
  ) -> QLPreviewItemEditingMode
  func previewController(
    _ controller: QLPreviewController,
    didUpdateContentsOf previewItem: any QLPreviewItem
  )
  func previewController(
    _ controller: QLPreviewController,
    didSaveEditedCopyOf previewItem: any QLPreviewItem,
    at modifiedContentsURL: URL
  )
  func previewController(
    _ controller: QLPreviewController,
    frameFor item: any QLPreviewItem,
    inSourceView view: UnsafeMutablePointer<UIView?>
  ) -> CGRect
  func previewController(
    _ controller: QLPreviewController,
    transitionImageFor item: any QLPreviewItem,
    contentRect: UnsafeMutablePointer<CGRect>
  ) -> UIImage?
  func previewController(
    _ controller: QLPreviewController,
    transitionViewFor item: any QLPreviewItem
  ) -> UIView?
}

public extension QLPreviewControllerDelegate {
  func previewControllerWillDismiss(_ controller: QLPreviewController) {
    _ = controller
  }

  func previewControllerDidDismiss(_ controller: QLPreviewController) {
    _ = controller
  }

  func previewController(
    _ controller: QLPreviewController,
    shouldOpen url: URL,
    for item: any QLPreviewItem
  ) -> Bool {
    _ = controller
    _ = url
    _ = item
    return true
  }

  func previewController(
    _ controller: QLPreviewController,
    editingModeFor previewItem: any QLPreviewItem
  ) -> QLPreviewItemEditingMode {
    _ = controller
    _ = previewItem
    return .disabled
  }

  func previewController(
    _ controller: QLPreviewController,
    didUpdateContentsOf previewItem: any QLPreviewItem
  ) {
    _ = controller
    _ = previewItem
  }

  func previewController(
    _ controller: QLPreviewController,
    didSaveEditedCopyOf previewItem: any QLPreviewItem,
    at modifiedContentsURL: URL
  ) {
    _ = controller
    _ = previewItem
    _ = modifiedContentsURL
  }

  func previewController(
    _ controller: QLPreviewController,
    frameFor item: any QLPreviewItem,
    inSourceView view: UnsafeMutablePointer<UIView?>
  ) -> CGRect {
    _ = controller
    _ = item
    _ = view
    return .zero
  }

  func previewController(
    _ controller: QLPreviewController,
    transitionImageFor item: any QLPreviewItem,
    contentRect: UnsafeMutablePointer<CGRect>
  ) -> UIImage? {
    _ = controller
    _ = item
    contentRect.pointee = .zero
    return nil
  }

  func previewController(
    _ controller: QLPreviewController,
    transitionViewFor item: any QLPreviewItem
  ) -> UIView? {
    _ = controller
    _ = item
    return nil
  }
}

#if canImport(UIKit)
@MainActor
open class QLPreviewController: UIViewController {
  public weak var dataSource: (any QLPreviewControllerDataSource)?
  public weak var delegate: (any QLPreviewControllerDelegate)?

  public var currentPreviewItemIndex: Int = 0 {
    didSet {
      _normalizeIndex()
      refreshCurrentPreviewItem()
    }
  }

  public var currentPreviewItem: (any QLPreviewItem)? {
    guard cachedItems.indices.contains(currentPreviewItemIndex) else {
      return nil
    }
    return cachedItems[currentPreviewItemIndex]
  }

  private var cachedItems: [any QLPreviewItem] = []
  private var portableDataSource: _QLURLDataSource?
  private var portableDismiss: (() -> Void)?
  private let imageView = UIImageView()
  private let textView = UITextView()
  private let metadataLabel = UILabel()
  #if canImport(PDFKit)
  private let pdfView = PDFView()
  #endif

  open class func canPreview(_ item: any QLPreviewItem) -> Bool {
    guard let url = item.previewItemURL, url.isFileURL else { return false }
    return _QLPreviewableContent.isPreviewable(url: url)
  }

  @_spi(OpenUIKitHost)
  public var _previewTitle: String? {
    currentPreviewItem?.previewItemTitle
      ?? currentPreviewItem?.previewItemURL?.lastPathComponent
  }

  @_spi(OpenUIKitHost)
  public var _previewKind: String {
    _QLPreviewableContent.kind(for: currentPreviewItem?.previewItemURL).rawValue
  }

  open override func viewDidLoad() {
    super.viewDidLoad()
    imageView.contentMode = .scaleAspectFit
    textView.isEditable = false
    textView.isHidden = true
    metadataLabel.numberOfLines = 0
    metadataLabel.textAlignment = .center
    view.addSubview(imageView)
    view.addSubview(textView)
    view.addSubview(metadataLabel)
    #if canImport(PDFKit)
    pdfView.isHidden = true
    view.addSubview(pdfView)
    #endif
    reloadData()
  }

  open override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    imageView.frame = view.bounds
    textView.frame = view.bounds
    metadataLabel.frame = view.bounds.insetBy(dx: 24, dy: 24)
    #if canImport(PDFKit)
    pdfView.frame = view.bounds
    #endif
  }

  open override func viewWillDisappear(_ animated: Bool) {
    delegate?.previewControllerWillDismiss(self)
    super.viewWillDisappear(animated)
  }

  open override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    delegate?.previewControllerDidDismiss(self)
    let callback = portableDismiss
    portableDismiss = nil
    callback?()
  }

  open func reloadData() {
    guard let dataSource else {
      cachedItems = []
      currentPreviewItemIndex = NSNotFound
      _renderCurrentItem()
      return
    }
    let count = max(0, dataSource.numberOfPreviewItems(in: self))
    cachedItems = (0..<count).map {
      dataSource.previewController(self, previewItemAt: $0)
    }
    _normalizeIndex()
    _renderCurrentItem()
  }

  open func refreshCurrentPreviewItem() {
    _renderCurrentItem()
  }

  fileprivate func _setPortableURLs(
    _ urls: [URL], selectedIndex: Int, onDismiss: @escaping () -> Void
  ) {
    let source = _QLURLDataSource(urls: urls)
    portableDataSource = source
    dataSource = source
    portableDismiss = onDismiss
    reloadData()
    currentPreviewItemIndex = selectedIndex
  }

  private func _normalizeIndex() {
    guard !cachedItems.isEmpty else {
      if currentPreviewItemIndex != NSNotFound {
        currentPreviewItemIndex = NSNotFound
      }
      return
    }
    if currentPreviewItemIndex == NSNotFound {
      currentPreviewItemIndex = 0
      return
    }
    let normalized = min(max(currentPreviewItemIndex, 0), cachedItems.count - 1)
    if currentPreviewItemIndex != normalized {
      currentPreviewItemIndex = normalized
    }
  }

  private func _hideContentViews() {
    imageView.isHidden = true
    imageView.image = nil
    textView.isHidden = true
    textView.text = nil
    metadataLabel.isHidden = true
    #if canImport(PDFKit)
    pdfView.isHidden = true
    pdfView.document = nil
    #endif
  }

  private func _renderCurrentItem() {
    navigationItem.title = _previewTitle
    guard isViewLoaded else { return }
    _hideContentViews()
    guard let item = currentPreviewItem else { return }
    let url = item.previewItemURL
    switch _QLPreviewableContent.kind(for: url) {
    case .image:
      if let path = url?.path, let image = UIImage(contentsOfFile: path) {
        imageView.image = image
        imageView.isHidden = false
      } else {
        _showMetadataFallback(item: item, url: url)
      }
    case .pdf:
      #if canImport(PDFKit)
      if let url, let document = PDFDocument(url: url) {
        pdfView.document = document
        pdfView.isHidden = false
      } else {
        _showMetadataFallback(item: item, url: url)
      }
      #else
      _showMetadataFallback(item: item, url: url)
      #endif
    case .text:
      if let url, let body = try? String(contentsOf: url, encoding: .utf8) {
        textView.text = body
        textView.isHidden = false
      } else {
        _showMetadataFallback(item: item, url: url)
      }
    case .other, .unsupported, .empty:
      _showMetadataFallback(item: item, url: url)
    }
  }

  private func _showMetadataFallback(item: any QLPreviewItem, url: URL?) {
    metadataLabel.isHidden = false
    metadataLabel.text = item.previewItemTitle
      ?? url?.lastPathComponent
      ?? "Preview unavailable"
  }
}
#else
@MainActor
open class QLPreviewController: NSObject {
  public weak var dataSource: (any QLPreviewControllerDataSource)?
  public weak var delegate: (any QLPreviewControllerDelegate)?

  public var currentPreviewItemIndex: Int = 0 {
    didSet {
      _normalizeIndex()
      refreshCurrentPreviewItem()
    }
  }

  public var currentPreviewItem: (any QLPreviewItem)? {
    guard cachedItems.indices.contains(currentPreviewItemIndex) else {
      return nil
    }
    return cachedItems[currentPreviewItemIndex]
  }

  private var cachedItems: [any QLPreviewItem] = []

  open class func canPreview(_ item: any QLPreviewItem) -> Bool {
    guard let url = item.previewItemURL, url.isFileURL else { return false }
    return _QLPreviewableContent.isPreviewable(url: url)
  }

  @_spi(OpenUIKitHost)
  public var _previewTitle: String? {
    currentPreviewItem?.previewItemTitle
      ?? currentPreviewItem?.previewItemURL?.lastPathComponent
  }

  @_spi(OpenUIKitHost)
  public var _previewKind: String {
    _QLPreviewableContent.kind(for: currentPreviewItem?.previewItemURL).rawValue
  }

  open func reloadData() {
    guard let dataSource else {
      cachedItems = []
      currentPreviewItemIndex = NSNotFound
      return
    }
    let count = max(0, dataSource.numberOfPreviewItems(in: self))
    cachedItems = (0..<count).map {
      dataSource.previewController(self, previewItemAt: $0)
    }
    _normalizeIndex()
  }

  open func refreshCurrentPreviewItem() {}

  private func _normalizeIndex() {
    guard !cachedItems.isEmpty else {
      if currentPreviewItemIndex != NSNotFound {
        currentPreviewItemIndex = NSNotFound
      }
      return
    }
    if currentPreviewItemIndex == NSNotFound {
      currentPreviewItemIndex = 0
      return
    }
    let normalized = min(max(currentPreviewItemIndex, 0), cachedItems.count - 1)
    if currentPreviewItemIndex != normalized {
      currentPreviewItemIndex = normalized
    }
  }
}
#endif

#if canImport(UIKit)
@MainActor
private final class _QLURLDataSource: QLPreviewControllerDataSource {
  private let items: [NSURL]

  init(urls: [URL]) {
    items = urls.map { $0 as NSURL }
  }

  func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
    _ = controller
    return items.count
  }

  func previewController(
    _ controller: QLPreviewController,
    previewItemAt index: Int
  ) -> any QLPreviewItem {
    _ = controller
    return items[index]
  }
}
#endif

#if canImport(SwiftUI)
@MainActor
private struct _PortableQuickLookModifier: ViewModifier {
  @Binding var selection: URL?
  let items: [URL]

  func body(content: Content) -> some View {
    content
      .onAppear { synchronize(selection) }
      .onChange(of: selection) { _, selectedURL in
        synchronize(selectedURL)
      }
  }

  private func synchronize(_ selectedURL: URL?) {
    guard let selectedURL else {
      QuickLookPortable._dismissPresentation()
      return
    }
    guard items.contains(selectedURL) else {
      selection = nil
      return
    }
    _ = QuickLookPortable._requestPresentation(
      urls: items,
      selectedURL: selectedURL
    ) { updatedSelection in
      selection = updatedSelection
    }
  }
}

public extension View {
  nonisolated func quickLookPreview(_ item: Binding<URL?>) -> some View {
    modifier(
      _PortableQuickLookModifier(
        selection: item,
        items: item.wrappedValue.map { [$0] } ?? []
      )
    )
  }

  nonisolated func quickLookPreview<Items>(
    _ selection: Binding<Items.Element?>,
    in items: Items
  ) -> some View where Items: RandomAccessCollection, Items.Element == URL {
    modifier(
      _PortableQuickLookModifier(
        selection: selection,
        items: Array(items)
      )
    )
  }
}
#endif
