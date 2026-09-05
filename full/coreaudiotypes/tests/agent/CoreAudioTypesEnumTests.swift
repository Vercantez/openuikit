import CoreAudioTypes

private func require(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError("COREAUDIOTYPES_TEST_FAIL: \(message)")
    }
}

private func requireEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) {
    require(actual == expected, "\(message): \(actual) != \(expected)")
}

func testAudioChannelCoordinateIndexIdentity() {
    requireEqual(MemoryLayout<AudioChannelCoordinateIndex>.stride, 4, "stride")
    requireEqual(MemoryLayout<AudioChannelCoordinateIndex>.alignment, 4, "alignment")
    require(AudioChannelCoordinateIndex.coordinates_LeftRight != .coordinates_BackFront, "!=")
    require(AudioChannelCoordinateIndex(rawValue: 0) == .coordinates_LeftRight, "init 0")
    require(AudioChannelCoordinateIndex(rawValue: 1) == .coordinates_BackFront, "init 1")
    require(AudioChannelCoordinateIndex(rawValue: 2) == .coordinates_DownUp, "init 2")
    require(AudioChannelCoordinateIndex(rawValue: 99) == nil, "unknown raw is nil")
    requireEqual(AudioChannelCoordinateIndex.coordinates_LeftRight.hashValue, AudioChannelCoordinateIndex.coordinates_Azimuth.hashValue, "alias hashValue")
    var hasher = Hasher()
    AudioChannelCoordinateIndex.coordinates_DownUp.hash(into: &hasher)
    _ = hasher.finalize()
    requireEqual(
        Set([AudioChannelCoordinateIndex.coordinates_LeftRight, .coordinates_Azimuth, .coordinates_DownUp]).count,
        2,
        "Hashable aliases"
    )
}

func testMPEG4ObjectIDIdentity() {
    requireEqual(MemoryLayout<MPEG4ObjectID>.stride, 8, "stride")
    requireEqual(MemoryLayout<MPEG4ObjectID>.alignment, 8, "alignment")
    require(MPEG4ObjectID.AAC_LC != .aac_Main, "!=")
    require(MPEG4ObjectID(rawValue: 2) == .AAC_LC, "init LC")
    require(MPEG4ObjectID(rawValue: 1) == .aac_Main, "init main")
    require(MPEG4ObjectID(rawValue: 0) == nil, "unknown raw is nil")
    requireEqual(MPEG4ObjectID.AAC_LC.hashValue, MPEG4ObjectID.AAC_LC.hashValue, "stable hashValue")
    var hasher = Hasher()
    MPEG4ObjectID.CELP.hash(into: &hasher)
    _ = hasher.finalize()
    requireEqual(Set([MPEG4ObjectID.AAC_LC, .AAC_LC, .CELP]).count, 2, "Hashable")
}

func testSMPTETimeTypeIdentity() {
    requireEqual(MemoryLayout<SMPTETimeType>.stride, 4, "stride")
    requireEqual(MemoryLayout<SMPTETimeType>.alignment, 4, "alignment")
    require(SMPTETimeType.type25 != .type24, "!=")
    require(SMPTETimeType(rawValue: 0) == .type24, "init 0")
    require(SMPTETimeType(rawValue: 2) == .type30Drop, "init 2")
    require(SMPTETimeType(rawValue: 99) == nil, "unknown raw is nil")
    requireEqual(SMPTETimeType.type24.hashValue, SMPTETimeType.type24.hashValue, "stable hashValue")
    var hasher = Hasher()
    SMPTETimeType.type30.hash(into: &hasher)
    _ = hasher.finalize()
    requireEqual(Set([SMPTETimeType.type24, .type24, .type30]).count, 2, "Hashable")
}
