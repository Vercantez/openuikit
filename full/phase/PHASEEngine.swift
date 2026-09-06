import Foundation

#if canImport(AVFAudio)
import AVFAudio
#endif

public final class PHASEEngine: NSObject {
    public enum UpdateMode: Int, Hashable, Sendable {
        case automatic = 0
        case manual = 1
    }

    public let updateMode: UpdateMode
    public private(set) var renderingState: PHASESoundEvent.RenderingState = .stopped
    public var outputSpatializationMode: PHASESpatializationMode = .automatic
    public var defaultReverbPreset: PHASEReverbPreset = .mediumRoom
    public var unitsPerSecond: Double = 1
    public var unitsPerMeter: Double = 1
    public let rootObject: PHASEObject
    public var defaultMedium: PHASEMedium
    public let assetRegistry: PHASEAssetRegistry
    public private(set) var soundEvents: [PHASESoundEvent] = []
    public private(set) var groups: [String: PHASEGroup] = [:]
    public private(set) var duckers: [PHASEDucker] = []
    public internal(set) var activeGroupPreset: PHASEGroupPreset?

#if canImport(AVFAudio)
    public var lastRenderTime: AVAudioTime? { nil }
#endif

    public init(updateMode: UpdateMode) {
        self.updateMode = updateMode
        let registry = PHASEAssetRegistry()
        self.assetRegistry = registry
        let root = PHASEObject(unbound: ())
        self.rootObject = root
        let medium = PHASEMedium(unbound: ())
        self.defaultMedium = medium
        super.init()
        root.engine = self
        medium.engine = self
        medium.presetStorage = .air
        registry.engine = self
    }

    public func start() throws {
        throw PHASEError(
            .initializeFailed,
            userInfo: phaseLinuxReason("engine start requires the Apple PHASE renderer")
        )
    }

    public func pause() {
        if renderingState == .started {
            renderingState = .paused
        }
    }

    public func stop() {
        renderingState = .stopped
        for event in soundEvents {
            event.hostStop()
        }
    }

    public func update() {
        // Manual-mode tick. No audio is rendered on Linux.
    }

    func registerGroup(_ group: PHASEGroup) {
        groups[group.identifier] = group
    }

    func unregisterGroup(_ group: PHASEGroup) {
        if groups[group.identifier] === group {
            groups.removeValue(forKey: group.identifier)
        }
    }

    func registerDucker(_ ducker: PHASEDucker) {
        if !duckers.contains(where: { $0 === ducker }) {
            duckers.append(ducker)
        }
    }

    func registerSoundEvent(_ event: PHASESoundEvent) {
        if !soundEvents.contains(where: { $0 === event }) {
            soundEvents.append(event)
        }
    }

    func unregisterSoundEvent(_ event: PHASESoundEvent) {
        soundEvents.removeAll { $0 === event }
    }
}

public final class PHASEMedium: NSObject {
    public enum Preset: Int, Hashable, Sendable {
        case air = 1_835_286_898
    }

    weak var engine: PHASEEngine?
    var presetStorage: Preset = .air
    public var preset: Preset { presetStorage }

    public init(engine: PHASEEngine, preset: Preset) {
        self.engine = engine
        self.presetStorage = preset
        super.init()
    }

    init(unbound: Void) {
        super.init()
    }
}
