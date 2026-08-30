// Project-owned compatibility build support, deliberately NOT application
// source. Pinned Focus Package.swift declares no Widget resources, so Apple
// SwiftPM 6.2.1 emits no accessor and defines
// SWIFT_MODULE_RESOURCE_BUNDLE_UNAVAILABLE even though unchanged Assets.swift
// spells Bundle.module. The proof explicitly stages its reviewed normalized
// Focus_Widget.bundle beside the guest, with no build-machine fallback.

import SwiftUI

extension Bundle {
    static let module: Bundle = {
        let url = Bundle.main.bundleURL.appendingPathComponent(
            "Focus_Widget.bundle",
            isDirectory: true
        )
        guard let bundle = Bundle(url: url) else {
            Swift.fatalError("missing normalized Focus_Widget.bundle: \(url.path)")
        }
        return bundle
    }()
}

/// Project-owned runtime visibility into the compatibility-support boundary.
/// Evaluating these values executes the exact unchanged Assets.swift
/// declarations; the harness separately proves their rendered pixels.
public enum FocusWidgetResourceProof {
    public static var bundlePath: String { Bundle.module.bundlePath }
    public static var resourcePath: String? { Bundle.module.resourcePath }

    @MainActor
    public static func exerciseUnchangedAssets() {
        _ = Gradient.quickAccessWidget
        _ = Image.logo
    }
}
