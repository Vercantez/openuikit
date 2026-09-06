// Drag and drop — process-local session model. Owner: event module.
//
// Census (full/ladder/APP_LADDER.md §4 row 15, 2026-08-27): UIDropSession
// 8 apps / 61 uses, UIDragItem 7/41, UIDragSession 7/27, plus
// UIDragInteraction / UIDropInteraction and the table/collection
// drag+drop delegates. Previews are stored as data (no live lift
// composite — docs/KNOWN_GAPS.md).
//
// MEASURED GestureProbe, iPhone SE 2x / iOS 26.1:
//   UIDragInteraction.isEnabledByDefault = true
//   _UIDragLiftGestureRecognizer.minimumPressDuration = 0.325
//   allowableMovement = 10 (same slop as pan / long-press)
// The session is driven by that long-press lift; drop proposals are
// copy/move/cancel/forbidden with table/collection intents.

#if canImport(Foundation)
import Foundation
import class Foundation.NSObject
#elseif canImport(ObjectiveC)
import class ObjectiveC.NSObject
#endif
#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
#endif
#if !canImport(Foundation) && canImport(FoundationEssentials)
// Guest library route (merge_gestures47-merged.log UIDragDrop.swift:192/202):
// `canLoadObjects` names `URL.self` for localObject; Foundation hidden,
// URL lives on FoundationEssentials (UIPrintInteractionController sibling).
import struct FoundationEssentials.URL
#endif

// MARK: - Drop operation / proposal

public enum UIDropOperation: Int, Sendable {
    case cancel = 0
    case forbidden = 1
    case copy = 2
    case move = 3
}

public enum UIDropSessionProgressIndicatorStyle: Int, Sendable {
    case none = 0
    case `default` = 1
}

@preconcurrency @MainActor
open class UIDropProposal {
    public let operation: UIDropOperation
    public var isPrecise = false
    public var prefersFullSizePreview = false

    public init(operation: UIDropOperation) {
        self.operation = operation
    }
}

public enum UITableViewDropIntent: Int, Sendable {
    case unspecified = 0
    case insertAtDestinationIndexPath = 1
    case insertIntoDestinationIndexPath = 2
    case automatic = 3
}

@preconcurrency @MainActor
open class UITableViewDropProposal: UIDropProposal {
    public let intent: UITableViewDropIntent
    public init(operation: UIDropOperation, intent: UITableViewDropIntent) {
        self.intent = intent
        super.init(operation: operation)
    }

    public override init(operation: UIDropOperation) {
        self.intent = .unspecified
        super.init(operation: operation)
    }
}

public enum UICollectionViewDropIntent: Int, Sendable {
    case unspecified = 0
    case insertAtDestinationIndexPath = 1
    case insertIntoDestinationIndexPath = 2
}

@preconcurrency @MainActor
open class UICollectionViewDropProposal: UIDropProposal {
    public let intent: UICollectionViewDropIntent
    public init(operation: UIDropOperation, intent: UICollectionViewDropIntent) {
        self.intent = intent
        super.init(operation: operation)
    }

    public override init(operation: UIDropOperation) {
        self.intent = .unspecified
        super.init(operation: operation)
    }
}

// MARK: - Drag item / preview

@preconcurrency @MainActor
open class UIDragPreview {
    public let view: UIView
    public let parameters: UIDragPreviewParameters
    public init(view: UIView, parameters: UIDragPreviewParameters) {
        self.view = view
        self.parameters = parameters
    }
    public convenience init(view: UIView) {
        self.init(view: view, parameters: UIDragPreviewParameters())
    }
}

@preconcurrency @MainActor
open class UIDragItem {
    public let itemProvider: NSItemProvider
    public var localObject: Any?
    public var previewProvider: (() -> UIDragPreview?)?

    public init(itemProvider: NSItemProvider) {
        self.itemProvider = itemProvider
    }

    public func setNeedsDropPreviewUpdate() {}
}

// MARK: - Sessions

@preconcurrency @MainActor
public protocol UIDragDropSession: AnyObject {
    var items: [UIDragItem] { get }
    var allowsMoveOperation: Bool { get }
    var isRestrictedToDraggingApplication: Bool { get }
    func location(in view: UIView) -> CGPoint
    func hasItemsConforming(toTypeIdentifiers typeIdentifiers: [String]) -> Bool
    func canLoadObjects(ofClass aClass: Any.Type) -> Bool
}

extension UIDragDropSession {
    public func canLoadObjects<T>(ofClass type: T.Type) -> Bool {
        canLoadObjects(ofClass: type as Any.Type)
    }
}

@preconcurrency @MainActor
public protocol UIDragSession: UIDragDropSession {
    var localContext: Any? { get set }
}

@preconcurrency @MainActor
public protocol UIDropSession: UIDragDropSession {
    var localDragSession: UIDragSession? { get }
    var progressIndicatorStyle: UIDropSessionProgressIndicatorStyle { get set }
#if canImport(Foundation)
    @discardableResult
    func loadObjects<T>(ofClass type: T.Type, completion: @escaping ([T]) -> Void) -> Progress
#endif
}

@preconcurrency @MainActor
final class _UIDragSessionImpl: UIDragSession, UIDropSession {
    var items: [UIDragItem]
    var allowsMoveOperation = true
    var isRestrictedToDraggingApplication = false
    var localContext: Any?
    var localDragSession: UIDragSession? { self }
    var progressIndicatorStyle: UIDropSessionProgressIndicatorStyle = .default
    var locationInWindow: CGPoint = .zero
    weak var sourceView: UIView?
    weak var sourceTable: UITableView?
    weak var sourceCollection: UICollectionView?
    var destinationIndexPath: IndexPath?
    var enteredDrop: [ObjectIdentifier] = []

    init(items: [UIDragItem], location: CGPoint, sourceView: UIView?) {
        self.items = items
        self.locationInWindow = location
        self.sourceView = sourceView
    }

    func location(in view: UIView) -> CGPoint {
        view.convert(locationInWindow, from: view.window ?? sourceView?.window)
    }

    func hasItemsConforming(toTypeIdentifiers typeIdentifiers: [String]) -> Bool {
        for item in items {
            for id in typeIdentifiers {
                if item.itemProvider.hasItemConformingToTypeIdentifier(id) { return true }
            }
        }
        return false
    }

    func canLoadObjects(ofClass aClass: Any.Type) -> Bool {
        for item in items {
            if let obj = item.localObject {
                if type(of: obj) == aClass { return true }
                if aClass == String.self, obj is String { return true }
                // MEASURED merge_gestures47-merged.log:192/202 — URL.self
                // needs Foundation or FoundationEssentials (import above).
                if aClass == URL.self, obj is URL { return true }
            }
#if os(Linux) || !canImport(Foundation)
            if item.itemProvider._canLoad(aClass) { return true }
#else
            if aClass == String.self,
               item.itemProvider.hasItemConformingToTypeIdentifier("public.utf8-plain-text")
                || item.itemProvider.hasItemConformingToTypeIdentifier("public.text") {
                return true
            }
            if aClass == URL.self,
               item.itemProvider.hasItemConformingToTypeIdentifier("public.url")
                || item.itemProvider.hasItemConformingToTypeIdentifier("public.file-url") {
                return true
            }
            if !item.itemProvider.registeredTypeIdentifiers.isEmpty { return true }
#endif
        }
        return false
    }

#if canImport(Foundation)
    @discardableResult
    func loadObjects<T>(ofClass type: T.Type, completion: @escaping ([T]) -> Void) -> Progress {
        var out: [T] = []
        for item in items {
            if let obj = item.localObject as? T {
                out.append(obj)
                continue
            }
#if os(Linux)
            if let obj = item.itemProvider._load(type) { out.append(obj) }
#else
            if let obj = item.itemProvider._openUIKitLoad(type) { out.append(obj) }
#endif
        }
        completion(out)
        return Progress(totalUnitCount: Int64(out.count))
    }
#endif
}

@MainActor
enum _UIDragDropCenter {
    static var active: _UIDragSessionImpl?
}

// MARK: - Animating

@preconcurrency @MainActor
public protocol UIDragAnimating: AnyObject {
    func addAnimations(_ animations: @escaping () -> Void)
    func addCompletion(_ completion: @escaping (UIViewAnimatingPosition) -> Void)
}

@preconcurrency @MainActor
final class _UIDragAnimator: UIDragAnimating {
    func addAnimations(_ animations: @escaping () -> Void) { animations() }
    func addCompletion(_ completion: @escaping (UIViewAnimatingPosition) -> Void) {
        completion(.end)
    }
}

// MARK: - Interactions

@preconcurrency @MainActor
public protocol UIDragInteractionDelegate: AnyObject {
    func dragInteraction(_ interaction: UIDragInteraction,
                         itemsForBeginning session: UIDragSession) -> [UIDragItem]
    func dragInteraction(_ interaction: UIDragInteraction,
                         previewForLifting item: UIDragItem,
                         session: UIDragSession) -> UITargetedDragPreview?
    func dragInteraction(_ interaction: UIDragInteraction,
                         sessionWillBegin session: UIDragSession)
    func dragInteraction(_ interaction: UIDragInteraction,
                         sessionAllowsMoveOperation session: UIDragSession) -> Bool
    func dragInteraction(_ interaction: UIDragInteraction,
                         sessionIsRestrictedToDraggingApplication session: UIDragSession) -> Bool
    func dragInteraction(_ interaction: UIDragInteraction,
                         sessionDidMove session: UIDragSession)
    func dragInteraction(_ interaction: UIDragInteraction,
                         session: UIDragSession,
                         willEndWith operation: UIDropOperation)
    func dragInteraction(_ interaction: UIDragInteraction,
                         session: UIDragSession,
                         didEndWith operation: UIDropOperation)
    func dragInteraction(_ interaction: UIDragInteraction,
                         sessionDidTransferItems session: UIDragSession)
}

public extension UIDragInteractionDelegate {
    func dragInteraction(_ interaction: UIDragInteraction,
                         previewForLifting item: UIDragItem,
                         session: UIDragSession) -> UITargetedDragPreview? { nil }
    func dragInteraction(_ interaction: UIDragInteraction,
                         sessionWillBegin session: UIDragSession) {}
    func dragInteraction(_ interaction: UIDragInteraction,
                         sessionAllowsMoveOperation session: UIDragSession) -> Bool { true }
    func dragInteraction(_ interaction: UIDragInteraction,
                         sessionIsRestrictedToDraggingApplication session: UIDragSession) -> Bool { false }
    func dragInteraction(_ interaction: UIDragInteraction,
                         sessionDidMove session: UIDragSession) {}
    func dragInteraction(_ interaction: UIDragInteraction,
                         session: UIDragSession,
                         willEndWith operation: UIDropOperation) {}
    func dragInteraction(_ interaction: UIDragInteraction,
                         session: UIDragSession,
                         didEndWith operation: UIDropOperation) {}
    func dragInteraction(_ interaction: UIDragInteraction,
                         sessionDidTransferItems session: UIDragSession) {}
}

@preconcurrency @MainActor
public final class UIDragInteraction: UIInteraction {
    public private(set) weak var delegate: UIDragInteractionDelegate?
    public private(set) weak var view: UIView?
    public var allowsSimultaneousRecognitionDuringLift = false
    public var isEnabled: Bool
    /// MEASURED GestureProbe, iPhone SE 2x / iOS 26.1: true.
    public static var isEnabledByDefault: Bool { true }

    var liftPress: UILongPressGestureRecognizer?

    public init(delegate: UIDragInteractionDelegate) {
        self.delegate = delegate
        self.isEnabled = UIDragInteraction.isEnabledByDefault
    }

    public func willMove(to view: UIView?) {
        if let press = liftPress {
            self.view?.removeGestureRecognizer(press)
            liftPress = nil
        }
    }

    public func didMove(to view: UIView?) {
        self.view = view
        guard let view else { return }
        // MEASURED GestureProbe: _UIDragLiftGestureRecognizer duration 0.325,
        // allowableMovement 10.
        let press = UILongPressGestureRecognizer { [weak self] r in
            self?.handleLift(r)
        }
        press.minimumPressDuration = 0.325
        press.allowableMovement = 10
        view.addGestureRecognizer(press)
        liftPress = press
    }

    func handleLift(_ recognizer: UIGestureRecognizer) {
        guard isEnabled, let view, let delegate else { return }
        guard let press = recognizer as? UILongPressGestureRecognizer else { return }
        switch press.state {
        case .began:
            let loc = press.location(in: nil)
            let session = _UIDragSessionImpl(items: [], location: loc, sourceView: view)
            let items = delegate.dragInteraction(self, itemsForBeginning: session)
            guard !items.isEmpty else { return }
            session.items = items
            session.allowsMoveOperation = delegate.dragInteraction(self, sessionAllowsMoveOperation: session)
            session.isRestrictedToDraggingApplication =
                delegate.dragInteraction(self, sessionIsRestrictedToDraggingApplication: session)
            _UIDragDropCenter.active = session
            delegate.dragInteraction(self, sessionWillBegin: session)
        case .changed:
            guard let session = _UIDragDropCenter.active else { return }
            session.locationInWindow = press.location(in: nil)
            delegate.dragInteraction(self, sessionDidMove: session)
            session._updateDrops()
        case .ended:
            finish(operation: _UIDragDropCenter.active?._dropOperation() ?? .cancel)
        case .cancelled:
            finish(operation: .cancel)
        default:
            break
        }
    }

    func finish(operation: UIDropOperation) {
        guard let session = _UIDragDropCenter.active else { return }
        delegate?.dragInteraction(self, session: session, willEndWith: operation)
        session._performDropIfNeeded(operation: operation)
        delegate?.dragInteraction(self, session: session, didEndWith: operation)
        if operation == .copy || operation == .move {
            delegate?.dragInteraction(self, sessionDidTransferItems: session)
        }
        _UIDragDropCenter.active = nil
    }
}

@preconcurrency @MainActor
public protocol UIDropInteractionDelegate: AnyObject {
    func dropInteraction(_ interaction: UIDropInteraction,
                         canHandle session: UIDropSession) -> Bool
    func dropInteraction(_ interaction: UIDropInteraction,
                         sessionDidEnter session: UIDropSession)
    func dropInteraction(_ interaction: UIDropInteraction,
                         sessionDidUpdate session: UIDropSession) -> UIDropProposal
    func dropInteraction(_ interaction: UIDropInteraction,
                         sessionDidExit session: UIDropSession)
    func dropInteraction(_ interaction: UIDropInteraction,
                         performDrop session: UIDropSession)
    func dropInteraction(_ interaction: UIDropInteraction,
                         concludeDrop session: UIDropSession)
    func dropInteraction(_ interaction: UIDropInteraction,
                         sessionDidEnd session: UIDropSession)
}

public extension UIDropInteractionDelegate {
    func dropInteraction(_ interaction: UIDropInteraction,
                         canHandle session: UIDropSession) -> Bool { true }
    func dropInteraction(_ interaction: UIDropInteraction,
                         sessionDidEnter session: UIDropSession) {}
    func dropInteraction(_ interaction: UIDropInteraction,
                         sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        UIDropProposal(operation: .copy)
    }
    func dropInteraction(_ interaction: UIDropInteraction,
                         sessionDidExit session: UIDropSession) {}
    func dropInteraction(_ interaction: UIDropInteraction,
                         performDrop session: UIDropSession) {}
    func dropInteraction(_ interaction: UIDropInteraction,
                         concludeDrop session: UIDropSession) {}
    func dropInteraction(_ interaction: UIDropInteraction,
                         sessionDidEnd session: UIDropSession) {}
}

@preconcurrency @MainActor
public final class UIDropInteraction: UIInteraction {
    public private(set) weak var delegate: UIDropInteractionDelegate?
    public private(set) weak var view: UIView?
    public var allowsSimultaneousDropSessions = false

    public init(delegate: UIDropInteractionDelegate) {
        self.delegate = delegate
    }

    public func didMove(to view: UIView?) {
        self.view = view
    }
}

// MARK: - Session drop routing

extension _UIDragSessionImpl {
    func _updateDrops() {
        guard let window = sourceView?.window else { return }
        let hit = window.hitTest(locationInWindow, with: nil)
        var v: UIView? = hit
        var seen: Set<ObjectIdentifier> = []
        while let cur = v {
            for interaction in cur.interactions {
                if let drop = interaction as? UIDropInteraction, let d = drop.delegate {
                    let id = ObjectIdentifier(drop)
                    seen.insert(id)
                    if !enteredDrop.contains(id) {
                        if d.dropInteraction(drop, canHandle: self) {
                            enteredDrop.append(id)
                            d.dropInteraction(drop, sessionDidEnter: self)
                        }
                    }
                    if enteredDrop.contains(id) {
                        _ = d.dropInteraction(drop, sessionDidUpdate: self)
                    }
                }
            }
            if let table = cur as? UITableView, let drop = table.dropDelegate {
                let id = ObjectIdentifier(table)
                seen.insert(id)
                let dest = table.indexPathForRow(at: location(in: table))
                destinationIndexPath = dest
                if !enteredDrop.contains(id) {
                    if drop.tableView(table, canHandle: self) {
                        enteredDrop.append(id)
                        drop.tableView(table, dropSessionDidEnter: self)
                    }
                }
                if enteredDrop.contains(id) {
                    table._activeDrop = true
                    _ = drop.tableView(table, dropSessionDidUpdate: self,
                                       withDestinationIndexPath: dest)
                }
            }
            if let collection = cur as? UICollectionView, let drop = collection.dropDelegate {
                let id = ObjectIdentifier(collection)
                seen.insert(id)
                let dest = collection.indexPathForItem(at: location(in: collection))
                destinationIndexPath = dest
                if !enteredDrop.contains(id) {
                    if drop.collectionView(collection, canHandle: self) {
                        enteredDrop.append(id)
                        drop.collectionView(collection, dropSessionDidEnter: self)
                    }
                }
                if enteredDrop.contains(id) {
                    collection._activeDrop = true
                    _ = drop.collectionView(collection, dropSessionDidUpdate: self,
                                            withDestinationIndexPath: dest)
                }
            }
            v = cur.superview
        }
        for id in enteredDrop where !seen.contains(id) {
            // Exit is best-effort; leftover ids are cleared on end.
            _ = id
        }
    }

    func _dropOperation() -> UIDropOperation {
        .copy
    }

    func _performDropIfNeeded(operation: UIDropOperation) {
        guard operation == .copy || operation == .move else {
            _endAll()
            return
        }
        guard let window = sourceView?.window else { _endAll(); return }
        let hit = window.hitTest(locationInWindow, with: nil)
        var v: UIView? = hit
        while let cur = v {
            for interaction in cur.interactions {
                if let drop = interaction as? UIDropInteraction, let d = drop.delegate {
                    d.dropInteraction(drop, performDrop: self)
                    d.dropInteraction(drop, concludeDrop: self)
                    d.dropInteraction(drop, sessionDidEnd: self)
                }
            }
            if let table = cur as? UITableView, let drop = table.dropDelegate {
                let coordinator = _UITableViewDropCoordinatorImpl(
                    session: self, table: table, destination: destinationIndexPath)
                drop.tableView(table, performDropWith: coordinator)
                drop.tableView(table, dropSessionDidEnd: self)
                table._activeDrop = false
            }
            if let collection = cur as? UICollectionView, let drop = collection.dropDelegate {
                let coordinator = _UICollectionViewDropCoordinatorImpl(
                    session: self, collection: collection, destination: destinationIndexPath)
                drop.collectionView(collection, performDropWith: coordinator)
                drop.collectionView(collection, dropSessionDidEnd: self)
                collection._activeDrop = false
            }
            v = cur.superview
        }
        _endAll()
    }

    func _endAll() {
        sourceTable?._activeDrag = false
        sourceCollection?._activeDrag = false
        sourceTable?._activeDrop = false
        sourceCollection?._activeDrop = false
    }
}

// MARK: - Table / collection drop items + coordinators

@preconcurrency @MainActor
public protocol UITableViewDropItem: AnyObject {
    var dragItem: UIDragItem { get }
    var sourceIndexPath: IndexPath? { get }
    var previewSize: CGSize { get }
}

@preconcurrency @MainActor
final class _UITableViewDropItemImpl: UITableViewDropItem {
    let dragItem: UIDragItem
    let sourceIndexPath: IndexPath?
    var previewSize: CGSize { .zero }
    init(dragItem: UIDragItem, sourceIndexPath: IndexPath?) {
        self.dragItem = dragItem
        self.sourceIndexPath = sourceIndexPath
    }
}

@preconcurrency @MainActor
open class UITableViewPlaceholder {
    public let insertionIndexPath: IndexPath
    public let reuseIdentifier: String
    public let rowHeight: CGFloat
    public var cellUpdateHandler: ((UITableViewCell) -> Void)?
    public init(insertionIndexPath: IndexPath, reuseIdentifier: String, rowHeight: CGFloat) {
        self.insertionIndexPath = insertionIndexPath
        self.reuseIdentifier = reuseIdentifier
        self.rowHeight = rowHeight
    }
}

@preconcurrency @MainActor
open class UITableViewDropPlaceholder: UITableViewPlaceholder {
    public var previewParametersProvider: ((UITableViewCell) -> UIDragPreviewParameters?)?
}

@preconcurrency @MainActor
public protocol UITableViewDropPlaceholderContext: UIDragAnimating {
    var dragItem: UIDragItem { get }
    func commitInsertion(dataSourceUpdates: (IndexPath) -> Void) -> Bool
    func deletePlaceholder() -> Bool
}

@preconcurrency @MainActor
final class _UITableViewDropPlaceholderContextImpl: UITableViewDropPlaceholderContext {
    let dragItem: UIDragItem
    let insertionIndexPath: IndexPath
    var available = true
    init(dragItem: UIDragItem, insertionIndexPath: IndexPath) {
        self.dragItem = dragItem
        self.insertionIndexPath = insertionIndexPath
    }
    func addAnimations(_ animations: @escaping () -> Void) { animations() }
    func addCompletion(_ completion: @escaping (UIViewAnimatingPosition) -> Void) {
        completion(.end)
    }
    func commitInsertion(dataSourceUpdates: (IndexPath) -> Void) -> Bool {
        guard available else { return false }
        dataSourceUpdates(insertionIndexPath)
        available = false
        return true
    }
    func deletePlaceholder() -> Bool {
        guard available else { return false }
        available = false
        return true
    }
}

@preconcurrency @MainActor
public protocol UITableViewDropCoordinator: AnyObject {
    var items: [UITableViewDropItem] { get }
    var destinationIndexPath: IndexPath? { get }
    var proposal: UITableViewDropProposal { get }
    var session: UIDropSession { get }
    func drop(_ dragItem: UIDragItem, to placeholder: UITableViewDropPlaceholder)
        -> UITableViewDropPlaceholderContext
    func drop(_ dragItem: UIDragItem, toRowAt indexPath: IndexPath) -> UIDragAnimating
    func drop(_ dragItem: UIDragItem, intoRowAt indexPath: IndexPath, rect: CGRect) -> UIDragAnimating
    func drop(_ dragItem: UIDragItem, to target: UIDragPreviewTarget) -> UIDragAnimating
}

@preconcurrency @MainActor
final class _UITableViewDropCoordinatorImpl: UITableViewDropCoordinator {
    let session: UIDropSession
    let destinationIndexPath: IndexPath?
    let proposal: UITableViewDropProposal
    let items: [UITableViewDropItem]
    init(session: _UIDragSessionImpl, table: UITableView, destination: IndexPath?) {
        self.session = session
        self.destinationIndexPath = destination
        self.proposal = UITableViewDropProposal(operation: .copy, intent: .unspecified)
        self.items = session.items.map {
            _UITableViewDropItemImpl(dragItem: $0, sourceIndexPath: nil)
        }
    }
    func drop(_ dragItem: UIDragItem, to placeholder: UITableViewDropPlaceholder)
        -> UITableViewDropPlaceholderContext {
        _UITableViewDropPlaceholderContextImpl(
            dragItem: dragItem, insertionIndexPath: placeholder.insertionIndexPath)
    }
    func drop(_ dragItem: UIDragItem, toRowAt indexPath: IndexPath) -> UIDragAnimating {
        _ = (dragItem, indexPath)
        return _UIDragAnimator()
    }
    func drop(_ dragItem: UIDragItem, intoRowAt indexPath: IndexPath, rect: CGRect) -> UIDragAnimating {
        _ = (dragItem, indexPath, rect)
        return _UIDragAnimator()
    }
    func drop(_ dragItem: UIDragItem, to target: UIDragPreviewTarget) -> UIDragAnimating {
        _ = (dragItem, target)
        return _UIDragAnimator()
    }
}

@preconcurrency @MainActor
public protocol UICollectionViewDropItem: AnyObject {
    var dragItem: UIDragItem { get }
    var sourceIndexPath: IndexPath? { get }
    var previewSize: CGSize { get }
}

@preconcurrency @MainActor
final class _UICollectionViewDropItemImpl: UICollectionViewDropItem {
    let dragItem: UIDragItem
    let sourceIndexPath: IndexPath?
    var previewSize: CGSize { .zero }
    init(dragItem: UIDragItem, sourceIndexPath: IndexPath?) {
        self.dragItem = dragItem
        self.sourceIndexPath = sourceIndexPath
    }
}

@preconcurrency @MainActor
open class UICollectionViewPlaceholder {
    public let insertionIndexPath: IndexPath
    public let reuseIdentifier: String
    public var cellUpdateHandler: ((UICollectionViewCell) -> Void)?
    public init(insertionIndexPath: IndexPath, reuseIdentifier: String) {
        self.insertionIndexPath = insertionIndexPath
        self.reuseIdentifier = reuseIdentifier
    }
}

@preconcurrency @MainActor
open class UICollectionViewDropPlaceholder: UICollectionViewPlaceholder {
    public var previewParametersProvider: ((UICollectionViewCell) -> UIDragPreviewParameters?)?
}

@preconcurrency @MainActor
public protocol UICollectionViewDropPlaceholderContext: UIDragAnimating {
    var dragItem: UIDragItem { get }
    func commitInsertion(dataSourceUpdates: (IndexPath) -> Void) -> Bool
    func deletePlaceholder() -> Bool
    func setNeedsCellUpdate()
}

@preconcurrency @MainActor
final class _UICollectionViewDropPlaceholderContextImpl: UICollectionViewDropPlaceholderContext {
    let dragItem: UIDragItem
    let insertionIndexPath: IndexPath
    var available = true
    init(dragItem: UIDragItem, insertionIndexPath: IndexPath) {
        self.dragItem = dragItem
        self.insertionIndexPath = insertionIndexPath
    }
    func addAnimations(_ animations: @escaping () -> Void) { animations() }
    func addCompletion(_ completion: @escaping (UIViewAnimatingPosition) -> Void) {
        completion(.end)
    }
    func commitInsertion(dataSourceUpdates: (IndexPath) -> Void) -> Bool {
        guard available else { return false }
        dataSourceUpdates(insertionIndexPath)
        available = false
        return true
    }
    func deletePlaceholder() -> Bool {
        guard available else { return false }
        available = false
        return true
    }
    func setNeedsCellUpdate() {}
}

@preconcurrency @MainActor
public protocol UICollectionViewDropCoordinator: AnyObject {
    var items: [UICollectionViewDropItem] { get }
    var destinationIndexPath: IndexPath? { get }
    var proposal: UICollectionViewDropProposal { get }
    var session: UIDropSession { get }
    func drop(_ dragItem: UIDragItem, to placeholder: UICollectionViewDropPlaceholder)
        -> UICollectionViewDropPlaceholderContext
    func drop(_ dragItem: UIDragItem, toItemAt indexPath: IndexPath) -> UIDragAnimating
    func drop(_ dragItem: UIDragItem, intoItemAt indexPath: IndexPath, rect: CGRect) -> UIDragAnimating
    func drop(_ dragItem: UIDragItem, to target: UIDragPreviewTarget) -> UIDragAnimating
}

@preconcurrency @MainActor
final class _UICollectionViewDropCoordinatorImpl: UICollectionViewDropCoordinator {
    let session: UIDropSession
    let destinationIndexPath: IndexPath?
    let proposal: UICollectionViewDropProposal
    let items: [UICollectionViewDropItem]
    init(session: _UIDragSessionImpl, collection: UICollectionView, destination: IndexPath?) {
        self.session = session
        self.destinationIndexPath = destination
        self.proposal = UICollectionViewDropProposal(operation: .copy, intent: .unspecified)
        self.items = session.items.map {
            _UICollectionViewDropItemImpl(dragItem: $0, sourceIndexPath: nil)
        }
    }
    func drop(_ dragItem: UIDragItem, to placeholder: UICollectionViewDropPlaceholder)
        -> UICollectionViewDropPlaceholderContext {
        _UICollectionViewDropPlaceholderContextImpl(
            dragItem: dragItem, insertionIndexPath: placeholder.insertionIndexPath)
    }
    func drop(_ dragItem: UIDragItem, toItemAt indexPath: IndexPath) -> UIDragAnimating {
        _ = (dragItem, indexPath)
        return _UIDragAnimator()
    }
    func drop(_ dragItem: UIDragItem, intoItemAt indexPath: IndexPath, rect: CGRect) -> UIDragAnimating {
        _ = (dragItem, indexPath, rect)
        return _UIDragAnimator()
    }
    func drop(_ dragItem: UIDragItem, to target: UIDragPreviewTarget) -> UIDragAnimating {
        _ = (dragItem, target)
        return _UIDragAnimator()
    }
}

// MARK: - Table / collection drag+drop delegates

@preconcurrency @MainActor
public protocol UITableViewDragDelegate: AnyObject {
    func tableView(_ tableView: UITableView,
                   itemsForBeginning session: UIDragSession,
                   at indexPath: IndexPath) -> [UIDragItem]
    func tableView(_ tableView: UITableView, dragSessionWillBegin session: UIDragSession)
    func tableView(_ tableView: UITableView, dragSessionDidEnd session: UIDragSession)
    func tableView(_ tableView: UITableView,
                   dragSessionAllowsMoveOperation session: UIDragSession) -> Bool
    func tableView(_ tableView: UITableView,
                   dragSessionIsRestrictedToDraggingApplication session: UIDragSession) -> Bool
}

public extension UITableViewDragDelegate {
    func tableView(_ tableView: UITableView, dragSessionWillBegin session: UIDragSession) {}
    func tableView(_ tableView: UITableView, dragSessionDidEnd session: UIDragSession) {}
    func tableView(_ tableView: UITableView,
                   dragSessionAllowsMoveOperation session: UIDragSession) -> Bool { true }
    func tableView(_ tableView: UITableView,
                   dragSessionIsRestrictedToDraggingApplication session: UIDragSession) -> Bool { false }
}

@preconcurrency @MainActor
public protocol UITableViewDropDelegate: AnyObject {
    func tableView(_ tableView: UITableView,
                   performDropWith coordinator: UITableViewDropCoordinator)
    func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool
    func tableView(_ tableView: UITableView, dropSessionDidEnter session: UIDropSession)
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession,
                   withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal
    func tableView(_ tableView: UITableView, dropSessionDidExit session: UIDropSession)
    func tableView(_ tableView: UITableView, dropSessionDidEnd session: UIDropSession)
}

public extension UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool { true }
    func tableView(_ tableView: UITableView, dropSessionDidEnter session: UIDropSession) {}
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession,
                   withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        UITableViewDropProposal(operation: .copy, intent: .unspecified)
    }
    func tableView(_ tableView: UITableView, dropSessionDidExit session: UIDropSession) {}
    func tableView(_ tableView: UITableView, dropSessionDidEnd session: UIDropSession) {}
}

@preconcurrency @MainActor
public protocol UICollectionViewDragDelegate: AnyObject {
    func collectionView(_ collectionView: UICollectionView,
                         itemsForBeginning session: UIDragSession,
                         at indexPath: IndexPath) -> [UIDragItem]
    func collectionView(_ collectionView: UICollectionView,
                         dragSessionWillBegin session: UIDragSession)
    func collectionView(_ collectionView: UICollectionView,
                         dragSessionDidEnd session: UIDragSession)
    func collectionView(_ collectionView: UICollectionView,
                         dragSessionAllowsMoveOperation session: UIDragSession) -> Bool
    func collectionView(_ collectionView: UICollectionView,
                         dragSessionIsRestrictedToDraggingApplication session: UIDragSession) -> Bool
}

public extension UICollectionViewDragDelegate {
    func collectionView(_ collectionView: UICollectionView,
                         dragSessionWillBegin session: UIDragSession) {}
    func collectionView(_ collectionView: UICollectionView,
                         dragSessionDidEnd session: UIDragSession) {}
    func collectionView(_ collectionView: UICollectionView,
                         dragSessionAllowsMoveOperation session: UIDragSession) -> Bool { true }
    func collectionView(_ collectionView: UICollectionView,
                         dragSessionIsRestrictedToDraggingApplication session: UIDragSession) -> Bool { false }
}

@preconcurrency @MainActor
public protocol UICollectionViewDropDelegate: AnyObject {
    func collectionView(_ collectionView: UICollectionView,
                         performDropWith coordinator: UICollectionViewDropCoordinator)
    func collectionView(_ collectionView: UICollectionView,
                         canHandle session: UIDropSession) -> Bool
    func collectionView(_ collectionView: UICollectionView,
                         dropSessionDidEnter session: UIDropSession)
    func collectionView(_ collectionView: UICollectionView,
                         dropSessionDidUpdate session: UIDropSession,
                         withDestinationIndexPath destinationIndexPath: IndexPath?)
        -> UICollectionViewDropProposal
    func collectionView(_ collectionView: UICollectionView,
                         dropSessionDidExit session: UIDropSession)
    func collectionView(_ collectionView: UICollectionView,
                         dropSessionDidEnd session: UIDropSession)
}

public extension UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView,
                         canHandle session: UIDropSession) -> Bool { true }
    func collectionView(_ collectionView: UICollectionView,
                         dropSessionDidEnter session: UIDropSession) {}
    func collectionView(_ collectionView: UICollectionView,
                         dropSessionDidUpdate session: UIDropSession,
                         withDestinationIndexPath destinationIndexPath: IndexPath?)
        -> UICollectionViewDropProposal {
        UICollectionViewDropProposal(operation: .copy, intent: .unspecified)
    }
    func collectionView(_ collectionView: UICollectionView,
                         dropSessionDidExit session: UIDropSession) {}
    func collectionView(_ collectionView: UICollectionView,
                         dropSessionDidEnd session: UIDropSession) {}
}

// MARK: - Paste configuration

@preconcurrency @MainActor
open class UIPasteConfiguration {
    public var acceptableTypeIdentifiers: [String]
    public init() { acceptableTypeIdentifiers = [] }
    public init(acceptableTypeIdentifiers: [String]) {
        self.acceptableTypeIdentifiers = acceptableTypeIdentifiers
    }

    public func addAcceptableTypeIdentifiers(_ typeIdentifiers: [String]) {
        acceptableTypeIdentifiers.append(contentsOf: typeIdentifiers)
    }
}

@preconcurrency @MainActor
public protocol UIPasteConfigurationSupporting: AnyObject {
    var pasteConfiguration: UIPasteConfiguration? { get set }
    func paste(itemProviders: [NSItemProvider])
    func canPaste(itemProviders: [NSItemProvider]) -> Bool
}

public extension UIPasteConfigurationSupporting {
    func paste(itemProviders: [NSItemProvider]) {}
    func canPaste(itemProviders: [NSItemProvider]) -> Bool {
        guard let config = pasteConfiguration else { return false }
        return itemProviders.contains { provider in
            config.acceptableTypeIdentifiers.contains { provider.hasItemConformingToTypeIdentifier($0) }
        }
    }
}

extension UIView: UIPasteConfigurationSupporting {
    public var pasteConfiguration: UIPasteConfiguration? {
        get { _pasteConfiguration }
        set { _pasteConfiguration = newValue }
    }
}

#if canImport(Foundation) && !os(Linux)
extension NSItemProvider {
    func _openUIKitLoad<T>(_ type: T.Type) -> T? {
        if type == String.self {
            // Foundation NSItemProvider does not expose the in-process item
            // as a typed getter; tests that need a round-trip set localObject.
            return nil
        }
        return nil
    }
}
#endif

// MARK: - Table / collection lift

extension UITableView {
    func _installDragLift() {
        if let press = _dragLift {
            removeGestureRecognizer(press)
            _dragLift = nil
        }
        guard dragDelegate != nil else { return }
        let press = UILongPressGestureRecognizer { [weak self] r in
            self?._handleDragLift(r)
        }
        press.minimumPressDuration = 0.325
        press.allowableMovement = 10
        addGestureRecognizer(press)
        _dragLift = press
    }

    func _handleDragLift(_ recognizer: UIGestureRecognizer) {
        guard dragInteractionEnabled, let dragDelegate else { return }
        switch recognizer.state {
        case .began:
            let loc = recognizer.location(in: self)
            guard let path = indexPathForRow(at: loc) else { return }
            let session = _UIDragSessionImpl(
                items: [], location: recognizer.location(in: nil), sourceView: self)
            session.sourceTable = self
            let items = dragDelegate.tableView(self, itemsForBeginning: session, at: path)
            guard !items.isEmpty else { return }
            session.items = items
            session.allowsMoveOperation =
                dragDelegate.tableView(self, dragSessionAllowsMoveOperation: session)
            session.isRestrictedToDraggingApplication =
                dragDelegate.tableView(self, dragSessionIsRestrictedToDraggingApplication: session)
            _UIDragDropCenter.active = session
            _activeDrag = true
            dragDelegate.tableView(self, dragSessionWillBegin: session)
        case .changed:
            guard let session = _UIDragDropCenter.active else { return }
            session.locationInWindow = recognizer.location(in: nil)
            session._updateDrops()
        case .ended, .cancelled:
            let op: UIDropOperation = recognizer.state == .ended ? .copy : .cancel
            if let session = _UIDragDropCenter.active {
                session._performDropIfNeeded(operation: op)
                dragDelegate.tableView(self, dragSessionDidEnd: session)
            }
            _activeDrag = false
            _UIDragDropCenter.active = nil
        default:
            break
        }
    }
}

extension UICollectionView {
    func _installDragLift() {
        if let press = _dragLift {
            removeGestureRecognizer(press)
            _dragLift = nil
        }
        guard dragDelegate != nil else { return }
        let press = UILongPressGestureRecognizer { [weak self] r in
            self?._handleDragLift(r)
        }
        press.minimumPressDuration = 0.325
        press.allowableMovement = 10
        addGestureRecognizer(press)
        _dragLift = press
    }

    func _handleDragLift(_ recognizer: UIGestureRecognizer) {
        guard dragInteractionEnabled, let dragDelegate else { return }
        switch recognizer.state {
        case .began:
            let loc = recognizer.location(in: self)
            guard let path = indexPathForItem(at: loc) else { return }
            let session = _UIDragSessionImpl(
                items: [], location: recognizer.location(in: nil), sourceView: self)
            session.sourceCollection = self
            let items = dragDelegate.collectionView(self, itemsForBeginning: session, at: path)
            guard !items.isEmpty else { return }
            session.items = items
            session.allowsMoveOperation =
                dragDelegate.collectionView(self, dragSessionAllowsMoveOperation: session)
            session.isRestrictedToDraggingApplication =
                dragDelegate.collectionView(self, dragSessionIsRestrictedToDraggingApplication: session)
            _UIDragDropCenter.active = session
            _activeDrag = true
            dragDelegate.collectionView(self, dragSessionWillBegin: session)
        case .changed:
            guard let session = _UIDragDropCenter.active else { return }
            session.locationInWindow = recognizer.location(in: nil)
            session._updateDrops()
        case .ended, .cancelled:
            let op: UIDropOperation = recognizer.state == .ended ? .copy : .cancel
            if let session = _UIDragDropCenter.active {
                session._performDropIfNeeded(operation: op)
                dragDelegate.collectionView(self, dragSessionDidEnd: session)
            }
            _activeDrag = false
            _UIDragDropCenter.active = nil
        default:
            break
        }
    }
}
