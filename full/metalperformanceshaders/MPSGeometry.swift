import Foundation

public typealias vector_ushort2 = SIMD2<UInt16>
public typealias vector_short2 = SIMD2<Int16>

public struct MPSOffset: Equatable, Sendable {
    public var x: Int
    public var y: Int
    public var z: Int

    public init(x: Int, y: Int, z: Int) {
        self.x = x
        self.y = y
        self.z = z
    }

    public init() {
        self.init(x: 0, y: 0, z: 0)
    }
}

public struct MPSOrigin: Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var z: Double

    public init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }

    public init() {
        self.init(x: 0, y: 0, z: 0)
    }
}

public struct MPSSize: Equatable, Sendable {
    public var width: Double
    public var height: Double
    public var depth: Double

    public init(width: Double, height: Double, depth: Double) {
        self.width = width
        self.height = height
        self.depth = depth
    }

    public init() {
        self.init(width: 0, height: 0, depth: 0)
    }
}

public struct MPSRegion: Equatable, Sendable {
    public var origin: MPSOrigin
    public var size: MPSSize

    public init(origin: MPSOrigin, size: MPSSize) {
        self.origin = origin
        self.size = size
    }

    public init() {
        self.init(origin: MPSOrigin(), size: MPSSize())
    }
}

public struct MPSScaleTransform: Equatable, Sendable {
    public var scaleX: Double
    public var scaleY: Double
    public var translateX: Double
    public var translateY: Double

    public init(scaleX: Double, scaleY: Double, translateX: Double, translateY: Double) {
        self.scaleX = scaleX
        self.scaleY = scaleY
        self.translateX = translateX
        self.translateY = translateY
    }

    public init() {
        self.init(scaleX: 1, scaleY: 1, translateX: 0, translateY: 0)
    }
}

public struct MPSImageCoordinate: Equatable, Sendable {
    public var x: Int
    public var y: Int
    public var channel: Int

    public init(x: Int, y: Int, channel: Int) {
        self.x = x
        self.y = y
        self.channel = channel
    }

    public init() {
        self.init(x: 0, y: 0, channel: 0)
    }
}

public struct MPSImageRegion: Equatable, Sendable {
    public var offset: MPSImageCoordinate
    public var size: MPSImageCoordinate

    public init(offset: MPSImageCoordinate, size: MPSImageCoordinate) {
        self.offset = offset
        self.size = size
    }

    public init() {
        self.init(offset: MPSImageCoordinate(), size: MPSImageCoordinate())
    }
}

public struct MPSImageReadWriteParams: Equatable, Sendable {
    public var featureChannelOffset: Int
    public var numberOfFeatureChannelsToReadWrite: Int

    public init(featureChannelOffset: Int, numberOfFeatureChannelsToReadWrite: Int) {
        self.featureChannelOffset = featureChannelOffset
        self.numberOfFeatureChannelsToReadWrite = numberOfFeatureChannelsToReadWrite
    }

    public init() {
        self.init(featureChannelOffset: 0, numberOfFeatureChannelsToReadWrite: 0)
    }
}

public struct MPSIntegerDivisionParams: Equatable, Sendable {
    public var divisor: UInt16
    public var recip: UInt16
    public var addend: UInt16
    public var shift: UInt16

    public init(divisor: UInt16, recip: UInt16, addend: UInt16, shift: UInt16) {
        self.divisor = divisor
        self.recip = recip
        self.addend = addend
        self.shift = shift
    }

    public init() {
        self.init(divisor: 1, recip: 1, addend: 0, shift: 0)
    }
}

public struct MPSDimensionSlice: Equatable, Sendable {
    public var start: Int
    public var length: Int

    public init(start: Int, length: Int) {
        self.start = start
        self.length = length
    }

    public init() {
        self.init(start: 0, length: 0)
    }
}

public struct MPSMatrixOffset: Equatable, Sendable {
    public var rowOffset: UInt32
    public var columnOffset: UInt32

    public init(rowOffset: UInt32, columnOffset: UInt32) {
        self.rowOffset = rowOffset
        self.columnOffset = columnOffset
    }

    public init() {
        self.init(rowOffset: 0, columnOffset: 0)
    }
}

public struct MPSMatrixCopyOffsets: Equatable, Sendable {
    public var sourceRowOffset: UInt32
    public var sourceColumnOffset: UInt32
    public var destinationRowOffset: UInt32
    public var destinationColumnOffset: UInt32

    public init(
        sourceRowOffset: UInt32,
        sourceColumnOffset: UInt32,
        destinationRowOffset: UInt32,
        destinationColumnOffset: UInt32
    ) {
        self.sourceRowOffset = sourceRowOffset
        self.sourceColumnOffset = sourceColumnOffset
        self.destinationRowOffset = destinationRowOffset
        self.destinationColumnOffset = destinationColumnOffset
    }

    public init() {
        self.init(
            sourceRowOffset: 0,
            sourceColumnOffset: 0,
            destinationRowOffset: 0,
            destinationColumnOffset: 0
        )
    }
}

public struct MPSNDArrayOffsets: Sendable {
    public var dimensions: (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int)

    public init(
        dimensions: (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int)
    ) {
        self.dimensions = dimensions
    }

    public init() {
        self.init(dimensions: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
    }
}

public struct MPSNDArraySizes: Sendable {
    public var dimensions: (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int)

    public init(
        dimensions: (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int)
    ) {
        self.dimensions = dimensions
    }

    public init() {
        self.init(dimensions: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
    }
}

public struct MPSImageHistogramInfo: Equatable, Sendable {
    public var numberOfHistogramEntries: Int
    public var histogramForAlpha: ObjCBool
    public var minPixelValue: vector_float4
    public var maxPixelValue: vector_float4

    public init(
        numberOfHistogramEntries: Int,
        histogramForAlpha: ObjCBool,
        minPixelValue: vector_float4,
        maxPixelValue: vector_float4
    ) {
        self.numberOfHistogramEntries = numberOfHistogramEntries
        self.histogramForAlpha = histogramForAlpha
        self.minPixelValue = minPixelValue
        self.maxPixelValue = maxPixelValue
    }

    public init() {
        self.init(
            numberOfHistogramEntries: 256,
            histogramForAlpha: ObjCBool(false),
            minPixelValue: vector_float4(0, 0, 0, 0),
            maxPixelValue: vector_float4(1, 1, 1, 1)
        )
    }

    public static func == (lhs: MPSImageHistogramInfo, rhs: MPSImageHistogramInfo) -> Bool {
        lhs.numberOfHistogramEntries == rhs.numberOfHistogramEntries
            && lhs.histogramForAlpha.boolValue == rhs.histogramForAlpha.boolValue
            && lhs.minPixelValue == rhs.minPixelValue
            && lhs.maxPixelValue == rhs.maxPixelValue
    }
}

public struct MPSImageKeypointData: Equatable, Sendable {
    public var keypointCoordinate: vector_ushort2
    public var keypointColorValue: Float

    public init(keypointCoordinate: vector_ushort2, keypointColorValue: Float) {
        self.keypointCoordinate = keypointCoordinate
        self.keypointColorValue = keypointColorValue
    }

    public init() {
        self.init(keypointCoordinate: vector_ushort2(0, 0), keypointColorValue: 0)
    }
}

public struct MPSImageKeypointRangeInfo: Equatable, Sendable {
    public var maximumKeypoints: Int
    public var minimumThresholdValue: Float

    public init(maximumKeypoints: Int, minimumThresholdValue: Float) {
        self.maximumKeypoints = maximumKeypoints
        self.minimumThresholdValue = minimumThresholdValue
    }

    public init() {
        self.init(maximumKeypoints: 0, minimumThresholdValue: 0)
    }
}

public struct MPSCustomKernelArgumentCount: Equatable, Sendable {
    public var destinationTextureCount: UInt
    public var sourceTextureCount: UInt
    public var broadcastTextureCount: UInt

    public init(destinationTextureCount: UInt, sourceTextureCount: UInt, broadcastTextureCount: UInt) {
        self.destinationTextureCount = destinationTextureCount
        self.sourceTextureCount = sourceTextureCount
        self.broadcastTextureCount = broadcastTextureCount
    }

    public init() {
        self.init(destinationTextureCount: 1, sourceTextureCount: 1, broadcastTextureCount: 0)
    }
}

public struct MPSCustomKernelIndex: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: UInt32) {
        self.rawValue = rawValue
    }
}

public var MPSCustomKernelIndexDestIndex: MPSCustomKernelIndex { MPSCustomKernelIndex(0) }
public var MPSCustomKernelIndexSrc0Index: MPSCustomKernelIndex { MPSCustomKernelIndex(1) }
public var MPSCustomKernelIndexSrc1Index: MPSCustomKernelIndex { MPSCustomKernelIndex(2) }
public var MPSCustomKernelIndexSrc2Index: MPSCustomKernelIndex { MPSCustomKernelIndex(3) }
public var MPSCustomKernelIndexSrc3Index: MPSCustomKernelIndex { MPSCustomKernelIndex(4) }
public var MPSCustomKernelIndexSrc4Index: MPSCustomKernelIndex { MPSCustomKernelIndex(5) }
public var MPSCustomKernelIndexUserDataIndex: MPSCustomKernelIndex { MPSCustomKernelIndex(6) }

public struct MPSImageType: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: UInt32) {
        self.rawValue = rawValue
    }
}

public var MPSImageType2d: MPSImageType { MPSImageType(0) }
public var MPSImageType2d_array: MPSImageType { MPSImageType(1) }
public var MPSImageTypeArray2d: MPSImageType { MPSImageType(2) }
public var MPSImageTypeArray2d_array: MPSImageType { MPSImageType(3) }
public var MPSImageType2d_noAlpha: MPSImageType { MPSImageType(4) }
public var MPSImageType2d_array_noAlpha: MPSImageType { MPSImageType(5) }
public var MPSImageTypeArray2d_noAlpha: MPSImageType { MPSImageType(6) }
public var MPSImageTypeArray2d_array_noAlpha: MPSImageType { MPSImageType(7) }
public var MPSImageType_typeMask: MPSImageType { MPSImageType(0x3) }
public var MPSImageType_noAlpha: MPSImageType { MPSImageType(0x4) }
public var MPSImageType_ArrayMask: MPSImageType { MPSImageType(0x8) }
public var MPSImageType_BatchMask: MPSImageType { MPSImageType(0x10) }
public var MPSImageType_mask: MPSImageType { MPSImageType(0x1F) }
public var MPSImageType_texelFormatShift: MPSImageType { MPSImageType(5) }
public var MPSImageType_texelFormatMask: MPSImageType { MPSImageType(0xE0) }
public var MPSImageType_texelFormatStandard: MPSImageType { MPSImageType(0) }
public var MPSImageType_texelFormatUnorm8: MPSImageType { MPSImageType(1 << 5) }
public var MPSImageType_texelFormatFloat16: MPSImageType { MPSImageType(2 << 5) }
public var MPSImageType_texelFormatBFloat16: MPSImageType { MPSImageType(3 << 5) }
public var MPSImageType_bitCount: MPSImageType { MPSImageType(8) }

public struct MPSDeviceCapsValues: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: UInt32) {
        self.rawValue = rawValue
    }
}

public var MPSDeviceCapsNull: MPSDeviceCapsValues { MPSDeviceCapsValues(0) }
public var MPSDeviceIsAppleDevice: MPSDeviceCapsValues { MPSDeviceCapsValues(1 << 0) }
public var MPSDeviceSupportsFloat32Filtering: MPSDeviceCapsValues { MPSDeviceCapsValues(1 << 1) }
public var MPSDeviceSupportsSimdShuffle: MPSDeviceCapsValues { MPSDeviceCapsValues(1 << 2) }
public var MPSDeviceSupportsSimdReduction: MPSDeviceCapsValues { MPSDeviceCapsValues(1 << 3) }
public var MPSDeviceSupportsQuadShuffle: MPSDeviceCapsValues { MPSDeviceCapsValues(1 << 4) }
public var MPSDeviceSupportsSimdShuffleAndFill: MPSDeviceCapsValues { MPSDeviceCapsValues(1 << 5) }
public var MPSDeviceSupportsSimdgroupBarrier: MPSDeviceCapsValues { MPSDeviceCapsValues(1 << 6) }
public var MPSDeviceSupportsReadWriteTextures: MPSDeviceCapsValues { MPSDeviceCapsValues(1 << 7) }
public var MPSDeviceSupportsReadableArrayOfTextures: MPSDeviceCapsValues { MPSDeviceCapsValues(1 << 8) }
public var MPSDeviceSupportsWritableArrayOfTextures: MPSDeviceCapsValues { MPSDeviceCapsValues(1 << 9) }
public var MPSDeviceSupportsNorm16BicubicFiltering: MPSDeviceCapsValues { MPSDeviceCapsValues(1 << 10) }
public var MPSDeviceSupportsFloat16BicubicFiltering: MPSDeviceCapsValues { MPSDeviceCapsValues(1 << 11) }
public var MPSDeviceSupportsBFloat16Arithmetic: MPSDeviceCapsValues { MPSDeviceCapsValues(1 << 12) }
public var MPSDeviceCapsLast: MPSDeviceCapsValues { MPSDeviceCapsValues(1 << 13) }

public struct MPSStateTextureInfo: Equatable, Sendable {
    public var width: Int
    public var height: Int
    public var depth: Int
    public var arrayLength: Int
    public var pixelFormat: MTLPixelFormat
    public var textureType: MTLTextureType
    public var usage: MTLTextureUsage

    public init() {
        self.width = 0
        self.height = 0
        self.depth = 1
        self.arrayLength = 1
        self.pixelFormat = .invalid
        self.textureType = .type2D
        self.usage = []
    }
}

public struct MPSCustomKernelInfo: Equatable, Sendable {
    public var clipOrigin: vector_ushort4
    public var clipSize: vector_ushort4
    public var destinationFeatureChannels: UInt16
    public var destImageArraySize: UInt16
    public var sourceImageCount: UInt16
    public var threadgroupSize: UInt16
    public var subbatchIndex: UInt16
    public var subbatchStride: UInt16
    public var idiv: MPSIntegerDivisionParams

    public init(
        clipOrigin: vector_ushort4,
        clipSize: vector_ushort4,
        destinationFeatureChannels: UInt16,
        destImageArraySize: UInt16,
        sourceImageCount: UInt16,
        threadgroupSize: UInt16,
        subbatchIndex: UInt16,
        subbatchStride: UInt16,
        idiv: MPSIntegerDivisionParams
    ) {
        self.clipOrigin = clipOrigin
        self.clipSize = clipSize
        self.destinationFeatureChannels = destinationFeatureChannels
        self.destImageArraySize = destImageArraySize
        self.sourceImageCount = sourceImageCount
        self.threadgroupSize = threadgroupSize
        self.subbatchIndex = subbatchIndex
        self.subbatchStride = subbatchStride
        self.idiv = idiv
    }

    public init() {
        self.init(
            clipOrigin: .zero,
            clipSize: .zero,
            destinationFeatureChannels: 0,
            destImageArraySize: 0,
            sourceImageCount: 0,
            threadgroupSize: 0,
            subbatchIndex: 0,
            subbatchStride: 0,
            idiv: MPSIntegerDivisionParams()
        )
    }
}

public struct MPSCustomKernelSourceInfo: Equatable, Sendable {
    public var kernelOrigin: vector_short2
    public var kernelPhase: vector_ushort2
    public var kernelSize: vector_ushort2
    public var offset: vector_short2
    public var stride: vector_ushort2
    public var dilationRate: vector_ushort2
    public var featureChannelOffset: UInt16
    public var featureChannels: UInt16
    public var imageArrayOffset: UInt16
    public var imageArraySize: UInt16

    public init(
        kernelOrigin: vector_short2,
        kernelPhase: vector_ushort2,
        kernelSize: vector_ushort2,
        offset: vector_short2,
        stride: vector_ushort2,
        dilationRate: vector_ushort2,
        featureChannelOffset: UInt16,
        featureChannels: UInt16,
        imageArrayOffset: UInt16,
        imageArraySize: UInt16
    ) {
        self.kernelOrigin = kernelOrigin
        self.kernelPhase = kernelPhase
        self.kernelSize = kernelSize
        self.offset = offset
        self.stride = stride
        self.dilationRate = dilationRate
        self.featureChannelOffset = featureChannelOffset
        self.featureChannels = featureChannels
        self.imageArrayOffset = imageArrayOffset
        self.imageArraySize = imageArraySize
    }

    public init() {
        self.init(
            kernelOrigin: .zero,
            kernelPhase: .zero,
            kernelSize: .zero,
            offset: .zero,
            stride: .zero,
            dilationRate: .zero,
            featureChannelOffset: 0,
            featureChannels: 0,
            imageArrayOffset: 0,
            imageArraySize: 0
        )
    }
}

public func MPSFindIntegerDivisionParams(_ divisor: UInt16) -> MPSIntegerDivisionParams {
    if divisor <= 1 {
        return MPSIntegerDivisionParams(divisor: 1, recip: 1, addend: 0, shift: 0)
    }
    let d = UInt32(divisor)
    var shift: UInt32 = 0
    while (d << shift) < 0x1_0000 && shift < 15 {
        shift += 1
    }
    let scaled = (UInt32(1) << (16 + shift)) / d
    let recip = UInt16(min(scaled, 0xFFFF))
    return MPSIntegerDivisionParams(
        divisor: divisor,
        recip: recip,
        addend: 0,
        shift: UInt16(shift)
    )
}

public func MPSGetCustomKernelMaxBatchSize(
    _ c: MPSCustomKernelArgumentCount,
    _ MPSMaxTextures: UInt
) -> UInt {
    let perSample = c.destinationTextureCount + c.sourceTextureCount
    if perSample == 0 { return 0 }
    return MPSMaxTextures / perSample
}

public func MPSGetCustomKernelBatchedDestinationIndex(
    _ c: MPSCustomKernelArgumentCount
) -> UInt {
    _ = c
    return 0
}

public func MPSGetCustomKernelBatchedSourceIndex(
    _ c: MPSCustomKernelArgumentCount,
    _ sourceIndex: UInt,
    _ MPSMaxTextures: UInt
) -> UInt {
    let batch = MPSGetCustomKernelMaxBatchSize(c, MPSMaxTextures)
    return c.destinationTextureCount * batch + sourceIndex * batch
}

public func MPSGetCustomKernelBroadcastSourceIndex(
    _ c: MPSCustomKernelArgumentCount,
    _ sourceIndex: UInt,
    _ MPSMaxTextures: UInt
) -> UInt {
    let batched = MPSGetCustomKernelBatchedSourceIndex(c, c.sourceTextureCount, MPSMaxTextures)
    return batched + sourceIndex
}
