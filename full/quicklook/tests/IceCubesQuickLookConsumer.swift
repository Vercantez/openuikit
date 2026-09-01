import Foundation
import QuickLook
import SwiftUI

@MainActor
private struct IceCubesQuickLookToolbarProbe: View {
  @Binding var localPath: URL?

  var body: some View {
    Text("preview")
      .quickLookPreview($localPath)
  }
}
