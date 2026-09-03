#if canImport(CoreGraphics)
import CoreGraphics
#endif
#if canImport(Metal)
import Metal
#endif
#if canImport(ModelIO)
import ModelIO
#endif
#if canImport(QuartzCore)
import QuartzCore
#endif
#if canImport(UIKit)
import UIKit
#endif
import Foundation
import MetalKit

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation plus lookalikes is not integrated Metal/UIKit
// success.
//
// Expected EC2 steps (no local Docker):
// 1. Build guest Foundation, CoreGraphics, Metal, ModelIO, QuartzCore, UIKit.
// 2. Build MetalKit with those modules on -I / -L (lookalikes replaced).
// 3. Link this file as a client that imports MetalKit and its dependencies.
// 4. Run with LD_LIBRARY_PATH covering the dylibs.
// 5. Confirm METALKIT_DEPENDENCY_IDENTITY_OK and that libMetalKit.dylib loaded.

#if canImport(Metal) && canImport(UIKit) && canImport(CoreGraphics)
func metalKitDependencyIdentityMain() {
    let viewIsUIView = MTKView.self is UIView.Type
    precondition(viewIsUIView, "MTKView must inherit UIKit.UIView in the integrated build")
    print("METALKIT_DEPENDENCY_IDENTITY_OK")
}
#else
func metalKitDependencyIdentityMain() {
    fputs(
        "METALKIT_DEPENDENCY_IDENTITY_SKIP isolated host has no Metal/UIKit/CoreGraphics modules\n",
        stderr
    )
}
#endif
