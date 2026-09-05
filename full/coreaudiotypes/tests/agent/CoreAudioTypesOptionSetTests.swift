import CoreAudioTypes

private func require(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError("COREAUDIOTYPES_TEST_FAIL: \(message)")
    }
}

private func requireEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) {
    require(actual == expected, "\(message): \(actual) != \(expected)")
}

private func exerciseOptionSetAlgebra<T>(
    empty: T,
    a: T,
    b: T,
    name: String
) where T: OptionSet, T: Equatable, T.Element == T, T: ExpressibleByArrayLiteral, T.ArrayLiteralElement == T {
    require(empty.isEmpty, "\(name) isEmpty")
    require(!a.isEmpty, "\(name) a is nonempty")
    require(a.contains(a), "\(name) contains self")
    require(!empty.contains(a), "\(name) empty does not contain a")
    requireEqual(a.union(b).intersection(a), a, "\(name) union/intersection")
    var formed = empty
    formed.formUnion(a)
    requireEqual(formed, a, "\(name) formUnion")
    requireEqual(a.intersection(empty), empty, "\(name) intersection empty")
    var inter = a.union(b)
    inter.formIntersection(a)
    requireEqual(inter, a, "\(name) formIntersection")
    requireEqual(a.symmetricDifference(a), empty, "\(name) symmetricDifference self")
    var sym = a
    sym.formSymmetricDifference(a)
    requireEqual(sym, empty, "\(name) formSymmetricDifference")
    requireEqual(a.subtracting(a), empty, "\(name) subtracting self")
    var sub = a.union(b)
    sub.subtract(a)
    requireEqual(sub.intersection(a), empty, "\(name) subtract")
    require(a.union(b).isSuperset(of: a), "\(name) isSuperset")
    require(a.isSubset(of: a.union(b)), "\(name) isSubset")
    require(empty.isDisjoint(with: a), "\(name) empty disjoint")
    require(a.isDisjoint(with: empty), "\(name) a disjoint empty")
    require(a.isStrictSubset(of: a.union(b)), "\(name) isStrictSubset")
    require(a.union(b).isStrictSuperset(of: a), "\(name) isStrictSuperset")
    require(!a.isStrictSubset(of: a), "\(name) not strict subset of self")
    require(!a.isStrictSuperset(of: a), "\(name) not strict superset of self")
    var mutable = empty
    let inserted = mutable.insert(a)
    require(inserted.inserted, "\(name) insert new")
    require(mutable.contains(a), "\(name) insert contains")
    _ = mutable.update(with: a)
    require(mutable.contains(a), "\(name) update")
    let removed = mutable.remove(a)
    require(removed != nil, "\(name) remove")
    require(!mutable.contains(a), "\(name) removed")
    require(empty != a, "\(name) !=")
    requireEqual(T(rawValue: a.rawValue), a, "\(name) rawValue round trip")
    let literal: T = [a, b]
    require(literal.contains(a) && literal.contains(b), "\(name) arrayLiteral")
    let fromSequence = T([a, b])
    require(fromSequence.contains(a) && fromSequence.contains(b), "\(name) sequence init")
    require(T().isEmpty, "\(name) init()")
}

func testAudioChannelBitmapAlgebra() {
    let empty = AudioChannelBitmap()
    let left = AudioChannelBitmap.bit_Left
    let right = AudioChannelBitmap.bit_Right
    exerciseOptionSetAlgebra(empty: empty, a: left, b: right, name: "AudioChannelBitmap")
    let stereo: AudioChannelBitmap = [.bit_Left, .bit_Right]
    require(stereo.contains(.bit_Left) && stereo.contains(.bit_Right), "stereo bits")
    require(!stereo.contains(.bit_Center), "stereo excludes center")
    requireEqual(stereo.union(.bit_Center).intersection(.bit_Center), .bit_Center, "center union")
    requireEqual(AudioChannelBitmap(rawValue: 0x5).rawValue, 0x5, "raw 0x5")
}

func testAudioChannelFlagsAlgebra() {
    let empty = AudioChannelFlags()
    let rectangular = AudioChannelFlags.rectangularCoordinates
    let meters = AudioChannelFlags.meters
    exerciseOptionSetAlgebra(empty: empty, a: rectangular, b: meters, name: "AudioChannelFlags")
    let flags: AudioChannelFlags = [.rectangularCoordinates, .meters]
    require(flags.contains(.rectangularCoordinates), "rect")
    require(flags.contains(.meters), "meters")
    require(!flags.contains(.sphericalCoordinates), "not spherical")
    requireEqual(AudioChannelFlags(rawValue: flags.rawValue), flags, "flags round trip")
}

func testAudioTimeStampFlagsAlgebra() {
    let empty = AudioTimeStampFlags()
    let sample = AudioTimeStampFlags.sampleTimeValid
    let host = AudioTimeStampFlags.hostTimeValid
    exerciseOptionSetAlgebra(empty: empty, a: sample, b: host, name: "AudioTimeStampFlags")
    var timestampFlags: AudioTimeStampFlags = [.sampleTimeValid]
    timestampFlags.formUnion(.hostTimeValid)
    requireEqual(timestampFlags, .sampleHostTimeValid, "sampleHostTimeValid is sample+host")
    requireEqual(
        AudioTimeStampFlags.sampleTimeValid.union(.rateScalarValid).symmetricDifference(.rateScalarValid),
        .sampleTimeValid,
        "timestamp symmetric difference"
    )
    requireEqual(AudioTimeStampFlags(rawValue: 0x15).rawValue, 0x15, "raw 0x15")
    require(AudioTimeStampFlags.smpteTimeValid.contains(.smpteTimeValid), "smpte valid")
    require(AudioTimeStampFlags.wordClockTimeValid.contains(.wordClockTimeValid), "word clock")
}

func testSMPTETimeFlagsAlgebra() {
    let empty = SMPTETimeFlags()
    let valid = SMPTETimeFlags.valid
    let running = SMPTETimeFlags.running
    exerciseOptionSetAlgebra(empty: empty, a: valid, b: running, name: "SMPTETimeFlags")
    let smpte: SMPTETimeFlags = [.valid, .running]
    require(smpte.contains(.valid) && smpte.contains(.running), "both flags")
    requireEqual(SMPTETimeFlags(rawValue: smpte.rawValue), smpte, "round trip")
    require(!SMPTETimeFlags().contains(.valid), "empty has no valid")
}
