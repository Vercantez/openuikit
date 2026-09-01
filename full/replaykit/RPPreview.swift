import Foundation

#if canImport(UIKit)
import UIKit

public protocol RPPreviewViewControllerDelegate: NSObjectProtocol {
    func previewControllerDidFinish(_ previewController: RPPreviewViewController)

    func previewController(
        _ previewController: RPPreviewViewController,
        didFinishWithActivityTypes activityTypes: Set<String>
    )
}

public extension RPPreviewViewControllerDelegate {
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        _ = previewController
    }

    func previewController(
        _ previewController: RPPreviewViewController,
        didFinishWithActivityTypes activityTypes: Set<String>
    ) {
        _ = (previewController, activityTypes)
    }
}

/// Recording preview controller. Linux never produces a recording, so this
/// type exists for source compatibility and delegate wiring only. It is a
/// real `UIKit.UIViewController` subclass when UIKit is imported.
@MainActor
open class RPPreviewViewController: UIViewController, @unchecked Sendable {
    open weak var previewControllerDelegate: RPPreviewViewControllerDelegate?
}

public protocol RPBroadcastActivityViewControllerDelegate: NSObjectProtocol {
    func broadcastActivityViewController(
        _ broadcastActivityViewController: RPBroadcastActivityViewController,
        didFinishWith broadcastController: RPBroadcastController?,
        error: (any Error)?
    )
}

/// System UI that lets the user pick a broadcast service. With no extension
/// catalog, `load` fails closed with a typed ReplayKit error.
@MainActor
open class RPBroadcastActivityViewController: UIViewController, @unchecked Sendable {
    open weak var delegate: RPBroadcastActivityViewControllerDelegate?

    open class func load(
        handler: @escaping (RPBroadcastActivityViewController?, (any Error)?) -> Void
    ) {
        handler(nil, replayKitUnavailableError(.broadcastSetupFailed))
    }

    open class func load(
        withPreferredExtension preferredExtension: String?,
        handler: @escaping (RPBroadcastActivityViewController?, (any Error)?) -> Void
    ) {
        _ = preferredExtension
        load(handler: handler)
    }
}

/// View that hosts the system broadcast picker button.
///
/// Preferred-extension and microphone-button flags are stored. The control
/// does not present Control Center or start a broadcast. It is a real
/// `UIKit.UIView` subclass when UIKit is imported.
@MainActor
open class RPSystemBroadcastPickerView: UIView, @unchecked Sendable {
    open var preferredExtension: String?
    open var showsMicrophoneButton = true
}

#endif
