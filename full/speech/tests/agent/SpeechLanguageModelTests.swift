@_spi(OpenUIKitHost) import Speech
import Foundation

func testSFSpeechLanguageModelConfiguration() {
    let modelURL = URL(fileURLWithPath: "/tmp/lm.bin")
    let vocabURL = URL(fileURLWithPath: "/tmp/vocab.txt")
    let short = SFSpeechLanguageModel.Configuration(languageModel: modelURL)
    precondition(short.languageModel == modelURL)
    precondition(short.vocabulary == nil)
    precondition(short.weight == nil)
    let withVocab = SFSpeechLanguageModel.Configuration(languageModel: modelURL, vocabulary: vocabURL)
    precondition(withVocab.vocabulary == vocabURL)
    let config = SFSpeechLanguageModel.Configuration(
        languageModel: modelURL,
        vocabulary: vocabURL,
        weight: NSNumber(value: 1.5)
    )
    precondition(config.languageModel.path.hasSuffix("lm.bin"))
    precondition(config.vocabulary?.path.hasSuffix("vocab.txt") == true)
    precondition(config.weight?.doubleValue == 1.5)
    precondition(SFSpeechLanguageModel.Configuration(coder: NSCoder()) == nil)
}

func testPrepareCustomLanguageModel() {
    let config = SFSpeechLanguageModel.Configuration(
        languageModel: URL(fileURLWithPath: "/tmp/lm.bin")
    )
    speechRunAsync {
        do {
            try await SFSpeechLanguageModel.prepareCustomLanguageModel(
                for: URL(fileURLWithPath: "/tmp/asset"),
                clientIdentifier: "client",
                configuration: config
            )
            fatalError("prepare should fail closed")
        } catch {
            precondition((error as? SFSpeechError)?.code == .internalServiceError)
        }
        do {
            try await SFSpeechLanguageModel.prepareCustomLanguageModel(
                for: URL(fileURLWithPath: "/tmp/asset"),
                clientIdentifier: "client",
                configuration: config,
                ignoresCache: true
            )
            fatalError("prepare should fail closed")
        } catch {
            precondition((error as? SFSpeechError)?.code == .internalServiceError)
        }
        do {
            try await SFSpeechLanguageModel.prepareCustomLanguageModel(
                for: URL(fileURLWithPath: "/tmp/asset"),
                configuration: config
            )
            fatalError("prepare should fail closed")
        } catch {
            precondition((error as? SFSpeechError)?.code == .internalServiceError)
        }
        do {
            try await SFSpeechLanguageModel.prepareCustomLanguageModel(
                for: URL(fileURLWithPath: "/tmp/asset"),
                configuration: config,
                ignoresCache: true
            )
            fatalError("prepare should fail closed")
        } catch {
            precondition((error as? SFSpeechError)?.code == .internalServiceError)
        }
    }
}
