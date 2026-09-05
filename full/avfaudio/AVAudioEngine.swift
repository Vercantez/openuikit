import Foundation
#if canImport(CoreAudioTypes)
import CoreAudioTypes
#endif
#if canImport(AudioToolbox)
import AudioToolbox
#endif
#if canImport(CoreMIDI)
import CoreMIDI
#endif

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

open class AVAudioNode: NSObject {
    public internal(set) weak var engine: AVAudioEngine?
    public var numberOfInputs: Int { 1 }
    public var numberOfOutputs: Int { 1 }
    public var latency: TimeInterval { 0 }
    public var outputPresentationLatency: TimeInterval { 0 }
    public var lastRenderTime: AVAudioTime?
    var storedVolume: Float = 1
    var storedPan: Float = 0
    var storedFormat: AVAudioFormat =
        AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
    private var taps: [AVAudioNodeBus: AVAudioNodeTapBlock] = [:]

    public func reset() {
        lastRenderTime = nil
    }

    func avfaudioFireTap(bus: AVAudioNodeBus, buffer: AVAudioPCMBuffer, time: AVAudioTime) {
        taps[bus]?(buffer, time)
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

public final class AVAudioMixingDestination: NSObject {
    public let connectionPoint: AVAudioConnectionPoint
    public init(connectionPoint: AVAudioConnectionPoint) {
        self.connectionPoint = connectionPoint
        super.init()
    }
}

public final class AVAudioConnectionPoint: NSObject {
    public private(set) weak var node: AVAudioNode?
    public let bus: AVAudioNodeBus
    public init(node: AVAudioNode, bus: AVAudioNodeBus) {
        self.node = node
        self.bus = bus
        super.init()
    }
}

open class AVAudioIONode: AVAudioNode {
    #if canImport(AudioToolbox)
    public var audioUnit: AudioUnit? { nil }
    #endif
    public var presentationLatency: TimeInterval { 0 }
    public private(set) var isVoiceProcessingEnabled = false

    public func setVoiceProcessingEnabled(_ enabled: Bool) throws {
        _ = enabled
        throw avfaudioHostUnavailableError("Voice processing requires an AVFAudio host service.")
    }
}

public final class AVAudioInputNode: AVAudioIONode, AVAudioMixing {
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

    #if canImport(CoreAudioTypes) || canImport(AudioToolbox)
    public func setManualRenderingInputPCMFormat(
        _ format: AVAudioFormat,
        inputBlock block: @escaping AVAudioIONodeInputBlock
    ) -> Bool {
        _ = block
        storedFormat = format
        return false
    }
    #endif

    public func setMutedSpeechActivityEventListener(
        _ listenerBlock: ((AVAudioVoiceProcessingSpeechActivityEvent) -> Void)?
    ) -> Bool {
        _ = listenerBlock
        return false
    }
}

public final class AVAudioOutputNode: AVAudioIONode {
    override public var numberOfOutputs: Int { 0 }
}

public final class AVAudioMixerNode: AVAudioNode, AVAudioMixing {
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
    var usedInputBuses: Set<AVAudioNodeBus> = []

    public override init() {
        super.init()
    }

    func avfaudioNoteInputBus(_ bus: AVAudioNodeBus) {
        usedInputBuses.insert(bus)
        var candidate: AVAudioNodeBus = 0
        while usedInputBuses.contains(candidate) {
            candidate += 1
        }
        nextAvailableInputBus = candidate
    }

    func avfaudioReleaseInputBus(_ bus: AVAudioNodeBus) {
        usedInputBuses.remove(bus)
        var candidate: AVAudioNodeBus = 0
        while usedInputBuses.contains(candidate) {
            candidate += 1
        }
        nextAvailableInputBus = candidate
    }
}

public final class AVAudioPlayerNode: AVAudioNode, AVAudioMixing {
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
    var scheduled: [AVAudioPlayerScheduledBuffer] = []
    private var sampleCursor: AVAudioFramePosition = 0

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
        sampleCursor = 0
    }

    public func prepare(withFrameCount frameCount: AVAudioFrameCount) {
        _ = frameCount
    }

    public func nodeTime(forPlayerTime playerTime: AVAudioTime) -> AVAudioTime? { playerTime }
    public func playerTime(forNodeTime nodeTime: AVAudioTime) -> AVAudioTime? { nodeTime }

    func avfaudioEnqueue(
        _ buffer: AVAudioPCMBuffer,
        at when: AVAudioTime?,
        options: AVAudioPlayerNodeBufferOptions,
        completionCallbackType: AVAudioPlayerNodeCompletionCallbackType?,
        completion: ((AVAudioPlayerNodeCompletionCallbackType) -> Void)?
    ) {
        _ = when
        if options.contains(.interrupts) {
            scheduled.removeAll()
        } else if options.contains(.interruptsAtLoop) {
            scheduled.removeAll { $0.options.contains(.loops) }
        }
        scheduled.append(
            AVAudioPlayerScheduledBuffer(
                buffer: buffer,
                options: options,
                cursor: 0,
                completionType: completionCallbackType,
                completion: completion
            )
        )
    }

    public func scheduleBuffer(_ buffer: AVAudioPCMBuffer) async {
        avfaudioEnqueue(buffer, at: nil, options: [], completionCallbackType: nil, completion: nil)
    }

    public func scheduleBuffer(
        _ buffer: AVAudioPCMBuffer,
        completionCallbackType callbackType: AVAudioPlayerNodeCompletionCallbackType
    ) async -> AVAudioPlayerNodeCompletionCallbackType {
        avfaudioEnqueue(
            buffer,
            at: nil,
            options: [],
            completionCallbackType: callbackType,
            completion: nil
        )
        return callbackType
    }

    public func scheduleBuffer(
        _ buffer: AVAudioPCMBuffer,
        at when: AVAudioTime?,
        options: AVAudioPlayerNodeBufferOptions = []
    ) async {
        avfaudioEnqueue(buffer, at: when, options: options, completionCallbackType: nil, completion: nil)
    }

    public func scheduleBuffer(
        _ buffer: AVAudioPCMBuffer,
        at when: AVAudioTime?,
        options: AVAudioPlayerNodeBufferOptions = [],
        completionCallbackType callbackType: AVAudioPlayerNodeCompletionCallbackType
    ) async -> AVAudioPlayerNodeCompletionCallbackType {
        avfaudioEnqueue(
            buffer,
            at: when,
            options: options,
            completionCallbackType: callbackType,
            completion: nil
        )
        return callbackType
    }

    public func scheduleBuffer(
        _ buffer: AVAudioPCMBuffer,
        completionHandler: @escaping AVAudioNodeCompletionHandler
    ) {
        avfaudioEnqueue(
            buffer,
            at: nil,
            options: [],
            completionCallbackType: .dataConsumed,
            completion: { _ in completionHandler() }
        )
    }

    public func scheduleFile(_ file: AVAudioFile, at when: AVAudioTime?) async {
        avfaudioScheduleFile(file, startingFrame: 0, frameCount: AVAudioFrameCount(max(file.length, 0)), at: when)
    }

    public func scheduleFile(
        _ file: AVAudioFile,
        at when: AVAudioTime?,
        completionCallbackType callbackType: AVAudioPlayerNodeCompletionCallbackType
    ) async -> AVAudioPlayerNodeCompletionCallbackType {
        avfaudioScheduleFile(file, startingFrame: 0, frameCount: AVAudioFrameCount(max(file.length, 0)), at: when)
        return callbackType
    }

    public func scheduleSegment(
        _ file: AVAudioFile,
        startingFrame startFrame: AVAudioFramePosition,
        frameCount numberFrames: AVAudioFrameCount,
        at when: AVAudioTime?
    ) async {
        avfaudioScheduleFile(file, startingFrame: startFrame, frameCount: numberFrames, at: when)
    }

    public func scheduleSegment(
        _ file: AVAudioFile,
        startingFrame startFrame: AVAudioFramePosition,
        frameCount numberFrames: AVAudioFrameCount,
        at when: AVAudioTime?,
        completionCallbackType callbackType: AVAudioPlayerNodeCompletionCallbackType
    ) async -> AVAudioPlayerNodeCompletionCallbackType {
        avfaudioScheduleFile(file, startingFrame: startFrame, frameCount: numberFrames, at: when)
        return callbackType
    }

    private func avfaudioScheduleFile(
        _ file: AVAudioFile,
        startingFrame: AVAudioFramePosition,
        frameCount: AVAudioFrameCount,
        at when: AVAudioTime?
    ) {
        let saved = file.framePosition
        file.framePosition = max(startingFrame, 0)
        defer { file.framePosition = saved }
        guard
            let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: max(frameCount, 1))
        else {
            return
        }
        try? file.read(into: buffer, frameCount: frameCount)
        avfaudioEnqueue(buffer, at: when, options: [], completionCallbackType: nil, completion: nil)
    }

    func avfaudioRenderScheduled(
        into destination: AVAudioPCMBuffer,
        frames: Int
    ) {
        guard isPlaying, frames > 0 else { return }
        var remaining = frames
        var destOffset = 0
        while remaining > 0, !scheduled.isEmpty {
            var item = scheduled[0]
            let available = Int(item.buffer.frameLength) - Int(item.cursor)
            if available <= 0 {
                avfaudioFinishScheduled(&item)
                scheduled.removeFirst()
                continue
            }
            let take = min(remaining, available)
            guard
                let slice = AVAudioPCMBuffer(
                    pcmFormat: item.buffer.format,
                    frameCapacity: AVAudioFrameCount(take)
                )
            else {
                break
            }
            slice.frameLength = AVAudioFrameCount(take)
            for channel in 0..<Int(item.buffer.format.channelCount) {
                for frame in 0..<take {
                    let sample = avfaudioReadPCMSample(
                        item.buffer,
                        channel: channel,
                        frame: Int(item.cursor) + frame
                    )
                    avfaudioWritePCMSample(slice, channel: channel, frame: frame, value: sample)
                }
            }
            if slice.format.sampleRate != destination.format.sampleRate
                || slice.format.channelCount != destination.format.channelCount
                || slice.format.commonFormat != destination.format.commonFormat
            {
                guard
                    let converted = AVAudioPCMBuffer(
                        pcmFormat: destination.format,
                        frameCapacity: AVAudioFrameCount(take)
                    )
                else {
                    break
                }
                _ = avfaudioConvertPCM(from: slice, to: converted, channelMap: [], downmix: false)
            avfaudioMixPCM(
                source: converted,
                into: destination,
                volume: 1,
                pan: 0,
                extraGain: 1,
                frames: Int(converted.frameLength),
                destOffset: destOffset
            )
            } else {
                avfaudioMixPCM(
                    source: slice,
                    into: destination,
                    volume: 1,
                    pan: 0,
                    extraGain: 1,
                    frames: take,
                    destOffset: destOffset
                )
            }
            item.cursor += AVAudioFrameCount(take)
            destOffset += take
            remaining -= take
            sampleCursor += AVAudioFramePosition(take)
            if item.cursor >= item.buffer.frameLength {
                if item.options.contains(.loops) {
                    item.cursor = 0
                    scheduled[0] = item
                } else {
                    avfaudioFinishScheduled(&item)
                    scheduled.removeFirst()
                }
            } else {
                scheduled[0] = item
            }
        }
        lastRenderTime = AVAudioTime(sampleTime: sampleCursor, atRate: storedFormat.sampleRate)
    }

    private func avfaudioFinishScheduled(_ item: inout AVAudioPlayerScheduledBuffer) {
        let kind = item.completionType ?? .dataConsumed
        if let completion = item.completion {
            AVFAudioCallbackDelivery.deliverExactlyOnce {
                completion(kind)
            }
        }
    }
}

struct AVAudioPlayerScheduledBuffer {
    let buffer: AVAudioPCMBuffer
    let options: AVAudioPlayerNodeBufferOptions
    var cursor: AVAudioFrameCount
    var completionType: AVAudioPlayerNodeCompletionCallbackType?
    var completion: ((AVAudioPlayerNodeCompletionCallbackType) -> Void)?
}

#if canImport(CoreAudioTypes) || canImport(AudioToolbox)
public final class AVAudioSourceNode: AVAudioNode, AVAudioMixing {
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

public final class AVAudioSinkNode: AVAudioNode {
    private let receiver: AVAudioSinkNodeReceiverBlock
    public init(receiverBlock: @escaping AVAudioSinkNodeReceiverBlock) {
        self.receiver = receiverBlock
        super.init()
    }
}

#endif

public final class AVAudioEngine: NSObject {
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
    #if canImport(AudioToolbox)
    public var musicSequence: MusicSequence?
    #endif

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
    #if canImport(CoreAudioTypes) || canImport(AudioToolbox)
    public var manualRenderingBlock: AVAudioEngineManualRenderingBlock {
        { _, _, status in
            status?.pointee = -1
            return .error
        }
    }
    #endif

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
            connections.removeAll { $0.1 === node2 && $0.3 == bus2 }
            connections.append((node1, node2, bus1, bus2, format))
            if let mixer = node2 as? AVAudioMixerNode {
                mixer.avfaudioNoteInputBus(bus2)
            }
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
        avfaudioLock(lock) {
            if let mixer = node as? AVAudioMixerNode {
                for connection in connections where connection.1 === node {
                    mixer.avfaudioReleaseInputBus(connection.3)
                }
            }
            connections.removeAll { $0.1 === node }
        }
    }

    public func disconnectNodeInput(_ node: AVAudioNode, bus: AVAudioNodeBus) {
        avfaudioLock(lock) {
            if let mixer = node as? AVAudioMixerNode {
                mixer.avfaudioReleaseInputBus(bus)
            }
            connections.removeAll { $0.1 === node && $0.3 == bus }
        }
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
        try avfaudioLock(lock) {
            if manual {
                running = true
                paused = false
                return
            }
            throw avfaudioHostUnavailableError(
                "AVAudioEngine.start requires an available audio device and host service."
            )
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
            for node in nodes {
                node.reset()
                if let player = node as? AVAudioPlayerNode {
                    player.stop()
                }
            }
        }
    }

    public func enableManualRenderingMode(
        _ mode: AVAudioEngineManualRenderingMode,
        format pcmFormat: AVAudioFormat,
        maximumFrameCount: AVAudioFrameCount
    ) throws {
        try avfaudioLock(lock) {
            if running, !manual {
                throw AVAudioEngineManualRenderingError.invalidMode
            }
            if manual {
                throw AVAudioEngineManualRenderingError.initialized
            }
            guard pcmFormat.commonFormat != .otherFormat, maximumFrameCount > 0 else {
                throw AVAudioEngineManualRenderingError.invalidMode
            }
            manual = true
            manualMode = mode
            manualFormat = pcmFormat
            manualMaxFrames = maximumFrameCount
            manualSampleTime = 0
            mainMixerNode.storedFormat = pcmFormat
            outputNode.storedFormat = pcmFormat
            inputNode.storedFormat = pcmFormat
        }
        NotificationCenter.default.post(
            name: .AVAudioEngineConfigurationChange,
            object: self
        )
    }

    public func disableManualRenderingMode() {
        avfaudioLock(lock) {
            manual = false
            running = false
        }
        NotificationCenter.default.post(
            name: .AVAudioEngineConfigurationChange,
            object: self
        )
    }

    public func renderOffline(
        _ numberOfFrames: AVAudioFrameCount,
        to buffer: AVAudioPCMBuffer
    ) throws -> AVAudioEngineManualRenderingStatus {
        try avfaudioLock(lock) {
            guard manual else { throw AVAudioEngineManualRenderingError.invalidMode }
            guard running else { throw AVAudioEngineManualRenderingError.notRunning }
            guard numberOfFrames > 0, numberOfFrames <= manualMaxFrames else {
                throw AVAudioEngineManualRenderingError.invalidMode
            }
            guard buffer.format.sampleRate == manualFormat.sampleRate,
                  buffer.format.channelCount == manualFormat.channelCount
            else {
                throw AVAudioEngineManualRenderingError.invalidMode
            }
            avfaudioZeroPCMBuffer(buffer, frames: numberOfFrames)
            let mixed = avfaudioRenderNode(
                mainMixerNode,
                frames: Int(numberOfFrames),
                format: manualFormat
            )
            let mixerGain = mainMixerNode.outputVolume
            let channels = Int(buffer.format.channelCount)
            buffer.frameLength = mixed.frameLength
            for frame in 0..<Int(mixed.frameLength) {
                for channel in 0..<channels {
                    let sample = avfaudioReadPCMSample(mixed, channel: channel, frame: frame)
                    let panned = avfaudioApplyGainPan(
                        sample,
                        channel: channel,
                        channelCount: channels,
                        volume: mixerGain,
                        pan: 0
                    )
                    avfaudioWritePCMSample(buffer, channel: channel, frame: frame, value: panned)
                }
            }
            let time = AVAudioTime(sampleTime: manualSampleTime, atRate: manualFormat.sampleRate)
            mainMixerNode.lastRenderTime = time
            outputNode.lastRenderTime = time
            mainMixerNode.avfaudioFireTap(bus: 0, buffer: buffer, time: time)
            manualSampleTime += AVAudioFramePosition(buffer.frameLength)
            return .success
        }
    }

    private func avfaudioRenderNode(
        _ node: AVAudioNode,
        frames: Int,
        format: AVAudioFormat
    ) -> AVAudioPCMBuffer {
        guard
            let output = AVAudioPCMBuffer(
                pcmFormat: format,
                frameCapacity: AVAudioFrameCount(max(frames, 1))
            )
        else {
            return AVAudioPCMBuffer(
                pcmFormat: format,
                frameCapacity: 1
            )!
        }
        avfaudioZeroPCMBuffer(output, frames: AVAudioFrameCount(frames))
        if let player = node as? AVAudioPlayerNode {
            player.avfaudioRenderScheduled(into: output, frames: frames)
            return output
        }
        let inputs = connections.filter { $0.1 === node }
        for (source, _, _, _, _) in inputs {
            let rendered = avfaudioRenderNode(source, frames: frames, format: format)
            var extra: Float = 1
            var volume: Float = 1
            var pan: Float = 0
            if let eq = source as? AVAudioUnitEQ {
                extra *= avfaudioDecibelToLinear(eq.globalGain)
            }
            if let mixing = source as? AVAudioMixing {
                volume = mixing.volume
                pan = mixing.pan
            }
            avfaudioMixPCM(
                source: rendered,
                into: output,
                volume: volume,
                pan: pan,
                extraGain: extra,
                frames: Int(rendered.frameLength)
            )
        }
        return output
    }

    #if canImport(CoreAudioTypes) || canImport(AudioToolbox)
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
        to destinationNodes: [AVAudioNode],
        format: AVAudioFormat?,
        block tapBlock: AUMIDIOutputEventBlock? = nil
    ) {
        _ = tapBlock
        for node in destinationNodes {
            connect(sourceNode, to: node, format: format)
        }
    }
    #endif

    #if canImport(CoreMIDI)
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
        eventListBlock tapBlock: AUMIDIEventListBlock? = nil
    ) {
        _ = tapBlock
        for node in destinationNodes {
            connect(sourceNode, to: node, format: format)
        }
    }
    #endif

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
}

public final class AVAudioEnvironmentDistanceAttenuationParameters: NSObject {
    public var distanceAttenuationModel: AVAudioEnvironmentDistanceAttenuationModel = .inverse
    public var referenceDistance: Float = 1
    public var maximumDistance: Float = 10000
    public var rolloffFactor: Float = 1
}

public final class AVAudioEnvironmentReverbParameters: NSObject {
    public var enable = false
    public var level: Float = 0
    public var filterParameters = AVAudioUnitEQFilterParameters()
    public func loadFactoryReverbPreset(_ preset: AVAudioUnitReverbPreset) {
        _ = preset
    }
}

public final class AVAudioEnvironmentNode: AVAudioNode, AVAudioMixing {
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
