import Foundation

public final class MPSImageDefaultAllocator: NSObject, MPSImageAllocator {
    public static var supportsSecureCoding: Bool { true }

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init()
        _ = coder
    }

    public func encode(with coder: NSCoder) {
        _ = coder
    }

    public func image(
        for cmdBuf: any MTLCommandBuffer,
        imageDescriptor descriptor: MPSImageDescriptor,
        kernel: MPSKernel
    ) -> MPSImage {
        _ = cmdBuf
        return MPSImage(device: kernel.device, imageDescriptor: descriptor)
    }
}

open class MPSImageDescriptor: NSObject {
    public var channelFormat: MPSImageFeatureChannelFormat
    public var width: Int
    public var height: Int
    public var featureChannels: Int
    public var numberOfImages: Int
    public var usage: MTLTextureUsage
    public var cpuCacheMode: MTLCPUCacheMode
    public var storageMode: MTLStorageMode

    public convenience init(
        channelFormat: MPSImageFeatureChannelFormat,
        width: Int,
        height: Int,
        featureChannels: Int
    ) {
        self.init(
            channelFormat: channelFormat,
            width: width,
            height: height,
            featureChannels: featureChannels,
            numberOfImages: 1,
            usage: [.shaderRead, .shaderWrite]
        )
    }

    public convenience init(
        channelFormat: MPSImageFeatureChannelFormat,
        width: Int,
        height: Int,
        featureChannels: Int,
        numberOfImages: Int,
        usage: MTLTextureUsage
    ) {
        self.init()
        self.channelFormat = channelFormat
        self.width = width
        self.height = height
        self.featureChannels = featureChannels
        self.numberOfImages = numberOfImages
        self.usage = usage
    }

    public override init() {
        self.channelFormat = .unorm8
        self.width = 1
        self.height = 1
        self.featureChannels = 1
        self.numberOfImages = 1
        self.usage = [.shaderRead]
        self.cpuCacheMode = .defaultCache
        self.storageMode = .shared
        super.init()
    }

    public var pixelFormat: MTLPixelFormat {
        mpsPixelFormat(channelFormat: channelFormat, featureChannels: featureChannels)
    }

    public func copy(with zone: NSZone? = nil) -> Self {
        _ = zone
        let copied = MPSImageDescriptor(
            channelFormat: channelFormat,
            width: width,
            height: height,
            featureChannels: featureChannels,
            numberOfImages: numberOfImages,
            usage: usage
        )
        copied.cpuCacheMode = cpuCacheMode
        copied.storageMode = storageMode
        return copied as! Self
    }
}

open class MPSImage: NSObject {
    public private(set) var device: any MTLDevice
    public private(set) var width: Int
    public private(set) var height: Int
    public private(set) var featureChannels: Int
    public private(set) var numberOfImages: Int
    public private(set) var featureChannelFormat: MPSImageFeatureChannelFormat
    public private(set) var pixelFormat: MTLPixelFormat
    public private(set) var textureType: MTLTextureType
    public private(set) var usage: MTLTextureUsage
    public var label: String?
    public private(set) var parent: MPSImage?
    public let pixelSize: Int
    public let precision: Int
    public private(set) var texture: any MTLTexture
    private var hostStorage: Data
    public var readCount: Int = Int.max

    public class func defaultAllocator() -> any MPSImageAllocator {
        MPSImageDefaultAllocator()
    }

    public convenience init(device: any MTLDevice, imageDescriptor: MPSImageDescriptor) {
        let descriptor = MTLTextureDescriptor()
        descriptor.pixelFormat = imageDescriptor.pixelFormat
        descriptor.width = imageDescriptor.width
        descriptor.height = imageDescriptor.height
        // Five feature channels require two RGBA slices per image. The
        // testMPSImageFeatureSlicesAndBatch probe uses 2x1x5, two images:
        // 4 slices * 2 pixels * 4 bytes = 32 bytes (previously 16).
        let slicesPerImage = max((imageDescriptor.featureChannels + 3) / 4, 1)
        descriptor.arrayLength = max(imageDescriptor.numberOfImages, 1) * slicesPerImage
        descriptor.textureType = descriptor.arrayLength > 1 ? .type2DArray : .type2D
        descriptor.usage = imageDescriptor.usage
        descriptor.cpuCacheMode = imageDescriptor.cpuCacheMode
        descriptor.storageMode = imageDescriptor.storageMode
        let texture: any MTLTexture
        if let host = device as? MPSHostDevice {
            texture = host.makeTexture(descriptor: descriptor)
        } else {
            texture = MPSHostTexture(device: device, descriptor: descriptor)
        }
        self.init(
            device: device,
            texture: texture,
            featureChannels: imageDescriptor.featureChannels,
            featureChannelFormat: imageDescriptor.channelFormat,
            numberOfImages: imageDescriptor.numberOfImages,
            parent: nil
        )
    }

    public convenience init(texture: any MTLTexture, featureChannels: Int) {
        self.init(
            device: texture.device,
            texture: texture,
            featureChannels: featureChannels,
            featureChannelFormat: mpsChannelFormat(for: texture.pixelFormat),
            numberOfImages: max(texture.arrayLength / max((featureChannels + 3) / 4, 1), 1),
            parent: nil
        )
    }

    public init(parentImage parent: MPSImage, sliceRange: NSRange, featureChannels: Int) {
        self.device = parent.device
        self.width = parent.width
        self.height = parent.height
        self.featureChannels = featureChannels
        self.numberOfImages = sliceRange.length
        self.featureChannelFormat = parent.featureChannelFormat
        self.pixelFormat = parent.pixelFormat
        self.textureType = parent.textureType
        self.usage = parent.usage
        self.parent = parent
        self.pixelSize = parent.pixelSize
        self.precision = parent.precision
        self.texture = parent.texture
        self.hostStorage = parent.hostStorage
        super.init()
        _ = sliceRange
    }

    private init(
        device: any MTLDevice,
        texture: any MTLTexture,
        featureChannels: Int,
        featureChannelFormat: MPSImageFeatureChannelFormat,
        numberOfImages: Int,
        parent: MPSImage?
    ) {
        self.device = device
        self.texture = texture
        self.width = texture.width
        self.height = texture.height
        self.featureChannels = featureChannels
        self.numberOfImages = numberOfImages
        self.featureChannelFormat = featureChannelFormat
        self.pixelFormat = texture.pixelFormat
        self.textureType = texture.textureType
        self.usage = texture.usage
        self.parent = parent
        self.pixelSize = mpsHostBytesPerPixel(texture.pixelFormat)
        self.precision = mpsPrecision(for: featureChannelFormat)
        if let host = texture as? MPSHostTexture {
            self.hostStorage = host.bytes
        } else {
            self.hostStorage = Data(
                count: max(texture.width, 1) * max(texture.height, 1) * max(featureChannels, 1)
                    * max(numberOfImages, 1) * mpsHostBytesPerChannel(featureChannelFormat)
            )
        }
        super.init()
    }

    open func resourceSize() -> Int {
        hostStorage.count
    }

    open func setPurgeableState(_ state: MPSPurgeableState) -> MPSPurgeableState {
        if state == .keepCurrent { return .nonVolatile }
        return state
    }

    open func subImage(withFeatureChannelRange range: NSRange) -> MPSImage {
        MPSImage(parentImage: self, sliceRange: NSRange(location: 0, length: 1), featureChannels: range.length)
    }

    open func batchRepresentation() -> [MPSImage] {
        batchRepresentation(withSubRange: NSRange(location: 0, length: numberOfImages))
    }

    open func batchRepresentation(withSubRange subRange: NSRange) -> [MPSImage] {
        let count = max(subRange.length, 0)
        if count <= 1 { return [self] }
        return (0..<count).map { index in
            MPSImage(
                parentImage: self,
                sliceRange: NSRange(location: subRange.location + index, length: 1),
                featureChannels: featureChannels
            )
        }
    }

    open func synchronize(on commandBuffer: any MTLCommandBuffer) {
        _ = commandBuffer
    }

    open func readBytes(
        _ dataBytes: UnsafeMutableRawPointer,
        dataLayout: MPSDataLayout,
        imageIndex: Int
    ) {
        let params = MPSImageReadWriteParams(
            featureChannelOffset: 0,
            numberOfFeatureChannelsToReadWrite: featureChannels
        )
        readBytes(
            dataBytes,
            dataLayout: dataLayout,
            bytesPerRow: mpsHostBytesPerRow(
                width: width,
                featureChannels: featureChannels,
                format: featureChannelFormat,
                layout: dataLayout
            ),
            region: MTLRegion.make2D(0, 0, width, height),
            featureChannelInfo: params,
            imageIndex: imageIndex
        )
    }

    open func readBytes(
        _ dataBytes: UnsafeMutableRawPointer,
        dataLayout: MPSDataLayout,
        bytesPerRow: Int,
        region: MTLRegion,
        featureChannelInfo: MPSImageReadWriteParams,
        imageIndex: Int
    ) {
        readBytes(
            dataBytes,
            dataLayout: dataLayout,
            bytesPerRow: bytesPerRow,
            bytesPerImage: bytesPerRow * max(region.size.height, 1),
            region: region,
            featureChannelInfo: featureChannelInfo,
            imageIndex: imageIndex
        )
    }

    open func readBytes(
        _ dataBytes: UnsafeMutableRawPointer,
        dataLayout: MPSDataLayout,
        bytesPerRow: Int,
        bytesPerImage: Int,
        region: MTLRegion,
        featureChannelInfo: MPSImageReadWriteParams,
        imageIndex: Int
    ) {
        copyRegion(
            region,
            featureChannelInfo: featureChannelInfo,
            bytesPerRow: bytesPerRow,
            bytesPerImage: bytesPerImage,
            imageIndex: imageIndex,
            dataLayout: dataLayout,
            destination: dataBytes,
            writing: false
        )
    }

    open func writeBytes(
        _ dataBytes: UnsafeRawPointer,
        dataLayout: MPSDataLayout,
        imageIndex: Int
    ) {
        let params = MPSImageReadWriteParams(
            featureChannelOffset: 0,
            numberOfFeatureChannelsToReadWrite: featureChannels
        )
        writeBytes(
            dataBytes,
            dataLayout: dataLayout,
            bytesPerRow: mpsHostBytesPerRow(
                width: width,
                featureChannels: featureChannels,
                format: featureChannelFormat,
                layout: dataLayout
            ),
            region: MTLRegion.make2D(0, 0, width, height),
            featureChannelInfo: params,
            imageIndex: imageIndex
        )
    }

    open func writeBytes(
        _ dataBytes: UnsafeRawPointer,
        dataLayout: MPSDataLayout,
        bytesPerRow: Int,
        region: MTLRegion,
        featureChannelInfo: MPSImageReadWriteParams,
        imageIndex: Int
    ) {
        writeBytes(
            dataBytes,
            dataLayout: dataLayout,
            bytesPerRow: bytesPerRow,
            bytesPerImage: bytesPerRow * max(region.size.height, 1),
            region: region,
            featureChannelInfo: featureChannelInfo,
            imageIndex: imageIndex
        )
    }

    open func writeBytes(
        _ dataBytes: UnsafeRawPointer,
        dataLayout: MPSDataLayout,
        bytesPerRow: Int,
        bytesPerImage: Int,
        region: MTLRegion,
        featureChannelInfo: MPSImageReadWriteParams,
        imageIndex: Int
    ) {
        copyRegion(
            region,
            featureChannelInfo: featureChannelInfo,
            bytesPerRow: bytesPerRow,
            bytesPerImage: bytesPerImage,
            imageIndex: imageIndex,
            dataLayout: dataLayout,
            destination: UnsafeMutableRawPointer(mutating: dataBytes),
            writing: true
        )
    }

    open func writeBytes(
        _ dataBytes: UnsafeRawPointer,
        dataLayout: MPSDataLayout,
        bytesPerColumn: Int,
        bytesPerRow: Int,
        bytesPerImage: Int,
        region: MTLRegion,
        featureChannelInfo: MPSImageReadWriteParams,
        imageIndex: Int
    ) {
        _ = bytesPerColumn
        writeBytes(
            dataBytes,
            dataLayout: dataLayout,
            bytesPerRow: bytesPerRow,
            bytesPerImage: bytesPerImage,
            region: region,
            featureChannelInfo: featureChannelInfo,
            imageIndex: imageIndex
        )
    }

    private func copyRegion(
        _ region: MTLRegion,
        featureChannelInfo: MPSImageReadWriteParams,
        bytesPerRow: Int,
        bytesPerImage: Int,
        imageIndex: Int,
        dataLayout: MPSDataLayout,
        destination: UnsafeMutableRawPointer,
        writing: Bool
    ) {
        let channelBytes = mpsHostBytesPerChannel(featureChannelFormat)
        let channels = featureChannelInfo.numberOfFeatureChannelsToReadWrite
        let channelOffset = featureChannelInfo.featureChannelOffset
        let x0 = max(region.origin.x, 0)
        let y0 = max(region.origin.y, 0)
        let rw = min(region.size.width, width - x0)
        let rh = min(region.size.height, height - y0)
        guard rw > 0, rh > 0, channels > 0, channelOffset >= 0,
              channelOffset <= featureChannels, channels <= featureChannels - channelOffset,
              imageIndex >= 0, imageIndex < numberOfImages else { return }
        let lanes = max(pixelSize / channelBytes, 1)
        let slicesPerImage = (featureChannels + lanes - 1) / lanes
        let sliceBytes = width * height * pixelSize
        let planar = dataLayout == .featureChannelsxHeightxWidth
        let rowBytes = max(bytesPerRow, rw * (planar ? 1 : channels) * channelBytes)
        let planeBytes = max(bytesPerImage, rowBytes * rh)
        // Host texture storage follows array-slice order. External HWC/CHW
        // buffers remain tightly packed except for caller-specified strides.
        // Read current texture bytes so image wrappers observe texture writes.
        if let host = texture as? MPSHostTexture { hostStorage = host.bytes }
        guard (imageIndex + 1) * slicesPerImage * sliceBytes <= hostStorage.count else { return }
        hostStorage.withUnsafeMutableBytes { buffer in
            guard let base = buffer.baseAddress else { return }
            for row in 0..<rh {
                for col in 0..<rw {
                    for channel in 0..<channels {
                        let feature = channelOffset + channel
                        let slice = imageIndex * slicesPerImage + feature / lanes
                        let imageByte = slice * sliceBytes + ((y0 + row) * width + x0 + col) * pixelSize
                            + (feature % lanes) * channelBytes
                        let externalByte = planar
                            ? channel * planeBytes + row * rowBytes + col * channelBytes
                            : row * rowBytes + (col * channels + channel) * channelBytes
                        let imagePointer = base.advanced(by: imageByte)
                        let externalPointer = destination.advanced(by: externalByte)
                        if writing {
                            imagePointer.copyMemory(from: UnsafeRawPointer(externalPointer), byteCount: channelBytes)
                        } else {
                            externalPointer.copyMemory(from: UnsafeRawPointer(imagePointer), byteCount: channelBytes)
                        }
                    }
                }
            }
        }
        if writing, let host = texture as? MPSHostTexture { host.bytes = hostStorage }
    }

    func mpsHostStorageCount() -> Int { hostStorage.count }

    func mpsWithHostStorage<R>(_ body: (UnsafeMutableRawBufferPointer) -> R) -> R {
        hostStorage.withUnsafeMutableBytes(body)
    }

    func mpsCommitHostStorage() {
        if let host = texture as? MPSHostTexture {
            host.bytes = hostStorage
        }
    }
}

open class MPSTemporaryImage: MPSImage {
    open override class func defaultAllocator() -> any MPSImageAllocator {
        MPSImageDefaultAllocator()
    }

    public class func prefetchStorage(
        with commandBuffer: any MTLCommandBuffer,
        imageDescriptorList descriptorList: [MPSImageDescriptor]
    ) {
        _ = (commandBuffer, descriptorList)
    }

    public convenience init(commandBuffer: any MTLCommandBuffer, imageDescriptor: MPSImageDescriptor) {
        self.init(device: commandBuffer.device, imageDescriptor: imageDescriptor)
        readCount = 1
    }

    public convenience init(
        commandBuffer: any MTLCommandBuffer,
        textureDescriptor: MTLTextureDescriptor
    ) {
        let texture: any MTLTexture
        if let host = commandBuffer.device as? MPSHostDevice {
            texture = host.makeTexture(descriptor: textureDescriptor)
        } else {
            texture = MPSHostTexture(device: commandBuffer.device, descriptor: textureDescriptor)
        }
        self.init(texture: texture, featureChannels: 4)
        readCount = 1
    }

    public convenience init(
        commandBuffer: any MTLCommandBuffer,
        textureDescriptor: MTLTextureDescriptor,
        featureChannels: Int
    ) {
        let texture: any MTLTexture
        if let host = commandBuffer.device as? MPSHostDevice {
            texture = host.makeTexture(descriptor: textureDescriptor)
        } else {
            texture = MPSHostTexture(device: commandBuffer.device, descriptor: textureDescriptor)
        }
        self.init(texture: texture, featureChannels: featureChannels)
        readCount = 1
    }
}

public func MPSGetImageType(_ image: MPSImage) -> MPSImageType {
    var raw: UInt32 = MPSImageType2d.rawValue
    if image.numberOfImages > 1 {
        raw = MPSImageType2d_array.rawValue
    }
    switch image.featureChannelFormat {
    case .unorm8:
        raw |= MPSImageType_texelFormatUnorm8.rawValue
    case .float16:
        raw |= MPSImageType_texelFormatFloat16.rawValue
    default:
        break
    }
    return MPSImageType(raw)
}

public func MPSImageBatchIncrementReadCount(_ batch: [MPSImage], _ amount: Int) -> Int {
    for image in batch {
        if image.readCount == Int.max { continue }
        image.readCount += amount
    }
    return batch.count
}

public func MPSImageBatchIterate(
    _ batch: [MPSImage],
    _ iteratorBlock: @escaping (MPSImage, Int) -> Int
) -> Int {
    for (index, image) in batch.enumerated() {
        let status = iteratorBlock(image, index)
        if status != 0 { return status }
    }
    return 0
}

public func MPSImageBatchResourceSize(_ batch: [MPSImage]) -> Int {
    batch.reduce(0) { $0 + $1.resourceSize() }
}

public func MPSImageBatchSynchronize(_ batch: [MPSImage], _ cmdBuf: any MTLCommandBuffer) {
    for image in batch {
        image.synchronize(on: cmdBuf)
    }
}

func mpsPixelFormat(
    channelFormat: MPSImageFeatureChannelFormat,
    featureChannels: Int
) -> MTLPixelFormat {
    switch channelFormat {
    case .float32:
        return featureChannels <= 1 ? .r32Float : .rgba32Float
    case .float16:
        return featureChannels <= 1 ? .r16Float : .rgba16Float
    case .unorm8:
        return featureChannels <= 1 ? .r8Unorm : .rgba8Unorm
    default:
        return featureChannels <= 1 ? .r8Unorm : .rgba8Unorm
    }
}

func mpsChannelFormat(for format: MTLPixelFormat) -> MPSImageFeatureChannelFormat {
    switch format {
    case .r32Float, .rgba32Float:
        return .float32
    case .r16Float, .rgba16Float:
        return .float16
    default:
        return .unorm8
    }
}

func mpsPrecision(for format: MPSImageFeatureChannelFormat) -> Int {
    switch format {
    case .float32:
        return 32
    case .float16, .unorm16:
        return 16
    default:
        return 8
    }
}

func mpsHostBytesPerChannel(_ format: MPSImageFeatureChannelFormat) -> Int {
    switch format {
    case .float32:
        return 4
    case .float16, .unorm16:
        return 2
    default:
        return 1
    }
}

func mpsHostBytesPerRow(
    width: Int,
    featureChannels: Int,
    format: MPSImageFeatureChannelFormat,
    layout: MPSDataLayout
) -> Int {
    let channelBytes = mpsHostBytesPerChannel(format)
    if layout == .featureChannelsxHeightxWidth {
        return max(width, 1) * channelBytes
    }
    return max(width, 1) * max(featureChannels, 1) * channelBytes
}
