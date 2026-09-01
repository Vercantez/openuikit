import Foundation
import UIKit
@_spi(OpenUIKitHost) import QuickLook

@MainActor
private final class GuestDataSource: QLPreviewControllerDataSource {
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

@main
private struct QuickLookGuestRuntime {
  @MainActor
  static func main() {
    let first = URL(fileURLWithPath: "/tmp/first.png")
    let second = URL(fileURLWithPath: "/tmp/second.pdf")
    let source = GuestDataSource(urls: [first, second])
    let controller = QLPreviewController()
    controller.dataSource = source
    controller.reloadData()
    precondition(controller.currentPreviewItemIndex == 0)
    precondition(controller.currentPreviewItem?.previewItemURL == first)
    controller.currentPreviewItemIndex = 1
    precondition(controller.currentPreviewItem?.previewItemURL == second)
    controller.currentPreviewItemIndex = 99
    precondition(controller.currentPreviewItemIndex == 1)
    precondition(!QLPreviewController.canPreview(source.items[0]))

    QuickLookPortable._reset()
    precondition(
      QuickLookPortable.defaultCapability == .localImageAndMetadata
    )
    var events: [QuickLookPortable.Event] = []
    var selected: URL? = first
    QuickLookPortable._installEventHandler { events.append($0) }
    precondition(
      QuickLookPortable._requestPresentation(
        urls: [first, second], selectedURL: second
      ) { selected = $0 }
    )
    precondition(events == [.present(urls: [first, second], selectedIndex: 1)])
    QuickLookPortable._hostDidSelect(first)
    precondition(selected == first)
    QuickLookPortable._hostDidDismiss()
    precondition(selected == nil)
    precondition(events.last == .dismiss)
    QuickLookPortable._reset()

    print(
      "QUICKLOOK_GUEST_MACHO_OK controller=items,indexed "
        + "overlay=host-driven selection=synchronized unsupported=fail-closed"
    )
  }
}
