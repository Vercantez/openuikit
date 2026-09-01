import QuickLook
import SwiftUI

@MainActor
private final class NativeDataSource: NSObject,
  QLPreviewControllerDataSource, QLPreviewControllerDelegate
{
  let item = ARQuickLookPreviewItem(
    fileAt: URL(fileURLWithPath: "/tmp/native.usdz")
  )

  func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
    _ = controller
    return 1
  }

  func previewController(
    _ controller: QLPreviewController,
    previewItemAt index: Int
  ) -> any QLPreviewItem {
    _ = controller
    _ = index
    return item
  }
}

@MainActor
private func nativeQuickLookSurface() {
  let source = NativeDataSource()
  let controller = QLPreviewController()
  controller.dataSource = source
  controller.delegate = source
  controller.reloadData()
  controller.refreshCurrentPreviewItem()
  _ = QLPreviewController.canPreview(source.item)

  var selected: URL?
  let binding = Binding<URL?>(get: { selected }, set: { selected = $0 })
  _ = Text("preview").quickLookPreview(binding)
  _ = Text("previews").quickLookPreview(
    binding,
    in: [URL(fileURLWithPath: "/tmp/native.usdz")]
  )
}
