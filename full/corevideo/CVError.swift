import Foundation

/// Typed overlay of `CVReturn`. Success (`kCVReturnSuccess`) is not an error
/// and therefore yields `nil` from `init(rawValue:)`.
@frozen
public struct CVError: Error, RawRepresentable, Hashable, Sendable, CustomStringConvertible,
    LocalizedError
{
    public typealias RawValue = CVReturn
    public var rawValue: CVReturn

    public init?(rawValue: CVReturn) {
        if rawValue == kCVReturnSuccess { return nil }
        self.rawValue = rawValue
    }

    public static let internalError = CVError(unchecked: kCVReturnError)
    public static let invalidArgument = CVError(unchecked: kCVReturnInvalidArgument)
    public static let allocationFailed = CVError(unchecked: kCVReturnAllocationFailed)
    public static let unsupported = CVError(unchecked: kCVReturnUnsupported)
    public static let invalidPixelFormat = CVError(unchecked: kCVReturnInvalidPixelFormat)
    public static let invalidSize = CVError(unchecked: kCVReturnInvalidSize)
    public static let invalidPixelBufferAttributes = CVError(
        unchecked: kCVReturnInvalidPixelBufferAttributes
    )
    public static let pixelBufferNotMetalCompatible = CVError(
        unchecked: kCVReturnPixelBufferNotMetalCompatible
    )
    public static let wouldExceedAllocationThreshold = CVError(
        unchecked: kCVReturnWouldExceedAllocationThreshold
    )
    public static let poolAllocationFailed = CVError(unchecked: kCVReturnPoolAllocationFailed)
    public static let invalidPoolAttributes = CVError(unchecked: kCVReturnInvalidPoolAttributes)
    public static let retry = CVError(unchecked: kCVReturnRetry)

    private init(unchecked rawValue: CVReturn) {
        self.rawValue = rawValue
    }

    public static func check(_ status: CVReturn) throws(CVError) {
        if status == kCVReturnSuccess { return }
        throw CVError(rawValue: status) ?? .internalError
    }

    public var description: String { _cvErrorName(rawValue) }

    public var errorDescription: String? { description }

    public var localizedDescription: String { description }
}

func _cvErrorName(_ status: CVReturn) -> String {
    switch status {
    case kCVReturnSuccess: return "kCVReturnSuccess"
    case kCVReturnInvalidArgument: return "kCVReturnInvalidArgument"
    case kCVReturnAllocationFailed: return "kCVReturnAllocationFailed"
    case kCVReturnUnsupported: return "kCVReturnUnsupported"
    case kCVReturnInvalidDisplay: return "kCVReturnInvalidDisplay"
    case kCVReturnDisplayLinkAlreadyRunning: return "kCVReturnDisplayLinkAlreadyRunning"
    case kCVReturnDisplayLinkNotRunning: return "kCVReturnDisplayLinkNotRunning"
    case kCVReturnDisplayLinkCallbacksNotSet: return "kCVReturnDisplayLinkCallbacksNotSet"
    case kCVReturnInvalidPixelFormat: return "kCVReturnInvalidPixelFormat"
    case kCVReturnInvalidSize: return "kCVReturnInvalidSize"
    case kCVReturnInvalidPixelBufferAttributes: return "kCVReturnInvalidPixelBufferAttributes"
    case kCVReturnPixelBufferNotOpenGLCompatible: return "kCVReturnPixelBufferNotOpenGLCompatible"
    case kCVReturnPixelBufferNotMetalCompatible: return "kCVReturnPixelBufferNotMetalCompatible"
    case kCVReturnWouldExceedAllocationThreshold:
        return "kCVReturnWouldExceedAllocationThreshold"
    case kCVReturnPoolAllocationFailed: return "kCVReturnPoolAllocationFailed"
    case kCVReturnInvalidPoolAttributes: return "kCVReturnInvalidPoolAttributes"
    case kCVReturnRetry: return "kCVReturnRetry"
    case kCVReturnError: return "kCVReturnError"
    default: return "CVReturn(\(status))"
    }
}
