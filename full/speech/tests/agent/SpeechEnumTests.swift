@_spi(OpenUIKitHost) import Speech
import Foundation

func testSpeechClassicEnums() {
    precondition(SFSpeechRecognitionTaskHint.unspecified.rawValue == 0)
    precondition(SFSpeechRecognitionTaskHint.dictation.rawValue == 1)
    precondition(SFSpeechRecognitionTaskHint.search.rawValue == 2)
    precondition(SFSpeechRecognitionTaskHint.confirmation.rawValue == 3)
    precondition(SFSpeechRecognitionTaskHint(rawValue: 1) == .dictation)
    precondition(SFSpeechRecognitionTaskHint.dictation != .search)
    _ = speechHash(SFSpeechRecognitionTaskHint.dictation)
    _ = SFSpeechRecognitionTaskHint.search.hashValue

    precondition(SFSpeechRecognitionTaskState.starting.rawValue == 0)
    precondition(SFSpeechRecognitionTaskState.running.rawValue == 1)
    precondition(SFSpeechRecognitionTaskState.finishing.rawValue == 2)
    precondition(SFSpeechRecognitionTaskState.canceling.rawValue == 3)
    precondition(SFSpeechRecognitionTaskState.completed.rawValue == 4)
    precondition(SFSpeechRecognitionTaskState(rawValue: 2) == .finishing)
    precondition(SFSpeechRecognitionTaskState.running != .completed)
    _ = speechHash(SFSpeechRecognitionTaskState.running)
    _ = SFSpeechRecognitionTaskState.finishing.hashValue

    precondition(SFSpeechRecognizerAuthorizationStatus.notDetermined.rawValue == 0)
    precondition(SFSpeechRecognizerAuthorizationStatus.denied.rawValue == 1)
    precondition(SFSpeechRecognizerAuthorizationStatus.restricted.rawValue == 2)
    precondition(SFSpeechRecognizerAuthorizationStatus.authorized.rawValue == 3)
    precondition(SFSpeechRecognizerAuthorizationStatus(rawValue: 3) == .authorized)
    precondition(SFSpeechRecognizerAuthorizationStatus.denied != .authorized)
    _ = speechHash(SFSpeechRecognizerAuthorizationStatus.authorized)
    _ = SFSpeechRecognizerAuthorizationStatus.restricted.hashValue
}

func testSpeechTranscriberEnums() {
    let reporting: [SpeechTranscriber.ReportingOption] = [
        .fastResults, .volatileResults, .alternativeTranscriptions,
    ]
    precondition(SpeechTranscriber.ReportingOption.allCases.count == 3)
    for option in reporting {
        precondition(SpeechTranscriber.ReportingOption.allCases.contains(option))
        _ = speechHash(option)
        _ = option.hashValue
    }
    precondition(SpeechTranscriber.ReportingOption.fastResults != .volatileResults)
    _ = SpeechTranscriber.ReportingOption.AllCases.self

    precondition(SpeechTranscriber.TranscriptionOption.allCases.contains(.etiquetteReplacements))
    precondition(SpeechTranscriber.TranscriptionOption.etiquetteReplacements == .etiquetteReplacements)
    _ = speechHash(SpeechTranscriber.TranscriptionOption.etiquetteReplacements)
    _ = SpeechTranscriber.TranscriptionOption.etiquetteReplacements.hashValue
    _ = SpeechTranscriber.TranscriptionOption.AllCases.self

    precondition(SpeechTranscriber.ResultAttributeOption.allCases.contains(.audioTimeRange))
    precondition(SpeechTranscriber.ResultAttributeOption.allCases.contains(.transcriptionConfidence))
    precondition(SpeechTranscriber.ResultAttributeOption.audioTimeRange != .transcriptionConfidence)
    _ = speechHash(SpeechTranscriber.ResultAttributeOption.audioTimeRange)
    _ = SpeechTranscriber.ResultAttributeOption.transcriptionConfidence.hashValue
    _ = SpeechTranscriber.ResultAttributeOption.AllCases.self
}

func testDictationTranscriberEnums() {
    precondition(DictationTranscriber.ReportingOption.allCases.contains(.volatileResults))
    precondition(DictationTranscriber.ReportingOption.allCases.contains(.frequentFinalization))
    precondition(DictationTranscriber.ReportingOption.allCases.contains(.alternativeTranscriptions))
    precondition(DictationTranscriber.ReportingOption.volatileResults != .frequentFinalization)
    _ = speechHash(DictationTranscriber.ReportingOption.volatileResults)
    _ = DictationTranscriber.ReportingOption.frequentFinalization.hashValue
    _ = DictationTranscriber.ReportingOption.AllCases.self

    precondition(DictationTranscriber.TranscriptionOption.allCases.contains(.punctuation))
    precondition(DictationTranscriber.TranscriptionOption.allCases.contains(.etiquetteReplacements))
    precondition(DictationTranscriber.TranscriptionOption.allCases.contains(.emoji))
    precondition(DictationTranscriber.TranscriptionOption.punctuation != .emoji)
    _ = speechHash(DictationTranscriber.TranscriptionOption.punctuation)
    _ = DictationTranscriber.TranscriptionOption.emoji.hashValue
    _ = DictationTranscriber.TranscriptionOption.AllCases.self

    precondition(DictationTranscriber.ResultAttributeOption.allCases.contains(.audioTimeRange))
    precondition(DictationTranscriber.ResultAttributeOption.allCases.contains(.transcriptionConfidence))
    precondition(DictationTranscriber.ResultAttributeOption.audioTimeRange != .transcriptionConfidence)
    _ = speechHash(DictationTranscriber.ResultAttributeOption.audioTimeRange)
    _ = DictationTranscriber.ResultAttributeOption.transcriptionConfidence.hashValue
    _ = DictationTranscriber.ResultAttributeOption.AllCases.self
}

func testSpeechDetectorSensitivityEnum() {
    precondition(SpeechDetector.SensitivityLevel.low.rawValue == 0)
    precondition(SpeechDetector.SensitivityLevel.medium.rawValue == 1)
    precondition(SpeechDetector.SensitivityLevel.high.rawValue == 2)
    precondition(SpeechDetector.SensitivityLevel(rawValue: 1) == .medium)
    precondition(SpeechDetector.SensitivityLevel.allCases.count == 3)
    precondition(SpeechDetector.SensitivityLevel.low != .high)
    _ = speechHash(SpeechDetector.SensitivityLevel.high)
    _ = SpeechDetector.SensitivityLevel.medium.hashValue
    _ = SpeechDetector.SensitivityLevel.AllCases.self
    _ = SpeechDetector.SensitivityLevel.RawValue.self
}

func testSpeechAnalyzerModelRetentionEnum() {
    precondition(SpeechAnalyzer.Options.ModelRetention.allCases.contains(.whileInUse))
    precondition(SpeechAnalyzer.Options.ModelRetention.allCases.contains(.processLifetime))
    precondition(SpeechAnalyzer.Options.ModelRetention.allCases.contains(.lingering))
    precondition(SpeechAnalyzer.Options.ModelRetention.whileInUse != .lingering)
    _ = speechHash(SpeechAnalyzer.Options.ModelRetention.processLifetime)
    _ = SpeechAnalyzer.Options.ModelRetention.lingering.hashValue
    _ = SpeechAnalyzer.Options.ModelRetention.AllCases.self
}

func testAssetInventoryStatusEnum() {
    precondition(AssetInventory.Status.unsupported < .supported)
    precondition(AssetInventory.Status.supported < .downloading)
    precondition(AssetInventory.Status.downloading < .installed)
    precondition(AssetInventory.Status.unsupported != .installed)
    precondition(AssetInventory.Status.installed == .installed)
    precondition(AssetInventory.Status.installed > .unsupported)
    precondition(AssetInventory.Status.installed >= .downloading)
    precondition(AssetInventory.Status.unsupported <= .supported)
    let closed = AssetInventory.Status.unsupported ... .installed
    precondition(closed.contains(.supported))
    let half = AssetInventory.Status.unsupported ..< .installed
    precondition(half.contains(.downloading))
    precondition(half.contains(.installed) == false)
    let from = AssetInventory.Status.supported...
    precondition(from.contains(.installed))
    let through = ...AssetInventory.Status.supported
    precondition(through.contains(.unsupported))
    let upTo = ..<AssetInventory.Status.installed
    precondition(upTo.contains(.downloading))
    _ = speechHash(AssetInventory.Status.installed)
    _ = AssetInventory.Status.supported.hashValue
}
