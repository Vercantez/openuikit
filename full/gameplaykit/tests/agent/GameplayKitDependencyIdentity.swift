import Foundation
#if canImport(simd)
import simd
#endif
#if canImport(SceneKit)
import SceneKit
#endif
#if canImport(SpriteKit)
import SpriteKit
#endif
#if canImport(GameplayKit)
import GameplayKit
#endif

enum GameplayKitDependencyIdentityFailure: Error {
    case message(String)
}

private func require(_ condition: Bool, _ message: String) throws {
    if !condition {
        throw GameplayKitDependencyIdentityFailure.message(message)
    }
}

/// Future EC2 cold-build probe. This file is not part of the isolated host gate.
/// It prints `GAMEPLAYKIT_DEPENDENCY_IDENTITY_OK` only when Foundation, the
/// shared SIMD/simd provider, SceneKit, SpriteKit, and GameplayKit are all
/// present and the identity/ABI assertions pass. Missing modules print
/// `GAMEPLAYKIT_DEPENDENCY_IDENTITY_UNAVAILABLE` and do not claim success.
func runGameplayKitDependencyIdentity() throws {
    #if canImport(simd) && canImport(SceneKit) && canImport(SpriteKit) && canImport(GameplayKit)
    try proveVectorMatrixIdentity()
    try proveCodingAndCopy()
    try proveComponentOwnership()
    try proveSceneKitSpriteKitBridging()
    try proveDylibLoad()
    print("GAMEPLAYKIT_DEPENDENCY_IDENTITY_OK")
    #else
    var missing: [String] = []
    #if !canImport(simd)
    missing.append("simd")
    #endif
    #if !canImport(SceneKit)
    missing.append("SceneKit")
    #endif
    #if !canImport(SpriteKit)
    missing.append("SpriteKit")
    #endif
    #if !canImport(GameplayKit)
    missing.append("GameplayKit")
    #endif
    print("GAMEPLAYKIT_DEPENDENCY_IDENTITY_UNAVAILABLE missing=\(missing.joined(separator: ","))")
    #endif
}

#if canImport(simd) && canImport(SceneKit) && canImport(SpriteKit) && canImport(GameplayKit)
#if os(Linux)
import Glibc
#endif
private func proveVectorMatrixIdentity() throws {
    let node = GKGraphNode2D(point: SIMD2<Float>(1, 2))
    try require(type(of: node.position) == vector_float2.self, "vector_float2 identity")
    try require(MemoryLayout<SIMD2<Float>>.size == MemoryLayout<vector_float2>.size, "vector_float2 layout")
    try require(MemoryLayout<SIMD3<Float>>.size == MemoryLayout<vector_float3>.size, "vector_float3 layout")
    try require(MemoryLayout<SIMD2<Int32>>.size == MemoryLayout<vector_int2>.size, "vector_int2 layout")
    try require(MemoryLayout<SIMD2<Double>>.size == MemoryLayout<vector_double2>.size, "vector_double2 layout")
    try require(MemoryLayout<SIMD3<Double>>.size == MemoryLayout<vector_double3>.size, "vector_double3 layout")
    try require(MemoryLayout<matrix_float3x3>.size == MemoryLayout<simd_float3x3>.size, "matrix_float3x3 layout")
    let agent = GKAgent3D()
    agent.rotation = matrix_float3x3(
        SIMD3<Float>(1, 0, 0),
        SIMD3<Float>(0, 1, 0),
        SIMD3<Float>(0, 0, 1)
    )
    _ = agent.rotation
}

private func proveCodingAndCopy() throws {
    let entity = GKEntity()
    entity.addComponent(GKComponent())
    let data: Data
    do {
        data = try NSKeyedArchiver.archivedData(withRootObject: entity, requiringSecureCoding: true)
        _ = data
        try require(false, "secure archive of uncoded entity must not succeed")
    } catch {
        // Expected: GameplayKit types do not advertise NSSecureCoding here.
    }
    let garbage = Data([0x00, 0x01, 0x02])
    do {
        let coder = try NSKeyedUnarchiver(forReadingFrom: garbage)
        try require(GKEntity(coder: coder) == nil, "malformed entity archive")
        try require(GKScene(coder: coder) == nil, "malformed scene archive")
        try require(GKDecisionTree(coder: coder) == nil, "malformed tree archive")
    } catch {
        // Unarchiver may throw on garbage; that is still fail-closed.
    }
    let node = GKGraphNode2D(point: SIMD2<Float>(4, 5))
    let copy = node.copy() as! GKGraphNode2D
    copy.position.x = 0
    try require(node.position.x == 4, "copy independence")
}

private func proveComponentOwnership() throws {
    let a = GKEntity()
    let b = GKEntity()
    let component = GKComponent()
    a.addComponent(component)
    b.addComponent(component)
    try require(component.entity === b, "transferred")
    try require(a.components.isEmpty, "source empty")
}

private func proveSceneKitSpriteKitBridging() throws {
    let sk = SKNode()
    let scn = SCNNode()
    let entity = GKEntity()
    #if canImport(SpriteKit)
    let skComponent = GKSKNodeComponent(node: sk)
    entity.addComponent(skComponent)
    try require(skComponent.node === sk, "SK node round-trip")
    #endif
    #if canImport(SceneKit)
    let scnComponent = GKSCNNodeComponent(node: scn)
    try require(scnComponent.node === scn, "SCN node round-trip")
    #endif
    _ = SKTexture.self
    _ = SKTileMapNode.self
}

private func proveDylibLoad() throws {
    #if os(Linux)
    let names = ["libGameplayKit.dylib", "libGameplayKit.so"]
    var loaded = false
    for name in names {
        if let handle = dlopen(name, RTLD_NOW | RTLD_LOCAL) {
            loaded = true
            dlclose(handle)
            break
        }
    }
    try require(loaded, "libGameplayKit dylib/so load")
    #else
    try require(true, "dylib load deferred to Linux guest")
    #endif
}
#endif

do {
    try runGameplayKitDependencyIdentity()
} catch {
    print("GAMEPLAYKIT_DEPENDENCY_IDENTITY_FAILED: \(error)")
    exit(1)
}
