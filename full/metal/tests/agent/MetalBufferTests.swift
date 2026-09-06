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
    privateBuf.contents().storeBytes(of: UInt32(0xAABBCCDD), as: UInt32.self)
    privateBuf.didModifyRange(0..<4)
    let privateDest = device.makeBuffer(length: 4, options: .storageModeShared)!
    let queue = device.makeCommandQueue()!
    let copy = queue.makeCommandBuffer()!
    let blit = copy.makeBlitCommandEncoder()!
    blit.copy(from: privateBuf, sourceOffset: 0, to: privateDest, destinationOffset: 0, size: 4)
    blit.endEncoding()
    copy.commit()
    copy.waitUntilCompleted()
    precondition(privateDest.contents().load(as: UInt32.self) == 0xAABBCCDD)
    let viewDesc = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .r8Unorm,
        width: 2,
        height: 2,
        mipmapped: false
    )
    viewDesc.usage = [.shaderRead]
    let layout: [UInt8] = [1, 2, 0xAA, 0xBB, 3, 4, 0xCC, 0xDD]
    layout.withUnsafeBytes { raw in
        destination.contents().copyMemory(from: raw.baseAddress!, byteCount: 8)
    }
    let view = destination.makeTexture(descriptor: viewDesc, offset: 0, bytesPerRow: 4)!
    precondition(view.buffer === destination)
    precondition(view.bufferOffset == 0)
    precondition(view.bufferBytesPerRow == 4)
    var fromView = [UInt8](repeating: 0, count: 4)
    fromView.withUnsafeMutableBytes { raw in
        view.getBytes(
            raw.baseAddress!,
            bytesPerRow: 2,
            from: MTLRegionMake2D(0, 0, 2, 2),
            mipmapLevel: 0
        )
    }
    precondition(fromView == [1, 2, 3, 4])
    _ = destination.device
}
