import Foundation

/// `NSInteger` cases follow independent `dotnet/macios` Native bindings
/// (`TuriCore = -1`, `Ok = 0`, then sequential). That is declaration
/// evidence, not an Apple runtime oracle.
public enum VNErrorCode: Int, CaseIterable, Sendable {
    case turiCoreErrorCode = -1
    case OK = 0
    case requestCancelled = 1
    case invalidFormat = 2
    case operationFailed = 3
    case outOfBoundsError = 4
    case invalidOption = 5
    case ioError = 6
    case missingOption = 7
    case notImplemented = 8
    case internalError = 9
    case outOfMemory = 10
    case unknownError = 11
    case invalidOperation = 12
    case invalidImage = 13
    case invalidArgument = 14
    case invalidModel = 15
    case unsupportedRevision = 16
    case dataUnavailable = 17
    case timeStampNotFound = 18
    case unsupportedRequest = 19
    case timeout = 20
    case unsupportedComputeStage = 21
    case unsupportedComputeDevice = 22
}

func vnMakeError(_ code: VNErrorCode, description: String? = nil) -> NSError {
    var info: [String: Any] = [:]
    if let description {
        info[NSLocalizedDescriptionKey] = description
    }
    return NSError(domain: VNErrorDomain, code: code.rawValue, userInfo: info)
}

func vnThrow(_ code: VNErrorCode, description: String) throws -> Never {
    throw vnMakeError(code, description: description)
}

func visionValidateNormalizedROI(_ roi: CGRect) throws {
    if roi.size.width < 0 || roi.size.height < 0 {
        throw vnMakeError(.invalidArgument, description: "regionOfInterest has negative size")
    }
    let eps: CGFloat = 1e-6
    if roi.origin.x < -eps || roi.origin.y < -eps
        || roi.origin.x + roi.size.width > 1 + eps
        || roi.origin.y + roi.size.height > 1 + eps
    {
        throw vnMakeError(.outOfBoundsError, description: "regionOfInterest is outside the unit square")
    }
}

func visionValidateRequestConfiguration(_ request: VNRequest) throws {
    let supported = type(of: request).supportedRevisions
    if !supported.contains(request.revision) {
        let unspecifiedOnly = supported == IndexSet(integer: VNRequestRevisionUnspecified)
        let matchesDefault = request.revision == type(of: request).defaultRevision
        if !(unspecifiedOnly && matchesDefault) {
            throw vnMakeError(
                .unsupportedRevision,
                description: "revision \(request.revision) is not in supportedRevisions"
            )
        }
    }
    if let imageRequest = request as? VNImageBasedRequest {
        try visionValidateNormalizedROI(imageRequest.regionOfInterest)
    }
}
