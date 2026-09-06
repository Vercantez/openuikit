@_spi(OpenUIKitHost) import PHASE
import Foundation

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testSoundEventMissingAsset() {
    let engine = PHASEEngine(updateMode: .manual)
    do {
        _ = try PHASESoundEvent(engine: engine, assetIdentifier: "missing")
        preconditionFailure("missing")
    } catch let error as PHASESoundEventError {
        expect(error.code == .notFound, "notFound")
    } catch {
        preconditionFailure("unexpected")
    }
}

func testSoundEventPrepareStartFailClosed() {
    let engine = PHASEEngine(updateMode: .manual)
    let pipeline = PHASESpatialPipeline(flags: .directPathTransmission)!
    let mixer = PHASESpatialMixerDefinition(spatialPipeline: pipeline)
    let sampler = PHASESamplerNodeDefinition(soundAssetIdentifier: "tone", mixerDefinition: mixer)
    _ = try! engine.assetRegistry.registerSoundEventAsset(rootNode: sampler, identifier: "evt")
    let event = try! PHASESoundEvent(engine: engine, assetIdentifier: "evt")
    expect(engine.soundEvents.contains(where: { $0 === event }), "registered")
    expect(event.renderingState == .stopped, "stopped")
    expect(event.prepareState == .prepareNotStarted, "not prepared")
    expect(event.metaParameters.isEmpty, "meta")
    expect(event.mixers.isEmpty, "mixers")
    expect(event.pushStreamNodes.isEmpty, "push")
    expect(event.pullStreamNodes.isEmpty, "pull")
    var prepare: PHASESoundEvent.PrepareHandlerReason?
    event.prepare { prepare = $0 }
    expect(prepare == .failure, "prepare failure")
    expect(event.prepareState == .prepareNotStarted, "prepare remains unstarted")
    var start: PHASESoundEvent.StartHandlerReason?
    event.start { start = $0 }
    expect(start == .failure, "start failure")
    expect(event.renderingState == .stopped, "still stopped")
}

func testSoundEventPauseResumeStop() {
    let engine = PHASEEngine(updateMode: .manual)
    let pipeline = PHASESpatialPipeline(flags: .earlyReflections)!
    let mixer = PHASESpatialMixerDefinition(spatialPipeline: pipeline)
    let sampler = PHASESamplerNodeDefinition(soundAssetIdentifier: "tone", mixerDefinition: mixer)
    _ = try! engine.assetRegistry.registerSoundEventAsset(rootNode: sampler, identifier: "evt2")
    let event = try! PHASESoundEvent(engine: engine, assetIdentifier: "evt2")
    event.pause()
    expect(event.renderingState == .stopped, "pause noop")
    event.resume()
    expect(event.renderingState == .stopped, "resume noop")
    event.stopAndInvalidate()
    expect(event.renderingState == .stopped, "invalidated")
    expect(!engine.soundEvents.contains(where: { $0 === event }), "unregistered")
}

func testSoundEventMixerParametersInit() {
    let engine = PHASEEngine(updateMode: .manual)
    let pipeline = PHASESpatialPipeline(flags: .lateReverb)!
    let mixerDef = PHASESpatialMixerDefinition(spatialPipeline: pipeline)
    let sampler = PHASESamplerNodeDefinition(soundAssetIdentifier: "tone", mixerDefinition: mixerDef)
    _ = try! engine.assetRegistry.registerSoundEventAsset(rootNode: sampler, identifier: "evt3")
    let params = PHASEMixerParameters()
    let listener = PHASEListener(engine: engine)
    let source = PHASESource(engine: engine)
    params.addSpatialMixerParameters(identifier: mixerDef.identifier, source: source, listener: listener)
    params.addAmbientMixerParameters(identifier: "amb", listener: listener)
    let event = try! PHASESoundEvent(
        engine: engine,
        assetIdentifier: "evt3",
        mixerParameters: params
    )
    expect(event.assetIdentifier == "evt3", "id")
}

func testSoundEventIndefiniteLoop() {
    let engine = PHASEEngine(updateMode: .manual)
    let pipeline = PHASESpatialPipeline(flags: .directPathTransmission)!
    let mixer = PHASESpatialMixerDefinition(spatialPipeline: pipeline)
    let sampler = PHASESamplerNodeDefinition(soundAssetIdentifier: "loop", mixerDefinition: mixer)
    sampler.playbackMode = .looping
    _ = try! engine.assetRegistry.registerSoundEventAsset(rootNode: sampler, identifier: "loop")
    let event = try! PHASESoundEvent(engine: engine, assetIdentifier: "loop")
    expect(event.isIndefinite, "looping is indefinite")
}

func testSoundEventHostSeekFailure() {
    let engine = PHASEEngine(updateMode: .manual)
    let pipeline = PHASESpatialPipeline(flags: .directPathTransmission)!
    let mixer = PHASESpatialMixerDefinition(spatialPipeline: pipeline)
    let sampler = PHASESamplerNodeDefinition(soundAssetIdentifier: "tone", mixerDefinition: mixer)
    _ = try! engine.assetRegistry.registerSoundEventAsset(rootNode: sampler, identifier: "seek")
    let event = try! PHASESoundEvent(engine: engine, assetIdentifier: "seek")
    expect(event.hostSeekFailure(to: 0.5) == .failure, "seek fail-closed")
}
