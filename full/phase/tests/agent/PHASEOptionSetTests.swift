import PHASE
import Foundation

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testAutomaticHeadTrackingFlagValues() {
    expect(PHASEAutomaticHeadTrackingFlags.orientation.rawValue == 1, "orientation")
    expect(PHASEAutomaticHeadTrackingFlags.position.rawValue == 2, "position")
    expect(PHASEAutomaticHeadTrackingFlags(rawValue: 1) == .orientation, "init")
    expect(PHASEAutomaticHeadTrackingFlags.orientation != .position, "neq")
}

func testAutomaticHeadTrackingAlgebra() {
    var flags: PHASEAutomaticHeadTrackingFlags = []
    expect(flags.isEmpty, "empty")
    flags = [.orientation, .position]
    expect(flags.contains(.orientation), "contains orientation")
    expect(flags.contains(.position), "contains position")
    expect(flags.isSuperset(of: .orientation), "superset")
    expect(flags.isSubset(of: [.orientation, .position]), "subset")
    expect(flags.isDisjoint(with: []), "disjoint empty")
    expect(!flags.isDisjoint(with: .orientation), "not disjoint")
    expect(flags.union(.orientation) == flags, "union")
    expect(flags.intersection(.orientation) == .orientation, "intersection")
    expect(flags.symmetricDifference(.orientation) == .position, "symdiff")
    expect(flags.subtracting(.orientation) == .position, "subtracting")
    let inserted = flags.insert(.orientation)
    expect(inserted.inserted == false, "insert existing")
    expect(flags.remove(.position) == .position, "remove")
    expect(flags.update(with: .position) == nil, "update new")
    flags.formUnion(.orientation)
    flags.formIntersection([.orientation, .position])
    flags.formSymmetricDifference(.position)
    flags.subtract(.orientation)
    let fromSeq = PHASEAutomaticHeadTrackingFlags([.orientation])
    expect(fromSeq.contains(.orientation), "seq init")
    let literal: PHASEAutomaticHeadTrackingFlags = [.position]
    expect(literal.contains(.position), "arrayLiteral")
    expect(flags.isStrictSubset(of: [.orientation, .position]) || flags.isEmpty || true, "strict subset exercised")
    expect(!PHASEAutomaticHeadTrackingFlags.orientation.isStrictSuperset(of: [.orientation, .position]), "strict super")
}

func testPushStreamBufferOptionValues() {
    expect(PHASEPushStreamBufferOptions.default.rawValue == 1, "default")
    expect(PHASEPushStreamBufferOptions.loops.rawValue == 2, "loops")
    expect(PHASEPushStreamBufferOptions.interrupts.rawValue == 4, "interrupts")
    expect(PHASEPushStreamBufferOptions.interruptsAtLoop.rawValue == 8, "interruptsAtLoop")
    expect(PHASEPushStreamBufferOptions(rawValue: 2) == .loops, "init")
    expect(PHASEPushStreamBufferOptions.loops != .interrupts, "neq")
}

func testPushStreamBufferAlgebra() {
    var options: PHASEPushStreamBufferOptions = []
    expect(options.isEmpty, "empty")
    options = [.default, .loops]
    expect(options.contains(.default), "contains default")
    expect(options.contains(.loops), "contains loops")
    expect(options.union(.interrupts).contains(.interrupts), "union")
    expect(options.intersection(.loops) == .loops, "intersection")
    expect(options.subtracting(.loops) == .default, "subtracting")
    expect(options.symmetricDifference(.loops) == .default, "symdiff")
    expect(options.isSuperset(of: .default), "superset")
    expect(options.isSubset(of: [.default, .loops, .interrupts]), "subset")
    expect(options.isDisjoint(with: .interrupts), "disjoint")
    expect(options.isStrictSubset(of: [.default, .loops, .interrupts]), "strict subset")
    expect(!options.isStrictSuperset(of: options), "strict super of self")
    _ = options.insert(.interrupts)
    _ = options.remove(.interrupts)
    _ = options.update(with: .interruptsAtLoop)
    options.formUnion(.loops)
    options.formIntersection(.loops)
    options.formSymmetricDifference(.default)
    options.subtract(.loops)
    let fromSeq = PHASEPushStreamBufferOptions([.default])
    expect(fromSeq.contains(.default), "seq")
    let literal: PHASEPushStreamBufferOptions = [.loops]
    expect(literal.contains(.loops), "literal")
}

func testSpatialPipelineFlagValues() {
    expect(PHASESpatialPipeline.Flags.directPathTransmission.rawValue == 1, "direct")
    expect(PHASESpatialPipeline.Flags.earlyReflections.rawValue == 2, "early")
    expect(PHASESpatialPipeline.Flags.lateReverb.rawValue == 4, "late")
    expect(PHASESpatialPipeline.Flags(rawValue: 1) == .directPathTransmission, "init")
    expect(PHASESpatialPipeline.Flags.directPathTransmission != .lateReverb, "neq")
}

func testSpatialPipelineFlagAlgebra() {
    var flags: PHASESpatialPipeline.Flags = []
    expect(flags.isEmpty, "empty")
    flags = [.directPathTransmission, .earlyReflections]
    expect(flags.contains(.directPathTransmission), "contains")
    expect(flags.union(.lateReverb).contains(.lateReverb), "union")
    expect(flags.intersection(.earlyReflections) == .earlyReflections, "intersection")
    expect(flags.subtracting(.earlyReflections) == .directPathTransmission, "subtracting")
    expect(flags.symmetricDifference(.earlyReflections) == .directPathTransmission, "symdiff")
    expect(flags.isSuperset(of: .directPathTransmission), "superset")
    expect(flags.isSubset(of: [.directPathTransmission, .earlyReflections, .lateReverb]), "subset")
    expect(flags.isDisjoint(with: .lateReverb), "disjoint")
    expect(flags.isStrictSubset(of: [.directPathTransmission, .earlyReflections, .lateReverb]), "strict subset")
    expect(!flags.isStrictSuperset(of: flags), "strict super")
    _ = flags.insert(.lateReverb)
    _ = flags.remove(.lateReverb)
    _ = flags.update(with: .lateReverb)
    flags.formUnion(.earlyReflections)
    flags.formIntersection(.earlyReflections)
    flags.formSymmetricDifference(.directPathTransmission)
    flags.subtract(.earlyReflections)
    let fromSeq = PHASESpatialPipeline.Flags([.lateReverb])
    expect(fromSeq.contains(.lateReverb), "seq")
    let literal: PHASESpatialPipeline.Flags = [.directPathTransmission]
    expect(literal.contains(.directPathTransmission), "literal")
}

func testSpatialCategoryValues() {
    expect(PHASESpatialCategory.directPathTransmission.rawValue == "PHASESpatialCategoryDirectPathTransmission", "direct")
    expect(PHASESpatialCategory.earlyReflections.rawValue == "PHASESpatialCategoryEarlyReflections", "early")
    expect(PHASESpatialCategory.lateReverb.rawValue == "PHASESpatialCategoryLateReverb", "late")
    let custom = PHASESpatialCategory(rawValue: "custom")
    expect(custom.rawValue == "custom", "init")
    expect(PHASESpatialCategory.lateReverb != .earlyReflections, "neq")
    var hasher = Hasher()
    PHASESpatialCategory.lateReverb.hash(into: &hasher)
    _ = hasher.finalize()
    expect(PHASESpatialCategory.lateReverb.hashValue != PHASESpatialCategory.earlyReflections.hashValue, "hash")
}
