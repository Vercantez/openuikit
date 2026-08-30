// Project-owned compatibility build support, not Mozilla Focus application
// source. Pinned Focus Package.swift declares no DesignSystem resources, so
// Apple SwiftPM 6.2.1 emits no Bundle.module accessor and defines
// SWIFT_MODULE_RESOURCE_BUNDLE_UNAVAILABLE for this target. The bounded proof
// compiles and links the unchanged sources but makes accidental resource use
// fail instead of inventing a bundle name or silently using app data.
import Foundation

extension Foundation.Bundle {
    static let module: Bundle = {
        Swift.fatalError(
            "pinned Focus Package.swift declares no DesignSystem resources; "
                + "Bundle.module is compile/link-only compatibility support"
        )
    }()
}
