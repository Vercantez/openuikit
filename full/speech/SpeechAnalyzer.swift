public protocol SpeechModuleResult: Sendable {
    var resultsFinalizationTime: CMTime { get }
    var range: CMTimeRange { get }
}

extension SpeechModuleResult {
    public var isFinal: Bool { resultsFinalizationTime.isNumeric }
}

public protocol SpeechModule: AnyObject, Sendable {
    associatedtype Result: SpeechModuleResult & Sendable
    associatedtype Results: Sendable & AsyncSequence
        where Results.Element == Result, Results.Failure == any Error

    var results: Results { get }
    var availableCompatibleAudioFormats: [AVAudioFormat] { get async }
}

public protocol LocaleDependentSpeechModule: SpeechModule {
    var selectedLocales: [Locale] { get }
    static var supportedLocales: [Locale] { get async }
    static func supportedLocale(equivalentTo locale: Locale) async -> Locale?
}

public struct SpeechEmptyResults<Element: Sendable>: Sendable, AsyncSequence {
    public typealias Failure = any Error

    public struct Iterator: AsyncIteratorProtocol {
        public mutating func next() async throws -> Element? { nil }
    }

    public func makeAsyncIterator() -> Iterator { Iterator() }
}

public struct AnalyzerInput: Sendable {
    public let buffer: AVAudioPCMBuffer
    public let bufferStartTime: CMTime?

    public init(buffer: AVAudioPCMBuffer) {
        self.buffer = buffer
        self.bufferStartTime = nil
    }

    public init(buffer: AVAudioPCMBuffer, bufferStartTime: CMTime?) {
        self.buffer = buffer
        self.bufferStartTime = bufferStartTime
    }
}

public final class AnalysisContext: @unchecked Sendable {
    public struct UserDataTag: RawRepresentable, Hashable, Sendable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public init(_ rawValue: String) { self.rawValue = rawValue }
    }

    public struct ContextualStringsTag: RawRepresentable, Hashable, Sendable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public init(_ rawValue: String) { self.rawValue = rawValue }
        public static let general = ContextualStringsTag("general")
    }

    public var contextualStrings: [ContextualStringsTag: [String]] = [:]
    public var userData: [UserDataTag: any Sendable] = [:]

    public init() {}
}

public final class AssetInstallationRequest: @unchecked Sendable {
    public let progress: Progress

    init(progress: Progress = Progress(totalUnitCount: 1)) {
        self.progress = progress
        progress.isCancellable = false
    }

    public func downloadAndInstall() async throws {
        throw SpeechPortable.failClosedError(
            .noModel,
            reason: "Speech asset download is unavailable on this host"
        )
    }
}

public final class AssetInventory: Sendable {
    public enum Status: Hashable, Sendable, Comparable {
        case unsupported
        case supported
        case downloading
        case installed
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
    public static func reserve(locale: Locale) async throws -> Bool {
        _ = locale
        throw SpeechPortable.failClosedError(
            .cannotAllocateUnsupportedLocale,
            reason: "Speech locales cannot be reserved on this host"
        )
    }

    @discardableResult
    public static func release(reservedLocale: Locale) async -> Bool {
        _ = reservedLocale
        return false
    }
}

public final class SpeechTranscriber: LocaleDependentSpeechModule, @unchecked Sendable {
    public enum ReportingOption: Hashable, Sendable, CaseIterable {
        case fastResults
        case volatileResults
        case alternativeTranscriptions
    }

    public enum TranscriptionOption: Hashable, Sendable, CaseIterable {
        case etiquetteReplacements
    }

    public enum ResultAttributeOption: Hashable, Sendable, CaseIterable {
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
            reportingOptions: [.volatileResults, .fastResults],
            attributeOptions: []
        )
        public static let transcriptionWithAlternatives = Preset(
            transcriptionOptions: [],
            reportingOptions: [.alternativeTranscriptions],
            attributeOptions: []
        )
        public static let timeIndexedProgressiveTranscription = Preset(
            transcriptionOptions: [],
            reportingOptions: [.volatileResults, .fastResults],
            attributeOptions: [.audioTimeRange]
        )
        public static let timeIndexedTranscriptionWithAlternatives = Preset(
            transcriptionOptions: [],
            reportingOptions: [.alternativeTranscriptions],
            attributeOptions: [.audioTimeRange]
        )
    }

    public struct Result: SpeechModuleResult, Hashable, Sendable, CustomStringConvertible {
        public let text: AttributedString
        public let alternatives: [AttributedString]
        public let range: CMTimeRange
        public let resultsFinalizationTime: CMTime

        public init(
            text: AttributedString,
            alternatives: [AttributedString],
            range: CMTimeRange,
            resultsFinalizationTime: CMTime
        ) {
            self.text = text
            self.alternatives = alternatives
            self.range = range
            self.resultsFinalizationTime = resultsFinalizationTime
        }

        public var description: String { String(text.characters) }
    }

    public typealias Results = SpeechEmptyResults<Result>

    public let selectedLocales: [Locale]
    public let transcriptionOptions: Set<TranscriptionOption>
    public let reportingOptions: Set<ReportingOption>
    public let attributeOptions: Set<ResultAttributeOption>
    public let results = SpeechEmptyResults<Result>()

    public static var isAvailable: Bool { false }

    public static var supportedLocales: [Locale] {
        get async { [] }
    }

    public static var installedLocales: [Locale] {
        get async { [] }
    }

    public var availableCompatibleAudioFormats: [AVAudioFormat] {
        get async { [] }
    }

    public static func supportedLocale(equivalentTo locale: Locale) async -> Locale? {
        _ = locale
        return nil
    }

    public convenience init(
        locale: Locale,
        transcriptionOptions: Set<TranscriptionOption>,
        reportingOptions: Set<ReportingOption>,
        attributeOptions: Set<ResultAttributeOption>
    ) {
        self.init(
            locales: [locale],
            transcriptionOptions: transcriptionOptions,
            reportingOptions: reportingOptions,
            attributeOptions: attributeOptions
        )
    }

    public convenience init(locale: Locale, preset: Preset) {
        self.init(
            locale: locale,
            transcriptionOptions: preset.transcriptionOptions,
            reportingOptions: preset.reportingOptions,
            attributeOptions: preset.attributeOptions
        )
    }

    init(
        locales: [Locale],
        transcriptionOptions: Set<TranscriptionOption>,
        reportingOptions: Set<ReportingOption>,
        attributeOptions: Set<ResultAttributeOption>
    ) {
        self.selectedLocales = locales
        self.transcriptionOptions = transcriptionOptions
        self.reportingOptions = reportingOptions
        self.attributeOptions = attributeOptions
    }
}

public final class DictationTranscriber: LocaleDependentSpeechModule, @unchecked Sendable {
    public struct ContentHint: Hashable, Sendable {
        enum Kind: Hashable, Sendable {
            case atypicalSpeech
            case farField
            case shortForm
            case customizedLanguage(URL)
        }

        let kind: Kind

        public static let atypicalSpeech = ContentHint(kind: .atypicalSpeech)
        public static let farField = ContentHint(kind: .farField)
        public static let shortForm = ContentHint(kind: .shortForm)

        public static func customizedLanguage(
            modelConfiguration: SFSpeechLanguageModel.Configuration
        ) -> ContentHint {
            ContentHint(kind: .customizedLanguage(modelConfiguration.languageModel))
        }
    }

    public enum ReportingOption: Hashable, Sendable, CaseIterable {
        case volatileResults
        case frequentFinalization
        case alternativeTranscriptions
    }

    public enum TranscriptionOption: Hashable, Sendable, CaseIterable {
        case punctuation
        case etiquetteReplacements
        case emoji
    }

    public enum ResultAttributeOption: Hashable, Sendable, CaseIterable {
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
            contentHints: [.shortForm],
            transcriptionOptions: [.punctuation],
            reportingOptions: [],
            attributeOptions: []
        )
        public static let shortDictation = Preset(
            contentHints: [.shortForm],
            transcriptionOptions: [.punctuation, .etiquetteReplacements],
            reportingOptions: [],
            attributeOptions: []
        )
        public static let longDictation = Preset(
            contentHints: [],
            transcriptionOptions: [.punctuation, .etiquetteReplacements, .emoji],
            reportingOptions: [],
            attributeOptions: []
        )
        public static let progressiveShortDictation = Preset(
            contentHints: [.shortForm],
            transcriptionOptions: [.punctuation],
            reportingOptions: [.volatileResults, .frequentFinalization],
            attributeOptions: []
        )
        public static let progressiveLongDictation = Preset(
            contentHints: [],
            transcriptionOptions: [.punctuation, .etiquetteReplacements],
            reportingOptions: [.volatileResults, .frequentFinalization],
            attributeOptions: []
        )
        public static let timeIndexedLongDictation = Preset(
            contentHints: [],
            transcriptionOptions: [.punctuation, .etiquetteReplacements],
            reportingOptions: [],
            attributeOptions: [.audioTimeRange]
        )
    }

    public struct Result: SpeechModuleResult, Hashable, Sendable, CustomStringConvertible {
        public let text: AttributedString
        public let alternatives: [AttributedString]
        public let range: CMTimeRange
        public let resultsFinalizationTime: CMTime

        public init(
            text: AttributedString,
            alternatives: [AttributedString],
            range: CMTimeRange,
            resultsFinalizationTime: CMTime
        ) {
            self.text = text
            self.alternatives = alternatives
            self.range = range
            self.resultsFinalizationTime = resultsFinalizationTime
        }

        public var description: String { String(text.characters) }
    }

    public typealias Results = SpeechEmptyResults<Result>

    public let selectedLocales: [Locale]
    public let contentHints: Set<ContentHint>
    public let transcriptionOptions: Set<TranscriptionOption>
    public let reportingOptions: Set<ReportingOption>
    public let attributeOptions: Set<ResultAttributeOption>
    public let results = SpeechEmptyResults<Result>()

    public static var supportedLocales: [Locale] {
        get async { [] }
    }

    public static var installedLocales: [Locale] {
        get async { [] }
    }

    public var availableCompatibleAudioFormats: [AVAudioFormat] {
        get async { [] }
    }

    public static func supportedLocale(equivalentTo locale: Locale) async -> Locale? {
        _ = locale
        return nil
    }

    public convenience init(
        locale: Locale,
        contentHints: Set<ContentHint>,
        transcriptionOptions: Set<TranscriptionOption>,
        reportingOptions: Set<ReportingOption>,
        attributeOptions: Set<ResultAttributeOption>
    ) {
        self.init(
            locales: [locale],
            contentHints: contentHints,
            transcriptionOptions: transcriptionOptions,
            reportingOptions: reportingOptions,
            attributeOptions: attributeOptions
        )
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

    init(
        locales: [Locale],
        contentHints: Set<ContentHint>,
        transcriptionOptions: Set<TranscriptionOption>,
        reportingOptions: Set<ReportingOption>,
        attributeOptions: Set<ResultAttributeOption>
    ) {
        self.selectedLocales = locales
        self.contentHints = contentHints
        self.transcriptionOptions = transcriptionOptions
        self.reportingOptions = reportingOptions
        self.attributeOptions = attributeOptions
    }
}

public final class SpeechDetector: SpeechModule, @unchecked Sendable {
    public enum SensitivityLevel: Int, Hashable, Sendable, CaseIterable {
        case low = 0
        case medium = 1
        case high = 2
    }

    public struct DetectionOptions: Hashable, Sendable {
        public let sensitivityLevel: SensitivityLevel

        public init(sensitivityLevel: SensitivityLevel) {
            self.sensitivityLevel = sensitivityLevel
        }
    }

    public struct Result: SpeechModuleResult, Hashable, Sendable, CustomStringConvertible {
        public let speechDetected: Bool
        public let range: CMTimeRange
        public let resultsFinalizationTime: CMTime

        public init(
            speechDetected: Bool,
            range: CMTimeRange,
            resultsFinalizationTime: CMTime
        ) {
            self.speechDetected = speechDetected
            self.range = range
            self.resultsFinalizationTime = resultsFinalizationTime
        }

        public var description: String {
            speechDetected ? "speechDetected" : "noSpeech"
        }
    }

    public typealias Results = SpeechEmptyResults<Result>

    public let detectionOptions: DetectionOptions
    public let reportResults: Bool
    public let results = SpeechEmptyResults<Result>()
    public let availableCompatibleAudioFormats: [AVAudioFormat] = []

    public convenience init() {
        self.init(
            detectionOptions: DetectionOptions(sensitivityLevel: .medium),
            reportResults: true
        )
    }

    public init(detectionOptions: DetectionOptions, reportResults: Bool) {
        self.detectionOptions = detectionOptions
        self.reportResults = reportResults
    }
}

public final actor SpeechAnalyzer {
    public struct Options: Hashable, Sendable {
        public enum ModelRetention: Hashable, Sendable, CaseIterable {
            case whileInUse
            case lingering
            case processLifetime
        }

        public let priority: TaskPriority
        public let modelRetention: ModelRetention

        public init(priority: TaskPriority, modelRetention: ModelRetention) {
            self.priority = priority
            self.modelRetention = modelRetention
        }

        public static func == (lhs: Options, rhs: Options) -> Bool {
            lhs.priority.rawValue == rhs.priority.rawValue
                && lhs.modelRetention == rhs.modelRetention
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(priority.rawValue)
            hasher.combine(modelRetention)
        }
    }

    public private(set) var modules: [any SpeechModule]
    private var storedContext: AnalysisContext
    private var options: Options?
    public private(set) var volatileRange: CMTimeRange?
    private var volatileRangeChangedHandler: ((CMTimeRange, Bool, Bool) -> Void)?

    public var context: AnalysisContext {
        get async { storedContext }
    }

    public init(modules: [any SpeechModule], options: Options? = nil) {
        self.init(
            modules: modules,
            options: options,
            analysisContext: AnalysisContext(),
            volatileRangeChangedHandler: nil
        )
    }

    public init<InputSequence>(
        inputSequence: InputSequence,
        modules: [any SpeechModule],
        options: Options? = nil,
        analysisContext: AnalysisContext = .init(),
        volatileRangeChangedHandler: sending ((CMTimeRange, Bool, Bool) -> Void)? = nil
    ) where InputSequence: Sendable, InputSequence: AsyncSequence, InputSequence.Element == AnalyzerInput {
        self.init(
            modules: modules,
            options: options,
            analysisContext: analysisContext,
            volatileRangeChangedHandler: volatileRangeChangedHandler
        )
        _ = inputSequence
    }

    public init(
        inputAudioFile: AVAudioFile,
        modules: [any SpeechModule],
        options: Options? = nil,
        analysisContext: AnalysisContext = .init(),
        finishAfterFile: Bool = false,
        volatileRangeChangedHandler: sending ((CMTimeRange, Bool, Bool) -> Void)? = nil
    ) async throws {
        _ = (inputAudioFile, finishAfterFile)
        self.init(
            modules: modules,
            options: options,
            analysisContext: analysisContext,
            volatileRangeChangedHandler: volatileRangeChangedHandler
        )
        throw SpeechPortable.failClosedError(
            .noModel,
            reason: "SpeechAnalyzer cannot read audio files without a speech model"
        )
    }

    init(
        modules: [any SpeechModule],
        options: Options?,
        analysisContext: AnalysisContext,
        volatileRangeChangedHandler: ((CMTimeRange, Bool, Bool) -> Void)?
    ) {
        self.modules = modules
        self.options = options
        self.storedContext = analysisContext
        self.volatileRangeChangedHandler = volatileRangeChangedHandler
        self.volatileRange = nil
    }

    public func setContext(_ newContext: AnalysisContext) async throws {
        storedContext = newContext
    }

    public func setModules(_ newModules: [any SpeechModule]) async throws {
        modules = newModules
    }

    public func setVolatileRangeChangedHandler(
        _ handler: sending ((CMTimeRange, Bool, Bool) -> Void)?
    ) {
        volatileRangeChangedHandler = handler
    }

    public static func bestAvailableAudioFormat(
        compatibleWith modules: [any SpeechModule]
    ) async -> AVAudioFormat? {
        await bestAvailableAudioFormat(compatibleWith: modules, considering: nil)
    }

    public static func bestAvailableAudioFormat(
        compatibleWith modules: [any SpeechModule],
        considering naturalFormat: AVAudioFormat?
    ) async -> AVAudioFormat? {
        _ = (modules, naturalFormat)
        return nil
    }

    public func prepareToAnalyze(in audioFormat: AVAudioFormat?) async throws {
        try await prepareToAnalyze(in: audioFormat, withProgressReadyHandler: nil)
    }

    public func prepareToAnalyze(
        in audioFormat: AVAudioFormat?,
        withProgressReadyHandler progressReadyHandler: sending ((Progress) -> Void)?
    ) async throws {
        _ = (audioFormat, progressReadyHandler)
        throw SpeechPortable.failClosedError(
            .noModel,
            reason: "SpeechAnalyzer has no on-device model on this host"
        )
    }

    public func analyzeSequence<InputSequence>(
        _ inputSequence: InputSequence
    ) async throws -> CMTime? where InputSequence: Sendable, InputSequence: AsyncSequence, InputSequence.Element == AnalyzerInput {
        _ = inputSequence
        throw SpeechPortable.failClosedError(
            .noModel,
            reason: "SpeechAnalyzer cannot analyze audio without a speech model"
        )
    }

    public func analyzeSequence(from audioFile: AVAudioFile) async throws -> CMTime? {
        _ = audioFile
        throw SpeechPortable.failClosedError(
            .audioReadFailed,
            reason: "SpeechAnalyzer cannot decode audio files on this host"
        )
    }

    public func start<InputSequence>(
        inputSequence: InputSequence
    ) async throws where InputSequence: Sendable, InputSequence: AsyncSequence, InputSequence.Element == AnalyzerInput {
        _ = inputSequence
        throw SpeechPortable.failClosedError(
            .noModel,
            reason: "SpeechAnalyzer cannot start without a speech model"
        )
    }

    public func start(
        inputAudioFile audioFile: AVAudioFile,
        finishAfterFile: Bool = false
    ) async throws {
        _ = (audioFile, finishAfterFile)
        throw SpeechPortable.failClosedError(
            .noModel,
            reason: "SpeechAnalyzer cannot start an audio file without a speech model"
        )
    }

    public func cancelAnalysis(before: CMTime) {
        _ = before
        volatileRange = nil
    }

    public func cancelAndFinishNow() async {
        volatileRange = nil
    }

    public func finalize(through: CMTime?) async throws {
        _ = through
    }

    public func finalizeAndFinish(through: CMTime) async throws {
        _ = through
        volatileRange = nil
    }

    public func finalizeAndFinishThroughEndOfInput() async throws {
        volatileRange = nil
    }

    public func finish(after: CMTime) async throws {
        _ = after
        volatileRange = nil
    }
}
