import Foundation

/// Packed 4×3 transform used by acceleration-structure instance descriptors.
/// This is CPU-side instance data. Linux does not build BLAS/TLAS on a GPU.
public struct _MTLPackedFloat4x3: Equatable, Sendable {
    public var columns: (MTLPackedFloat3, MTLPackedFloat3, MTLPackedFloat3, MTLPackedFloat3)

    public init() {
        self.columns = (MTLPackedFloat3(), MTLPackedFloat3(), MTLPackedFloat3(), MTLPackedFloat3())
    }

    public init(columns: (MTLPackedFloat3, MTLPackedFloat3, MTLPackedFloat3, MTLPackedFloat3)) {
        self.columns = columns
    }

    public static func == (lhs: _MTLPackedFloat4x3, rhs: _MTLPackedFloat4x3) -> Bool {
        lhs.columns.0 == rhs.columns.0
            && lhs.columns.1 == rhs.columns.1
            && lhs.columns.2 == rhs.columns.2
            && lhs.columns.3 == rhs.columns.3
    }
}

public typealias MTLPackedFloat4x3 = _MTLPackedFloat4x3

public struct MTLAccelerationStructureSizes: Equatable, Hashable, Sendable {
    public var accelerationStructureSize: Int
    public var buildScratchBufferSize: Int
    public var refitScratchBufferSize: Int

    public init() {
        self.accelerationStructureSize = 0
        self.buildScratchBufferSize = 0
        self.refitScratchBufferSize = 0
    }

    public init(
        accelerationStructureSize: Int,
        buildScratchBufferSize: Int,
        refitScratchBufferSize: Int
    ) {
        self.accelerationStructureSize = accelerationStructureSize
        self.buildScratchBufferSize = buildScratchBufferSize
        self.refitScratchBufferSize = refitScratchBufferSize
    }
}

public struct MTLAccelerationStructureInstanceDescriptor: Equatable, Sendable {
    public var transformationMatrix: MTLPackedFloat4x3
    public var options: MTLAccelerationStructureInstanceOptions
    public var mask: UInt32
    public var intersectionFunctionTableOffset: UInt32
    public var accelerationStructureIndex: UInt32

    public init() {
        self.transformationMatrix = MTLPackedFloat4x3()
        self.options = []
        self.mask = 0
        self.intersectionFunctionTableOffset = 0
        self.accelerationStructureIndex = 0
    }

    public init(
        transformationMatrix: MTLPackedFloat4x3,
        options: MTLAccelerationStructureInstanceOptions,
        mask: UInt32,
        intersectionFunctionTableOffset: UInt32,
        accelerationStructureIndex: UInt32
    ) {
        self.transformationMatrix = transformationMatrix
        self.options = options
        self.mask = mask
        self.intersectionFunctionTableOffset = intersectionFunctionTableOffset
        self.accelerationStructureIndex = accelerationStructureIndex
    }
}

public struct MTLAccelerationStructureUserIDInstanceDescriptor: Equatable, Sendable {
    public var transformationMatrix: MTLPackedFloat4x3
    public var options: MTLAccelerationStructureInstanceOptions
    public var mask: UInt32
    public var intersectionFunctionTableOffset: UInt32
    public var accelerationStructureIndex: UInt32
    public var userID: UInt32

    public init() {
        self.transformationMatrix = MTLPackedFloat4x3()
        self.options = []
        self.mask = 0
        self.intersectionFunctionTableOffset = 0
        self.accelerationStructureIndex = 0
        self.userID = 0
    }

    public init(
        transformationMatrix: MTLPackedFloat4x3,
        options: MTLAccelerationStructureInstanceOptions,
        mask: UInt32,
        intersectionFunctionTableOffset: UInt32,
        accelerationStructureIndex: UInt32,
        userID: UInt32
    ) {
        self.transformationMatrix = transformationMatrix
        self.options = options
        self.mask = mask
        self.intersectionFunctionTableOffset = intersectionFunctionTableOffset
        self.accelerationStructureIndex = accelerationStructureIndex
        self.userID = userID
    }
}

public struct MTLAccelerationStructureMotionInstanceDescriptor: Equatable, Sendable {
    public var options: MTLAccelerationStructureInstanceOptions
    public var mask: UInt32
    public var intersectionFunctionTableOffset: UInt32
    public var accelerationStructureIndex: UInt32
    public var userID: UInt32
    public var motionTransformsStartIndex: UInt32
    public var motionTransformsCount: UInt32
    public var motionStartTime: Float
    public var motionEndTime: Float
    public var motionStartBorderMode: MTLMotionBorderMode
    public var motionEndBorderMode: MTLMotionBorderMode

    public init() {
        self.options = []
        self.mask = 0
        self.intersectionFunctionTableOffset = 0
        self.accelerationStructureIndex = 0
        self.userID = 0
        self.motionTransformsStartIndex = 0
        self.motionTransformsCount = 0
        self.motionStartTime = 0
        self.motionEndTime = 1
        self.motionStartBorderMode = .clamp
        self.motionEndBorderMode = .clamp
    }
}

public struct MTLIndirectAccelerationStructureInstanceDescriptor: Equatable, Sendable {
    public var transformationMatrix: MTLPackedFloat4x3
    public var options: MTLAccelerationStructureInstanceOptions
    public var mask: UInt32
    public var intersectionFunctionTableOffset: UInt32
    public var userID: UInt32
    public var accelerationStructureID: MTLResourceID

    public init() {
        self.transformationMatrix = MTLPackedFloat4x3()
        self.options = []
        self.mask = 0
        self.intersectionFunctionTableOffset = 0
        self.userID = 0
        self.accelerationStructureID = MTLResourceID()
    }

    public init(
        transformationMatrix: MTLPackedFloat4x3,
        options: MTLAccelerationStructureInstanceOptions,
        mask: UInt32,
        intersectionFunctionTableOffset: UInt32,
        userID: UInt32,
        accelerationStructureID: MTLResourceID
    ) {
        self.transformationMatrix = transformationMatrix
        self.options = options
        self.mask = mask
        self.intersectionFunctionTableOffset = intersectionFunctionTableOffset
        self.userID = userID
        self.accelerationStructureID = accelerationStructureID
    }
}

public struct MTLIndirectAccelerationStructureMotionInstanceDescriptor: Equatable, Sendable {
    public var options: MTLAccelerationStructureInstanceOptions
    public var mask: UInt32
    public var intersectionFunctionTableOffset: UInt32
    public var userID: UInt32
    public var accelerationStructureID: MTLResourceID
    public var motionTransformsStartIndex: UInt32
    public var motionTransformsCount: UInt32
    public var motionStartTime: Float
    public var motionEndTime: Float
    public var motionStartBorderMode: MTLMotionBorderMode
    public var motionEndBorderMode: MTLMotionBorderMode

    public init() {
        self.options = []
        self.mask = 0
        self.intersectionFunctionTableOffset = 0
        self.userID = 0
        self.accelerationStructureID = MTLResourceID()
        self.motionTransformsStartIndex = 0
        self.motionTransformsCount = 0
        self.motionStartTime = 0
        self.motionEndTime = 1
        self.motionStartBorderMode = .clamp
        self.motionEndBorderMode = .clamp
    }
}
