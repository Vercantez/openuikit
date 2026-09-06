import Foundation

public struct MTLOrigin: Equatable, Hashable, Sendable {
    public var x: Int
    public var y: Int
    public var z: Int

    public init() {
        self.x = 0
        self.y = 0
        self.z = 0
    }

    public init(x: Int, y: Int, z: Int) {
        self.x = x
        self.y = y
        self.z = z
    }
}

public func MTLOriginMake(_ x: Int, _ y: Int, _ z: Int) -> MTLOrigin {
    MTLOrigin(x: x, y: y, z: z)
}

public struct MTLSize: Equatable, Hashable, Sendable {
    public var width: Int
    public var height: Int
    public var depth: Int

    public init() {
        self.width = 0
        self.height = 0
        self.depth = 0
    }

    public init(width: Int, height: Int, depth: Int) {
        self.width = width
        self.height = height
        self.depth = depth
    }
}

public func MTLSizeMake(_ width: Int, _ height: Int, _ depth: Int) -> MTLSize {
    MTLSize(width: width, height: height, depth: depth)
}

public struct MTLRegion: Equatable, Hashable, Sendable {
    public var origin: MTLOrigin
    public var size: MTLSize

    public init() {
        self.origin = MTLOrigin()
        self.size = MTLSize()
    }

    public init(origin: MTLOrigin, size: MTLSize) {
        self.origin = origin
        self.size = size
    }
}

public func MTLRegionMake1D(_ x: Int, _ width: Int) -> MTLRegion {
    MTLRegion(
        origin: MTLOrigin(x: x, y: 0, z: 0),
        size: MTLSize(width: width, height: 1, depth: 1)
    )
}

public func MTLRegionMake2D(_ x: Int, _ y: Int, _ width: Int, _ height: Int) -> MTLRegion {
    MTLRegion(
        origin: MTLOrigin(x: x, y: y, z: 0),
        size: MTLSize(width: width, height: height, depth: 1)
    )
}

public func MTLRegionMake3D(
    _ x: Int,
    _ y: Int,
    _ z: Int,
    _ width: Int,
    _ height: Int,
    _ depth: Int
) -> MTLRegion {
    MTLRegion(
        origin: MTLOrigin(x: x, y: y, z: z),
        size: MTLSize(width: width, height: height, depth: depth)
    )
}

public struct MTLSizeAndAlign: Equatable, Hashable, Sendable {
    public var size: Int
    public var align: Int

    public init() {
        self.size = 0
        self.align = 0
    }

    public init(size: Int, align: Int) {
        self.size = size
        self.align = align
    }
}

public struct MTLClearColor: Equatable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double

    public init() {
        self.red = 0
        self.green = 0
        self.blue = 0
        self.alpha = 1
    }

    public init(red: Double, green: Double, blue: Double, alpha: Double) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}

public func MTLClearColorMake(
    _ red: Double,
    _ green: Double,
    _ blue: Double,
    _ alpha: Double
) -> MTLClearColor {
    MTLClearColor(red: red, green: green, blue: blue, alpha: alpha)
}

public struct MTLViewport: Equatable, Sendable {
    public var originX: Double
    public var originY: Double
    public var width: Double
    public var height: Double
    public var znear: Double
    public var zfar: Double

    public init() {
        self.originX = 0
        self.originY = 0
        self.width = 0
        self.height = 0
        self.znear = 0
        self.zfar = 1
    }

    public init(
        originX: Double,
        originY: Double,
        width: Double,
        height: Double,
        znear: Double,
        zfar: Double
    ) {
        self.originX = originX
        self.originY = originY
        self.width = width
        self.height = height
        self.znear = znear
        self.zfar = zfar
    }
}

public struct MTLScissorRect: Equatable, Hashable, Sendable {
    public var x: Int
    public var y: Int
    public var width: Int
    public var height: Int

    public init() {
        self.x = 0
        self.y = 0
        self.width = 0
        self.height = 0
    }

    public init(x: Int, y: Int, width: Int, height: Int) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

public struct MTLSamplePosition: Equatable, Sendable {
    public var x: Float
    public var y: Float

    public init() {
        self.x = 0
        self.y = 0
    }

    public init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }
}

public func MTLSamplePositionMake(_ x: Float, _ y: Float) -> MTLSamplePosition {
    MTLSamplePosition(x: x, y: y)
}

public func MTLCoordinate2DMake(_ x: Float, _ y: Float) -> MTLCoordinate2D {
    MTLSamplePosition(x: x, y: y)
}

public struct MTLIndirectCommandBufferExecutionRange: Equatable, Hashable, Sendable {
    public var location: UInt32
    public var length: UInt32

    public init() {
        self.location = 0
        self.length = 0
    }

    public init(location: UInt32, length: UInt32) {
        self.location = location
        self.length = length
    }
}

public func MTLIndirectCommandBufferExecutionRangeMake(
    _ location: UInt32,
    _ length: UInt32
) -> MTLIndirectCommandBufferExecutionRange {
    MTLIndirectCommandBufferExecutionRange(location: location, length: length)
}

public struct MTL4BufferRange: Equatable, Hashable, Sendable {
    public var bufferAddress: MTLGPUAddress
    public var length: UInt64

    public init() {
        self.bufferAddress = 0
        self.length = 0
    }

    public init(bufferAddress: MTLGPUAddress, length: UInt64) {
        self.bufferAddress = bufferAddress
        self.length = length
    }
}

public func MTL4BufferRangeMake(
    _ bufferAddress: MTLGPUAddress,
    _ length: UInt64
) -> MTL4BufferRange {
    MTL4BufferRange(bufferAddress: bufferAddress, length: length)
}

public struct MTLTextureSwizzleChannels: Equatable, Hashable, Sendable {
    public var red: MTLTextureSwizzle
    public var green: MTLTextureSwizzle
    public var blue: MTLTextureSwizzle
    public var alpha: MTLTextureSwizzle

    public init() {
        self.red = .red
        self.green = .green
        self.blue = .blue
        self.alpha = .alpha
    }

    public init(
        red: MTLTextureSwizzle,
        green: MTLTextureSwizzle,
        blue: MTLTextureSwizzle,
        alpha: MTLTextureSwizzle
    ) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}

public struct MTLVertexAmplificationViewMapping: Equatable, Hashable, Sendable {
    public var viewportArrayIndexOffset: UInt32
    public var renderTargetArrayIndexOffset: UInt32

    public init() {
        self.viewportArrayIndexOffset = 0
        self.renderTargetArrayIndexOffset = 0
    }

    public init(viewportArrayIndexOffset: UInt32, renderTargetArrayIndexOffset: UInt32) {
        self.viewportArrayIndexOffset = viewportArrayIndexOffset
        self.renderTargetArrayIndexOffset = renderTargetArrayIndexOffset
    }
}

open class MTLTensorExtents: NSObject, NSCopying, @unchecked Sendable {
    public let rank: Int
    public let extents: [Int]

    public override init() {
        self.rank = 0
        self.extents = []
        super.init()
    }

    public init(rank: Int, extents: [Int]) {
        self.rank = rank
        self.extents = extents
        super.init()
    }

    public convenience init?(_ values: [Int]) {
        guard values.allSatisfy({ $0 >= 0 }) else { return nil }
        self.init(rank: values.count, extents: values)
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        MTLTensorExtents(rank: rank, extents: extents)
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? MTLTensorExtents else { return false }
        return rank == other.rank && extents == other.extents
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(rank)
        hasher.combine(extents)
        return hasher.finalize()
    }
}

public struct MTLPackedFloatQuaternion: Equatable, Hashable, Sendable {
    public var x: Float
    public var y: Float
    public var z: Float
    public var w: Float

    public init() {
        self.x = 0
        self.y = 0
        self.z = 0
        self.w = 1
    }

    public init(x: Float, y: Float, z: Float, w: Float) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }
}

public struct MTLComponentTransform: Equatable, Sendable {
    public var scale: MTLPackedFloat3
    public var shear: MTLPackedFloat3
    public var pivot: MTLPackedFloat3
    public var rotation: MTLPackedFloatQuaternion
    public var translation: MTLPackedFloat3

    public init() {
        self.scale = MTLPackedFloat3Make(1, 1, 1)
        self.shear = MTLPackedFloat3()
        self.pivot = MTLPackedFloat3()
        self.rotation = MTLPackedFloatQuaternion()
        self.translation = MTLPackedFloat3()
    }

    public init(
        scale: MTLPackedFloat3,
        shear: MTLPackedFloat3,
        pivot: MTLPackedFloat3,
        rotation: MTLPackedFloatQuaternion,
        translation: MTLPackedFloat3
    ) {
        self.scale = scale
        self.shear = shear
        self.pivot = pivot
        self.rotation = rotation
        self.translation = translation
    }

    public static func == (lhs: MTLComponentTransform, rhs: MTLComponentTransform) -> Bool {
        lhs.scale == rhs.scale
            && lhs.shear == rhs.shear
            && lhs.pivot == rhs.pivot
            && lhs.rotation == rhs.rotation
            && lhs.translation == rhs.translation
    }
}

public struct MTLMapIndirectArguments: Equatable, Hashable, Sendable {
    public var regionOriginX: UInt32
    public var regionOriginY: UInt32
    public var regionOriginZ: UInt32
    public var regionSizeWidth: UInt32
    public var regionSizeHeight: UInt32
    public var regionSizeDepth: UInt32
    public var mipMapLevel: UInt32
    public var sliceId: UInt32

    public init() {
        self.regionOriginX = 0
        self.regionOriginY = 0
        self.regionOriginZ = 0
        self.regionSizeWidth = 0
        self.regionSizeHeight = 0
        self.regionSizeDepth = 0
        self.mipMapLevel = 0
        self.sliceId = 0
    }

    public init(
        regionOriginX: UInt32,
        regionOriginY: UInt32,
        regionOriginZ: UInt32,
        regionSizeWidth: UInt32,
        regionSizeHeight: UInt32,
        regionSizeDepth: UInt32,
        mipMapLevel: UInt32,
        sliceId: UInt32
    ) {
        self.regionOriginX = regionOriginX
        self.regionOriginY = regionOriginY
        self.regionOriginZ = regionOriginZ
        self.regionSizeWidth = regionSizeWidth
        self.regionSizeHeight = regionSizeHeight
        self.regionSizeDepth = regionSizeDepth
        self.mipMapLevel = mipMapLevel
        self.sliceId = sliceId
    }
}

public struct MTLDrawPrimitivesIndirectArguments: Equatable, Hashable, Sendable {
    public var vertexCount: UInt32
    public var instanceCount: UInt32
    public var vertexStart: UInt32
    public var baseInstance: UInt32

    public init() {
        self.vertexCount = 0
        self.instanceCount = 0
        self.vertexStart = 0
        self.baseInstance = 0
    }

    public init(vertexCount: UInt32, instanceCount: UInt32, vertexStart: UInt32, baseInstance: UInt32) {
        self.vertexCount = vertexCount
        self.instanceCount = instanceCount
        self.vertexStart = vertexStart
        self.baseInstance = baseInstance
    }
}

public struct MTLDrawIndexedPrimitivesIndirectArguments: Equatable, Hashable, Sendable {
    public var indexCount: UInt32
    public var instanceCount: UInt32
    public var indexStart: UInt32
    public var baseVertex: Int32
    public var baseInstance: UInt32

    public init() {
        self.indexCount = 0
        self.instanceCount = 0
        self.indexStart = 0
        self.baseVertex = 0
        self.baseInstance = 0
    }

    public init(
        indexCount: UInt32,
        instanceCount: UInt32,
        indexStart: UInt32,
        baseVertex: Int32,
        baseInstance: UInt32
    ) {
        self.indexCount = indexCount
        self.instanceCount = instanceCount
        self.indexStart = indexStart
        self.baseVertex = baseVertex
        self.baseInstance = baseInstance
    }
}

public struct MTLDrawPatchIndirectArguments: Equatable, Hashable, Sendable {
    public var patchCount: UInt32
    public var instanceCount: UInt32
    public var patchStart: UInt32
    public var baseInstance: UInt32

    public init() {
        self.patchCount = 0
        self.instanceCount = 0
        self.patchStart = 0
        self.baseInstance = 0
    }

    public init(patchCount: UInt32, instanceCount: UInt32, patchStart: UInt32, baseInstance: UInt32) {
        self.patchCount = patchCount
        self.instanceCount = instanceCount
        self.patchStart = patchStart
        self.baseInstance = baseInstance
    }
}
