import Foundation
import NaturalLanguage

private func writeLinuxNLModel(
    type: NLModel.ModelType,
    language: NLLanguage?,
    revision: Int,
    labels: [String: String],
    to url: URL
) {
    var object: [String: Any] = [
        "nlModelFormat": 1,
        "type": type.rawValue,
        "revision": revision,
        "labels": labels,
    ]
    if let language {
        object["language"] = language.rawValue
    }
    let payload = try! JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    try! payload.write(to: url, options: .atomic)
}

func testNLModelLinuxJSONClassifier() {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("nl-model-classifier-\(UUID().uuidString).json")
    defer { try? FileManager.default.removeItem(at: url) }
    writeLinuxNLModel(
        type: .classifier,
        language: .english,
        revision: 2,
        labels: ["hello world": "greeting", "goodbye": "farewell"],
        to: url
    )
    let model = try! NLModel(contentsOf: url)
    precondition(model.predictedLabel(for: "hello world") == "greeting")
    precondition(model.predictedLabel(for: "goodbye") == "farewell")
    precondition(model.predictedLabel(for: "missing") == nil)
    let hypotheses = model.predictedLabelHypotheses(for: "hello world", maximumCount: 3)
    precondition(hypotheses == ["greeting": 1.0])
    precondition(model.predictedLabelHypotheses(for: "hello world", maximumCount: 0).isEmpty)
    precondition(model.predictedLabelHypotheses(for: "missing", maximumCount: 2).isEmpty)
    precondition(model.configuration.type == .classifier)
    precondition(model.configuration.language == .english)
    precondition(model.configuration.revision == 2)
}

func testNLModelLinuxJSONSequence() {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("nl-model-sequence-\(UUID().uuidString).json")
    defer { try? FileManager.default.removeItem(at: url) }
    writeLinuxNLModel(
        type: .sequence,
        language: .english,
        revision: 1,
        labels: ["OpenUIKit": "ORG", "Linux": "PLACE"],
        to: url
    )
    let model = try! NLModel(contentsOfURL: url)
    precondition(model.configuration.type == .sequence)
    let labels = model.predictedLabels(forTokens: ["OpenUIKit", "on", "Linux"])
    precondition(labels == ["ORG", "", "PLACE"])
    let hypotheses = model.predictedLabelHypotheses(
        forTokens: ["OpenUIKit", "on", "Linux"],
        maximumCount: 1
    )
    precondition(hypotheses.count == 3)
    precondition(hypotheses[0] == ["ORG": 1.0])
    precondition(hypotheses[1].isEmpty)
    precondition(hypotheses[2] == ["PLACE": 1.0])
    let emptyMax = model.predictedLabelHypotheses(
        forTokens: ["OpenUIKit"],
        maximumCount: 0
    )
    precondition(emptyMax == [[:]])
}

func testNLModelConfigurationFromLinuxJSON() {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("nl-model-config-\(UUID().uuidString).json")
    defer { try? FileManager.default.removeItem(at: url) }
    writeLinuxNLModel(
        type: .classifier,
        language: .french,
        revision: 4,
        labels: ["bonjour": "greeting"],
        to: url
    )
    let model = try! NLModel(contentsOf: url)
    let configuration = model.configuration
    precondition(configuration.type == .classifier)
    precondition(configuration.language == .french)
    precondition(configuration.revision == 4)
    let copied = configuration.copy() as! NLModelConfiguration
    precondition(copied.type == configuration.type)
    precondition(copied.language == configuration.language)
    precondition(copied.revision == configuration.revision)
    precondition(copied !== configuration)
}
