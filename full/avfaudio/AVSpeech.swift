import Foundation

public protocol AVSpeechSynthesizerDelegate: NSObjectProtocol {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance)
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance)
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance)
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance)
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance)
    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance: AVSpeechUtterance
    )
    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        willSpeak marker: AVSpeechSynthesisMarker,
        utterance: AVSpeechUtterance
    )
}

extension AVSpeechSynthesizerDelegate {
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {}
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {}
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {}
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {}
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {}
    public func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance: AVSpeechUtterance
    ) {}
    public func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        willSpeak marker: AVSpeechSynthesisMarker,
        utterance: AVSpeechUtterance
    ) {}
}

public final class AVSpeechSynthesisVoice: NSObject, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    public struct Traits: OptionSet, Hashable, Sendable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        public static let isNoveltyVoice = Traits(rawValue: 1 << 0)
        public static let isPersonalVoice = Traits(rawValue: 1 << 1)
    }

    public let identifier: String
    public let language: String
    public let name: String
    public let quality: AVSpeechSynthesisVoiceQuality
    public let gender: AVSpeechSynthesisVoiceGender
    public let voiceTraits: Traits
    public var audioFileSettings: [String: Any] { [:] }

    public init?(identifier: String) {
        // Apple voice catalogs are not shipped; identifiers do not resolve.
        _ = identifier
        return nil
    }

    public init?(language languageCode: String?) {
        _ = languageCode
        return nil
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    public func encode(with coder: NSCoder) {
        coder.encode(identifier, forKey: "identifier")
    }

    public class func speechVoices() -> [AVSpeechSynthesisVoice] { [] }

    public class func currentLanguageCode() -> String {
        Locale.current.identifier
    }
}

public final class AVSpeechUtterance: NSObject, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    public let speechString: String
    public var attributedSpeechString: NSAttributedString {
        NSAttributedString(string: speechString)
    }
    public var voice: AVSpeechSynthesisVoice?
    public var rate: Float = AVSpeechUtteranceDefaultSpeechRate
    public var pitchMultiplier: Float = 1
    public var volume: Float = 1
    public var preUtteranceDelay: TimeInterval = 0
    public var postUtteranceDelay: TimeInterval = 0
    public var prefersAssistiveTechnologySettings = false

    public init(string: String) {
        self.speechString = string
        super.init()
    }

    public init(attributedString string: NSAttributedString) {
        self.speechString = string.string
        super.init()
    }

    public init?(ssmlRepresentation string: String) {
        guard !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        self.speechString = string
        super.init()
    }

    public convenience init?(SSMLRepresentation string: String) {
        self.init(ssmlRepresentation: string)
    }

    public required init?(coder: NSCoder) {
        guard let text = coder.decodeObject(of: NSString.self, forKey: "text") as String? else {
            return nil
        }
        self.speechString = text
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(speechString as NSString, forKey: "text")
    }
}

public final class AVSpeechSynthesisMarker: NSObject, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    public enum Mark: Int, Hashable, Sendable {
        case phoneme = 0
        case word = 1
        case sentence = 2
        case paragraph = 3
        case bookmark = 4
    }

    public var mark: Mark
    public var byteSampleOffset: Int
    public var textRange: NSRange
    public var bookmarkName: String?
    public var phoneme: String?

    public init(
        markerType type: Mark,
        forTextRange range: NSRange,
        atByteSampleOffset byteSampleOffset: Int
    ) {
        self.mark = type
        self.textRange = range
        self.byteSampleOffset = byteSampleOffset
        super.init()
    }

    public convenience init(wordRange: NSRange, atByteSampleOffset byteSampleOffset: Int) {
        self.init(markerType: .word, forTextRange: wordRange, atByteSampleOffset: byteSampleOffset)
    }

    public convenience init(sentenceRange: NSRange, atByteSampleOffset byteSampleOffset: Int) {
        self.init(markerType: .sentence, forTextRange: sentenceRange, atByteSampleOffset: byteSampleOffset)
    }

    public convenience init(paragraphRange: NSRange, atByteSampleOffset byteSampleOffset: Int) {
        self.init(markerType: .paragraph, forTextRange: paragraphRange, atByteSampleOffset: byteSampleOffset)
    }

    public init(phonemeString: String, atByteSampleOffset byteSampleOffset: Int) {
        self.mark = .phoneme
        self.phoneme = phonemeString
        self.byteSampleOffset = byteSampleOffset
        self.textRange = NSRange(location: 0, length: 0)
        super.init()
    }

    public init(bookmarkName: String, atByteSampleOffset byteSampleOffset: Int) {
        self.mark = .bookmark
        self.bookmarkName = bookmarkName
        self.byteSampleOffset = byteSampleOffset
        self.textRange = NSRange(location: 0, length: 0)
        super.init()
    }

    public required init?(coder: NSCoder) {
        mark = Mark(rawValue: coder.decodeInteger(forKey: "mark")) ?? .word
        byteSampleOffset = coder.decodeInteger(forKey: "offset")
        textRange = NSRange(location: 0, length: 0)
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(mark.rawValue, forKey: "mark")
        coder.encode(byteSampleOffset, forKey: "offset")
    }
}

public final class AVSpeechSynthesizer: NSObject, @unchecked Sendable {
    public enum PersonalVoiceAuthorizationStatus: UInt, Hashable, Sendable {
        case notDetermined = 0
        case denied = 1
        case authorized = 2
        case unsupported = 3
    }

    public typealias BufferCallback = (AVAudioBuffer) -> Void
    public typealias MarkerCallback = ([AVSpeechSynthesisMarker]) -> Void

    public static let availableVoicesDidChangeNotification = NSNotification.Name(
        "AVSpeechSynthesisAvailableVoicesDidChangeNotification"
    )

    public class var personalVoiceAuthorizationStatus: PersonalVoiceAuthorizationStatus {
        .unsupported
    }

    public weak var delegate: (any AVSpeechSynthesizerDelegate)?
    public var usesApplicationAudioSession = true
    public var mixToTelephonyUplink = false
    public var outputChannels: [AVAudioSessionChannelDescription]?
    public private(set) var isSpeaking = false
    public private(set) var isPaused = false
    private var queue: [AVSpeechUtterance] = []

    public class func requestPersonalVoiceAuthorization(
        completionHandler handler: @escaping (PersonalVoiceAuthorizationStatus) -> Void
    ) {
        handler(.unsupported)
    }

    public func speak(_ utterance: AVSpeechUtterance) {
        queue.append(utterance)
        // No Apple voice engine: the utterance is retained for inspection, not spoken.
        isSpeaking = false
        isPaused = false
    }

    public func stopSpeaking(at boundary: AVSpeechBoundary) -> Bool {
        _ = boundary
        let hadWork = !queue.isEmpty || isSpeaking || isPaused
        queue.removeAll()
        isSpeaking = false
        isPaused = false
        return hadWork
    }

    public func pauseSpeaking(at boundary: AVSpeechBoundary) -> Bool {
        _ = boundary
        guard isSpeaking else { return false }
        isPaused = true
        isSpeaking = false
        return true
    }

    public func continueSpeaking() -> Bool {
        guard isPaused else { return false }
        isPaused = false
        isSpeaking = false
        return false
    }

    public func write(
        _ utterance: AVSpeechUtterance,
        toBufferCallback bufferCallback: @escaping BufferCallback
    ) {
        _ = utterance
        _ = bufferCallback
        // Do not invent PCM speech. Callers observe no synthesized buffers.
    }

    public func write(
        _ utterance: AVSpeechUtterance,
        toBufferCallback bufferCallback: @escaping BufferCallback,
        toMarkerCallback markerCallback: @escaping MarkerCallback
    ) {
        _ = utterance
        _ = bufferCallback
        _ = markerCallback
    }

    public var _queuedUtterances: [AVSpeechUtterance] { queue }
}

public final class AVSpeechSynthesisProviderVoice: NSObject, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }
    public var name: String
    public var identifier: String
    public var primaryLanguages: [String]
    public var supportedLanguages: [String]
    public var voiceSize: Int64 = 0
    public var age: Int = 0
    public var gender: AVSpeechSynthesisVoiceGender = .unspecified
    public var version: String = ""

    public init(name: String, identifier: String, primaryLanguages: [String], supportedLanguages: [String]) {
        self.name = name
        self.identifier = identifier
        self.primaryLanguages = primaryLanguages
        self.supportedLanguages = supportedLanguages
        super.init()
    }

    public required init?(coder: NSCoder) {
        name = (coder.decodeObject(of: NSString.self, forKey: "name") as String?) ?? ""
        identifier = (coder.decodeObject(of: NSString.self, forKey: "id") as String?) ?? ""
        primaryLanguages = []
        supportedLanguages = []
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(name as NSString, forKey: "name")
        coder.encode(identifier as NSString, forKey: "id")
    }

    public class func updateSpeechVoices() {}
}

public final class AVSpeechSynthesisProviderRequest: NSObject, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }
    public let ssmlRepresentation: String
    public let voice: AVSpeechSynthesisProviderVoice

    public init(ssmlRepresentation: String, voice: AVSpeechSynthesisProviderVoice) {
        self.ssmlRepresentation = ssmlRepresentation
        self.voice = voice
        super.init()
    }

    public required init?(coder: NSCoder) {
        ssmlRepresentation = (coder.decodeObject(of: NSString.self, forKey: "ssml") as String?) ?? ""
        voice = AVSpeechSynthesisProviderVoice(
            name: "",
            identifier: "",
            primaryLanguages: [],
            supportedLanguages: []
        )
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(ssmlRepresentation as NSString, forKey: "ssml")
    }
}

public typealias AVSpeechSynthesisProviderOutputBlock = (
    [AVSpeechSynthesisMarker],
    AVSpeechSynthesisProviderRequest
) -> Void

open class AVSpeechSynthesisProviderAudioUnit: AUAudioUnit, @unchecked Sendable {
    public var speechVoices: [AVSpeechSynthesisProviderVoice] = []
    public var outputChannelCount: Int = 1
    public var speechSynthesisOutputMetadataBlock: AVSpeechSynthesisProviderOutputBlock?

    public func synthesizeSpeechRequest(_ speechRequest: AVSpeechSynthesisProviderRequest) {
        _ = speechRequest
    }

    public func cancelSpeechRequest() {}
}
