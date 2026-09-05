import Foundation
import Translation

func testLanguageAvailabilityStatusCases() {
    let values: [LanguageAvailability.Status] = [.installed, .supported, .unsupported]
    precondition(values.count == 3)
    precondition(LanguageAvailability.Status.installed == .installed)
    precondition(LanguageAvailability.Status.supported == .supported)
    precondition(LanguageAvailability.Status.unsupported == .unsupported)
    precondition(Set(values).count == 3)
}

func testLanguageAvailabilityStatusEquality() {
    precondition(LanguageAvailability.Status.installed == .installed)
    precondition(LanguageAvailability.Status.supported == .supported)
    precondition(!(LanguageAvailability.Status.installed == .supported))
    precondition(!(LanguageAvailability.Status.supported == .unsupported))
}

func testLanguageAvailabilityStatusInequality() {
    precondition(LanguageAvailability.Status.installed != .supported)
    precondition(LanguageAvailability.Status.supported != .unsupported)
    precondition(LanguageAvailability.Status.unsupported != .installed)
    precondition(!(LanguageAvailability.Status.unsupported != .unsupported))
}

func testLanguageAvailabilityStatusHash() {
    var hasher = Hasher()
    LanguageAvailability.Status.installed.hash(into: &hasher)
    LanguageAvailability.Status.supported.hash(into: &hasher)
    LanguageAvailability.Status.unsupported.hash(into: &hasher)
    _ = hasher.finalize()
}

func testLanguageAvailabilityStatusHashValue() {
    precondition(LanguageAvailability.Status.installed.hashValue == LanguageAvailability.Status.installed.hashValue)
    precondition(LanguageAvailability.Status.supported.hashValue != LanguageAvailability.Status.unsupported.hashValue
        || LanguageAvailability.Status.supported != .unsupported)
}

func testLanguageAvailabilityType() {
    let availability = LanguageAvailability()
    precondition(type(of: availability) == LanguageAvailability.self)
}

func testLanguageAvailabilityInit() {
    let first = LanguageAvailability()
    let second = LanguageAvailability()
    precondition(first !== second)
}

func testLanguageAvailabilitySupportedLanguages() {
    let availability = LanguageAvailability()
    switch translationAwait({ await availability.supportedLanguages }) {
    case .success(let languages):
        precondition(languages.isEmpty)
    case .failure(let error):
        preconditionFailure("supportedLanguages must not throw, got \(error)")
    }
}

func testLanguageAvailabilityStatusFromTo() {
    let availability = LanguageAvailability()
    let english = translationEnglish()
    let french = translationFrench()
    switch translationAwait({ await availability.status(from: english, to: french) }) {
    case .success(let status):
        precondition(status == .unsupported)
        precondition(status != .installed)
        precondition(status != .supported)
    case .failure(let error):
        preconditionFailure("status(from:to:) must not throw, got \(error)")
    }
    switch translationAwait({
        await availability.status(from: translationEnglishUS(), to: translationEnglishGB())
    }) {
    case .success(let status):
        precondition(status == .unsupported)
    case .failure(let error):
        preconditionFailure("same-language pairing must be unsupported, got \(error)")
    }
    switch translationAwait({ await availability.status(from: english, to: nil) }) {
    case .success(let status):
        precondition(status == .unsupported)
    case .failure(let error):
        preconditionFailure("nil target must be unsupported, got \(error)")
    }
}

func testLanguageAvailabilityStatusForTo() {
    let availability = LanguageAvailability()
    let french = translationFrench()
    translationExpectError(
        translationAwait { () async throws -> LanguageAvailability.Status in
            try await availability.status(for: "", to: french)
        },
        .unableToIdentifyLanguage
    )
    translationExpectError(
        translationAwait { () async throws -> LanguageAvailability.Status in
            try await availability.status(for: "Hello, world. This is sample text.", to: french)
        },
        .unableToIdentifyLanguage
    )
    translationExpectError(
        translationAwait { () async throws -> LanguageAvailability.Status in
            try await availability.status(for: "Hallo, Welt!", to: nil)
        },
        .unableToIdentifyLanguage
    )
}
