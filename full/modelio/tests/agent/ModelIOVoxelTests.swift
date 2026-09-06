import Foundation
import ModelIO

func testVoxelIndexRoundTrip() {
    var packed = Data()
    var values: [Int32] = [1, 2, 3, 0]
    packed.append(Data(bytes: &values, count: 16))
    let box = MDLAxisAlignedBoundingBox(maxBounds: SIMD3(4, 4, 4), minBounds: SIMD3(0, 0, 0))
    let voxels = MDLVoxelArray(data: packed, boundingBox: box, voxelExtent: 1)
    mdlCheck(voxels.count == 1, "count")
    let index = voxels.index(ofSpatialLocation: SIMD3(1.5, 2.5, 3.5))
    voxels.setVoxelAtIndex(index)
    mdlCheck(voxels.voxelExists(atIndex: index, allowAnyX: false, allowAnyY: false, allowAnyZ: false, allowAnyShell: false), "exists")
    let back = voxels.spatialLocation(ofIndex: index)
    mdlCheck(back.x > 0, "spatial")
    let vb = voxels.voxelBoundingBox(atIndex: index)
    mdlCheck(vb.maxBounds.x > vb.minBounds.x, "voxel box")
    mdlCheck(voxels.voxelIndices() != nil, "indices")
    let extent = MDLVoxelIndexExtent(minimumExtent: SIMD4(0, 0, 0, 0), maximumExtent: SIMD4(8, 8, 8, 0))
    mdlCheck(voxels.voxels(within: extent) != nil, "within")
    mdlCheck(voxels.voxelIndexExtent.maximumExtent.x >= 0, "index extent")
    let mesh = MDLMesh(boxWithExtent: SIMD3(1, 1, 1), segments: SIMD3<UInt32>(1, 1, 1), inwardNormals: false, geometryType: .triangles, allocator: nil)
    let asset = MDLAsset()
    asset.add(mesh)
    let fromAsset = MDLVoxelArray(asset: asset, divisions: 2, patchRadius: 0)
    mdlCheck(fromAsset.count >= 1, "from asset")
    fromAsset.setVoxelsFor(mesh, divisions: 2, patchRadius: 0)
    _ = fromAsset.boundingBox
}

func testVoxelSetOps() {
    let box = MDLAxisAlignedBoundingBox(maxBounds: SIMD3(2, 2, 2), minBounds: SIMD3(0, 0, 0))
    let a = MDLVoxelArray(data: Data(), boundingBox: box, voxelExtent: 1)
    a.setVoxelAtIndex(SIMD4(0, 0, 0, 0))
    a.setVoxelAtIndex(SIMD4(1, 0, 0, 0))
    let b = MDLVoxelArray(data: Data(), boundingBox: box, voxelExtent: 1)
    b.setVoxelAtIndex(SIMD4(1, 0, 0, 0))
    a.union(with: b)
    mdlCheck(a.count == 2, "union")
    a.intersect(with: b)
    mdlCheck(a.count == 1, "intersect")
    a.difference(with: b)
    mdlCheck(a.count == 0, "difference")
}

func testVoxelMesh() {
    let box = MDLAxisAlignedBoundingBox(maxBounds: SIMD3(1, 1, 1), minBounds: SIMD3(0, 0, 0))
    let voxels = MDLVoxelArray(data: Data(), boundingBox: box, voxelExtent: 1)
    voxels.setVoxelAtIndex(SIMD4(0, 0, 0, 0))
    mdlCheck(voxels.coarseMesh() != nil, "coarse")
    mdlCheck(voxels.coarseMesh(using: nil) != nil, "coarse alloc")
    mdlCheck(voxels.mesh(using: MDLMeshBufferDataAllocator()) != nil, "mesh")
}

func testVoxelShell() {
    let voxels = MDLVoxelArray(
        data: Data(),
        boundingBox: MDLAxisAlignedBoundingBox(maxBounds: SIMD3(1, 1, 1), minBounds: SIMD3()),
        voxelExtent: 1
    )
    voxels.shellFieldInteriorThickness = 0.2
    voxels.shellFieldExteriorThickness = 0.3
    voxels.convertToSignedShellField()
    mdlCheck(voxels.isValidSignedShellField, "signed")
    mdlCheck(voxels.shellFieldInteriorThickness == 0.2, "inner")
    mdlCheck(voxels.shellFieldExteriorThickness == 0.3, "outer")
}
