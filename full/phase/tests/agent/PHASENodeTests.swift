@_spi(OpenUIKitHost) import PHASE
import Foundation

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testSamplerNodeDefaults() {
    let pipeline = PHASESpatialPipeline(flags: .directPathTransmission)!
    let mixer = PHASESpatialMixerDefinition(spatialPipeline: pipeline)
    let sampler = PHASESamplerNodeDefinition(soundAssetIdentifier: "hit", mixerDefinition: mixer)
    expect(sampler.assetIdentifier == "hit", "asset")
    expect(sampler.cullOption == .terminate, "cull")
    expect(sampler.playbackMode == .oneShot, "playback")
    expect(sampler.mixerDefinition === mixer, "mixer")
    expect(sampler.rate == 1, "rate")
    expect(sampler.calibrationMode == .none, "calib")
    expect(sampler.level == 0, "level")
    sampler.setCalibrationMode(calibrationMode: .relativeSpl, level: -6)
    expect(sampler.calibrationMode == .relativeSpl, "set mode")
    expect(sampler.level == -6, "set level")
    sampler.rate = 1.25
    expect(sampler.rate == 1.25, "rate set")
    sampler.cullOption = .doNotCull
    sampler.playbackMode = .looping
    expect(sampler.cullOption == .doNotCull, "cull set")
    expect(sampler.playbackMode == .looping, "loop")
}

func testSamplerNodeIdentifier() {
    let pipeline = PHASESpatialPipeline(flags: .earlyReflections)!
    let mixer = PHASESpatialMixerDefinition(spatialPipeline: pipeline, identifier: "mix")
    let sampler = PHASESamplerNodeDefinition(
        soundAssetIdentifier: "hit",
        mixerDefinition: mixer,
        identifier: "sam"
    )
    expect(sampler.identifier == "sam", "id")
    expect(mixer.identifier == "mix", "mixer id")
}

func testContainerSubtree() {
    let container = PHASEContainerNodeDefinition()
    let named = PHASEContainerNodeDefinition(identifier: "root")
    expect(named.identifier == "root", "named")
    let created = PHASEContainerNodeDefinition.new()
    expect(created.children.isEmpty, "new")
    named.addSubtree(container)
    expect(named.children.count == 1, "child")
}

func testBlendRanges() {
    let param = PHASENumberMetaParameterDefinition(value: 0, minimum: 0, maximum: 1)
    let blend = PHASEBlendNodeDefinition(blendMetaParameterDefinition: param)
    expect(blend.blendParameterDefinition === param, "param")
    expect(blend.spatialMixerDefinitionForDistance == nil, "not distance")
    let leaf = PHASEContainerNodeDefinition(identifier: "leaf")
    blend.addRangeForInputValuesBelow(value: 0.2, fullGainAtValue: 0.1, fadeCurveType: .linear, subtree: leaf)
    blend.addRangeForInputValuesAbove(value: 0.8, fullGainAtValue: 0.9, fadeCurveType: .sine, subtree: leaf)
    blend.addRangeForInputValuesBetween(
        lowValue: 0.2,
        highValue: 0.8,
        fullGainAtLowValue: 0.3,
        fullGainAtHighValue: 0.7,
        lowFadeCurveType: .linear,
        highFadeCurveType: .squared,
        subtree: leaf
    )
    let env = PHASEEnvelope(
        startPoint: simd_double2(0, 0),
        segments: [PHASEEnvelopeSegment(endPoint: simd_double2(1, 1), curveType: .linear)]
    )!
    blend.addRange(envelope: env, subtree: leaf)
    expect(blend.children.count == 4, "ranges")
}

func testBlendDistanceInit() {
    let pipeline = PHASESpatialPipeline(flags: .lateReverb)!
    let mixer = PHASESpatialMixerDefinition(spatialPipeline: pipeline)
    let blend = PHASEBlendNodeDefinition(spatialMixerDefinition: mixer)
    expect(blend.spatialMixerDefinitionForDistance === mixer, "distance mixer")
    let named = PHASEBlendNodeDefinition(spatialMixerDefinition: mixer, identifier: "dblend")
    expect(named.identifier == "dblend", "id")
    let alias = PHASEBlendNodeDefinition(distanceBlendWithSpatialMixerDefinition: mixer)
    expect(alias.spatialMixerDefinitionForDistance === mixer, "alias")
    let aliasNamed = PHASEBlendNodeDefinition(
        distanceBlendWithSpatialMixerDefinition: mixer,
        identifier: "alias"
    )
    expect(aliasNamed.identifier == "alias", "alias id")
    let withId = PHASEBlendNodeDefinition(blendMetaParameterDefinition: PHASENumberMetaParameterDefinition(value: 0), identifier: "b")
    expect(withId.identifier == "b", "blend id")
}

func testSwitchNode() {
    let def = PHASEStringMetaParameterDefinition(value: "a")
    let node = PHASESwitchNodeDefinition(switchMetaParameterDefinition: def)
    expect(node.switchMetaParameterDefinition === def, "def")
    let named = PHASESwitchNodeDefinition(switchMetaParameterDefinition: def, identifier: "sw")
    expect(named.identifier == "sw", "id")
    named.addSubtree(PHASEContainerNodeDefinition(identifier: "c"), switchValue: "a")
    expect(named.children.count == 1, "child")
}

func testRandomNodeWeights() {
    let node = PHASERandomNodeDefinition()
    expect(node.uniqueSelectionQueueLength == 0, "queue")
    node.uniqueSelectionQueueLength = 3
    expect(node.uniqueSelectionQueueLength == 3, "set")
    let named = PHASERandomNodeDefinition(identifier: "rnd")
    expect(named.identifier == "rnd", "id")
    named.addSubtree(PHASEContainerNodeDefinition(), weight: NSNumber(value: 2))
    expect(named.children.count == 1, "weighted")
}

func testGeneratorMetaParameters() {
    let pipeline = PHASESpatialPipeline(flags: .directPathTransmission)!
    let mixer = PHASESpatialMixerDefinition(spatialPipeline: pipeline)
    let sampler = PHASESamplerNodeDefinition(soundAssetIdentifier: "t", mixerDefinition: mixer)
    let gain = PHASENumberMetaParameterDefinition(value: 1)
    let rate = PHASENumberMetaParameterDefinition(value: 1)
    sampler.gainMetaParameterDefinition = gain
    sampler.rateMetaParameterDefinition = rate
    expect(sampler.gainMetaParameterDefinition === gain, "gain")
    expect(sampler.rateMetaParameterDefinition === rate, "rate")
    let group = PHASEGroup(identifier: "g")
    sampler.group = group
    expect(sampler.group === group, "group")
}

func testPushPullHostNodes() {
    let mixer = PHASEMixer.hostMake(identifier: "m", gain: 0.7)
    expect(mixer.identifier == "m", "mixer id")
    expect(mixer.gain == 0.7, "gain")
    expect(mixer.gainMetaParameter == nil, "no meta")
    let stream = PHASEStreamNode.hostMake(mixer: mixer)
    expect(stream.mixer === mixer, "stream mixer")
    expect(stream.gainMetaParameter == nil, "gain meta")
    expect(stream.rateMetaParameter == nil, "rate meta")
    let push = PHASEPushStreamNode.hostMake(mixer: mixer)
    expect(push.mixer === mixer, "push mixer")
    let pull = PHASEPullStreamNode.hostMake(mixer: mixer)
    expect(pull.mixer === mixer, "pull mixer")
}

func testPushPullDefinitionsHost() {
    let pipeline = PHASESpatialPipeline(flags: .directPathTransmission)!
    let mixer = PHASESpatialMixerDefinition(spatialPipeline: pipeline)
    let push = PHASEPushStreamNodeDefinition(mixerDefinition: mixer, hostIdentifier: "push")
    expect(push.identifier == "push", "push id")
    expect(push.normalize == false, "push normalize")
    push.normalize = true
    expect(push.normalize, "push set")
    let pull = PHASEPullStreamNodeDefinition(mixerDefinition: mixer, hostIdentifier: "pull")
    expect(pull.identifier == "pull", "pull id")
    pull.normalize = true
    expect(pull.normalize, "pull set")
}
