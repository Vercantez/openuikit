import Foundation
import FoundationModels

/// Identity probe for the later clean EC2 integration build. Isolated host
/// compilation does not execute this file. It passes genuine Foundation
/// values through public FoundationModels APIs.
func foundationModelsDependencyIdentityProbe() {
    let url = URL(fileURLWithPath: "/tmp/foundationmodels-identity-adapter")
    let data = Data("identity".utf8)
    let date = Date(timeIntervalSince1970: 1)
    let locale = Locale(identifier: "en_US")
    _ = date

    let content = try! GeneratedContent(json: "{\"ok\": true}")
    precondition(content.jsonString.contains("ok"))

    let model = SystemLanguageModel.default
    precondition(model.supportsLocale(locale) == false)
    precondition(model.supportedLanguages.isEmpty)

    do {
        _ = try SystemLanguageModel.Adapter(fileURL: url)
        fatalError("adapter fileURL must fail closed")
    } catch is SystemLanguageModel.Adapter.AssetError {
        ()
    }

    let session = LanguageModelSession(model: model, tools: [], instructions: "identity")
    let attachment = session.logFeedbackAttachment(
        sentiment: .neutral,
        issues: [],
        desiredResponseText: String(data: data, encoding: .utf8)
    )
    precondition(attachment.isEmpty)
}
