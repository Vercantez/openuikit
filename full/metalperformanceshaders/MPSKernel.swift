import Foundation

public typealias MPSCopyAllocator = (MPSKernel, any MTLCommandBuffer, any MTLTexture) -> any MTLTexture
public typealias MPSDeviceCaps = UInt32
public typealias MPSFunctionConstant = Int64
public typealias MPSFunctionConstantInMetal = UInt32
public typealias MPSAccelerationStructureCompletionHandler = (MPSAccelerationStructure?) -> Void
public typealias MPSNNGraphCompletionHandler = (MPSImage?, (any Error)?) -> Void
public typealias MPSGradientNodeBlock = (
    MPSNNFilterNode, MPSNNFilterNode, MPSNNImageNode, MPSNNImageNode
) -> Void

public let MPSFunctionConstantNone: MPSFunctionConstant = -1
public let MPSFunctionConstantNoneArray: (MPSFunctionConstant, MPSFunctionConstant) = (-1, -1)

public let MPSRectNoClip = MTLRegion(
    origin: MTLOrigin(x: 0, y: 0, z: 0),
    size: MTLSize(width: Int.max / 2, height: Int.max / 2, depth: Int.max / 2)
)

public var MPSBatchSizeIndex: Int32 { 0 }
public var MPSDeviceCapsIndex: Int32 { 1 }
public var MPSFunctionConstantIndex: Int32 { 2 }
public var MPSFunctionConstantIndexReserved: Int32 { 3 }
public var MPSNDArrayConstantIndex: Int32 { 4 }
public var MPSNDArrayConstantMultiDestDstAddressingIndex: Int32 { 5 }
public var MPSNDArrayConstantMultiDestIndex: Int32 { 6 }
public var MPSNDArrayConstantMultiDestIndex0: Int32 { 7 }
public var MPSNDArrayConstantMultiDestIndex1: Int32 { 8 }
public var MPSNDArrayConstantMultiDestSrcAddressingIndex: Int32 { 9 }
public var MPSTextureLinkingConstantIndex: Int32 { 10 }
public var MPSUserAvailableFunctionConstantStartIndex: Int32 { 11 }
public var MPSUserConstantIndex: Int32 { 12 }

/// Linux has no Metal GPU. Encode paths trap rather than returning a
/// fabricated filtered texture. Command-buffer memory hints are inert.
public enum MPSHostBoundary {
    public static func refuseGPUEncode(_ api: String) -> Never {
        fatalError("MetalPerformanceShaders: \(api) requires a Metal GPU, which is unavailable on this host")
    }
}

public protocol MPSDeviceProvider {
    func mpsMTLDevice() -> (any MTLDevice)!
}

public protocol MPSImageAllocator: NSObjectProtocol, NSSecureCoding {
    func image(
        for cmdBuf: any MTLCommandBuffer,
        imageDescriptor descriptor: MPSImageDescriptor,
        kernel: MPSKernel
    ) -> MPSImage

    func imageBatch(
        for cmdBuf: any MTLCommandBuffer,
        imageDescriptor descriptor: MPSImageDescriptor,
        kernel: MPSKernel,
        count: Int
    ) -> [MPSImage]
}

extension MPSImageAllocator {
    public func imageBatch(
        for cmdBuf: any MTLCommandBuffer,
        imageDescriptor descriptor: MPSImageDescriptor,
        kernel: MPSKernel,
        count: Int
    ) -> [MPSImage] {
        (0..<max(count, 0)).map { _ in
            image(for: cmdBuf, imageDescriptor: descriptor, kernel: kernel)
        }
    }
}

public protocol MPSNNPadding: NSObjectProtocol, NSSecureCoding {}

public protocol MPSHandle: NSObjectProtocol, NSSecureCoding {
    var label: String { get }
}

public protocol MPSHeapProvider: NSObjectProtocol {
    func newHeap(size: Int) -> AnyObject?
}

open class MPSKernel: NSObject, NSCopying {
    public private(set) var device: any MTLDevice
    public var label: String?
    public var options: MPSKernelOptions = .none

    public required init(device: any MTLDevice) {
        self.device = device
        super.init()
    }

    public init?(coder aDecoder: NSCoder) {
        return nil
    }

    public init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        _ = aDecoder
        return nil
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        copy(with: zone, device: device)
    }

    open func copy(with zone: NSZone? = nil, device: (any MTLDevice)?) -> Self {
        let copied = Self.init(device: device ?? self.device)
        copied.options = options
        copied.label = label
        return copied
    }
}

open class MPSUnaryImageKernel: MPSKernel {
    public var clipRect: MTLRegion = MPSRectNoClip
    public var offset: MPSOffset = MPSOffset()
    public var edgeMode: MPSImageEdgeMode = .clamp

    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        super.init(coder: aDecoder, device: device)
    }

    open func sourceRegion(destinationSize: MTLSize) -> MPSRegion {
        MPSRegion(
            origin: MPSOrigin(
                x: Double(offset.x + clipRect.origin.x),
                y: Double(offset.y + clipRect.origin.y),
                z: Double(offset.z + clipRect.origin.z)
            ),
            size: MPSSize(
                width: Double(destinationSize.width),
                height: Double(destinationSize.height),
                depth: Double(max(destinationSize.depth, 1))
            )
        )
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceTexture: any MTLTexture,
        destinationTexture: any MTLTexture
    ) {
        _ = (commandBuffer, sourceTexture, destinationTexture)
        MPSHostBoundary.refuseGPUEncode("MPSUnaryImageKernel.encode(sourceTexture:destinationTexture:)")
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceImage: MPSImage,
        destinationImage: MPSImage
    ) {
        _ = (commandBuffer, sourceImage, destinationImage)
        MPSHostBoundary.refuseGPUEncode("MPSUnaryImageKernel.encode(sourceImage:destinationImage:)")
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        inPlaceTexture texture: UnsafeMutablePointer<any MTLTexture>,
        fallbackCopyAllocator copyAllocator: MPSCopyAllocator? = nil
    ) -> Bool {
        _ = (commandBuffer, texture, copyAllocator)
        MPSHostBoundary.refuseGPUEncode("MPSUnaryImageKernel.encode(inPlaceTexture:)")
    }
}

open class MPSBinaryImageKernel: MPSKernel {
    public var clipRect: MTLRegion = MPSRectNoClip
    public var primaryOffset: MPSOffset = MPSOffset()
    public var secondaryOffset: MPSOffset = MPSOffset()
    public var primaryEdgeMode: MPSImageEdgeMode = .clamp
    public var secondaryEdgeMode: MPSImageEdgeMode = .clamp

    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        super.init(coder: aDecoder, device: device)
    }

    open func primarySourceRegion(forDestinationSize destinationSize: MTLSize) -> MPSRegion {
        MPSRegion(
            origin: MPSOrigin(
                x: Double(primaryOffset.x),
                y: Double(primaryOffset.y),
                z: Double(primaryOffset.z)
            ),
            size: MPSSize(
                width: Double(destinationSize.width),
                height: Double(destinationSize.height),
                depth: Double(max(destinationSize.depth, 1))
            )
        )
    }

    open func secondarySourceRegion(forDestinationSize destinationSize: MTLSize) -> MPSRegion {
        MPSRegion(
            origin: MPSOrigin(
                x: Double(secondaryOffset.x),
                y: Double(secondaryOffset.y),
                z: Double(secondaryOffset.z)
            ),
            size: MPSSize(
                width: Double(destinationSize.width),
                height: Double(destinationSize.height),
                depth: Double(max(destinationSize.depth, 1))
            )
        )
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        primaryTexture: any MTLTexture,
        secondaryTexture: any MTLTexture,
        destinationTexture: any MTLTexture
    ) {
        _ = (commandBuffer, primaryTexture, secondaryTexture, destinationTexture)
        MPSHostBoundary.refuseGPUEncode("MPSBinaryImageKernel.encode")
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        primaryImage: MPSImage,
        secondaryImage: MPSImage,
        destinationImage: MPSImage
    ) {
        _ = (commandBuffer, primaryImage, secondaryImage, destinationImage)
        MPSHostBoundary.refuseGPUEncode("MPSBinaryImageKernel.encode(images:)")
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        inPlacePrimaryTexture: UnsafeMutablePointer<any MTLTexture>,
        secondaryTexture: any MTLTexture,
        fallbackCopyAllocator copyAllocator: MPSCopyAllocator? = nil
    ) -> Bool {
        _ = (commandBuffer, inPlacePrimaryTexture, secondaryTexture, copyAllocator)
        MPSHostBoundary.refuseGPUEncode("MPSBinaryImageKernel.encode(inPlacePrimaryTexture:)")
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        primaryTexture: any MTLTexture,
        inPlaceSecondaryTexture: UnsafeMutablePointer<any MTLTexture>,
        fallbackCopyAllocator copyAllocator: MPSCopyAllocator? = nil
    ) -> Bool {
        _ = (commandBuffer, primaryTexture, inPlaceSecondaryTexture, copyAllocator)
        MPSHostBoundary.refuseGPUEncode("MPSBinaryImageKernel.encode(inPlaceSecondaryTexture:)")
    }
}

open class MPSState: NSObject {
    public var label: String?
    public var readCount: Int = 1
    public private(set) var isTemporary: Bool
    public private(set) var resourceCount: Int
    private var resources: [any MTLResource]
    private var bufferSizes: [Int]
    private var textureInfos: [MPSStateTextureInfo]

    public init(device: any MTLDevice, bufferSize: Int) {
        _ = device
        self.isTemporary = false
        self.resourceCount = 1
        self.bufferSizes = [max(bufferSize, 0)]
        self.textureInfos = [MPSStateTextureInfo()]
        self.resources = []
        super.init()
    }

    public init(device: any MTLDevice, resourceList: MPSStateResourceList) {
        _ = device
        self.isTemporary = false
        self.resourceCount = resourceList.count
        self.bufferSizes = Array(repeating: 0, count: resourceList.count)
        self.textureInfos = Array(repeating: MPSStateTextureInfo(), count: max(resourceList.count, 1))
        self.resources = []
        super.init()
    }

    public init(device: any MTLDevice, textureDescriptor descriptor: MTLTextureDescriptor) {
        _ = device
        self.isTemporary = false
        self.resourceCount = 1
        self.bufferSizes = [0]
        var info = MPSStateTextureInfo()
        info.width = descriptor.width
        info.height = descriptor.height
        info.depth = descriptor.depth
        info.arrayLength = descriptor.arrayLength
        info.pixelFormat = descriptor.pixelFormat
        info.textureType = descriptor.textureType
        info.usage = descriptor.usage
        self.textureInfos = [info]
        self.resources = []
        super.init()
    }

    public init(resource: (any MTLResource)?) {
        self.isTemporary = false
        if let resource {
            self.resources = [resource]
            self.resourceCount = 1
        } else {
            self.resources = []
            self.resourceCount = 0
        }
        self.bufferSizes = [resource?.allocatedSize ?? 0]
        self.textureInfos = [MPSStateTextureInfo()]
        super.init()
    }

    public init(resources: [any MTLResource]?) {
        let list = resources ?? []
        self.resources = list
        self.isTemporary = false
        self.resourceCount = list.count
        self.bufferSizes = list.map(\.allocatedSize)
        self.textureInfos = Array(repeating: MPSStateTextureInfo(), count: max(list.count, 1))
        super.init()
    }

    open class func temporaryState(with cmdBuf: any MTLCommandBuffer) -> Self {
        let state = MPSState(resource: nil)
        state.isTemporary = true
        _ = cmdBuf
        return state as! Self
    }

    open class func temporaryState(with cmdBuf: any MTLCommandBuffer, bufferSize: Int) -> Self {
        let state = MPSState(device: cmdBuf.device, bufferSize: bufferSize)
        state.isTemporary = true
        return state as! Self
    }

    open class func temporaryState(
        with commandBuffer: any MTLCommandBuffer,
        resourceList: MPSStateResourceList
    ) -> Self {
        let state = MPSState(device: commandBuffer.device, resourceList: resourceList)
        state.isTemporary = true
        return state as! Self
    }

    open class func temporaryState(
        with cmdBuf: any MTLCommandBuffer,
        textureDescriptor descriptor: MTLTextureDescriptor
    ) -> Self {
        let state = MPSState(device: cmdBuf.device, textureDescriptor: descriptor)
        state.isTemporary = true
        return state as! Self
    }

    open var resource: (any MTLResource)? { resources.first }

    open func resource(at index: Int, allocateMemory: Bool) -> (any MTLResource)? {
        _ = allocateMemory
        guard resources.indices.contains(index) else { return nil }
        return resources[index]
    }

    open func resourceSize() -> Int {
        bufferSizes.reduce(0, +)
    }

    open func bufferSize(at index: Int) -> Int {
        guard bufferSizes.indices.contains(index) else { return 0 }
        return bufferSizes[index]
    }

    open func resourceType(at index: Int) -> MPSStateResourceType {
        if resources.indices.contains(index) {
            if resources[index] is any MTLTexture { return .texture }
            if resources[index] is any MTLBuffer { return .buffer }
        }
        if bufferSizes.indices.contains(index), bufferSizes[index] > 0 {
            return .buffer
        }
        return .none
    }

    open func textureInfo(at index: Int) -> MPSStateTextureInfo {
        guard textureInfos.indices.contains(index) else { return MPSStateTextureInfo() }
        return textureInfos[index]
    }

    open func synchronize(on commandBuffer: any MTLCommandBuffer) {
        _ = commandBuffer
    }

    open func destinationImageDescriptor(
        forSourceImages sourceImages: [MPSImage],
        sourceStates: [MPSState]?,
        for kernel: MPSKernel,
        suggestedDescriptor inDescriptor: MPSImageDescriptor
    ) -> MPSImageDescriptor {
        _ = (sourceImages, sourceStates, kernel)
        return inDescriptor.copy() as MPSImageDescriptor
    }
}

open class MPSStateResourceList: NSObject {
    public private(set) var count: Int = 0

    public override init() {
        super.init()
    }

    public func append(_ bufferSize: Int) {
        _ = bufferSize
        count += 1
    }
}

open class MPSPredicate: NSObject {
    public private(set) var predicateBuffer: any MTLBuffer
    public private(set) var predicateOffset: Int

    public init(buffer: any MTLBuffer, offset: Int) {
        self.predicateBuffer = buffer
        self.predicateOffset = offset
        super.init()
    }

    public init(device: any MTLDevice) {
        if let host = device as? MPSHostDevice {
            self.predicateBuffer = host.makeBuffer(length: 8)
        } else {
            self.predicateBuffer = MPSHostBuffer(device: device, length: 8)
        }
        self.predicateOffset = 0
        super.init()
    }
}

open class MPSAccelerationStructure: MPSKernel {}

open class MPSNNFilterNode: NSObject {}

open class MPSNNImageNode: NSObject {}

public func MPSSupportsMTLDevice(_ device: (any MTLDevice)?) -> Bool {
    _ = device
    return false
}

public func MPSGetPreferredDevice(_ options: MPSDeviceOptions) -> (any MTLDevice)? {
    _ = options
    return nil
}

public func MPSHintTemporaryMemoryHighWaterMark(_ cmdBuf: any MTLCommandBuffer, _ bytes: Int) {
    _ = (cmdBuf, bytes)
}

public func MPSSetHeapCacheDuration(_ cmdBuf: any MTLCommandBuffer, _ seconds: Double) {
    _ = (cmdBuf, seconds)
}

public func MPSStateBatchIncrementReadCount(_ batch: [MPSState]?, _ amount: Int) -> Int {
    guard let batch else { return 0 }
    for state in batch {
        state.readCount += amount
    }
    return batch.count
}

public func MPSStateBatchResourceSize(_ batch: [MPSState]?) -> Int {
    guard let batch else { return 0 }
    return batch.reduce(0) { $0 + $1.resourceSize() }
}

public func MPSStateBatchSynchronize(_ batch: [MPSState], _ cmdBuf: any MTLCommandBuffer) {
    for state in batch {
        state.synchronize(on: cmdBuf)
    }
}
