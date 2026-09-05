import Foundation
import MetalPerformanceShaders

func testMPSGeometryStructs() {
    let offset = MPSOffset(x: 1, y: 2, z: 3)
    precondition(offset.x == 1 && offset.y == 2 && offset.z == 3)
    precondition(MPSOffset() == MPSOffset(x: 0, y: 0, z: 0))
    var origin = MPSOrigin(x: 1.5, y: 2.5, z: 3.5)
    precondition(origin.x == 1.5)
    origin = MPSOrigin()
    precondition(origin.y == 0)
    var size = MPSSize(width: 8, height: 4, depth: 1)
    precondition(size.width == 8)
    size = MPSSize()
    precondition(size.height == 0)
    var region = MPSRegion(origin: MPSOrigin(x: 1, y: 2, z: 0), size: MPSSize(width: 3, height: 4, depth: 1))
    precondition(region.size.width == 3)
    region = MPSRegion()
    precondition(region.origin.x == 0)
    var scale = MPSScaleTransform(scaleX: 2, scaleY: 3, translateX: 4, translateY: 5)
    precondition(scale.scaleX == 2 && scale.translateY == 5)
    scale = MPSScaleTransform()
    precondition(scale.scaleX == 1)
    var coord = MPSImageCoordinate(x: 3, y: 4, channel: 1)
    precondition(coord.channel == 1)
    coord = MPSImageCoordinate()
    precondition(coord.x == 0)
    var imageRegion = MPSImageRegion(offset: coord, size: MPSImageCoordinate(x: 2, y: 2, channel: 4))
    precondition(imageRegion.size.x == 2)
    imageRegion = MPSImageRegion()
    precondition(imageRegion.offset.y == 0)
    var rw = MPSImageReadWriteParams(featureChannelOffset: 1, numberOfFeatureChannelsToReadWrite: 3)
    precondition(rw.featureChannelOffset == 1)
    rw = MPSImageReadWriteParams()
    precondition(rw.numberOfFeatureChannelsToReadWrite == 0)
    var div = MPSIntegerDivisionParams(divisor: 7, recip: 1, addend: 0, shift: 2)
    precondition(div.divisor == 7)
    div = MPSIntegerDivisionParams()
    precondition(div.divisor == 1)
    var slice = MPSDimensionSlice(start: 2, length: 5)
    precondition(slice.length == 5)
    slice = MPSDimensionSlice()
    precondition(slice.start == 0)
    var moff = MPSMatrixOffset(rowOffset: 1, columnOffset: 2)
    precondition(moff.columnOffset == 2)
    moff = MPSMatrixOffset()
    precondition(moff.rowOffset == 0)
    var coff = MPSMatrixCopyOffsets(
        sourceRowOffset: 1,
        sourceColumnOffset: 2,
        destinationRowOffset: 3,
        destinationColumnOffset: 4
    )
    precondition(coff.destinationColumnOffset == 4)
    coff = MPSMatrixCopyOffsets()
    precondition(coff.sourceRowOffset == 0)
    let ndOff = MPSNDArrayOffsets()
    precondition(ndOff.dimensions.0 == 0)
    let ndSizes = MPSNDArraySizes(dimensions: (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16))
    precondition(ndSizes.dimensions.15 == 16)
    var hist = MPSImageHistogramInfo()
    precondition(hist.numberOfHistogramEntries == 256)
    hist = MPSImageHistogramInfo(
        numberOfHistogramEntries: 128,
        histogramForAlpha: ObjCBool(true),
        minPixelValue: vector_float4(0, 0, 0, 0),
        maxPixelValue: vector_float4(1, 1, 1, 1)
    )
    precondition(hist.histogramForAlpha.boolValue)
    var kp = MPSImageKeypointData(keypointCoordinate: vector_ushort2(1, 2), keypointColorValue: 0.5)
    precondition(kp.keypointColorValue == 0.5)
    kp = MPSImageKeypointData()
    precondition(kp.keypointCoordinate.x == 0)
    var range = MPSImageKeypointRangeInfo(maximumKeypoints: 10, minimumThresholdValue: 0.2)
    precondition(range.maximumKeypoints == 10)
    range = MPSImageKeypointRangeInfo()
    precondition(range.minimumThresholdValue == 0)
    var args = MPSCustomKernelArgumentCount(destinationTextureCount: 2, sourceTextureCount: 3, broadcastTextureCount: 1)
    precondition(args.sourceTextureCount == 3)
    args = MPSCustomKernelArgumentCount()
    precondition(args.destinationTextureCount == 1)
    var info = MPSCustomKernelInfo()
    precondition(info.sourceImageCount == 0)
    info = MPSCustomKernelInfo(
        clipOrigin: .zero,
        clipSize: vector_ushort4(1, 1, 1, 1),
        destinationFeatureChannels: 4,
        destImageArraySize: 1,
        sourceImageCount: 1,
        threadgroupSize: 8,
        subbatchIndex: 0,
        subbatchStride: 1,
        idiv: MPSIntegerDivisionParams()
    )
    precondition(info.threadgroupSize == 8)
    var srcInfo = MPSCustomKernelSourceInfo()
    srcInfo = MPSCustomKernelSourceInfo(
        kernelOrigin: .zero,
        kernelPhase: .zero,
        kernelSize: vector_ushort2(3, 3),
        offset: .zero,
        stride: vector_ushort2(1, 1),
        dilationRate: .zero,
        featureChannelOffset: 0,
        featureChannels: 4,
        imageArrayOffset: 0,
        imageArraySize: 1
    )
    precondition(srcInfo.featureChannels == 4)
    var tex = MPSStateTextureInfo()
    tex.width = 8
    tex.height = 4
    tex.pixelFormat = .rgba8Unorm
    tex.textureType = .type2D
    tex.usage = [.shaderRead]
    precondition(tex.width == 8)
}

func testMPSCustomKernelHelpers() {
    let params = MPSFindIntegerDivisionParams(7)
    precondition(params.divisor == 7)
    precondition(params.recip > 0)
    let one = MPSFindIntegerDivisionParams(1)
    precondition(one.divisor == 1 && one.recip == 1)
    let args = MPSCustomKernelArgumentCount(destinationTextureCount: 1, sourceTextureCount: 2, broadcastTextureCount: 1)
    let maxBatch = MPSGetCustomKernelMaxBatchSize(args, 16)
    precondition(maxBatch == 16 / 3)
    precondition(MPSGetCustomKernelBatchedDestinationIndex(args) == 0)
    let src = MPSGetCustomKernelBatchedSourceIndex(args, 1, 16)
    precondition(src == 1 * maxBatch + 1 * maxBatch)
    let broadcast = MPSGetCustomKernelBroadcastSourceIndex(args, 0, 16)
    precondition(broadcast >= src)
}

func testMPSPackedAndRayStructs() {
    var packed = MPSPackedFloat3(x: 1, y: 2, z: 3)
    precondition(packed.x == 1 && packed.y == 2 && packed.z == 3)
    packed.elements = (4, 5, 6)
    precondition(packed.x == 4 && packed.elements.2 == 6)
    packed = MPSPackedFloat3(elements: (7, 8, 9))
    precondition(packed.y == 8)
    packed = MPSPackedFloat3()
    precondition(packed.z == 0)
    var box = MPSAxisAlignedBoundingBox(min: vector_float3(0, 0, 0), max: vector_float3(1, 1, 1))
    precondition(box.max.x == 1)
    box = MPSAxisAlignedBoundingBox()
    precondition(box.min.y == 0)
    var ray = MPSRayOriginDirection(origin: vector_float3(1, 0, 0), direction: vector_float3(0, 1, 0))
    precondition(ray.origin.x == 1)
    ray = MPSRayOriginDirection()
    precondition(ray.direction.y == 0)
    var packedRay = MPSRayPackedOriginDirection(
        origin: MPSPackedFloat3(x: 1, y: 0, z: 0),
        direction: MPSPackedFloat3(x: 0, y: 1, z: 0)
    )
    precondition(packedRay.origin.x == 1)
    packedRay = MPSRayPackedOriginDirection()
    precondition(packedRay.direction.y == 0)
    var masked = MPSRayOriginMaskDirectionMaxDistance(
        origin: MPSPackedFloat3(),
        mask: 0xFF,
        direction: MPSPackedFloat3(x: 0, y: 0, z: 1),
        maxDistance: 10
    )
    precondition(masked.mask == 0xFF && masked.maxDistance == 10)
    masked = MPSRayOriginMaskDirectionMaxDistance()
    precondition(masked.maxDistance == 0)
    var ranged = MPSRayOriginMinDistanceDirectionMaxDistance(
        origin: MPSPackedFloat3(),
        minDistance: 0.1,
        direction: MPSPackedFloat3(x: 0, y: 1, z: 0),
        maxDistance: 5
    )
    precondition(ranged.minDistance == 0.1)
    ranged = MPSRayOriginMinDistanceDirectionMaxDistance()
    precondition(ranged.maxDistance == 0)
    var dist = MPSIntersectionDistance(distance: 3)
    precondition(dist.distance == 3)
    dist = MPSIntersectionDistance()
    precondition(dist.distance == 0)
    var prim = MPSIntersectionDistancePrimitiveIndex(distance: 1, primitiveIndex: 2)
    precondition(prim.primitiveIndex == 2)
    prim = MPSIntersectionDistancePrimitiveIndex()
    precondition(prim.distance == 0)
    var coords = MPSIntersectionDistancePrimitiveIndexCoordinates(
        distance: 1,
        primitiveIndex: 2,
        coordinates: vector_float2(0.3, 0.7)
    )
    precondition(coords.coordinates.y == 0.7)
    coords = MPSIntersectionDistancePrimitiveIndexCoordinates()
    precondition(coords.primitiveIndex == 0)
    var inst = MPSIntersectionDistancePrimitiveIndexInstanceIndex(
        distance: 1,
        primitiveIndex: 2,
        instanceIndex: 3
    )
    precondition(inst.instanceIndex == 3)
    inst = MPSIntersectionDistancePrimitiveIndexInstanceIndex()
    var instc = MPSIntersectionDistancePrimitiveIndexInstanceIndexCoordinates(
        distance: 1,
        primitiveIndex: 2,
        instanceIndex: 3,
        coordinates: .zero
    )
    precondition(instc.instanceIndex == 3)
    instc = MPSIntersectionDistancePrimitiveIndexInstanceIndexCoordinates()
    var buf = MPSIntersectionDistancePrimitiveIndexBufferIndex(
        distance: 1,
        primitiveIndex: 2,
        bufferIndex: 4
    )
    precondition(buf.bufferIndex == 4)
    buf = MPSIntersectionDistancePrimitiveIndexBufferIndex()
    var bufc = MPSIntersectionDistancePrimitiveIndexBufferIndexCoordinates(
        distance: 1,
        primitiveIndex: 2,
        bufferIndex: 4,
        coordinates: .zero
    )
    precondition(bufc.bufferIndex == 4)
    bufc = MPSIntersectionDistancePrimitiveIndexBufferIndexCoordinates()
    var bufi = MPSIntersectionDistancePrimitiveIndexBufferIndexInstanceIndex(
        distance: 1,
        primitiveIndex: 2,
        bufferIndex: 4,
        instanceIndex: 5
    )
    precondition(bufi.instanceIndex == 5)
    bufi = MPSIntersectionDistancePrimitiveIndexBufferIndexInstanceIndex()
    var all = MPSIntersectionDistancePrimitiveIndexBufferIndexInstanceIndexCoordinates(
        distance: 1,
        primitiveIndex: 2,
        bufferIndex: 4,
        instanceIndex: 5,
        coordinates: vector_float2(1, 0)
    )
    precondition(all.coordinates.x == 1)
    all = MPSIntersectionDistancePrimitiveIndexBufferIndexInstanceIndexCoordinates()
    precondition(all.distance == 0)
}
