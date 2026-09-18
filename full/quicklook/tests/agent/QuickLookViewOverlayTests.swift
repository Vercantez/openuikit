import Foundation
import QuickLook

#if canImport(SwiftUI)
import SwiftUI
#endif

// `quickLookPreview` overlay batches: each overload is invoked on EmptyView.
// Construction is lazy on every host — the portable modifier only synchronizes
// on appear/selection change, and the isolated host gate (no SwiftUI) is an
// identity no-op — so building the view performs no synchronous presentation
// and never mutates the selection binding.

private final class QLOverlaySelectionBox {
  var value: URL?

  init(_ value: URL?) {
    self.value = value
  }
}

private func qlOverlayBinding(_ box: QLOverlaySelectionBox) -> Binding<URL?> {
  Binding(get: { box.value }, set: { box.value = $0 })
}

func testViewOverlayBatch01() {
  let url = URL(fileURLWithPath: "/tmp/quicklook-overlay-preview.png")
  let box = QLOverlaySelectionBox(url)
  _ = EmptyView().quickLookPreview(qlOverlayBinding(box))
  precondition(box.value == url)

  let empty = QLOverlaySelectionBox(nil)
  _ = EmptyView().quickLookPreview(qlOverlayBinding(empty))
  precondition(empty.value == nil)
}

func testViewOverlayBatch02() {
  let first = URL(fileURLWithPath: "/tmp/quicklook-overlay-first.png")
  let second = URL(fileURLWithPath: "/tmp/quicklook-overlay-second.pdf")
  let box = QLOverlaySelectionBox(first)
  _ = EmptyView().quickLookPreview(qlOverlayBinding(box), in: [first, second])
  precondition(box.value == first)

  let strayURL = URL(fileURLWithPath: "/tmp/quicklook-overlay-stray.png")
  let stray = QLOverlaySelectionBox(strayURL)
  _ = EmptyView().quickLookPreview(qlOverlayBinding(stray), in: [first, second])
  precondition(stray.value == strayURL)
}
