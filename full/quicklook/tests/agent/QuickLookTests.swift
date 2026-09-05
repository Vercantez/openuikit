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
    precondition(controller._previewTitle == nil)
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
  let attachment = QLPreviewReplyAttachment(
    data: Data([0x41, 0x42]),
    contentType: .html
  )
  reply.attachments = ["body": attachment]
  precondition(reply.title == "Reply")
  precondition(reply.stringEncoding == .utf8)
  precondition(reply.attachments["body"]?.data == Data([0x41, 0x42]))
  precondition(reply.attachments["body"]?.contentType.identifier == "public.html")
  precondition(reply._fileURL == url)
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
  let attachment = QLPreviewReplyAttachment(data: Data([0x00]), contentType: .png)
  precondition(attachment.data == Data([0x00]))
  precondition(attachment.contentType.identifier == "public.png")
  precondition(attachment.contentType.conforms(to: .image))
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

private func qlMakeTempFile(extension ext: String, contents: Data = Data("x".utf8)) -> URL {
  let url = FileManager.default.temporaryDirectory
    .appendingPathComponent("quicklook-\(UUID().uuidString).\(ext)")
  precondition(FileManager.default.createFile(atPath: url.path, contents: contents))
  return url
}

func testQLPreviewControllerCanPreviewByType() {
  qlMain {
    let png = qlMakeTempFile(extension: "png")
    let pdf = qlMakeTempFile(extension: "pdf")
    let txt = qlMakeTempFile(extension: "txt")
    let csv = qlMakeTempFile(extension: "csv")
    let zip = qlMakeTempFile(extension: "zip")
    let usdz = qlMakeTempFile(extension: "usdz")
    let docx = qlMakeTempFile(extension: "docx")
    let bin = qlMakeTempFile(extension: "exe")
    defer {
      for url in [png, pdf, txt, csv, zip, usdz, docx, bin] {
        try? FileManager.default.removeItem(at: url)
      }
    }
    precondition(QLPreviewController.canPreview(png as NSURL))
    precondition(QLPreviewController.canPreview(pdf as NSURL))
    precondition(QLPreviewController.canPreview(txt as NSURL))
    precondition(QLPreviewController.canPreview(csv as NSURL))
    precondition(QLPreviewController.canPreview(zip as NSURL))
    precondition(QLPreviewController.canPreview(usdz as NSURL))
    precondition(QLPreviewController.canPreview(docx as NSURL))
    precondition(!QLPreviewController.canPreview(bin as NSURL))

    let missing = URL(fileURLWithPath: "/tmp/quicklook-missing-\(UUID().uuidString).png")
    precondition(!QLPreviewController.canPreview(missing as NSURL))
    let remote = URL(string: "https://example.com/file.pdf")!
    precondition(!QLPreviewController.canPreview(remote as NSURL))

    let untitled = URL(fileURLWithPath: "/tmp/no-extension-\(UUID().uuidString)")
    precondition(FileManager.default.createFile(atPath: untitled.path, contents: Data("x".utf8)))
    defer { try? FileManager.default.removeItem(at: untitled) }
    precondition(!QLPreviewController.canPreview(untitled as NSURL))
  }
}

func testQLPreviewControllerChromeTitleAndKind() {
  qlMain {
    final class TitledItem: NSObject, QLPreviewItem {
      let previewItemURL: URL?
      let previewItemTitle: String?
      init(url: URL, title: String?) {
        previewItemURL = url
        previewItemTitle = title
        super.init()
      }
    }
    final class TitledSource: QLPreviewControllerDataSource {
      let item: TitledItem
      init(item: TitledItem) { self.item = item }
      func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        _ = controller
        return 1
      }
      func previewController(
        _ controller: QLPreviewController,
        previewItemAt index: Int
      ) -> any QLPreviewItem {
        _ = (controller, index)
        return item
      }
    }

    let png = qlMakeTempFile(extension: "png")
    let pdf = qlMakeTempFile(extension: "pdf")
    let txt = qlMakeTempFile(extension: "txt")
    defer {
      for url in [png, pdf, txt] {
        try? FileManager.default.removeItem(at: url)
      }
    }

    let controller = QLPreviewController()
    let source = TitledSource(item: TitledItem(url: png, title: "Photo"))
    controller.dataSource = source
    controller.reloadData()
    precondition(controller._previewTitle == "Photo")
    precondition(controller._previewKind == "image")

    let pdfSource = TitledSource(item: TitledItem(url: pdf, title: nil))
    controller.dataSource = pdfSource
    controller.reloadData()
    precondition(controller._previewTitle == pdf.lastPathComponent)
    precondition(controller._previewKind == "pdf")

    let txtSource = TitledSource(item: TitledItem(url: txt, title: nil))
    controller.dataSource = txtSource
    controller.reloadData()
    precondition(controller._previewKind == "text")
    controller.refreshCurrentPreviewItem()
    precondition(controller.currentPreviewItem?.previewItemURL == txt)
  }
}

func testQLPreviewControllerDelegateTransitions() {
  qlMain {
    let url = URL(fileURLWithPath: "/tmp/transition.png")
    let source = RecordingDataSource(urls: [url])
    let controller = QLPreviewController()
    controller.dataSource = source
    controller.reloadData()
    final class DefaultsOnly: NSObject, QLPreviewControllerDelegate {}
    let defaults = DefaultsOnly()
    var sourceView: UIView? = UIView()
    let frame = defaults.previewController(
      controller,
      frameFor: source.items[0],
      inSourceView: &sourceView
    )
    precondition(frame == .zero)
    var contentRect = CGRect(x: 1, y: 2, width: 3, height: 4)
    let image = defaults.previewController(
      controller,
      transitionImageFor: source.items[0],
      contentRect: &contentRect
    )
    precondition(image == nil)
    precondition(contentRect == .zero)
    precondition(
      defaults.previewController(controller, transitionViewFor: source.items[0]) == nil
    )
  }
}

func testQLPreviewReplyConvenienceInitializers() {
  var drew = false
  let drawing = QLPreviewReply(
    contextSize: CGSize(width: 40, height: 60),
    isBitmap: true
  ) { _, _ in
    drew = true
  }
  precondition(!drew)
  precondition(drawing._contextSize == CGSize(width: 40, height: 60))
  precondition(drawing._isBitmap == true)
  precondition(drawing._fileURL == nil)

  var createdData = false
  let typed = QLPreviewReply(
    dataOfContentType: .png,
    contentSize: CGSize(width: 8, height: 8)
  ) { _ in
    createdData = true
    return Data([0x89])
  }
  precondition(!createdData)
  precondition(typed._contentType?.identifier == "public.png")
  precondition(typed._contentSize == CGSize(width: 8, height: 8))

  var createdPDF = false
  let pdf = QLPreviewReply(forPDFWithPageSize: CGSize(width: 612, height: 792)) { _ in
    createdPDF = true
    return PDFDocument()
  }
  precondition(!createdPDF)
  precondition(pdf._pdfPageSize == CGSize(width: 612, height: 792))
}

func testQLPreviewingControllerFailClosed() {
  final class HostPreviewing: NSObject, QLPreviewingController, @unchecked Sendable {}
  final class Box: @unchecked Sendable {
    var fileError: NSError?
    var searchError: NSError?
    var provideError: NSError?
  }
  let box = Box()
  let sem = DispatchSemaphore(value: 0)
  Task {
    let previewing = HostPreviewing()
    let url = URL(fileURLWithPath: "/tmp/previewing.bin")
    do {
      try await previewing.preparePreviewOfFile(at: url)
      preconditionFailure("preparePreviewOfFile must fail closed")
    } catch {
      box.fileError = error as NSError
    }
    do {
      try await previewing.preparePreviewOfSearchableItem(
        identifier: "id",
        queryString: nil
      )
      preconditionFailure("preparePreviewOfSearchableItem must fail closed")
    } catch {
      box.searchError = error as NSError
    }
    do {
      _ = try await previewing.providePreview(
        for: QLFilePreviewRequest(fileURL: url)
      )
      preconditionFailure("providePreview must fail closed")
    } catch {
      box.provideError = error as NSError
    }
    sem.signal()
  }
  precondition(sem.wait(timeout: .now() + 5) == .success)
  for error in [box.fileError, box.searchError, box.provideError] {
    precondition(error?.domain == NSCocoaErrorDomain)
    precondition(error?.code == CocoaError.Code.featureUnsupported.rawValue)
  }
}

