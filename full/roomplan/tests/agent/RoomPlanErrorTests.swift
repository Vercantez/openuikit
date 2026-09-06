import Foundation
import RoomPlan

func testCapturedRoomErrorCases() {
    let errors: [CapturedRoom.Error] = [
        .urlInvalidScheme,
        .urlInvalidFilePath,
        .urlMissingFileExtension,
        .urlInvalidFileExtension,
        .deviceNotSupported,
    ]
    precondition(errors[0] == .urlInvalidScheme)
    precondition(errors[4] == .deviceNotSupported)
    precondition(CapturedRoom.Error.urlInvalidScheme != .deviceNotSupported)
}

func testCapturedRoomErrorDescriptions() {
    precondition(CapturedRoom.Error.urlInvalidScheme.errorDescription != nil)
    precondition(CapturedRoom.Error.urlInvalidFilePath.errorDescription!.contains("path"))
    precondition(CapturedRoom.Error.urlMissingFileExtension.errorDescription!.contains("extension"))
    precondition(CapturedRoom.Error.urlInvalidFileExtension.errorDescription!.contains("extension"))
    precondition(CapturedRoom.Error.deviceNotSupported.errorDescription!.contains("device"))
    precondition(!CapturedRoom.Error.deviceNotSupported.localizedDescription.isEmpty)
}

func testCaptureErrorCases() {
    let errors: [RoomCaptureSession.CaptureError] = [
        .exceedSceneSizeLimit,
        .worldTrackingFailure,
        .invalidARConfiguration,
        .deviceTooHot,
        .deviceNotSupported,
        .internalError,
    ]
    precondition(errors.count == 6)
    precondition(RoomCaptureSession.CaptureError.deviceNotSupported != .internalError)
    precondition(RoomCaptureSession.CaptureError.deviceTooHot != .worldTrackingFailure)
}

func testCaptureErrorDescriptions() {
    precondition(RoomCaptureSession.CaptureError.exceedSceneSizeLimit.errorDescription != nil)
    precondition(RoomCaptureSession.CaptureError.worldTrackingFailure.errorDescription!.contains("ARKit"))
    precondition(
        RoomCaptureSession.CaptureError.invalidARConfiguration.errorDescription!.contains("configuration")
    )
    precondition(RoomCaptureSession.CaptureError.deviceTooHot.errorDescription!.contains("thermal"))
    precondition(RoomCaptureSession.CaptureError.deviceNotSupported.errorDescription!.contains("device"))
    precondition(RoomCaptureSession.CaptureError.internalError.errorDescription!.contains("unexpected"))
    precondition(!RoomCaptureSession.CaptureError.deviceNotSupported.localizedDescription.isEmpty)
}

func testRoomBuilderBuildErrorCases() {
    let errors: [RoomBuilder.BuildError] = [
        .insufficientInput,
        .invalidInput,
        .exceedSceneSizeLimit,
        .deviceNotSupported,
        .internalError,
    ]
    precondition(errors.count == 5)
    precondition(RoomBuilder.BuildError.insufficientInput != .invalidInput)
}

func testRoomBuilderBuildErrorDescriptions() {
    precondition(RoomBuilder.BuildError.insufficientInput.errorDescription!.contains("more"))
    precondition(RoomBuilder.BuildError.invalidInput.errorDescription!.contains("invalid"))
    precondition(RoomBuilder.BuildError.exceedSceneSizeLimit.errorDescription!.contains("size"))
    precondition(RoomBuilder.BuildError.deviceNotSupported.errorDescription!.contains("device"))
    precondition(RoomBuilder.BuildError.internalError.errorDescription!.contains("unexpected"))
    precondition(!RoomBuilder.BuildError.invalidInput.localizedDescription.isEmpty)
}

func testStructureBuilderBuildErrorCases() {
    let errors: [StructureBuilder.BuildError] = [
        .insufficientInput,
        .invalidInput,
        .invalidRoomLocation,
        .exceedSceneSizeLimit,
        .deviceNotSupported,
        .internalError,
    ]
    precondition(errors.count == 6)
    precondition(StructureBuilder.BuildError.invalidRoomLocation != .invalidInput)
}

func testStructureBuilderBuildErrorDescriptions() {
    precondition(StructureBuilder.BuildError.insufficientInput.errorDescription != nil)
    precondition(StructureBuilder.BuildError.invalidInput.errorDescription!.contains("invalid"))
    precondition(StructureBuilder.BuildError.invalidRoomLocation.errorDescription!.contains("world"))
    precondition(StructureBuilder.BuildError.exceedSceneSizeLimit.errorDescription!.contains("size"))
    precondition(StructureBuilder.BuildError.deviceNotSupported.errorDescription!.contains("device"))
    precondition(StructureBuilder.BuildError.internalError.errorDescription!.contains("unexpected"))
    precondition(!StructureBuilder.BuildError.deviceNotSupported.localizedDescription.isEmpty)
}

func testModelProviderErrorCases() {
    let missing = URL(fileURLWithPath: "/tmp/missing.usdz")
    let fileError = CapturedRoom.ModelProvider.Error.nonExistingFile(url: missing)
    let combo = CapturedRoom.ModelProvider.Error.attributeCombinationNotSupported
    switch fileError {
    case .nonExistingFile(let url):
        precondition(url.path == missing.path)
    default:
        preconditionFailure("expected nonExistingFile")
    }
    switch combo {
    case .attributeCombinationNotSupported:
        break
    default:
        preconditionFailure("expected attributeCombinationNotSupported")
    }
}

func testModelProviderErrorDescriptions() {
    let missing = URL(fileURLWithPath: "/tmp/missing.usdz")
    precondition(
        CapturedRoom.ModelProvider.Error.attributeCombinationNotSupported.errorDescription!
            .contains("attributes")
    )
    precondition(
        CapturedRoom.ModelProvider.Error.nonExistingFile(url: missing).errorDescription!
            .contains("missing.usdz")
    )
    precondition(
        !CapturedRoom.ModelProvider.Error.attributeCombinationNotSupported.localizedDescription
            .isEmpty
    )
}

func testLocalizedErrorOptionals() {
    let roomError = CapturedRoom.Error.deviceNotSupported
    precondition(roomError.helpAnchor == nil)
    precondition(roomError.failureReason == nil)
    precondition(roomError.recoverySuggestion == nil)

    let captureError = RoomCaptureSession.CaptureError.deviceNotSupported
    precondition(captureError.helpAnchor == nil)
    precondition(captureError.failureReason == nil)
    precondition(captureError.recoverySuggestion == nil)

    let buildError = RoomBuilder.BuildError.deviceNotSupported
    precondition(buildError.helpAnchor == nil)
    precondition(buildError.failureReason == nil)
    precondition(buildError.recoverySuggestion == nil)

    let structureError = StructureBuilder.BuildError.invalidRoomLocation
    precondition(structureError.helpAnchor == nil)
    precondition(structureError.failureReason == nil)
    precondition(structureError.recoverySuggestion == nil)

    let providerError = CapturedRoom.ModelProvider.Error.attributeCombinationNotSupported
    precondition(providerError.helpAnchor == nil)
    precondition(providerError.failureReason == nil)
    precondition(providerError.recoverySuggestion == nil)
}

func testErrorInequalityAndHash() {
    precondition(CapturedRoom.Error.urlInvalidScheme != .urlInvalidFilePath)
    precondition(RoomCaptureSession.CaptureError.internalError != .deviceTooHot)
    precondition(RoomBuilder.BuildError.insufficientInput != .internalError)
    precondition(StructureBuilder.BuildError.invalidRoomLocation != .exceedSceneSizeLimit)

    var hasherA = Hasher()
    var hasherB = Hasher()
    CapturedRoom.Error.deviceNotSupported.hash(into: &hasherA)
    CapturedRoom.Error.deviceNotSupported.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(
        RoomCaptureSession.CaptureError.deviceNotSupported.hashValue
            == RoomCaptureSession.CaptureError.deviceNotSupported.hashValue
    )
    RoomBuilder.BuildError.invalidInput.hash(into: &hasherA)
    StructureBuilder.BuildError.insufficientInput.hash(into: &hasherB)
}
