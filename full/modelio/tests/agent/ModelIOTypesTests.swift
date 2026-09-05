import Foundation
import ModelIO

func testVoxelIndexAlias() {
    let index: MDLVoxelIndex = SIMD4<Int32>(1, 2, 3, 0)
    mdlCheck(index.x == 1 && index.w == 0, "MDLVoxelIndex alias")
}

func testAxisAlignedBoundingBox() {
    var box = MDLAxisAlignedBoundingBox()
    mdlCheck(box.maxBounds == SIMD3<Float>(), "empty max")
    mdlCheck(box.minBounds == SIMD3<Float>(), "empty min")
    box = MDLAxisAlignedBoundingBox(maxBounds: SIMD3(1, 2, 3), minBounds: SIMD3(-1, -2, -3))
    mdlCheck(box.maxBounds.y == 2 && box.minBounds.z == -3, "members")
    let other = MDLAxisAlignedBoundingBox(maxBounds: SIMD3(4, 0, 0), minBounds: SIMD3(-4, -1, -1))
    let united = MDLAxisAlignedBoundingBox.union(box, other)
    mdlCheck(united.maxBounds.x == 4 && united.minBounds.x == -4, "union")
}

func testVoxelIndexExtent() {
    var extent = MDLVoxelIndexExtent()
    mdlCheck(extent.minimumExtent == SIMD4<Int32>(), "empty min")
    mdlCheck(extent.maximumExtent == SIMD4<Int32>(), "empty max")
    extent = MDLVoxelIndexExtent(minimumExtent: SIMD4(0, 0, 0, 0), maximumExtent: SIMD4(2, 2, 2, 0))
    mdlCheck(extent.maximumExtent.x == 2, "extent members")
    mdlCheck(extent == extent, "equatable")
}
