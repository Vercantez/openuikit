import CoreML
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
