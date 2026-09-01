@_exported import QuickLook
@_spi(OpenUIKitHost) import QuickLook
import Foundation
import SwiftUI

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
  func quickLookPreview(_ item: Binding<URL?>) -> some View {
    modifier(
      _PortableQuickLookModifier(
        selection: item,
        items: item.wrappedValue.map { [$0] } ?? []
      )
    )
  }

  func quickLookPreview<Items>(
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
