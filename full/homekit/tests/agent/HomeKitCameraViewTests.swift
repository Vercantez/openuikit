import Foundation
import HomeKit

// HMCameraView host identity: constructs the view, reads/writes cameraSource.
// Linux omits @MainActor (Darwin keeps it); the view never presents camera UI.

func testCameraViewHostIdentity() {
    let view = HMCameraView()
    _ = view.cameraSource
    let source = HMCameraSource()
    view.cameraSource = source
    _ = view.cameraSource
    _ = HMCameraView.self
}
