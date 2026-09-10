import XCTest
import Foundation
@testable import OpenUIKit

// Bounds-change invalidation ordering, measured by
// Tools/oracle2/signalrowsprobe (iPhone 16 / iOS 26.1,
// ios-26.1-iphone16.json `invalidate.*`). The trace layout mirrors the
// probe's: every callback records the collection view's bounds AT THE TIME
// OF THE CALL and whether the context handed to invalidateLayout(with:) is
// the object invalidationContext(forBoundsChange:) produced.

#if !os(Linux)
@MainActor
#endif
private final class TwoItemSource: NSObject, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { 2 }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
    }
}

#if !os(Linux)
@MainActor
#endif
private struct Event: Equatable {
    var name: String
    var phase: String
    var collectionBounds: CGRect?
    var newBounds: CGRect?
    var fromBoundsContext: Bool?
}

#if !os(Linux)
@MainActor
#endif
private final class TraceLayout: UICollectionViewLayout {
    var answer = true
    var phase = "sync"
    var events: [Event] = []
    var lastBoundsContext: ObjectIdentifier?
    var receivedContexts: [UICollectionViewLayoutInvalidationContext] = []

    override var collectionViewContentSize: CGSize { CGSize(width: 500, height: 1200) }
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        (0..<2).compactMap { layoutAttributesForItem(at: IndexPath(item: $0, section: 0)) }
    }
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let a = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        a.frame = CGRect(x: 0, y: CGFloat(indexPath.item) * 50, width: 100, height: 40)
        return a
    }
    override func prepare() {
        events.append(Event(name: "prepare", phase: phase, collectionBounds: collectionView?.bounds))
        super.prepare()
    }
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        events.append(Event(name: "shouldInvalidate", phase: phase, collectionBounds: collectionView?.bounds, newBounds: newBounds))
        return answer
    }
    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds)
        lastBoundsContext = ObjectIdentifier(context)
        events.append(Event(name: "boundsContext", phase: phase, collectionBounds: collectionView?.bounds, newBounds: newBounds))
        return context
    }
    override func invalidateLayout() {
        events.append(Event(name: "invalidateLayout", phase: phase, collectionBounds: collectionView?.bounds))
        super.invalidateLayout()
    }
    override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        receivedContexts.append(context)
        events.append(Event(name: "invalidateLayout(with:)", phase: phase, collectionBounds: collectionView?.bounds,
                            fromBoundsContext: lastBoundsContext == ObjectIdentifier(context)))
        super.invalidateLayout(with: context)
    }
}

#if !os(Linux)
@MainActor
#endif
private final class TraceFlow: UICollectionViewFlowLayout {
    var lastBoundsContext: ObjectIdentifier?
    var received: [(UICollectionViewLayoutInvalidationContext, Bool)] = []
    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds)
        lastBoundsContext = ObjectIdentifier(context)
        return context
    }
    override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        received.append((context, lastBoundsContext == ObjectIdentifier(context)))
        super.invalidateLayout(with: context)
    }
}

#if !os(Linux)
@MainActor
#endif
final class CollectionBoundsInvalidationTests: XCTestCase {
    private let source = TwoItemSource()
    private let old = CGRect(x: 0, y: 0, width: 200, height: 300)

    private func attached(_ layout: UICollectionViewLayout) -> (UIView, UICollectionView) {
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        let collection = UICollectionView(frame: old, collectionViewLayout: layout)
        collection.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collection.dataSource = source
        host.addSubview(collection)
        collection.layoutIfNeeded()
        return (host, collection)
    }

    private func run(answer: Bool, _ mutate: (UICollectionView) -> Void) -> (TraceLayout, UICollectionView) {
        let layout = TraceLayout()
        let (_, collection) = attached(layout)
        layout.answer = answer
        layout.events = []
        layout.receivedContexts = []
        layout.phase = "sync"
        mutate(collection)
        layout.phase = "layout"
        collection.layoutIfNeeded()
        return (layout, collection)
    }

    func testSizeChangeRunsTheChainOnOldBoundsThenPreparesSynchronously() {
        let new = CGRect(x: 0, y: 0, width: 220, height: 300)
        let (layout, collection) = run(answer: true) { $0.frame = new }
        XCTAssertEqual(collection.bounds, new)
        XCTAssertEqual(layout.events, [
            Event(name: "shouldInvalidate", phase: "sync", collectionBounds: old, newBounds: new),
            Event(name: "boundsContext", phase: "sync", collectionBounds: old, newBounds: new),
            Event(name: "invalidateLayout", phase: "sync", collectionBounds: new),
            Event(name: "invalidateLayout(with:)", phase: "sync", collectionBounds: new, fromBoundsContext: true),
            Event(name: "prepare", phase: "sync", collectionBounds: new),
        ])
        let context = try! XCTUnwrap(layout.receivedContexts.first)
        XCTAssertFalse(context.invalidateEverything)
        XCTAssertFalse(context.invalidateDataSourceCounts)
        XCTAssertEqual(context.contentOffsetAdjustment, .zero)
        XCTAssertEqual(context.contentSizeAdjustment, .zero)
    }

    func testSizeChangeWithFalseAnswerStopsAfterTheQuestion() {
        let new = CGRect(x: 0, y: 0, width: 220, height: 300)
        let (layout, _) = run(answer: false) { $0.frame = new }
        XCTAssertEqual(layout.events, [
            Event(name: "shouldInvalidate", phase: "sync", collectionBounds: old, newBounds: new),
        ])
    }

    func testOriginChangeRunsTheChainAndDefersPrepareToLayout() {
        let new = CGRect(x: 0, y: 40, width: 200, height: 300)
        let (layout, collection) = run(answer: true) { $0.contentOffset = CGPoint(x: 0, y: 40) }
        XCTAssertEqual(collection.contentOffset, CGPoint(x: 0, y: 40))
        XCTAssertEqual(layout.events, [
            Event(name: "shouldInvalidate", phase: "sync", collectionBounds: old, newBounds: new),
            Event(name: "boundsContext", phase: "sync", collectionBounds: old, newBounds: new),
            Event(name: "invalidateLayout", phase: "sync", collectionBounds: new),
            Event(name: "invalidateLayout(with:)", phase: "sync", collectionBounds: new, fromBoundsContext: true),
            Event(name: "prepare", phase: "layout", collectionBounds: new),
        ])
    }

    func testOriginChangeWithFalseAnswerOnlyAsks() {
        let new = CGRect(x: 0, y: 40, width: 200, height: 300)
        let (layout, _) = run(answer: false) { $0.contentOffset = CGPoint(x: 0, y: 40) }
        XCTAssertEqual(layout.events, [
            Event(name: "shouldInvalidate", phase: "sync", collectionBounds: old, newBounds: new),
        ])
    }

    func testBoundsSetterAndNonAnimatedSetContentOffsetAskFirst() {
        let moved = CGRect(x: 5, y: 6, width: 200, height: 300)
        let (layout, _) = run(answer: true) { $0.bounds = moved }
        XCTAssertEqual(layout.events.map(\.name),
                       ["shouldInvalidate", "boundsContext", "invalidateLayout", "invalidateLayout(with:)", "prepare"])
        XCTAssertEqual(layout.events[0].collectionBounds, old)
        XCTAssertEqual(layout.events[1].collectionBounds, old)
        XCTAssertEqual(layout.events[2].collectionBounds, moved)
        XCTAssertEqual(layout.events[3].fromBoundsContext, true)

        let scrolled = CGRect(x: 0, y: 40, width: 200, height: 300)
        let (viaSet, _) = run(answer: true) { $0.setContentOffset(CGPoint(x: 0, y: 40), animated: false) }
        XCTAssertEqual(viaSet.events.map(\.name),
                       ["shouldInvalidate", "boundsContext", "invalidateLayout", "invalidateLayout(with:)", "prepare"])
        XCTAssertEqual(viaSet.events[0].newBounds, scrolled)
        XCTAssertEqual(viaSet.events[0].collectionBounds, old)
    }

    func testSameFrameAsksNothing() {
        let (layout, _) = run(answer: true) { $0.frame = self.old }
        XCTAssertEqual(layout.events, [])
    }

    func testFlowBoundsContextFlagsFollowTheScrollAxis() {
        let layout = UICollectionViewFlowLayout()
        let (_, collection) = attached(layout)
        XCTAssertEqual(collection.bounds, old)
        for (rect, attributes) in [
            (old, false),
            (CGRect(x: 0, y: 40, width: 200, height: 300), false),
            (CGRect(x: 5, y: 6, width: 200, height: 300), true),
            (CGRect(x: 0, y: 0, width: 220, height: 300), true),
        ] {
            let context = layout.invalidationContext(forBoundsChange: rect) as! UICollectionViewFlowLayoutInvalidationContext
            XCTAssertEqual(context.invalidateFlowLayoutAttributes, attributes, "\(rect)")
            XCTAssertFalse(context.invalidateFlowLayoutDelegateMetrics)
        }
        layout.scrollDirection = .horizontal
        let alongHorizontal = layout.invalidationContext(forBoundsChange: CGRect(x: 40, y: 0, width: 200, height: 300)) as! UICollectionViewFlowLayoutInvalidationContext
        XCTAssertFalse(alongHorizontal.invalidateFlowLayoutAttributes)
    }

    func testFlowSizeChangeDeliversItsBoundsContext() {
        let layout = TraceFlow()
        let (_, collection) = attached(layout)
        layout.received = []
        collection.frame = CGRect(x: 0, y: 0, width: 220, height: 300)
        XCTAssertEqual(layout.received.count, 1)
        let (context, fromBounds) = layout.received[0]
        XCTAssertTrue(fromBounds)
        let flow = try! XCTUnwrap(context as? UICollectionViewFlowLayoutInvalidationContext)
        XCTAssertTrue(flow.invalidateFlowLayoutAttributes)
        XCTAssertFalse(flow.invalidateFlowLayoutDelegateMetrics)
        XCTAssertFalse(flow.invalidateEverything)
    }
}
