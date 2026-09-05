import CoreML
import Foundation

func testDictionaryFeatureProvider() {
    let input = try! MLDictionaryFeatureProvider(dictionary: [
        "age": MLFeatureValue(int64: 21),
        "score": 0.5,
        "label": "adult"
    ])
    precondition(input.featureNames == ["age", "score", "label"])
    precondition(input["age"]?.int64Value == 21)
    precondition(input.featureValue(for: "label")?.stringValue == "adult")
    precondition(input.dictionary["age"]?.int64Value == 21)
    let provider: any MLFeatureProvider = input
    precondition(provider.featureNames.contains("age"))
    precondition(provider.featureValue(for: "age")?.int64Value == 21)
    precondition(MLDictionaryFeatureProvider(coder: NSCoder()) == nil)
}

func testArrayBatchProvider() {
    let input = try! MLDictionaryFeatureProvider(dictionary: [
        "age": MLFeatureValue(int64: 21)
    ])
    let batch = MLArrayBatchProvider(array: [input, input])
    precondition(batch.count == 2)
    precondition(batch.features(at: 1).featureValue(for: "age")?.int64Value == 21)
    precondition(batch.array.count == 2)
    let alias = MLArrayBatchProvider(featureProviderArray: [input])
    precondition(alias.count == 1)
    let columns = try! MLArrayBatchProvider(dictionary: [
        "x": [1, 2],
        "y": ["a", "b"]
    ])
    precondition(columns.count == 2)
    precondition(columns.features(at: 1).featureValue(for: "x")?.int64Value == 2)
    let batchProvider: any MLBatchProvider = batch
    precondition(batchProvider.count == 2)
    _ = batchProvider.features(at: 0)
}
