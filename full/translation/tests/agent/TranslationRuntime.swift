import Foundation
import Translation

enum TranslationRuntime {
    static func main() async {
        runErrorSurface()
        await runLanguageAvailability()
        runConfigurationAndPayloads()
        await runSessionFailClosed()
        await runBatchSequence()
        print("TRANSLATION_AGENT_RUNTIME_OK")
    }

    private static func runErrorSurface() {
        let cases: [TranslationError] = [
            .internalError,
            .notInstalled,
            .alreadyCancelled,
            .nothingToTranslate,
            .unableToIdentifyLanguage,
            .unsupportedSourceLanguage,
            .unsupportedTargetLanguage,
            .unsupportedLanguagePairing,
        ]
        for item in cases {
            precondition(item.errorDescription != nil && !(item.errorDescription!.isEmpty))
            precondition(item.failureReason == item.errorDescription)
            precondition(item.helpAnchor == nil)
            precondition(item.recoverySuggestion == nil)
            precondition(!item.localizedDescription.isEmpty)
            precondition(item ~= item)
        }

        let boxed: any Error = TranslationError.notInstalled
        precondition(TranslationError.notInstalled ~= boxed)
        precondition(!(TranslationError.internalError ~= boxed))
        precondition(!(TranslationError.notInstalled ~= NSError(domain: "x", code: 1)))

        switch boxed {
        case TranslationError.notInstalled:
            break
        default:
            fatalError("pattern match failed for TranslationError.notInstalled")
        }
    }

    private static func runLanguageAvailability() async {
        let availability = LanguageAvailability()
        let languages = await availability.supportedLanguages
        precondition(languages.isEmpty)

        let english = Locale.Language(identifier: "en-US")
        let french = Locale.Language(identifier: "fr-FR")
        let fromStatus = await availability.status(from: english, to: french)
        precondition(fromStatus == .unsupported)
        precondition(fromStatus != .installed)
        precondition(fromStatus != .supported)
        let nilTarget = await availability.status(from: english, to: nil)
        precondition(nilTarget == .unsupported)

        do {
            _ = try await availability.status(for: "Hallo, Welt! This is a longer sample.", to: english)
            fatalError("status(for:to:) must fail closed without language identification")
        } catch {
            precondition(TranslationError.unableToIdentifyLanguage ~= error)
        }

        let statuses: [LanguageAvailability.Status] = [.unsupported, .installed, .supported]
        precondition(statuses[0] == .unsupported)
        precondition(LanguageAvailability.Status.installed != .supported)
        var hasher = Hasher()
        LanguageAvailability.Status.installed.hash(into: &hasher)
        LanguageAvailability.Status.supported.hash(into: &hasher)
        precondition(LanguageAvailability.Status.installed.hashValue == LanguageAvailability.Status.installed.hashValue)
        precondition(Set(statuses).count == 3)
    }

    private static func runConfigurationAndPayloads() {
        var configuration = TranslationSession.Configuration()
        precondition(configuration.source == nil)
        precondition(configuration.target == nil)
        precondition(configuration.version == 0)

        let source = Locale.Language(identifier: "en-US")
        let target = Locale.Language(identifier: "de-DE")
        configuration.source = source
        configuration.target = target
        let original = configuration
        precondition(original == configuration)
        configuration.invalidate()
        precondition(configuration.version == 1)
        precondition(original != configuration)
        precondition(configuration.source == source)
        precondition(configuration.target == target)

        let samePair = TranslationSession.Configuration(source: source, target: target)
        precondition(samePair != configuration)
        var copy = samePair
        copy.invalidate()
        copy.invalidate()
        precondition(copy.version == 2)
        precondition(copy != samePair)

        var request = TranslationSession.Request(sourceText: "Hello")
        precondition(request.sourceText == "Hello")
        precondition(request.clientIdentifier == nil)
        request.clientIdentifier = "req-1"
        request.sourceText = "Hallo"
        let identified = TranslationSession.Request(
            sourceText: "Hallo",
            clientIdentifier: "req-1"
        )
        precondition(identified.clientIdentifier == "req-1")
        precondition(identified.sourceText == request.sourceText)

        let response = TranslationSession.Response(
            sourceLanguage: source,
            targetLanguage: target,
            sourceText: "Hello",
            targetText: "Hallo",
            clientIdentifier: "req-1"
        )
        precondition(response.sourceLanguage == source)
        precondition(response.targetLanguage == target)
        precondition(response.sourceText == "Hello")
        precondition(response.targetText == "Hallo")
        precondition(response.clientIdentifier == "req-1")
        let preview = TranslationSession.Response(
            sourceLanguage: source,
            targetLanguage: target,
            sourceText: "Hello",
            targetText: "Hallo"
        )
        precondition(preview.clientIdentifier == nil)
    }

    private static func runSessionFailClosed() async {
        let englishUS = Locale.Language(identifier: "en-US")
        let englishGB = Locale.Language(identifier: "en-GB")
        let german = Locale.Language(identifier: "de-DE")

        let session = TranslationSession(installedSource: englishUS, target: german)
        precondition(session.sourceLanguage == englishUS)
        precondition(session.targetLanguage == german)
        precondition(session.canRequestDownloads == false)
        let ready = await session.isReady
        precondition(ready == false)

        do {
            try await session.prepareTranslation()
            fatalError("prepareTranslation must fail closed")
        } catch {
            precondition(TranslationError.notInstalled ~= error)
        }

        do {
            _ = try await session.translate("Hello, world")
            fatalError("translate(_:) must fail closed")
        } catch {
            precondition(TranslationError.notInstalled ~= error)
        }

        do {
            _ = try await session.translate("")
            fatalError("empty translate(_:) must throw nothingToTranslate")
        } catch {
            precondition(TranslationError.nothingToTranslate ~= error)
        }

        let requests = [
            TranslationSession.Request(sourceText: "Hello", clientIdentifier: "a"),
            TranslationSession.Request(sourceText: "World", clientIdentifier: "b"),
        ]
        do {
            _ = try await session.translations(from: requests)
            fatalError("translations(from:) must fail closed")
        } catch {
            precondition(TranslationError.notInstalled ~= error)
        }

        do {
            _ = try await session.translations(from: [])
            fatalError("empty translations(from:) must throw nothingToTranslate")
        } catch {
            precondition(TranslationError.nothingToTranslate ~= error)
        }

        do {
            _ = try await session.translations(
                from: [TranslationSession.Request(sourceText: "")]
            )
            fatalError("blank batch item must throw nothingToTranslate")
        } catch {
            precondition(TranslationError.nothingToTranslate ~= error)
        }

        let sameLanguage = TranslationSession(installedSource: englishUS, target: englishGB)
        do {
            _ = try await sameLanguage.translate("Hello")
            fatalError("same-language pairing must fail closed")
        } catch {
            precondition(TranslationError.unsupportedLanguagePairing ~= error)
        }

        session.cancel()
        do {
            try await session.prepareTranslation()
            fatalError("cancelled prepareTranslation must throw alreadyCancelled")
        } catch {
            precondition(TranslationError.alreadyCancelled ~= error)
        }
        do {
            _ = try await session.translate("Hello")
            fatalError("cancelled translate(_:) must throw alreadyCancelled")
        } catch {
            precondition(TranslationError.alreadyCancelled ~= error)
        }
        session.cancel()
        do {
            _ = try await session.translations(from: requests)
            fatalError("cancelled translations(from:) must throw alreadyCancelled")
        } catch {
            precondition(TranslationError.alreadyCancelled ~= error)
        }
    }

    private static func runBatchSequence() async {
        let english = Locale.Language(identifier: "en-US")
        let spanish = Locale.Language(identifier: "es-ES")
        let session = TranslationSession(installedSource: english, target: spanish)
        let requests = [
            TranslationSession.Request(sourceText: "Hello", clientIdentifier: "1"),
            TranslationSession.Request(sourceText: "Thanks", clientIdentifier: "2"),
        ]

        let sequence = session.translate(batch: requests)
        let _: TranslationSession.BatchResponse.Element.Type = TranslationSession.Response.self
        let _: TranslationSession.BatchResponse.AsyncIterator.Element.Type =
            TranslationSession.Response.self

        var iterator = sequence.makeAsyncIterator()
        do {
            _ = try await iterator.next()
            fatalError("batch next() must fail closed")
        } catch {
            precondition(TranslationError.notInstalled ~= error)
        }
        let ended = try? await iterator.next()
        precondition(ended == nil)

        do {
            for try await _ in session.translate(batch: requests) {
                fatalError("for-await must not yield fabricated translations")
            }
            fatalError("for-await must throw")
        } catch {
            precondition(TranslationError.notInstalled ~= error)
        }

        var isolationIterator = session.translate(batch: requests).makeAsyncIterator()
        do {
            _ = try await isolationIterator.next(isolation: nil)
            fatalError("next(isolation:) must fail closed")
        } catch {
            precondition(TranslationError.notInstalled ~= error)
        }

        let cancelled = TranslationSession(installedSource: english, target: spanish)
        cancelled.cancel()
        var cancelledIterator = cancelled.translate(batch: requests).makeAsyncIterator()
        do {
            _ = try await cancelledIterator.next()
            fatalError("cancelled batch must throw alreadyCancelled")
        } catch {
            precondition(TranslationError.alreadyCancelled ~= error)
        }

        var emptyIterator = session.translate(batch: []).makeAsyncIterator()
        do {
            _ = try await emptyIterator.next()
            fatalError("empty batch must throw nothingToTranslate")
        } catch {
            precondition(TranslationError.nothingToTranslate ~= error)
        }

        // Combinators are stdlib overlays on AsyncSequence. Forming them proves
        // the conformance compiles; iteration still fail-closes.
        let mapped = session.translate(batch: requests).map { $0.sourceText }
        do {
            _ = try await mapped.contains(where: { $0 == "Hello" })
            fatalError("mapped contains(where:) must fail closed")
        } catch {
            precondition(TranslationError.notInstalled ~= error)
        }
    }
}

await TranslationRuntime.main()
