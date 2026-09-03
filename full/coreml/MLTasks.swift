import Foundation

open class MLTask: NSObject {
    public private(set) var taskIdentifier: String
    public private(set) var state: MLTaskState
    public private(set) var error: (any Error)?

    public override init() {
        self.taskIdentifier = UUID().uuidString
        self.state = .failed
        self.error = coreMLNoBackend("MLTask")
        super.init()
    }

    init(taskIdentifier: String, state: MLTaskState, error: (any Error)?) {
        self.taskIdentifier = taskIdentifier
        self.state = state
        self.error = error
        super.init()
    }

    open func resume() {
        guard state == .suspended else { return }
        state = .failed
        error = coreMLNoBackend("MLTask.resume")
    }

    open func cancel() {
        state = .cancelling
        state = .completed
        error = coreMLError(.predictionCancelled, "MLTask.cancel")
    }
}

open class MLUpdateContext: NSObject {
    public private(set) var task: MLUpdateTask
    public private(set) var event: MLUpdateProgressEvent
    public private(set) var metrics: [MLMetricKey: Any]
    public private(set) var parameters: [MLParameterKey: Any]
    public var model: any MLModel & MLWritable {
        fatalError("CoreML has no updatable compiled model on Linux.")
    }

    init(
        task: MLUpdateTask,
        event: MLUpdateProgressEvent,
        metrics: [MLMetricKey: Any] = [:],
        parameters: [MLParameterKey: Any] = [:]
    ) {
        self.task = task
        self.event = event
        self.metrics = metrics
        self.parameters = parameters
        super.init()
    }
}

open class MLUpdateProgressHandlers: NSObject {
    public let interestedEvents: MLUpdateProgressEvent
    public let progressHandler: ((MLUpdateContext) -> Void)?
    public let completionHandler: (MLUpdateContext) -> Void

    public init(
        forEvents interestedEvents: MLUpdateProgressEvent,
        progressHandler: ((MLUpdateContext) -> Void)?,
        completionHandler: @escaping (MLUpdateContext) -> Void
    ) {
        self.interestedEvents = interestedEvents
        self.progressHandler = progressHandler
        self.completionHandler = completionHandler
        super.init()
    }
}

open class MLUpdateTask: MLTask {
    public init(
        forModelAt modelURL: URL,
        trainingData: any MLBatchProvider,
        completionHandler: @escaping (MLUpdateContext) -> Void
    ) throws {
        _ = (modelURL, trainingData, completionHandler)
        super.init(taskIdentifier: UUID().uuidString, state: .failed, error: coreMLError(.update, "Model update is unavailable on Linux."))
        throw coreMLError(.update, "Model update is unavailable on Linux.")
    }

    public convenience init(
        forModelAtURL modelURL: URL,
        trainingData: any MLBatchProvider,
        completionHandler: @escaping (MLUpdateContext) -> Void
    ) throws {
        try self.init(forModelAt: modelURL, trainingData: trainingData, completionHandler: completionHandler)
    }

    public convenience init(
        forModelAt modelURL: URL,
        trainingData: any MLBatchProvider,
        configuration: MLModelConfiguration?,
        completionHandler: @escaping (MLUpdateContext) -> Void
    ) throws {
        _ = configuration
        try self.init(forModelAt: modelURL, trainingData: trainingData, completionHandler: completionHandler)
    }

    public convenience init(
        forModelAtURL modelURL: URL,
        trainingData: any MLBatchProvider,
        configuration: MLModelConfiguration?,
        completionHandler: @escaping (MLUpdateContext) -> Void
    ) throws {
        try self.init(
            forModelAt: modelURL,
            trainingData: trainingData,
            configuration: configuration,
            completionHandler: completionHandler
        )
    }

    public init(
        forModelAt modelURL: URL,
        trainingData: any MLBatchProvider,
        configuration: MLModelConfiguration?,
        progressHandlers: MLUpdateProgressHandlers
    ) throws {
        _ = (modelURL, trainingData, configuration, progressHandlers)
        super.init(taskIdentifier: UUID().uuidString, state: .failed, error: coreMLError(.update, "Model update is unavailable on Linux."))
        throw coreMLError(.update, "Model update is unavailable on Linux.")
    }

    public convenience init(
        forModelAtURL modelURL: URL,
        trainingData: any MLBatchProvider,
        configuration: MLModelConfiguration?,
        progressHandlers: MLUpdateProgressHandlers
    ) throws {
        try self.init(
            forModelAt: modelURL,
            trainingData: trainingData,
            configuration: configuration,
            progressHandlers: progressHandlers
        )
    }

    public convenience init(
        forModelAt modelURL: URL,
        trainingData: any MLBatchProvider,
        progressHandlers: MLUpdateProgressHandlers
    ) throws {
        try self.init(
            forModelAt: modelURL,
            trainingData: trainingData,
            configuration: nil,
            progressHandlers: progressHandlers
        )
    }

    public convenience init(
        forModelAtURL modelURL: URL,
        trainingData: any MLBatchProvider,
        progressHandlers: MLUpdateProgressHandlers
    ) throws {
        try self.init(forModelAt: modelURL, trainingData: trainingData, progressHandlers: progressHandlers)
    }

    open func resume(withParameters updateParameters: [MLParameterKey: Any]) {
        _ = updateParameters
        resume()
    }
}
