import Foundation

#if canImport(AVFAudio)
import AVFAudio
#endif

public final class PHASESoundEvent: NSObject {
    public enum RenderingState: Int, Hashable, Sendable {
        case stopped = 0
        case started = 1
        case paused = 2
    }

    public enum PrepareHandlerReason: Int, Hashable, Sendable {
        case failure = 0
        case prepared = 1
        case terminated = 2
    }

    public enum StartHandlerReason: Int, Hashable, Sendable {
        case failure = 0
        case finishedPlaying = 1
        case terminated = 2
    }

    public enum SeekHandlerReason: Int, Hashable, Sendable {
        case failure = 0
        case failureSeekAlreadyInProgress = 1
        case seekSuccessful = 2
    }

    public enum PrepareState: Int, Hashable, Sendable {
        case prepareNotStarted = 0
        case prepareInProgress = 1
        case prepared = 2
    }

    public private(set) var renderingState: RenderingState = .stopped
    public private(set) var prepareState: PrepareState = .prepareNotStarted
    public private(set) var metaParameters: [String: PHASEMetaParameter] = [:]
    public private(set) var mixers: [String: PHASEMixer] = [:]
    public private(set) var pushStreamNodes: [String: PHASEPushStreamNode] = [:]
    public private(set) var pullStreamNodes: [String: PHASEPullStreamNode] = [:]
    public private(set) var isIndefinite = false
    public let assetIdentifier: String
    weak var engine: PHASEEngine?
    private var invalidated = false

    public init(engine: PHASEEngine, assetIdentifier: String) throws {
        guard engine.assetRegistry.asset(forIdentifier: assetIdentifier) != nil else {
            throw PHASESoundEventError(
                .notFound,
                userInfo: phaseLinuxReason("sound-event asset \(assetIdentifier) is not registered")
            )
        }
        self.engine = engine
        self.assetIdentifier = assetIdentifier
        super.init()
        engine.registerSoundEvent(self)
        if let root = engine.assetRegistry.registeredRoots[assetIdentifier] {
            isIndefinite = PHASESoundEvent.subtreeLooksIndefinite(root)
        }
    }

    public convenience init(
        engine: PHASEEngine,
        assetIdentifier: String,
        mixerParameters: PHASEMixerParameters
    ) throws {
        try self.init(engine: engine, assetIdentifier: assetIdentifier)
        _ = mixerParameters
    }

    public func prepare(completion handler: ((PrepareHandlerReason) -> Void)? = nil) {
        prepareState = .prepareInProgress
        prepareState = .prepareNotStarted
        handler?(.failure)
    }

    public func start(completion handler: ((StartHandlerReason) -> Void)? = nil) {
        handler?(.failure)
    }

    public func pause() {
        if renderingState == .started {
            renderingState = .paused
        }
        _ = invalidated
    }

    public func resume() {
        if renderingState == .paused {
            renderingState = .started
        }
    }

    public func stopAndInvalidate() {
        invalidated = true
        renderingState = .stopped
        prepareState = .prepareNotStarted
        engine?.unregisterSoundEvent(self)
    }

    public func seek(to time: Double) async -> SeekHandlerReason {
        _ = time
        return .failure
    }

#if canImport(AVFAudio)
    public func resume(at time: AVAudioTime?) {
        _ = time
        resume()
    }

    public func seek(to time: Double, resumeAt engineTime: AVAudioTime) async -> SeekHandlerReason {
        _ = time
        _ = engineTime
        return .failure
    }

    public func start(at when: AVAudioTime?) async -> StartHandlerReason {
        _ = when
        return .failure
    }
#endif

    func hostStop() {
        renderingState = .stopped
    }

    @_spi(OpenUIKitHost)
    public func hostSeekFailure(to time: Double) -> SeekHandlerReason {
        _ = time
        return .failure
    }

    private static func subtreeLooksIndefinite(_ node: PHASESoundEventNodeDefinition) -> Bool {
        if let sampler = node as? PHASESamplerNodeDefinition, sampler.playbackMode == .looping {
            return true
        }
        return node.children.contains { subtreeLooksIndefinite($0) }
    }
}
