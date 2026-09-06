@_spi(OpenUIKitHost) import PHASE
import Foundation

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testEngineInitManual() {
    let engine = PHASEEngine(updateMode: .manual)
    expect(engine.renderingState == .stopped, "stopped")
    expect(engine.outputSpatializationMode == .automatic, "spatial default")
    expect(engine.unitsPerMeter == 1, "unitsPerMeter")
    expect(engine.unitsPerSecond == 1, "unitsPerSecond")
    expect(engine.defaultReverbPreset == .mediumRoom, "reverb")
    expect(engine.soundEvents.isEmpty, "no events")
    expect(engine.groups.isEmpty, "no groups")
    expect(engine.duckers.isEmpty, "no duckers")
    expect(engine.activeGroupPreset == nil, "no preset")
}

func testEngineStartFailsClosed() {
    let engine = PHASEEngine(updateMode: .automatic)
    do {
        try engine.start()
        preconditionFailure("start must not succeed")
    } catch let error as PHASEError {
        expect(error.code == .initializeFailed, "initializeFailed")
    } catch {
        preconditionFailure("unexpected \(error)")
    }
    expect(engine.renderingState == .stopped, "still stopped")
}

func testEnginePauseStopUpdate() {
    let engine = PHASEEngine(updateMode: .manual)
    engine.pause()
    expect(engine.renderingState == .stopped, "pause noop when stopped")
    engine.stop()
    expect(engine.renderingState == .stopped, "stop")
    engine.update()
    engine.outputSpatializationMode = .alwaysUseBinaural
    expect(engine.outputSpatializationMode == .alwaysUseBinaural, "mode set")
    engine.unitsPerMeter = 2
    engine.unitsPerSecond = 3
    expect(engine.unitsPerMeter == 2 && engine.unitsPerSecond == 3, "units")
    engine.defaultReverbPreset = .cathedral
    expect(engine.defaultReverbPreset == .cathedral, "reverb set")
}

func testEngineRootAndMedium() {
    let engine = PHASEEngine(updateMode: .manual)
    expect(engine.rootObject.parent == nil, "root has no parent")
    expect(engine.rootObject.children.isEmpty, "root empty")
    let medium = PHASEMedium(engine: engine, preset: .air)
    engine.defaultMedium = medium
    expect(engine.defaultMedium.preset == .air, "air")
    _ = engine.assetRegistry
}

func testEngineAssetRegistryIdentity() {
    let engine = PHASEEngine(updateMode: .manual)
    expect(engine.assetRegistry.globalMetaParameters.isEmpty, "empty globals")
    expect(engine.assetRegistry.asset(forIdentifier: "missing") == nil, "missing")
}
