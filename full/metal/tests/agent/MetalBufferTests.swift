import Foundation
import Metal

func testBufferStorage() {
    let device = MTLCreateSystemDefaultDevice()!
    let bytes: [UInt8] = [1, 2, 3, 4, 5]
    let source = bytes.withUnsafeBytes { raw in
        device.makeBuffer(bytes: raw.baseAddress!, length: bytes.count, options: .storageModeShared)!
    }
    precondition(source.length == 5)
    precondition(source.allocatedSize >= 5)
    precondition(source.contents().load(as: UInt8.self) == 1)
    source.didModifyRange(0..<5)
    source.addDebugMarker("src", range: 0..<5)
    source.removeAllDebugMarkers()
    source.label = "source"
    precondition(source.label == "source")
    precondition(source.storageMode == .shared)
    precondition(source.cpuCacheMode == .defaultCache)
    _ = source.hazardTrackingMode
    _ = source.resourceOptions
    _ = source.gpuAddress
    _ = source.sparseBufferTier
    _ = source.heap
    _ = source.heapOffset
    _ = source.setPurgeableState(.nonVolatile)
    source.makeAliasable()
    _ = source.isAliasable()
    let destination = device.makeBuffer(length: 8, options: [])!
    precondition(destination.length == 8)
    precondition(destination.contents().load(as: UInt8.self) == 0)
    var borrowed = [UInt8](repeating: 9, count: 4)
    let noCopy = borrowed.withUnsafeMutableBytes { raw in
        device.makeBuffer(
            bytesNoCopy: raw.baseAddress!,
            length: 4,
            options: .cpuCacheModeDefaultCache,
            deallocator: { _, _ in }
        )!
    }
    precondition(noCopy.length == 4)
    let privateBuf = device.makeBuffer(length: 4, options: .storageModePrivate)!
    precondition(privateBuf.storageMode == .private)
    let viewDesc = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .r8Unorm,
        width: 4,
        height: 1,
        mipmapped: false
    )
    viewDesc.usage = [.shaderRead]
    let view = destination.makeTexture(descriptor: viewDesc, offset: 0, bytesPerRow: 4)
    precondition(view != nil)
    _ = destination.device
}
