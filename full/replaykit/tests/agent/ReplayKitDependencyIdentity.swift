import Foundation
import UIKit
import AVFoundation
import CoreMedia
import ReplayKit

#if os(Linux)
import Glibc
#endif

/// Future EC2 integration client.
///
/// Isolated `test_host.sh` does not compile or run this file. A later EC2 run
/// must build the real guest UIKit, AVFoundation, and CoreMedia modules first,
/// compile ReplayKit with those `-I`/`-L` paths, then link this client against
/// `libReplayKit.dylib` plus the dependency dylibs and run it with
/// `LD_LIBRARY_PATH`. It must not be taken as success of the isolated gate.

private final class PreviewDelegateProbe: NSObject, RPPreviewViewControllerDelegate {
    var didFinish = false
    var activityTypes: Set<String> = []

    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        _ = previewController
        didFinish = true
    }

    func previewController(
        _ previewController: RPPreviewViewController,
        didFinishWithActivityTypes activityTypes: Set<String>
    ) {
        _ = previewController
        self.activityTypes = activityTypes
    }
}

private final class ActivityDelegateProbe: NSObject, RPBroadcastActivityViewControllerDelegate {
    var sawFinish = false

    func broadcastActivityViewController(
        _ broadcastActivityViewController: RPBroadcastActivityViewController,
        didFinishWith broadcastController: RPBroadcastController?,
        error: (any Error)?
    ) {
        _ = (broadcastActivityViewController, broadcastController, error)
        sawFinish = true
    }
}

private final class RecorderDelegateProbe: NSObject, RPScreenRecorderDelegate {
    var availabilityChanged = false
    var sawStopWithPreview = false

    func screenRecorderDidChangeAvailability(_ screenRecorder: RPScreenRecorder) {
        _ = screenRecorder
        availabilityChanged = true
    }

    func screenRecorder(
        _ screenRecorder: RPScreenRecorder,
        didStopRecordingWith previewViewController: RPPreviewViewController?,
        error: (any Error)?
    ) {
        _ = (screenRecorder, previewViewController, error)
        sawStopWithPreview = true
    }
}

private func requireCode(_ error: (any Error)?, _ expected: RPRecordingErrorCode) {
    guard let code = error as? RPRecordingErrorCode else {
        fatalError("expected RPRecordingErrorCode, got \(String(describing: error))")
    }
    precondition(code == expected)
}

private func moduleName<T>(_ type: T.Type) -> String {
    String(reflecting: type)
}

private func libReplayKitIsLoaded() -> Bool {
    if let maps = try? String(contentsOfFile: "/proc/self/maps", encoding: .utf8),
       maps.contains("libReplayKit.dylib")
    {
        return true
    }
    return dlopen("libReplayKit.dylib", RTLD_NOW | RTLD_NOLOAD) != nil
}

@MainActor
private func proveUIKitSurface() {
    precondition(moduleName(UIViewController.self).contains("UIKit"))
    precondition(moduleName(UIView.self).contains("UIKit"))
    precondition(moduleName(UIImage.self).contains("UIKit"))

    let preview = RPPreviewViewController()
    precondition(preview is UIViewController)
    let asController: UIViewController = preview
    precondition(asController === preview)
    precondition(moduleName(RPPreviewViewController.self).contains("ReplayKit"))

    let previewDelegate = PreviewDelegateProbe()
    let previewExistential: any RPPreviewViewControllerDelegate = previewDelegate
    preview.previewControllerDelegate = previewExistential
    previewExistential.previewControllerDidFinish(preview)
    previewExistential.previewController(preview, didFinishWithActivityTypes: ["com.apple.UIKit.activity.CopyToPasteboard"])
    precondition(previewDelegate.didFinish)
    precondition(previewDelegate.activityTypes.contains("com.apple.UIKit.activity.CopyToPasteboard"))

    let picker = RPSystemBroadcastPickerView()
    precondition(picker is UIView)
    let asView: UIView = picker
    precondition(asView === picker)
    picker.preferredExtension = "org.example.BroadcastUpload"
    picker.showsMicrophoneButton = false
    precondition(picker.preferredExtension == "org.example.BroadcastUpload")
    precondition(!picker.showsMicrophoneButton)

    let activityDelegate = ActivityDelegateProbe()
    let activityExistential: any RPBroadcastActivityViewControllerDelegate = activityDelegate
    var loaded: RPBroadcastActivityViewController?
    var loadError: (any Error)?
    RPBroadcastActivityViewController.load { controller, error in
        loaded = controller
        loadError = error
    }
    precondition(loaded == nil)
    requireCode(loadError, .broadcastSetupFailed)
    activityExistential.broadcastActivityViewController(
        RPBroadcastActivityViewController(),
        didFinishWith: nil,
        error: RPRecordingErrorCode.broadcastSetupFailed
    )
    precondition(activityDelegate.sawFinish)
}

private func proveCoreMediaSurface() {
    precondition(moduleName(CMSampleBuffer.self).contains("CoreMedia"))

    let handler = RPBroadcastSampleHandler()
    let buffer = CMSampleBuffer()
    let process: (CMSampleBuffer, RPSampleBufferType) -> Void = { sample, type in
        handler.processSampleBuffer(sample, with: type)
    }
    process(buffer, .video)
    process(buffer, .audioApp)
    process(buffer, .audioMic)
    precondition(handler.portableLastSampleBufferType == .audioMic)

    let recorder = RPScreenRecorder.shared()
    var captureHandlerInvoked = false
    recorder.startCapture(handler: { sample, type, error in
        _ = (sample, type, error)
        captureHandlerInvoked = true
    }) { error in
        requireCode(error, .failedToStartCaptureStack)
    }
    precondition(!captureHandlerInvoked)
}

private func proveFoundationExtensionSurface() {
    precondition(moduleName(NSExtensionContext.self).contains("Foundation"))
    let context = NSExtensionContext()
    precondition(context is NSObject)

    var loadedBundle = "unset"
    var loadedName = "unset"
    var loadedIcon: UIImage?
    context.loadBroadcastingApplicationInfo { bundleID, name, icon in
        loadedBundle = bundleID
        loadedName = name
        loadedIcon = icon
    }
    precondition(loadedBundle.isEmpty)
    precondition(loadedName.isEmpty)
    precondition(loadedIcon == nil)

    let config = RPBroadcastConfiguration()
    context.completeRequest(
        withBroadcast: URL(string: "https://example.invalid/broadcast")!,
        broadcastConfiguration: config,
        setupInfo: nil
    )
    context.completeRequest(
        withBroadcast: URL(string: "https://example.invalid/broadcast")!,
        setupInfo: ["token": NSString(string: "none")]
    )
}

private func proveAVFoundationLinkage() {
    _ = AVFileType.mp4
    _ = String(reflecting: AVAsset.self)
}

private func proveRecorderDelegateExistential() {
    let recorder = RPScreenRecorder.shared()
    let probe = RecorderDelegateProbe()
    let existential: any RPScreenRecorderDelegate = probe
    recorder.delegate = existential
    existential.screenRecorderDidChangeAvailability(recorder)
    existential.screenRecorder(recorder, didStopRecordingWith: nil, error: nil)
    precondition(probe.availabilityChanged)
    precondition(probe.sawStopWithPreview)
    precondition(recorder.cameraPreviewView == nil)
    recorder.stopRecording { preview, error in
        precondition(preview == nil)
        requireCode(error, .attemptToStopNonRecording)
    }
}

precondition(libReplayKitIsLoaded())
proveAVFoundationLinkage()
proveFoundationExtensionSurface()
proveCoreMediaSurface()
proveRecorderDelegateExistential()
if Thread.isMainThread {
    MainActor.assumeIsolated {
        proveUIKitSurface()
    }
} else {
    DispatchQueue.main.sync {
        MainActor.assumeIsolated {
            proveUIKitSurface()
        }
    }
}

print("REPLAYKIT_DEPENDENCY_IDENTITY_OK")
