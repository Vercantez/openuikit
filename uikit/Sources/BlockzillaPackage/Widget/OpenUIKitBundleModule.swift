// Project-owned Bundle.module for the Widget target. Upstream Widget
// Assets.swift uses Color/Image(…, bundle: .module). SwiftPM generates
// this only when resources are declared; this file is the same
// compatibility shape as full/swiftui/FocusWidgetBundle.generated.swift,
// looking up a main-relative bundle and falling back to Bundle.main
// (no trap on the launch path).

import Foundation

extension Bundle {
    static var module: Bundle {
        let url = Bundle.main.bundleURL.appendingPathComponent(
            "Focus_Widget.bundle", isDirectory: true)
        return Bundle(url: url) ?? .main
    }
}
