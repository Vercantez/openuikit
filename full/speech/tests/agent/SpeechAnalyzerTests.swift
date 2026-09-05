@_spi(OpenUIKitHost) import Speech
import Foundation

func testAnalysisContext() {
    let context = AnalysisContext()
    let topic = AnalysisContext.UserDataTag("topic")
    let rawTag = AnalysisContext.UserDataTag(rawValue: "other")
    precondition(topic.rawValue == "topic")
    precondition(rawTag.rawValue == "other")
    precondition(topic != rawTag)
    _ = speechHash(topic)
    _ = topic.hashValue
    _ = AnalysisContext.UserDataTag.RawValue.self

    let general = AnalysisContext.ContextualStringsTag.general
    let other = AnalysisContext.ContextualStringsTag("other")
    let rawStrings = AnalysisContext.ContextualStringsTag(rawValue: "custom")
    precondition(general.rawValue == "general")
    precondition(other.rawValue == "other")
    precondition(rawStrings.rawValue == "custom")
    precondition(general != other)
    _ = speechHash(general)
    _ = general.hashValue
    _ = AnalysisContext.ContextualStringsTag.RawValue.self

    context.contextualStrings[.general] = ["OpenUIKit"]
    context.userData[topic] = "speech"
    precondition(context.contextualStrings[.general] == ["OpenUIKit"])
    precondition(context.userData[topic] as? String == "speech")
}

func testSpeechAnalyzerLifecycle() {
    let transcriber = SpeechTranscriber(locale: Locale(identifier: "en-US"), preset: .transcription)
    let dictation = DictationTranscriber(locale: Locale(identifier: "en-US"), preset: .phrase)
    let options = SpeechAnalyzer.Options(priority: .medium, modelRetention: .whileInUse)
    precondition(options.priority == .medium)
    precondition(options.modelRetention == .whileInUse)
    let other = SpeechAnalyzer.Options(priority: .high, modelRetention: .lingering)
    precondition(options != other)
    precondition(options == SpeechAnalyzer.Options(priority: .medium, modelRetention: .whileInUse))
    _ = speechHash(options)

    let context = AnalysisContext()
    context.contextualStrings[.general] = ["OpenUIKit"]
    speechWaitAsync {
        let analyzer = SpeechAnalyzer(modules: [transcriber], options: options)
        try? await analyzer.setContext(context)
        let stored = await analyzer.context
        precondition(stored.contextualStrings[.general] == ["OpenUIKit"])
        try? await analyzer.setModules([dictation])
        do {
            try await analyzer.finalizeAndFinishThroughEndOfInput()
            fatalError("analyzer should fail closed")
        } catch {
            precondition((error as? SFSpeechError)?.code == .noModel)
        }
        await analyzer.cancelAndFinishNow()
        let moduleCount = await analyzer.modules.count
        precondition(moduleCount == 1)
    }
}

func testSpeechAnalyzerIsolation() {
    speechWaitAsync {
        let analyzer = SpeechAnalyzer(modules: [])
        await analyzer.hostCheckIsolation()
        _ = analyzer.unownedExecutor
    }
}

func testAssetInventory() {
    let transcriber = SpeechTranscriber(locale: Locale(identifier: "en-US"), preset: .transcription)
    speechWaitAsync {
        let status = await AssetInventory.status(forModules: [transcriber])
        precondition(status == .unsupported)
        precondition(AssetInventory.maximumReservedLocales == 0)
        let reserved = await AssetInventory.reservedLocales
        precondition(reserved.isEmpty)
        do {
            _ = try await AssetInventory.reserve(locale: Locale(identifier: "en-US"))
            fatalError("reserve should fail closed")
        } catch {
            precondition((error as? SFSpeechError)?.code == .cannotAllocateUnsupportedLocale)
        }
        let released = await AssetInventory.release(reservedLocale: Locale(identifier: "en-US"))
        precondition(released == false)
        let request = try? await AssetInventory.assetInstallationRequest(supporting: [transcriber])
        precondition(request == nil)
    }
}

func testAssetInstallationRequest() {
    let install = AssetInstallationRequest()
    precondition(install.progress.totalUnitCount == 1)
    speechWaitAsync {
        do {
            try await install.downloadAndInstall()
            fatalError("download should fail closed")
        } catch {
            precondition((error as? SFSpeechError)?.code == .internalServiceError)
        }
    }
}

func testSpeechModels() {
    speechWaitAsync {
        await SpeechModels.endRetention()
    }
}

func testSpeechModuleProtocols() {
    let transcriber = SpeechTranscriber(locale: Locale(identifier: "en-US"), preset: .transcription)
    let detector = SpeechDetector()
    let dictation = DictationTranscriber(locale: Locale(identifier: "en-US"), preset: .phrase)
    precondition(transcriber.selectedLocales.count == 1)
    precondition(dictation.selectedLocales.count == 1)
    let hostResult = SpeechTranscriber.Result(text: AttributedString("x"), isFinal: true)
    precondition(hostResult.isFinal)
    precondition(SpeechDetector.Result(speechDetected: true).isFinal)
    precondition(DictationTranscriber.Result(text: AttributedString("d"), isFinal: true).isFinal)
    _ = SpeechTranscriber.Result.self
    _ = SpeechTranscriber.Results.self
    _ = SpeechDetector.Results.self
    _ = DictationTranscriber.Results.self
    speechWaitAsync {
        let supported = await SpeechTranscriber.supportedLocales
        precondition(supported.isEmpty)
        let equivalent = await SpeechTranscriber.supportedLocale(
            equivalentTo: Locale(identifier: "en-US")
        )
        precondition(equivalent == nil)
        var iterator = transcriber.results.makeAsyncIterator()
        let next = try? await iterator.next()
        precondition(next == nil)
        var detectorIterator = detector.results.makeAsyncIterator()
        _ = try? await detectorIterator.next()
        var dictationIterator = dictation.results.makeAsyncIterator()
        _ = try? await dictationIterator.next()
    }
}
