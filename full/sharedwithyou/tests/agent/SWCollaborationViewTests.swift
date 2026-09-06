import Foundation
@_spi(OpenUIKitHost) import SharedWithYou

func testCollaborationViewInitItemProvider() {
    let provider = NSItemProvider()
    let view = SWCollaborationView(itemProvider: provider)
    let asView: UIView = view
    swRequire(asView === view, "uiview")
}

func testCollaborationViewActiveParticipantCount() {
    let view = SWCollaborationView(itemProvider: NSItemProvider())
    swRequire(view.activeParticipantCount == 0, "zero")
    view.activeParticipantCount = 3
    swRequire(view.activeParticipantCount == 3, "three")
}

func testCollaborationViewHeaderTitle() {
    let view = SWCollaborationView(itemProvider: NSItemProvider())
    view.headerTitle = "Notes"
    swRequire(view.headerTitle == "Notes", "title")
}

func testCollaborationViewHeaderSubtitle() {
    let view = SWCollaborationView(itemProvider: NSItemProvider())
    view.headerSubtitle = "Shared"
    swRequire(view.headerSubtitle == "Shared", "subtitle")
}

func testCollaborationViewHeaderImage() {
    let view = SWCollaborationView(itemProvider: NSItemProvider())
    let image = UIImage()
    view.headerImage = image
    swRequire(view.headerImage === image, "image")
}

func testCollaborationViewManageButtonTitle() {
    let view = SWCollaborationView(itemProvider: NSItemProvider())
    view.manageButtonTitle = "Manage"
    swRequire(view.manageButtonTitle == "Manage", "title")
}

func testCollaborationViewSetShowManageButton() {
    let view = SWCollaborationView(itemProvider: NSItemProvider())
    swRequire(SharedWithYouHostControl.showsManageButton(view) == false, "hidden")
    view.setShowManageButton(true)
    swRequire(SharedWithYouHostControl.showsManageButton(view) == true, "shown")
}

func testCollaborationViewSetContent() {
    let view = SWCollaborationView(itemProvider: NSItemProvider())
    let content = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
    view.setContent(content)
    swRequire(SharedWithYouHostControl.contentView(view) === content, "content")
}

func testCollaborationViewDismissPopoverRunsCompletion() {
    let view = SWCollaborationView(itemProvider: NSItemProvider())
    var ran = false
    view.dismissPopover {
        ran = true
    }
    swRequire(ran, "completion")
}

func testCollaborationViewDismissPopoverNilCompletion() {
    let view = SWCollaborationView(itemProvider: NSItemProvider())
    view.dismissPopover(nil)
}

func testCollaborationViewDelegateProperty() {
    final class Probe: NSObject, SWCollaborationViewDelegate {}
    let view = SWCollaborationView(itemProvider: NSItemProvider())
    let probe = Probe()
    view.delegate = probe
    swRequire(view.delegate === probe, "delegate")
}

func testCollaborationViewCloudSharingDelegates() {
    final class Probe: NSObject, UICloudSharingControllerDelegate {}
    let view = SWCollaborationView(itemProvider: NSItemProvider())
    let probe = Probe()
    view.cloudSharingDelegate = probe
    view.cloudSharingControllerDelegate = probe
    swRequire(view.cloudSharingDelegate === probe, "sharing")
    swRequire(view.cloudSharingControllerDelegate === probe, "controller")
}

func testCollaborationViewShouldPresentDefault() {
    final class Probe: NSObject, SWCollaborationViewDelegate {}
    let view = SWCollaborationView(itemProvider: NSItemProvider())
    let probe = Probe()
    swRequire(probe.collaborationViewShouldPresentPopover(view) == true, "default true")
}

func testCollaborationViewWillPresentDefault() {
    final class Probe: NSObject, SWCollaborationViewDelegate {}
    let view = SWCollaborationView(itemProvider: NSItemProvider())
    Probe().collaborationViewWillPresentPopover(view)
}

func testCollaborationViewDidDismissDefault() {
    final class Probe: NSObject, SWCollaborationViewDelegate {}
    let view = SWCollaborationView(itemProvider: NSItemProvider())
    Probe().collaborationViewDidDismissPopover(view)
}
