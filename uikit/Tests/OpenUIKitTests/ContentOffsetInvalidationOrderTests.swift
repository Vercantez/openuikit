import XCTest
import Foundation
@testable import OpenUIKit

// contentOffset entry-point ordering, measured by
// Tools/oracle2/signalrowsprobe/offset.swift (iPhone 16 / iOS 26.1,
// offset-order-ios-26.1-iphone16.json). One recording layout plus a
// recording delegate/data source share a single event list, so the order of
// the layout callbacks, scrollViewDidScroll and the cell dequeues — and the
// collection view's bounds observed inside each — is one sequence.

#if !os(Linux)
@MainActor
#endif
private struct Event: Equatable, CustomStringConvertible {
    var name: String
    var bounds: CGRect?
    var argument: CGRect?
    var description: String {
        var s = name
        if let b = bounds { s += "@\(Int(b.origin.y))" }
        if let a = argument { s += "(arg \(Int(a.origin.y)))" }
        return s
    }
}

#if !os(Linux)
@MainActor
#endif
private final class OffsetOrderRecorder {
    var events: [Event] = []
    func note(_ name: String, _ bounds: CGRect?, _ argument: CGRect? = nil) {
        events.append(Event(name: name, bounds: bounds, argument: argument))
    }
    var names: [String] { events.map(\.name) }
}

#if !os(Linux)
@MainActor
#endif
private final class RecordingLayout: UICollectionViewLayout {
    let recorder: OffsetOrderRecorder
    var answer = true
    var lastBoundsContext: ObjectIdentifier?
    var contextsMatched: [Bool] = []
    init(_ recorder: OffsetOrderRecorder) { self.recorder = recorder; super.init() }
    override var collectionViewContentSize: CGSize { CGSize(width: 200, height: 2000) }
    override func prepare() { recorder.note("prepare", collectionView?.bounds); super.prepare() }
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        recorder.note("layoutAttributesForElements", collectionView?.bounds, rect)
        return (0..<40).compactMap { layoutAttributesForItem(at: IndexPath(item: $0, section: 0)) }
            .filter { $0.frame.intersects(rect) }
    }
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let a = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        a.frame = CGRect(x: 0, y: CGFloat(indexPath.item) * 50, width: 200, height: 40)
        return a
    }
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        recorder.note("shouldInvalidate", collectionView?.bounds, newBounds)
        return answer
    }
    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds)
        lastBoundsContext = ObjectIdentifier(context)
        recorder.note("boundsContext", collectionView?.bounds, newBounds)
        return context
    }
    override func invalidateLayout() {
        recorder.note("invalidateLayout", collectionView?.bounds)
        super.invalidateLayout()
    }
    override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        contextsMatched.append(lastBoundsContext == ObjectIdentifier(context))
        recorder.note("invalidateLayout(with:)", collectionView?.bounds)
        super.invalidateLayout(with: context)
    }
}

#if !os(Linux)
@MainActor
#endif
private final class RecordingSource: NSObject, UICollectionViewDataSource, UICollectionViewDelegate {
    let recorder: OffsetOrderRecorder
    init(_ recorder: OffsetOrderRecorder) { self.recorder = recorder }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { 40 }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        recorder.note("cellForItem \(indexPath.item)", collectionView.bounds)
        return collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) { recorder.note("scrollViewDidScroll", scrollView.bounds) }
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) { recorder.note("willBeginDragging", scrollView.bounds) }
}

#if !os(Linux)
@MainActor
#endif
private final class RecordingTableSource: NSObject, UITableViewDataSource, UITableViewDelegate {
    let recorder: OffsetOrderRecorder
    init(_ recorder: OffsetOrderRecorder) { self.recorder = recorder }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 100 }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        recorder.note("cellForRow \(indexPath.row)", tableView.bounds)
        return tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) { recorder.note("scrollViewDidScroll", scrollView.bounds) }
}

#if !os(Linux)
@MainActor
#endif
final class ContentOffsetInvalidationOrderTests: XCTestCase {
    private let old = CGRect(x: 0, y: 0, width: 200, height: 300)
    private func at(_ y: CGFloat) -> CGRect { CGRect(x: 0, y: y, width: 200, height: 300) }
    /// Data sources and delegates are weak on the views; keep them alive.
    private var retained: [AnyObject] = []
    override func tearDown() { retained = []; super.tearDown() }

    private func makeCollection() -> (UIWindow, UICollectionView, RecordingLayout, OffsetOrderRecorder, RecordingSource) {
        let recorder = OffsetOrderRecorder()
        let layout = RecordingLayout(recorder)
        let window = UIWindow(frame: old)
        let collection = UICollectionView(frame: old, collectionViewLayout: layout)
        collection.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        let source = RecordingSource(recorder)
        retained.append(source)
        collection.dataSource = source
        collection.delegate = source
        window.addSubview(collection)
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        recorder.events = []
        layout.contextsMatched = []
        return (window, collection, layout, recorder, source)
    }

    /// The chain shared by every entry point, on the OLD bounds with the
    /// new rect as the argument, then invalidateLayout at `seen`.
    private func chain(to new: CGRect, invalidatingAt seen: CGRect) -> [Event] {
        [Event(name: "shouldInvalidate", bounds: old, argument: new),
         Event(name: "boundsContext", bounds: old, argument: new),
         Event(name: "invalidateLayout", bounds: seen),
         Event(name: "invalidateLayout(with:)", bounds: seen)]
    }

    private func layoutPass(at new: CGRect, dequeuing items: [Int]) -> [Event] {
        [Event(name: "prepare", bounds: new),
         Event(name: "layoutAttributesForElements", bounds: new, argument: new)]
            + items.map { Event(name: "cellForItem \($0)", bounds: new) }
    }

    // MARK: setContentOffset(animated: false): chain BEFORE the move

    func testNonAnimatedSetContentOffsetInvalidatesOnTheOldBoundsThenMovesThenNotifies() {
        let (_, collection, layout, recorder, _) = makeCollection()
        collection.setContentOffset(CGPoint(x: 0, y: 40), animated: false)
        let sync = chain(to: at(40), invalidatingAt: old)
            + [Event(name: "scrollViewDidScroll", bounds: at(40))]
        XCTAssertEqual(recorder.events, sync, "\(recorder.events)")
        XCTAssertEqual(layout.contextsMatched, [true])
        collection.layoutIfNeeded()
        XCTAssertEqual(recorder.events, sync + layoutPass(at: at(40), dequeuing: [6]), "\(recorder.events)")
    }

    func testScrollRectToVisibleAndScrollToItemFollowTheSetContentOffsetOrder() {
        let (_, viaRect, _, rectRecorder, _) = makeCollection()
        viaRect.scrollRectToVisible(CGRect(x: 0, y: 300, width: 200, height: 40), animated: false)
        XCTAssertEqual(viaRect.contentOffset, CGPoint(x: 0, y: 40))
        XCTAssertEqual(rectRecorder.events, chain(to: at(40), invalidatingAt: old)
            + [Event(name: "scrollViewDidScroll", bounds: at(40))], "\(rectRecorder.events)")

        let (_, viaItem, _, itemRecorder, _) = makeCollection()
        viaItem.scrollToItem(at: IndexPath(item: 6, section: 0), at: .top, animated: false)
        XCTAssertEqual(viaItem.contentOffset, CGPoint(x: 0, y: 300))
        XCTAssertEqual(itemRecorder.events, chain(to: at(300), invalidatingAt: old)
            + [Event(name: "scrollViewDidScroll", bounds: at(300))], "\(itemRecorder.events)")
        viaItem.layoutIfNeeded()
        XCTAssertEqual(Array(itemRecorder.events.dropFirst(5)),
                       layoutPass(at: at(300), dequeuing: [6, 7, 8, 9, 10, 11]), "\(itemRecorder.events)")
    }

    /// iOS runs the same synchronous chain for the animated variants — on
    /// the old bounds with the TARGET as the argument — and moves nothing
    /// until the first frame. The port's model still jumps inside the
    /// animation block (documented wall), so only the synchronous prefix
    /// and the single question are asserted.
    func testAnimatedSetContentOffsetRunsTheChainOnTheTargetFirst() {
        let (_, collection, _, recorder, _) = makeCollection()
        collection.setContentOffset(CGPoint(x: 0, y: 40), animated: true)
        XCTAssertEqual(Array(recorder.events.prefix(4)), chain(to: at(40), invalidatingAt: old), "\(recorder.events)")
        XCTAssertEqual(recorder.names.filter { $0 == "shouldInvalidate" }.count, 1)
    }

    // MARK: direct sets: chain around the move

    func testDirectContentOffsetInvalidatesOnTheNewBoundsBeforeTheDelegateHears() {
        let (_, collection, layout, recorder, _) = makeCollection()
        collection.contentOffset = CGPoint(x: 0, y: 40)
        let sync = chain(to: at(40), invalidatingAt: at(40))
            + [Event(name: "scrollViewDidScroll", bounds: at(40))]
        XCTAssertEqual(recorder.events, sync, "\(recorder.events)")
        XCTAssertEqual(layout.contextsMatched, [true])
        collection.layoutIfNeeded()
        XCTAssertEqual(recorder.events, sync + layoutPass(at: at(40), dequeuing: [6]), "\(recorder.events)")
    }

    func testDirectBoundsSetRunsTheChainWithoutScrollViewDidScroll() {
        let (_, collection, _, recorder, _) = makeCollection()
        collection.bounds = at(40)
        XCTAssertEqual(recorder.events, chain(to: at(40), invalidatingAt: at(40)), "\(recorder.events)")
    }

    func testFalseAnswerStopsAfterTheQuestionOnEveryEntryPoint() {
        for entry in ["set", "direct", "rect"] {
            let (_, collection, layout, recorder, _) = makeCollection()
            layout.answer = false
            switch entry {
            case "set": collection.setContentOffset(CGPoint(x: 0, y: 40), animated: false)
            case "direct": collection.contentOffset = CGPoint(x: 0, y: 40)
            default: collection.scrollRectToVisible(CGRect(x: 0, y: 300, width: 200, height: 40), animated: false)
            }
            XCTAssertEqual(recorder.names.filter { $0 != "cellForItem 6" && !$0.hasPrefix("layoutAttributes") },
                           ["shouldInvalidate", "scrollViewDidScroll"], "\(entry): \(recorder.events)")
        }
    }

    // MARK: a pending invalidation silences the question

    func testBoundsChangeWhileAnInvalidationIsPendingAsksNothing() {
        let (_, collection, _, recorder, _) = makeCollection()
        collection.contentOffset = CGPoint(x: 0, y: 40)
        recorder.events = []
        collection.contentOffset = CGPoint(x: 0, y: 60)
        XCTAssertEqual(recorder.events, [Event(name: "scrollViewDidScroll", bounds: at(60))], "\(recorder.events)")
        recorder.events = []
        collection.layoutIfNeeded()
        XCTAssertEqual(recorder.names.first, "prepare", "\(recorder.events)")
        recorder.events = []
        collection.contentOffset = CGPoint(x: 0, y: 80)
        XCTAssertEqual(recorder.names, ["shouldInvalidate", "boundsContext", "invalidateLayout",
                                        "invalidateLayout(with:)", "scrollViewDidScroll"], "\(recorder.events)")
    }

    // MARK: drag steps and deceleration frames

    func testDragStepsAndDecelerationFramesInvalidateAroundEachMove() {
        let (window, collection, _, recorder, _) = makeCollection()
        window.sendTouch(.began, at: CGPoint(x: 100, y: 200), timestamp: 0)
        // The touch-down lays out (a retile query, nothing else).
        XCTAssertEqual(recorder.names.filter { $0 != "layoutAttributesForElements" }, [])
        recorder.events = []
        window.sendTouch(.moved, at: CGPoint(x: 100, y: 185), timestamp: 0.016)
        XCTAssertEqual(recorder.events, [Event(name: "willBeginDragging", bounds: old)]
            + chain(to: at(5), invalidatingAt: at(5))
            + [Event(name: "scrollViewDidScroll", bounds: at(5))], "\(recorder.events)")
        XCTAssertEqual(collection.contentOffset, CGPoint(x: 0, y: 5))

        // The host lays out before delivering the next event; the question
        // is back once the layout prepared.
        window.layoutIfNeeded()
        recorder.events = []
        window.sendTouch(.moved, at: CGPoint(x: 100, y: 170), timestamp: 0.032)
        XCTAssertEqual(recorder.events, [
            Event(name: "shouldInvalidate", bounds: at(5), argument: at(20)),
            Event(name: "boundsContext", bounds: at(5), argument: at(20)),
            Event(name: "invalidateLayout", bounds: at(20)),
            Event(name: "invalidateLayout(with:)", bounds: at(20)),
            Event(name: "scrollViewDidScroll", bounds: at(20)),
        ], "\(recorder.events)")

        window.sendTouch(.moved, at: CGPoint(x: 100, y: 140), timestamp: 0.048)
        window.sendTouch(.ended, at: CGPoint(x: 100, y: 140), timestamp: 0.058)
        window.layoutIfNeeded()
        XCTAssertTrue(collection.isDecelerating)
        let before = collection.bounds
        recorder.events = []
        window.tick(timestamp: 0.1)
        let after = collection.bounds
        XCTAssertGreaterThan(after.origin.y, before.origin.y)
        XCTAssertEqual(recorder.events, [
            Event(name: "shouldInvalidate", bounds: before, argument: after),
            Event(name: "boundsContext", bounds: before, argument: after),
            Event(name: "invalidateLayout", bounds: after),
            Event(name: "invalidateLayout(with:)", bounds: after),
            Event(name: "scrollViewDidScroll", bounds: after),
        ], "\(recorder.events)")
    }

    // MARK: table view (shares the scroll-view funnel)

    func testTableSetContentOffsetNotifiesBeforeDequeuingWithTheNewBounds() {
        let recorder = OffsetOrderRecorder()
        let table = UITableView(frame: old, style: .plain)
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        table.rowHeight = 44
        let source = RecordingTableSource(recorder)
        table.dataSource = source
        table.delegate = source
        let host = UIView(frame: old)
        host.addSubview(table)
        table.layoutIfNeeded()
        recorder.events = []

        table.setContentOffset(CGPoint(x: 0, y: 40), animated: false)
        table.layoutIfNeeded()
        XCTAssertEqual(recorder.events, [
            Event(name: "scrollViewDidScroll", bounds: at(40)),
            Event(name: "cellForRow 7", bounds: at(40)),
        ], "\(recorder.events)")

        recorder.events = []
        table.bounds = at(88)
        table.layoutIfNeeded()
        XCTAssertEqual(recorder.names, ["cellForRow 8"], "a direct bounds set does not notify the delegate")

        recorder.events = []
        table.scrollRectToVisible(CGRect(x: 0, y: 800, width: 200, height: 44), animated: false)
        XCTAssertEqual(table.contentOffset, CGPoint(x: 0, y: 544))
        XCTAssertEqual(recorder.names.first, "scrollViewDidScroll")
        withExtendedLifetime(source) {}
    }

    // MARK: scrollRectToVisible geometry

    func testScrollRectToVisibleScrollsTheMinimumAndClampsToTheContent() {
        let scroll = UIScrollView(frame: old)
        scroll.contentSize = CGSize(width: 200, height: 2000)
        scroll.scrollRectToVisible(CGRect(x: 0, y: 300, width: 200, height: 40), animated: false)
        XCTAssertEqual(scroll.contentOffset, CGPoint(x: 0, y: 40))
        scroll.scrollRectToVisible(CGRect(x: 0, y: 100, width: 200, height: 40), animated: false)
        XCTAssertEqual(scroll.contentOffset, CGPoint(x: 0, y: 40), "an already visible rect scrolls nothing")
        scroll.scrollRectToVisible(CGRect(x: 0, y: 10, width: 200, height: 40), animated: false)
        XCTAssertEqual(scroll.contentOffset, CGPoint(x: 0, y: 10), "a rect above lands on its minY")
        scroll.scrollRectToVisible(CGRect(x: 0, y: 1990, width: 200, height: 40), animated: false)
        XCTAssertEqual(scroll.contentOffset, CGPoint(x: 0, y: 1700), "clamped to the content end")
    }
}
