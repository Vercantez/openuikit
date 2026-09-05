import Foundation
@_spi(OpenUIKitHost) import SensorKit

func testPPGConditionsAndUsage() {
    skExpect(
        SRPhotoplethysmogramOpticalSample.Condition.signalSaturation.rawValue
            == "SRPhotoplethysmogramOpticalSampleConditionSignalSaturation",
        "sat"
    )
    skExpect(
        SRPhotoplethysmogramOpticalSample.Condition.unreliableNoise.rawValue
            == "SRPhotoplethysmogramOpticalSampleConditionUnreliableNoise",
        "noise"
    )
    let custom = SRPhotoplethysmogramOpticalSample.Condition(rawValue: "custom")
    skExpect(custom.rawValue == "custom", "custom")
    skExpect(custom != .signalSaturation, "!=")
    _ = custom.hashValue
    var hasher = Hasher()
    custom.hash(into: &hasher)
    _ = hasher.finalize()

    skExpect(
        SRPhotoplethysmogramSample.Usage.backgroundSystem.rawValue
            == "SRPhotoplethysmogramSampleUsageBackgroundSystem",
        "bg"
    )
    skExpect(
        SRPhotoplethysmogramSample.Usage.deepBreathing.rawValue
            == "SRPhotoplethysmogramSampleUsageDeepBreathing",
        "breath"
    )
    skExpect(
        SRPhotoplethysmogramSample.Usage.foregroundBloodOxygen.rawValue
            == "SRPhotoplethysmogramSampleUsageForegroundBloodOxygen",
        "o2"
    )
    skExpect(
        SRPhotoplethysmogramSample.Usage.foregroundHeartRate.rawValue
            == "SRPhotoplethysmogramSampleUsageForegroundHeartRate",
        "hr"
    )
    let usage = SRPhotoplethysmogramSample.Usage(rawValue: "x")
    skExpect(usage.rawValue == "x", "usage init")
    skExpect(usage != .deepBreathing, "!=")
    _ = usage.hashValue
    var hasher2 = Hasher()
    usage.hash(into: &hasher2)
    _ = hasher2.finalize()
}

func testPPGOpticalNoiseTerms() {
    let terms = SRPhotoplethysmogramOpticalSample.NoiseTerms(
        backgroundNoise: 1,
        backgroundNoiseOffset: 2,
        pinkNoise: 3,
        whiteNoise: 4
    )
    skExpect(terms.backgroundNoise == 1, "bg")
    skExpect(terms.backgroundNoiseOffset == 2, "off")
    skExpect(terms.pinkNoise == 3, "pink")
    skExpect(terms.whiteNoise == 4, "white")

    let optical = SRPhotoplethysmogramOpticalSample(
        activePhotodiodeIndexes: IndexSet(integersIn: 0..<3),
        conditions: [.signalSaturation],
        effectiveWavelength: Measurement(value: 850, unit: .nanometers),
        emitter: 2,
        nanosecondsSinceStart: 100,
        nominalWavelength: Measurement(value: 840, unit: .nanometers),
        samplingFrequency: Measurement(value: 64, unit: .hertz),
        signalIdentifier: 7,
        noiseTerms: terms,
        normalizedReflectance: 0.8
    )
    skExpect(optical.activePhotodiodeIndexes.contains(1), "idx")
    skExpect(optical.conditions == [.signalSaturation], "cond")
    skExpect(optical.effectiveWavelength.value == 850, "eff")
    skExpect(optical.emitter == 2, "em")
    skExpect(optical.nanosecondsSinceStart == 100, "ns")
    skExpect(optical.nominalWavelength.value == 840, "nom")
    skExpect(optical.samplingFrequency.value == 64, "freq")
    skExpect(optical.signalIdentifier == 7, "sig")
    skExpect(optical.noiseTerms?.pinkNoise == 3, "terms")
    skExpect(optical.normalizedReflectance == 0.8, "refl")
}

func testPPGAccelerometerAndSample() {
    let accel = SRPhotoplethysmogramAccelerometerSample(
        nanosecondsSinceStart: 5,
        samplingFrequency: Measurement(value: 50, unit: .hertz),
        x: Measurement(value: 0.1, unit: .metersPerSecondSquared),
        y: Measurement(value: 0.2, unit: .metersPerSecondSquared),
        z: Measurement(value: 0.3, unit: .metersPerSecondSquared)
    )
    skExpect(accel.nanosecondsSinceStart == 5, "ns")
    skExpect(accel.samplingFrequency.value == 50, "freq")
    skExpect(accel.x.value == 0.1, "x")
    skExpect(accel.y.value == 0.2, "y")
    skExpect(accel.z.value == 0.3, "z")

    let sample = SRPhotoplethysmogramSample(
        accelerometerSamples: [accel],
        nanosecondsSinceStart: 9,
        opticalSamples: [],
        startDate: Date(timeIntervalSinceReferenceDate: 3),
        temperature: Measurement(value: 36, unit: .celsius),
        usage: [.foregroundHeartRate]
    )
    skExpect(sample.accelerometerSamples.count == 1, "acc")
    skExpect(sample.nanosecondsSinceStart == 9, "ns")
    skExpect(sample.opticalSamples.isEmpty, "opt")
    skExpect(sample.startDate.timeIntervalSinceReferenceDate == 3, "start")
    skExpect(sample.temperature?.value == 36, "temp")
    skExpect(sample.usage == [.foregroundHeartRate], "usage")
}

func testSleepSession() {
    let session = SRSleepSession(
        duration: 8 * 3600,
        identifier: "sleep",
        startDate: Date(timeIntervalSinceReferenceDate: 100)
    )
    skExpect(session.duration == 8 * 3600, "dur")
    skExpect(session.identifier == "sleep", "id")
    skExpect(session.startDate.timeIntervalSinceReferenceDate == 100, "start")
}
