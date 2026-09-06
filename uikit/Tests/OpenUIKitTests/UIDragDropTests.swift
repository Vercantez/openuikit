// Process-local drag and drop. Lift timing MEASURED GestureProbe,
// iPhone SE 2x / iOS 26.1: 0.325 s / 10 pt.
import XCTest
import Foundation
@testable import OpenUIKit

#if !os(Linux)
@MainActor
#endif
private final class DragSpy: UIDragInteractionDelegate {
    var began = 0
    var moved = 0
    var ended = 0
    var items: [UIDragItem]
    init(items: [UIDragItem]) { self.items = items }
    func dragInteraction(_ interaction: UIDragInteraction,
                         itemsForBeginning session: UIDragSession) -> [UIDragItem] {
        items
    }
    func dragInteraction(_ interaction: UIDragInteraction,
                         sessionWillBegin session: UIDragSession) { began += 1 }
    func dragInteraction(_ interaction: UIDragInteraction,
                         sessionDidMove session: UIDragSession) { moved += 1 }
    func dragInteraction(_ interaction: UIDragInteraction,
                         session: UIDragSession,
                         didEndWith operation: UIDropOperation) { ended += 1 }
}

#if !os(Linux)
@MainActor
#endif
private final class DropSpy: UIDropInteractionDelegate {
    var entered = 0
    var updated = 0
    var performed = 0
    var ended = 0
    var lastProposal = UIDropProposal(operation: .copy)
    func dropInteraction(_ interaction: UIDropInteraction,
                         sessionDidEnter session: UIDropSession) { entered += 1 }
    func dropInteraction(_ interaction: UIDropInteraction,
                         sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        updated += 1
        return lastProposal
    }
    func dropInteraction(_ interaction: UIDropInteraction,
                         performDrop session: UIDropSession) { performed += 1 }
    func dropInteraction(_ interaction: UIDropInteraction,
                         sessionDidEnd session: UIDropSession) { ended += 1 }
}

#if !os(Linux)
@MainActor
#endif
private final class TableSource: UITableViewDataSource {
    var rows = ["a", "b", "c"]
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = rows[indexPath.row]
        return cell
    }
}

#if !os(Linux)
@MainActor
#endif
private final class TableDragSpy: UITableViewDragDelegate, UITableViewDropDelegate {
    var willBegin = 0
    var didEnd = 0
    var dropped = 0
    var lastCoordinator: UITableViewDropCoordinator?
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession,
                   at indexPath: IndexPath) -> [UIDragItem] {
        let provider = NSItemProvider(item: rowsText(indexPath) as NSString, typeIdentifier: "public.utf8-plain-text")
        let item = UIDragItem(itemProvider: provider)
        item.localObject = rowsText(indexPath)
        return [item]
    }
    func rowsText(_ indexPath: IndexPath) -> String { "row-\(indexPath.row)" }
    func tableView(_ tableView: UITableView, dragSessionWillBegin session: UIDragSession) {
        willBegin += 1
    }
    func tableView(_ tableView: UITableView, dragSessionDidEnd session: UIDragSession) { didEnd += 1 }
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        dropped += 1
        lastCoordinator = coordinator
        if let item = coordinator.items.first?.dragItem {
            _ = coordinator.drop(item, toRowAt: coordinator.destinationIndexPath
                                    ?? IndexPath(row: 0, section: 0))
        }
    }
}

#if !os(Linux)
@MainActor
#endif
final class UIDragDropTests: XCTestCase {
    func testItemProviderAndSessionLoad() {
        let provider = NSItemProvider(item: "hello" as NSString, typeIdentifier: "public.utf8-plain-text")
        XCTAssertTrue(provider.hasItemConformingToTypeIdentifier("public.utf8-plain-text"))
        let item = UIDragItem(itemProvider: provider)
        item.localObject = "hello"
        XCTAssertEqual(item.itemProvider.registeredTypeIdentifiers, ["public.utf8-plain-text"])
        let session = _UIDragSessionImpl(items: [item], location: .zero, sourceView: nil)
        XCTAssertTrue(session.hasItemsConforming(toTypeIdentifiers: ["public.utf8-plain-text"]))
        XCTAssertTrue(session.canLoadObjects(ofClass: String.self))
        var loaded: [String] = []
        _ = session.loadObjects(ofClass: String.self) { loaded = $0 }
        XCTAssertEqual(loaded, ["hello"])
    }

    func testDropProposalOperationsAndIntents() {
        let copy = UIDropProposal(operation: .copy)
        XCTAssertEqual(copy.operation, .copy)
        XCTAssertFalse(copy.isPrecise)
        let table = UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        XCTAssertEqual(table.intent, .insertAtDestinationIndexPath)
        let collection = UICollectionViewDropProposal(operation: .forbidden,
                                                        intent: .insertIntoDestinationIndexPath)
        XCTAssertEqual(collection.operation, .forbidden)
        XCTAssertEqual(UIDropOperation.cancel.rawValue, 0)
        XCTAssertEqual(UIDropOperation.forbidden.rawValue, 1)
        XCTAssertEqual(UIDropOperation.copy.rawValue, 2)
        XCTAssertEqual(UIDropOperation.move.rawValue, 3)
    }

    func testDragInteractionLiftAtMeasuredDuration() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
        let v = UIView(frame: window.bounds)
        window.addSubview(v)
        let provider = NSItemProvider(item: "drag" as NSString, typeIdentifier: "public.utf8-plain-text")
        let item = UIDragItem(itemProvider: provider)
        item.localObject = "drag"
        let spy = DragSpy(items: [item])
        let interaction = UIDragInteraction(delegate: spy)
        XCTAssertTrue(UIDragInteraction.isEnabledByDefault)
        XCTAssertTrue(interaction.isEnabled)
        v.addInteraction(interaction)
        XCTAssertNotNil(interaction.liftPress)
        XCTAssertEqual(interaction.liftPress!.minimumPressDuration, 0.325, accuracy: 1e-12)
        XCTAssertEqual(interaction.liftPress!.allowableMovement, 10, accuracy: 1e-12)

        window.sendTouch(.began, at: CGPoint(x: 50, y: 50), timestamp: 0)
        window.tick(timestamp: 0.2)
        XCTAssertEqual(spy.began, 0)
        window.tick(timestamp: 0.33)
        XCTAssertEqual(spy.began, 1)
        XCTAssertNotNil(_UIDragDropCenter.active)
        window.sendTouch(.moved, at: CGPoint(x: 80, y: 50), timestamp: 0.40)
        XCTAssertEqual(spy.moved, 1)
        window.sendTouch(.ended, at: CGPoint(x: 80, y: 50), timestamp: 0.45)
        XCTAssertEqual(spy.ended, 1)
        XCTAssertNil(_UIDragDropCenter.active)
    }

    func testDropInteractionReceivesSession() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
        let source = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let dest = UIView(frame: CGRect(x: 200, y: 0, width: 100, height: 100))
        window.addSubview(source)
        window.addSubview(dest)
        let provider = NSItemProvider(item: "x" as NSString, typeIdentifier: "public.utf8-plain-text")
        let item = UIDragItem(itemProvider: provider)
        let dragSpy = DragSpy(items: [item])
        source.addInteraction(UIDragInteraction(delegate: dragSpy))
        let dropSpy = DropSpy()
        dest.addInteraction(UIDropInteraction(delegate: dropSpy))

        window.sendTouch(.began, at: CGPoint(x: 40, y: 40), timestamp: 0)
        window.tick(timestamp: 0.33)
        XCTAssertEqual(dragSpy.began, 1)
        window.sendTouch(.moved, at: CGPoint(x: 240, y: 40), timestamp: 0.40)
        XCTAssertGreaterThanOrEqual(dropSpy.entered, 1)
        XCTAssertGreaterThanOrEqual(dropSpy.updated, 1)
        window.sendTouch(.ended, at: CGPoint(x: 240, y: 40), timestamp: 0.45)
        XCTAssertEqual(dropSpy.performed, 1)
        XCTAssertEqual(dropSpy.ended, 1)
    }

    func testTableDragDropDelegateOrderAndPlaceholder() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
        let table = UITableView(frame: window.bounds, style: .plain)
        let source = TableSource()
        let spy = TableDragSpy()
        table.dataSource = source
        table.dragDelegate = spy
        table.dropDelegate = spy
        window.addSubview(table)
        table.reloadData()
        table.layoutIfNeeded()
        XCTAssertTrue(table.dragInteractionEnabled)
        XCTAssertEqual(table._dragLift!.minimumPressDuration, 0.325, accuracy: 1e-12)

        let path = IndexPath(row: 0, section: 0)
        let rect = table.rectForRow(at: path)
        let p = CGPoint(x: rect.midX, y: rect.midY)
        window.sendTouch(.began, at: p, timestamp: 0)
        window.tick(timestamp: 0.33)
        XCTAssertEqual(spy.willBegin, 1)
        XCTAssertTrue(table.hasActiveDrag)
        window.sendTouch(.moved, at: CGPoint(x: rect.midX, y: rect.midY + 80), timestamp: 0.40)
        window.sendTouch(.ended, at: CGPoint(x: rect.midX, y: rect.midY + 80), timestamp: 0.45)
        XCTAssertEqual(spy.dropped, 1)
        XCTAssertEqual(spy.didEnd, 1)
        XCTAssertFalse(table.hasActiveDrag)

        let placeholder = UITableViewDropPlaceholder(
            insertionIndexPath: IndexPath(row: 1, section: 0),
            reuseIdentifier: "cell", rowHeight: 44)
        let coordinator = spy.lastCoordinator
        XCTAssertNotNil(coordinator)
        if let item = coordinator?.items.first?.dragItem {
            let ctx = coordinator!.drop(item, to: placeholder)
            var committed: IndexPath?
            XCTAssertTrue(ctx.commitInsertion { committed = $0 })
            XCTAssertEqual(committed, placeholder.insertionIndexPath)
            XCTAssertFalse(ctx.deletePlaceholder())
        }
    }

    func testPasteConfiguration() {
        let view = UIView()
        XCTAssertNil(view.pasteConfiguration)
        let config = UIPasteConfiguration(acceptableTypeIdentifiers: ["public.utf8-plain-text"])
        view.pasteConfiguration = config
        let provider = NSItemProvider(item: "x" as NSString, typeIdentifier: "public.utf8-plain-text")
        XCTAssertTrue(view.canPaste(itemProviders: [provider]))
        let other = NSItemProvider(item: nil, typeIdentifier: "public.image")
        XCTAssertFalse(view.canPaste(itemProviders: [other]))
        view.paste(itemProviders: [provider])
    }

    func testPreviewDescriptorsStoreInputs() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 20))
        let params = UIDragPreviewParameters()
        let preview = UIDragPreview(view: view, parameters: params)
        XCTAssertTrue(preview.view === view)
        let target = UIDragPreviewTarget(container: view, center: CGPoint(x: 10, y: 10))
        let targeted = UITargetedDragPreview(view: view, parameters: params, target: target)
        XCTAssertEqual(targeted.size, CGSize(width: 40, height: 20))
        let moved = targeted.retargetedPreview(
            with: UIDragPreviewTarget(container: view, center: CGPoint(x: 4, y: 4)))
        XCTAssertEqual(moved.target.center, CGPoint(x: 4, y: 4))
    }

    func testCollectionDropCoordinatorPlaceholderAndDropToItem() {
        let provider = NSItemProvider(item: "x" as NSString, typeIdentifier: "public.utf8-plain-text")
        let item = UIDragItem(itemProvider: provider)
        let session = _UIDragSessionImpl(items: [item], location: .zero, sourceView: nil)
        let cv = UICollectionView(frame: CGRect(x: 0, y: 0, width: 200, height: 200),
                                     collectionViewLayout: UICollectionViewFlowLayout())
        let dest = IndexPath(item: 1, section: 0)
        let coord = _UICollectionViewDropCoordinatorImpl(session: session, collection: cv,
                                                        destination: dest)
        XCTAssertEqual(coord.destinationIndexPath, dest)
        XCTAssertEqual(coord.items.count, 1)
        let placeholder = UICollectionViewDropPlaceholder(
            insertionIndexPath: dest, reuseIdentifier: "cell")
        let ctx = coord.drop(item, to: placeholder)
        var committed: IndexPath?
        XCTAssertTrue(ctx.commitInsertion { committed = $0 })
        XCTAssertEqual(committed, dest)
        XCTAssertFalse(ctx.deletePlaceholder())
        _ = coord.drop(item, toItemAt: dest)
        _ = coord.drop(item, intoItemAt: dest, rect: CGRect(x: 0, y: 0, width: 10, height: 10))
        _ = coord.drop(item, to: UIDragPreviewTarget(container: cv, center: .zero))
    }
}