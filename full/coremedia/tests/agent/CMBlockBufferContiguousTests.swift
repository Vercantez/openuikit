import CoreFoundation
import CoreMedia
import Foundation

private func verifyCMContiguousProtocol<T: CMBlockBufferProtocol>(_ buffer: T) throws {
    let contiguous = try buffer.makeContiguous()
    let compacted = try contiguous.dataBytes()
    let original = try buffer.dataBytes()
    precondition(compacted == original)
    let stored = try buffer.withContiguousStorage { bytes in Array(bytes) }
    precondition(stored == Array(original))
}

func testCMBlockBufferMakeContiguousAndContiguousStorage() {
    let allocator: CMBlockBuffer.CustomBlockAllocator = { count in
        UnsafeMutableRawPointer.allocate(byteCount: max(count, 1), alignment: 1)
    }
    let deallocator: CMBlockBuffer.CustomBlockDeallocator = { pointer, _ in
        pointer.deallocate()
    }

    // Concrete CMBlockBuffer host: storage is already contiguous, so the
    // compacted buffer holds an equal copy of the bytes.
    let buffer = CMBlockBuffer(data: Data([1, 2, 3, 4, 5]))
    let contiguous = try! buffer.makeContiguous()
    precondition(try! contiguous.dataBytes() == Data([1, 2, 3, 4, 5]))
    let custom = try! buffer.makeContiguous(allocator: allocator, deallocator: deallocator)
    precondition(try! custom.dataBytes() == Data([1, 2, 3, 4, 5]))
    let seen = try! buffer.withContiguousStorage { bytes in Array(bytes) }
    precondition(seen == [1, 2, 3, 4, 5])
    try! verifyCMContiguousProtocol(buffer)

    // Slice host: only the sliced range is compacted and yielded.
    let slice = buffer[1..<4]
    let sliceContiguous = try! slice.makeContiguous()
    precondition(try! sliceContiguous.dataBytes() == Data([2, 3, 4]))
    let sliceCustom = try! slice.makeContiguous(allocator: allocator, deallocator: deallocator)
    precondition(try! sliceCustom.dataBytes() == Data([2, 3, 4]))
    let sliceSeen = try! slice.withContiguousStorage { bytes in Array(bytes) }
    precondition(sliceSeen == [2, 3, 4])
    try! verifyCMContiguousProtocol(slice)

    // Empty input compacts to an empty buffer without touching the allocator.
    let empty = CMBlockBuffer()
    let emptyContiguous = try! empty.makeContiguous()
    precondition(try! emptyContiguous.dataBytes() == Data())
    let emptySeen = try! empty.withContiguousStorage { bytes in bytes.count }
    precondition(emptySeen == 0)
}
