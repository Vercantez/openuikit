// Compile/run with the guest Foundation umbrella, never Apple Foundation.
import Foundation
import OpenUIKit

@MainActor
private final class DropSession: UIDropSession {
    let items: [UIDragItem]
    init(_ providers: [OpenUIKit.NSItemProvider]) {
        items = providers.map { UIDragItem(itemProvider: $0) }
    }
    let allowsMoveOperation = true
    let isRestrictedToDraggingApplication = false
    var localDragSession: (any UIDragSession)? { nil }
    var progressIndicatorStyle: UIDropSessionProgressIndicatorStyle = .default
    func location(in view: UIView) -> CGPoint { .zero }
    func hasItemsConforming(toTypeIdentifiers ids: [String]) -> Bool {
        items.contains { item in ids.contains {
            item.itemProvider.hasItemConformingToTypeIdentifier($0)
        } }
    }
    func canLoadObjects(ofClass type: Any.Type) -> Bool {
        if type == URL.self { return !_openUIKitLoadObjects(ofClass: URL.self).isEmpty }
        if type == String.self { return !_openUIKitLoadObjects(ofClass: String.self).isEmpty }
        return false
    }
}

@main
struct FocusGuestDragDrop {
    @MainActor
    static func main() {
        let construct: (URL) -> Foundation.NSItemProvider? =
            Foundation.NSItemProvider.init(contentsOf:)
        let url = URL(string: "https://example.org/focus")!
        guard let provider = construct(url) else { fatalError("URL bar produced no drag") }
        precondition(provider.registeredTypeIdentifiers == ["public.url"])
        provider.suggestedName = "focus"
        let drag = UIDragItem(itemProvider: provider)
        precondition(drag.itemProvider === provider)
        precondition(drag.localObject == nil)

        let copy = provider.copy() as! Foundation.NSItemProvider
        precondition(copy !== provider && copy.suggestedName == "focus")
        provider.suggestedName = "changed"
        precondition(copy.suggestedName == "focus")
        let coder = NSCoder()
        copy.encode(with: coder)
        copy.suggestedName = "changed again"
        let decoded = Foundation.NSItemProvider(coder: coder)!
        precondition(decoded.suggestedName == "focus")
        precondition(Foundation.NSItemProvider.supportsSecureCoding)
        precondition(Foundation.NSItemProvider(coder: NSCoder()) == nil)
        let extensionItem = NSExtensionItem()
        extensionItem.attachments = [decoded]
        let itemCoder = NSCoder()
        extensionItem.encode(with: itemCoder)
        let decodedItem = NSExtensionItem(coder: itemCoder)!
        precondition(decodedItem.attachments!.first === decoded)

        let text = Foundation.NSItemProvider(item: "focus", typeIdentifier: "public.utf8-plain-text")
        let session: any UIDropSession = DropSession([provider, copy, decoded, text])
        var callbacks = 0
        let progress: Foundation.Progress = session.loadObjects(ofClass: URL.self) {
            precondition($0 == [url, url, url]); callbacks += 1
        }
        precondition(callbacks == 1)
        precondition(progress.totalUnitCount == 3 && progress.completedUnitCount == 3)
        session.loadObjects(ofClass: String.self) { precondition($0 == ["focus"]) }
        let empty: any UIDropSession = DropSession([])
        empty.loadObjects(ofClass: URL.self) { precondition($0.isEmpty); callbacks += 1 }
        precondition(callbacks == 2)
        let local = URL(string: "https://example.org/local")!
        session.items[0].localObject = local
        session.loadObjects(ofClass: URL.self) { precondition($0 == [local, url, url]) }
        print("FOCUS_GUEST_DND_OK same-object=true urls=3 strings=1 callbacks=once progress=3/3 copy=coding=retained")
    }
}
