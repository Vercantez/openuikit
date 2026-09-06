import Foundation
import Metal

func testGeometryHelpers() {
    let origin = MTLOriginMake(1, 2, 3)
    precondition(origin.x == 1 && origin.y == 2 && origin.z == 3)
    precondition(MTLOrigin().x == 0)
    precondition(MTLOrigin(x: 4, y: 5, z: 6).z == 6)
    let size = MTLSizeMake(4, 5, 6)
    precondition(size == MTLSize(width: 4, height: 5, depth: 6))
    precondition(MTLSize().width == 0)
    let region2D = MTLRegionMake2D(1, 2, 3, 4)
    precondition(region2D.origin.x == 1 && region2D.size.height == 4)
    let region3D = MTLRegionMake3D(0, 0, 0, 8, 8, 1)
    precondition(region3D.size.depth == 1)
    let region1D = MTLRegionMake1D(2, 10)
    precondition(region1D.size.width == 10)
    precondition(MTLRegion().size.width == 0)
    let sized = MTLSizeAndAlign(size: 64, align: 16)
    precondition(sized.size == 64 && sized.align == 16)
    precondition(MTLSizeAndAlign().align == 0)
    let clear = MTLClearColorMake(0.1, 0.2, 0.3, 1)
    precondition(clear.red == 0.1 && clear.green == 0.2 && clear.blue == 0.3 && clear.alpha == 1)
    precondition(MTLClearColor().alpha == 1)
    precondition(MTLClearColor(red: 1, green: 0, blue: 0, alpha: 1).red == 1)
    let viewport = MTLViewport(originX: 0, originY: 0, width: 100, height: 50, znear: 0, zfar: 1)
    precondition(viewport.width == 100 && viewport.height == 50 && viewport.znear == 0 && viewport.zfar == 1)
    precondition(MTLViewport().zfar == 1)
    let scissor = MTLScissorRect(x: 0, y: 1, width: 10, height: 12)
    precondition(scissor.x == 0 && scissor.y == 1 && scissor.width == 10 && scissor.height == 12)
    precondition(MTLScissorRect().width == 0)
    let sample = MTLSamplePositionMake(0.5, 0.25)
    precondition(sample.x == 0.5 && sample.y == 0.25)
    precondition(MTLSamplePosition().x == 0)
    let coord = MTLCoordinate2DMake(1, 2)
    precondition(coord.x == 1 && coord.y == 2)
    let packed = MTLPackedFloat3Make(1, 2, 3)
    precondition(packed.x == 1 && packed.y == 2 && packed.z == 3)
    precondition(packed.elements.0 == 1 && packed.elements.2 == 3)
    var packedMut = MTLPackedFloat3()
    packedMut.elements = (9, 8, 7)
    precondition(packedMut.x == 9)
    let range = MTLIndirectCommandBufferExecutionRangeMake(4, 8)
    precondition(range.location == 4 && range.length == 8)
    precondition(MTLIndirectCommandBufferExecutionRange().length == 0)
    let gpuRange = MTL4BufferRangeMake(16, 32)
    precondition(gpuRange.bufferAddress == 16 && gpuRange.length == 32)
    precondition(MTL4BufferRange().length == 0)
    let mapping = MTLVertexAmplificationViewMapping(
        viewportArrayIndexOffset: 1,
        renderTargetArrayIndexOffset: 2
    )
    precondition(mapping.viewportArrayIndexOffset == 1)
    precondition(mapping.renderTargetArrayIndexOffset == 2)
    _ = MTLVertexAmplificationViewMapping()
    let swizzle = MTLTextureSwizzleChannels(red: .red, green: .green, blue: .blue, alpha: .alpha)
    precondition(swizzle.red == .red && swizzle.alpha == .alpha)
    _ = MTLTextureSwizzleChannels()
    let resourceID = MTLResourceID()
    precondition(resourceID._impl == 0)

    let identity = MTLPackedFloat4x3()
    precondition(identity.columns.0.x == 0)
    let column0 = MTLPackedFloat3Make(1, 0, 0)
    let column1 = MTLPackedFloat3Make(0, 1, 0)
    let column2 = MTLPackedFloat3Make(0, 0, 1)
    let column3 = MTLPackedFloat3Make(4, 5, 6)
    let transform = MTLPackedFloat4x3(columns: (column0, column1, column2, column3))
    precondition(transform.columns.3.x == 4 && transform.columns.3.z == 6)
}

func testAccelerationStructureDescriptors() {
    let sizes = MTLAccelerationStructureSizes(
        accelerationStructureSize: 0,
        buildScratchBufferSize: 0,
        refitScratchBufferSize: 0
    )
    precondition(sizes.accelerationStructureSize == 0)
    precondition(MTLAccelerationStructureSizes() == sizes)
    let matrix = MTLPackedFloat4x3(columns: (
        MTLPackedFloat3Make(1, 0, 0),
        MTLPackedFloat3Make(0, 1, 0),
        MTLPackedFloat3Make(0, 0, 1),
        MTLPackedFloat3Make(10, 20, 30)
    ))
    var instance = MTLAccelerationStructureInstanceDescriptor(
        transformationMatrix: matrix,
        options: [.opaque, .disableTriangleCulling],
        mask: 0xFF,
        intersectionFunctionTableOffset: 2,
        accelerationStructureIndex: 3
    )
    precondition(instance.mask == 0xFF)
    precondition(instance.options.contains(.opaque))
    instance.accelerationStructureIndex = 7
    precondition(instance.accelerationStructureIndex == 7)
    precondition(instance.transformationMatrix.columns.3.y == 20)
    var user = MTLAccelerationStructureUserIDInstanceDescriptor(
        transformationMatrix: matrix,
        options: .nonOpaque,
        mask: 1,
        intersectionFunctionTableOffset: 0,
        accelerationStructureIndex: 1,
        userID: 42
    )
    precondition(user.userID == 42)
    user.userID = 99
    precondition(user.userID == 99)
    var motion = MTLAccelerationStructureMotionInstanceDescriptor()
    motion.motionStartTime = 0.25
    motion.motionEndTime = 0.75
    motion.motionStartBorderMode = .clamp
    motion.motionEndBorderMode = .vanish
    motion.motionTransformsCount = 4
    motion.motionTransformsStartIndex = 1
    motion.options = .triangleFrontFacingWindingCounterClockwise
    precondition(motion.motionEndBorderMode == .vanish)
    precondition(motion.motionTransformsCount == 4)
    var indirect = MTLIndirectAccelerationStructureInstanceDescriptor(
        transformationMatrix: matrix,
        options: .opaque,
        mask: 2,
        intersectionFunctionTableOffset: 0,
        userID: 8,
        accelerationStructureID: MTLResourceID()
    )
    precondition(indirect.accelerationStructureID._impl == 0)
    indirect.userID = 9
    precondition(indirect.userID == 9)
    var indirectMotion = MTLIndirectAccelerationStructureMotionInstanceDescriptor()
    indirectMotion.motionStartBorderMode = .vanish
    indirectMotion.accelerationStructureID = MTLResourceID()
    precondition(indirectMotion.motionStartBorderMode == .vanish)
    let descriptor = MTLAccelerationStructureDescriptor()
    descriptor.usage = [.refit, .preferFastBuild]
    precondition(descriptor.usage.contains(.refit))
    let device = MTLCreateSystemDefaultDevice()!
    let zero = device.accelerationStructureSizes(descriptor: descriptor)
    precondition(zero.accelerationStructureSize == 0)
    precondition(zero.buildScratchBufferSize == 0)
    precondition(zero.refitScratchBufferSize == 0)
    let sparse = device.sparseTileSize(with: .type2D, pixelFormat: .rgba8Unorm, sampleCount: 1)
    precondition(sparse.width == 0 && sparse.height == 0)
    let sparsePage = device.sparseTileSize(
        with: .type2D,
        pixelFormat: .rgba8Unorm,
        sampleCount: 1,
        sparsePageSize: .size16
    )
    precondition(sparsePage.width == 0)
}

func testAccelerationStructureGeometryDescriptors() {
    let keyframe = MTLMotionKeyframeData.data()
    keyframe.offset = 16
    precondition(keyframe.offset == 16)
    keyframe.buffer = nil
    let geometry = MTLAccelerationStructureGeometryDescriptor()
    geometry.intersectionFunctionTableOffset = 3
    geometry.opaque = true
    geometry.allowDuplicateIntersectionFunctionInvocation = false
    geometry.label = "geom"
    geometry.primitiveDataBuffer = nil
    geometry.primitiveDataBufferOffset = 8
    geometry.primitiveDataStride = 16
    geometry.primitiveDataElementSize = 4
    precondition(geometry.opaque)
    let curve = MTLAccelerationStructureCurveGeometryDescriptor.descriptor()
    curve.controlPointCount = 4
    curve.controlPointBufferOffset = 0
    curve.controlPointFormat = .float3
    curve.controlPointStride = 12
    curve.radiusBufferOffset = 0
    curve.radiusFormat = .float
    curve.radiusStride = 4
    curve.indexBufferOffset = 0
    curve.indexType = .uint16
    curve.segmentCount = 1
    curve.segmentControlPointCount = 4
    curve.curveType = .round
    curve.curveBasis = .bSpline
    curve.curveEndCaps = .none
    curve.controlPointBuffer = nil
    curve.radiusBuffer = nil
    curve.indexBuffer = nil
    precondition(curve.controlPointCount == 4)
    precondition(curve.curveBasis == .bSpline)
    let motion = MTLAccelerationStructureMotionCurveGeometryDescriptor.descriptor()
    motion.controlPointBuffers = [keyframe]
    motion.controlPointCount = 4
    motion.controlPointFormat = .float3
    motion.controlPointStride = 12
    motion.radiusBuffers = [keyframe]
    motion.radiusFormat = .float
    motion.radiusStride = 4
    motion.indexBuffer = nil
    motion.indexBufferOffset = 0
    motion.indexType = .uint32
    motion.segmentCount = 1
    motion.segmentControlPointCount = 4
    motion.curveType = .flat
    motion.curveBasis = .bezier
    motion.curveEndCaps = .sphere
    precondition(motion.controlPointBuffers.count == 1)
    precondition(motion.curveType == .flat)
    let indirect = MTLIndirectInstanceAccelerationStructureDescriptor.descriptor()
    indirect.instanceDescriptorBuffer = nil
    indirect.instanceDescriptorBufferOffset = 0
    indirect.instanceDescriptorStride = 64
    indirect.instanceDescriptorType = .indirect
    indirect.maxInstanceCount = 8
    indirect.instanceCountBuffer = nil
    indirect.instanceCountBufferOffset = 4
    indirect.instanceTransformationMatrixLayout = .columnMajor
    indirect.motionTransformBuffer = nil
    indirect.motionTransformBufferOffset = 0
    indirect.motionTransformStride = 48
    indirect.motionTransformType = .packedFloat4x3
    indirect.maxMotionTransformCount = 2
    indirect.motionTransformCountBuffer = nil
    indirect.motionTransformCountBufferOffset = 0
    precondition(indirect.maxInstanceCount == 8)
    precondition(indirect.instanceDescriptorType == .indirect)
}

func testTriangleAndInstanceAccelerationDescriptors() {
    let device = MTLCreateSystemDefaultDevice()!
    let vertices = device.makeBuffer(length: 36, options: .storageModeShared)!
    let indices = device.makeBuffer(length: 12, options: .storageModeShared)!
    let boxes = device.makeBuffer(length: 24, options: .storageModeShared)!
    let triangle = MTLAccelerationStructureTriangleGeometryDescriptor.descriptor()
    triangle.vertexBuffer = vertices
    triangle.vertexBufferOffset = 0
    triangle.vertexStride = 12
    triangle.vertexFormat = .float3
    triangle.indexBuffer = indices
    triangle.indexBufferOffset = 0
    triangle.indexType = .uint16
    triangle.triangleCount = 1
    triangle.transformationMatrixBuffer = nil
    triangle.transformationMatrixBufferOffset = 0
    triangle.transformationMatrixLayout = .columnMajor
    triangle.opaque = true
    triangle.label = "tri"
    precondition(triangle.triangleCount == 1)
    precondition(triangle.vertexStride == 12)
    let keyframe = MTLMotionKeyframeData.data()
    keyframe.buffer = vertices
    keyframe.offset = 0
    let motionTri = MTLAccelerationStructureMotionTriangleGeometryDescriptor.descriptor()
    motionTri.vertexBuffers = [keyframe]
    motionTri.vertexStride = 12
    motionTri.vertexFormat = .float3
    motionTri.indexBuffer = indices
    motionTri.indexBufferOffset = 0
    motionTri.indexType = .uint32
    motionTri.triangleCount = 2
    motionTri.transformationMatrixBuffer = nil
    motionTri.transformationMatrixBufferOffset = 0
    motionTri.transformationMatrixLayout = .rowMajor
    precondition(motionTri.vertexBuffers.count == 1)
    precondition(motionTri.triangleCount == 2)
    let box = MTLAccelerationStructureBoundingBoxGeometryDescriptor.descriptor()
    box.boundingBoxBuffer = boxes
    box.boundingBoxBufferOffset = 0
    box.boundingBoxCount = 1
    box.boundingBoxStride = 24
    precondition(box.boundingBoxCount == 1)
    let motionBox = MTLAccelerationStructureMotionBoundingBoxGeometryDescriptor.descriptor()
    motionBox.boundingBoxBuffers = [keyframe]
    motionBox.boundingBoxCount = 1
    motionBox.boundingBoxStride = 24
    precondition(motionBox.boundingBoxBuffers.count == 1)
    let primitive = MTLPrimitiveAccelerationStructureDescriptor.descriptor()
    primitive.geometryDescriptors = [triangle, box]
    primitive.motionStartBorderMode = .clamp
    primitive.motionEndBorderMode = .vanish
    primitive.motionStartTime = 0
    primitive.motionEndTime = 1
    primitive.motionKeyframeCount = 1
    primitive.usage = [.preferFastBuild]
    precondition(primitive.geometryDescriptors?.count == 2)
    let instance = MTLInstanceAccelerationStructureDescriptor.descriptor()
    instance.instanceDescriptorBuffer = vertices
    instance.instanceDescriptorBufferOffset = 0
    instance.instanceDescriptorStride = 64
    instance.instanceDescriptorType = .userID
    instance.instanceCount = 2
    instance.instancedAccelerationStructures = [device.makeAccelerationStructure(size: 0)!]
    instance.instanceTransformationMatrixLayout = .columnMajor
    instance.motionTransformBuffer = nil
    instance.motionTransformBufferOffset = 0
    instance.motionTransformStride = 48
    instance.motionTransformType = .packedFloat4x3
    instance.motionTransformCount = 0
    precondition(instance.instanceCount == 2)
    precondition(instance.instanceDescriptorType == .userID)
    let sizes = device.accelerationStructureSizes(descriptor: primitive)
    precondition(sizes.accelerationStructureSize == 0)

    var quaternion = MTLPackedFloatQuaternion(x: 0, y: 0, z: 0, w: 1)
    quaternion.x = 0.1
    precondition(quaternion.w == 1)
    precondition(MTLPackedFloatQuaternion() != quaternion)
    var transform = MTLComponentTransform()
    transform.scale = MTLPackedFloat3Make(1, 2, 3)
    transform.shear = MTLPackedFloat3()
    transform.pivot = MTLPackedFloat3()
    transform.rotation = quaternion
    transform.translation = MTLPackedFloat3Make(4, 5, 6)
    precondition(transform.scale.y == 2)
    precondition(transform == MTLComponentTransform(
        scale: transform.scale,
        shear: transform.shear,
        pivot: transform.pivot,
        rotation: transform.rotation,
        translation: transform.translation
    ))
    var mapArgs = MTLMapIndirectArguments(
        regionOriginX: 1, regionOriginY: 2, regionOriginZ: 0,
        regionSizeWidth: 4, regionSizeHeight: 4, regionSizeDepth: 1,
        mipMapLevel: 0, sliceId: 0
    )
    mapArgs.sliceId = 1
    precondition(mapArgs.regionSizeWidth == 4)
    precondition(MTLMapIndirectArguments().mipMapLevel == 0)
    var draw = MTLDrawPrimitivesIndirectArguments(vertexCount: 3, instanceCount: 1, vertexStart: 0, baseInstance: 0)
    draw.instanceCount = 2
    precondition(draw.vertexCount == 3)
    var indexed = MTLDrawIndexedPrimitivesIndirectArguments(
        indexCount: 3, instanceCount: 1, indexStart: 0, baseVertex: 0, baseInstance: 0
    )
    indexed.baseVertex = -1
    precondition(indexed.indexCount == 3)
    var patch = MTLDrawPatchIndirectArguments(patchCount: 1, instanceCount: 1, patchStart: 0, baseInstance: 0)
    patch.patchStart = 1
    precondition(patch.patchCount == 1)
}

func testMetal4AccelerationStructureDescriptors() {
    let geometry = MTL4AccelerationStructureGeometryDescriptor()
    geometry.intersectionFunctionTableOffset = 2
    geometry.opaque = true
    geometry.allowDuplicateIntersectionFunctionInvocation = false
    geometry.label = "g4"
    geometry.primitiveDataBuffer = MTL4BufferRangeMake(8, 16)
    geometry.primitiveDataStride = 16
    geometry.primitiveDataElementSize = 4
    precondition(geometry.opaque)
    let curve = MTL4AccelerationStructureCurveGeometryDescriptor()
    curve.controlPointBuffer = MTL4BufferRangeMake(0, 48)
    curve.controlPointCount = 4
    curve.controlPointStride = 12
    curve.controlPointFormat = .float3
    curve.radiusBuffer = MTL4BufferRangeMake(48, 16)
    curve.radiusFormat = .float
    curve.radiusStride = 4
    curve.indexBuffer = MTL4BufferRangeMake(64, 8)
    curve.indexType = .uint16
    curve.segmentCount = 1
    curve.segmentControlPointCount = 4
    curve.curveType = .round
    curve.curveBasis = .bSpline
    curve.curveEndCaps = .none
    precondition(curve.controlPointCount == 4)
    let motionCurve = MTL4AccelerationStructureMotionCurveGeometryDescriptor()
    motionCurve.controlPointBuffers = MTL4BufferRangeMake(0, 96)
    motionCurve.controlPointCount = 4
    motionCurve.controlPointStride = 12
    motionCurve.controlPointFormat = .float3
    motionCurve.radiusBuffers = MTL4BufferRangeMake(96, 32)
    motionCurve.radiusFormat = .float
    motionCurve.radiusStride = 4
    motionCurve.indexBuffer = MTL4BufferRangeMake(128, 8)
    motionCurve.indexType = .uint32
    motionCurve.segmentCount = 1
    motionCurve.segmentControlPointCount = 4
    motionCurve.curveType = .flat
    motionCurve.curveBasis = .bezier
    motionCurve.curveEndCaps = .sphere
    precondition(motionCurve.curveType == .flat)
    let tri = MTL4AccelerationStructureTriangleGeometryDescriptor()
    tri.vertexBuffer = MTL4BufferRangeMake(0, 36)
    tri.vertexFormat = .float3
    tri.vertexStride = 12
    tri.indexBuffer = MTL4BufferRangeMake(36, 12)
    tri.indexType = .uint16
    tri.triangleCount = 1
    tri.transformationMatrixBuffer = MTL4BufferRangeMake(48, 48)
    tri.transformationMatrixLayout = .columnMajor
    precondition(tri.triangleCount == 1)
    let motionTri = MTL4AccelerationStructureMotionTriangleGeometryDescriptor()
    motionTri.vertexBuffers = MTL4BufferRangeMake(0, 72)
    motionTri.vertexFormat = .float3
    motionTri.vertexStride = 12
    motionTri.indexBuffer = MTL4BufferRangeMake(72, 12)
    motionTri.indexType = .uint32
    motionTri.triangleCount = 2
    motionTri.transformationMatrixBuffer = MTL4BufferRange()
    motionTri.transformationMatrixLayout = .rowMajor
    precondition(motionTri.triangleCount == 2)
    let box = MTL4AccelerationStructureBoundingBoxGeometryDescriptor()
    box.boundingBoxBuffer = MTL4BufferRangeMake(0, 24)
    box.boundingBoxCount = 1
    box.boundingBoxStride = 24
    precondition(box.boundingBoxCount == 1)
    let motionBox = MTL4AccelerationStructureMotionBoundingBoxGeometryDescriptor()
    motionBox.boundingBoxBuffers = MTL4BufferRangeMake(0, 48)
    motionBox.boundingBoxCount = 2
    motionBox.boundingBoxStride = 24
    precondition(motionBox.boundingBoxCount == 2)
    let primitive = MTL4PrimitiveAccelerationStructureDescriptor()
    primitive.geometryDescriptors = [curve, tri, box]
    primitive.motionStartBorderMode = .clamp
    primitive.motionEndBorderMode = .vanish
    primitive.motionStartTime = 0
    primitive.motionEndTime = 1
    primitive.motionKeyframeCount = 2
    precondition(primitive.geometryDescriptors?.count == 3)
    let instance = MTL4InstanceAccelerationStructureDescriptor()
    instance.instanceDescriptorBuffer = MTL4BufferRangeMake(0, 128)
    instance.instanceDescriptorStride = 64
    instance.instanceDescriptorType = .default
    instance.instanceCount = 2
    instance.instanceTransformationMatrixLayout = .columnMajor
    instance.motionTransformBuffer = MTL4BufferRange()
    instance.motionTransformStride = 48
    instance.motionTransformType = .packedFloat4x3
    instance.motionTransformCount = 0
    precondition(instance.instanceCount == 2)
    let indirect = MTL4IndirectInstanceAccelerationStructureDescriptor()
    indirect.instanceDescriptorBuffer = MTL4BufferRangeMake(0, 256)
    indirect.instanceDescriptorStride = 64
    indirect.instanceDescriptorType = .indirect
    indirect.maxInstanceCount = 8
    indirect.instanceCountBuffer = MTL4BufferRangeMake(256, 4)
    indirect.instanceTransformationMatrixLayout = .columnMajor
    indirect.motionTransformBuffer = MTL4BufferRange()
    indirect.motionTransformStride = 48
    indirect.motionTransformType = .component
    indirect.maxMotionTransformCount = 2
    indirect.motionTransformCountBuffer = MTL4BufferRangeMake(260, 4)
    precondition(indirect.maxInstanceCount == 8)
    precondition(indirect.instanceDescriptorType == .indirect)
}
