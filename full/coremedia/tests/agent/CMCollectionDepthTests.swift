import CoreFoundation
import CoreMedia
import Foundation

private struct CMDepthGenerator: RandomNumberGenerator {
    var value: UInt64 = 0x9e3779b97f4a7c15
    mutating func next() -> UInt64 {
        value = value &* 6364136223846793005 &+ 1
        return value
    }
}

func testCMFormatDescriptionExtensionsCollectionAlgorithms() {
    var values = CMFormatDescription.Extensions()
    values[.formatName] = .string("video")
    values[.vendor] = .string("appl")
    values[.version] = .number(3)

    precondition(!values.isEmpty && values.count == 3)
    precondition(values.first != nil)
    precondition(values.distance(from: values.startIndex, to: values.endIndex) == 3)
    precondition(values.index(values.startIndex, offsetBy: 2) < values.endIndex)
    precondition(values.index(values.startIndex, offsetBy: 4, limitedBy: values.endIndex) == nil)
    var index = values.startIndex
    values.formIndex(after: &index)
    values.formIndex(&index, offsetBy: 1)
    precondition(index == values.index(before: values.endIndex))

    precondition(values.prefix(2).count == 2)
    precondition(values.prefix(upTo: index).count == 2)
    precondition(values.prefix(through: index).count == 3)
    precondition(values.suffix(from: index).count == 1)
    precondition(values.dropFirst().count == 2)
    precondition(values.dropLast().count == 2)
    precondition(values.reversed().count == 3)
    precondition(values.lazy.count == 3)
    precondition(values.enumerated().count == 3)
    precondition(values.map { $0.key }.count == 3)
    precondition(values.compactMap { $0.value }.count == 3)
    precondition(values.filter { !$0.key.rawValue.isEmpty }.count == 3)
    precondition(values.reduce(0) { count, _ in count + 1 } == 3)
    var reduced = 0
    reduced = values.reduce(into: 0) { count, _ in count += 1 }
    precondition(reduced == 3)
    precondition(values.allSatisfy { !$0.key.rawValue.isEmpty })
    precondition(values.contains { $0.key == .vendor })
    precondition(values.first { $0.key == .formatName } != nil)
    var visited = 0
    values.forEach { _ in visited += 1 }
    precondition(visited == 3)
    var iterator = values.makeIterator()
    precondition(iterator.next() != nil)
}

func testCMSamplePropertiesCollectionAlgorithms() {
    let timing = CMSampleTimingInfo(
        duration: CMTime(value: 1, timescale: 30),
        presentationTimeStamp: .zero,
        decodeTimeStamp: .invalid
    )
    let first = CMSampleBuffer.SampleProperties(size: 1, timing: timing)
    let second = CMSampleBuffer.SampleProperties(size: 2, timing: timing)
    let third = CMSampleBuffer.SampleProperties(size: 3, timing: timing)
    let values: CMSampleBuffer.SamplePropertiesCollection = [first, second, third]

    precondition(!values.isEmpty && values.count == 3)
    precondition(values.first == first && values.last == third)
    precondition(values.firstIndex(of: second) == 1)
    precondition(values.lastIndex(of: second) == 1)
    precondition(values.contains(second))
    precondition(values.elementsEqual([first, second, third]))
    precondition(values.starts(with: [first, second]))
    precondition(values.dropFirst().count == 2)
    precondition(values.dropLast().count == 2)
    precondition(values.prefix(2).count == 2)
    precondition(values.suffix(2).count == 2)
    precondition(values.reversed().first == third)
    precondition(values.map(\.size) == [1, 2, 3])
    precondition(values.compactMap { ($0.size ?? 0) > 1 ? $0.size : nil } == [2, 3])
    precondition(values.filter { ($0.size ?? 0) > 1 }.count == 2)
    precondition(values.reduce(0) { $0 + ($1.size ?? 0) } == 6)
    precondition(values.allSatisfy { ($0.size ?? 0) > 0 })
    precondition(values.contains { $0.size == 2 })
    precondition(values.first { $0.size == 3 } == third)
    precondition(values.min { ($0.size ?? 0) < ($1.size ?? 0) } == first)
    precondition(values.max { ($0.size ?? 0) < ($1.size ?? 0) } == third)
    precondition(values.sorted { ($0.size ?? 0) > ($1.size ?? 0) }.first == third)
    precondition(values.lexicographicallyPrecedes([third]) { ($0.size ?? 0) < ($1.size ?? 0) })
    precondition(values.split(separator: second).count == 2)
    var generator = CMDepthGenerator()
    precondition(values.shuffled(using: &generator).count == 3)
    var visited = 0
    values.forEach { _ in visited += 1 }
    precondition(visited == 3)
    var iterator = values.makeIterator()
    precondition(iterator.next() == first)
}

func testCMSampleAttachmentsArrayCollectionAlgorithms() {
    var one = CMSampleBuffer.PerSampleAttachmentsDictionary()
    one[.doNotDisplay] = true
    var two = CMSampleBuffer.PerSampleAttachmentsDictionary()
    two[.notSync] = true
    var values = CMSampleBuffer.SampleAttachmentsArray(count: 3)
    values[0] = one
    values[1] = two
    values[2] = one

    precondition(!values.isEmpty && values.count == 3)
    precondition(values.first?[.doNotDisplay] as? Bool == true)
    precondition(values.prefix(2).count == 2)
    precondition(values.suffix(2).count == 2)
    precondition(values.dropFirst().count == 2)
    precondition(values.dropLast().count == 2)
    precondition(values.reversed().count == 3)
    precondition(values.map { $0.reduce(0) { count, _ in count + 1 } }.count == 3)
    precondition(values.compactMap { $0[.doNotDisplay] as? Bool }.count == 2)
    precondition(values.filter { $0.reduce(0) { count, _ in count + 1 } > 0 }.count == 3)
    precondition(values.reduce(0) { $0 + $1.reduce(0) { count, _ in count + 1 } } == 3)
    precondition(values.allSatisfy { $0.reduce(0) { count, _ in count + 1 } > 0 })
    precondition(values.contains { $0[.notSync] as? Bool == true })
    precondition(values.first { $0[.notSync] as? Bool == true } != nil)
    var visited = 0
    values.forEach { _ in visited += 1 }
    precondition(visited == 3)
    var iterator = values.makeIterator()
    precondition(iterator.next() != nil)
}

func testCMOptionSetAndRawValueAlgorithms() {
    var block: CMBlockBuffer.Flags = [.assureMemoryNow]
    precondition(block.contains(.assureMemoryNow))
    precondition(block.insert(.alwaysCopyData).inserted)
    precondition(block.remove(.assureMemoryNow) != nil)
    precondition(block.update(with: .assureMemoryNow) == nil)
    precondition(block.union(.alwaysCopyData).contains(.alwaysCopyData))
    precondition(block.intersection(.assureMemoryNow) == .assureMemoryNow)
    precondition(block.symmetricDifference(.assureMemoryNow).contains(.alwaysCopyData))
    var copy = block
    copy.formUnion(.dontOptimizeDepth)
    copy.formIntersection(block)
    copy.formSymmetricDifference(.alwaysCopyData)

    var sample: CMSampleBuffer.Flags = []
    let alignment = CMSampleBuffer.Flags.audioBufferListAssure16ByteAlignment
    precondition(sample.insert(alignment).inserted)
    precondition(sample.contains(alignment))
    precondition(sample.remove(alignment) != nil)
    _ = sample.update(with: alignment)
    precondition(sample.union([]) == sample)
    precondition(sample.intersection(alignment) == sample)
    precondition(sample.symmetricDifference(alignment).isEmpty)
    sample.formUnion(alignment)
    sample.formIntersection(alignment)
    sample.formSymmetricDifference(alignment)
}

func testCMFormatDescriptionRawWrapperHashAndEquality() {
    func verify<T: Hashable>(_ value: T, _ same: T) {
        precondition(value == same)
        precondition(!(value != same))
        var first = Hasher()
        var second = Hasher()
        value.hash(into: &first)
        same.hash(into: &second)
        precondition(first.finalize() == second.finalize())
        precondition(value.hashValue == same.hashValue)
    }
    verify(CMFormatDescription.MediaType.video, .video)
    verify(CMFormatDescription.MediaSubType.h264, .h264)
    verify(CMFormatDescription.Extensions.Key.formatName, .formatName)
    verify(CMFormatDescription.Extensions.Value.FieldDetail.temporalBottomFirst, .temporalBottomFirst)
    verify(CMFormatDescription.Extensions.Value.YCbCrMatrix.itu_R_2020, .itu_R_2020)
    verify(CMFormatDescription.Extensions.Value.ChromaLocation.center, .center)
    verify(CMFormatDescription.Extensions.Value.ColorPrimaries.itu_R_2020, .itu_R_2020)
    verify(CMFormatDescription.Extensions.Value.ProjectionKind.rectilinear, .rectilinear)
    verify(CMFormatDescription.Extensions.Value.ViewPackingKind.sideBySide, .sideBySide)
    verify(CMFormatDescription.Extensions.Value.AlphaChannelMode.straightAlpha, .straightAlpha)
    verify(CMFormatDescription.Extensions.Value.TextDisplayFlags.scrollIn, .scrollIn)
    verify(CMFormatDescription.Extensions.Value.TransferFunction.itu_R_709_2, .itu_R_709_2)
    verify(CMFormatDescription.Extensions.Value.TextJustification.left, .left)
    verify(CMFormatDescription.Extensions.Value.LogTransferFunction.appleLog, .appleLog)
    verify(CMFormatDescription.Extensions.Value.Vendor.apple, .apple)
    verify(CMFormatDescription.Extensions.Value.HeroEye.left, .left)
    verify(CMFormatDescription.Extensions.Value.FontFace.bold, .bold)
}

func testCMSampleBufferAttachmentKeyTable() {
    let keys: [CMSampleBuffer.AttachmentKey] = [
        .displayEmptyMediaImmediately, .permanentEmptyMedia, .emptyMedia, .forceKeyFrame,
        .resumeOutput, .transitionID, .speedMultiplier, .trimDurationAtEnd,
        .drainAfterDecoding, .droppedFrameReason, .sampleReferenceURL,
        .trimDurationAtStart, .cameraIntrinsicMatrix, .gradualDecoderRefresh,
        .droppedFrameReasonInfo, .sampleReferenceByteOffset, .endsPreviousSampleDuration,
        .resetDecoderBeforeDecoding, .postNotificationWhenConsumed,
        .fillDiscontinuitiesWithSilence, .stillImageLensStabilizationInfo, .reverse,
    ]
    precondition(keys.count == 22)
    precondition(Set(keys).count == keys.count)
    precondition(keys.allSatisfy { CFStringGetLength($0.rawValue) > 0 })
}
