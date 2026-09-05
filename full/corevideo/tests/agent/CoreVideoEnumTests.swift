import CoreVideo
import Foundation

func testAttachmentMode() {
    precondition(CVAttachmentMode.shouldNotPropagate.rawValue == 0)
    precondition(CVAttachmentMode.shouldPropagate.rawValue == 1)
    precondition(CVAttachmentMode(rawValue: 1) == .shouldPropagate)
    precondition(CVAttachmentMode.shouldPropagate != .shouldNotPropagate)
    var hasher = Hasher()
    CVAttachmentMode.shouldPropagate.hash(into: &hasher)
    _ = CVAttachmentMode.shouldPropagate.hashValue
}

func testPixelBufferLockFlags() {
    precondition(CVPixelBufferLockFlags.readOnly.rawValue == 1)
    let flags = CVPixelBufferLockFlags(rawValue: 1)
    precondition(flags.contains(.readOnly))
    precondition(CVPixelBufferLockFlags(arrayLiteral: .readOnly) == .readOnly)
    precondition(CVPixelBufferLockFlags([.readOnly]) == .readOnly)
    precondition(CVPixelBufferLockFlags.readOnly != [])
}

func testPixelBufferPoolFlushFlags() {
    precondition(CVPixelBufferPoolFlushFlags.excessBuffers.rawValue == 1)
    precondition(CVPixelBufferPoolFlushFlags(rawValue: 1).contains(.excessBuffers))
    precondition(CVPixelBufferPoolFlushFlags(arrayLiteral: .excessBuffers) == .excessBuffers)
    precondition(CVPixelBufferPoolFlushFlags([.excessBuffers]) == .excessBuffers)
}

func testSMPTETimeTypeAndFlags() {
    precondition(CVSMPTETimeType.type24.rawValue == 0)
    precondition(CVSMPTETimeType.type25.rawValue == 1)
    precondition(CVSMPTETimeType.type30Drop.rawValue == 2)
    precondition(CVSMPTETimeType.type30.rawValue == 3)
    precondition(CVSMPTETimeType.type2997.rawValue == 4)
    precondition(CVSMPTETimeType.type2997Drop.rawValue == 5)
    precondition(CVSMPTETimeType.type60.rawValue == 6)
    precondition(CVSMPTETimeType.type5994.rawValue == 7)
    precondition(CVSMPTETimeType(rawValue: 3) == .type30)
    precondition(CVSMPTETimeType.type24 != .type60)
    var hasher = Hasher()
    CVSMPTETimeType.type24.hash(into: &hasher)
    _ = CVSMPTETimeType.type24.hashValue
    precondition(CVSMPTETimeFlags.valid.rawValue == 1)
    precondition(CVSMPTETimeFlags.running.rawValue == 2)
}

func testCVTimeFlags() {
    precondition(CVTimeFlags.isIndefinite.rawValue == 1)
    precondition(CVTimeFlags(rawValue: 1) == .isIndefinite)
}

func testCVTimeStampFlagsMembers() {
    precondition(CVTimeStampFlags.videoTimeValid.rawValue == 1)
    precondition(CVTimeStampFlags.hostTimeValid.rawValue == 2)
    precondition(CVTimeStampFlags.smpteTimeValid.rawValue == 4)
    precondition(CVTimeStampFlags.videoRefreshPeriodValid.rawValue == 8)
    precondition(CVTimeStampFlags.rateScalarValid.rawValue == 16)
    precondition(CVTimeStampFlags.topField.rawValue == 32)
    precondition(CVTimeStampFlags.bottomField.rawValue == 64)
    precondition(CVTimeStampFlags.videoHostTimeValid == [.videoTimeValid, .hostTimeValid])
    precondition(CVTimeStampFlags.isInterlaced == [.topField, .bottomField])
}

func testCVTimeStampFlagsAlgebra() {
    var flags = CVTimeStampFlags()
    precondition(flags.isEmpty)
    let inserted = flags.insert(.hostTimeValid)
    precondition(inserted.inserted)
    precondition(flags.contains(.hostTimeValid))
    precondition(flags.union(.topField).contains(.topField))
    precondition(flags.intersection(.hostTimeValid) == .hostTimeValid)
    precondition(flags.symmetricDifference(.topField).contains(.topField))
    flags.formUnion(.bottomField)
    flags.formIntersection([.hostTimeValid, .bottomField])
    flags.formSymmetricDifference(.topField)
    _ = flags.remove(.topField)
    _ = flags.update(with: .rateScalarValid)
    flags.subtract(.rateScalarValid)
    precondition(flags.subtracting(.hostTimeValid).isDisjoint(with: .hostTimeValid))
    precondition(CVTimeStampFlags.videoHostTimeValid.isSuperset(of: .hostTimeValid))
    precondition(CVTimeStampFlags.hostTimeValid.isSubset(of: .videoHostTimeValid))
    precondition(CVTimeStampFlags.hostTimeValid.isStrictSubset(of: .videoHostTimeValid))
    precondition(CVTimeStampFlags.videoHostTimeValid.isStrictSuperset(of: .hostTimeValid))
    precondition(CVTimeStampFlags(rawValue: 2) == .hostTimeValid)
    precondition(CVTimeStampFlags(arrayLiteral: .topField) == .topField)
    precondition(CVTimeStampFlags([.bottomField]) == .bottomField)
    precondition(CVTimeStampFlags.hostTimeValid != .topField)
    var hasher = Hasher()
    flags.hash(into: &hasher)
    _ = flags.hashValue
}

func testLockFlagsAlgebra() {
    var flags = CVPixelBufferLockFlags()
    precondition(flags.isEmpty)
    _ = flags.insert(.readOnly)
    precondition(flags.contains(.readOnly))
    precondition(flags.union(.readOnly) == .readOnly)
    precondition(flags.intersection(.readOnly) == .readOnly)
    _ = flags.symmetricDifference([])
    flags.formUnion(.readOnly)
    flags.formIntersection(.readOnly)
    flags.formSymmetricDifference([])
    _ = flags.remove(.readOnly)
    _ = flags.update(with: .readOnly)
    flags.subtract(.readOnly)
    precondition(CVPixelBufferLockFlags.readOnly.isSuperset(of: .readOnly))
    precondition(CVPixelBufferLockFlags.readOnly.isSubset(of: .readOnly))
    precondition(!CVPixelBufferLockFlags.readOnly.isStrictSubset(of: .readOnly))
    precondition(!CVPixelBufferLockFlags.readOnly.isStrictSuperset(of: .readOnly))
    precondition(CVPixelBufferLockFlags.readOnly.isDisjoint(with: []))
    precondition(CVPixelBufferLockFlags.readOnly.subtracting(.readOnly).isEmpty)
    var hasher = Hasher()
    CVPixelBufferLockFlags.readOnly.hash(into: &hasher)
    _ = CVPixelBufferLockFlags.readOnly.hashValue
}

func testTimeFlagsAlgebra() {
    var flags = CVTimeFlags()
    _ = flags.insert(.isIndefinite)
    precondition(flags.contains(.isIndefinite))
    precondition(flags.union(.isIndefinite) == .isIndefinite)
    precondition(flags.intersection(.isIndefinite) == .isIndefinite)
    _ = flags.symmetricDifference([])
    flags.formUnion(.isIndefinite)
    flags.formIntersection(.isIndefinite)
    flags.formSymmetricDifference([])
    _ = flags.remove(.isIndefinite)
    _ = flags.update(with: .isIndefinite)
    flags.subtract([])
    precondition(CVTimeFlags.isIndefinite.isSuperset(of: .isIndefinite))
    precondition(CVTimeFlags.isIndefinite.isSubset(of: .isIndefinite))
    precondition(!CVTimeFlags.isIndefinite.isStrictSubset(of: .isIndefinite))
    precondition(!CVTimeFlags.isIndefinite.isStrictSuperset(of: .isIndefinite))
    precondition(CVTimeFlags.isIndefinite.isDisjoint(with: []))
    precondition(CVTimeFlags(arrayLiteral: .isIndefinite) == .isIndefinite)
    precondition(CVTimeFlags([.isIndefinite]) == .isIndefinite)
    precondition(CVTimeFlags() != .isIndefinite)
    var hasher = Hasher()
    CVTimeFlags.isIndefinite.hash(into: &hasher)
    _ = CVTimeFlags.isIndefinite.hashValue
}

func testSMPTEFlagsAlgebra() {
    var flags = CVSMPTETimeFlags()
    _ = flags.insert(.valid)
    flags.formUnion(.running)
    precondition(flags.contains(.running))
    precondition(flags.union(.valid).contains(.valid))
    precondition(flags.intersection(.valid) == .valid)
    _ = flags.symmetricDifference(.running)
    flags.formIntersection([.valid, .running])
    flags.formSymmetricDifference(.running)
    _ = flags.remove(.running)
    _ = flags.update(with: .valid)
    flags.subtract([])
    precondition(CVSMPTETimeFlags.valid.isSubset(of: [.valid, .running]))
    precondition(([.valid, .running] as CVSMPTETimeFlags).isSuperset(of: .valid))
    precondition(CVSMPTETimeFlags.valid.isStrictSubset(of: [.valid, .running]))
    precondition(([.valid, .running] as CVSMPTETimeFlags).isStrictSuperset(of: .valid))
    precondition(CVSMPTETimeFlags.valid.isDisjoint(with: .running))
    precondition(CVSMPTETimeFlags(arrayLiteral: .valid) == .valid)
    precondition(CVSMPTETimeFlags([.running]) == .running)
    precondition(CVSMPTETimeFlags.valid != .running)
    var hasher = Hasher()
    flags.hash(into: &hasher)
    _ = flags.hashValue
}

func testPoolFlushFlagsAlgebra() {
    var flags = CVPixelBufferPoolFlushFlags()
    _ = flags.insert(.excessBuffers)
    precondition(flags.contains(.excessBuffers))
    precondition(flags.union(.excessBuffers) == .excessBuffers)
    precondition(flags.intersection(.excessBuffers) == .excessBuffers)
    _ = flags.symmetricDifference([])
    flags.formUnion(.excessBuffers)
    flags.formIntersection(.excessBuffers)
    flags.formSymmetricDifference([])
    _ = flags.remove(.excessBuffers)
    _ = flags.update(with: .excessBuffers)
    flags.subtract([])
    precondition(CVPixelBufferPoolFlushFlags.excessBuffers.isSuperset(of: .excessBuffers))
    precondition(CVPixelBufferPoolFlushFlags.excessBuffers.isSubset(of: .excessBuffers))
    precondition(!CVPixelBufferPoolFlushFlags.excessBuffers.isStrictSubset(of: .excessBuffers))
    precondition(!CVPixelBufferPoolFlushFlags.excessBuffers.isStrictSuperset(of: .excessBuffers))
    precondition(CVPixelBufferPoolFlushFlags.excessBuffers.isDisjoint(with: []))
    precondition(CVPixelBufferPoolFlushFlags() != .excessBuffers)
    var hasher = Hasher()
    CVPixelBufferPoolFlushFlags.excessBuffers.hash(into: &hasher)
    _ = CVPixelBufferPoolFlushFlags.excessBuffers.hashValue
}
