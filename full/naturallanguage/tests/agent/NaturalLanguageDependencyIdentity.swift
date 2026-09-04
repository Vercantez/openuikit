import Foundation
import NaturalLanguage

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest-Foundation success.

private func assertNotNaturalLanguageType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("NaturalLanguage."))
}

func naturalLanguageDependencyIdentityProbe() {
    let data = Data("identity".utf8)
    assertNotNaturalLanguageType(data)

    let gazetteer = try! NLGazetteer(
        dictionary: ["org": ["OpenUIKit"]],
        language: .english
    )
    precondition(gazetteer.label(for: "OpenUIKit") == "org")
    assertNotNaturalLanguageType(gazetteer.data)

    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("nl-identity-\(UUID().uuidString).json")
    defer { try? FileManager.default.removeItem(at: url) }
    assertNotNaturalLanguageType(url)
    try! NLEmbedding.write(
        ["alpha": [1.0, 0.0], "beta": [0.0, 1.0]],
        language: .english,
        revision: 1,
        to: url
    )
    let embedding = try! NLEmbedding(contentsOf: url)
    precondition(embedding.contains("alpha"))

    let encoded = try! JSONEncoder().encode(NLLanguage.english)
    let decoded = try! JSONDecoder().decode(NLLanguage.self, from: encoded)
    precondition(decoded == .english)
    assertNotNaturalLanguageType(encoded)
}

#if NL_IDENTITY_MAIN
naturalLanguageDependencyIdentityProbe()
print("NATURALLANGUAGE_DEPENDENCY_IDENTITY_OK")
#endif
