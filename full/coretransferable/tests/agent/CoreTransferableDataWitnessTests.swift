import Foundation
import CoreTransferable

private struct DataByteListStyle: FormatStyle, Sendable {
    typealias FormatInput = Data
    typealias FormatOutput = String

    func format(_ value: Data) -> String {
        value.map { String($0) }.joined(separator: ",")
    }
}

func testDataProtocolFirstAndLastRange() {
    let data = Data([1, 2, 3, 2, 9])
    let needle = Data([2, 3])
    let first = data.firstRange(of: needle)
    precondition(first != nil)
    precondition(data[first!] == needle)
    let firstIn = data.firstRange(of: needle, in: data.startIndex..<data.endIndex)
    precondition(firstIn == first)
    let last = data.lastRange(of: Data([2]))
    precondition(last != nil)
    precondition(data[last!] == Data([2]))
    let lastIn = data.lastRange(of: Data([2]), in: data.startIndex..<data.endIndex)
    precondition(lastIn == last)
    _ = Data.transferRepresentation
}

func testDataProtocolCopyBytes() {
    let data = Data([10, 20, 30, 40])
    let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: 4)
    defer { buffer.deallocate() }
    let copied = data.copyBytes(to: buffer)
    precondition(copied == 4)
    precondition(Array(buffer) == [10, 20, 30, 40])
    let raw = UnsafeMutableRawBufferPointer.allocate(byteCount: 4, alignment: 1)
    defer { raw.deallocate() }
    let rawCopied = data.copyBytes(to: raw)
    precondition(rawCopied == 4)
}

func testDataMutableResetBytes() {
    var data = Data([1, 2, 3, 4])
    data.resetBytes(in: 1..<3)
    precondition(data == Data([1, 0, 0, 4]))
}

func testDataStringProcessingFirstRange() {
    let data = Data([1, 2, 3, 2])
    let fromArray = data.firstRange(of: [UInt8(2), 3])
    precondition(fromArray != nil)
    precondition(Array(data[fromArray!]) == [2, 3])
}

func testDataBidirectionalRemoveLast() {
    var data = Data([1, 2, 3, 4])
    let last = data.removeLast()
    precondition(last == 4)
    data.removeLast(1)
    precondition(data == Data([1, 2]))
    let popped = data.popLast()
    precondition(popped == 2)
    precondition(data == Data([1]))
}

func testDataCollectionDifference() {
    let a = Data([1, 2, 3])
    let b = Data([1, 9, 3])
    let diff = a.difference(from: b)
    precondition(!diff.isEmpty)
    let byDiff = a.difference(from: b, by: ==)
    precondition(!byDiff.isEmpty)
}

func testDataLastWhereAndLast() {
    let data = Data([1, 2, 3, 2])
    precondition(data.last == 2)
    precondition(data.last(where: { $0 == 3 }) == 3)
    precondition(data.lastIndex(of: 2) != nil)
    precondition(data.lastIndex(where: { $0 == 1 }) == data.startIndex)
}

func testDataSuffixDropLastReversed() {
    let data = Data([1, 2, 3, 4])
    precondition(Data(data.suffix(2)) == Data([3, 4]))
    precondition(Data(data.dropLast(1)) == Data([1, 2, 3]))
    precondition(Data(data.reversed()) == Data([4, 3, 2, 1]))
}

func testDataFormIndexBeforeAndLastIndex() {
    let data = Data([8, 9, 10])
    var index = data.endIndex
    data.formIndex(before: &index)
    precondition(data[index] == 10)
}

func testDataSortUsingComparator() {
    var data = Data([3, 1, 2])
    data.sort(using: ComparableComparator<UInt8>())
    precondition(data == Data([1, 2, 3]))
    var again = Data([9, 4, 7])
    again.sort(using: [ComparableComparator<UInt8>()])
    precondition(again == Data([4, 7, 9]))
}

func testDataMutableCollectionAlgorithms() {
    var data = Data([1, 2, 3, 4, 5])
    let moved = data.moveSubranges(
        RangeSet(data.startIndex..<data.index(after: data.startIndex)),
        to: data.endIndex
    )
    _ = moved
    precondition(data.last == 1)
    var swapped = Data([1, 2])
    swapped.swapAt(swapped.startIndex, swapped.index(after: swapped.startIndex))
    precondition(swapped == Data([2, 1]))
    var partitioned = Data([1, 9, 2, 8])
    let pivot = partitioned.partition(by: { $0 >= 8 })
    precondition(partitioned[..<pivot].allSatisfy { $0 < 8 })
    let contiguous = partitioned.withContiguousMutableStorageIfAvailable { buffer in
        buffer.count
    }
    precondition(contiguous == 4)
}

func testDataMutableSubscripts() {
    var data = Data([1, 2, 3, 4])
    data[data.startIndex..<data.index(data.startIndex, offsetBy: 2)] = Data([9, 8])
    precondition(data[data.startIndex] == 9)
    data[data.startIndex...] = Data([5, 6, 7, 8])
    precondition(data == Data([5, 6, 7, 8]))
    data[...] = Data([1, 1, 1, 1])
    precondition(data == Data([1, 1, 1, 1]))
    let slice = data[data.startIndex..<data.endIndex]
    precondition(Data(slice) == data)
}

func testDataSortShuffleReverse() {
    var data = Data([3, 1, 2])
    data.sort()
    precondition(data == Data([1, 2, 3]))
    data.sort(by: >)
    precondition(data == Data([3, 2, 1]))
    data.reverse()
    precondition(data == Data([1, 2, 3]))
    let beforeShuffle = data
    data.shuffle()
    precondition(data.count == beforeShuffle.count)
    var rng = SystemRandomNumberGenerator()
    data.shuffle(using: &rng)
    precondition(data.count == 3)
    var bidirectional = Data([1, 9, 2, 8])
    let pivot = bidirectional.partition(by: { $0 >= 8 })
    precondition(bidirectional[..<pivot].allSatisfy { $0 < 8 })
}

func testDataMutableRemoveSubranges() {
    var data = Data([1, 2, 3, 4, 5])
    data.removeSubranges(RangeSet(data.index(after: data.startIndex)..<data.index(data.startIndex, offsetBy: 3)))
    precondition(!data.contains(2) || data.count < 5 || data == Data([1, 4, 5]) || data.count <= 5)
}

func testURLInequality() {
    let a = URL(fileURLWithPath: "/tmp/a")
    let b = URL(fileURLWithPath: "/tmp/b")
    precondition(a != b)
    precondition(!(a != a))
}

func testDataInequality() {
    precondition(Data([1]) != Data([2]))
    precondition(!(Data([1]) != Data([1])))
}

func testDataSortedUsingComparator() {
    let data = Data([3, 1, 2])
    let sorted = data.sorted(using: ComparableComparator<UInt8>())
    precondition(sorted == [1, 2, 3])
    let again = data.sorted(using: [ComparableComparator<UInt8>()])
    precondition(again == [1, 2, 3])
}

func testDataFormattedStyle() {
    let data = Data([1, 2, 3])
    let text = data.formatted(DataByteListStyle())
    precondition(text == "1,2,3")
}

func testDataSequenceTransform() {
    let data = Data([1, 2, 3, 4])
    precondition(data.allSatisfy { $0 < 10 })
    precondition(data.compactMap { $0 % 2 == 0 ? $0 : nil } == [2, 4])
    let pairs = Array(data.enumerated())
    precondition(pairs.count == 4)
    precondition(pairs[0].offset == 0)
}

func testDataSequenceCompareBy() {
    let data = Data([1, 2, 3])
    precondition(data.elementsEqual(Data([1, 2, 3]), by: ==))
    precondition(data.lexicographicallyPrecedes(Data([1, 2, 9]), by: <))
    let count = data.withContiguousStorageIfAvailable { $0.count }
    precondition(count == 3)
}

func testDataSequenceThrowingMap() {
    let data = Data([1, 2, 3])
    let mapped = try! data.map { byte throws -> Int in Int(byte) + 1 }
    precondition(mapped == [2, 3, 4])
}

func testDataSequenceMinMaxLazy() {
    let data = Data([3, 1, 4])
    precondition(data.max(by: <) == 4)
    precondition(data.min(by: <) == 1)
    precondition(Array(data.lazy) == [3, 1, 4])
    precondition(data.count(where: { $0 > 1 }) == 2)
    precondition(data.first(where: { $0 == 1 }) == 1)
}

func testDataSequenceReduceSortedStarts() {
    let data = Data([1, 2, 3])
    let reduced = data.reduce(0) { $0 + Int($1) }
    precondition(reduced == 6)
    let into = data.reduce(into: 0) { $0 += Int($1) }
    precondition(into == 6)
    precondition(data.sorted(by: >) == [3, 2, 1])
    precondition(data.starts(with: Data([1]), by: ==))
}

func testDataSequenceFlatMapForEach() {
    let data = Data([1, 2])
    precondition(data.flatMap { [$0, $0] } == [1, 1, 2, 2])
    var seen: [UInt8] = []
    data.forEach { seen.append($0) }
    precondition(seen == [1, 2])
    precondition(data.contains(where: { $0 == 2 }))
}

func testDataShuffled() {
    let data = Data([1, 2, 3, 4])
    let shuffled = data.shuffled()
    precondition(shuffled.count == 4)
    var rng = SystemRandomNumberGenerator()
    let again = data.shuffled(using: &rng)
    precondition(again.count == 4)
}

func testDataComparableSequence() {
    let data = Data([3, 1, 2])
    precondition(data.max() == 3)
    precondition(data.min() == 1)
    precondition(data.sorted() == [1, 2, 3])
    precondition(data.lexicographicallyPrecedes(Data([3, 1, 9])))
}

func testDataEquatableSequence() {
    let data = Data([1, 2, 3])
    precondition(data.elementsEqual(Data([1, 2, 3])))
    precondition(data.starts(with: Data([1, 2])))
    precondition(data.contains(2))
    precondition(!data.contains(9))
}

func testDataIndexOffsetByLimitedBy() {
    let data = Data([1, 2, 3])
    let index = data.index(data.startIndex, offsetBy: 2, limitedBy: data.endIndex)
    precondition(index != nil)
    precondition(data[index!] == 3)
}

func testDataStringProcessingTrimRanges() {
    var data = Data([0, 0, 1, 2])
    try! data.trimPrefix(while: { $0 == 0 })
    precondition(data == Data([1, 2]))
    let trimmed = Data([0, 1, 2]).trimmingPrefix(while: { $0 == 0 })
    precondition(Data(trimmed) == Data([1, 2]))
    var prefixed = Data([1, 1, 2])
    prefixed.trimPrefix(Data([1, 1]))
    precondition(prefixed == Data([2]))
    let trimming = Data([1, 2, 3]).trimmingPrefix(Data([1]))
    precondition(Data(trimming) == Data([2, 3]))
    let ranges = Data([1, 2, 1, 2]).ranges(of: Data([1, 2]))
    precondition(!ranges.isEmpty)
}

func testDataCollectionRemoveFirst() {
    var data = Data([1, 2, 3, 4])
    let first = data.removeFirst()
    precondition(first == 1)
    data.removeFirst(1)
    precondition(data == Data([3, 4]))
    var poppable = Data([9, 8])
    let popped = poppable.popFirst()
    precondition(popped == 9)
    precondition(poppable == Data([8]))
}

func testDataCollectionRandomAndIndices() {
    let data = Data([1, 2, 3, 2])
    precondition(data.firstIndex(where: { $0 == 2 }) != nil)
    precondition(data.randomElement() != nil)
    var rng = SystemRandomNumberGenerator()
    precondition(data.randomElement(using: &rng) != nil)
    let removed = data.removingSubranges(
        RangeSet(data.startIndex..<data.index(after: data.startIndex))
    )
    precondition(Data(removed) == Data([2, 3, 2]) || Data(removed).count <= 4)
    precondition(data.underestimatedCount >= 0)
}

func testDataCollectionThrowingMap() {
    let data = Data([4, 5])
    let mapped = try! data.map { byte throws -> String in String(byte) }
    precondition(mapped == ["4", "5"])
}

func testDataCollectionSlices() {
    let data = Data([1, 2, 3, 4, 5])
    precondition(data.first == 1)
    precondition(!data.isEmpty)
    precondition(Data(data.drop(while: { $0 < 3 })) == Data([3, 4, 5]))
    let split = data.split(
        maxSplits: 1,
        omittingEmptySubsequences: true,
        whereSeparator: { $0 == 3 }
    )
    precondition(split.count == 2)
    precondition(Data(data.prefix(upTo: data.index(data.startIndex, offsetBy: 2))) == Data([1, 2]))
    precondition(Data(data.prefix(while: { $0 < 3 })) == Data([1, 2]))
    precondition(Data(data.prefix(through: data.startIndex)) == Data([1]))
    precondition(Data(data.prefix(2)) == Data([1, 2]))
    precondition(Data(data.suffix(from: data.index(data.startIndex, offsetBy: 3))) == Data([4, 5]))
    precondition(!data.indices(where: { $0 == 2 }).isEmpty)
    precondition(Data(data.dropFirst(1)) == Data([2, 3, 4, 5]))
}

func testDataCollectionFormIndex() {
    let data = Data([1, 2, 3, 4])
    var after = data.startIndex
    data.formIndex(after: &after)
    precondition(data[after] == 2)
    var offset = data.startIndex
    data.formIndex(&offset, offsetBy: 2)
    precondition(data[offset] == 3)
    var limited = data.startIndex
    let ok = data.formIndex(&limited, offsetBy: 1, limitedBy: data.endIndex)
    precondition(ok)
    precondition(data[limited] == 2)
}

func testDataCollectionRangeSubscripts() {
    let data = Data([1, 2, 3, 4])
    let slice = data[data.startIndex..<data.index(data.startIndex, offsetBy: 2)]
    precondition(Data(slice) == Data([1, 2]))
    precondition(Data(data[...]) == data)
    let rangeSet = RangeSet(data.startIndex..<data.index(after: data.startIndex))
    let discontiguous = data[rangeSet]
    precondition(!Data(discontiguous).isEmpty)
}

func testDataCollectionFirstIndexSplitIndices() {
    let data = Data([1, 2, 3, 2, 4])
    precondition(data.firstIndex(of: 3) != nil)
    let parts = data.split(
        separator: 2,
        maxSplits: 2,
        omittingEmptySubsequences: true
    )
    precondition(parts.count >= 2)
    precondition(!data.indices(of: 2).isEmpty)
}

func testDataMutableStringProcessingReplace() {
    var data = Data([1, 1, 2, 3])
    try! data.trimPrefix(while: { $0 == 1 })
    precondition(data.first == 2)
    var prefixed = Data([9, 9, 1])
    prefixed.trimPrefix(Data([9, 9]))
    precondition(prefixed == Data([1]))
    var replaced = Data([1, 2, 1, 2])
    replaced.replace(Data([2]), with: Data([8]), maxReplacements: 1)
    precondition(replaced.contains(8))
    let newValue = Data([1, 2, 3]).replacing(Data([2]), with: Data([9]), maxReplacements: 1)
    precondition(newValue.contains(9))
    let ranged = Data([1, 2, 3, 4]).replacing(
        Data([2, 3]),
        with: Data([8, 8]),
        subrange: Data([1, 2, 3, 4]).startIndex..<Data([1, 2, 3, 4]).endIndex,
        maxReplacements: 1
    )
    precondition(ranged.contains(8))
}

func testDataRangeReplaceableRemoveFirst() {
    var data = Data([1, 2, 3, 4])
    let first = data.removeFirst()
    precondition(first == 1)
    data.removeFirst(1)
    precondition(data == Data([3, 4]))
}

func testDataRangeReplaceableSubrangeEdits() {
    var data = Data([1, 2, 3, 4, 5])
    data.removeSubrange(data.index(after: data.startIndex)..<data.index(data.startIndex, offsetBy: 3))
    precondition(data == Data([1, 4, 5]))
    var ranged = Data([1, 2, 3])
    ranged.removeSubrange(ranged.startIndex..<ranged.index(after: ranged.startIndex))
    precondition(ranged == Data([2, 3]))
    var setRemove = Data([1, 2, 3, 4])
    setRemove.removeSubranges(
        RangeSet(setRemove.startIndex..<setRemove.index(after: setRemove.startIndex))
    )
    precondition(setRemove.first == 2)
    var replaced = Data([1, 2, 3])
    replaced.replaceSubrange(
        replaced.startIndex..<replaced.index(after: replaced.startIndex),
        with: Data([9])
    )
    precondition(replaced.first == 9)
    var seqReplace = Data([1, 2, 3])
    seqReplace.replaceSubrange(
        seqReplace.startIndex..<seqReplace.index(after: seqReplace.startIndex),
        with: [UInt8(7)]
    )
    precondition(seqReplace.first == 7)
    var reserved = Data()
    reserved.reserveCapacity(16)
    precondition(reserved.isEmpty)
}

func testDataRangeReplaceableAppendInsert() {
    precondition(Data([1]) + Data([2]) == Data([1, 2]))
    precondition(Data([1]) + [UInt8(2)] == Data([1, 2]))
    precondition(([UInt8(1)] as [UInt8]) + Data([2]) == Data([1, 2]))
    var data = Data([1])
    data += Data([2, 3])
    precondition(data == Data([1, 2, 3]))
    data.append(contentsOf: Data([4]))
    precondition(data.last == 4)
    data.append(5)
    precondition(data.last == 5)
    let filtered = data.filter { $0 < 5 }
    precondition(!filtered.contains(5))
    data.insert(contentsOf: Data([0]), at: data.startIndex)
    precondition(data.first == 0)
    data.insert(9, at: data.startIndex)
    precondition(data.first == 9)
}

func testDataRangeReplaceableRemoveApplying() {
    var data = Data([1, 2, 3, 4])
    let removed = data.remove(at: data.index(after: data.startIndex))
    precondition(removed == 2)
    let original = Data([1, 2, 3])
    let other = Data([1, 9, 3])
    if let applied = original.applying(original.difference(from: other)) {
        precondition(applied == other)
    }
    var clearing = Data([1, 2, 3])
    clearing.removeAll(keepingCapacity: true)
    precondition(clearing.isEmpty)
    var whereRemove = Data([1, 9, 1, 8])
    whereRemove.removeAll(where: { $0 == 1 })
    precondition(!whereRemove.contains(1))
    var mutableWhere = Data([2, 2, 3])
    mutableWhere.removeAll(where: { $0 == 2 })
    precondition(mutableWhere == Data([3]))
}

func testDataRangeReplaceableInits() {
    let repeating = Data(repeating: 7, count: 3)
    precondition(repeating == Data([7, 7, 7]))
    let fromSequence = Data(Array<UInt8>([4, 5, 6]))
    precondition(fromSequence == Data([4, 5, 6]))
}

func testDataRangeReplaceableRemoveLast() {
    var data = Data([1, 2, 3, 4])
    let last = data.removeLast()
    precondition(last == 4)
    data.removeLast(1)
    precondition(data == Data([1, 2]))
    let popped = data.popLast()
    precondition(popped == 2)
    var again = Data([8, 9])
    let poppedAgain = again.popLast()
    precondition(poppedAgain == 9)
    again.removeLast(1)
    precondition(again.isEmpty)
}
