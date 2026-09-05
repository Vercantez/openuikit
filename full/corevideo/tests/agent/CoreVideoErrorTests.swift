import CoreVideo
import Foundation

func testCVErrorStatics() {
    precondition(CVError.internalError.rawValue == kCVReturnError)
    precondition(CVError.invalidArgument.rawValue == kCVReturnInvalidArgument)
    precondition(CVError.allocationFailed.rawValue == kCVReturnAllocationFailed)
    precondition(CVError.unsupported.rawValue == kCVReturnUnsupported)
    precondition(CVError.invalidPixelFormat.rawValue == kCVReturnInvalidPixelFormat)
    precondition(CVError.invalidSize.rawValue == kCVReturnInvalidSize)
    precondition(CVError.invalidPixelBufferAttributes.rawValue == kCVReturnInvalidPixelBufferAttributes)
    precondition(
        CVError.pixelBufferNotMetalCompatible.rawValue == kCVReturnPixelBufferNotMetalCompatible
    )
    precondition(
        CVError.wouldExceedAllocationThreshold.rawValue == kCVReturnWouldExceedAllocationThreshold
    )
    precondition(CVError.poolAllocationFailed.rawValue == kCVReturnPoolAllocationFailed)
    precondition(CVError.invalidPoolAttributes.rawValue == kCVReturnInvalidPoolAttributes)
    precondition(CVError.retry.rawValue == kCVReturnRetry)
    precondition(CVError(rawValue: kCVReturnSuccess) == nil)
    precondition(CVError(rawValue: kCVReturnUnsupported) == .unsupported)
    let _: CVError.RawValue = CVError.unsupported.rawValue
}

func testCVErrorCheck() {
    do {
        try CVError.check(kCVReturnSuccess)
    } catch {
        preconditionFailure("success must not throw")
    }
    do {
        try CVError.check(kCVReturnUnsupported)
        preconditionFailure("unsupported must throw")
    } catch {
        precondition(error == .unsupported)
    }
}

func testCVErrorDescriptions() {
    precondition(CVError.unsupported.description == "kCVReturnUnsupported")
    precondition(CVError.unsupported.errorDescription == "kCVReturnUnsupported")
    precondition(CVError.unsupported.localizedDescription == "kCVReturnUnsupported")
    precondition(CVError.unsupported != .invalidSize)
    var hasher = Hasher()
    CVError.unsupported.hash(into: &hasher)
    _ = CVError.unsupported.hashValue
}
