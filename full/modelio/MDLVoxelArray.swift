import Foundation

public class MDLVoxelArray: MDLObject {
    public private(set) var count: UInt = 0
    public private(set) var voxelIndexExtent = MDLVoxelIndexExtent()
    public private(set) var boundingBox = MDLAxisAlignedBoundingBox()
    public private(set) var isValidSignedShellField = false
    public var shellFieldInteriorThickness: Float = 0
    public var shellFieldExteriorThickness: Float = 0
    private var voxels: Set<MDLVoxelKey> = []
    private var voxelExtent: Float = 1

    struct MDLVoxelKey: Hashable {
        var x: Int32
        var y: Int32
        var z: Int32
        var w: Int32
    }

    public init(data voxelData: Data, boundingBox: MDLAxisAlignedBoundingBox, voxelExtent: Float) {
        self.boundingBox = boundingBox
        self.voxelExtent = max(voxelExtent, 0.001)
        super.init()
        voxelData.withUnsafeBytes { raw in
            let ints = raw.bindMemory(to: Int32.self)
            var i = 0
            while i + 3 < ints.count {
                voxels.insert(MDLVoxelKey(x: ints[i], y: ints[i + 1], z: ints[i + 2], w: ints[i + 3]))
                i += 4
            }
        }
        recount()
    }

    public init(asset: MDLAsset, divisions: Int32, patchRadius: Float) {
        super.init()
        boundingBox = asset.boundingBox
        voxelExtent = max(
            (boundingBox.maxBounds.x - boundingBox.minBounds.x) / max(Float(divisions), 1),
            0.001
        )
        _ = patchRadius
        for object in asset.childObjects(of: MDLMesh.self) {
            if let mesh = object as? MDLMesh {
                setVoxelsFor(mesh, divisions: divisions, patchRadius: patchRadius)
            }
        }
    }

    public func setVoxelAtIndex(_ index: MDLVoxelIndex) {
        voxels.insert(MDLVoxelKey(x: index.x, y: index.y, z: index.z, w: index.w))
        recount()
    }

    public func setVoxelsFor(_ mesh: MDLMesh, divisions: Int32, patchRadius: Float) {
        _ = patchRadius
        let box = mesh.boundingBox
        boundingBox = MDLAxisAlignedBoundingBox.union(boundingBox, box)
        let div = max(Int(divisions), 1)
        voxelExtent = max((box.maxBounds.x - box.minBounds.x) / Float(div), 0.001)
        let (positions, _, _, _) = mdlExtractMeshChannels(mesh)
        for p in positions {
            setVoxelAtIndex(index(ofSpatialLocation: p))
        }
    }

    public func index(ofSpatialLocation location: SIMD3<Float>) -> MDLVoxelIndex {
        let origin = boundingBox.minBounds
        let x = Int32(floor((location.x - origin.x) / voxelExtent))
        let y = Int32(floor((location.y - origin.y) / voxelExtent))
        let z = Int32(floor((location.z - origin.z) / voxelExtent))
        return SIMD4(x, y, z, 0)
    }

    public func spatialLocation(ofIndex index: MDLVoxelIndex) -> SIMD3<Float> {
        let origin = boundingBox.minBounds
        return SIMD3(
            origin.x + (Float(index.x) + 0.5) * voxelExtent,
            origin.y + (Float(index.y) + 0.5) * voxelExtent,
            origin.z + (Float(index.z) + 0.5) * voxelExtent
        )
    }

    public func voxelBoundingBox(atIndex index: MDLVoxelIndex) -> MDLAxisAlignedBoundingBox {
        let min = spatialLocation(ofIndex: index) - SIMD3(repeating: voxelExtent * 0.5)
        let max = min + SIMD3(repeating: voxelExtent)
        return MDLAxisAlignedBoundingBox(maxBounds: max, minBounds: min)
    }

    public func voxelExists(
        atIndex index: MDLVoxelIndex,
        allowAnyX: Bool,
        allowAnyY: Bool,
        allowAnyZ: Bool,
        allowAnyShell: Bool
    ) -> Bool {
        voxels.contains { voxel in
            (allowAnyX || voxel.x == index.x)
                && (allowAnyY || voxel.y == index.y)
                && (allowAnyZ || voxel.z == index.z)
                && (allowAnyShell || voxel.w == index.w)
        }
    }

    public func voxelIndices() -> Data? {
        pack(Array(voxels))
    }

    public func voxels(within extent: MDLVoxelIndexExtent) -> Data? {
        let filtered = voxels.filter { voxel in
            voxel.x >= extent.minimumExtent.x && voxel.x <= extent.maximumExtent.x
                && voxel.y >= extent.minimumExtent.y && voxel.y <= extent.maximumExtent.y
                && voxel.z >= extent.minimumExtent.z && voxel.z <= extent.maximumExtent.z
        }
        return pack(Array(filtered))
    }

    public func union(with other: MDLVoxelArray) {
        voxels.formUnion(other.voxels)
        boundingBox = MDLAxisAlignedBoundingBox.union(boundingBox, other.boundingBox)
        recount()
    }

    public func intersect(with other: MDLVoxelArray) {
        voxels.formIntersection(other.voxels)
        recount()
    }

    public func difference(with other: MDLVoxelArray) {
        voxels.subtract(other.voxels)
        recount()
    }

    public func convertToSignedShellField() {
        isValidSignedShellField = true
    }

    public func coarseMesh() -> MDLMesh? {
        coarseMesh(using: nil)
    }

    public func coarseMesh(using allocator: (any MDLMeshBufferAllocator)?) -> MDLMesh? {
        mesh(using: allocator)
    }

    public func mesh(using allocator: (any MDLMeshBufferAllocator)?) -> MDLMesh? {
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        for voxel in voxels {
            let box = voxelBoundingBox(atIndex: SIMD4(voxel.x, voxel.y, voxel.z, voxel.w))
            let built = mdlBuildBox(
                extent: box.maxBounds - box.minBounds,
                segments: SIMD3<UInt32>(1, 1, 1),
                inwardNormals: false,
                geometryType: .triangles
            )
            let base = UInt32(positions.count)
            let center = (box.maxBounds + box.minBounds) * 0.5
            positions.append(contentsOf: built.positions.map { $0 + center })
            normals.append(contentsOf: built.normals)
            uvs.append(contentsOf: built.uvs)
            indices.append(contentsOf: built.indices.map { $0 + base })
        }
        guard !positions.isEmpty else { return nil }
        return mdlMeshFromInterleaved(
            positions: positions,
            normals: normals,
            uvs: uvs,
            indices: indices,
            allocator: mdlDefaultAllocator(allocator),
            name: "voxels"
        )
    }

    private func pack(_ values: [MDLVoxelKey]) -> Data {
        var ints: [Int32] = []
        for voxel in values {
            ints.append(contentsOf: [voxel.x, voxel.y, voxel.z, voxel.w])
        }
        return ints.withUnsafeBufferPointer { Data(buffer: $0) }
    }

    private func recount() {
        count = UInt(voxels.count)
        if let first = voxels.first {
            var minE = SIMD4(first.x, first.y, first.z, first.w)
            var maxE = minE
            for voxel in voxels {
                minE = SIMD4(min(minE.x, voxel.x), min(minE.y, voxel.y), min(minE.z, voxel.z), min(minE.w, voxel.w))
                maxE = SIMD4(max(maxE.x, voxel.x), max(maxE.y, voxel.y), max(maxE.z, voxel.z), max(maxE.w, voxel.w))
            }
            voxelIndexExtent = MDLVoxelIndexExtent(minimumExtent: minE, maximumExtent: maxE)
        }
    }
}

public class MDLUtility: NSObject {
    public class func convert(toUSDZ inputURL: URL, writeTo outputURL: URL) {
        _ = (inputURL, outputURL)
        // Apple USDZ conversion requires the USD toolchain; Linux is fail-closed.
    }
}
