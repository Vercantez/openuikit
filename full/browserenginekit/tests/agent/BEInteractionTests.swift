import Foundation
import BrowserEngineKit

func testBEScrollViewDelegateRoundTrip() {
    let scrollView = BEScrollView(frame: .zero)
    precondition(scrollView.delegate == nil)
    final class HostDelegate: NSObject, BEScrollViewDelegate {}
    let delegate = HostDelegate()
    scrollView.delegate = delegate
    precondition(scrollView.delegate === delegate)
    scrollView.delegate = nil
    precondition(scrollView.delegate == nil)
}

func testBEScrollViewDelegateParentDefaultNil() {
    final class HostDelegate: NSObject, BEScrollViewDelegate {}
    let delegate = HostDelegate()
    let scrollView = BEScrollView()
    precondition(delegate.parentScrollView(for: scrollView) == nil)
}

func testBEScrollViewScrollUpdateLocationAndTranslation() {
    let update = BEScrollViewScrollUpdate.host_make(
        timestamp: 12.5,
        phase: .changed,
        location: CGPoint(x: 3, y: 4),
        translation: CGPoint(x: -1, y: 2)
    )
    precondition(update.timestamp == 12.5)
    precondition(update.phase == .changed)
    let view = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
    precondition(update.location(in: view) == CGPoint(x: 3, y: 4))
    precondition(update.translation(in: view) == CGPoint(x: -1, y: 2))
    precondition(update.location(in: nil) == CGPoint(x: 3, y: 4))
    precondition(update.translation(in: nil) == CGPoint(x: -1, y: 2))
}

func testBEWebAppManifestValidJSONObject() {
    let json = Data(#"{"name":"App","start_url":"/"}"#.utf8)
    let url = URL(string: "https://example.test/manifest.webmanifest")!
    let manifest = BEWebAppManifest(jsonData: json, manifestURL: url)
    precondition(manifest != nil)
    precondition(manifest?.jsonData == json)
    precondition(manifest?.manifestURL == url)
    let aliased = BEWebAppManifest(JSONData: json, manifestURL: url)
    precondition(aliased != nil)
}

func testBEWebAppManifestRejectsNonObjectJSON() {
    let array = Data("[1,2,3]".utf8)
    let url = URL(string: "https://example.test/m")!
    precondition(BEWebAppManifest(jsonData: array, manifestURL: url) == nil)
    precondition(BEWebAppManifest(jsonData: Data("not-json".utf8), manifestURL: url) == nil)
}

func testBEContextMenuConfigurationFulfillFalse() {
    let configuration = BEContextMenuConfiguration()
    precondition(configuration.fulfill(using: nil) == false)
    precondition(configuration.fulfill(using: UIContextMenuConfiguration()) == false)
}

func testBEDragInteractionStoresWeakDelegate() {
    final class HostDrag: NSObject, BEDragInteractionDelegate {}
    let delegate = HostDelegateBox(HostDrag())
    let interaction = BEDragInteraction(delegate: delegate.value)
    precondition(interaction.delegate === delegate.value)
}

private final class HostDelegateBox<T: AnyObject> {
    let value: T
    init(_ value: T) { self.value = value }
}

func testBETextInteractionRecordsHostActions() {
    let interaction = BETextInteraction()
    interaction.addShortcut(forText: "hi", from: CGRect(x: 1, y: 2, width: 3, height: 4))
    precondition(interaction.host_lastAction == .addShortcut("hi", CGRect(x: 1, y: 2, width: 3, height: 4)))
    interaction.share(text: "s", from: .zero)
    precondition(interaction.host_lastAction == .share("s", .zero))
    interaction.showDictionary(
        forTextInContext: "abc",
        definingTextInRange: NSRange(location: 1, length: 1),
        from: .zero
    )
    precondition(interaction.host_lastAction == .showDictionary("abc", NSRange(location: 1, length: 1), .zero))
    interaction.translate(text: "t", from: .zero)
    precondition(interaction.host_lastAction == .translate("t", .zero))
    interaction.showReplacements(forText: "r")
    precondition(interaction.host_lastAction == .showReplacements("r"))
    interaction.transliterateChinese(forText: "zh")
    precondition(interaction.host_lastAction == .transliterateChinese("zh"))
    interaction.presentEditMenuForSelection()
    precondition(interaction.host_lastAction == .presentEditMenu)
    interaction.dismissEditMenuForSelection()
    precondition(interaction.host_lastAction == .dismissEditMenu)
    interaction.editabilityChanged()
    precondition(interaction.host_lastAction == .editabilityChanged)
    interaction.refreshKeyboardUI()
    precondition(interaction.host_lastAction == .refreshKeyboardUI)
    interaction.selectionChangedWithGesture(
        at: CGPoint(x: 1, y: 1),
        gesture: .loupe,
        state: .began,
        flags: .wordIsNearTap
    )
    precondition(interaction.host_lastAction == .selectionGesture(CGPoint(x: 1, y: 1), .loupe, .began, .wordIsNearTap))
    interaction.selectionBoundaryAdjusted(to: .zero, touchPhase: .moved, flags: [])
    precondition(interaction.host_lastAction == .selectionBoundary(.zero, .moved, []))
    _ = interaction.contextMenuInteraction
    _ = interaction.textSelectionDisplayInteraction
    precondition(interaction.delegate == nil)
    precondition(interaction.contextMenuInteractionDelegate == nil)
}

private final class HostTextInteractionDelegate: BETextInteractionDelegate {
    var will = 0
    var did = 0
    func systemWillChangeSelection(for textInteraction: BETextInteraction) {
        _ = textInteraction
        will += 1
    }
    func systemDidChangeSelection(for textInteraction: BETextInteraction) {
        _ = textInteraction
        did += 1
    }
}

func testBETextInteractionDelegateCallbacks() {
    let delegate = HostTextInteractionDelegate()
    let interaction = BETextInteraction()
    delegate.systemWillChangeSelection(for: interaction)
    delegate.systemDidChangeSelection(for: interaction)
    precondition(delegate.will == 1)
    precondition(delegate.did == 1)
}
