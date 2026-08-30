// Project-owned compatibility build support, not Mozilla Focus application
// source. Pinned Focus Package.swift declares no Onboarding resources, so
// Apple SwiftPM 6.2.1 emits no accessor and defines
// SWIFT_MODULE_RESOURCE_BUNDLE_UNAVAILABLE even though unchanged sources spell
// Bundle.module. The proof explicitly stages its reviewed normalized
// Focus_Onboarding.bundle beside the guest, with no build-machine fallback.
@_exported import Foundation
import SwiftUI

extension Bundle {
    static let module: Bundle = {
        let url = Bundle.main.bundleURL.appendingPathComponent(
            "Focus_Onboarding.bundle",
            isDirectory: true
        )
        guard let bundle = Bundle(url: url) else {
            Swift.fatalError("missing normalized Focus_Onboarding.bundle: \(url.path)")
        }
        return bundle
    }()
}

/// Project-owned runtime visibility into the compatibility-support boundary.
/// Evaluating `actionButton` executes the exact unchanged Color+AppColors
/// declaration against `Bundle.module`; the harness asserts both roots first.
public enum FocusOnboardingResourceProof {
    public static var bundlePath: String { Bundle.module.bundlePath }
    public static var resourcePath: String? { Bundle.module.resourcePath }

    @MainActor
    public static func exerciseUnchangedAssets() -> Bool {
        _ = Color.actionButton
        _ = Image.logo
        return UIImage(
            named: "icon_logo",
            in: Bundle.module,
            compatibleWith: nil
        ) != nil
    }
}
