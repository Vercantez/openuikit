@_spi(OpenUIKitHost) import PHASE
import Foundation

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testAssetRegistryMetaParameter() {
    let engine = PHASEEngine(updateMode: .manual)
    let definition = PHASENumberMetaParameterDefinition(value: 0.5, minimum: 0, maximum: 1)
    let asset = try! engine.assetRegistry.registerGlobalMetaParameter(metaParameterDefinition: definition)
    expect(asset.identifier == definition.identifier, "id")
    expect(engine.assetRegistry.asset(forIdentifier: definition.identifier) === asset, "lookup")
    expect(engine.assetRegistry.globalMetaParameters[definition.identifier] != nil, "stored")
}

func testAssetRegistryDuplicateMetaParameter() {
    let engine = PHASEEngine(updateMode: .manual)
    let definition = PHASENumberMetaParameterDefinition(value: 1, identifier: "dup")
    _ = try! engine.assetRegistry.registerGlobalMetaParameter(metaParameterDefinition: definition)
    do {
        _ = try engine.assetRegistry.registerGlobalMetaParameter(metaParameterDefinition: definition)
        preconditionFailure("duplicate")
    } catch let error as PHASEAssetError {
        expect(error.code == .alreadyExists, "alreadyExists")
    } catch {
        preconditionFailure("unexpected")
    }
}

func testAssetRegistrySoundEventAsset() {
    let engine = PHASEEngine(updateMode: .manual)
    let pipeline = PHASESpatialPipeline(flags: .directPathTransmission)!
    let mixer = PHASESpatialMixerDefinition(spatialPipeline: pipeline)
    let sampler = PHASESamplerNodeDefinition(soundAssetIdentifier: "tone", mixerDefinition: mixer)
    let asset = try! engine.assetRegistry.registerSoundEventAsset(rootNode: sampler, identifier: "event")
    expect(asset.identifier == "event", "id")
    expect(engine.assetRegistry.asset(forIdentifier: "event") is PHASESoundEventNodeAsset, "type")
}

func testAssetRegistryDuplicateSoundEvent() {
    let engine = PHASEEngine(updateMode: .manual)
    let pipeline = PHASESpatialPipeline(flags: .directPathTransmission)!
    let mixer = PHASESpatialMixerDefinition(spatialPipeline: pipeline)
    let sampler = PHASESamplerNodeDefinition(soundAssetIdentifier: "tone", mixerDefinition: mixer)
    _ = try! engine.assetRegistry.registerSoundEventAsset(rootNode: sampler, identifier: "event")
    do {
        _ = try engine.assetRegistry.registerSoundEventAsset(rootNode: sampler, identifier: "event")
        preconditionFailure("duplicate")
    } catch let error as PHASEAssetError {
        expect(error.code == .alreadyExists, "alreadyExists")
    } catch {
        preconditionFailure("unexpected")
    }
}

func testAssetRegistryHostUnregister() {
    let engine = PHASEEngine(updateMode: .manual)
    let pipeline = PHASESpatialPipeline(flags: .lateReverb)!
    let mixer = PHASESpatialMixerDefinition(spatialPipeline: pipeline)
    let sampler = PHASESamplerNodeDefinition(soundAssetIdentifier: "tone", mixerDefinition: mixer)
    _ = try! engine.assetRegistry.registerSoundEventAsset(rootNode: sampler, identifier: "gone")
    expect(engine.assetRegistry.hostUnregisterAsset(identifier: "gone"), "removed")
    expect(engine.assetRegistry.asset(forIdentifier: "gone") == nil, "missing")
    expect(!engine.assetRegistry.hostUnregisterAsset(identifier: "gone"), "second")
}

func testSoundAssetTypeOnHost() {
    expect(PHASEAsset.AssetType.resident != .streamed, "types")
}

func testStringGlobalMetaParameter() {
    let engine = PHASEEngine(updateMode: .manual)
    let definition = PHASEStringMetaParameterDefinition(value: "hello", identifier: "tag")
    _ = try! engine.assetRegistry.registerGlobalMetaParameter(metaParameterDefinition: definition)
    let stored = engine.assetRegistry.globalMetaParameters["tag"]
    expect(stored is PHASEStringMetaParameter, "string param")
    expect(stored?.value as? String == "hello", "value")
}
