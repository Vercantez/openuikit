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
    private let linuxModel: MLModel

    public var model: any MLModel & MLWritable {
        linuxModel
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
        self.linuxModel = MLModel(
            configuration: MLModelConfiguration(),
            modelDescription: MLModelDescription()
        )
        super.init()
    }

    /// Linux probe constructor. Apple never exposes a public UpdateContext
    /// initializer; on-device contexts are produced only by a running update.
    public static func linuxFailClosedContext(
        event: MLUpdateProgressEvent = .trainingBegin,
        metrics: [MLMetricKey: Any] = [.lossValue: 0.0],
        parameters: [MLParameterKey: Any] = [.learningRate: 0.01]
    ) -> MLUpdateContext {
        let dummyURL = URL(fileURLWithPath: "/tmp/missing.mlmodelc")
        let dummyBatch = MLArrayBatchProvider(array: [])
        let dummyTask: MLUpdateTask
        do {
            dummyTask = try MLUpdateTask(
                forModelAt: dummyURL,
                trainingData: dummyBatch,
                completionHandler: { _ in }
            )
        } catch {
            dummyTask = MLUpdateTask.linuxFailedTask()
        }
        return MLUpdateContext(task: dummyTask, event: event, metrics: metrics, parameters: parameters)
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

    static func linuxFailedTask() -> MLUpdateTask {
        MLUpdateTask(uninitializedFailClosed: ())
    }

    private init(uninitializedFailClosed: Void) {
        _ = uninitializedFailClosed
        super.init(
            taskIdentifier: UUID().uuidString,
            state: .failed,
            error: coreMLError(.update, "Model update is unavailable on Linux.")
        )
    }
}

open class MLModelCollectionEntry: NSObject {
    public private(set) var modelIdentifier: String
    public private(set) var modelURL: URL

    public init(modelIdentifier: String, modelURL: URL) {
        self.modelIdentifier = modelIdentifier
        self.modelURL = modelURL
        super.init()
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? MLModelCollectionEntry else { return false }
        return modelIdentifier == other.modelIdentifier && modelURL == other.modelURL
    }
}

/// Apple Model Deployment collections require the `com.apple.developer.coreml.model-collection`
/// entitlement and the model-catalog daemon. Linux has neither, so every access path
/// completes with `MLModelError.modelCollection`.
open class MLModelCollection: NSObject {
    public private(set) var identifier: String
    public private(set) var deploymentID: String
    public private(set) var entries: [String: MLModelCollectionEntry]

    init(identifier: String, deploymentID: String, entries: [String: MLModelCollectionEntry] = [:]) {
        self.identifier = identifier
        self.deploymentID = deploymentID
        self.entries = entries
        super.init()
    }

    open class func beginAccessing(
        identifier: String,
        completionHandler handler: @escaping (MLModelCollection?, (any Error)?) -> Void
    ) -> Progress {
        let progress = Progress(totalUnitCount: 1)
        let error = coreMLError(
            .modelCollection,
            "MLModelCollection requires the Apple model-catalog daemon and the CoreML model-collection entitlement."
        )
        coreMLDeliverCompletion {
            progress.completedUnitCount = 1
            handler(nil, error)
        }
        return progress
    }

    open class func beginAccessing(
        identifier: String,
        completionHandler handler: @escaping (Result<MLModelCollection, any Error>) -> Void
    ) -> Progress {
        beginAccessing(identifier: identifier) { collection, error in
            if let error {
                handler(.failure(error))
            } else if let collection {
                handler(.success(collection))
            } else {
                handler(.failure(coreMLError(.modelCollection, "MLModelCollection is fail-closed on Linux.")))
            }
        }
    }

    open class func endAccessing(
        identifier: String,
        completionHandler handler: @escaping ((any Error)?) -> Void
    ) {
        _ = identifier
        let error = coreMLError(
            .modelCollection,
            "MLModelCollection requires the Apple model-catalog daemon and the CoreML model-collection entitlement."
        )
        coreMLDeliverCompletion {
            handler(error)
        }
    }

    open class func endAccessing(
        identifier: String,
        completionHandler handler: @escaping (Result<Void, any Error>) -> Void
    ) {
        endAccessing(identifier: identifier) { error in
            if let error {
                handler(.failure(error))
            } else {
                handler(.success(()))
            }
        }
    }
}
