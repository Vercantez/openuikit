#if canImport(UIKit) && canImport(CoreMedia) && canImport(AVFoundation)
import AVFoundation
import CoreMedia
import Foundation
import ReplayKit
import UIKit

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest UIKit/AVFoundation
// success.
//
// Expected EC2 steps (no local Docker):
// 1. Build guest Foundation, UIKit, AVFoundation, and CoreMedia dylibs.
// 2. Build ReplayKit with those modules on `-I` / `-L`.
// 3. Link this file as a client that imports ReplayKit and the dependencies.
// 4. Run with `LD_LIBRARY_PATH` covering every dylib.
// 5. Confirm `REPLAYKIT_DEPENDENCY_IDENTITY_OK` and that `libReplayKit.dylib`
//    was loaded.

private func assertNotReplayKitType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("ReplayKit."))
}

enum ReplayKitDependencyIdentity {
    static func main() {
        let preview: UIKit.UIViewController = RPPreviewViewController()
        assertNotReplayKitType(type(of: preview) as Any)
        precondition(preview is RPPreviewViewController)

        let activity: UIKit.UIViewController = RPBroadcastActivityViewController()
        precondition(activity is RPBroadcastActivityViewController)

        let picker: UIKit.UIView = RPSystemBroadcastPickerView(frame: .zero)
        precondition(picker is RPSystemBroadcastPickerView)

        let _: (RPBroadcastSampleHandler) -> (CMSampleBuffer, RPSampleBufferType) -> Void =
            { handler in
                { sample, type in
                    handler.processSampleBuffer(sample, with: type)
                }
            }

        let contextType = NSExtensionContext.self
        assertNotReplayKitType(contextType)
        let _: (NSExtensionContext) -> (URL, [String: any NSCoding & NSObjectProtocol]?) -> Void =
            { context in
                { url, info in
                    context.completeRequest(withBroadcast: url, setupInfo: info)
                }
            }

        let recorder = RPScreenRecorder.shared()
        let availability: any RPScreenRecorderDelegate = IdentityRecorderDelegate()
        availability.screenRecorderDidChangeAvailability(recorder)

        let controller = RPBroadcastController()
        let broadcastDelegate: any RPBroadcastControllerDelegate = IdentityBroadcastDelegate()
        broadcastDelegate.broadcastController(controller, didFinishWithError: nil)

        print("REPLAYKIT_DEPENDENCY_IDENTITY_OK")
    }
}

private final class IdentityRecorderDelegate: NSObject, RPScreenRecorderDelegate {
    func screenRecorderDidChangeAvailability(_ screenRecorder: RPScreenRecorder) {
        _ = screenRecorder
    }
}

private final class IdentityBroadcastDelegate: NSObject, RPBroadcastControllerDelegate {}

ReplayKitDependencyIdentity.main()
#endif
