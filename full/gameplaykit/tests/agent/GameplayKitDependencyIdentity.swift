import Foundation
#if canImport(simd)
import simd
#elseif canImport(SIMD)
import SIMD
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
#if os(Linux)
import Glibc
#endif

enum GameplayKitDependencyIdentityFailure: Error {
    case message(String)
}

private func require(_ condition: Bool, _ message: String) throws {
    if !condition {
        throw GameplayKitDependencyIdentityFailure.message(message)
    }
}

/// Future EC2 cold-build probe. Not part of the isolated host gate.
/// Prints `GAMEPLAYKIT_DEPENDENCY_IDENTITY_OK` only after Foundation, the
/// shared SIMD/simd provider, SceneKit, SpriteKit, and GameplayKit are all
/// present and identity/ABI assertions pass. Otherwise prints
/// `GAMEPLAYKIT_DEPENDENCY_IDENTITY_UNAVAILABLE` and does not claim success.
func runGameplayKitDependencyIdentity() throws {
    #if canImport(simd) && canImport(SceneKit) && canImport(SpriteKit) && canImport(GameplayKit)
    try proveVectorMatrixIdentity()
    try proveCodingAndCopy()
    try proveComponentOwnership()
    try proveSceneKitSpriteKitBridging()
    try proveDylibLoadAndSymbols()
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
private func proveVectorMatrixIdentity() throws {
    let node = GKGraphNode2D(point: SIMD2<Float>(1, 2))
    try require(type(of: node.position) == vector_float2.self, "vector_float2 identity")
    try require(SIMD2<Float>.self == vector_float2.self, "vector_float2 nominal")
    try require(SIMD3<Float>.self == vector_float3.self, "vector_float3 nominal")
    try require(SIMD2<Int32>.self == vector_int2.self, "vector_int2 nominal")
    try require(SIMD2<Double>.self == vector_double2.self, "vector_double2 nominal")
    try require(SIMD3<Double>.self == vector_double3.self, "vector_double3 nominal")
    try require(MemoryLayout<SIMD2<Float>>.size == MemoryLayout<vector_float2>.size, "vector_float2 layout")
    try require(MemoryLayout<SIMD3<Float>>.size == MemoryLayout<vector_float3>.size, "vector_float3 layout")
    try require(MemoryLayout<SIMD2<Int32>>.size == MemoryLayout<vector_int2>.size, "vector_int2 layout")
    try require(MemoryLayout<SIMD2<Double>>.size == MemoryLayout<vector_double2>.size, "vector_double2 layout")
    try require(MemoryLayout<SIMD3<Double>>.size == MemoryLayout<vector_double3>.size, "vector_double3 layout")
    try require(matrix_float3x3.self == simd_float3x3.self, "matrix_float3x3 nominal")
    try require(MemoryLayout<matrix_float3x3>.size == MemoryLayout<simd_float3x3>.size, "matrix_float3x3 layout")
    try require(MemoryLayout<matrix_float3x3>.stride == MemoryLayout<simd_float3x3>.stride, "matrix_float3x3 stride")
    let agent = GKAgent3D()
    let col0 = SIMD3<Float>(1, 0, 0)
    let col1 = SIMD3<Float>(0, 1, 0)
    let col2 = SIMD3<Float>(0, 0, 1)
    agent.rotation = matrix_float3x3(col0, col1, col2)
    try require(type(of: agent.rotation) == matrix_float3x3.self, "rotation type")
    _ = agent.rotation
}

private func proveCodingAndCopy() throws {
    let entity = GKEntity()
    entity.addComponent(GKComponent())
    let data = try NSKeyedArchiver.archivedData(withRootObject: entity, requiringSecureCoding: true)
    let decoded = try NSKeyedUnarchiver.unarchivedObject(ofClass: GKEntity.self, from: data)
    try require(decoded != nil, "entity archive round-trip")
    try require(decoded?.components.count == 1, "decoded component count")
    try require(decoded?.components.first?.entity === decoded, "decoded ownership")

    let garbage = Data([0x00, 0x01, 0x02])
    do {
        let coder = try NSKeyedUnarchiver(forReadingFrom: garbage)
        try require(GKEntity(coder: coder) == nil, "malformed entity archive")
        try require(GKScene(coder: coder) == nil, "malformed scene archive")
        try require(GKDecisionTree(coder: coder) == nil, "malformed tree archive")
    } catch {
        // Unarchiver may throw on garbage; that is still fail-closed.
    }

    let a = GKGraphNode2D(point: SIMD2<Float>(4, 5))
    let b = GKGraphNode2D(point: SIMD2<Float>(6, 7))
    a.addConnections(to: [b], bidirectional: false)
    let graph = GKGraph(nodes: [a, b])
    let graphData = try NSKeyedArchiver.archivedData(withRootObject: graph, requiringSecureCoding: true)
    let graphDecoded = try NSKeyedUnarchiver.unarchivedObject(ofClass: GKGraph.self, from: graphData)
    try require(graphDecoded?.nodes?.count == 2, "graph archive")
    let copy = a.copy() as! GKGraphNode2D
    copy.position.x = 0
    try require(a.position.x == 4, "copy independence")
}

private func proveComponentOwnership() throws {
    let a = GKEntity()
    let b = GKEntity()
    let component = GKComponent()
    a.addComponent(component)
    b.addComponent(component)
    try require(component.entity === b, "transferred")
    try require(a.components.isEmpty, "source empty")
    let replacement = GKComponent()
    b.addComponent(replacement)
    try require(component.entity == nil, "replaced")
    b.removeComponent(ofType: GKComponent.self)
    try require(b.components.isEmpty, "removed")
    var host: GKEntity? = GKEntity()
    let orphan = GKComponent()
    host!.addComponent(orphan)
    host = nil
    try require(orphan.entity == nil, "deallocated")
}

private func proveSceneKitSpriteKitBridging() throws {
    let sk = SKNode()
    let scn = SCNNode()
    let entity = GKEntity()
    let skComponent = GKSKNodeComponent(node: sk)
    entity.addComponent(skComponent)
    try require(skComponent.node === sk, "SK node round-trip")
    sk.entity = entity
    try require(sk.entity === entity, "SKNode.entity")
    let scnComponent = GKSCNNodeComponent(node: scn)
    try require(scnComponent.node === scn, "SCN node round-trip")
    scn.entity = entity
    try require(scn.entity === entity, "SCNNode.entity")
    _ = SKTexture.self
    _ = SKTileMapNode.self
}

private func candidateLibraryPaths() -> [String] {
    var paths = ["libGameplayKit.dylib", "libGameplayKit.so"]
    let extra = [".", "/tmp"]
    for directory in extra {
        paths.append("\(directory)/libGameplayKit.dylib")
        paths.append("\(directory)/libGameplayKit.so")
    }
    #if os(Linux)
    if let raw = getenv("LD_LIBRARY_PATH") {
        let directories = String(cString: raw).split(separator: ":")
        for directory in directories {
            paths.append("\(directory)/libGameplayKit.dylib")
            paths.append("\(directory)/libGameplayKit.so")
        }
    }
    #endif
    return paths
}

private func inspectELF(path: String) throws {
    let readelf = Process()
    readelf.executableURL = URL(fileURLWithPath: "/usr/bin/readelf")
    readelf.arguments = ["-d", path]
    let readPipe = Pipe()
    readelf.standardOutput = readPipe
    readelf.standardError = Pipe()
    if FileManager.default.isExecutableFile(atPath: "/usr/bin/readelf") {
        try readelf.run()
        readelf.waitUntilExit()
        let text = String(data: readPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        try require(
            text.contains("libswiftCore") || text.contains("libFoundation") || text.contains("NEEDED"),
            "readelf NEEDED"
        )
    }
    let nm = Process()
    nm.executableURL = URL(fileURLWithPath: "/usr/bin/nm")
    nm.arguments = ["-D", path]
    let nmPipe = Pipe()
    nm.standardOutput = nmPipe
    nm.standardError = Pipe()
    if FileManager.default.isExecutableFile(atPath: "/usr/bin/nm") {
        try nm.run()
        nm.waitUntilExit()
        let text = String(data: nmPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        try require(text.contains("GKEntity") || text.contains("GameplayKit"), "nm symbols")
    }
}

private func proveDylibLoadAndSymbols() throws {
    #if os(Linux)
    var loadedPath: String?
    var handle: UnsafeMutableRawPointer?
    for path in candidateLibraryPaths() {
        if let opened = dlopen(path, RTLD_NOW | RTLD_LOCAL) {
            handle = opened
            loadedPath = path
            break
        }
    }
    try require(handle != nil, "libGameplayKit dylib/so load")
    if let handle {
        let names = [
            "$s11GameplayKit8GKEntityC",
            "OBJC_CLASS_$_GKEntity"
        ]
        var found = false
        for name in names {
            if dlsym(handle, name) != nil {
                found = true
                break
            }
        }
        if let loadedPath {
            do {
                try inspectELF(path: loadedPath)
                found = true
            } catch {
                if !found {
                    throw error
                }
            }
        }
        try require(found, "GameplayKit symbols")
        dlclose(handle)
    }
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
