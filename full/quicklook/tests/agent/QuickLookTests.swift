@_spi(OpenUIKitHost) import QuickLook
import Foundation

private func qlMain(_ body: @escaping @MainActor () -> Void) {
  if Thread.isMainThread {
    MainActor.assumeIsolated(body)
  } else {
    DispatchQueue.main.sync {
      MainActor.assumeIsolated(body)
    }
  }
}

@MainActor
private final class RecordingDataSource: QLPreviewControllerDataSource {
  let items: [NSURL]

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

@MainActor
private final class RecordingDelegate: NSObject, QLPreviewControllerDelegate {
  var willDismissCount = 0
  var didDismissCount = 0
  var lastEditingMode: QLPreviewItemEditingMode?
  var lastShouldOpen: Bool?
  var updatedItem: (any QLPreviewItem)?
  var savedURL: URL?

  func previewControllerWillDismiss(_ controller: QLPreviewController) {
    _ = controller
    willDismissCount += 1
  }

  func previewControllerDidDismiss(_ controller: QLPreviewController) {
    _ = controller
    didDismissCount += 1
  }

  func previewController(
    _ controller: QLPreviewController,
    shouldOpen url: URL,
    for item: any QLPreviewItem
  ) -> Bool {
    _ = controller
    _ = item
    lastShouldOpen = url.isFileURL
    return url.isFileURL
  }

  func previewController(
    _ controller: QLPreviewController,
    editingModeFor previewItem: any QLPreviewItem
  ) -> QLPreviewItemEditingMode {
    _ = controller
    _ = previewItem
    lastEditingMode = .disabled
    return .disabled
  }

  func previewController(
    _ controller: QLPreviewController,
    didUpdateContentsOf previewItem: any QLPreviewItem
  ) {
    _ = controller
    updatedItem = previewItem
  }

  func previewController(
    _ controller: QLPreviewController,
    didSaveEditedCopyOf previewItem: any QLPreviewItem,
    at modifiedContentsURL: URL
  ) {
    _ = controller
    _ = previewItem
    savedURL = modifiedContentsURL
  }
}

func testPreviewItemEditingMode() {
  precondition(QLPreviewItemEditingMode.disabled.rawValue == 0)
  precondition(QLPreviewItemEditingMode.updateContents.rawValue == 1)
  precondition(QLPreviewItemEditingMode.createCopy.rawValue == 2)
  precondition(QLPreviewItemEditingMode(rawValue: 0) == .disabled)
  precondition(QLPreviewItemEditingMode(rawValue: 1) == .updateContents)
  precondition(QLPreviewItemEditingMode(rawValue: 2) == .createCopy)
  precondition(QLPreviewItemEditingMode(rawValue: 99) == nil)
  precondition(QLPreviewItemEditingMode.disabled != .createCopy)
  precondition(QLPreviewItemEditingMode.disabled == QLPreviewItemEditingMode.disabled)
  var hasher = Hasher()
  QLPreviewItemEditingMode.disabled.hash(into: &hasher)
  precondition(QLPreviewItemEditingMode.disabled.hashValue == QLPreviewItemEditingMode.disabled.hashValue)
}

func testARQuickLookPreviewItem() {
  let url = URL(fileURLWithPath: "/tmp/model.usdz")
  let designated = ARQuickLookPreviewItem(fileAt: url)
  precondition(designated.previewItemURL == url)
  precondition(designated.previewItemTitle == nil)
  precondition(designated.allowsContentScaling)
  designated.allowsContentScaling = false
  designated.canonicalWebPageURL = URL(string: "https://example.com/model")
  precondition(!designated.allowsContentScaling)
  precondition(designated.canonicalWebPageURL?.host == "example.com")

  let synthesized = ARQuickLookPreviewItem(fileAtURL: url)
  precondition(synthesized.previewItemURL == url)
}

func testQLPreviewItemNSURL() {
  let url = URL(fileURLWithPath: "/tmp/preview.png")
  let item = url as NSURL
  let preview: any QLPreviewItem = item
  precondition(preview.previewItemURL == url)
  precondition(preview.previewItemTitle == nil)
}

func testQLPreviewControllerItems() {
  qlMain {
    let first = URL(fileURLWithPath: "/tmp/first.png")
    let second = URL(fileURLWithPath: "/tmp/second.pdf")
    let source = RecordingDataSource(urls: [first, second])
    let controller = QLPreviewController()
    controller.dataSource = source
    controller.reloadData()
    precondition(controller.currentPreviewItemIndex == 0)
    precondition(controller.currentPreviewItem?.previewItemURL == first)
    controller.currentPreviewItemIndex = 1
    precondition(controller.currentPreviewItem?.previewItemURL == second)
    controller.refreshCurrentPreviewItem()
    controller.currentPreviewItemIndex = 99
    precondition(controller.currentPreviewItemIndex == 1)
    controller.dataSource = nil
    controller.reloadData()
    precondition(controller.currentPreviewItem == nil)

    let missing = URL(fileURLWithPath: "/tmp/quicklook-missing-\(UUID().uuidString).png")
    precondition(!QLPreviewController.canPreview(missing as NSURL))

    let existing = FileManager.default.temporaryDirectory
      .appendingPathComponent("quicklook-can-preview-\(UUID().uuidString).txt")
    precondition(
      FileManager.default.createFile(atPath: existing.path, contents: Data("ok".utf8))
    )
    defer { try? FileManager.default.removeItem(at: existing) }
    precondition(QLPreviewController.canPreview(existing as NSURL))
  }
}

func testQLPreviewControllerDelegate() {
  qlMain {
    let url = URL(fileURLWithPath: "/tmp/delegate.png")
    let source = RecordingDataSource(urls: [url])
    let delegate = RecordingDelegate()
    let controller = QLPreviewController()
    controller.dataSource = source
    controller.delegate = delegate
    controller.reloadData()

    precondition(delegate.previewController(controller, shouldOpen: url, for: source.items[0]))
    precondition(delegate.lastShouldOpen == true)
    precondition(
      delegate.previewController(controller, editingModeFor: source.items[0]) == .disabled
    )
    delegate.previewController(controller, didUpdateContentsOf: source.items[0])
    precondition(delegate.updatedItem?.previewItemURL == url)
    let copy = URL(fileURLWithPath: "/tmp/edited-copy.png")
    delegate.previewController(
      controller,
      didSaveEditedCopyOf: source.items[0],
      at: copy
    )
    precondition(delegate.savedURL == copy)
    delegate.previewControllerWillDismiss(controller)
    delegate.previewControllerDidDismiss(controller)
    precondition(delegate.willDismissCount == 1)
    precondition(delegate.didDismissCount == 1)

    final class DefaultsOnly: NSObject, QLPreviewControllerDelegate {}
    let defaults = DefaultsOnly()
    precondition(defaults.previewController(controller, shouldOpen: url, for: source.items[0]))
    precondition(
      defaults.previewController(controller, editingModeFor: source.items[0]) == .disabled
    )
    defaults.previewControllerWillDismiss(controller)
    defaults.previewControllerDidDismiss(controller)
    defaults.previewController(controller, didUpdateContentsOf: source.items[0])
    defaults.previewController(
      controller,
      didSaveEditedCopyOf: source.items[0],
      at: copy
    )
  }
}

func testQLPreviewReply() {
  let url = URL(fileURLWithPath: "/tmp/reply.html")
  let reply = QLPreviewReply(fileURL: url)
  reply.title = "Reply"
  reply.stringEncoding = .utf8
  let attachment = QLPreviewReplyAttachment(data: Data([0x41, 0x42]))
  reply.attachments = ["body": attachment]
  precondition(reply.title == "Reply")
  precondition(reply.stringEncoding == .utf8)
  precondition(reply.attachments["body"]?.data == Data([0x41, 0x42]))
}

func testQLFilePreviewRequest() {
  let url = URL(fileURLWithPath: "/tmp/request.pdf")
  let request = QLFilePreviewRequest(fileURL: url)
  precondition(request.fileURL == url)
}

func testQLPreviewSceneActivationConfiguration() {
  let first = URL(fileURLWithPath: "/tmp/scene-a.png")
  let second = URL(fileURLWithPath: "/tmp/scene-b.png")
  let options = QLPreviewSceneActivationConfiguration.Options()
  options.initialPreviewIndex = 1
  let configuration = QLPreviewSceneActivationConfiguration(
    itemsAt: [first, second],
    options: options
  )
  precondition(configuration._itemURLs == [first, second])
  precondition(configuration._sceneOptions?.initialPreviewIndex == 1)

  let synthesized = QLPreviewSceneActivationConfiguration(
    itemsAtURLs: [first],
    options: nil
  )
  precondition(synthesized._itemURLs == [first])
  precondition(synthesized._sceneOptions == nil)
}

func testQLPreviewProviderAndAttachment() {
  let provider = QLPreviewProvider()
  _ = provider
  let attachment = QLPreviewReplyAttachment(data: Data([0x00]))
  precondition(attachment.data == Data([0x00]))
}

func testQuickLookPortableHostFailClosed() {
  qlMain {
    QuickLookPortable._reset()
    precondition(QuickLookPortable.defaultCapability == .unavailable)
    precondition(!QuickLookPortable.supportsProprietaryPreviewGenerators)
    precondition(!QuickLookPortable.supportsEditing)

    let url = URL(fileURLWithPath: "/tmp/portable-preview.png")
    var selected: URL? = url
    let unavailable = QuickLookPortable._requestPresentation(
      urls: [url], selectedURL: url
    ) { selected = $0 }
    precondition(!unavailable)
    precondition(selected == url)

    var events: [QuickLookPortable.Event] = []
    QuickLookPortable._installEventHandler { events.append($0) }
    let accepted = QuickLookPortable._requestPresentation(
      urls: [url], selectedURL: url
    ) { selected = $0 }
    precondition(accepted)
    precondition(events == [.present(urls: [url], selectedIndex: 0)])
    QuickLookPortable._hostDidDismiss()
    QuickLookPortable._reset()
  }
}
