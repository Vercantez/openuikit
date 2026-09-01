#if canImport(Foundation)
import Foundation
#endif
#if canImport(CoreGraphics)
import CoreGraphics
#endif
#if canImport(QuartzCore)
import QuartzCore
#endif
#if canImport(Metal)
import Metal
#endif
#if canImport(simd)
import simd
#endif
import SceneKit

#if canImport(Foundation)
_ = NSStringFromClass(SCNNode.self)
_ = SCNErrorDomain as String
#endif

#if canImport(CoreGraphics)
let viewport = CGSize(width: 16, height: 9)
_ = SCNCamera().projectionTransform(withViewportSize: viewport)
_ = CGFloat(1)
_ = CGPoint.zero
#endif

#if canImport(QuartzCore)
let quartzCorePresent = true
_ = quartzCorePresent
#endif

#if canImport(Metal)
let metalPresent = true
_ = metalPresent
#endif

#if canImport(simd)
let quat: simd_quatf = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1)
let simdNode = SCNNode()
simdNode.simdOrientation = quat
if abs(simdNode.simdOrientation.vector.w - 1) > 0.001 {
    fatalError("simd_quatf identity did not round-trip through SCNNode")
}
#endif

print("SCENEKIT_AGENT_DEPENDENCY_IDENTITY_OK")
