import Foundation
@_spi(OpenUIKitHost) import FileProviderUI

private final class ProbeActionViewController: FPUIActionExtensionViewController {
    var overrideAction: String?
    var overrideItems: [NSFileProviderItemIdentifier] = []
    var overrideError: (any Error)?

    override func prepare(
        forAction actionIdentifier: String,
        itemIdentifiers: [NSFileProviderItemIdentifier]
    ) {
        overrideAction = actionIdentifier
        overrideItems = itemIdentifiers
        super.prepare(forAction: actionIdentifier, itemIdentifiers: itemIdentifiers)
    }

    override func prepare(forError error: any Error) {
        overrideError = error
        super.prepare(forError: error)
    }
}

func testActionExtensionViewControllerClass() {
    let controller = FPUIActionExtensionViewController()
    let asViewController: UIViewController = controller
    precondition(asViewController === controller)
    precondition(type(of: controller) == FPUIActionExtensionViewController.self)
    precondition(controller.hostPreparedActionIdentifier == nil)
    precondition(controller.hostPreparedItemIdentifiers == nil)
    precondition(controller.hostPreparedError == nil)
}

func testExtensionContext() {
    let controller = FPUIActionExtensionViewController()
    let context = controller.extensionContext
    precondition(type(of: context) == FPUIActionExtensionContext.self)
    precondition(context.hostDisposition == .active)
    precondition(controller.extensionContext === context)
    context.completeRequest()
    precondition(controller.extensionContext.hostDisposition == .completed)
}

func testPrepareForAction() {
    let controller = ProbeActionViewController()
    let items = [
        NSFileProviderItemIdentifier("item-1"),
        NSFileProviderItemIdentifier(rawValue: "item-2"),
    ]
    controller.prepare(forAction: "com.example.share", itemIdentifiers: items)
    precondition(controller.overrideAction == "com.example.share")
    precondition(controller.overrideItems == items)
    precondition(controller.hostPreparedActionIdentifier == "com.example.share")
    precondition(controller.hostPreparedItemIdentifiers == items)
    precondition(controller.hostPreparedError == nil)
    precondition(controller.extensionContext.hostDisposition == .active)
}

func testPrepareForError() {
    let controller = ProbeActionViewController()
    controller.prepare(forError: FPUIExtensionErrorCode.failed)
    let stored = controller.overrideError as? FPUIExtensionErrorCode
    precondition(stored == .failed)
    let hostError = controller.hostPreparedError as? FPUIExtensionErrorCode
    precondition(hostError == .failed)
    precondition(controller.hostPreparedActionIdentifier == nil)
    precondition(controller.hostPreparedItemIdentifiers == nil)
    let nsError = hostError.map { $0 as NSError }
    precondition(nsError?.domain == FPUIErrorDomain)
    precondition(nsError?.code == 1)
}
