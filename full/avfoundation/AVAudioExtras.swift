import Dispatch
import Foundation

// MARK: - AVAudioSession extras (IceCubes / ladder corpus)
//
// iOS 26.1 places AVAudioSession in AVFAudio. This module keeps a portable
// copy so 14 ladder apps that `import AVFoundation` still compile. Linux has
// no audio hardware: `currentRoute` is empty and `outputVolume` is 0.

extension AVAudioSession {
    public struct Mode: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public init(stringLiteral value: String) { self.init(rawValue: value) }

        public static let `default` = Mode(rawValue: "AVAudioSessionModeDefault")
        public static let voiceChat = Mode(rawValue: "AVAudioSessionModeVoiceChat")
        public static let videoChat = Mode(rawValue: "AVAudioSessionModeVideoChat")
        public static let gameChat = Mode(rawValue: "AVAudioSessionModeGameChat")
        public static let videoRecording = Mode(rawValue: "AVAudioSessionModeVideoRecording")
        public static let measurement = Mode(rawValue: "AVAudioSessionModeMeasurement")
        public static let moviePlayback = Mode(rawValue: "AVAudioSessionModeMoviePlayback")
        public static let spokenAudio = Mode(rawValue: "AVAudioSessionModeSpokenAudio")
        public static let voicePrompt = Mode(rawValue: "AVAudioSessionModeVoicePrompt")
    }

    public struct Port: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public init(stringLiteral value: String) { self.init(rawValue: value) }

        public static let builtInSpeaker = Port(rawValue: "Speaker")
        public static let builtInReceiver = Port(rawValue: "Receiver")
        public static let headphones = Port(rawValue: "Headphones")
        public static let bluetoothA2DP = Port(rawValue: "BluetoothA2DPOutput")
        public static let builtInMic = Port(rawValue: "MicrophoneBuiltIn")
    }

    public enum InterruptionType: UInt, Hashable, Sendable {
        case ended = 0
        case began = 1
    }

    public struct InterruptionOptions: OptionSet, Hashable, Sendable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        public static let shouldResume = InterruptionOptions(rawValue: 1 << 0)
    }

    public enum RouteChangeReason: UInt, Hashable, Sendable {
        case unknown = 0
        case newDeviceAvailable = 1
        case oldDeviceUnavailable = 2
        case categoryChange = 3
        case override = 4
        case wakeFromSleep = 5
        case noSuitableRouteForCategory = 6
        case routeConfigurationChange = 7
    }

    public static let interruptionNotification = Notification.Name(
        "AVAudioSessionInterruptionNotification"
    )
    public static let routeChangeNotification = Notification.Name(
        "AVAudioSessionRouteChangeNotification"
    )
}

public let AVAudioSessionInterruptionTypeKey = "AVAudioSessionInterruptionTypeKey"
public let AVAudioSessionInterruptionOptionKey = "AVAudioSessionInterruptionOptionKey"
public let AVAudioSessionRouteChangeReasonKey = "AVAudioSessionRouteChangeReasonKey"
public let AVAudioSessionRouteChangePreviousRouteKey = "AVAudioSessionRouteChangePreviousRouteKey"

open class AVAudioSessionPortDescription: NSObject, @unchecked Sendable {
    public let portType: AVAudioSession.Port
    public let portName: String
    public let uid: String

    public init(portType: AVAudioSession.Port, portName: String, uid: String) {
        self.portType = portType
        self.portName = portName
        self.uid = uid
        super.init()
    }
}

open class AVAudioSessionRouteDescription: NSObject, @unchecked Sendable {
    public let inputs: [AVAudioSessionPortDescription]
    public let outputs: [AVAudioSessionPortDescription]

    public init(
        inputs: [AVAudioSessionPortDescription] = [],
        outputs: [AVAudioSessionPortDescription] = []
    ) {
        self.inputs = inputs
        self.outputs = outputs
        super.init()
    }
}

extension AVAudioSession {
    private static let extrasLock = NSLock()
    nonisolated(unsafe) private static var storedMode = Mode.default
    nonisolated(unsafe) private static var storedRoute = AVAudioSessionRouteDescription()

    public var mode: Mode {
        AVAudioSession.extrasLock.withLock { AVAudioSession.storedMode }
    }

    /// Empty route: documented Linux "no audio hardware" path.
    /// Measured testAVAudioSessionNoHardwareRoute: inputs/outputs empty,
    /// outputVolume == 0 after setCategory(.playAndRecord, mode: .voiceChat).
    public var currentRoute: AVAudioSessionRouteDescription {
        AVAudioSession.extrasLock.withLock { AVAudioSession.storedRoute }
    }

    /// 0: no output device (fail closed). Not Apple's hardware volume.
    public var outputVolume: Float { 0 }

    public func setCategory(
        _ category: Category,
        mode: Mode,
        options: CategoryOptions = []
    ) throws {
        try setCategory(category, options: options)
        AVAudioSession.extrasLock.withLock { AVAudioSession.storedMode = mode }
    }

    public func setMode(_ mode: Mode) throws {
        AVAudioSession.extrasLock.withLock { AVAudioSession.storedMode = mode }
    }
}

// MARK: - AVAudioPlayer / AVAudioRecorder (silent clock; no PCM output)

public protocol AVAudioPlayerDelegate: AnyObject {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool)
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?)
}

public protocol AVAudioRecorderDelegate: AnyObject {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool)
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?)
}

open class AVAudioPlayer: NSObject, @unchecked Sendable {
    public let url: URL?
    public var volume: Float = 1
    public var numberOfLoops: Int = 0
    public var enableRate: Bool = false
    public var rate: Float = 1
    public var pan: Float = 0
    public var numberOfChannels: Int { 0 }
    public var isMeteringEnabled: Bool = false
    public weak var delegate: AVAudioPlayerDelegate?

    private let lock = NSLock()
    private var playing = false
    private var mediaSeconds: Double = 0
    private var wallAnchor: Double?
    private var durationSeconds: Double = 0
    private var loopsRemaining: Int = 0
    private var pulse: DispatchSourceTimer?
    private let pulseQueue = DispatchQueue(label: "AVFoundation.AVAudioPlayer.clock")

    public init(contentsOf url: URL) throws {
        self.url = url
        super.init()
    }

    public init(data: Data) throws {
        _ = data
        self.url = nil
        super.init()
    }

    public var duration: TimeInterval { durationSeconds }

    public var currentTime: TimeInterval {
        get { lock.withLock { currentSeconds() } }
        set { lock.withLock { seek(to: newValue) } }
    }

    public var isPlaying: Bool { lock.withLock { playing } }

    public func prepareToPlay() -> Bool { true }

    public func play() -> Bool {
        lock.lock()
        if durationSeconds == 0 {
            playing = true
            wallAnchor = nil
            lock.unlock()
            return true
        }
        playing = true
        wallAnchor = AVMonotonicClock.seconds()
        loopsRemaining = numberOfLoops
        ensurePulse()
        lock.unlock()
        return true
    }

    public func play(atTime time: TimeInterval) -> Bool {
        currentTime = time
        return play()
    }

    public func pause() {
        lock.lock()
        commit()
        playing = false
        wallAnchor = nil
        lock.unlock()
    }

    public func stop() {
        lock.lock()
        playing = false
        mediaSeconds = 0
        wallAnchor = nil
        lock.unlock()
    }

    public func updateMeters() {}
    public func peakPower(forChannel channelNumber: Int) -> Float {
        _ = channelNumber
        return -160
    }
    public func averagePower(forChannel channelNumber: Int) -> Float {
        _ = channelNumber
        return -160
    }

    @_spi(OpenUIKitHost)
    public func _portableSetDuration(_ seconds: Double) {
        lock.withLock { durationSeconds = max(0, seconds) }
    }

    private func currentSeconds() -> Double {
        if let wallAnchor, playing {
            return mediaSeconds + (AVMonotonicClock.seconds() - wallAnchor) * Double(rate == 0 ? 1 : rate)
        }
        return mediaSeconds
    }

    private func commit() {
        mediaSeconds = currentSeconds()
        wallAnchor = playing ? AVMonotonicClock.seconds() : nil
    }

    private func seek(to seconds: Double) {
        mediaSeconds = max(0, seconds)
        wallAnchor = playing ? AVMonotonicClock.seconds() : nil
    }

    private func ensurePulse() {
        if pulse != nil { return }
        let timer = DispatchSource.makeTimerSource(queue: pulseQueue)
        timer.schedule(deadline: .now(), repeating: 0.02)
        timer.setEventHandler { [weak self] in self?.tick() }
        pulse = timer
        timer.resume()
    }

    private func tick() {
        lock.lock()
        guard playing, durationSeconds > 0 else {
            lock.unlock()
            return
        }
        let now = currentSeconds()
        var finished = false
        let success = true
        if now >= durationSeconds {
            if loopsRemaining == -1 || loopsRemaining > 0 {
                if loopsRemaining > 0 { loopsRemaining -= 1 }
                mediaSeconds = 0
                wallAnchor = AVMonotonicClock.seconds()
            } else {
                playing = false
                mediaSeconds = durationSeconds
                wallAnchor = nil
                finished = true
            }
        }
        lock.unlock()
        if finished {
            delegate?.audioPlayerDidFinishPlaying(self, successfully: success)
        }
    }

    deinit { pulse?.cancel() }
}

open class AVAudioRecorder: NSObject, @unchecked Sendable {
    public let url: URL
    public var isMeteringEnabled: Bool = false
    public weak var delegate: AVAudioRecorderDelegate?

    private let lock = NSLock()
    private var recording = false
    private var mediaSeconds: Double = 0
    private var wallAnchor: Double?

    public init(url: URL, settings: [String: Any]) throws {
        self.url = url
        _ = settings
        super.init()
    }

    public var isRecording: Bool { lock.withLock { recording } }

    public var currentTime: TimeInterval {
        lock.withLock {
            if let wallAnchor, recording {
                return mediaSeconds + (AVMonotonicClock.seconds() - wallAnchor)
            }
            return mediaSeconds
        }
    }

    public func prepareToRecord() -> Bool { true }

    public func record() -> Bool {
        lock.lock()
        recording = true
        wallAnchor = AVMonotonicClock.seconds()
        lock.unlock()
        return true
    }

    public func record(forDuration duration: TimeInterval) -> Bool {
        _ = duration
        return record()
    }

    public func pause() {
        lock.lock()
        if let wallAnchor, recording {
            mediaSeconds += AVMonotonicClock.seconds() - wallAnchor
        }
        recording = false
        wallAnchor = nil
        lock.unlock()
    }

    public func stop() {
        pause()
        delegate?.audioRecorderDidFinishRecording(self, successfully: false)
    }

    public func deleteRecording() -> Bool { false }

    public func updateMeters() {}
    public func peakPower(forChannel channelNumber: Int) -> Float {
        _ = channelNumber
        return -160
    }
    public func averagePower(forChannel channelNumber: Int) -> Float {
        _ = channelNumber
        return -160
    }
}

// MARK: - AVSpeechSynthesizer (fail closed)

open class AVSpeechSynthesisVoice: NSObject, @unchecked Sendable {
    public let language: String
    public let identifier: String
    public let name: String

    public init(language: String = "en-US") {
        self.language = language
        self.identifier = language
        self.name = language
        super.init()
    }

    public class func speechVoices() -> [AVSpeechSynthesisVoice] { [] }
    public class func currentLanguageCode() -> String { "en-US" }
}

open class AVSpeechUtterance: NSObject, @unchecked Sendable {
    public let speechString: String
    public var voice: AVSpeechSynthesisVoice?
    public var rate: Float = 0.5
    public var pitchMultiplier: Float = 1
    public var volume: Float = 1
    public var preUtteranceDelay: TimeInterval = 0
    public var postUtteranceDelay: TimeInterval = 0

    public init(string: String) {
        self.speechString = string
        super.init()
    }
}

public protocol AVSpeechSynthesizerDelegate: AnyObject {}

open class AVSpeechSynthesizer: NSObject, @unchecked Sendable {
    public weak var delegate: AVSpeechSynthesizerDelegate?
    public var isSpeaking: Bool { false }
    public var isPaused: Bool { false }

    public override init() {
        super.init()
    }

    @discardableResult
    public func speak(_ utterance: AVSpeechUtterance) -> Bool {
        _ = utterance
        return false
    }

    public func stopSpeaking(at boundary: AVSpeechBoundary) -> Bool {
        _ = boundary
        return false
    }

    public func pauseSpeaking(at boundary: AVSpeechBoundary) -> Bool {
        _ = boundary
        return false
    }

    public func continueSpeaking() -> Bool { false }
}

public enum AVSpeechBoundary: UInt, Hashable, Sendable {
    case immediate = 0
    case word = 1
}
