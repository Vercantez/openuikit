@_spi(OpenUIKitHost) import PHASE
import Foundation

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testNumberMetaParameterDefinitionClamp() {
    let def = PHASENumberMetaParameterDefinition(value: 5, minimum: 0, maximum: 1)
    expect(def.minimum == 0, "min")
    expect(def.maximum == 1, "max")
    expect((def.value as? NSNumber)?.doubleValue == 1, "clamped")
    let ident = PHASENumberMetaParameterDefinition(value: 0.2, identifier: "n")
    expect(ident.identifier == "n", "id")
    let simple = PHASENumberMetaParameterDefinition(value: 3)
    expect((simple.value as? NSNumber)?.doubleValue == 3, "simple")
    let ranged = PHASENumberMetaParameterDefinition(value: 0.4, minimum: 0, maximum: 1, identifier: "r")
    expect(ranged.identifier == "r", "ranged id")
}

func testStringMetaParameterDefinition() {
    let def = PHASEStringMetaParameterDefinition(value: "on")
    expect(def.value as? String == "on", "value")
    let named = PHASEStringMetaParameterDefinition(value: "off", identifier: "sw")
    expect(named.identifier == "sw", "id")
}

func testMappedMetaParameterDefinition() {
    let input = PHASENumberMetaParameterDefinition(value: 0, minimum: 0, maximum: 1)
    let env = PHASEEnvelope(
        startPoint: simd_double2(0, 0),
        segments: [PHASEEnvelopeSegment(endPoint: simd_double2(1, 2), curveType: .linear)]
    )!
    let mapped = PHASEMappedMetaParameterDefinition(
        inputMetaParameterDefinition: input,
        envelope: env
    )
    expect(mapped.envelope === env, "envelope")
    expect(mapped.inputMetaParameterDefinition === input, "input")
    let named = PHASEMappedMetaParameterDefinition(
        inputMetaParameterDefinition: input,
        envelope: env,
        identifier: "map"
    )
    expect(named.identifier == "map", "id")
}

func testNumberMetaParameterFade() {
    let param = PHASENumberMetaParameter.hostMake(identifier: "g", value: 0.5, minimum: 0, maximum: 1)
    expect(param.identifier == "g", "id")
    expect(param.minimum == 0 && param.maximum == 1, "range")
    param.fade(value: 2, duration: 0.1)
    expect((param.value as? NSNumber)?.doubleValue == 1, "clamped fade")
    param.fade(value: -1, duration: 0)
    expect((param.value as? NSNumber)?.doubleValue == 0, "floor")
}

func testMixerDefinitionGain() {
    let pipeline = PHASESpatialPipeline(flags: [.directPathTransmission, .earlyReflections])!
    let mixer = PHASESpatialMixerDefinition(spatialPipeline: pipeline)
    expect(mixer.gain == 1, "default gain")
    mixer.gain = 0.5
    expect(mixer.gain == 0.5, "set")
    expect(mixer.spatialPipeline === pipeline, "pipeline")
    expect(mixer.distanceModelParameters == nil, "distance")
    expect(mixer.listenerDirectivityModelParameters == nil, "listener dir")
    expect(mixer.sourceDirectivityModelParameters == nil, "source dir")
    let gain = PHASENumberMetaParameterDefinition(value: 1)
    mixer.gainMetaParameterDefinition = gain
    expect(mixer.gainMetaParameterDefinition === gain, "gain meta")
}

func testAmbientChannelHostMixers() {
    let ambient = PHASEAmbientMixerDefinition(hostIdentifier: "amb")
    expect(ambient.identifier == "amb", "amb id")
    let channel = PHASEChannelMixerDefinition(hostIdentifier: "ch")
    expect(channel.identifier == "ch", "ch id")
}

func testMixerParametersBindings() {
    let engine = PHASEEngine(updateMode: .manual)
    let params = PHASEMixerParameters()
    let listener = PHASEListener(engine: engine)
    let source = PHASESource(engine: engine)
    params.addSpatialMixerParameters(identifier: "s", source: source, listener: listener)
    params.addAmbientMixerParameters(identifier: "a", listener: listener)
}
