import Foundation
@_spi(OpenUIKitHost) import SensorKit

func testAmbientLightPlacement() {
    let rows: [(SRAmbientLightSample.SensorPlacement, Int)] = [
        (.unknown, 0), (.frontTop, 1), (.frontBottom, 2), (.frontRight, 3),
        (.frontLeft, 4), (.frontTopRight, 5), (.frontTopLeft, 6),
        (.frontBottomRight, 7), (.frontBottomLeft, 8),
    ]
    for (value, raw) in rows {
        skExpect(value.rawValue == raw, "placement \(raw)")
        skExpect(SRAmbientLightSample.SensorPlacement(rawValue: raw) == value, "rt")
        skExpect(value != .unknown || raw == 0, "!=")
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
}

func testChromaticity() {
    let zero = SRAmbientLightSample.Chromaticity()
    skExpect(zero.x == 0 && zero.y == 0, "zero init")
    var chroma = SRAmbientLightSample.Chromaticity(x: 0.3, y: 0.4)
    skExpect(chroma.x == 0.3 && chroma.y == 0.4, "xy")
    chroma.x = 0.5
    chroma.y = 0.6
    skExpect(chroma.x == 0.5 && chroma.y == 0.6, "mutate")
}

func testAmbientLightSample() {
    let sample = SRAmbientLightSample(
        chromaticity: SRAmbientLightSample.Chromaticity(x: 0.31, y: 0.32),
        lux: Measurement(value: 120, unit: .lux),
        placement: .frontTop
    )
    skExpect(sample.chromaticity.x == 0.31, "x")
    skExpect(sample.lux.value == 120, "lux")
    skExpect(sample.placement == .frontTop, "placement")
}

func testWristDetectionEnums() {
    skExpect(SRWristDetection.CrownOrientation.left.rawValue == 0, "crown left")
    skExpect(SRWristDetection.CrownOrientation.right.rawValue == 1, "crown right")
    skExpect(SRWristDetection.CrownOrientation(rawValue: 1) == .right, "rt")
    skExpect(SRWristDetection.CrownOrientation.left != .right, "!=")
    _ = SRWristDetection.CrownOrientation.left.hashValue
    var hasher = Hasher()
    SRWristDetection.CrownOrientation.right.hash(into: &hasher)
    _ = hasher.finalize()

    skExpect(SRWristDetection.WristLocation.left.rawValue == 0, "wrist left")
    skExpect(SRWristDetection.WristLocation.right.rawValue == 1, "wrist right")
    skExpect(SRWristDetection.WristLocation(rawValue: 0) == .left, "rt")
    skExpect(SRWristDetection.WristLocation.left != .right, "!=")
    _ = SRWristDetection.WristLocation.right.hashValue
    var hasher2 = Hasher()
    SRWristDetection.WristLocation.left.hash(into: &hasher2)
    _ = hasher2.finalize()
}

func testWristDetectionSample() {
    let on = Date(timeIntervalSinceReferenceDate: 10)
    let off = Date(timeIntervalSinceReferenceDate: 20)
    let detection = SRWristDetection(
        crownOrientation: .left,
        offWristDate: off,
        onWrist: true,
        onWristDate: on,
        wristLocation: .right
    )
    skExpect(detection.crownOrientation == .left, "crown")
    skExpect(detection.offWristDate == off, "off")
    skExpect(detection.onWrist, "on")
    skExpect(detection.onWristDate == on, "onDate")
    skExpect(detection.wristLocation == .right, "loc")
}

func testWristTemperatureCondition() {
    var flags: SRWristTemperature.Condition = []
    skExpect(flags.isEmpty, "empty")
    skExpect(SRWristTemperature.Condition.offWrist.rawValue == 1, "offWrist")
    skExpect(SRWristTemperature.Condition.onCharger.rawValue == 2, "onCharger")
    skExpect(SRWristTemperature.Condition.inMotion.rawValue == 4, "inMotion")
    flags.insert(.offWrist)
    skExpect(flags.contains(.offWrist), "contains")
    flags.formUnion(.onCharger)
    skExpect(flags.contains(.onCharger), "union")
    skExpect(flags.isSuperset(of: .offWrist), "superset")
    skExpect(flags.isSubset(of: [.offWrist, .onCharger, .inMotion]), "subset")
    skExpect(!flags.isDisjoint(with: .offWrist), "disjoint")
    skExpect(flags.intersection(.offWrist) == .offWrist, "intersection")
    skExpect(flags.symmetricDifference(.onCharger) == .offWrist, "symdiff")
    let subtracted = flags.subtracting(.offWrist)
    skExpect(subtracted == .onCharger, "subtracting")
    var copy = flags
    copy.subtract(.onCharger)
    skExpect(copy == .offWrist, "subtract")
    var form = SRWristTemperature.Condition.offWrist
    form.formIntersection(.offWrist)
    form.formSymmetricDifference(.inMotion)
    skExpect(form.contains(.inMotion), "formSym")
    let sequence = SRWristTemperature.Condition([.offWrist, .inMotion])
    skExpect(sequence.contains(.offWrist) && sequence.contains(.inMotion), "seq")
    let literal: SRWristTemperature.Condition = [.onCharger]
    skExpect(literal == .onCharger, "literal")
    skExpect(!flags.isStrictSubset(of: .offWrist), "strict subset")
    skExpect(SRWristTemperature.Condition.offWrist.isStrictSubset(of: [.offWrist, .onCharger]), "strict")
    skExpect(flags.isStrictSuperset(of: .offWrist) || flags.contains(.offWrist), "strict super")
    let removed = flags.remove(.offWrist)
    skExpect(removed != nil, "remove")
    let updated = flags.update(with: .inMotion)
    _ = updated
    skExpect(SRWristTemperature.Condition() == [], "init")
    skExpect(SRWristTemperature.Condition.offWrist != .onCharger, "!=")
}

func testWristTemperatureSample() {
    let sample = SRWristTemperature(
        condition: [.offWrist],
        errorEstimate: Measurement(value: 0.1, unit: .celsius),
        timestamp: Date(timeIntervalSinceReferenceDate: 1),
        value: Measurement(value: 36.5, unit: .celsius)
    )
    skExpect(sample.condition.contains(.offWrist), "cond")
    skExpect(sample.errorEstimate.value == 0.1, "err")
    skExpect(sample.value.value == 36.5, "value")
    skExpect(sample.timestamp.timeIntervalSinceReferenceDate == 1, "ts")

    let session = SRWristTemperatureSession(
        duration: 60,
        startDate: Date(timeIntervalSinceReferenceDate: 0),
        version: "1",
        temperatures: [sample]
    )
    skExpect(session.duration == 60, "dur")
    skExpect(session.version == "1", "ver")
    skExpect(Array(session.temperatures).count == 1, "seq")
}

func testECGEnumsAndFlags() {
    skExpect(SRElectrocardiogramSample.Lead.rightArmMinusLeftArm.rawValue == 1, "lead1")
    skExpect(SRElectrocardiogramSample.Lead.leftArmMinusRightArm.rawValue == 2, "lead2")
    skExpect(SRElectrocardiogramSample.Lead(rawValue: 2) == .leftArmMinusRightArm, "rt")
    skExpect(SRElectrocardiogramSample.Lead.rightArmMinusLeftArm != .leftArmMinusRightArm, "!=")
    _ = SRElectrocardiogramSample.Lead.rightArmMinusLeftArm.hashValue
    var hasher = Hasher()
    SRElectrocardiogramSample.Lead.leftArmMinusRightArm.hash(into: &hasher)
    _ = hasher.finalize()

    skExpect(SRElectrocardiogramSession.State.begin.rawValue == 1, "begin")
    skExpect(SRElectrocardiogramSession.State.active.rawValue == 2, "active")
    skExpect(SRElectrocardiogramSession.State.end.rawValue == 3, "end")
    skExpect(SRElectrocardiogramSession.State(rawValue: 2) == .active, "rt")
    skExpect(SRElectrocardiogramSession.State.begin != .end, "!=")
    _ = SRElectrocardiogramSession.State.begin.hashValue
    var hasher2 = Hasher()
    SRElectrocardiogramSession.State.end.hash(into: &hasher2)
    _ = hasher2.finalize()

    skExpect(SRElectrocardiogramSession.SessionGuidance.guided.rawValue == 1, "guided")
    skExpect(SRElectrocardiogramSession.SessionGuidance.unguided.rawValue == 2, "unguided")
    skExpect(SRElectrocardiogramSession.SessionGuidance(rawValue: 1) == .guided, "rt")
    skExpect(SRElectrocardiogramSession.SessionGuidance.guided != .unguided, "!=")
    _ = SRElectrocardiogramSession.SessionGuidance.guided.hashValue
    var hasher3 = Hasher()
    SRElectrocardiogramSession.SessionGuidance.unguided.hash(into: &hasher3)
    _ = hasher3.finalize()

    var flags: SRElectrocardiogramData.Flags = []
    skExpect(flags.isEmpty, "empty")
    skExpect(SRElectrocardiogramData.Flags.signalInvalid.rawValue == 1, "invalid")
    skExpect(SRElectrocardiogramData.Flags.crownTouched.rawValue == 2, "crown")
    flags.insert(.signalInvalid)
    skExpect(flags.contains(.signalInvalid), "contains")
    flags.formUnion(.crownTouched)
    skExpect(flags.union(.signalInvalid).contains(.crownTouched), "union")
    skExpect(flags.intersection(.crownTouched) == .crownTouched, "inter")
    skExpect(flags.symmetricDifference(.crownTouched).contains(.signalInvalid), "sym")
    skExpect(flags.subtracting(.crownTouched) == .signalInvalid, "sub")
    var mut = flags
    mut.subtract(.signalInvalid)
    skExpect(mut.contains(.crownTouched), "subtract")
    var form = SRElectrocardiogramData.Flags.signalInvalid
    form.formIntersection(.signalInvalid)
    form.formSymmetricDifference(.crownTouched)
    let seq = SRElectrocardiogramData.Flags([.signalInvalid])
    skExpect(seq.contains(.signalInvalid), "seq")
    let literal: SRElectrocardiogramData.Flags = [.crownTouched]
    skExpect(literal.contains(.crownTouched), "lit")
    skExpect(SRElectrocardiogramData.Flags().isEmpty, "init")
    skExpect(SRElectrocardiogramData.Flags.signalInvalid != .crownTouched, "!=")
    skExpect(flags.isSuperset(of: .crownTouched), "super")
    skExpect(flags.isSubset(of: [.signalInvalid, .crownTouched]), "subset")
    skExpect(!flags.isDisjoint(with: .signalInvalid), "disjoint")
    skExpect(SRElectrocardiogramData.Flags.signalInvalid.isStrictSubset(of: flags), "strict")
    skExpect(flags.isStrictSuperset(of: .signalInvalid), "strict super")
    _ = flags.remove(.crownTouched)
    _ = flags.update(with: .signalInvalid)
}

func testECGSample() {
    let session = SRElectrocardiogramSession(identifier: "s", sessionGuidance: .guided, state: .active)
    skExpect(session.identifier == "s", "id")
    skExpect(session.sessionGuidance == .guided, "guide")
    skExpect(session.state == .active, "state")
    let datum = SRElectrocardiogramData(
        flags: .signalInvalid,
        value: Measurement(value: 1.2, unit: .volts)
    )
    skExpect(datum.flags.contains(.signalInvalid), "flags")
    skExpect(datum.value.value == 1.2, "mV")
    let sample = SRElectrocardiogramSample(
        data: [datum],
        date: Date(timeIntervalSinceReferenceDate: 5),
        frequency: Measurement(value: 512, unit: .hertz),
        lead: .leftArmMinusRightArm,
        session: session
    )
    skExpect(sample.data.count == 1, "data")
    skExpect(sample.date.timeIntervalSinceReferenceDate == 5, "date")
    skExpect(sample.frequency.value == 512, "freq")
    skExpect(sample.lead == .leftArmMinusRightArm, "lead")
    skExpect(sample.session.identifier == "s", "session")
}
