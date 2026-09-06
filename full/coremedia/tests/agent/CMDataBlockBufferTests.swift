import CoreFoundation
import CoreMedia
import Dispatch
import Foundation

func testCMReadOnlyDataBlockBufferCopyAndIndex() {
    let data = Data([0x10, 0x20, 0x30, 0x40])
    var buffer = CMReadOnlyDataBlockBuffer(data)
    precondition(buffer.count == 4)
    precondition(!buffer.isEmpty)
    precondition(buffer.isContiguous)
    precondition(buffer.startIndex == 0)
    precondition(buffer.endIndex == 4)
    precondition(buffer[0] == 0x10)
    precondition(buffer[3] == 0x40)
    let slice = buffer[1..<3]
    precondition(slice.count == 2)
    precondition(slice[0] == 0x20)
    let regions = buffer.regions
    precondition(regions.count == 1)
    precondition(regions[0].count == 4)
    precondition(regions[0].startIndex == 0)
    precondition(regions[0].endIndex == 4)
    precondition(regions[0][1] == 0x20)
    let fromBlock = CMReadOnlyDataBlockBuffer(unsafeBlockBuffer: CMBlockBuffer(data: data))
    precondition(fromBlock.count == 4)
    buffer.append(referenceOf: fromBlock)
    precondition(buffer.count == 8)
    var sum = 0
    let contiguousCount = buffer.withContiguousStorageIfAvailable { pointer -> Int in
        sum = Int(pointer[0])
        return pointer.count
    }
    precondition(contiguousCount == 8)
    precondition(sum == 0x10)
    let blockLength = buffer.withUnsafeBlockBuffer { block in
        CMBlockBufferGetDataLength(block)
    }
    precondition(blockLength == 8)
}

func testCMMutableDataBlockBufferReplaceAppendAndPointer() {
    var buffer = CMMutableDataBlockBuffer(count: 4)
    precondition(buffer.count == 4)
    precondition(buffer.isContiguous)
    precondition(buffer.isRangeContiguous(0..<4))
    buffer[0] = 1
    buffer[1] = 2
    buffer.replaceAll(repeating: 9)
    precondition(buffer[0] == 9)
    buffer.replaceAll(with: Data([5, 6, 7, 8]))
    precondition(buffer[3] == 8)
    buffer.replaceSubrange(1..<3, repeating: 0)
    precondition(buffer[1] == 0)
    precondition(buffer[2] == 0)
    buffer.extend(by: 2)
    precondition(buffer.count == 6)
    var other = CMMutableDataBlockBuffer(count: 2)
    other[0] = 0xAA
    buffer.append(referenceOf: other)
    precondition(buffer.count == 8)
    var destination = [UInt8](repeating: 0, count: 4)
    destination.withUnsafeMutableBytes { dest in
        buffer.copyBytes(to: dest, from: 0..<4)
    }
    precondition(destination[0] == 5)
    let mutated = buffer.withContiguousMutableStorageIfAvailable { pointer in
        pointer[0] = 0x11
        return pointer.count
    }
    precondition(mutated == buffer.count)
    precondition(buffer[0] == 0x11)
    var fired = false
    let source = CMMutableDataBlockBuffer.BlockSource(
        allocate: { count in
            fired = true
            let pointer = UnsafeMutableRawPointer.allocate(byteCount: count, alignment: 1)
            pointer.initializeMemory(as: UInt8.self, repeating: 0x42, count: count)
            return UnsafeMutableRawBufferPointer(start: pointer, count: count)
        },
        deallocate: { pointer in
            pointer.baseAddress?.deallocate()
        }
    )
    let allocated = CMMutableDataBlockBuffer(count: 3, blockSource: source)
    precondition(fired)
    precondition(allocated.count == 3)
    precondition(allocated[0] == 0x42)
    let pool = CMMutableDataBlockBuffer.MemoryPool(ageOutDuration: 0.5)
    let pooled = pool.makeBlockBuffer(count: 2)
    precondition(pooled.count == 2)
    pool.flush()
    var regionsSeen = 0
    let expectedRegionCount = buffer.count
    buffer.withUnsafeMutableBlockRegions { regions in
        regionsSeen = regions.count
        precondition(regions[0].count == expectedRegionCount)
    }
    precondition(regionsSeen == 1)
}

func testCMDataBlockBufferEmptyAndPlus() {
    let empty = CMReadOnlyDataBlockBuffer(subBlockCapacity: 4)
    precondition(empty.isEmpty)
    var mutable = CMMutableDataBlockBuffer(subBlockCapacity: 2, blockSource: nil)
    mutable.extend(by: 1)
    mutable[0] = 7
    let combined = empty + mutable
    precondition(combined.count == 1)
    precondition(combined[0] == 7)
    var lhs = CMReadOnlyDataBlockBuffer(Data([1]))
    lhs += CMReadOnlyDataBlockBuffer(Data([2]))
    precondition(lhs.count == 2)
    var mutableSum = CMMutableDataBlockBuffer(count: 1)
    mutableSum[0] = 3
    mutableSum += CMMutableDataBlockBuffer(count: 0)
    precondition(mutableSum.count == 1)
    let fromDispatch = CMReadOnlyDataBlockBuffer(DispatchData.empty)
    precondition(fromDispatch.isEmpty)
}

func testCMBlockBufferSliceOwnerRange() {
    let buffer = CMBlockBuffer(data: Data([1, 2, 3, 4]))
    let slice = buffer.slice(from: 1, to: 3)
    precondition(slice.owner === buffer)
    precondition(slice.startIndex == 1)
    precondition(slice.endIndex == 3)
    precondition(buffer.startIndex == 0)
    precondition(buffer.endIndex == 4)
    precondition(buffer.owner === buffer)
}
