// Project-owned Bundle.module for Darwin Onboarding (same shape as
// Widget/OpenUIKitBundleModule.swift). Upstream Color+AppColors uses
// bundle: .module.

import Foundation

extension Bundle {
    static var module: Bundle {
        let url = Bundle.main.bundleURL.appendingPathComponent(
            "Focus_Onboarding.bundle", isDirectory: true)
        return Bundle(url: url) ?? .main
    }
}
