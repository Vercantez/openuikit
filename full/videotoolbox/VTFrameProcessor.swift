import Foundation

public let VTFrameProcessorErrorDomain: String = "VTFrameProcessorErrorDomain"

public struct VTFrameProcessorError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: Int, Hashable, Sendable {
        case unknownError = -19730
        case unsupportedResolution = -19731
        case sessionNotStarted = -19732
        case sessionAlreadyActive = -19733
        case fatalError = -19734
        case sessionLevelError = -19735
        case initializationFailed = -19736
        case unsupportedInput = -19737
        case memoryAllocationFailure = -19738
        case revisionNotSupported = -19739
        case processingError = -19740
        case invalidParameterError = -19741
        case invalidFrameTiming = -19742
        case assetDownloadFailed = -19743
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { VTFrameProcessorErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static let unknownError = Code.unknownError
    public static let unsupportedResolution = Code.unsupportedResolution
    public static let sessionNotStarted = Code.sessionNotStarted
    public static let sessionAlreadyActive = Code.sessionAlreadyActive
    public static let fatalError = Code.fatalError
    public static let sessionLevelError = Code.sessionLevelError
    public static let initializationFailed = Code.initializationFailed
    public static let unsupportedInput = Code.unsupportedInput
    public static let memoryAllocationFailure = Code.memoryAllocationFailure
    public static let revisionNotSupported = Code.revisionNotSupported
    public static let processingError = Code.processingError
    public static let invalidParameterError = Code.invalidParameterError
    public static let invalidFrameTiming = Code.invalidFrameTiming
    public static let assetDownloadFailed = Code.assetDownloadFailed

    public static func == (lhs: VTFrameProcessorError, rhs: VTFrameProcessorError) -> Bool {
        lhs.code == rhs.code
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

extension VTFrameProcessorError.Code {
    public static func ~= (match: VTFrameProcessorError.Code, error: any Error) -> Bool {
        (error as? VTFrameProcessorError)?.code == match
    }
}

public protocol VTFrameProcessorConfiguration: NSObjectProtocol, Sendable {
    static var isSupported: Bool { get }
    var destinationPixelBufferAttributes: [String: any Sendable] { get }
    var sourcePixelBufferAttributes: [String: any Sendable] { get }
    static var maximumDimensions: CMVideoDimensions? { get }
    static var minimumDimensions: CMVideoDimensions? { get }
    var nextFrameCount: Int? { get }
    var previousFrameCount: Int? { get }
}

extension VTFrameProcessorConfiguration {
    public static var isSupported: Bool { false }
    public static var maximumDimensions: CMVideoDimensions? { nil }
    public static var minimumDimensions: CMVideoDimensions? { nil }
    public var nextFrameCount: Int? { nil }
    public var previousFrameCount: Int? { nil }
    public var destinationPixelBufferAttributes: [String: any Sendable] { [:] }
    public var sourcePixelBufferAttributes: [String: any Sendable] { [:] }
}

public protocol VTFrameProcessorParameters: NSObjectProtocol {
    var sourceFrame: VTFrameProcessorFrame { get }
    var destinationFrame: VTFrameProcessorFrame? { get }
    var destinationFrames: [VTFrameProcessorFrame]? { get }
}

extension VTFrameProcessorParameters {
    public var destinationFrame: VTFrameProcessorFrame? { nil }
    public var destinationFrames: [VTFrameProcessorFrame]? { nil }
}

open class VTFrameProcessorFrame: NSObject, @unchecked Sendable {
    public let buffer: CVPixelBuffer
    public let presentationTimeStamp: CMTime

    public init?(buffer: CVPixelBuffer, presentationTimeStamp: CMTime) {
        self.buffer = buffer
        self.presentationTimeStamp = presentationTimeStamp
        super.init()
    }

    public struct ReadOnlyFrame: Sendable {
        public var frame: CVReadOnlyPixelBuffer
        public var timeStamp: CMTime

        public init(frame: CVReadOnlyPixelBuffer, timeStamp: CMTime) {
            self.frame = frame
            self.timeStamp = timeStamp
        }
    }
}

open class VTFrameProcessorOpticalFlow: NSObject, @unchecked Sendable {
    public let forwardFlow: CVPixelBuffer
    public let backwardFlow: CVPixelBuffer

    public init?(forwardFlow: CVPixelBuffer, backwardFlow: CVPixelBuffer) {
        self.forwardFlow = forwardFlow
        self.backwardFlow = backwardFlow
        super.init()
    }
}

open class VTFrameProcessor: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }

    public func startSession(configuration: any VTFrameProcessorConfiguration) throws {
        _ = configuration
        throw VTFrameProcessorError(.initializationFailed)
    }

    public func endSession() {}

    public func process(
        with commandBuffer: any MTLCommandBuffer,
        parameters: any VTFrameProcessorParameters
    ) {
        _ = (commandBuffer, parameters)
    }

    public func process(
        parameters: any VTFrameProcessorParameters
    ) async throws -> any VTFrameProcessorParameters {
        _ = parameters
        throw VTFrameProcessorError(.sessionNotStarted)
    }

    public func process(
        parameters: any VTFrameProcessorParameters
    ) -> some AsyncSequence<VTFrameProcessorFrame.ReadOnlyFrame, any Error> {
        _ = parameters
        return AsyncThrowingStream<VTFrameProcessorFrame.ReadOnlyFrame, any Error> { continuation in
            continuation.finish(throwing: VTFrameProcessorError(.sessionNotStarted))
        }
    }
}

private let _emptyAttributes: [String: any Sendable] = [:]

open class VTFrameRateConversionConfiguration: NSObject, VTFrameProcessorConfiguration, @unchecked Sendable {
    public enum QualityPrioritization: Int, Hashable, Sendable {
        case normal = 1
        case quality = 2
    }

    public enum Revision: Int, Hashable, Sendable {
        case revision1 = 1
    }

    public let frameWidth: Int
    public let frameHeight: Int
    public let usePrecomputedFlow: Bool
    public let qualityPrioritization: QualityPrioritization
    public let revision: Revision

    public class var isSupported: Bool { false }
    public class var defaultRevision: Revision { .revision1 }
    public class var supportedRevisions: IndexSet { IndexSet() }
    public class var maximumDimensions: CMVideoDimensions? { nil }
    public class var minimumDimensions: CMVideoDimensions? { nil }

    public var destinationPixelBufferAttributes: [String: any Sendable] { _emptyAttributes }
    public var sourcePixelBufferAttributes: [String: any Sendable] { _emptyAttributes }
    public var supportedPixelFormats: [OSType] { [] }
    public var nextFrameCount: Int? { 1 }
    public var previousFrameCount: Int? { nil }

    public init?(
        frameWidth: Int,
        frameHeight: Int,
        usePrecomputedFlow: Bool,
        qualityPrioritization: QualityPrioritization,
        revision: Revision
    ) {
        _ = (frameWidth, frameHeight, usePrecomputedFlow, qualityPrioritization, revision)
        return nil
    }
}

open class VTFrameRateConversionParameters: NSObject, VTFrameProcessorParameters, @unchecked Sendable {
    public enum SubmissionMode: Int, Hashable, Sendable {
        case sequential = 1
        case random = 2
        case sequentialReferencesUnchanged = 3
    }

    public let sourceFrame: VTFrameProcessorFrame
    public let nextFrame: VTFrameProcessorFrame?
    public let opticalFlow: VTFrameProcessorOpticalFlow?
    public let interpolationPhase: [Float]
    public let submissionMode: SubmissionMode
    public let destinationFrames: [VTFrameProcessorFrame]?
    public var destinationFrame: VTFrameProcessorFrame? { destinationFrames?.first }

    public convenience init?(
        sourceFrame: VTFrameProcessorFrame,
        nextFrame: VTFrameProcessorFrame,
        opticalFlow: VTFrameProcessorOpticalFlow?,
        interpolationPhase: [Float],
        submissionMode: SubmissionMode,
        destinationFrames: [VTFrameProcessorFrame]
    ) {
        self.init(
            source: sourceFrame,
            next: nextFrame,
            flow: opticalFlow,
            phase: interpolationPhase,
            mode: submissionMode,
            destinations: destinationFrames
        )
    }

    private init(
        source: VTFrameProcessorFrame,
        next: VTFrameProcessorFrame,
        flow: VTFrameProcessorOpticalFlow?,
        phase: [Float],
        mode: SubmissionMode,
        destinations: [VTFrameProcessorFrame]
    ) {
        self.sourceFrame = source
        self.nextFrame = next
        self.opticalFlow = flow
        self.interpolationPhase = phase
        self.submissionMode = mode
        self.destinationFrames = destinations
        super.init()
    }
}

open class VTLowLatencyFrameInterpolationConfiguration: NSObject, VTFrameProcessorConfiguration, @unchecked Sendable {
    public let frameWidth: Int
    public let frameHeight: Int
    public let numberOfInterpolatedFrames: Int
    public let spatialScaleFactor: Int

    public class var isSupported: Bool { false }
    public class var maximumDimensions: CMVideoDimensions? { nil }
    public class var minimumDimensions: CMVideoDimensions? { nil }

    public var destinationPixelBufferAttributes: [String: any Sendable] { _emptyAttributes }
    public var sourcePixelBufferAttributes: [String: any Sendable] { _emptyAttributes }
    public var supportedPixelFormats: [OSType] { [] }
    public var nextFrameCount: Int? { numberOfInterpolatedFrames }
    public var previousFrameCount: Int? { 1 }

    public init?(frameWidth: Int, frameHeight: Int, numberOfInterpolatedFrames: Int) {
        _ = (frameWidth, frameHeight, numberOfInterpolatedFrames)
        return nil
    }

    public init?(frameWidth: Int, frameHeight: Int, spatialScaleFactor: Int) {
        _ = (frameWidth, frameHeight, spatialScaleFactor)
        return nil
    }
}

open class VTLowLatencyFrameInterpolationParameters: NSObject, VTFrameProcessorParameters, @unchecked Sendable {
    public let sourceFrame: VTFrameProcessorFrame
    public let previousFrame: VTFrameProcessorFrame
    public let interpolationPhase: [Float]
    public let destinationFrames: [VTFrameProcessorFrame]?
    public var destinationFrame: VTFrameProcessorFrame? { destinationFrames?.first }

    public convenience init?(
        sourceFrame: VTFrameProcessorFrame,
        previousFrame: VTFrameProcessorFrame,
        interpolationPhase: [Float],
        destinationFrames: [VTFrameProcessorFrame]
    ) {
        self.init(
            source: sourceFrame,
            previous: previousFrame,
            phase: interpolationPhase,
            destinations: destinationFrames
        )
    }

    private init(
        source: VTFrameProcessorFrame,
        previous: VTFrameProcessorFrame,
        phase: [Float],
        destinations: [VTFrameProcessorFrame]
    ) {
        self.sourceFrame = source
        self.previousFrame = previous
        self.interpolationPhase = phase
        self.destinationFrames = destinations
        super.init()
    }
}

open class VTLowLatencySuperResolutionScalerConfiguration: NSObject, VTFrameProcessorConfiguration, @unchecked Sendable {
    public let frameWidth: Int
    public let frameHeight: Int
    public let scaleFactor: Float

    public class var isSupported: Bool { false }
    public class var maximumDimensions: CMVideoDimensions? { nil }
    public class var minimumDimensions: CMVideoDimensions? { nil }

    public var destinationPixelBufferAttributes: [String: any Sendable] { _emptyAttributes }
    public var sourcePixelBufferAttributes: [String: any Sendable] { _emptyAttributes }
    public var supportedPixelFormats: [OSType] { [] }
    public var nextFrameCount: Int? { nil }
    public var previousFrameCount: Int? { nil }

    public init(frameWidth: Int, frameHeight: Int, scaleFactor: Float) {
        self.frameWidth = frameWidth
        self.frameHeight = frameHeight
        self.scaleFactor = scaleFactor
        super.init()
    }

    public class func supportedScaleFactors(frameWidth: Int, frameHeight: Int) -> [Float] {
        _ = (frameWidth, frameHeight)
        return []
    }
}

open class VTLowLatencySuperResolutionScalerParameters: NSObject, VTFrameProcessorParameters, @unchecked Sendable {
    public let sourceFrame: VTFrameProcessorFrame
    public let destinationFrame: VTFrameProcessorFrame?
    public var destinationFrames: [VTFrameProcessorFrame]? {
        destinationFrame.map { [$0] }
    }

    public init(sourceFrame: VTFrameProcessorFrame, destinationFrame: VTFrameProcessorFrame) {
        self.sourceFrame = sourceFrame
        self.destinationFrame = destinationFrame
        super.init()
    }
}

open class VTMotionBlurConfiguration: NSObject, VTFrameProcessorConfiguration, @unchecked Sendable {
    public enum QualityPrioritization: Int, Hashable, Sendable {
        case normal = 1
        case quality = 2
    }

    public enum Revision: Int, Hashable, Sendable {
        case revision1 = 1
    }

    public let frameWidth: Int
    public let frameHeight: Int
    public let usePrecomputedFlow: Bool
    public let qualityPrioritization: QualityPrioritization
    public let revision: Revision

    public class var isSupported: Bool { false }
    public class var defaultRevision: Revision { .revision1 }
    public class var supportedRevisions: IndexSet { IndexSet() }
    public class var maximumDimensions: CMVideoDimensions? { nil }
    public class var minimumDimensions: CMVideoDimensions? { nil }

    public var destinationPixelBufferAttributes: [String: any Sendable] { _emptyAttributes }
    public var sourcePixelBufferAttributes: [String: any Sendable] { _emptyAttributes }
    public var supportedPixelFormats: [OSType] { [] }
    public var nextFrameCount: Int? { 1 }
    public var previousFrameCount: Int? { 1 }

    public init?(
        frameWidth: Int,
        frameHeight: Int,
        usePrecomputedFlow: Bool,
        qualityPrioritization: QualityPrioritization,
        revision: Revision
    ) {
        _ = (frameWidth, frameHeight, usePrecomputedFlow, qualityPrioritization, revision)
        return nil
    }
}

open class VTMotionBlurParameters: NSObject, VTFrameProcessorParameters, @unchecked Sendable {
    public enum SubmissionMode: Int, Hashable, Sendable {
        case sequential = 1
        case random = 2
    }

    public let sourceFrame: VTFrameProcessorFrame
    public let nextFrame: VTFrameProcessorFrame?
    public let previousFrame: VTFrameProcessorFrame?
    public let nextOpticalFlow: VTFrameProcessorOpticalFlow?
    public let previousOpticalFlow: VTFrameProcessorOpticalFlow?
    public let motionBlurStrength: Int
    public let submissionMode: SubmissionMode
    public let destinationFrame: VTFrameProcessorFrame?
    public var destinationFrames: [VTFrameProcessorFrame]? {
        destinationFrame.map { [$0] }
    }

    public init?(
        sourceFrame: VTFrameProcessorFrame,
        nextFrame: VTFrameProcessorFrame?,
        previousFrame: VTFrameProcessorFrame?,
        nextOpticalFlow: VTFrameProcessorOpticalFlow?,
        previousOpticalFlow: VTFrameProcessorOpticalFlow?,
        motionBlurStrength: Int,
        submissionMode: SubmissionMode,
        destinationFrame: VTFrameProcessorFrame
    ) {
        self.sourceFrame = sourceFrame
        self.nextFrame = nextFrame
        self.previousFrame = previousFrame
        self.nextOpticalFlow = nextOpticalFlow
        self.previousOpticalFlow = previousOpticalFlow
        self.motionBlurStrength = motionBlurStrength
        self.submissionMode = submissionMode
        self.destinationFrame = destinationFrame
        super.init()
    }
}

open class VTOpticalFlowConfiguration: NSObject, VTFrameProcessorConfiguration, @unchecked Sendable {
    public enum QualityPrioritization: Int, Hashable, Sendable {
        case normal = 1
        case quality = 2
    }

    public enum Revision: Int, Hashable, Sendable {
        case revision1 = 1
    }

    public let frameWidth: Int
    public let frameHeight: Int
    public let qualityPrioritization: QualityPrioritization
    public let revision: Revision

    public class var isSupported: Bool { false }
    public class var defaultRevision: Revision { .revision1 }
    public class var supportedRevisions: IndexSet { IndexSet() }
    public class var maximumDimensions: CMVideoDimensions? { nil }
    public class var minimumDimensions: CMVideoDimensions? { nil }

    public var destinationPixelBufferAttributes: [String: any Sendable] { _emptyAttributes }
    public var sourcePixelBufferAttributes: [String: any Sendable] { _emptyAttributes }
    public var supportedPixelFormats: [OSType] { [] }
    public var nextFrameCount: Int? { 1 }
    public var previousFrameCount: Int? { nil }

    public init?(
        frameWidth: Int,
        frameHeight: Int,
        qualityPrioritization: QualityPrioritization,
        revision: Revision
    ) {
        _ = (frameWidth, frameHeight, qualityPrioritization, revision)
        return nil
    }
}

open class VTOpticalFlowParameters: NSObject, VTFrameProcessorParameters, @unchecked Sendable {
    public enum SubmissionMode: Int, Hashable, Sendable {
        case sequential = 1
        case random = 2
    }

    public let sourceFrame: VTFrameProcessorFrame
    public let nextFrame: VTFrameProcessorFrame
    public let submissionMode: SubmissionMode
    public let destinationOpticalFlow: VTFrameProcessorOpticalFlow
    public var destinationFrame: VTFrameProcessorFrame? { nil }
    public var destinationFrames: [VTFrameProcessorFrame]? { nil }

    public init?(
        sourceFrame: VTFrameProcessorFrame,
        nextFrame: VTFrameProcessorFrame,
        submissionMode: SubmissionMode,
        destinationOpticalFlow: VTFrameProcessorOpticalFlow
    ) {
        self.sourceFrame = sourceFrame
        self.nextFrame = nextFrame
        self.submissionMode = submissionMode
        self.destinationOpticalFlow = destinationOpticalFlow
        super.init()
    }
}

open class VTSuperResolutionScalerConfiguration: NSObject, VTFrameProcessorConfiguration, @unchecked Sendable {
    public enum InputType: Int, Hashable, Sendable {
        case image = 1
        case video = 2
    }

    public enum ModelStatus: Int, Hashable, Sendable {
        case downloadRequired = 0
        case downloading = 1
        case ready = 2
    }

    public enum QualityPrioritization: Int, Hashable, Sendable {
        case normal = 1
    }

    public enum Revision: Int, Hashable, Sendable {
        case revision1 = 1
    }

    public let frameWidth: Int
    public let frameHeight: Int
    public let scaleFactor: Int
    public let inputType: InputType
    public let usesPrecomputedFlow: Bool
    public let qualityPrioritization: QualityPrioritization
    public let revision: Revision

    public class var isSupported: Bool { false }
    public class var defaultRevision: Revision { .revision1 }
    public class var supportedRevisions: IndexSet { IndexSet() }
    public class var supportedScaleFactors: [Int] { [] }
    public class var maximumDimensions: CMVideoDimensions? { nil }
    public class var minimumDimensions: CMVideoDimensions? { nil }

    public var destinationPixelBufferAttributes: [String: any Sendable] { _emptyAttributes }
    public var sourcePixelBufferAttributes: [String: any Sendable] { _emptyAttributes }
    public var supportedPixelFormats: [OSType] { [] }
    public var configurationModelPercentageAvailable: Float { 0 }
    public var configurationModelStatus: ModelStatus { .downloadRequired }
    public var nextFrameCount: Int? { nil }
    public var previousFrameCount: Int? { usesPrecomputedFlow ? 1 : nil }

    public init?(
        frameWidth: Int,
        frameHeight: Int,
        scaleFactor: Int,
        inputType: InputType,
        usePrecomputedFlow: Bool,
        qualityPrioritization: QualityPrioritization,
        revision: Revision
    ) {
        _ = (
            frameWidth, frameHeight, scaleFactor, inputType, usePrecomputedFlow,
            qualityPrioritization, revision
        )
        return nil
    }

    public func downloadConfigurationModel(completionHandler: @escaping ((any Error)?) -> Void) {
        completionHandler(VTFrameProcessorError(.assetDownloadFailed))
    }
}

open class VTSuperResolutionScalerParameters: NSObject, VTFrameProcessorParameters, @unchecked Sendable {
    public enum SubmissionMode: Int, Hashable, Sendable {
        case sequential = 1
        case random = 2
    }

    public let sourceFrame: VTFrameProcessorFrame
    public let previousFrame: VTFrameProcessorFrame?
    public let previousOutputFrame: VTFrameProcessorFrame?
    public let opticalFlow: VTFrameProcessorOpticalFlow?
    public let submissionMode: SubmissionMode
    public let destinationFrame: VTFrameProcessorFrame?
    public var destinationFrames: [VTFrameProcessorFrame]? {
        destinationFrame.map { [$0] }
    }

    public init?(
        sourceFrame: VTFrameProcessorFrame,
        previousFrame: VTFrameProcessorFrame?,
        previousOutputFrame: VTFrameProcessorFrame?,
        opticalFlow: VTFrameProcessorOpticalFlow?,
        submissionMode: SubmissionMode,
        destinationFrame: VTFrameProcessorFrame
    ) {
        self.sourceFrame = sourceFrame
        self.previousFrame = previousFrame
        self.previousOutputFrame = previousOutputFrame
        self.opticalFlow = opticalFlow
        self.submissionMode = submissionMode
        self.destinationFrame = destinationFrame
        super.init()
    }
}

open class VTTemporalNoiseFilterConfiguration: NSObject, VTFrameProcessorConfiguration, @unchecked Sendable {
    public let frameWidth: Int
    public let frameHeight: Int

    public class var isSupported: Bool { false }
    public class var supportedSourcePixelFormats: [OSType] { [] }
    public class var maximumDimensions: CMVideoDimensions? { nil }
    public class var minimumDimensions: CMVideoDimensions? { nil }

    public var destinationPixelBufferAttributes: [String: any Sendable] { _emptyAttributes }
    public var sourcePixelBufferAttributes: [String: any Sendable] { _emptyAttributes }
    public var supportedPixelFormats: [OSType] { [] }
    public var nextFrameCount: Int? { 1 }
    public var previousFrameCount: Int? { 1 }

    public init?(frameWidth: Int, frameHeight: Int, sourcePixelFormat: OSType) {
        _ = (frameWidth, frameHeight, sourcePixelFormat)
        return nil
    }
}

open class VTTemporalNoiseFilterParameters: NSObject, VTFrameProcessorParameters, @unchecked Sendable {
    public let sourceFrame: VTFrameProcessorFrame
    public let nextFrames: [VTFrameProcessorFrame]
    public let previousFrames: [VTFrameProcessorFrame]
    public let destinationFrame: VTFrameProcessorFrame?
    public var filterStrength: Float
    public var hasDiscontinuity: Bool
    public var destinationFrames: [VTFrameProcessorFrame]? {
        destinationFrame.map { [$0] }
    }

    public init?(
        sourceFrame: VTFrameProcessorFrame,
        nextFrames: [VTFrameProcessorFrame],
        previousFrames: [VTFrameProcessorFrame],
        destinationFrame: VTFrameProcessorFrame,
        filterStrength: Float,
        hasDiscontinuity: Bool
    ) {
        self.sourceFrame = sourceFrame
        self.nextFrames = nextFrames
        self.previousFrames = previousFrames
        self.destinationFrame = destinationFrame
        self.filterStrength = filterStrength
        self.hasDiscontinuity = hasDiscontinuity
        super.init()
    }
}
