import Foundation

public typealias PHImageRequestID = Int32
public typealias PHAssetResourceDataRequestID = Int32
public typealias PHLivePhotoRequestID = Int32
public typealias PHContentEditingInputRequestID = Int
public typealias PHAssetImageProgressHandler = (
    Double, (any Error)?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?
) -> Void
public typealias PHAssetVideoProgressHandler = (
    Double, (any Error)?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?
) -> Void
public typealias PHAssetResourceProgressHandler = (Double) -> Void

public let PHImageCancelledKey = "PHImageCancelledKey"
public let PHImageErrorKey = "PHImageErrorKey"
public let PHImageResultIsDegradedKey = "PHImageResultIsDegradedKey"
public let PHImageResultIsInCloudKey = "PHImageResultIsInCloudKey"
public let PHImageResultRequestIDKey = "PHImageResultRequestIDKey"
public let PHContentEditingInputCancelledKey = "PHContentEditingInputCancelledKey"
public let PHContentEditingInputErrorKey = "PHContentEditingInputErrorKey"
public let PHContentEditingInputResultIsInCloudKey =
    "PHContentEditingInputResultIsInCloudKey"
public let PHLivePhotoInfoCancelledKey = "PHLivePhotoInfoCancelledKey"
public let PHLivePhotoInfoErrorKey = "PHLivePhotoInfoErrorKey"
public let PHLivePhotoInfoIsDegradedKey = "PHLivePhotoInfoIsDegradedKey"
public let PHLocalIdentifiersErrorKey = "PHLocalIdentifiersErrorKey"
public let PHPhotosErrorDomain = "PHPhotosErrorDomain"

public let PHInvalidImageRequestID: PHImageRequestID = 0
public let PHInvalidAssetResourceDataRequestID: PHAssetResourceDataRequestID = 0
public let PHLivePhotoRequestIDInvalid: PHLivePhotoRequestID = 0
public let PHImageManagerMaximumSize = CGSize(
    width: CGFloat.greatestFiniteMagnitude,
    height: CGFloat.greatestFiniteMagnitude
)

// Photos invalid-error probe, iPhone 17 / iOS 26.1 (23B86):
// PHPhotosErrorInvalid == -1 == PHPhotosError.Code.internalError.rawValue.
// SDK diagnostics give the iOS 14 / macOS 11 deprecation and rename.
@available(iOS, deprecated: 14.0, renamed: "PHPhotosError.invalid")
@available(macOS, deprecated: 11.0, renamed: "PHPhotosError.invalid")
public let PHPhotosErrorInvalid: Int = PHPhotosError.Code.internalError.rawValue

public let PHPhotosErrorUserCancelled: Int = PHPhotosError.Code.userCancelled.rawValue
public let PHPhotosErrorLibraryVolumeOffline: Int =
    PHPhotosError.Code.libraryVolumeOffline.rawValue
public let PHPhotosErrorRelinquishingLibraryBundleToWriter: Int =
    PHPhotosError.Code.relinquishingLibraryBundleToWriter.rawValue
public let PHPhotosErrorSwitchingSystemPhotoLibrary: Int =
    PHPhotosError.Code.switchingSystemPhotoLibrary.rawValue
