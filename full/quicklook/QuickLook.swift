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

#if canImport(UIKit)
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
