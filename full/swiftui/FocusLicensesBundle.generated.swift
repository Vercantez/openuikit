// Project-owned portable form of Apple SwiftPM 6.2.1's generated primary
// resource lookup for pinned Focus Package.swift. This is not Mozilla Focus
// application source. The machine-specific build-directory fallback is
// deliberately omitted; the exact Focus_Licenses.bundle must be main-relative.
import Foundation

extension Foundation.Bundle {
    static let module: Bundle = {
        let mainPath = Bundle.main.bundleURL.appendingPathComponent(
            "Focus_Licenses.bundle",
            isDirectory: true
        ).path
        guard let bundle = Bundle(path: mainPath) else {
            Swift.fatalError(
                "could not load main-relative Focus_Licenses.bundle: "
                    + mainPath
            )
        }
        return bundle
    }()
}

/// Project-owned proof surface for the exact generated primary lookup.
public enum FocusLicensesResourceProof {
    public static var bundlePath: String { Bundle.module.bundlePath }
    public static var resourcePath: String? { Bundle.module.resourcePath }
    public static var focusLicensePath: String? {
        Bundle.module.url(
            forResource: "focus-ios",
            withExtension: "plist"
        )?.path
    }
    public static var libraryLicensesPath: String? {
        Bundle.module.url(
            forResource: "license-list",
            withExtension: "plist"
        )?.path
    }
    public static var missingResourcePath: String? {
        Bundle.module.url(
            forResource: "definitely-missing-license",
            withExtension: "plist"
        )?.path
    }
}
