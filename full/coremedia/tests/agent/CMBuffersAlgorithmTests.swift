import CoreFoundation
import CoreMedia
import Foundation

private func cmBuffersSample(pts: Int64, duration: Int64, size: Int) -> CMSampleBuffer {
    let timing = CMSampleTimingInfo(
        duration: CMTime(value: duration, timescale: 1),
        presentationTimeStamp: CMTime(value: pts, timescale: 1),
        decodeTimeStamp: .invalid
    )
    return try! CMSampleBuffer(
        dataBuffer: CMBlockBuffer(data: Data(repeating: 7, count: size)),
        formatDescription: nil,
        numSamples: 1,
        sampleTimings: [timing],
        sampleSizes: [size],
        dataReady: true
    )
}

private func cmBuffersQueue() -> (CMBufferQueue, CMSampleBuffer, CMSampleBuffer, CMSampleBuffer) {
    let q = CMBufferQueue(capacity: 8, handlers: .unsortedSampleBuffers)
    let a = cmBuffersSample(pts: 10, duration: 2, size: 4)
    let b = cmBuffersSample(pts: 12, duration: 2, size: 8)
    let c = cmBuffersSample(pts: 14, duration: 2, size: 2)
    try! q.enqueue(a)
    try! q.enqueue(b)
    try! q.enqueue(c)
    return (q, a, b, c)
}

func testCMBufferQueueBuffersAlgorithms() {
    let (q, a, b, c) = cmBuffersQueue()
    let buffers = q.buffers
    let expected: [CMBuffer] = [a, b, c]
    let sizes = buffers.map { ($0 as? CMSampleBuffer)?.totalSampleSize ?? -1 }
    precondition(sizes == [4, 8, 2])
    let compacted = buffers.compactMap { ($0 as? CMSampleBuffer)?.totalSampleSize }
    precondition(compacted == [4, 8, 2])
    let droppedNil = buffers.compactMap { ($0 as? CMSampleBuffer)?.totalSampleSize == 8 ? nil : $0 }
    precondition(droppedNil.count == 2)
    let pairs = Array(buffers.enumerated())
    precondition(pairs.count == 3)
    precondition(pairs[0].offset == 0 && (pairs[0].element as AnyObject) === a)
    precondition(pairs[2].offset == 2 && (pairs[2].element as AnyObject) === c)
    precondition(buffers.filter { (($0 as? CMSampleBuffer)?.totalSampleSize ?? 0) != 8 }.count == 2)
    precondition((buffers.first(where: { (($0 as? CMSampleBuffer)?.totalSampleSize ?? 0) == 8 }) as AnyObject?) === b)
    precondition(buffers.contains(where: { (($0 as? CMSampleBuffer)?.totalSampleSize ?? 0) == 2 }))
    precondition(!buffers.contains(where: { (($0 as? CMSampleBuffer)?.totalSampleSize ?? 0) == 99 }))
    precondition(buffers.allSatisfy { (($0 as? CMSampleBuffer)?.totalSampleSize ?? 0) > 0 })
    precondition(buffers.count(where: { (($0 as? CMSampleBuffer)?.totalSampleSize ?? 0) >= 4 }) == 2)
    var visited = 0
    buffers.forEach { _ in visited += 1 }
    precondition(visited == 3)
    precondition(buffers.reduce(0) { $0 + (($1 as? CMSampleBuffer)?.totalSampleSize ?? 0) } == 14)
    precondition(
        buffers.reduce(into: 0) { $0 += (($1 as? CMSampleBuffer)?.totalSampleSize ?? 0) } == 14
    )
    precondition((buffers.min(by: cmBufferSizeLess) as AnyObject?) === c)
    precondition((buffers.max(by: cmBufferSizeLess) as AnyObject?) === b)
    let ordered = buffers.sorted(by: cmBufferSizeLess).map {
        ($0 as? CMSampleBuffer)?.totalSampleSize ?? -1
    }
    precondition(ordered == [2, 4, 8])
    precondition(buffers.elementsEqual(expected, by: ===))
    precondition(!buffers.elementsEqual([expected[0], expected[2]], by: ===))
    precondition(buffers.starts(with: [expected[0], expected[1]], by: ===))
    precondition(!buffers.starts(with: [expected[1]], by: ===))
    precondition(buffers.lexicographicallyPrecedes([b] as [CMBuffer], by: cmBufferSizeLess))
    let chunks = buffers.split(whereSeparator: { ($0 as AnyObject) === b })
    precondition(chunks.count == 2)
    precondition(Array(buffers.prefix(2)).count == 2)
    precondition(buffers.prefix(while: { (($0 as? CMSampleBuffer)?.totalSampleSize ?? 0) != 8 }).count == 1)
    precondition(Array(buffers.drop(while: { (($0 as? CMSampleBuffer)?.totalSampleSize ?? 0) != 8 })).count == 2)
    precondition(Array(buffers.dropFirst(1)).count == 2)
    precondition(buffers.dropLast(1).count == 2)
    precondition(buffers.suffix(2).count == 2)
    precondition(buffers.reversed().count == 3)
    precondition((buffers.reversed().first as AnyObject?) === c)
    precondition(buffers.flatMap { [$0] }.count == 3)
    precondition(buffers.lazy.filter { _ in true }.count == 3)
    precondition(buffers.underestimatedCount == 0)
    var storageCalls = 0
    let contiguous: Int? = buffers.withContiguousStorageIfAvailable { _ in
        storageCalls += 1
        return 3
    }
    precondition(contiguous == nil && storageCalls == 0)
    let shuffledOnce = buffers.shuffled()
    precondition(shuffledOnce.count == 3)
    precondition(shuffledOnce.map { ($0 as? CMSampleBuffer)?.totalSampleSize ?? -1 }.sorted() == [2, 4, 8])
    var generator = SystemRandomNumberGenerator()
    let shuffledSeeded = buffers.shuffled(using: &generator)
    precondition(shuffledSeeded.count == 3)
}

private func cmBufferSizeLess(_ left: CMBuffer, _ right: CMBuffer) -> Bool {
    ((left as? CMSampleBuffer)?.totalSampleSize ?? 0) < ((right as? CMSampleBuffer)?.totalSampleSize ?? 0)
}

func testCMBlockBufferOverlayInits() {
    let cap = try! CMBlockBuffer(capacity: 16, flags: [])
    precondition(cap.dataLength == 0)
    var threw = false
    do {
        _ = try CMBlockBuffer(capacity: -1, flags: [])
    } catch {
        threw = true
    }
    precondition(threw)
    var raw = Data([1, 2, 3, 4])
    let fromPtr = try! raw.withUnsafeMutableBytes { pointer in
        try CMBlockBuffer(buffer: pointer, allocator: kCFAllocatorDefault, flags: [])
    }
    precondition(try! fromPtr.dataBytes() == Data([1, 2, 3, 4]))
    let slicePtr = try! raw.withUnsafeMutableBytes { pointer in
        try CMBlockBuffer(buffer: pointer[1..<3], allocator: nil, flags: [])
    }
    precondition(try! slicePtr.dataBytes() == Data([2, 3]))
    var freed = 0
    let fromDealloc = try! raw.withUnsafeMutableBytes { pointer in
        try CMBlockBuffer(
            buffer: pointer,
            deallocator: { _, _ in freed += 1 },
            flags: []
        )
    }
    precondition(try! fromDealloc.dataBytes() == Data([1, 2, 3, 4]))
    precondition(freed == 1)
    var freedSlice = 0
    let fromDeallocSlice = try! raw.withUnsafeMutableBytes { pointer in
        try CMBlockBuffer(
            buffer: pointer[0..<2],
            deallocator: { _, _ in freedSlice += 1 },
            flags: []
        )
    }
    precondition(try! fromDeallocSlice.dataBytes() == Data([1, 2]))
    precondition(freedSlice == 1)
    let ranged = try! CMBlockBuffer(length: 8, allocator: nil, range: 1..<5, flags: [])
    precondition(ranged.dataLength == 4)
    precondition(try! ranged.dataBytes() == Data(repeating: 0, count: 4))
    let full = try! CMBlockBuffer(length: 3, allocator: nil, range: nil, flags: [])
    precondition(full.dataLength == 3)
    var allocated = 0
    var released = 0
    let custom = try! CMBlockBuffer(
        length: 8,
        allocator: { count in
            allocated += 1
            return UnsafeMutableRawPointer.allocate(byteCount: count, alignment: 1)
        },
        deallocator: { pointer, _ in
            released += 1
            pointer.deallocate()
        },
        range: 2..<6,
        flags: []
    )
    precondition(custom.dataLength == 4)
    precondition(allocated == 1 && released == 1)
    precondition(try! custom.dataBytes() == Data(repeating: 0, count: 4))
    let src = CMBlockBuffer(data: Data([9, 8, 7, 6]))
    let refd = try! CMBlockBuffer(bufferReference: src, flags: [])
    precondition(try! refd.dataBytes() == Data([9, 8, 7, 6]))
    let refdSlice = try! CMBlockBuffer(bufferReference: src.slice(from: 1, to: 3), flags: [])
    precondition(try! refdSlice.dataBytes() == Data([8, 7]))
    var source = CMBlockBufferCustomBlockSource()
    precondition(source.version == kCMBlockBufferCustomBlockSourceVersion)
    source.refCon = nil
    source.AllocateBlock = { _, count in UnsafeMutableRawPointer.allocate(byteCount: count, alignment: 1) }
    source.FreeBlock = { _, pointer, _ in pointer.deallocate() }
    precondition(source.AllocateBlock != nil && source.FreeBlock != nil)
    let rebuilt = CMBlockBufferCustomBlockSource(
        version: kCMBlockBufferCustomBlockSourceVersion,
        AllocateBlock: source.AllocateBlock,
        FreeBlock: source.FreeBlock,
        refCon: nil
    )
    precondition(rebuilt.version == source.version)
    precondition(rebuilt.refCon == nil)
    var out: CMBlockBuffer?
    withUnsafePointer(to: rebuilt) { pointer in
        precondition(
            CMBlockBufferCreateWithMemoryBlock(
                allocator: nil,
                memoryBlock: nil,
                blockLength: 4,
                blockAllocator: nil,
                customBlockSource: pointer,
                offsetToData: 0,
                dataLength: 4,
                flags: 0,
                blockBufferOut: &out
            ) == 0
        )
    }
    precondition(out?.dataLength == 4)
}
