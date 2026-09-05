@_spi(OpenUIKitHost) import Speech
import Foundation

func testSpeechTranscriberPresets() {
    let custom = SpeechTranscriber.Preset(
        transcriptionOptions: [.etiquetteReplacements],
        reportingOptions: [.volatileResults],
        attributeOptions: [.audioTimeRange]
    )
    precondition(custom.transcriptionOptions.contains(.etiquetteReplacements))
    precondition(custom.reportingOptions.contains(.volatileResults))
    precondition(custom.attributeOptions.contains(.audioTimeRange))
    precondition(SpeechTranscriber.Preset.transcription != .progressiveTranscription)
    precondition(SpeechTranscriber.Preset.transcription == .transcription)
    _ = SpeechTranscriber.Preset.progressiveTranscription
    _ = SpeechTranscriber.Preset.transcriptionWithAlternatives
    _ = SpeechTranscriber.Preset.timeIndexedProgressiveTranscription
    _ = SpeechTranscriber.Preset.timeIndexedTranscriptionWithAlternatives
    _ = speechHash(custom)
    _ = custom.hashValue
}

func testSpeechTranscriberRuntime() {
    let transcriber = SpeechTranscriber(locale: Locale(identifier: "en-US"), preset: .transcription)
    precondition(SpeechTranscriber.isAvailable == false)
    precondition(transcriber.selectedLocales.count == 1)
    let explicit = SpeechTranscriber(
        locale: Locale(identifier: "en-US"),
        transcriptionOptions: [.etiquetteReplacements],
        reportingOptions: [.fastResults],
        attributeOptions: [.transcriptionConfidence]
    )
    precondition(explicit.preset.transcriptionOptions.contains(.etiquetteReplacements))
    let hostResult = SpeechTranscriber.Result(text: AttributedString("x"), isFinal: true)
    precondition(hostResult.description == "x")
    precondition(hostResult.isFinal)
    precondition(hostResult.text.characters.elementsEqual("x"))
    precondition(hostResult.alternatives.isEmpty)
    precondition(hostResult != SpeechTranscriber.Result(text: AttributedString("y"), isFinal: false))
    _ = speechHash(hostResult)
    _ = hostResult.hashValue
    _ = SpeechTranscriber.Results.self
    speechRunAsync {
        let supported = await SpeechTranscriber.supportedLocales
        precondition(supported.isEmpty)
        let installed = await SpeechTranscriber.installedLocales
        precondition(installed.isEmpty)
        let equivalent = await SpeechTranscriber.supportedLocale(equivalentTo: Locale(identifier: "en-US"))
        precondition(equivalent == nil)
        var iterator = transcriber.results.makeAsyncIterator()
        let first = try? await iterator.next()
        precondition(first == nil)
    }
}

func testDictationTranscriberPresets() {
    let custom = DictationTranscriber.Preset(
        contentHints: [.shortForm, .farField, .atypicalSpeech],
        transcriptionOptions: [.punctuation],
        reportingOptions: [.volatileResults],
        attributeOptions: [.audioTimeRange]
    )
    precondition(custom.contentHints.contains(.shortForm))
    precondition(custom.transcriptionOptions.contains(.punctuation))
    precondition(custom.reportingOptions.contains(.volatileResults))
    precondition(custom.attributeOptions.contains(.audioTimeRange))
    precondition(DictationTranscriber.Preset.phrase != .shortDictation)
    _ = DictationTranscriber.Preset.shortDictation
    _ = DictationTranscriber.Preset.longDictation
    _ = DictationTranscriber.Preset.progressiveShortDictation
    _ = DictationTranscriber.Preset.progressiveLongDictation
    _ = DictationTranscriber.Preset.timeIndexedLongDictation
    _ = speechHash(custom)
    _ = custom.hashValue
    precondition(DictationTranscriber.ContentHint.farField != .shortForm)
    precondition(DictationTranscriber.ContentHint.atypicalSpeech != .farField)
    _ = speechHash(DictationTranscriber.ContentHint.shortForm)
    _ = DictationTranscriber.ContentHint.farField.hashValue
    _ = DictationTranscriber.ContentHint.customizedLanguage(
        modelConfiguration: SFSpeechLanguageModel.Configuration(
            languageModel: URL(fileURLWithPath: "/tmp/lm.bin")
        )
    )
}

func testDictationTranscriberRuntime() {
    let dictation = DictationTranscriber(locale: Locale(identifier: "en-US"), preset: .phrase)
    precondition(dictation.preset == .phrase)
    precondition(dictation.selectedLocales.count == 1)
    let explicit = DictationTranscriber(
        locale: Locale(identifier: "en-US"),
        contentHints: [.farField],
        transcriptionOptions: [.emoji],
        reportingOptions: [.frequentFinalization],
        attributeOptions: [.transcriptionConfidence]
    )
    precondition(explicit.preset.contentHints.contains(.farField))
    let result = DictationTranscriber.Result(text: AttributedString("dictation"), isFinal: true)
    precondition(result.description == "dictation")
    precondition(result.isFinal)
    precondition(result.alternatives.isEmpty)
    precondition(result != DictationTranscriber.Result(text: AttributedString("other"), isFinal: false))
    _ = speechHash(result)
    _ = result.hashValue
    _ = DictationTranscriber.Results.self
    speechRunAsync {
        let supported = await DictationTranscriber.supportedLocales
        precondition(supported.isEmpty)
        let installed = await DictationTranscriber.installedLocales
        precondition(installed.isEmpty)
        let equivalent = await DictationTranscriber.supportedLocale(
            equivalentTo: Locale(identifier: "en-US")
        )
        precondition(equivalent == nil)
        var iterator = dictation.results.makeAsyncIterator()
        let first = try? await iterator.next()
        precondition(first == nil)
    }
}

func testSpeechDetectorRuntime() {
    let detector = SpeechDetector()
    precondition(detector.detectionOptions.sensitivityLevel == .medium)
    let options = SpeechDetector.DetectionOptions(sensitivityLevel: .high)
    precondition(options.sensitivityLevel == .high)
    precondition(options != SpeechDetector.DetectionOptions(sensitivityLevel: .low))
    _ = speechHash(options)
    _ = options.hashValue
    let detector2 = SpeechDetector(detectionOptions: options, reportResults: true)
    precondition(detector2.reportResults)
    precondition(detector2.detectionOptions == options)
    let detected = SpeechDetector.Result(speechDetected: false)
    precondition(detected.description == "silence")
    precondition(detected.speechDetected == false)
    precondition(detected.isFinal)
    _ = SpeechDetector.Results.self
    speechRunAsync {
        var iterator = detector.results.makeAsyncIterator()
        let first = try? await iterator.next()
        precondition(first == nil)
    }
}

func testSpeechDetectorOptionsHashable() {
    let low = SpeechDetector.DetectionOptions(sensitivityLevel: .low)
    let high = SpeechDetector.DetectionOptions(sensitivityLevel: .high)
    precondition(low != high)
    precondition(low == SpeechDetector.DetectionOptions(sensitivityLevel: .low))
    _ = speechHash(low)
    _ = low.hashValue
}
