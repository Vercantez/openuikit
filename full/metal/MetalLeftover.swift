import Foundation

// MARK: - Indirect-argument C structs
//
// Linux value mirrors of the Apple C structs used with indirect command
// buffers, tessellation factors, and stage-in regions. Array members are
// tuples exactly as in the Apple Swift overlay.

public struct _MTLAxisAlignedBoundingBox: Equatable, Sendable {
    public var min: MTLPackedFloat3
    public var max: MTLPackedFloat3

    public init() {
        self.min = MTLPackedFloat3()
        self.max = MTLPackedFloat3()
    }

    public init(min: MTLPackedFloat3, max: MTLPackedFloat3) {
        self.min = min
        self.max = max
    }
}

public typealias MTLAxisAlignedBoundingBox = _MTLAxisAlignedBoundingBox

public struct MTL4TimestampHeapEntry: Equatable, Hashable, Sendable {
    public var timestamp: UInt64

    public init() {
        self.timestamp = 0
    }

    public init(timestamp: UInt64) {
        self.timestamp = timestamp
    }
}

public struct MTLDispatchThreadgroupsIndirectArguments: Equatable, Hashable, Sendable {
    public var threadgroupsPerGrid: (UInt32, UInt32, UInt32)

    public init() {
        self.threadgroupsPerGrid = (0, 0, 0)
    }

    public init(threadgroupsPerGrid: (UInt32, UInt32, UInt32)) {
        self.threadgroupsPerGrid = threadgroupsPerGrid
    }

    public static func == (
        lhs: MTLDispatchThreadgroupsIndirectArguments,
        rhs: MTLDispatchThreadgroupsIndirectArguments
    ) -> Bool {
        lhs.threadgroupsPerGrid == rhs.threadgroupsPerGrid
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(threadgroupsPerGrid.0)
        hasher.combine(threadgroupsPerGrid.1)
        hasher.combine(threadgroupsPerGrid.2)
    }
}

public struct MTLDispatchThreadsIndirectArguments: Equatable, Hashable, Sendable {
    public var threadsPerGrid: (UInt32, UInt32, UInt32)
    public var threadsPerThreadgroup: (UInt32, UInt32, UInt32)

    public init() {
        self.threadsPerGrid = (0, 0, 0)
        self.threadsPerThreadgroup = (0, 0, 0)
    }

    public init(
        threadsPerGrid: (UInt32, UInt32, UInt32),
        threadsPerThreadgroup: (UInt32, UInt32, UInt32)
    ) {
        self.threadsPerGrid = threadsPerGrid
        self.threadsPerThreadgroup = threadsPerThreadgroup
    }

    public static func == (
        lhs: MTLDispatchThreadsIndirectArguments,
        rhs: MTLDispatchThreadsIndirectArguments
    ) -> Bool {
        lhs.threadsPerGrid == rhs.threadsPerGrid
            && lhs.threadsPerThreadgroup == rhs.threadsPerThreadgroup
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(threadsPerGrid.0)
        hasher.combine(threadsPerGrid.1)
        hasher.combine(threadsPerGrid.2)
        hasher.combine(threadsPerThreadgroup.0)
        hasher.combine(threadsPerThreadgroup.1)
        hasher.combine(threadsPerThreadgroup.2)
    }
}

public struct MTLIntersectionFunctionBufferArguments: Equatable, Hashable, Sendable {
    public var intersectionFunctionBuffer: UInt64
    public var intersectionFunctionBufferSize: UInt64
    public var intersectionFunctionStride: UInt64

    public init() {
        self.intersectionFunctionBuffer = 0
        self.intersectionFunctionBufferSize = 0
        self.intersectionFunctionStride = 0
    }

    public init(
        intersectionFunctionBuffer: UInt64,
        intersectionFunctionBufferSize: UInt64,
        intersectionFunctionStride: UInt64
    ) {
        self.intersectionFunctionBuffer = intersectionFunctionBuffer
        self.intersectionFunctionBufferSize = intersectionFunctionBufferSize
        self.intersectionFunctionStride = intersectionFunctionStride
    }
}

public struct MTLQuadTessellationFactorsHalf: Equatable, Hashable, Sendable {
    public var edgeTessellationFactor: (UInt16, UInt16, UInt16, UInt16)
    public var insideTessellationFactor: (UInt16, UInt16)

    public init() {
        self.edgeTessellationFactor = (0, 0, 0, 0)
        self.insideTessellationFactor = (0, 0)
    }

    public init(
        edgeTessellationFactor: (UInt16, UInt16, UInt16, UInt16),
        insideTessellationFactor: (UInt16, UInt16)
    ) {
        self.edgeTessellationFactor = edgeTessellationFactor
        self.insideTessellationFactor = insideTessellationFactor
    }

    public static func == (
        lhs: MTLQuadTessellationFactorsHalf,
        rhs: MTLQuadTessellationFactorsHalf
    ) -> Bool {
        lhs.edgeTessellationFactor == rhs.edgeTessellationFactor
            && lhs.insideTessellationFactor == rhs.insideTessellationFactor
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(edgeTessellationFactor.0)
        hasher.combine(edgeTessellationFactor.1)
        hasher.combine(edgeTessellationFactor.2)
        hasher.combine(edgeTessellationFactor.3)
        hasher.combine(insideTessellationFactor.0)
        hasher.combine(insideTessellationFactor.1)
    }
}

public struct MTLStageInRegionIndirectArguments: Equatable, Hashable, Sendable {
    public var stageInOrigin: (UInt32, UInt32, UInt32)
    public var stageInSize: (UInt32, UInt32, UInt32)

    public init() {
        self.stageInOrigin = (0, 0, 0)
        self.stageInSize = (0, 0, 0)
    }

    public init(
        stageInOrigin: (UInt32, UInt32, UInt32),
        stageInSize: (UInt32, UInt32, UInt32)
    ) {
        self.stageInOrigin = stageInOrigin
        self.stageInSize = stageInSize
    }

    public static func == (
        lhs: MTLStageInRegionIndirectArguments,
        rhs: MTLStageInRegionIndirectArguments
    ) -> Bool {
        lhs.stageInOrigin == rhs.stageInOrigin && lhs.stageInSize == rhs.stageInSize
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(stageInOrigin.0)
        hasher.combine(stageInOrigin.1)
        hasher.combine(stageInOrigin.2)
        hasher.combine(stageInSize.0)
        hasher.combine(stageInSize.1)
        hasher.combine(stageInSize.2)
    }
}

public struct MTLTriangleTessellationFactorsHalf: Equatable, Hashable, Sendable {
    public var edgeTessellationFactor: (UInt16, UInt16, UInt16)
    public var insideTessellationFactor: UInt16

    public init() {
        self.edgeTessellationFactor = (0, 0, 0)
        self.insideTessellationFactor = 0
    }

    public init(
        edgeTessellationFactor: (UInt16, UInt16, UInt16),
        insideTessellationFactor: UInt16
    ) {
        self.edgeTessellationFactor = edgeTessellationFactor
        self.insideTessellationFactor = insideTessellationFactor
    }

    public static func == (
        lhs: MTLTriangleTessellationFactorsHalf,
        rhs: MTLTriangleTessellationFactorsHalf
    ) -> Bool {
        lhs.edgeTessellationFactor == rhs.edgeTessellationFactor
            && lhs.insideTessellationFactor == rhs.insideTessellationFactor
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(edgeTessellationFactor.0)
        hasher.combine(edgeTessellationFactor.1)
        hasher.combine(edgeTessellationFactor.2)
        hasher.combine(insideTessellationFactor)
    }
}

// MARK: - Async pipeline completion handlers
//
// Stored and invoked synchronously by tests; the Linux reference never
// completes asynchronous GPU compilation.

public typealias MTL4NewBinaryFunctionCompletionHandler = (
    (any MTL4BinaryFunction)?,
    (any Error)?
) -> Void

public typealias MTL4NewMachineLearningPipelineStateCompletionHandler = (
    (any MTL4MachineLearningPipelineState)?,
    (any Error)?
) -> Void

public typealias MTLNewComputePipelineStateWithReflectionCompletionHandler = (
    (any MTLComputePipelineState)?,
    MTLComputePipelineReflection?,
    (any Error)?
) -> Void

public typealias MTLNewDynamicLibraryCompletionHandler = (
    (any MTLDynamicLibrary)?,
    (any Error)?
) -> Void

public typealias MTLNewRenderPipelineStateWithReflectionCompletionHandler = (
    (any MTLRenderPipelineState)?,
    MTLRenderPipelineReflection?,
    (any Error)?
) -> Void

// MARK: - IO compression context (fail-closed)
//
// Linux has no Apple IO compression backend. Context creation fails closed
// with nil, appends are inert, and flush reports `.error`. The default chunk
// size (65536) is pinned by an Apple-oracle probe of the iPhoneOS 26.1 SDK.

public typealias MTLIOCompressionContext = UnsafeMutableRawPointer

public func MTLIOCompressionContextDefaultChunkSize() -> Int {
    65536
}

public func MTLIOCreateCompressionContext(
    _ path: String,
    _ type: MTLIOCompressionMethod,
    _ chunkSize: Int
) -> MTLIOCompressionContext? {
    _ = (path, type, chunkSize)
    return nil
}

public func MTLIOCompressionContextAppendData(
    _ context: MTLIOCompressionContext,
    _ data: UnsafeRawPointer,
    _ size: Int
) {
    _ = (context, data, size)
}

public func MTLIOFlushAndDestroyCompressionContext(
    _ context: MTLIOCompressionContext
) -> MTLIOCompressionStatus {
    _ = context
    return .error
}

// MARK: - Function log value object

public final class LinuxMTLFunctionLog: NSObject, MTLFunctionLog, @unchecked Sendable {
    public let type: MTLFunctionLogType
    public let encoderLabel: String?
    public let function: (any MTLFunction)?
    public let debugLocation: (any MTLFunctionLogDebugLocation)?

    public init(
        type: MTLFunctionLogType,
        encoderLabel: String?,
        function: (any MTLFunction)?,
        debugLocation: (any MTLFunctionLogDebugLocation)?
    ) {
        self.type = type
        self.encoderLabel = encoderLabel
        self.function = function
        self.debugLocation = debugLocation
        super.init()
    }
}

// MARK: - Counters

public protocol MTLCounter: NSObjectProtocol, Sendable {
    var name: String { get }
}

public final class LinuxMTLCounter: NSObject, MTLCounter, @unchecked Sendable {
    public let name: String

    public init(name: String) {
        self.name = name
        super.init()
    }
}

public final class LinuxMTLCounterSet: NSObject, MTLCounterSet, @unchecked Sendable {
    public let name: String
    public let counters: [any MTLCounter]

    public init(name: String, counters: [any MTLCounter] = []) {
        self.name = name
        self.counters = counters
        super.init()
    }
}

// MARK: - Function log debug location

public final class LinuxMTLFunctionLogDebugLocation: NSObject, MTLFunctionLogDebugLocation, @unchecked Sendable {
    public let functionName: String?
    public let url: URL?
    public let line: Int
    public let column: Int

    public init(functionName: String?, url: URL?, line: Int, column: Int) {
        self.functionName = functionName
        self.url = url
        self.line = line
        self.column = column
        super.init()
    }
}

// MARK: - IO scratch buffers (CPU shared memory)

public final class LinuxMTLIOScratchBuffer: NSObject, MTLIOScratchBuffer, @unchecked Sendable {
    public let buffer: any MTLBuffer

    public init?(device: any MTLDevice, minimumSize: Int) {
        guard minimumSize >= 0,
              let linux = device as? LinuxMTLDevice,
              let buffer = linux.makeBuffer(length: minimumSize, options: .storageModeShared)
        else { return nil }
        self.buffer = buffer
        super.init()
    }
}

public final class LinuxMTLIOScratchBufferAllocator: NSObject, MTLIOScratchBufferAllocator, @unchecked Sendable {
    public let device: any MTLDevice

    public init(device: any MTLDevice) {
        self.device = device
        super.init()
    }

    public func makeScratchBuffer(minimumSize: Int) -> (any MTLIOScratchBuffer)? {
        guard let linux = device as? LinuxMTLDevice else { return nil }
        return LinuxMTLIOScratchBuffer(device: linux, minimumSize: minimumSize)
    }
}

// MARK: - Reflection binding value objects

public protocol MTLObjectPayloadBinding: MTLBinding {
    var objectPayloadAlignment: Int { get }
    var objectPayloadDataSize: Int { get }
}

public protocol MTLTextureBinding: MTLBinding {
    var arrayLength: Int { get }
    var isDepthTexture: Bool { get }
    var textureDataType: MTLDataType { get }
    var textureType: MTLTextureType { get }
}

public protocol MTLThreadgroupBinding: MTLBinding {
    var threadgroupMemoryAlignment: Int { get }
    var threadgroupMemoryDataSize: Int { get }
}

public protocol MTLTensorBinding: MTLBinding {
    var dimensions: MTLTensorExtents? { get }
    var indexType: MTLDataType { get }
    var tensorDataType: MTLTensorDataType { get }
}

open class LinuxMTLBindingBase: NSObject, MTLBinding, @unchecked Sendable {
    public let name: String
    public let index: Int
    public let type: MTLBindingType
    public let access: MTLBindingAccess
    public let isUsed: Bool
    public let isArgument: Bool

    public init(
        name: String,
        index: Int,
        type: MTLBindingType,
        access: MTLBindingAccess,
        isUsed: Bool,
        isArgument: Bool
    ) {
        self.name = name
        self.index = index
        self.type = type
        self.access = access
        self.isUsed = isUsed
        self.isArgument = isArgument
        super.init()
    }
}

public final class LinuxMTLObjectPayloadBinding: LinuxMTLBindingBase, MTLObjectPayloadBinding, @unchecked Sendable {
    public let objectPayloadAlignment: Int
    public let objectPayloadDataSize: Int

    public init(
        name: String,
        index: Int,
        access: MTLBindingAccess,
        alignment: Int,
        dataSize: Int
    ) {
        self.objectPayloadAlignment = alignment
        self.objectPayloadDataSize = dataSize
        super.init(
            name: name,
            index: index,
            type: .objectPayload,
            access: access,
            isUsed: true,
            isArgument: true
        )
    }
}

public final class LinuxMTLTextureBinding: LinuxMTLBindingBase, MTLTextureBinding, @unchecked Sendable {
    public let isDepthTexture: Bool
    public let textureDataType: MTLDataType
    public let textureType: MTLTextureType
    public let arrayLength: Int

    public init(
        name: String,
        index: Int,
        access: MTLBindingAccess,
        isDepthTexture: Bool,
        textureDataType: MTLDataType,
        textureType: MTLTextureType,
        arrayLength: Int
    ) {
        self.isDepthTexture = isDepthTexture
        self.textureDataType = textureDataType
        self.textureType = textureType
        self.arrayLength = arrayLength
        super.init(
            name: name,
            index: index,
            type: .texture,
            access: access,
            isUsed: true,
            isArgument: true
        )
    }
}

public final class LinuxMTLThreadgroupBinding: LinuxMTLBindingBase, MTLThreadgroupBinding, @unchecked Sendable {
    public let threadgroupMemoryAlignment: Int
    public let threadgroupMemoryDataSize: Int

    public init(
        name: String,
        index: Int,
        access: MTLBindingAccess,
        alignment: Int,
        dataSize: Int
    ) {
        self.threadgroupMemoryAlignment = alignment
        self.threadgroupMemoryDataSize = dataSize
        super.init(
            name: name,
            index: index,
            type: .threadgroupMemory,
            access: access,
            isUsed: true,
            isArgument: true
        )
    }
}

public final class LinuxMTLTensorBinding: LinuxMTLBindingBase, MTLTensorBinding, @unchecked Sendable {
    public let dimensions: MTLTensorExtents?
    public let indexType: MTLDataType
    public let tensorDataType: MTLTensorDataType

    public init(
        name: String,
        index: Int,
        access: MTLBindingAccess,
        dimensions: MTLTensorExtents?,
        indexType: MTLDataType,
        tensorDataType: MTLTensorDataType
    ) {
        self.dimensions = dimensions
        self.indexType = indexType
        self.tensorDataType = tensorDataType
        super.init(
            name: name,
            index: index,
            type: .tensor,
            access: access,
            isUsed: true,
            isArgument: true
        )
    }
}

// MARK: - Metal 4 machine learning (fail-closed data model)
//
// The CPU reference has no ML compiler or neural engine. Descriptors and
// reflection are real value objects; compiler creation throws
// `MTLLibraryError.compileFailure` and dispatch marks the command buffer
// `MTL4CommandQueueError.notPermitted` at commit.

open class MTL4MachineLearningPipelineDescriptor: NSObject, @unchecked Sendable {
    public var label: String?
    public var machineLearningFunctionDescriptor: MTL4FunctionDescriptor?
    private var dimensions: [Int: MTLTensorExtents] = [:]

    public override init() {
        super.init()
    }

    public func inputDimensions(bufferIndex: Int) -> MTLTensorExtents? {
        dimensions[bufferIndex]
    }

    public func setInputDimensions(_ dimensions: MTLTensorExtents?, bufferIndex: Int) {
        self.dimensions[bufferIndex] = dimensions
    }

    public func reset() {
        label = nil
        machineLearningFunctionDescriptor = nil
        dimensions.removeAll()
    }
}

open class MTL4MachineLearningPipelineReflection: NSObject, @unchecked Sendable {
    public var bindings: [any MTLBinding]

    public override init() {
        self.bindings = []
        super.init()
    }

    public init(bindings: [any MTLBinding]) {
        self.bindings = bindings
        super.init()
    }
}

open class MTL4StitchedFunctionDescriptor: NSObject, @unchecked Sendable {
    public var functionDescriptors: [MTL4FunctionDescriptor]?
    public var functionGraph: MTLFunctionStitchingGraph?

    public override init() {
        super.init()
    }
}

public protocol MTL4MachineLearningPipelineState: MTLAllocation, Sendable {
    var device: any MTLDevice { get }
    var intermediatesHeapSize: Int { get }
    var label: String? { get }
    var reflection: MTL4MachineLearningPipelineReflection? { get }
}

public final class LinuxMTL4MachineLearningPipelineState: NSObject, MTL4MachineLearningPipelineState, @unchecked Sendable {
    public let device: any MTLDevice
    public let intermediatesHeapSize: Int
    public let label: String?
    public let reflection: MTL4MachineLearningPipelineReflection?
    public let allocatedSize: Int = 0

    public init(
        device: any MTLDevice,
        label: String?,
        intermediatesHeapSize: Int,
        reflection: MTL4MachineLearningPipelineReflection?
    ) {
        self.device = device
        self.label = label
        self.intermediatesHeapSize = max(intermediatesHeapSize, 0)
        self.reflection = reflection
        super.init()
    }
}

public protocol MTL4MachineLearningCommandEncoder: MTL4CommandEncoder {
    func setPipelineState(_ pipelineState: any MTL4MachineLearningPipelineState)
    func setArgumentTable(_ argumentTable: any MTL4ArgumentTable)
    func dispatchNetwork(intermediatesHeap heap: any MTLHeap)
}

final class LinuxMTL4MachineLearningCommandEncoder: LinuxMTL4EncoderBase, MTL4MachineLearningCommandEncoder, @unchecked Sendable {
    private var pipeline: (any MTL4MachineLearningPipelineState)?
    private var argumentTable: (any MTL4ArgumentTable)?

    func setPipelineState(_ pipelineState: any MTL4MachineLearningPipelineState) {
        pipeline = pipelineState
    }

    func setArgumentTable(_ argumentTable: any MTL4ArgumentTable) {
        self.argumentTable = argumentTable
    }

    func dispatchNetwork(intermediatesHeap heap: any MTLHeap) {
        _ = (pipeline, argumentTable, heap)
        owner.noteShaderWork()
    }
}

// MARK: - Visible / intersection function tables (CPU data)

final class LinuxMTLVisibleFunctionTable: LinuxMTLResource, MTLVisibleFunctionTable, @unchecked Sendable {
    let gpuResourceID: MTLResourceID
    let functionCount: Int
    private var functions: [(any MTLFunctionHandle)?]

    init(device: LinuxMTLDevice, functionCount: Int) {
        self.gpuResourceID = device.nextID()
        self.functionCount = max(functionCount, 0)
        self.functions = Array(repeating: nil, count: max(functionCount, 0))
        super.init(
            device: device,
            options: .storageModeShared,
            allocatedSize: max(functionCount, 0) * 8,
            heap: nil,
            heapOffset: 0
        )
    }

    func function(at index: Int) -> (any MTLFunctionHandle)? {
        guard index >= 0, index < functions.count else { return nil }
        return functions[index]
    }

    func setFunction(_ function: (any MTLFunctionHandle)?, index: Int) {
        guard index >= 0, index < functions.count else { return }
        functions[index] = function
    }

    func setFunctions(_ functions: [(any MTLFunctionHandle)?], range: Range<Int>) {
        var destination = range.lowerBound
        for function in functions where destination < range.upperBound {
            if destination >= 0, destination < self.functions.count {
                self.functions[destination] = function
            }
            destination += 1
        }
    }
}

final class LinuxMTLIntersectionFunctionTable: LinuxMTLResource, MTLIntersectionFunctionTable, @unchecked Sendable {
    let gpuResourceID: MTLResourceID
    let functionCount: Int
    private var functions: [(any MTLFunctionHandle)?]
    private var buffers: [Int: ((any MTLBuffer)?, Int)] = [:]
    private var visibleTables: [Int: (any MTLVisibleFunctionTable)?] = [:]
    private var curveSignatures: [Int: MTLIntersectionFunctionSignature] = [:]
    private var triangleSignatures: [Int: MTLIntersectionFunctionSignature] = [:]

    init(device: LinuxMTLDevice, functionCount: Int) {
        self.gpuResourceID = device.nextID()
        self.functionCount = max(functionCount, 0)
        self.functions = Array(repeating: nil, count: max(functionCount, 0))
        super.init(
            device: device,
            options: .storageModeShared,
            allocatedSize: max(functionCount, 0) * 8,
            heap: nil,
            heapOffset: 0
        )
    }

    func setFunction(_ function: (any MTLFunctionHandle)?, index: Int) {
        guard index >= 0, index < functions.count else { return }
        functions[index] = function
    }

    func setFunctions(_ functions: [(any MTLFunctionHandle)?], range: Range<Int>) {
        var destination = range.lowerBound
        for function in functions where destination < range.upperBound {
            if destination >= 0, destination < self.functions.count {
                self.functions[destination] = function
            }
            destination += 1
        }
    }

    func setBuffer(_ buffer: (any MTLBuffer)?, offset: Int, index: Int) {
        buffers[index] = (buffer, offset)
    }

    func setBuffers(_ buffers: [(any MTLBuffer)?], offsets: [Int], range: Range<Int>) {
        var destination = range.lowerBound
        for (position, buffer) in buffers.enumerated() where destination < range.upperBound {
            let offset = position < offsets.count ? offsets[position] : 0
            self.buffers[destination] = (buffer, offset)
            destination += 1
        }
    }

    func bufferOffset(at index: Int) -> Int {
        buffers[index]?.1 ?? 0
    }

    func setVisibleFunctionTable(_ functionTable: (any MTLVisibleFunctionTable)?, bufferIndex: Int) {
        visibleTables[bufferIndex] = functionTable
    }

    func setVisibleFunctionTables(
        _ functionTables: [(any MTLVisibleFunctionTable)?],
        bufferRange: Range<Int>
    ) {
        var destination = bufferRange.lowerBound
        for table in functionTables where destination < bufferRange.upperBound {
            visibleTables[destination] = table
            destination += 1
        }
    }

    func setOpaqueCurveIntersectionFunction(signature: MTLIntersectionFunctionSignature, index: Int) {
        curveSignatures[index] = signature
    }

    func setOpaqueCurveIntersectionFunction(signature: MTLIntersectionFunctionSignature, range: NSRange) {
        for index in range.location..<(range.location + range.length) {
            curveSignatures[index] = signature
        }
    }

    func setOpaqueTriangleIntersectionFunction(signature: MTLIntersectionFunctionSignature, index: Int) {
        triangleSignatures[index] = signature
    }

    func setOpaqueTriangleIntersectionFunction(signature: MTLIntersectionFunctionSignature, range: NSRange) {
        for index in range.location..<(range.location + range.length) {
            triangleSignatures[index] = signature
        }
    }

    func curveSignature(at index: Int) -> MTLIntersectionFunctionSignature {
        curveSignatures[index] ?? []
    }

    func triangleSignature(at index: Int) -> MTLIntersectionFunctionSignature {
        triangleSignatures[index] ?? []
    }
}
