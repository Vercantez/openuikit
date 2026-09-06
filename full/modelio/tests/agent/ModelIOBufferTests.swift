import Foundation
import ModelIO

func testMeshBufferMap() {
    var storage: UInt8 = 7
    let map = MDLMeshBufferMap(bytes: &storage, deallocator: nil)
    mdlCheck(map.bytes.load(as: UInt8.self) == 7, "bytes")
}

func testZoneDefault() {
    let allocator = MDLMeshBufferDataAllocator()
    let zone = MDLMeshBufferZoneDefault(allocator: allocator, capacity: 128)
    mdlCheck(zone.capacity == 128, "capacity")
    mdlCheck((zone.allocator as AnyObject) === allocator, "allocator")
}

func testMeshBufferData() {
    let payload = Data([1, 2, 3, 4])
    let buffer = MDLMeshBufferData(type: .vertex, data: payload)
    mdlCheck(buffer.data == payload, "data")
    mdlCheck(buffer.length == 4, "length")
    mdlCheck(buffer.type == .vertex, "type")
    buffer.fill(Data([9, 9]), offset: 1)
    mdlCheck(buffer.data[1] == 9, "fill")
}

func testMeshBufferDataLength() {
    let buffer = MDLMeshBufferData(type: .index, length: 16)
    mdlCheck(buffer.length == 16, "length init")
    mdlCheck(buffer.type == .index, "index type")
}

func testAllocator() {
    let allocator = MDLMeshBufferDataAllocator()
    let buffer = allocator.newBuffer(8, type: .custom)
    mdlCheck(buffer.length == 8, "newBuffer length")
    mdlCheck(buffer.type == .custom, "custom")
}

func testAllocatorProtocol() {
    let allocator: any MDLMeshBufferAllocator = MDLMeshBufferDataAllocator()
    let zone = allocator.newZone(64)
    mdlCheck(zone.capacity == 64, "zone")
    let data = Data(count: 4)
    let fromData = allocator.newBuffer(with: data, type: .vertex)
    mdlCheck(fromData.length == 4, "from data")
    let zoned = allocator.newBuffer(from: zone, data: data, type: .index)
    mdlCheck(zoned != nil, "zoned data")
    let zonedLen = allocator.newBuffer(from: zone, length: 2, type: .vertex)
    mdlCheck(zonedLen != nil, "zoned len")
    let sized = allocator.newZoneForBuffers(withSize: [NSNumber(value: 3), NSNumber(value: 5)], andType: [NSNumber(value: 1), NSNumber(value: 2)])
    mdlCheck(sized.capacity == 8, "sized zone")
}

func testMeshBufferProtocol() {
    let allocator = MDLMeshBufferDataAllocator()
    let buffer: any MDLMeshBuffer = allocator.newBuffer(with: Data([1, 2, 3]), type: .vertex)
    mdlCheck(buffer.length == 3, "length")
    mdlCheck(buffer.type == .vertex, "type")
    _ = buffer.zone
    _ = buffer.allocator
    let mapped = buffer.map()
    mdlCheck(mapped.bytes.load(as: UInt8.self) == 1, "map")
    let copied = buffer.copy(with: nil)
    mdlCheck(copied is MDLMeshBufferData, "copy")
}

func testZoneProtocol() {
    let allocator = MDLMeshBufferDataAllocator()
    let zone: any MDLMeshBufferZone = allocator.newZone(32)
    mdlCheck(zone.capacity == 32, "capacity")
    mdlCheck((zone.allocator as AnyObject) === allocator, "allocator identity")
}
