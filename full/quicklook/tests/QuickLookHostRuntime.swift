import Foundation
@_spi(OpenUIKitHost) import QuickLook

@main
private struct QuickLookHostRuntime {
  @MainActor
  static func main() {
    QuickLookPortable._reset()
    precondition(
      QuickLookPortable.defaultCapability == .unavailable
    )
    precondition(!QuickLookPortable.supportsProprietaryPreviewGenerators)
    precondition(!QuickLookPortable.supportsEditing)

    let url = URL(fileURLWithPath: "/tmp/portable-preview.png")
    let arItem = ARQuickLookPreviewItem(fileAt: url)
    precondition(arItem.previewItemURL == url)
    precondition(arItem.allowsContentScaling)
    arItem.allowsContentScaling = false
    arItem.canonicalWebPageURL = URL(string: "https://example.com/model")
    precondition(!arItem.allowsContentScaling)

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

    let replacement = URL(fileURLWithPath: "/tmp/replacement.pdf")
    QuickLookPortable._hostDidSelect(replacement)
    precondition(selected == replacement)
    QuickLookPortable._hostDidDismiss()
    precondition(selected == nil)
    precondition(events.last == .dismiss)

    let remote = URL(string: "https://example.com/file.pdf")!
    let rejected = QuickLookPortable._requestPresentation(
      urls: [remote], selectedURL: remote
    ) { _ in preconditionFailure("remote selection mutated") }
    precondition(!rejected)
    QuickLookPortable._reset()
    print(
      "QUICKLOOK_HOST_OK item=metadata presentation=host-driven "
        + "selection=synchronized unsupported=fail-closed"
    )
  }
}
