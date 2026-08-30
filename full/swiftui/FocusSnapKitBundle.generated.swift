// Project-owned portable form of Apple SwiftPM 6.2.1's generated primary
// resource lookup for pinned SnapKit 5.7.0 Package.swift. This is build support,
// not SnapKit source. The machine-specific build-directory fallback is omitted;
// the exact SnapKit_SnapKit.bundle must be main-relative.
import Foundation

extension Foundation.Bundle {
    static let module: Bundle = {
        let mainPath = Bundle.main.bundleURL.appendingPathComponent(
            "SnapKit_SnapKit.bundle",
            isDirectory: true
        ).path
        guard let bundle = Bundle(path: mainPath) else {
            Swift.fatalError(
                "could not load main-relative SnapKit_SnapKit.bundle: "
                    + mainPath
            )
        }
        return bundle
    }()
}

public enum FocusSnapKitResourceProof {
    public static var bundlePath: String { Bundle.module.bundlePath }
    public static var resourcePath: String? { Bundle.module.resourcePath }
    public static var privacyManifestPath: String? {
        Bundle.module.url(
            forResource: "PrivacyInfo",
            withExtension: "xcprivacy"
        )?.path
    }
    public static var missingResourcePath: String? {
        Bundle.module.url(
            forResource: "definitely-missing-privacy",
            withExtension: "xcprivacy"
        )?.path
    }
}
