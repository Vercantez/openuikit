import Foundation
@_spi(OpenUIKitHost) import StickerKit

func testAvatarEditorViewControllerIsNSObjectSubclass() {
    let editor = AvatarEditorViewController(nibName: nil, bundle: nil)
    let asObject: NSObject = editor
    precondition(asObject === editor)
    let other = AvatarEditorViewController(nibName: nil, bundle: nil)
    precondition(editor !== other)
    precondition(type(of: editor) == AvatarEditorViewController.self)
    precondition(!editor.linuxDidPresentAppleAvatarEditor)
    precondition(!editor.linuxDidLoadRemoteViewController)
}

func testAvatarEditorViewControllerInitCoderFailsClosed() {
    let archiver = NSKeyedArchiver(requiringSecureCoding: true)
    archiver.encode("AvatarEditor", forKey: "nibName")
    precondition(AvatarEditorViewController(coder: archiver) == nil)

    let empty = NSKeyedArchiver(requiringSecureCoding: false)
    precondition(AvatarEditorViewController(coder: empty) == nil)
}

func testAvatarEditorViewControllerInitNibNameRecordsBundle() {
    let bundle = Bundle.main
    let editor = AvatarEditorViewController(nibName: "AvatarEditor", bundle: bundle)
    precondition(editor.linuxNibName == "AvatarEditor")
    precondition(editor.linuxNibBundle === bundle)

    let unnamed = AvatarEditorViewController(nibName: nil, bundle: nil)
    precondition(unnamed.linuxNibName == nil)
    precondition(unnamed.linuxNibBundle == nil)
    precondition(!unnamed.linuxIsViewLoaded)
    precondition(!unnamed.linuxDidPresentAppleAvatarEditor)
}

func testAvatarEditorViewControllerViewDidLoadMarksLoadedWithoutPresenting() {
    let editor = AvatarEditorViewController(nibName: "AvatarEditor", bundle: nil)
    precondition(!editor.linuxIsViewLoaded)
    editor.viewDidLoad()
    precondition(editor.linuxIsViewLoaded)
    editor.viewDidLoad()
    precondition(editor.linuxIsViewLoaded)
    precondition(!editor.linuxDidPresentAppleAvatarEditor)
    precondition(!editor.linuxDidLoadRemoteViewController)
    precondition(editor.linuxViewWillAppearCount == 0)
}

func testAvatarEditorViewControllerViewWillAppearRecordsAnimatedWithoutPresenting() {
    let editor = AvatarEditorViewController(nibName: nil, bundle: nil)
    let delegate = AvatarEditorRecordingDelegate()
    editor.delegate = delegate
    precondition(editor.linuxViewWillAppearCount == 0)
    precondition(editor.linuxLastViewWillAppearAnimated == nil)

    editor.viewWillAppear(true)
    precondition(editor.linuxViewWillAppearCount == 1)
    precondition(editor.linuxLastViewWillAppearAnimated == true)
    precondition(!editor.linuxIsViewLoaded)
    precondition(delegate.dismissCount == 0)

    editor.viewWillAppear(false)
    precondition(editor.linuxViewWillAppearCount == 2)
    precondition(editor.linuxLastViewWillAppearAnimated == false)
    precondition(!editor.linuxDidPresentAppleAvatarEditor)
    precondition(delegate.dismissCount == 0)
}

func testAvatarEditorViewControllerDelegateWeakStorage() {
    let editor = AvatarEditorViewController(nibName: nil, bundle: nil)
    precondition(editor.delegate == nil)
    do {
        let delegate = AvatarEditorRecordingDelegate()
        editor.delegate = delegate
        precondition(editor.delegate === delegate)
        editor.delegate = nil
        precondition(editor.delegate == nil)
        editor.delegate = delegate
        precondition(editor.delegate === delegate)
    }
    precondition(editor.delegate == nil)
}
