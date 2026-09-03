#if canImport(simd)
import simd
#endif
import Foundation
import SceneKit

// Future EC2 identity probe. Isolated host compile does not import CoreGraphics,
// QuartzCore, or Metal; those modules are absent here. This file is not part of
// tests/acceptance/test_host.sh.
enum SceneKitDependencyIdentity {
    static let marker = "SCENEKIT_DEPENDENCY_IDENTITY_OK"

    static func foundationIdentity() -> Bool {
        SCNErrorDomain == "SCNErrorDomain"
    }

    static func simdIdentityAvailable() -> Bool {
        #if canImport(simd)
        true
        #else
        false
        #endif
    }
}
