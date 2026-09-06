import Dispatch
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

func testSharedEventHostClock() {
    let device = MTLCreateSystemDefaultDevice()!
    let event = device.makeSharedEvent()!
    event.label = "host-clock"
    precondition(event.label == "host-clock")
    precondition(event.device.name == device.name)
    precondition(event.signaledValue == 0)
    event.signaledValue = 3
    precondition(event.signaledValue == 3)
    event.signaledValue = 1
    precondition(event.signaledValue == 3)
    precondition(event.wait(untilSignaledValue: 3, timeoutMS: 0))
    precondition(!event.wait(untilSignaledValue: 4, timeoutMS: 0))
    var notified = false
    let listener = MTLSharedEventListener()
    _ = listener.dispatchQueue
    event.notify(listener, atValue: 5) { shared, value in
        notified = true
        precondition(value >= 5)
        precondition(shared.signaledValue >= 5)
    }
    event.signaledValue = 5
    precondition(notified)
    let sharedListener = MTLSharedEventListener.shared()
    precondition(sharedListener === MTLSharedEventListener.shared())
    let queued = MTLSharedEventListener(dispatchQueue: DispatchQueue.global())
    _ = queued.dispatchQueue
    let handle = event.makeSharedEventHandle()
    handle.label = "cloned"
    let restored = device.makeSharedEvent(handle: handle)!
    precondition(restored.signaledValue == 5)
    let queue = device.makeCommandQueue()!
    let commandBuffer = queue.makeCommandBuffer()!
    commandBuffer.encodeSignalEvent(event, value: 7)
    commandBuffer.encodeWaitForEvent(event, value: 7)
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
    precondition(event.signaledValue >= 7)
    _ = MTLSharedEventHandle.supportsSecureCoding
}

func testResidencySetAndRasterizationRateMap() {
    let device = MTLCreateSystemDefaultDevice()!
    let residencyDesc = MTLResidencySetDescriptor()
    residencyDesc.label = "resident"
    residencyDesc.initialCapacity = 4
    let residency = try! device.makeResidencySet(descriptor: residencyDesc)
    residency.label = "cpu-set"
    precondition(residency.device.name == device.name)
    precondition(residency.label == "cpu-set")
    let buffer = device.makeBuffer(length: 32, options: .storageModeShared)!
    let textureDesc = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .r8Unorm,
        width: 2,
        height: 2,
        mipmapped: false
    )
    let texture = device.makeTexture(descriptor: textureDesc)!
    residency.addAllocation(buffer)
    residency.addAllocations([texture])
    precondition(residency.containsAllocation(buffer))
    precondition(residency.allocationCount == 2)
    precondition(residency.allAllocations.count == 2)
    precondition(residency.allocatedSize >= 32)
    residency.commit()
    residency.requestResidency()
    residency.removeAllocation(texture)
    precondition(!residency.containsAllocation(texture))
    residency.removeAllocations([buffer])
    residency.removeAllAllocations()
    precondition(residency.allocationCount == 0)
    residency.endResidency()
    let queue = device.makeCommandQueue()!
    queue.addResidencySet(residency)
    queue.addResidencySets([residency])
    queue.removeResidencySet(residency)
    queue.removeResidencySets([residency])
    let commandBuffer = queue.makeCommandBuffer()!
    commandBuffer.useResidencySet(residency)
    commandBuffer.useResidencySets([residency])
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()

    let layer = MTLRasterizationRateLayerDescriptor(sampleCount: MTLSizeMake(2, 2, 1))
    precondition(layer.maxSampleCount.width == 2)
    layer.sampleCount = MTLSizeMake(2, 2, 1)
    layer.horizontal[0] = 1
    layer.horizontal[1] = 1
    layer.vertical[0] = 1
    layer.vertical[1] = 1
    let fromArrays = MTLRasterizationRateLayerDescriptor(horizontal: [1, 1], vertical: [1, 1])
    precondition(fromArrays.horizontal[0] == 1)
    let copied = fromArrays.copy() as! MTLRasterizationRateLayerDescriptor
    precondition(copied.vertical[0] == 1)
    let rateDesc = MTLRasterizationRateMapDescriptor(screenSize: MTLSizeMake(8, 8, 1), layer: layer, label: "identity")
    rateDesc.setLayer(layer, at: 0)
    precondition(rateDesc.layerCount == 1)
    precondition(rateDesc.layer(at: 0) != nil)
    precondition(rateDesc.layers[0] != nil)
    rateDesc.screenSize = MTLSizeMake(8, 8, 1)
    let multi = MTLRasterizationRateMapDescriptor(
        screenSize: MTLSizeMake(4, 4, 1),
        layers: [layer],
        label: "multi"
    )
    precondition(multi.layerCount == 1)
    _ = MTLRasterizationRateMapDescriptor(screenSize: MTLSizeMake(2, 2, 1), label: "empty")
    let map = device.makeRasterizationRateMap(descriptor: rateDesc)!
    precondition(map.device.name == device.name)
    precondition(map.label == "identity")
    precondition(map.screenSize.width == 8)
    precondition(map.layerCount == 1)
    precondition(map.physicalGranularity.width == 1)
    precondition(map.physicalSize(layer: 0).width == 8)
    precondition(map.parameterBufferSizeAndAlign.size >= 16)
    let screen = MTLCoordinate2DMake(3, 4)
    let physical = map.physicalCoordinates(screenCoordinates: screen, layer: 0)
    precondition(physical.x == 3 && physical.y == 4)
    let back = map.screenCoordinates(physicalCoordinates: physical, layer: 0)
    precondition(back.x == 3)
    let param = device.makeBuffer(length: 64, options: .storageModeShared)!
    map.copyParameterData(buffer: param, offset: 0)
    precondition(param.contents().load(as: UInt32.self) == 8)
}
