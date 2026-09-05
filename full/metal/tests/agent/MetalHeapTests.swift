import Foundation
import Metal

func testHeapFenceAndEvent() {
    let device = MTLCreateSystemDefaultDevice()!
    let heapDesc = MTLHeapDescriptor()
    heapDesc.size = 4096
    heapDesc.storageMode = .shared
    let heap = device.makeHeap(descriptor: heapDesc)!
    heap.label = "heap"
    precondition(heap.label == "heap")
    precondition(heap.size == 4096)
    precondition(heap.device.name == device.name)
    precondition(heap.storageMode == .shared)
    _ = heap.cpuCacheMode
    _ = heap.hazardTrackingMode
    _ = heap.resourceOptions
    _ = heap.type
    _ = heap.allocatedSize
    _ = heap.currentAllocatedSize
    _ = heap.usedSize
    _ = heap.maxAvailableSize(alignment: 16)
    _ = heap.setPurgeableState(.nonVolatile)
    let heapBuffer = heap.makeBuffer(length: 32, options: .storageModeShared)!
    precondition(heapBuffer.heap != nil)
    precondition(heapBuffer.length == 32)
    let placed = heap.makeBuffer(length: 16, options: [], offset: 64)
    precondition(placed != nil)
    let texDesc = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .r8Unorm,
        width: 4,
        height: 1,
        mipmapped: false
    )
    precondition(heap.makeTexture(descriptor: texDesc) != nil)
    precondition(heap.makeTexture(descriptor: texDesc, offset: 256) != nil)
    let fence = device.makeFence()!
    fence.label = "cpu-fence"
    precondition(fence.label == "cpu-fence")
    precondition(fence.device.name == device.name)
    let event = device.makeEvent()!
    event.label = "cpu-event"
    precondition(event.label == "cpu-event")
    precondition(event.device.name == device.name)
    let queue = device.makeCommandQueue()!
    let commandBuffer = queue.makeCommandBuffer()!
    commandBuffer.encodeSignalEvent(event, value: 1)
    commandBuffer.encodeWaitForEvent(event, value: 1)
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
}
