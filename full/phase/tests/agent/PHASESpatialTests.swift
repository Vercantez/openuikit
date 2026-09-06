@_spi(OpenUIKitHost) import PHASE
import Foundation

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testSpatialPipelineEntries() {
    guard let pipeline = PHASESpatialPipeline(flags: [.directPathTransmission, .lateReverb]) else {
        preconditionFailure("pipeline")
    }
    expect(pipeline.flags.contains(.directPathTransmission), "flags")
    expect(pipeline.entries[.directPathTransmission] != nil, "direct entry")
    expect(pipeline.entries[.lateReverb] != nil, "late entry")
    expect(pipeline.entries[.earlyReflections] == nil, "no early")
    pipeline.entries[.directPathTransmission]!.sendLevel = 0.4
    expect(pipeline.entries[.directPathTransmission]!.sendLevel == 0.4, "send")
    let meta = PHASENumberMetaParameterDefinition(value: 0.4)
    pipeline.entries[.directPathTransmission]!.sendLevelMetaParameterDefinition = meta
    expect(
        pipeline.entries[.directPathTransmission]!.sendLevelMetaParameterDefinition === meta,
        "send meta"
    )
}

func testSpatialPipelineEmptyNil() {
    expect(PHASESpatialPipeline(flags: []) == nil, "empty flags nil")
}

func testSpatialPipelineEntryDefaults() {
    let entry = PHASESpatialPipelineEntry()
    expect(entry.sendLevel == 1, "default send")
    expect(entry.sendLevelMetaParameterDefinition == nil, "no meta")
}

func testCardioidSubband() {
    let band = PHASECardioidDirectivityModelSubbandParameters()
    expect(band.frequency == 0, "freq")
    expect(band.pattern == 0, "pattern")
    expect(band.sharpness == 0, "sharp")
    band.frequency = 1000
    band.pattern = 0.5
    band.sharpness = 0.2
    expect(band.frequency == 1000, "set freq")
    let model = PHASECardioidDirectivityModelParameters(subbandParameters: [band])
    expect(model.subbandParameters.count == 1, "bands")
}

func testConeAngles() {
    let band = PHASEConeDirectivityModelSubbandParameters()
    expect(band.innerAngle == 0 && band.outerAngle == 0, "angles")
    expect(band.outerGain == 0, "gain")
    band.setAngles(innerAngle: 30, outerAngle: 90)
    band.frequency = 250
    band.outerGain = 0.1
    expect(band.innerAngle == 30, "inner")
    expect(band.outerAngle == 90, "outer")
    expect(band.frequency == 250, "freq")
    expect(band.outerGain == 0.1, "gain set")
    let model = PHASEConeDirectivityModelParameters(subbandParameters: [band])
    expect(model.subbandParameters.count == 1, "bands")
}

func testDistanceModels() {
    let fade = PHASEDistanceModelFadeOutParameters(cullDistance: 25)
    expect(fade.cullDistance == 25, "cull")
    let geo = PHASEGeometricSpreadingDistanceModelParameters()
    expect(geo.rolloffFactor == 1, "rolloff")
    geo.rolloffFactor = 2
    geo.fadeOutParameters = fade
    expect(geo.rolloffFactor == 2, "set")
    expect(geo.fadeOutParameters === fade, "fade")
    let env = PHASEEnvelope(
        startPoint: simd_double2(0, 1),
        segments: [PHASEEnvelopeSegment(endPoint: simd_double2(10, 0), curveType: .inverseSquared)]
    )!
    let envelopeModel = PHASEEnvelopeDistanceModelParameters(envelope: env)
    expect(envelopeModel.envelope === env, "envelope")
}

func testSpatialMixerDistanceAttach() {
    let pipeline = PHASESpatialPipeline(flags: .directPathTransmission)!
    let mixer = PHASESpatialMixerDefinition(spatialPipeline: pipeline)
    let geo = PHASEGeometricSpreadingDistanceModelParameters()
    mixer.distanceModelParameters = geo
    expect(mixer.distanceModelParameters === geo, "attached")
    let cardioid = PHASECardioidDirectivityModelParameters(subbandParameters: [])
    mixer.listenerDirectivityModelParameters = cardioid
    mixer.sourceDirectivityModelParameters = cardioid
    expect(mixer.listenerDirectivityModelParameters === cardioid, "listener")
    expect(mixer.sourceDirectivityModelParameters === cardioid, "source")
}
