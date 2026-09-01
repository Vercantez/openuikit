import Foundation

public protocol AVAudioStereoMixing: NSObjectProtocol {
    var pan: Float { get set }
}

public protocol AVAudio3DMixing: NSObjectProtocol {
    var renderingAlgorithm: AVAudio3DMixingRenderingAlgorithm { get set }
    var sourceMode: AVAudio3DMixingSourceMode { get set }
    var pointSourceInHeadMode: AVAudio3DMixingPointSourceInHeadMode { get set }
    var rate: Float { get set }
    var reverbBlend: Float { get set }
    var obstruction: Float { get set }
    var occlusion: Float { get set }
    var position: AVAudio3DPoint { get set }
}

public protocol AVAudioMixing: AVAudio3DMixing, AVAudioStereoMixing {
    var volume: Float { get set }
    func destination(forMixer mixer: AVAudioNode, bus: AVAudioNodeBus) -> AVAudioMixingDestination?
}

extension AVAudioMixing {
    public func destination(forMixer mixer: AVAudioNode, bus: AVAudioNodeBus) -> AVAudioMixingDestination? {
        _ = mixer
        _ = bus
        return nil
    }
}

open class AVAudioNode: NSObject, @unchecked Sendable {
    public internal(set) weak var engine: AVAudioEngine?
    public var numberOfInputs: Int { 1 }
    public var numberOfOutputs: Int { 1 }
    public var latency: TimeInterval { 0 }
    public var outputPresentationLatency: TimeInterval { 0 }
    public var lastRenderTime: AVAudioTime?
    public var auAudioUnit: AUAudioUnit { AUAudioUnit() }
    var storedVolume: Float = 1
    var storedPan: Float = 0
    var storedFormat: AVAudioFormat =
        AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
    private var taps: [AVAudioNodeBus: AVAudioNodeTapBlock] = [:]

    public func reset() {
        lastRenderTime = nil
    }

    public func inputFormat(forBus bus: AVAudioNodeBus) -> AVAudioFormat {
        _ = bus
        return storedFormat
    }

    public func outputFormat(forBus bus: AVAudioNodeBus) -> AVAudioFormat {
        _ = bus
        return storedFormat
    }

    public func name(forInputBus bus: AVAudioNodeBus) -> String? {
        "input-\(bus)"
    }

    public func name(forOutputBus bus: AVAudioNodeBus) -> String? {
        "output-\(bus)"
    }

    public func installTap(
        onBus bus: AVAudioNodeBus,
        bufferSize: AVAudioFrameCount,
        format: AVAudioFormat?,
        block tapBlock: @escaping AVAudioNodeTapBlock
    ) {
        _ = bufferSize
        _ = format
        taps[bus] = tapBlock
    }

    public func removeTap(onBus bus: AVAudioNodeBus) {
        taps[bus] = nil
    }
}

public final class AVAudioMixingDestination: NSObject, @unchecked Sendable {
    public let connectionPoint: AVAudioConnectionPoint
    public init(connectionPoint: AVAudioConnectionPoint) {
        self.connectionPoint = connectionPoint
        super.init()
    }
}

public final class AVAudioConnectionPoint: NSObject, @unchecked Sendable {
    public private(set) weak var node: AVAudioNode?
    public let bus: AVAudioNodeBus
    public init(node: AVAudioNode, bus: AVAudioNodeBus) {
        self.node = node
        self.bus = bus
        super.init()
    }
}

open class AVAudioIONode: AVAudioNode, @unchecked Sendable {
    public var audioUnit: AudioUnit? { nil }
    public var presentationLatency: TimeInterval { 0 }
    public private(set) var isVoiceProcessingEnabled = false

    public func setVoiceProcessingEnabled(_ enabled: Bool) throws {
        guard !enabled else { throw AVAudioError.notSupported }
        isVoiceProcessingEnabled = false
    }
}

public final class AVAudioInputNode: AVAudioIONode, AVAudioMixing, @unchecked Sendable {
    public var volume: Float {
        get { storedVolume }
        set { storedVolume = newValue }
    }
    public var pan: Float {
        get { storedPan }
        set { storedPan = min(max(newValue, -1), 1) }
    }
    public var renderingAlgorithm: AVAudio3DMixingRenderingAlgorithm = .auto
    public var sourceMode: AVAudio3DMixingSourceMode = .spatializeIfMono
    public var pointSourceInHeadMode: AVAudio3DMixingPointSourceInHeadMode = .mono
    public var rate: Float = 1
    public var reverbBlend: Float = 0
    public var obstruction: Float = 0
    public var occlusion: Float = 0
    public var position: AVAudio3DPoint = AVAudio3DPoint()
    public var isVoiceProcessingBypassed = false
    public var isVoiceProcessingAGCEnabled = false
    public var isVoiceProcessingInputMuted = false
    public var voiceProcessingOtherAudioDuckingConfiguration =
        AVAudioVoiceProcessingOtherAudioDuckingConfiguration()
    override public var numberOfInputs: Int { 0 }

    public func setManualRenderingInputPCMFormat(
        _ format: AVAudioFormat,
        inputBlock block: @escaping AVAudioIONodeInputBlock
    ) -> Bool {
        _ = block
        storedFormat = format
        return true
    }

    public func setMutedSpeechActivityEventListener(
        _ listenerBlock: ((AVAudioVoiceProcessingSpeechActivityEvent) -> Void)?
    ) -> Bool {
        _ = listenerBlock
        return false
    }
}

public final class AVAudioOutputNode: AVAudioIONode, @unchecked Sendable {
    override public var numberOfOutputs: Int { 0 }
}

public final class AVAudioMixerNode: AVAudioNode, AVAudioMixing, @unchecked Sendable {
    public var outputVolume: Float = 1
    public var volume: Float {
        get { storedVolume }
        set { storedVolume = newValue }
    }
    public var pan: Float {
        get { storedPan }
        set { storedPan = min(max(newValue, -1), 1) }
    }
    public var renderingAlgorithm: AVAudio3DMixingRenderingAlgorithm = .auto
    public var sourceMode: AVAudio3DMixingSourceMode = .spatializeIfMono
    public var pointSourceInHeadMode: AVAudio3DMixingPointSourceInHeadMode = .mono
    public var rate: Float = 1
    public var reverbBlend: Float = 0
    public var obstruction: Float = 0
    public var occlusion: Float = 0
    public var position: AVAudio3DPoint = AVAudio3DPoint()
    public var nextAvailableInputBus: AVAudioNodeBus = 0
    override public var numberOfInputs: Int { 8 }

    public override init() {
        super.init()
    }
}

public final class AVAudioPlayerNode: AVAudioNode, AVAudioMixing, @unchecked Sendable {
    public private(set) var isPlaying = false
    public var volume: Float {
        get { storedVolume }
        set { storedVolume = newValue }
    }
    public var pan: Float {
        get { storedPan }
        set { storedPan = min(max(newValue, -1), 1) }
    }
    public var renderingAlgorithm: AVAudio3DMixingRenderingAlgorithm = .auto
    public var sourceMode: AVAudio3DMixingSourceMode = .spatializeIfMono
    public var pointSourceInHeadMode: AVAudio3DMixingPointSourceInHeadMode = .mono
    public var rate: Float = 1
    public var reverbBlend: Float = 0
    public var obstruction: Float = 0
    public var occlusion: Float = 0
    public var position: AVAudio3DPoint = AVAudio3DPoint()
    var scheduled: [AVAudioPCMBuffer] = []

    public override init() {
        super.init()
    }

    public func play() {
        isPlaying = true
    }

    public func play(at when: AVAudioTime?) {
        _ = when
        play()
    }

    public func pause() {
        isPlaying = false
    }

    public func stop() {
        isPlaying = false
        scheduled.removeAll()
    }

    public func prepare(withFrameCount frameCount: AVAudioFrameCount) {
        _ = frameCount
    }

    public func nodeTime(forPlayerTime playerTime: AVAudioTime) -> AVAudioTime? { playerTime }
    public func playerTime(forNodeTime nodeTime: AVAudioTime) -> AVAudioTime? { nodeTime }

    public func scheduleBuffer(_ buffer: AVAudioPCMBuffer) async {
        scheduled.append(buffer)
    }

    public func scheduleBuffer(
        _ buffer: AVAudioPCMBuffer,
        completionCallbackType callbackType: AVAudioPlayerNodeCompletionCallbackType
    ) async -> AVAudioPlayerNodeCompletionCallbackType {
        scheduled.append(buffer)
        return callbackType
    }

    public func scheduleBuffer(
        _ buffer: AVAudioPCMBuffer,
        at when: AVAudioTime?,
        options: AVAudioPlayerNodeBufferOptions = []
    ) async {
        _ = when
        _ = options
        scheduled.append(buffer)
    }

    public func scheduleBuffer(
        _ buffer: AVAudioPCMBuffer,
        at when: AVAudioTime?,
        options: AVAudioPlayerNodeBufferOptions = [],
        completionCallbackType callbackType: AVAudioPlayerNodeCompletionCallbackType
    ) async -> AVAudioPlayerNodeCompletionCallbackType {
        _ = when
        _ = options
        scheduled.append(buffer)
        return callbackType
    }

    public func scheduleFile(_ file: AVAudioFile, at when: AVAudioTime?) async {
        _ = file
        _ = when
    }

    public func scheduleFile(
        _ file: AVAudioFile,
        at when: AVAudioTime?,
        completionCallbackType callbackType: AVAudioPlayerNodeCompletionCallbackType
    ) async -> AVAudioPlayerNodeCompletionCallbackType {
        _ = file
        _ = when
        return callbackType
    }

    public func scheduleSegment(
        _ file: AVAudioFile,
        startingFrame startFrame: AVAudioFramePosition,
        frameCount numberFrames: AVAudioFrameCount,
        at when: AVAudioTime?
    ) async {
        _ = file
        _ = startFrame
        _ = numberFrames
        _ = when
    }

    public func scheduleSegment(
        _ file: AVAudioFile,
        startingFrame startFrame: AVAudioFramePosition,
        frameCount numberFrames: AVAudioFrameCount,
        at when: AVAudioTime?,
        completionCallbackType callbackType: AVAudioPlayerNodeCompletionCallbackType
    ) async -> AVAudioPlayerNodeCompletionCallbackType {
        _ = file
        _ = startFrame
        _ = numberFrames
        _ = when
        return callbackType
    }
}

public final class AVAudioSourceNode: AVAudioNode, AVAudioMixing, @unchecked Sendable {
    public var volume: Float {
        get { storedVolume }
        set { storedVolume = newValue }
    }
    public var pan: Float {
        get { storedPan }
        set { storedPan = newValue }
    }
    public var renderingAlgorithm: AVAudio3DMixingRenderingAlgorithm = .auto
    public var sourceMode: AVAudio3DMixingSourceMode = .spatializeIfMono
    public var pointSourceInHeadMode: AVAudio3DMixingPointSourceInHeadMode = .mono
    public var rate: Float = 1
    public var reverbBlend: Float = 0
    public var obstruction: Float = 0
    public var occlusion: Float = 0
    public var position: AVAudio3DPoint = AVAudio3DPoint()
    private let renderBlock: AVAudioSourceNodeRenderBlock

    public init(renderBlock: @escaping AVAudioSourceNodeRenderBlock) {
        self.renderBlock = renderBlock
        super.init()
    }

    public init(
        format: AVAudioFormat,
        renderBlock: @escaping AVAudioSourceNodeRenderBlock
    ) {
        self.renderBlock = renderBlock
        super.init()
        storedFormat = format
    }
}

public final class AVAudioSinkNode: AVAudioNode, @unchecked Sendable {
    private let receiver: AVAudioSinkNodeReceiverBlock
    public init(receiverBlock: @escaping AVAudioSinkNodeReceiverBlock) {
        self.receiver = receiverBlock
        super.init()
    }
}

public final class AVAudioEngine: NSObject, @unchecked Sendable {
    private let lock = NSLock()
    private var nodes: [AVAudioNode] = []
    private var connections: [(AVAudioNode, AVAudioNode, AVAudioNodeBus, AVAudioNodeBus, AVAudioFormat?)] = []
    private var running = false
    private var prepared = false
    private var paused = false
    private var autoShutdown = false
    private var manual = false
    private var manualMode = AVAudioEngineManualRenderingMode.offline
    private var manualFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
    private var manualMaxFrames: AVAudioFrameCount = 4096
    private var manualSampleTime: AVAudioFramePosition = 0
    public let mainMixerNode = AVAudioMixerNode()
    public let outputNode = AVAudioOutputNode()
    public let inputNode = AVAudioInputNode()
    public var musicSequence: MusicSequence?

    public override init() {
        super.init()
        attach(mainMixerNode)
        attach(outputNode)
        attach(inputNode)
        connect(mainMixerNode, to: outputNode, format: manualFormat)
    }

    public var isRunning: Bool { avfaudioLock(lock) { running } }
    public var isAutoShutdownEnabled: Bool {
        get { avfaudioLock(lock) { autoShutdown } }
        set { avfaudioLock(lock) { autoShutdown = newValue } }
    }
    public var isInManualRenderingMode: Bool { avfaudioLock(lock) { manual } }
    public var manualRenderingMode: AVAudioEngineManualRenderingMode {
        avfaudioLock(lock) { manualMode }
    }
    public var manualRenderingFormat: AVAudioFormat { avfaudioLock(lock) { manualFormat } }
    public var manualRenderingMaximumFrameCount: AVAudioFrameCount {
        avfaudioLock(lock) { manualMaxFrames }
    }
    public var manualRenderingSampleTime: AVAudioFramePosition {
        avfaudioLock(lock) { manualSampleTime }
    }
    public var attachedNodes: Set<AVAudioNode> {
        avfaudioLock(lock) { Set(nodes) }
    }
    public var manualRenderingBlock: AVAudioEngineManualRenderingBlock {
        { [weak self] frameCount, list, status in
            guard let self else { return .error }
            return self.renderList(frameCount: frameCount, list: list, status: status)
        }
    }

    public func attach(_ node: AVAudioNode) {
        avfaudioLock(lock) {
            if !nodes.contains(where: { $0 === node }) {
                nodes.append(node)
            }
            node.engine = self
        }
    }

    public func detach(_ node: AVAudioNode) {
        avfaudioLock(lock) {
            connections.removeAll { $0.0 === node || $0.1 === node }
            node.engine = nil
            nodes.removeAll { $0 === node }
        }
    }

    public func connect(_ node1: AVAudioNode, to node2: AVAudioNode, format: AVAudioFormat?) {
        connect(node1, to: node2, fromBus: 0, toBus: 0, format: format)
    }

    public func connect(
        _ node1: AVAudioNode,
        to node2: AVAudioNode,
        fromBus bus1: AVAudioNodeBus,
        toBus bus2: AVAudioNodeBus,
        format: AVAudioFormat?
    ) {
        attach(node1)
        attach(node2)
        avfaudioLock(lock) {
            connections.removeAll { $0.0 === node1 && $0.3 == bus2 }
            connections.append((node1, node2, bus1, bus2, format))
            if let format {
                node1.storedFormat = format
                node2.storedFormat = format
            }
        }
    }

    public func connect(
        _ sourceNode: AVAudioNode,
        to destNodes: [AVAudioConnectionPoint],
        fromBus sourceBus: AVAudioNodeBus,
        format: AVAudioFormat?
    ) {
        for point in destNodes {
            if let node = point.node {
                connect(sourceNode, to: node, fromBus: sourceBus, toBus: point.bus, format: format)
            }
        }
    }

    public func disconnectNodeInput(_ node: AVAudioNode) {
        avfaudioLock(lock) { connections.removeAll { $0.1 === node } }
    }

    public func disconnectNodeInput(_ node: AVAudioNode, bus: AVAudioNodeBus) {
        avfaudioLock(lock) { connections.removeAll { $0.1 === node && $0.3 == bus } }
    }

    public func disconnectNodeOutput(_ node: AVAudioNode) {
        avfaudioLock(lock) { connections.removeAll { $0.0 === node } }
    }

    public func disconnectNodeOutput(_ node: AVAudioNode, bus: AVAudioNodeBus) {
        avfaudioLock(lock) { connections.removeAll { $0.0 === node && $0.2 == bus } }
    }

    public func inputConnectionPoint(
        for node: AVAudioNode,
        inputBus bus: AVAudioNodeBus
    ) -> AVAudioConnectionPoint? {
        avfaudioLock(lock) {
            connections.first { $0.1 === node && $0.3 == bus }.map {
                AVAudioConnectionPoint(node: $0.0, bus: $0.2)
            }
        }
    }

    public func outputConnectionPoints(
        for node: AVAudioNode,
        outputBus bus: AVAudioNodeBus
    ) -> [AVAudioConnectionPoint] {
        avfaudioLock(lock) {
            connections.filter { $0.0 === node && $0.2 == bus }.map {
                AVAudioConnectionPoint(node: $0.1, bus: $0.3)
            }
        }
    }

    public func prepare() {
        avfaudioLock(lock) { prepared = true }
    }

    public func start() throws {
        avfaudioLock(lock) {
            prepared = true
            running = true
            paused = false
        }
    }

    public func pause() {
        avfaudioLock(lock) { paused = true; running = false }
    }

    public func stop() {
        avfaudioLock(lock) {
            running = false
            paused = false
        }
    }

    public func reset() {
        avfaudioLock(lock) {
            connections.removeAll {
                $0.0 !== mainMixerNode || $0.1 !== outputNode
            }
            manualSampleTime = 0
        }
    }

    public func enableManualRenderingMode(
        _ mode: AVAudioEngineManualRenderingMode,
        format pcmFormat: AVAudioFormat,
        maximumFrameCount: AVAudioFrameCount
    ) throws {
        avfaudioLock(lock) {
            manual = true
            manualMode = mode
            manualFormat = pcmFormat
            manualMaxFrames = maximumFrameCount
            running = true
        }
    }

    public func disableManualRenderingMode() {
        avfaudioLock(lock) { manual = false; running = false }
    }

    public func renderOffline(
        _ numberOfFrames: AVAudioFrameCount,
        to buffer: AVAudioPCMBuffer
    ) throws -> AVAudioEngineManualRenderingStatus {
        guard isInManualRenderingMode else {
            throw AVAudioEngineManualRenderingError.invalidMode
        }
        guard numberOfFrames <= buffer.frameCapacity else {
            throw AVAudioEngineManualRenderingError.invalidMode
        }
        buffer.frameLength = numberOfFrames
        if let floatPlanes = buffer.floatChannelData {
            let frames = Int(numberOfFrames)
            let channels = Int(buffer.format.channelCount)
            for channel in 0..<channels {
                floatPlanes[channel].update(repeating: 0, count: frames * buffer.stride)
            }
            mixScheduledPlayerNodes(into: buffer)
        }
        avfaudioLock(lock) { manualSampleTime += AVAudioFramePosition(numberOfFrames) }
        return .success
    }

    public func connectMIDI(
        _ sourceNode: AVAudioNode,
        to destinationNode: AVAudioNode,
        format: AVAudioFormat?,
        block tapBlock: AUMIDIOutputEventBlock? = nil
    ) {
        _ = tapBlock
        connect(sourceNode, to: destinationNode, format: format)
    }

    public func connectMIDI(
        _ sourceNode: AVAudioNode,
        to destinationNode: AVAudioNode,
        format: AVAudioFormat?,
        eventListBlock tapBlock: AUMIDIEventListBlock? = nil
    ) {
        _ = tapBlock
        connect(sourceNode, to: destinationNode, format: format)
    }

    public func connectMIDI(
        _ sourceNode: AVAudioNode,
        to destinationNodes: [AVAudioNode],
        format: AVAudioFormat?,
        block tapBlock: AUMIDIOutputEventBlock? = nil
    ) {
        _ = tapBlock
        for node in destinationNodes {
            connect(sourceNode, to: node, format: format)
        }
    }

    public func connectMIDI(
        _ sourceNode: AVAudioNode,
        to destinationNodes: [AVAudioNode],
        format: AVAudioFormat?,
        eventListBlock tapBlock: AUMIDIEventListBlock? = nil
    ) {
        _ = tapBlock
        for node in destinationNodes {
            connect(sourceNode, to: node, format: format)
        }
    }

    public func disconnectMIDI(_ sourceNode: AVAudioNode, from destinationNode: AVAudioNode) {
        avfaudioLock(lock) {
            connections.removeAll { $0.0 === sourceNode && $0.1 === destinationNode }
        }
    }

    public func disconnectMIDI(_ sourceNode: AVAudioNode, from destinationNodes: [AVAudioNode]) {
        for node in destinationNodes {
            disconnectMIDI(sourceNode, from: node)
        }
    }

    public func disconnectMIDIInput(_ node: AVAudioNode) {
        disconnectNodeInput(node)
    }

    public func disconnectMIDIOutput(_ node: AVAudioNode) {
        disconnectNodeOutput(node)
    }

    private func mixScheduledPlayerNodes(into buffer: AVAudioPCMBuffer) {
        let players = avfaudioLock(lock) {
            nodes.compactMap { $0 as? AVAudioPlayerNode }
        }
        guard let dest = buffer.floatChannelData else { return }
        let frames = Int(buffer.frameLength)
        let channels = Int(buffer.format.channelCount)
        for player in players where player.isPlaying {
            guard let source = player.scheduled.first,
                let src = source.floatChannelData
            else { continue }
            let copyFrames = min(frames, Int(source.frameLength))
            let copyChannels = min(channels, Int(source.format.channelCount))
            let gain = player.volume * mainMixerNode.outputVolume
            for channel in 0..<copyChannels {
                for frame in 0..<copyFrames {
                    dest[channel][frame] += src[channel][frame] * gain
                }
            }
        }
    }

    private func renderList(
        frameCount: AVAudioFrameCount,
        list: UnsafeMutablePointer<AudioBufferList>,
        status: UnsafeMutablePointer<OSStatus>?
    ) -> AVAudioEngineManualRenderingStatus {
        _ = list
        status?.pointee = noErr
        avfaudioLock(lock) { manualSampleTime += AVAudioFramePosition(frameCount) }
        return .success
    }
}

public final class AVAudioEnvironmentDistanceAttenuationParameters: NSObject, @unchecked Sendable {
    public var distanceAttenuationModel: AVAudioEnvironmentDistanceAttenuationModel = .inverse
    public var referenceDistance: Float = 1
    public var maximumDistance: Float = 10000
    public var rolloffFactor: Float = 1
}

public final class AVAudioEnvironmentReverbParameters: NSObject, @unchecked Sendable {
    public var enable = false
    public var level: Float = 0
    public var filterParameters = AVAudioUnitEQFilterParameters()
    public func loadFactoryReverbPreset(_ preset: AVAudioUnitReverbPreset) {
        _ = preset
    }
}

public final class AVAudioEnvironmentNode: AVAudioNode, AVAudioMixing, @unchecked Sendable {
    public var volume: Float {
        get { storedVolume }
        set { storedVolume = newValue }
    }
    public var pan: Float {
        get { storedPan }
        set { storedPan = newValue }
    }
    public var renderingAlgorithm: AVAudio3DMixingRenderingAlgorithm = .auto
    public var sourceMode: AVAudio3DMixingSourceMode = .spatializeIfMono
    public var pointSourceInHeadMode: AVAudio3DMixingPointSourceInHeadMode = .mono
    public var rate: Float = 1
    public var reverbBlend: Float = 0
    public var obstruction: Float = 0
    public var occlusion: Float = 0
    public var position: AVAudio3DPoint = AVAudio3DPoint()
    public var listenerPosition = AVAudio3DPoint()
    public var listenerAngularOrientation = AVAudio3DAngularOrientation()
    public var listenerVectorOrientation = AVAudio3DVectorOrientation()
    public var nextAvailableInputBus: AVAudioNodeBus = 0
    public var outputType: AVAudioEnvironmentOutputType = .auto
    public var outputVolume: Float = 1
    public let distanceAttenuationParameters = AVAudioEnvironmentDistanceAttenuationParameters()
    public let reverbParameters = AVAudioEnvironmentReverbParameters()
    public var applicableRenderingAlgorithms: [NSNumber] { [] }
}
