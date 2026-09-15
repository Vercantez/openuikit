import CoreFoundation
import CoreMedia
import Foundation

/// Exercises the concrete standard-library witnesses inherited by
/// `CMReadOnlyDataBlockBuffer`. Each call below names the concrete host so
/// the synthesized witness for that exact type is covered. Randomness is
/// only asserted by shape (permutation preserves the multiset).
func testCMDataBlockBufferConcreteWitnesses() {
    let bytes = CMReadOnlyDataBlockBuffer(Data([1, 2, 3, 4]))
    let changed = CMReadOnlyDataBlockBuffer(Data([1, 9, 3, 4]))

    precondition(bytes.difference(from: changed).count == 2)
    precondition(bytes.difference(from: changed, by: ==).count == 2)
    precondition(bytes.max() == 4)
    precondition(bytes.min() == 1)
    precondition(bytes.sorted() == [1, 2, 3, 4])
    precondition(bytes.contains(2))
    precondition(!bytes.contains(9))
    precondition(bytes.index(bytes.startIndex, offsetBy: 9, limitedBy: bytes.endIndex) == nil)
    precondition(bytes.index(bytes.startIndex, offsetBy: 2, limitedBy: bytes.endIndex) == 2)

    var removals = RangeSet<Int>()
    removals.insert(contentsOf: 1..<3)
    precondition(Array(bytes.removingSubranges(removals)) == [1, 4])
    precondition(Array(bytes.drop(while: { $0 < 3 })) == [3, 4])
    precondition(bytes.split(whereSeparator: { $0 == 2 }).count == 2)
    precondition(bytes.split(separator: 2).count == 2)
    precondition(bytes.count == 4)
    precondition(Array(bytes[...]) == [1, 2, 3, 4])

    var first = CMReadOnlyDataBlockBuffer(Data([1, 2, 3, 4]))
    precondition(first.removeFirst() == 1)
    var firstCount = CMReadOnlyDataBlockBuffer(Data([1, 2, 3, 4]))
    firstCount.removeFirst(2)
    precondition(Array(firstCount) == [3, 4])
    var last = CMReadOnlyDataBlockBuffer(Data([1, 2, 3, 4]))
    precondition(last.removeLast() == 4)
    var lastCount = CMReadOnlyDataBlockBuffer(Data([1, 2, 3, 4]))
    lastCount.removeLast(2)
    precondition(Array(lastCount) == [1, 2])
    var poppedFirst = CMReadOnlyDataBlockBuffer(Data([1, 2, 3, 4]))
    precondition(poppedFirst.popFirst() == 1)
    var poppedLast = CMReadOnlyDataBlockBuffer(Data([1, 2, 3, 4]))
    precondition(poppedLast.popLast() == 4)

    precondition(bytes.shuffled().sorted() == [1, 2, 3, 4])
    var generator = SystemRandomNumberGenerator()
    precondition(bytes.shuffled(using: &generator).sorted() == [1, 2, 3, 4])
    if let one = bytes.randomElement() {
        precondition(bytes.contains(one))
    } else {
        preconditionFailure("nonempty buffer must produce a random element")
    }
    if let two = bytes.randomElement(using: &generator) {
        precondition(bytes.contains(two))
    } else {
        preconditionFailure("nonempty buffer must produce a random element")
    }

    precondition(bytes.firstRange(of: [UInt8(2), 3]) == 1..<3)
    precondition(bytes.ranges(of: [UInt8(2), 3]).count == 1)
    precondition(Array(bytes.trimmingPrefix([UInt8(1), 2])) == [3, 4])
    precondition(Array(bytes.trimmingPrefix(while: { $0 < 3 })) == [3, 4])
    var trimmed = CMReadOnlyDataBlockBuffer(Data([1, 2, 3, 4]))
    trimmed.trimPrefix([UInt8(1)])
    precondition(Array(trimmed) == [2, 3, 4])
    var trimmedWhile = CMReadOnlyDataBlockBuffer(Data([1, 2, 3, 4]))
    try! trimmedWhile.trimPrefix(while: { $0 < 3 })
    precondition(Array(trimmedWhile) == [3, 4])

    let pattern = Data([2, 3])
    precondition(bytes.firstRange(of: pattern) == 1..<3)
    precondition(bytes.firstRange(of: pattern, in: 0..<4) == 1..<3)
    precondition(bytes.lastRange(of: pattern) == 1..<3)
    precondition(bytes.lastRange(of: pattern, in: 0..<4) == 1..<3)
}

/// Exercises the same witness families on the two `BlockRegion` projections.
/// `Slice`-based regions keep stable indices, so `indices(where:)` /
/// `indices(of:)` are asserted exactly here.
func testCMDataBlockBufferRegionWitnesses() {
    let readOnly = CMReadOnlyDataBlockBuffer(Data([1, 2, 3, 4]))
    let readOnlyRegion = readOnly.regions[0]
    var mutable = CMMutableDataBlockBuffer(count: 4)
    for (index, byte) in [UInt8(1), 2, 3, 4].enumerated() {
        mutable[index] = byte
    }
    let mutableRegion = mutable.withUnsafeMutableBlockRegions { $0[0] }
    let pattern = Data([2, 3])

    // Read-only region.
    let changedReadOnly = CMReadOnlyDataBlockBuffer(Data([1, 9, 3, 4]))
    precondition(readOnlyRegion.difference(from: changedReadOnly.regions[0]).count == 2)
    precondition(readOnlyRegion.difference(from: changedReadOnly.regions[0], by: ==).count == 2)
    precondition(readOnlyRegion.max() == 4)
    precondition(readOnlyRegion.min() == 1)
    precondition(readOnlyRegion.sorted() == [1, 2, 3, 4])
    precondition(readOnlyRegion.contains(2))
    precondition(!readOnlyRegion.contains(9))
    precondition(
        readOnlyRegion.index(readOnlyRegion.startIndex, offsetBy: 9, limitedBy: readOnlyRegion.endIndex) == nil
    )
    var readOnlyRemovals = RangeSet<Int>()
    readOnlyRemovals.insert(contentsOf: 1..<3)
    precondition(Array(readOnlyRegion.removingSubranges(readOnlyRemovals)) == [1, 4])
    precondition(Array(readOnlyRegion.drop(while: { $0 < 3 })) == [3, 4])
    precondition(readOnlyRegion.split(whereSeparator: { $0 == 2 }).count == 2)
    precondition(readOnlyRegion.split(separator: 2).count == 2)
    precondition(readOnlyRegion.indices(where: { $0 > 2 }) == RangeSet([2..<4]))
    precondition(readOnlyRegion.indices(of: UInt8(2)) == RangeSet([1..<2]))
    precondition(readOnlyRegion.shuffled().sorted() == [1, 2, 3, 4])
    var readOnlyGenerator = SystemRandomNumberGenerator()
    precondition(readOnlyRegion.shuffled(using: &readOnlyGenerator).sorted() == [1, 2, 3, 4])
    if let one = readOnlyRegion.randomElement() {
        precondition(readOnlyRegion.contains(one))
    } else {
        preconditionFailure("nonempty region must produce a random element")
    }
    if let two = readOnlyRegion.randomElement(using: &readOnlyGenerator) {
        precondition(readOnlyRegion.contains(two))
    } else {
        preconditionFailure("nonempty region must produce a random element")
    }
    precondition(readOnlyRegion.firstRange(of: [UInt8(2), 3]) == 1..<3)
    precondition(readOnlyRegion.ranges(of: [UInt8(2), 3]).count == 1)
    precondition(Array(readOnlyRegion.trimmingPrefix([UInt8(1), 2])) == [3, 4])
    precondition(Array(readOnlyRegion.trimmingPrefix(while: { $0 < 3 })) == [3, 4])
    precondition(readOnlyRegion.firstRange(of: pattern) == 1..<3)
    precondition(readOnlyRegion.firstRange(of: pattern, in: 0..<4) == 1..<3)
    precondition(readOnlyRegion.lastRange(of: pattern) == 1..<3)
    precondition(readOnlyRegion.lastRange(of: pattern, in: 0..<4) == 1..<3)

    // Mutable region.
    let changedMutable = CMReadOnlyDataBlockBuffer(Data([1, 9, 3, 4]))
    precondition(mutableRegion.difference(from: changedMutable.regions[0]).count == 2)
    precondition(mutableRegion.difference(from: changedMutable.regions[0], by: ==).count == 2)
    precondition(mutableRegion.max() == 4)
    precondition(mutableRegion.min() == 1)
    precondition(mutableRegion.sorted() == [1, 2, 3, 4])
    precondition(mutableRegion.contains(2))
    precondition(!mutableRegion.contains(9))
    precondition(
        mutableRegion.index(mutableRegion.startIndex, offsetBy: 9, limitedBy: mutableRegion.endIndex) == nil
    )
    var mutableRemovals = RangeSet<Int>()
    mutableRemovals.insert(contentsOf: 1..<3)
    precondition(Array(mutableRegion.removingSubranges(mutableRemovals)) == [1, 4])
    precondition(Array(mutableRegion.drop(while: { $0 < 3 })) == [3, 4])
    precondition(mutableRegion.split(whereSeparator: { $0 == 2 }).count == 2)
    precondition(mutableRegion.split(separator: 2).count == 2)
    precondition(mutableRegion.indices(where: { $0 > 2 }) == RangeSet([2..<4]))
    precondition(mutableRegion.indices(of: UInt8(2)) == RangeSet([1..<2]))
    precondition(mutableRegion.shuffled().sorted() == [1, 2, 3, 4])
    var mutableGenerator = SystemRandomNumberGenerator()
    precondition(mutableRegion.shuffled(using: &mutableGenerator).sorted() == [1, 2, 3, 4])
    if let one = mutableRegion.randomElement() {
        precondition(mutableRegion.contains(one))
    } else {
        preconditionFailure("nonempty region must produce a random element")
    }
    if let two = mutableRegion.randomElement(using: &mutableGenerator) {
        precondition(mutableRegion.contains(two))
    } else {
        preconditionFailure("nonempty region must produce a random element")
    }
    precondition(mutableRegion.firstRange(of: [UInt8(2), 3]) == 1..<3)
    precondition(mutableRegion.ranges(of: [UInt8(2), 3]).count == 1)
    precondition(Array(mutableRegion.trimmingPrefix([UInt8(1), 2])) == [3, 4])
    precondition(Array(mutableRegion.trimmingPrefix(while: { $0 < 3 })) == [3, 4])
    precondition(mutableRegion.firstRange(of: pattern) == 1..<3)
    precondition(mutableRegion.firstRange(of: pattern, in: 0..<4) == 1..<3)
    precondition(mutableRegion.lastRange(of: pattern) == 1..<3)
    precondition(mutableRegion.lastRange(of: pattern, in: 0..<4) == 1..<3)
}

/// Forms the `OptionSet` overlay hosts through array literals so each
/// `ArrayLiteralElement` witness is exercised on its concrete host.
func testCMOptionSetArrayLiteralWitnesses() {
    let mask: CMFormatDescription.EqualityMask = [.magicCookie, .extensions]
    precondition(mask.contains(.magicCookie) && mask.contains(.extensions))
    let maskElement: CMFormatDescription.EqualityMask.ArrayLiteralElement = .magicCookie
    precondition(maskElement == .magicCookie)

    let fontFace: CMFormatDescription.Extensions.Value.FontFace = [.bold, .italic]
    precondition(fontFace.contains(.bold) && fontFace.contains(.italic))
    let fontFaceElement: CMFormatDescription.Extensions.Value.FontFace.ArrayLiteralElement = .bold
    precondition(fontFaceElement == .bold)

    let timeCodeFlag: CMFormatDescription.TimeCode.Flag = [.dropFrame]
    precondition(timeCodeFlag.contains(.dropFrame))
    let timeCodeFlagElement: CMFormatDescription.TimeCode.Flag.ArrayLiteralElement = .dropFrame
    precondition(timeCodeFlagElement == .dropFrame)
}

/// Exercises `!=` on the tag and sample-reference value types whose `==` is
/// already covered elsewhere.
func testCMTagAndSampleReferenceInequality() {
    let first = CMTag(rawCategory: 1, rawTagValue: .flags(1))
    let second = CMTag(rawCategory: 1, rawTagValue: .flags(2))
    precondition(first != second)
    precondition(!(first != first))
    precondition(CMTag.Value.flags(1) != CMTag.Value.flags(2))
    precondition(!(CMTag.Value.int64(3) != CMTag.Value.int64(3)))
    let firstReference = CMSampleDataReference(
        containerLocation: URL(string: "file:///a")!,
        byteOffset: 1
    )
    let secondReference = CMSampleDataReference(
        containerLocation: URL(string: "file:///a")!,
        byteOffset: 2
    )
    precondition(firstReference != secondReference)
    precondition(!(firstReference != firstReference))
}

/// Covers the `T` family typealiases, the per-sample timing arrays, and the
/// always-nil tagged-buffer getter on buffers this port can construct.
func testCMSampleBufferFamilyWitnesses() {
    let timebaseAlias: CMTimebase.T? = nil
    precondition(timebaseAlias == nil)
    precondition(CMTimebase.T.self == CMTimebase.self)
    let blockAlias: CMBlockBuffer.T? = nil
    precondition(blockAlias == nil)
    precondition(CMBlockBuffer.T.self == CMBlockBuffer.self)
    let sampleAlias: CMSampleBuffer.T? = nil
    precondition(sampleAlias == nil)
    precondition(CMSampleBuffer.T.self == CMSampleBuffer.self)
    let formatAlias: CMFormatDescription.T? = nil
    precondition(formatAlias == nil)
    precondition(CMFormatDescription.T.self == CMFormatDescription.self)

    let firstTiming = CMSampleTimingInfo(
        duration: CMTime(value: 1, timescale: 30),
        presentationTimeStamp: .zero,
        decodeTimeStamp: .invalid
    )
    let secondTiming = CMSampleTimingInfo(
        duration: CMTime(value: 1, timescale: 30),
        presentationTimeStamp: CMTime(value: 1, timescale: 30),
        decodeTimeStamp: .invalid
    )
    let distinct = try! CMSampleBuffer(
        dataBuffer: nil,
        formatDescription: nil,
        numSamples: 2,
        sampleTimings: [firstTiming, secondTiming],
        sampleSizes: [1, 1]
    )
    precondition(try! distinct.sampleTimingInfos() == [firstTiming, secondTiming])
    precondition(try! distinct.outputSampleTimingInfos() == [firstTiming, secondTiming])

    let uniform = try! CMSampleBuffer(
        dataBuffer: nil,
        formatDescription: nil,
        numSamples: 2,
        sampleTimings: [firstTiming],
        sampleSizes: [1]
    )
    precondition(try! uniform.sampleTimingInfos() == [firstTiming, firstTiming])
    precondition(try! uniform.outputSampleTimingInfos() == [firstTiming, firstTiming])

    let marker = try! CMSampleBuffer(
        dataBuffer: nil,
        formatDescription: nil,
        numSamples: 0,
        sampleTimings: [],
        sampleSizes: []
    )
    precondition((try? marker.sampleTimingInfos()) == nil)
    precondition((try? marker.outputSampleTimingInfos()) == nil)
    precondition(marker.taggedBuffers == nil)

    let withData = try! CMSampleBuffer(
        dataBuffer: CMBlockBuffer(data: Data([1])),
        formatDescription: nil,
        numSamples: 1,
        sampleTimings: [firstTiming],
        sampleSizes: [1]
    )
    precondition(withData.taggedBuffers == nil)

    let invalidated = try! CMSampleBuffer(
        dataBuffer: nil,
        formatDescription: nil,
        numSamples: 1,
        sampleTimings: [firstTiming],
        sampleSizes: [1]
    )
    invalidated.invalidate()
    precondition((try? invalidated.sampleTimingInfos()) == nil)
    precondition((try? invalidated.outputSampleTimingInfos()) == nil)
}
