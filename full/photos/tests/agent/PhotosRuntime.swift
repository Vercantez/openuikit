@_spi(OpenUIKitHost) import Photos
import Foundation

/// Isolated host probe kept for the wave-5 Runtime.swift requirement.
/// The sealed gate compiles `*Tests.swift` plus LoadSmoke, not this file.
func photosRuntimeProbe() {
    PHPhotoLibraryPortable._reset()
    precondition(PHPhotoLibrary.authorizationStatus(for: .addOnly) == .notDetermined)
    precondition(PHPhotosErrorDomain == "PHPhotosErrorDomain")
    print("PHOTOS_AGENT_RUNTIME_OK")
}
