import CoreML
import Dispatch
import Foundation

func testUpdateTaskFailsClosed() {
    let provider = MLArrayBatchProvider(array: [])
    let url = URL(fileURLWithPath: "/tmp/model.mlmodelc")
    coremlRequireThrows(.update) {
        _ = try MLUpdateTask(
            forModelAt: url,
            trainingData: provider,
            completionHandler: { _ in }
        )
    }
    coremlRequireThrows(.update) {
        _ = try MLUpdateTask(
            forModelAtURL: url,
            trainingData: provider,
            completionHandler: { _ in }
        )
    }
    coremlRequireThrows(.update) {
        _ = try MLUpdateTask(
            forModelAt: url,
            trainingData: provider,
            configuration: MLModelConfiguration(),
            completionHandler: { _ in }
        )
    }
    coremlRequireThrows(.update) {
        _ = try MLUpdateTask(
            forModelAtURL: url,
            trainingData: provider,
            configuration: MLModelConfiguration(),
            completionHandler: { _ in }
        )
    }
    let handlers = MLUpdateProgressHandlers(
        forEvents: [.trainingBegin, .epochEnd],
        progressHandler: nil,
        completionHandler: { _ in }
    )
    coremlRequireThrows(.update) {
        _ = try MLUpdateTask(
            forModelAt: url,
            trainingData: provider,
            progressHandlers: handlers
        )
    }
    coremlRequireThrows(.update) {
        _ = try MLUpdateTask(
            forModelAtURL: url,
            trainingData: provider,
            progressHandlers: handlers
        )
    }
    coremlRequireThrows(.update) {
        _ = try MLUpdateTask(
            forModelAt: url,
            trainingData: provider,
            configuration: nil,
            progressHandlers: handlers
        )
    }
    coremlRequireThrows(.update) {
        _ = try MLUpdateTask(
            forModelAtURL: url,
            trainingData: provider,
            configuration: nil,
            progressHandlers: handlers
        )
    }
}

func testCustomLayerFailsClosed() {
    coremlRequireThrows(.customLayer) {
        _ = try MLFailClosedCustomLayer(parameterDictionary: ["k": 1])
    }
    coremlRequireThrows(.customLayer) {
        _ = try MLFailClosedCustomLayer(parameters: [:])
    }
}

private struct EchoCustomModel: MLCustomModel {
    init(modelDescription: MLModelDescription, parameters: [String: Any]) throws {
        _ = (modelDescription, parameters)
    }

    init(modelDescription: MLModelDescription, parameterDictionary parameters: [String: Any]) throws {
        try self.init(modelDescription: modelDescription, parameters: parameters)
    }

    func prediction(
        from input: any MLFeatureProvider,
        options: MLPredictionOptions
    ) throws -> any MLFeatureProvider {
        _ = options
        return input
    }
}

func testCustomModelProtocolAndBatchDefault() {
    let description = MLModelDescription()
    let direct = try! EchoCustomModel(modelDescription: description, parameters: ["mode": "echo"])
    let alias = try! EchoCustomModel(modelDescription: description, parameterDictionary: [:])
    let input = try! MLDictionaryFeatureProvider(dictionary: ["value": 42])
    let options = MLPredictionOptions()
    let output = try! direct.prediction(from: input, options: options)
    precondition(output.featureValue(for: "value")?.int64Value == 42)

    let batch = MLArrayBatchProvider(array: [input, input])
    let outputs = try! alias.predictions(from: batch, options: options)
    precondition(outputs.count == 2)
    precondition(outputs.features(at: 1).featureValue(for: "value")?.int64Value == 42)
}

func testTaskResumeAndCancel() {
    let task = MLTask()
    precondition(task.state == .failed)
    _ = task.taskIdentifier
    _ = task.error
    task.resume()
    precondition(task.state == .failed)
    task.cancel()
    precondition(task.state == .completed)
}

func testEmptyStateFailsClosed() {
    let state = MLState()
    do {
        _ = try state.withMultiArray { _ in 1 }
        fatalError("empty MLState must fail closed")
    } catch {
        coremlRequireError(error, .generic)
    }
}

func testUpdateContextFailClosedModel() {
    let context = MLUpdateContext.linuxFailClosedContext(
        event: .epochEnd,
        metrics: [.lossValue: 0.25],
        parameters: [.epochs: 2]
    )
    precondition(context.event == .epochEnd)
    precondition((context.metrics[.lossValue] as? Double) == 0.25)
    precondition((context.parameters[.epochs] as? Int) == 2)
    _ = context.task.taskIdentifier
    precondition(context.task.state == .failed)
    let writable: any MLModel & MLWritable = context.model
    coremlRequireThrows(.io) {
        try writable.write(to: URL(fileURLWithPath: "/tmp/updated.mlmodelc"))
    }
}

func testModelCollectionFailsClosed() {
    let beginOnce = DispatchSemaphore(value: 0)
    let progress = MLModelCollection.beginAccessing(identifier: "bundle") { collection, error in
        precondition(collection == nil)
        coremlRequireError(error!, .modelCollection)
        beginOnce.signal()
    }
    _ = progress
    precondition(beginOnce.wait(timeout: .now() + 5) == .success)
    let resultOnce = DispatchSemaphore(value: 0)
    let resultProgress = MLModelCollection.beginAccessing(identifier: "bundle") { (result: Result<MLModelCollection, any Error>) in
        if case .failure(let error) = result {
            coremlRequireError(error, .modelCollection)
        } else {
            fatalError("collection begin must fail closed")
        }
        resultOnce.signal()
    }
    _ = resultProgress
    precondition(resultOnce.wait(timeout: .now() + 5) == .success)
    let delivered = DispatchSemaphore(value: 0)
    MLModelCollection.endAccessing(identifier: "bundle") { error in
        coremlRequireError(error!, .modelCollection)
        delivered.signal()
    }
    precondition(delivered.wait(timeout: .now() + 5) == .success)
    let endOnce = DispatchSemaphore(value: 0)
    MLModelCollection.endAccessing(identifier: "bundle") { (result: Result<Void, any Error>) in
        if case .failure(let error) = result {
            coremlRequireError(error, .modelCollection)
        } else {
            fatalError("collection end Result must fail closed")
        }
        endOnce.signal()
    }
    precondition(endOnce.wait(timeout: .now() + 5) == .success)
    let entry = MLModelCollectionEntry(
        modelIdentifier: "m",
        modelURL: URL(fileURLWithPath: "/tmp/x.mlmodelc")
    )
    precondition(entry.modelIdentifier == "m")
    precondition(entry.isEqual(entry))
}
