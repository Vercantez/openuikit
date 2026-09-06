import Foundation
@_spi(OpenUIKitHost) import StickerKit

final class AvatarEditorRecordingDelegate: NSObject, AvatarEditorViewControllerDelegate {
    var dismissCount = 0

    func avatarEditorRemoteViewControllerShouldDismiss() {
        dismissCount += 1
    }
}

func testAvatarEditorViewControllerDelegateProtocolConformance() {
    let probe = AvatarEditorRecordingDelegate()
    let asProtocol: any AvatarEditorViewControllerDelegate = probe
    let asObjectProtocol: any NSObjectProtocol = probe
    precondition((asProtocol as AnyObject) === probe)
    precondition((asObjectProtocol as AnyObject) === probe)
}

func testAvatarEditorRemoteViewControllerShouldDismissHostDelivery() {
    let editor = AvatarEditorViewController(nibName: nil, bundle: nil)
    let delegate = AvatarEditorRecordingDelegate()
    editor.delegate = delegate
    precondition(delegate.dismissCount == 0)

    delegate.avatarEditorRemoteViewControllerShouldDismiss()
    precondition(delegate.dismissCount == 1)

    editor.hostDeliverRemoteViewControllerShouldDismiss()
    precondition(delegate.dismissCount == 2)

    editor.viewDidLoad()
    editor.viewWillAppear(true)
    precondition(delegate.dismissCount == 2)
    precondition(!editor.linuxDidLoadRemoteViewController)

    editor.delegate = nil
    editor.hostDeliverRemoteViewControllerShouldDismiss()
    precondition(delegate.dismissCount == 2)
}
