import Foundation

public protocol MTLAllocation: NSObjectProtocol {
    var allocatedSize: Int { get }
}

public protocol MTLResource: MTLAllocation {
    var device: any MTLDevice { get }
    var cpuCacheMode: MTLCPUCacheMode { get }
    var storageMode: MTLStorageMode { get }
    var hazardTrackingMode: MTLHazardTrackingMode { get }
    var resourceOptions: MTLResourceOptions { get }
    var heap: (any MTLHeap)? { get }
    var heapOffset: Int { get }
    var label: String? { get set }
    func setPurgeableState(_ state: MTLPurgeableState) -> MTLPurgeableState
    func makeAliasable()
    func isAliasable() -> Bool
}

public protocol MTLBuffer: MTLResource {
    var length: Int { get }
    var gpuAddress: MTLGPUAddress { get }
    var sparseBufferTier: MTLBufferSparseTier { get }
    func contents() -> UnsafeMutableRawPointer
    func addDebugMarker(_ marker: String, range: Range<Int>)
    func removeAllDebugMarkers()
    func makeTexture(descriptor: MTLTextureDescriptor, offset: Int, bytesPerRow: Int) -> (any MTLTexture)?
}

public protocol MTLTexture: MTLResource {
    var textureType: MTLTextureType { get }
    var pixelFormat: MTLPixelFormat { get }
    var width: Int { get }
    var height: Int { get }
    var depth: Int { get }
    var mipmapLevelCount: Int { get }
    var sampleCount: Int { get }
    var arrayLength: Int { get }
    var usage: MTLTextureUsage { get }
    var isFramebufferOnly: Bool { get }
    var isShareable: Bool { get }
    var isSparse: Bool { get }
    var allowGPUOptimizedContents: Bool { get }
    var compressionType: MTLTextureCompressionType { get }
    var swizzle: MTLTextureSwizzleChannels { get }
    var parent: (any MTLTexture)? { get }
    var parentRelativeLevel: Int { get }
    var parentRelativeSlice: Int { get }
    var buffer: (any MTLBuffer)? { get }
    var bufferOffset: Int { get }
    var bufferBytesPerRow: Int { get }
    var rootResource: (any MTLResource)? { get }
    var gpuResourceID: MTLResourceID { get }
    var firstMipmapInTail: Int { get }
    var tailSizeInBytes: Int { get }
    var sparseTextureTier: MTLTextureSparseTier { get }
    func replace(region: MTLRegion, mipmapLevel level: Int, withBytes pixelBytes: UnsafeRawPointer, bytesPerRow: Int)
    func replace(
        region: MTLRegion,
        mipmapLevel level: Int,
        slice: Int,
        withBytes pixelBytes: UnsafeRawPointer,
        bytesPerRow: Int,
        bytesPerImage: Int
    )
    func getBytes(_ pixelBytes: UnsafeMutableRawPointer, bytesPerRow: Int, from region: MTLRegion, mipmapLevel level: Int)
    func getBytes(
        _ pixelBytes: UnsafeMutableRawPointer,
        bytesPerRow: Int,
        bytesPerImage: Int,
        from region: MTLRegion,
        mipmapLevel level: Int,
        slice: Int
    )
    func makeTextureView(pixelFormat: MTLPixelFormat) -> (any MTLTexture)?
}

public protocol MTLHeap: MTLAllocation {
    var device: any MTLDevice { get }
    var label: String? { get set }
    var size: Int { get }
    var usedSize: Int { get }
    var storageMode: MTLStorageMode { get }
    var cpuCacheMode: MTLCPUCacheMode { get }
    var type: MTLHeapType { get }
}

public protocol MTLCommandEncoder: NSObjectProtocol {
    var device: any MTLDevice { get }
    var label: String? { get set }
    func endEncoding()
    func insertDebugSignpost(_ string: String)
    func pushDebugGroup(_ string: String)
    func popDebugGroup()
}

public protocol MTLBlitCommandEncoder: MTLCommandEncoder {
    func fill(buffer: any MTLBuffer, range: Range<Int>, value: UInt8)
    func copy(
        from sourceBuffer: any MTLBuffer,
        sourceOffset: Int,
        to destinationBuffer: any MTLBuffer,
        destinationOffset: Int,
        size: Int
    )
    func generateMipmaps(for texture: any MTLTexture)
    func optimizeContentsForCPUAccess(texture: any MTLTexture)
    func optimizeContentsForGPUAccess(texture: any MTLTexture)
}

public protocol MTLCommandQueue: NSObjectProtocol, Sendable {
    var device: any MTLDevice { get }
    var label: String? { get set }
    func makeCommandBuffer() -> (any MTLCommandBuffer)?
    func makeCommandBuffer(descriptor: MTLCommandBufferDescriptor) -> (any MTLCommandBuffer)?
    func makeCommandBufferWithUnretainedReferences() -> (any MTLCommandBuffer)?
    func insertDebugCaptureBoundary()
}

public protocol MTLCommandBuffer: NSObjectProtocol {
    var device: any MTLDevice { get }
    var commandQueue: any MTLCommandQueue { get }
    var retainedReferences: Bool { get }
    var errorOptions: MTLCommandBufferErrorOption { get }
    var label: String? { get set }
    var status: MTLCommandBufferStatus { get }
    var error: (any Error)? { get }
    var kernelStartTime: TimeInterval { get }
    var kernelEndTime: TimeInterval { get }
    var gpuStartTime: TimeInterval { get }
    var gpuEndTime: TimeInterval { get }
    var logs: MTLLogContainer { get }
    func enqueue()
    func commit()
    func addScheduledHandler(_ block: @escaping MTLCommandBufferHandler)
    func addCompletedHandler(_ block: @escaping MTLCommandBufferHandler)
    func waitUntilScheduled()
    func waitUntilCompleted()
    func pushDebugGroup(_ string: String)
    func popDebugGroup()
    func present(_ drawable: any MTLDrawable)
    func makeBlitCommandEncoder() -> (any MTLBlitCommandEncoder)?
}

public protocol MTLDevice: NSObjectProtocol, Sendable {
    var name: String { get }
    var registryID: UInt64 { get }
    var architecture: MTLArchitecture { get }
    var maxThreadsPerThreadgroup: MTLSize { get }
    var hasUnifiedMemory: Bool { get }
    var recommendedMaxWorkingSetSize: UInt64 { get }
    var currentAllocatedSize: Int { get }
    var maxBufferLength: Int { get }
    var maxThreadgroupMemoryLength: Int { get }
    var maxArgumentBufferSamplerCount: Int { get }
    var argumentBuffersSupport: MTLArgumentBuffersTier { get }
    var readWriteTextureSupport: MTLReadWriteTextureTier { get }
    var areBarycentricCoordsSupported: Bool { get }
    var areRasterOrderGroupsSupported: Bool { get }
    var areProgrammableSamplePositionsSupported: Bool { get }
    var sparseTileSizeInBytes: Int { get }
    var supports32BitFloatFiltering: Bool { get }
    var supports32BitMSAA: Bool { get }
    var supportsBCTextureCompression: Bool { get }
    var supportsPullModelInterpolation: Bool { get }
    var supportsShaderBarycentricCoordinates: Bool { get }
    var supportsQueryTextureLOD: Bool { get }
    var supportsFunctionPointers: Bool { get }
    var supportsFunctionPointersFromRender: Bool { get }
    var supportsRaytracing: Bool { get }
    var supportsRaytracingFromRender: Bool { get }
    var supportsPrimitiveMotionBlur: Bool { get }
    var supportsDynamicLibraries: Bool { get }
    var supportsRenderDynamicLibraries: Bool { get }
    var maximumConcurrentCompilationTaskCount: Int { get }
    func supportsFamily(_ gpuFamily: MTLGPUFamily) -> Bool
    func supportsFeatureSet(_ featureSet: MTLFeatureSet) -> Bool
    func supportsTextureSampleCount(_ sampleCount: Int) -> Bool
    func supportsVertexAmplificationCount(_ count: Int) -> Bool
    func supportsRasterizationRateMap(layerCount: Int) -> Bool
    func supportsCounterSampling(_ samplingPoint: MTLCounterSamplingPoint) -> Bool
    func minimumLinearTextureAlignment(for format: MTLPixelFormat) -> Int
    func minimumTextureBufferAlignment(for format: MTLPixelFormat) -> Int
    func heapBufferSizeAndAlign(length: Int, options: MTLResourceOptions) -> MTLSizeAndAlign
    func heapTextureSizeAndAlign(descriptor desc: MTLTextureDescriptor) -> MTLSizeAndAlign
    func makeCommandQueue() -> (any MTLCommandQueue)?
    func makeCommandQueue(maxCommandBufferCount: Int) -> (any MTLCommandQueue)?
    func makeCommandQueue(descriptor: MTLCommandQueueDescriptor) -> (any MTLCommandQueue)?
    func makeBuffer(length: Int, options: MTLResourceOptions) -> (any MTLBuffer)?
    func makeBuffer(bytes pointer: UnsafeRawPointer, length: Int, options: MTLResourceOptions) -> (any MTLBuffer)?
    func makeTexture(descriptor: MTLTextureDescriptor) -> (any MTLTexture)?
    func makeSamplerState(descriptor: MTLSamplerDescriptor) -> (any MTLSamplerState)?
    func makeDepthStencilState(descriptor: MTLDepthStencilDescriptor) -> (any MTLDepthStencilState)?
    func makeDefaultLibrary() -> (any MTLLibrary)?
    func makeLibrary(source: String, options: MTLCompileOptions?) throws -> any MTLLibrary
    func makeLibrary(URL url: URL) throws -> any MTLLibrary
    func makeEvent() -> (any MTLEvent)?
    func makeFence() -> (any MTLFence)?
    func getDefaultSamplePositions(sampleCount: Int) -> [MTLSamplePosition]
}

public protocol MTLLibrary: NSObjectProtocol, Sendable {
    var device: any MTLDevice { get }
    var label: String? { get set }
    var functionNames: [String] { get }
    var type: MTLLibraryType { get }
    var installName: String? { get }
    func makeFunction(name functionName: String) -> (any MTLFunction)?
}

public protocol MTLFunction: NSObjectProtocol, Sendable {
    var device: any MTLDevice { get }
    var functionType: MTLFunctionType { get }
    var name: String { get }
    var label: String? { get set }
}

public protocol MTLSamplerState: NSObjectProtocol, Sendable {
    var device: any MTLDevice { get }
    var label: String? { get }
    var gpuResourceID: MTLResourceID { get }
}

public protocol MTLDepthStencilState: NSObjectProtocol, Sendable {
    var device: any MTLDevice { get }
    var label: String? { get }
    var gpuResourceID: MTLResourceID { get }
}

public protocol MTLRenderPipelineState: MTLAllocation, Sendable {
    var device: any MTLDevice { get }
    var label: String? { get }
}

public protocol MTLComputePipelineState: MTLAllocation, Sendable {
    var device: any MTLDevice { get }
    var maxTotalThreadsPerThreadgroup: Int { get }
}

public protocol MTLDrawable: NSObjectProtocol {
    var drawableID: Int { get }
    func present()
}

public protocol MTLFence: NSObjectProtocol, Sendable {
    var device: any MTLDevice { get }
    var label: String? { get set }
}

public protocol MTLEvent: NSObjectProtocol, Sendable {
    var device: any MTLDevice { get }
    var label: String? { get set }
}

public protocol MTLCaptureScope: NSObjectProtocol {
    var device: (any MTLDevice)? { get }
    var commandQueue: (any MTLCommandQueue)? { get }
    var label: String? { get set }
    func begin()
    func end()
}

public protocol MTLDynamicLibrary: NSObjectProtocol, Sendable {
    var device: any MTLDevice { get }
    var label: String? { get set }
    var installName: String { get }
}

public protocol MTLLogState: NSObjectProtocol, Sendable {}

public protocol MTLFunctionLog: NSObjectProtocol {}

public protocol MTLCounterSet: NSObjectProtocol {
    var name: String { get }
}

public enum MTLCounterSamplingPoint: UInt, Equatable, Hashable, Sendable {
    case atStageBoundary = 0
    case atDrawBoundary = 1
    case atDispatchBoundary = 2
    case atTileDispatchBoundary = 3
    case atBlitBoundary = 4
}

public struct MTLLogContainer: Sendable {
    public struct Iterator: IteratorProtocol {
        public typealias Element = any MTLFunctionLog

        public mutating func next() -> (any MTLFunctionLog)? {
            nil
        }
    }

    public func makeIterator() -> Iterator {
        Iterator()
    }
}

open class MTLCaptureManager: NSObject, @unchecked Sendable {
    private static let instance = MTLCaptureManager()
    private var capturing = false
    public var defaultCaptureScope: (any MTLCaptureScope)?

    public var isCapturing: Bool { capturing }

    public class func shared() -> MTLCaptureManager {
        instance
    }

    public func supportsDestination(_ destination: MTLCaptureDestination) -> Bool {
        _ = destination
        return false
    }

    public func startCapture(with descriptor: MTLCaptureDescriptor) throws {
        _ = descriptor
        throw MTLCaptureError.notSupported
    }

    public func startCapture(device: any MTLDevice) {
        _ = device
    }

    public func startCapture(commandQueue: any MTLCommandQueue) {
        _ = commandQueue
    }

    public func startCapture(scope captureScope: any MTLCaptureScope) {
        _ = captureScope
    }

    public func stopCapture() {
        capturing = false
    }

    public func makeCaptureScope(device: any MTLDevice) -> any MTLCaptureScope {
        LinuxMTLCaptureScope(device: device, commandQueue: nil)
    }

    public func makeCaptureScope(commandQueue: any MTLCommandQueue) -> any MTLCaptureScope {
        LinuxMTLCaptureScope(device: commandQueue.device, commandQueue: commandQueue)
    }
}
