import Foundation
#if canImport(AVFoundation)
import AVFoundation
#endif
#if canImport(CoreMedia)
import CoreMedia
#endif

public protocol SpeechModuleResult {
    var isFinal: Bool { get }
#if canImport(CoreMedia)
    var resultsFinalizationTime: CMTime { get }
    var range: CMTimeRange { get }
#endif
}

public protocol SpeechModule: AnyObject, Sendable {
    associatedtype Result: SpeechModuleResult & Sendable where Result == Results.Element
    associatedtype Results: Sendable & AsyncSequence where Results.Failure == any Error
    var results: Results { get }
#if canImport(AVFoundation)
    var availableCompatibleAudioFormats: [AVAudioFormat] { get async }
#endif
}

public protocol LocaleDependentSpeechModule: SpeechModule {
    static func supportedLocale(equivalentTo locale: Locale) async -> Locale?
    var selectedLocales: [Locale] { get }
    static var supportedLocales: [Locale] { get async }
}

public enum SpeechModels: Sendable {
    public static func endRetention() async {}
}

public final class AnalysisContext: @unchecked Sendable {
    public struct UserDataTag: RawRepresentable, Hashable, Sendable {
        public var rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public init(_ rawValue: String) { self.rawValue = rawValue }
    }

    public struct ContextualStringsTag: RawRepresentable, Hashable, Sendable {
        public var rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public init(_ rawValue: String) { self.rawValue = rawValue }
        public static let general = ContextualStringsTag("general")
    }

    private let lock = NSLock()
    private var _contextualStrings: [ContextualStringsTag: [String]] = [:]
    private var _userData: [UserDataTag: any Sendable] = [:]

    public var contextualStrings: [ContextualStringsTag: [String]] {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _contextualStrings
        }
        set {
            lock.lock()
            _contextualStrings = newValue
            lock.unlock()
        }
    }

    public var userData: [UserDataTag: any Sendable] {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _userData
        }
        set {
            lock.lock()
            _userData = newValue
            lock.unlock()
        }
    }

    public init() {}
}

public final class AssetInstallationRequest: NSObject, @unchecked Sendable {
    public let progress: Progress = Progress(totalUnitCount: 1)

    @_spi(OpenUIKitHost)
    public override init() {
        super.init()
        progress.completedUnitCount = 0
    }

    public func downloadAndInstall() async throws {
        throw speechFailClosedError(.internalServiceError)
    }
}

public final class AssetInventory: Sendable {
    public enum Status: Hashable, Comparable, Sendable {
        case unsupported
        case supported
        case downloading
        case installed

        public static func < (lhs: Status, rhs: Status) -> Bool {
            lhs.rank < rhs.rank
        }

        private var rank: Int {
            switch self {
            case .unsupported: return 0
            case .supported: return 1
            case .downloading: return 2
            case .installed: return 3
            }
        }
    }

    public static var maximumReservedLocales: Int { 0 }

    public static var reservedLocales: [Locale] {
        get async { [] }
    }

    public static func status(forModules modules: [any SpeechModule]) async -> Status {
        _ = modules
        return .unsupported
    }

    public static func assetInstallationRequest(
        supporting modules: [any SpeechModule]
    ) async throws -> AssetInstallationRequest? {
        _ = modules
        return nil
    }

    @discardableResult
    public static func release(reservedLocale: Locale) async -> Bool {
        _ = reservedLocale
        return false
    }

    @discardableResult
    public static func reserve(locale: Locale) async throws -> Bool {
        _ = locale
        throw speechFailClosedError(.cannotAllocateUnsupportedLocale)
    }
}

public final actor SpeechAnalyzer {
    public struct Options: Hashable, Sendable {
        public enum ModelRetention: String, Hashable, Sendable, CaseIterable {
            case lingering
            case whileInUse
            case processLifetime
        }

        public var priority: TaskPriority
        public var modelRetention: ModelRetention

        public init(priority: TaskPriority, modelRetention: ModelRetention) {
            self.priority = priority
            self.modelRetention = modelRetention
        }

        public static func == (lhs: Options, rhs: Options) -> Bool {
            lhs.priority == rhs.priority && lhs.modelRetention == rhs.modelRetention
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(priority.rawValue)
            hasher.combine(modelRetention)
        }
    }

    public private(set) var modules: [any SpeechModule]
    public var context: AnalysisContext {
        get async { analysisContext }
    }

    private var analysisContext: AnalysisContext
    private let options: Options?

    public init(modules: [any SpeechModule], options: Options? = nil) {
        self.modules = modules
        self.options = options
        self.analysisContext = AnalysisContext()
    }

    public func setContext(_ newContext: AnalysisContext) async throws {
        analysisContext = newContext
    }

    public func setModules(_ newModules: [any SpeechModule]) async throws {
        modules = newModules
    }

    public func cancelAndFinishNow() async {}

    public func finalizeAndFinishThroughEndOfInput() async throws {
        throw speechFailClosedError(.noModel)
    }

    public func hostCheckIsolation() {
        assertIsolated()
        preconditionIsolated()
        _ = assumeIsolated { isolated in isolated.modules.count }
    }

#if canImport(AVFoundation)
    public func prepareToAnalyze(in audioFormat: AVAudioFormat?) async throws {
        _ = audioFormat
        throw speechFailClosedError(.noModel)
    }

    public func prepareToAnalyze(
        in audioFormat: AVAudioFormat?,
        withProgressReadyHandler progressReadyHandler: sending ((Progress) -> Void)?
    ) async throws {
        _ = progressReadyHandler
        try await prepareToAnalyze(in: audioFormat)
    }

    public static func bestAvailableAudioFormat(
        compatibleWith modules: [any SpeechModule]
    ) async -> AVAudioFormat? {
        _ = modules
        return nil
    }

    public static func bestAvailableAudioFormat(
        compatibleWith modules: [any SpeechModule],
        considering naturalFormat: AVAudioFormat?
    ) async -> AVAudioFormat? {
        _ = (modules, naturalFormat)
        return nil
    }

    public func start(inputAudioFile audioFile: AVAudioFile, finishAfterFile: Bool = false) async throws {
        _ = (audioFile, finishAfterFile)
        throw speechFailClosedError(.noModel)
    }

    public func analyzeSequence(from audioFile: AVAudioFile) async throws -> CMTime? {
        _ = audioFile
        throw speechFailClosedError(.noModel)
    }
#endif

#if canImport(CoreMedia)
    public var volatileRange: CMTimeRange? { nil }

    public func cancelAnalysis(before: CMTime) {
        _ = before
    }

    public func finalize(through: CMTime?) async throws {
        _ = through
        throw speechFailClosedError(.noModel)
    }

    public func finalizeAndFinish(through: CMTime) async throws {
        _ = through
        throw speechFailClosedError(.noModel)
    }

    public func finish(after: CMTime) async throws {
        _ = after
        throw speechFailClosedError(.noModel)
    }

    public func setVolatileRangeChangedHandler(
        _ handler: sending ((CMTimeRange, Bool, Bool) -> Void)?
    ) {
        _ = handler
    }
#endif
}

public final class SpeechDetector: @unchecked Sendable {
    public struct DetectionOptions: Hashable, Sendable {
        public var sensitivityLevel: SensitivityLevel
        public init(sensitivityLevel: SensitivityLevel) {
            self.sensitivityLevel = sensitivityLevel
        }
    }

    public enum SensitivityLevel: Int, Hashable, Sendable, CaseIterable {
        case low = 0
        case medium = 1
        case high = 2
    }

    public struct Result: Sendable, Hashable, CustomStringConvertible {
        public var isFinal: Bool { true }
        public let speechDetected: Bool
        public var description: String { speechDetected ? "speech" : "silence" }
#if canImport(CoreMedia)
        public let resultsFinalizationTime: CMTime
        public let range: CMTimeRange
#endif
        @_spi(OpenUIKitHost)
        public init(speechDetected: Bool) {
            self.speechDetected = speechDetected
        }
    }

    public typealias Results = SpeechEmptyResults<Result>
    public let results = SpeechEmptyResults<Result>()
    public let detectionOptions: DetectionOptions
    public let reportResults: Bool

    public convenience init() {
        self.init(
            detectionOptions: DetectionOptions(sensitivityLevel: .medium),
            reportResults: false
        )
    }

    public init(detectionOptions: DetectionOptions, reportResults: Bool) {
        self.detectionOptions = detectionOptions
        self.reportResults = reportResults
    }

#if canImport(AVFoundation)
    public var availableCompatibleAudioFormats: [AVAudioFormat] { [] }
#endif
}

public final class SpeechTranscriber: LocaleDependentSpeechModule, @unchecked Sendable {
    public enum ReportingOption: String, Hashable, Sendable, CaseIterable {
        case fastResults
        case volatileResults
        case alternativeTranscriptions
    }

    public enum TranscriptionOption: String, Hashable, Sendable, CaseIterable {
        case etiquetteReplacements
    }

    public enum ResultAttributeOption: String, Hashable, Sendable, CaseIterable {
        case audioTimeRange
        case transcriptionConfidence
    }

    public struct Preset: Hashable, Sendable {
        public var transcriptionOptions: Set<TranscriptionOption>
        public var reportingOptions: Set<ReportingOption>
        public var attributeOptions: Set<ResultAttributeOption>

        public init(
            transcriptionOptions: Set<TranscriptionOption>,
            reportingOptions: Set<ReportingOption>,
            attributeOptions: Set<ResultAttributeOption>
        ) {
            self.transcriptionOptions = transcriptionOptions
            self.reportingOptions = reportingOptions
            self.attributeOptions = attributeOptions
        }

        public static let transcription = Preset(
            transcriptionOptions: [],
            reportingOptions: [],
            attributeOptions: []
        )
        public static let progressiveTranscription = Preset(
            transcriptionOptions: [],
            reportingOptions: [.volatileResults],
            attributeOptions: []
        )
        public static let transcriptionWithAlternatives = Preset(
            transcriptionOptions: [],
            reportingOptions: [.alternativeTranscriptions],
            attributeOptions: []
        )
        public static let timeIndexedProgressiveTranscription = Preset(
            transcriptionOptions: [],
            reportingOptions: [.volatileResults],
            attributeOptions: [.audioTimeRange]
        )
        public static let timeIndexedTranscriptionWithAlternatives = Preset(
            transcriptionOptions: [],
            reportingOptions: [.alternativeTranscriptions],
            attributeOptions: [.audioTimeRange]
        )
    }

    public struct Result: SpeechModuleResult, Sendable, Hashable, CustomStringConvertible {
        public let text: AttributedString
        public let alternatives: [AttributedString]
        public let isFinal: Bool
        public var description: String { String(text.characters) }
#if canImport(CoreMedia)
        public let resultsFinalizationTime: CMTime
        public let range: CMTimeRange
#endif
        @_spi(OpenUIKitHost)
        public init(
            text: AttributedString,
            alternatives: [AttributedString] = [],
            isFinal: Bool = true
        ) {
            self.text = text
            self.alternatives = alternatives
            self.isFinal = isFinal
        }
    }

    public typealias Results = SpeechEmptyResults<Result>
    public let results = SpeechEmptyResults<Result>()
    public static var isAvailable: Bool { false }
    public private(set) var selectedLocales: [Locale]
    public let preset: Preset

    public static var supportedLocales: [Locale] { get async { [] } }
    public static var installedLocales: [Locale] { get async { [] } }

    public static func supportedLocale(equivalentTo locale: Locale) async -> Locale? {
        _ = locale
        return nil
    }

    public convenience init(locale: Locale, preset: Preset) {
        self.init(
            locale: locale,
            transcriptionOptions: preset.transcriptionOptions,
            reportingOptions: preset.reportingOptions,
            attributeOptions: preset.attributeOptions
        )
    }

    public init(
        locale: Locale,
        transcriptionOptions: Set<TranscriptionOption>,
        reportingOptions: Set<ReportingOption>,
        attributeOptions: Set<ResultAttributeOption>
    ) {
        self.selectedLocales = [locale]
        self.preset = Preset(
            transcriptionOptions: transcriptionOptions,
            reportingOptions: reportingOptions,
            attributeOptions: attributeOptions
        )
    }

#if canImport(AVFoundation)
    public var availableCompatibleAudioFormats: [AVAudioFormat] { get async { [] } }
#endif
}

public final class DictationTranscriber: LocaleDependentSpeechModule, @unchecked Sendable {
    public struct ContentHint: Hashable, Sendable {
        private let token: String

        private init(token: String) {
            self.token = token
        }

        public static let atypicalSpeech = ContentHint(token: "atypicalSpeech")
        public static let farField = ContentHint(token: "farField")
        public static let shortForm = ContentHint(token: "shortForm")

        public static func customizedLanguage(
            modelConfiguration: SFSpeechLanguageModel.Configuration
        ) -> ContentHint {
            _ = modelConfiguration
            return ContentHint(token: "customizedLanguage")
        }
    }

    public enum ReportingOption: String, Hashable, Sendable, CaseIterable {
        case volatileResults
        case frequentFinalization
        case alternativeTranscriptions
    }

    public enum TranscriptionOption: String, Hashable, Sendable, CaseIterable {
        case punctuation
        case etiquetteReplacements
        case emoji
    }

    public enum ResultAttributeOption: String, Hashable, Sendable, CaseIterable {
        case audioTimeRange
        case transcriptionConfidence
    }

    public struct Preset: Hashable, Sendable {
        public var contentHints: Set<ContentHint>
        public var transcriptionOptions: Set<TranscriptionOption>
        public var reportingOptions: Set<ReportingOption>
        public var attributeOptions: Set<ResultAttributeOption>

        public init(
            contentHints: Set<ContentHint>,
            transcriptionOptions: Set<TranscriptionOption>,
            reportingOptions: Set<ReportingOption>,
            attributeOptions: Set<ResultAttributeOption>
        ) {
            self.contentHints = contentHints
            self.transcriptionOptions = transcriptionOptions
            self.reportingOptions = reportingOptions
            self.attributeOptions = attributeOptions
        }

        public static let phrase = Preset(
            contentHints: [],
            transcriptionOptions: [],
            reportingOptions: [],
            attributeOptions: []
        )
        public static let shortDictation = Preset(
            contentHints: [.shortForm],
            transcriptionOptions: [.punctuation],
            reportingOptions: [],
            attributeOptions: []
        )
        public static let longDictation = Preset(
            contentHints: [],
            transcriptionOptions: [.punctuation],
            reportingOptions: [],
            attributeOptions: []
        )
        public static let progressiveShortDictation = Preset(
            contentHints: [.shortForm],
            transcriptionOptions: [.punctuation],
            reportingOptions: [.volatileResults],
            attributeOptions: []
        )
        public static let progressiveLongDictation = Preset(
            contentHints: [],
            transcriptionOptions: [.punctuation],
            reportingOptions: [.volatileResults],
            attributeOptions: []
        )
        public static let timeIndexedLongDictation = Preset(
            contentHints: [],
            transcriptionOptions: [.punctuation],
            reportingOptions: [],
            attributeOptions: [.audioTimeRange]
        )
    }

    public struct Result: SpeechModuleResult, Sendable, Hashable, CustomStringConvertible {
        public let text: AttributedString
        public let alternatives: [AttributedString]
        public let isFinal: Bool
        public var description: String { String(text.characters) }
#if canImport(CoreMedia)
        public let resultsFinalizationTime: CMTime
        public let range: CMTimeRange
#endif
        @_spi(OpenUIKitHost)
        public init(
            text: AttributedString,
            alternatives: [AttributedString] = [],
            isFinal: Bool = true
        ) {
            self.text = text
            self.alternatives = alternatives
            self.isFinal = isFinal
        }
    }

    public typealias Results = SpeechEmptyResults<Result>
    public let results = SpeechEmptyResults<Result>()
    public private(set) var selectedLocales: [Locale]
    public let preset: Preset

    public static var supportedLocales: [Locale] { get async { [] } }
    public static var installedLocales: [Locale] { get async { [] } }

    public static func supportedLocale(equivalentTo locale: Locale) async -> Locale? {
        _ = locale
        return nil
    }

    public convenience init(locale: Locale, preset: Preset) {
        self.init(
            locale: locale,
            contentHints: preset.contentHints,
            transcriptionOptions: preset.transcriptionOptions,
            reportingOptions: preset.reportingOptions,
            attributeOptions: preset.attributeOptions
        )
    }

    public init(
        locale: Locale,
        contentHints: Set<ContentHint>,
        transcriptionOptions: Set<TranscriptionOption>,
        reportingOptions: Set<ReportingOption>,
        attributeOptions: Set<ResultAttributeOption>
    ) {
        self.selectedLocales = [locale]
        self.preset = Preset(
            contentHints: contentHints,
            transcriptionOptions: transcriptionOptions,
            reportingOptions: reportingOptions,
            attributeOptions: attributeOptions
        )
    }

#if canImport(AVFoundation)
    public var availableCompatibleAudioFormats: [AVAudioFormat] { get async { [] } }
#endif
}

#if canImport(AVFoundation) && canImport(CoreMedia)
import AVFoundation
import CoreMedia

public struct AnalyzerInput: Sendable {
    public let buffer: AVAudioPCMBuffer
    public let bufferStartTime: CMTime?

    public init(buffer: AVAudioPCMBuffer, bufferStartTime: CMTime?) {
        self.buffer = buffer
        self.bufferStartTime = bufferStartTime
    }

    public init(buffer: AVAudioPCMBuffer) {
        self.init(buffer: buffer, bufferStartTime: nil)
    }
}
#endif
