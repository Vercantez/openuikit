import Foundation

public struct MDLAxisAlignedBoundingBox: Equatable, Sendable {
    public var maxBounds: SIMD3<Float>
    public var minBounds: SIMD3<Float>

    public init() {
        maxBounds = SIMD3<Float>(repeating: 0)
        minBounds = SIMD3<Float>(repeating: 0)
    }

    public init(maxBounds: SIMD3<Float>, minBounds: SIMD3<Float>) {
        self.maxBounds = maxBounds
        self.minBounds = minBounds
    }

    public static func union(_ a: MDLAxisAlignedBoundingBox, _ b: MDLAxisAlignedBoundingBox) -> MDLAxisAlignedBoundingBox {
        if a == MDLAxisAlignedBoundingBox() { return b }
        if b == MDLAxisAlignedBoundingBox() { return a }
        return MDLAxisAlignedBoundingBox(
            maxBounds: SIMD3(max(a.maxBounds.x, b.maxBounds.x), max(a.maxBounds.y, b.maxBounds.y), max(a.maxBounds.z, b.maxBounds.z)),
            minBounds: SIMD3(min(a.minBounds.x, b.minBounds.x), min(a.minBounds.y, b.minBounds.y), min(a.minBounds.z, b.minBounds.z))
        )
    }
}

public struct MDLVoxelIndexExtent: Equatable, Sendable {
    public var minimumExtent: MDLVoxelIndex
    public var maximumExtent: MDLVoxelIndex

    public init() {
        minimumExtent = SIMD4<Int32>(repeating: 0)
        maximumExtent = SIMD4<Int32>(repeating: 0)
    }

    public init(minimumExtent: MDLVoxelIndex, maximumExtent: MDLVoxelIndex) {
        self.minimumExtent = minimumExtent
        self.maximumExtent = maximumExtent
    }
}

func mdlEmptyBounds() -> MDLAxisAlignedBoundingBox {
    MDLAxisAlignedBoundingBox(
        maxBounds: SIMD3<Float>(repeating: -Float.greatestFiniteMagnitude),
        minBounds: SIMD3<Float>(repeating: Float.greatestFiniteMagnitude)
    )
}

func mdlBoundsFromPositions(_ positions: [SIMD3<Float>]) -> MDLAxisAlignedBoundingBox {
    guard !positions.isEmpty else { return MDLAxisAlignedBoundingBox() }
    var mn = positions[0]
    var mx = positions[0]
    for p in positions {
        mn = SIMD3(min(mn.x, p.x), min(mn.y, p.y), min(mn.z, p.z))
        mx = SIMD3(max(mx.x, p.x), max(mx.y, p.y), max(mx.z, p.z))
    }
    return MDLAxisAlignedBoundingBox(maxBounds: mx, minBounds: mn)
}
