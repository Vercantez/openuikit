import Foundation
import VideoToolbox

func vtExpect(_ condition: Bool, _ message: String) {
    guard condition else {
        fatalError("VIDEOTOOLBOX_RUNTIME_FAIL \(message)")
    }
}

func vtExpectStatus(_ status: OSStatus, _ expected: OSStatus, _ message: String) {
    vtExpect(status == expected, "\(message) got \(status) expected \(expected)")
}

final class VTTestBox: @unchecked Sendable {
    var image: OpaquePointer?
    var pts = VTMediaTime.invalid
    var duration = VTMediaTime.invalid
    var count = 0
    var handlerCalled = false
    var visited = 0
}

func testErrorConstantValues() {
    let pairs: [(OSStatus, OSStatus, String)] = [
        (kVTAllocationFailedErr, -12904, "kVTAllocationFailedErr"),
        (kVTColorCorrectionImageRotationFailedErr, -12219, "kVTColorCorrectionImageRotationFailedErr"),
        (kVTColorCorrectionPixelTransferFailedErr, -12212, "kVTColorCorrectionPixelTransferFailedErr"),
        (kVTColorSyncTransformConvertFailedErr, -12919, "kVTColorSyncTransformConvertFailedErr"),
        (kVTCouldNotCreateColorCorrectionDataErr, -12918, "kVTCouldNotCreateColorCorrectionDataErr"),
        (kVTCouldNotCreateInstanceErr, -12907, "kVTCouldNotCreateInstanceErr"),
        (kVTCouldNotFindExtensionErr, -19510, "kVTCouldNotFindExtensionErr"),
        (kVTCouldNotFindTemporalFilterErr, -12217, "kVTCouldNotFindTemporalFilterErr"),
        (kVTCouldNotFindVideoDecoderErr, -12906, "kVTCouldNotFindVideoDecoderErr"),
        (kVTCouldNotFindVideoEncoderErr, -12908, "kVTCouldNotFindVideoEncoderErr"),
        (kVTCouldNotOutputTaggedBufferGroupErr, -17699, "kVTCouldNotOutputTaggedBufferGroupErr"),
        (kVTExtensionConflictErr, -19511, "kVTExtensionConflictErr"),
        (kVTExtensionDisabledErr, -17697, "kVTExtensionDisabledErr"),
        (kVTFormatDescriptionChangeNotSupportedErr, -12916, "kVTFormatDescriptionChangeNotSupportedErr"),
        (kVTFrameSiloInvalidTimeRangeErr, -12216, "kVTFrameSiloInvalidTimeRangeErr"),
        (kVTFrameSiloInvalidTimeStampErr, -12215, "kVTFrameSiloInvalidTimeStampErr"),
        (kVTImageRotationNotSupportedErr, -12914, "kVTImageRotationNotSupportedErr"),
        (kVTInsufficientSourceColorDataErr, -12917, "kVTInsufficientSourceColorDataErr"),
        (kVTInvalidSessionErr, -12903, "kVTInvalidSessionErr"),
        (kVTMultiPassStorageIdentifierMismatchErr, -12913, "kVTMultiPassStorageIdentifierMismatchErr"),
        (kVTMultiPassStorageInvalidErr, -12214, "kVTMultiPassStorageInvalidErr"),
        (kVTParameterErr, -12902, "kVTParameterErr"),
        (kVTPixelRotationNotSupportedErr, -12914, "kVTPixelRotationNotSupportedErr"),
        (kVTPixelTransferNotPermittedErr, -12218, "kVTPixelTransferNotPermittedErr"),
        (kVTPixelTransferNotSupportedErr, -12905, "kVTPixelTransferNotSupportedErr"),
        (kVTPropertyNotSupportedErr, -12900, "kVTPropertyNotSupportedErr"),
        (kVTPropertyReadOnlyErr, -12901, "kVTPropertyReadOnlyErr"),
        (kVTSessionMalfunctionErr, -17691, "kVTSessionMalfunctionErr"),
        (kVTVideoDecoderAuthorizationErr, -12210, "kVTVideoDecoderAuthorizationErr"),
        (kVTVideoDecoderBadDataErr, -12909, "kVTVideoDecoderBadDataErr"),
        (kVTVideoDecoderCallbackMessagingErr, -17695, "kVTVideoDecoderCallbackMessagingErr"),
        (kVTVideoDecoderMalfunctionErr, -12911, "kVTVideoDecoderMalfunctionErr"),
        (kVTVideoDecoderNeedsRosettaErr, -17692, "kVTVideoDecoderNeedsRosettaErr"),
        (kVTVideoDecoderNotAvailableNowErr, -12913, "kVTVideoDecoderNotAvailableNowErr"),
        (kVTVideoDecoderReferenceMissingErr, -17694, "kVTVideoDecoderReferenceMissingErr"),
        (kVTVideoDecoderRemovedErr, -17690, "kVTVideoDecoderRemovedErr"),
        (kVTVideoDecoderUnknownErr, -17696, "kVTVideoDecoderUnknownErr"),
        (kVTVideoDecoderUnsupportedDataFormatErr, -12910, "kVTVideoDecoderUnsupportedDataFormatErr"),
        (kVTVideoEncoderAuthorizationErr, -12211, "kVTVideoEncoderAuthorizationErr"),
        (kVTVideoEncoderAutoWhiteBalanceNotLockedErr, -19512, "kVTVideoEncoderAutoWhiteBalanceNotLockedErr"),
        (kVTVideoEncoderMVHEVCVideoLayerIDsMismatchErr, -17698, "kVTVideoEncoderMVHEVCVideoLayerIDsMismatchErr"),
        (kVTVideoEncoderMalfunctionErr, -12912, "kVTVideoEncoderMalfunctionErr"),
        (kVTVideoEncoderNeedsRosettaErr, -17693, "kVTVideoEncoderNeedsRosettaErr"),
        (kVTVideoEncoderNotAvailableNowErr, -12915, "kVTVideoEncoderNotAvailableNowErr"),
    ]
    vtExpect(pairs.count >= 40, "error table size \(pairs.count)")
    for (value, expected, name) in pairs {
        vtExpect(value == expected, "\(name) got \(value) expected \(expected)")
        vtExpect(value != 0 || name.contains("Ok"), "nonzero \(name)")
    }
    let host = VTHostAllErrorConstants()
    vtExpect(host.count == pairs.count, "host error table")
}
