import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// The item contract consumed by `QLPreviewController`.
///
/// Objective-C optional requirements are expressed with protocol defaults on
/// the portable runtime so ordinary Swift conformers can implement the same
/// source surface while Objective-C interoperability is disabled.
public protocol QLPreviewItem: AnyObject {
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
/// OpenUIKit includes a local image/metadata controller when UIKit is present.
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
    presenter.present(controller, animated: true)
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
/// convenience initializers stay undeclared on the Foundation-only host because
/// they require CoreGraphics, UniformTypeIdentifiers, or PDFKit types.
open class QLPreviewReply: NSObject {
  public var stringEncoding: String.Encoding = .utf8
  public var attachments: [String: QLPreviewReplyAttachment] = [:]
  public var title: String = ""
  private let sourceFileURL: URL

  public init(fileURL: URL) {
    sourceFileURL = fileURL
    super.init()
  }
}

/// Attachment payload. `contentType` and `init(data:contentType:)` require
/// UniformTypeIdentifiers.UTType, which is not a declared host dependency.
open class QLPreviewReplyAttachment: NSObject {
  public let data: Data

  @_spi(OpenUIKitHost)
  public init(data: Data) {
    self.data = data
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
/// preview pipeline.
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
    throw _QLPreviewingHostError.unsupported
  }

  func preparePreviewOfSearchableItem(
    identifier: String,
    queryString: String?
  ) async throws {
    _ = identifier
    _ = queryString
    throw _QLPreviewingHostError.unsupported
  }

  func providePreview(for request: QLFilePreviewRequest) async throws
    -> QLPreviewReply
  {
    _ = request
    throw _QLPreviewingHostError.unsupported
  }
}

enum _QLPreviewingHostError: Error {
  case unsupported
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
  private let metadataLabel = UILabel()

  open class func canPreview(_ item: any QLPreviewItem) -> Bool {
    guard let url = item.previewItemURL, url.isFileURL else { return false }
    return FileManager.default.fileExists(atPath: url.path)
  }

  open override func viewDidLoad() {
    super.viewDidLoad()
    imageView.contentMode = .scaleAspectFit
    metadataLabel.numberOfLines = 0
    metadataLabel.textAlignment = .center
    view.addSubview(imageView)
    view.addSubview(metadataLabel)
    reloadData()
  }

  open override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    imageView.frame = view.bounds
    metadataLabel.frame = view.bounds.insetBy(dx: 24, dy: 24)
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

  private func _renderCurrentItem() {
    guard isViewLoaded, let item = currentPreviewItem else { return }
    let url = item.previewItemURL
    if let path = url?.path, let image = UIImage(contentsOfFile: path) {
      imageView.image = image
      imageView.isHidden = false
      metadataLabel.isHidden = true
    } else {
      imageView.image = nil
      imageView.isHidden = true
      metadataLabel.isHidden = false
      metadataLabel.text = item.previewItemTitle
        ?? url?.lastPathComponent
        ?? "Preview unavailable"
    }
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
    return FileManager.default.fileExists(atPath: url.path)
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

