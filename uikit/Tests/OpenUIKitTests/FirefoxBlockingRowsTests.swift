// firefox-ios §9.6 blocking rows: UIToolbarDelegate (2 uses) and
// NSCollectionLayoutAnchor (2 uses). Every expected number is a row of
// Tools/oracle2/firefoxrowsprobe/ios-26.1-iphone16.json (iPhone 16, 3x);
// each test names its row.
import XCTest
@testable import OpenUIKit

// MARK: - UIToolbarDelegate / UIBarPosition

@MainActor
private final class PositionDelegate: UIToolbarDelegate {
    let answer: UIBarPosition
    var calls = 0
    var seen: [UIBarPositioning] = []
    init(_ answer: UIBarPosition) { self.answer = answer }
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        calls += 1
        seen.append(bar)
        return answer
    }
}

/// firefox's TabTrayViewController shape: conforms, implements nothing.
@MainActor
private final class ConformingOnlyDelegate: UIToolbarDelegate {}

/// firefox's TestableUIToolbar shape: a `UIToolbarDelegate?` forwarded to a
/// real toolbar.
@MainActor
private final class ForwardingToolbar {
    let real = UIToolbar(frame: CGRect(x: 0, y: 0, width: 393, height: 44))
    var delegate: UIToolbarDelegate? {
        get { real.delegate }
        set { real.delegate = newValue }
    }
}

@MainActor
final class ToolbarDelegateTests: XCTestCase {

    private func toolbar() -> UIToolbar {
        UIToolbar(frame: CGRect(x: 0, y: 100, width: 393, height: 44))
    }

    /// Row `barPosition.raw`: any/bottom/top/topAttached = 0/1/2/3.
    func testBarPositionRawValues() {
        XCTAssertEqual(UIBarPosition.any.rawValue, 0)
        XCTAssertEqual(UIBarPosition.bottom.rawValue, 1)
        XCTAssertEqual(UIBarPosition.top.rawValue, 2)
        XCTAssertEqual(UIBarPosition.topAttached.rawValue, 3)
    }

    /// Row `toolbar.noDelegate`: delegateNilBefore true, posDetachedNoDelegate
    /// 1, posInWindow 1.
    func testDefaultPositionIsBottomWithoutDelegate() {
        let tb = toolbar()
        XCTAssertNil(tb.delegate)
        XCTAssertEqual(tb.barPosition, .bottom)
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        host.addSubview(tb)
        tb.layoutIfNeeded()
        XCTAssertEqual(tb.barPosition, .bottom)
    }

    /// Row `toolbar.delegate.top`: callsAfterSet 0, posDetachedWithDelegate 1,
    /// callsAfterDetachedRead 0, callsAfterAdd 1, callsAfterLayout 1,
    /// posInWindow 2, callsAfterSecondLayout 1, seenBar ["UIToolbar"].
    func testDelegateIsAskedOnceWhenAddedToSuperview() {
        let tb = toolbar()
        let d = PositionDelegate(.top)
        tb.delegate = d
        XCTAssertEqual(d.calls, 0)
        XCTAssertEqual(tb.barPosition, .bottom)
        XCTAssertEqual(d.calls, 0)
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        host.addSubview(tb)
        XCTAssertEqual(d.calls, 1)
        tb.layoutIfNeeded()
        XCTAssertEqual(d.calls, 1)
        XCTAssertEqual(tb.barPosition, .top)
        tb.setNeedsLayout()
        tb.layoutIfNeeded()
        XCTAssertEqual(d.calls, 1)
        XCTAssertTrue(d.seen.first === tb)
    }

    /// Rows `toolbar.delegate.any` (posInWindow 1), `.bottom` (1),
    /// `.topAttached` (3).
    func testEachAnswerReadsBackInWindow() {
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        for (answer, expected) in [(UIBarPosition.any, UIBarPosition.bottom),
                                   (.bottom, .bottom), (.top, .top),
                                   (.topAttached, .topAttached)] {
            let tb = toolbar()
            let d = PositionDelegate(answer)
            tb.delegate = d
            host.addSubview(tb)
            tb.layoutIfNeeded()
            XCTAssertEqual(tb.barPosition, expected, "answer \(answer)")
            XCTAssertEqual(d.calls, 1, "answer \(answer)")
            tb.removeFromSuperview()
        }
    }

    /// Row `toolbar.delegateNoImpl`: a delegate that implements nothing
    /// (TabTrayViewController) leaves the bar at .bottom with no call.
    func testConformingOnlyDelegateLeavesBottom() {
        let tb = toolbar()
        let d = ConformingOnlyDelegate()
        tb.delegate = d
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        host.addSubview(tb)
        tb.layoutIfNeeded()
        XCTAssertEqual(tb.barPosition, .bottom)
        XCTAssertTrue(tb.delegate === d)
    }

    /// TestableUIToolbar forwards a `UIToolbarDelegate?` property; the
    /// delegate is weak, as UIKit's.
    func testDelegatePropertyForwardsAndIsWeak() {
        let wrapper = ForwardingToolbar()
        var d: PositionDelegate? = PositionDelegate(.top)
        wrapper.delegate = d
        XCTAssertTrue(wrapper.real.delegate === d)
        d = nil
        XCTAssertNil(wrapper.delegate)
    }
}

// MARK: - NSCollectionLayoutAnchor

@MainActor
private final class BadgeSource: UICollectionViewDataSource {
    let sections: Int
    init(sections: Int) { self.sections = sections }
    func numberOfSections(in collectionView: UICollectionView) -> Int { sections }
    func collectionView(_ cv: UICollectionView, numberOfItemsInSection section: Int) -> Int { 2 }
    func collectionView(_ cv: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        cv.dequeueReusableCell(withReuseIdentifier: "c", for: indexPath)
    }
    func collectionView(_ cv: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        cv.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "b",
                                           for: indexPath)
    }
}

private var keptBadgeSources: [BadgeSource] = []

@MainActor
final class CollectionLayoutAnchorTests: XCTestCase {
    private typealias Size = OpenUIKit.NSCollectionLayoutSize
    private typealias Dim = OpenUIKit.NSCollectionLayoutDimension
    private let kind = "badge"
    private let badge20 = Size(widthDimension: Dim.absolute(20), heightDimension: Dim.absolute(20))

    private var previousTraits: UITraitCollection?

    override func setUp() {
        super.setUp()
        // The transcript is iPhone 16 (3x); thirds appear in centred rows.
        previousTraits = UITraitCollection.current
        UITraitCollection.current = UITraitCollection(userInterfaceStyle: .light, displayScale: 3)
    }

    override func tearDown() {
        if let previousTraits { UITraitCollection.current = previousTraits }
        super.tearDown()
    }

    private struct Case {
        var size: Size
        var container: OpenUIKit.NSCollectionLayoutAnchor
        var item: OpenUIKit.NSCollectionLayoutAnchor? = nil
        var insets: OpenUIKit.NSDirectionalEdgeInsets = .zero
    }

    /// The probe's layout: 300 pt collection, section insets 20/30/20/0, two
    /// items per row from `subitem:count: 2` of an absolute-100 item in a
    /// fractionalWidth(1) × absolute(100) group with 20 pt spacing, 40 pt
    /// between sections. Item 0 of section s is [30, 20 + 180 s, 125, 100].
    private func collection(_ cases: [Case]) -> UICollectionView {
        let kind = self.kind
        let cfg = UICollectionViewCompositionalLayoutConfiguration()
        cfg.interSectionSpacing = 40
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { s, _ in
            let c = cases[s]
            let supp: OpenUIKit.NSCollectionLayoutSupplementaryItem
            if let itemAnchor = c.item {
                supp = OpenUIKit.NSCollectionLayoutSupplementaryItem(
                    layoutSize: c.size, elementKind: kind,
                    containerAnchor: c.container, itemAnchor: itemAnchor)
            } else {
                supp = OpenUIKit.NSCollectionLayoutSupplementaryItem(
                    layoutSize: c.size, elementKind: kind, containerAnchor: c.container)
            }
            let item = OpenUIKit.NSCollectionLayoutItem(
                layoutSize: Size(widthDimension: Dim.absolute(100), heightDimension: Dim.absolute(100)),
                supplementaryItems: [supp])
            item.contentInsets = c.insets
            let group = OpenUIKit.NSCollectionLayoutGroup.horizontal(
                layoutSize: Size(widthDimension: Dim.fractionalWidth(1), heightDimension: Dim.absolute(100)),
                subitem: item, count: 2)
            group.interItemSpacing = OpenUIKit.NSCollectionLayoutSpacing.fixed(20)
            let section = OpenUIKit.NSCollectionLayoutSection(group: group)
            section.contentInsets = OpenUIKit.NSDirectionalEdgeInsets(top: 20, leading: 30, bottom: 20, trailing: 0)
            return section
        }, configuration: cfg)
        let cv = UICollectionView(frame: CGRect(x: 0, y: 0, width: 300, height: 600),
                                   collectionViewLayout: layout)
        cv.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "c")
        cv.register(UICollectionReusableView.self, forSupplementaryViewOfKind: kind,
                    withReuseIdentifier: "b")
        let src = BadgeSource(sections: cases.count)
        keptBadgeSources.append(src)
        cv.dataSource = src
        cv.layoutIfNeeded()
        return cv
    }

    private func supp(_ cv: UICollectionView, _ section: Int, _ item: Int = 0) -> CGRect? {
        cv.layoutAttributesForSupplementaryElement(ofKind: kind,
                                                   at: IndexPath(item: item, section: section))?.frame
    }

    private func item(_ cv: UICollectionView, _ section: Int, _ item: Int = 0) -> CGRect? {
        cv.layoutAttributesForItem(at: IndexPath(item: item, section: section))?.frame
    }

    /// Rows `anchor.edgesOnly` / `anchor.absolute` / `anchor.fractional`,
    /// `rectEdge.raw`, `supp.defaults`, `item.supplementaryItems`.
    func testAnchorAndSupplementaryReadback() {
        XCTAssertEqual(OpenUIKit.NSDirectionalRectEdge.top.rawValue, 1)
        XCTAssertEqual(OpenUIKit.NSDirectionalRectEdge.leading.rawValue, 2)
        XCTAssertEqual(OpenUIKit.NSDirectionalRectEdge.bottom.rawValue, 4)
        XCTAssertEqual(OpenUIKit.NSDirectionalRectEdge.trailing.rawValue, 8)
        XCTAssertEqual(OpenUIKit.NSDirectionalRectEdge.all.rawValue, 15)
        let a1 = OpenUIKit.NSCollectionLayoutAnchor(edges: [.top, .trailing])
        XCTAssertEqual(a1.edges.rawValue, 9)
        XCTAssertEqual(a1.offset, .zero)
        XCTAssertTrue(a1.isAbsoluteOffset)
        XCTAssertFalse(a1.isFractionalOffset)
        let a2 = OpenUIKit.NSCollectionLayoutAnchor(edges: [.top, .trailing],
                                                    absoluteOffset: CGPoint(x: 10, y: -10))
        XCTAssertEqual(a2.offset, CGPoint(x: 10, y: -10))
        XCTAssertTrue(a2.isAbsoluteOffset)
        let a3 = OpenUIKit.NSCollectionLayoutAnchor(edges: [.bottom],
                                                    fractionalOffset: CGPoint(x: 0.5, y: -0.5))
        XCTAssertEqual(a3.edges.rawValue, 4)
        XCTAssertEqual(a3.offset, CGPoint(x: 0.5, y: -0.5))
        XCTAssertFalse(a3.isAbsoluteOffset)
        XCTAssertTrue(a3.isFractionalOffset)

        let s1 = OpenUIKit.NSCollectionLayoutSupplementaryItem(layoutSize: badge20, elementKind: kind,
                                                                containerAnchor: a1)
        XCTAssertEqual(s1.zIndex, 1)
        XCTAssertNil(s1.itemAnchor)
        XCTAssertTrue(s1.containerAnchor === a1)
        XCTAssertEqual(s1.elementKind, kind)
        XCTAssertEqual(s1.contentInsets, .zero)
        let s2 = OpenUIKit.NSCollectionLayoutSupplementaryItem(layoutSize: badge20, elementKind: kind,
                                                                containerAnchor: a1, itemAnchor: a3)
        XCTAssertTrue(s2.itemAnchor === a3)
        let it = OpenUIKit.NSCollectionLayoutItem(layoutSize: badge20, supplementaryItems: [s1, s2])
        XCTAssertEqual(it.supplementaryItems.count, 2)
        XCTAssertEqual(OpenUIKit.NSCollectionLayoutItem(layoutSize: badge20).supplementaryItems.count, 0)
    }

    /// Row `anchors.ltr.bottom.fullwidth` — firefox's TabsSectionManager
    /// title: item0 [30, 20, 125, 100], supp0 [30, 90, 125, 30]; item1
    /// [175, 20, 125, 100], supp1 [175, 90, 125, 30]; z 1, index path (0, i).
    func testFirefoxBottomFullWidthTitle() {
        let cv = collection([Case(size: Size(widthDimension: Dim.fractionalWidth(1.0),
                                             heightDimension: Dim.absolute(30)),
                                  container: OpenUIKit.NSCollectionLayoutAnchor(edges: [.bottom]))])
        XCTAssertEqual(item(cv, 0, 0), CGRect(x: 30, y: 20, width: 125, height: 100))
        XCTAssertEqual(supp(cv, 0, 0), CGRect(x: 30, y: 90, width: 125, height: 30))
        XCTAssertEqual(item(cv, 0, 1), CGRect(x: 175, y: 20, width: 125, height: 100))
        XCTAssertEqual(supp(cv, 0, 1), CGRect(x: 175, y: 90, width: 125, height: 30))
        let a = cv.layoutAttributesForSupplementaryElement(ofKind: kind, at: IndexPath(item: 1, section: 0))
        XCTAssertEqual(a?.zIndex, 1)
        XCTAssertEqual(a?.indexPath, IndexPath(item: 1, section: 0))
        XCTAssertEqual(cv.layoutAttributesForItem(at: IndexPath(item: 1, section: 0))?.zIndex, 0)
    }

    /// Rows `topTrailing` [135, 200, 20, 20], `topTrailing.fractional.5`
    /// [145, 370, 20, 20], `topTrailing.absolute10` [145, 550, 20, 20]:
    /// the badge sits inside the corner; a fractional offset scales by the
    /// badge's own 20 pt, not the item's 125.
    func testTopTrailingCornerAndOffsets() {
        let cv = collection([
            Case(size: badge20, container: OpenUIKit.NSCollectionLayoutAnchor(edges: [.top, .trailing])),
            Case(size: badge20, container: OpenUIKit.NSCollectionLayoutAnchor(
                edges: [.top, .trailing], fractionalOffset: CGPoint(x: 0.5, y: -0.5))),
            Case(size: badge20, container: OpenUIKit.NSCollectionLayoutAnchor(
                edges: [.top, .trailing], absoluteOffset: CGPoint(x: 10, y: -10))),
        ])
        XCTAssertEqual(item(cv, 0), CGRect(x: 30, y: 20, width: 125, height: 100))
        XCTAssertEqual(supp(cv, 0), CGRect(x: 135, y: 20, width: 20, height: 20))
        XCTAssertEqual(supp(cv, 0, 1), CGRect(x: 280, y: 20, width: 20, height: 20))
        XCTAssertEqual(item(cv, 1), CGRect(x: 30, y: 200, width: 125, height: 100))
        XCTAssertEqual(supp(cv, 1), CGRect(x: 145, y: 190, width: 20, height: 20))
        XCTAssertEqual(item(cv, 2), CGRect(x: 30, y: 380, width: 125, height: 100))
        XCTAssertEqual(supp(cv, 2), CGRect(x: 145, y: 370, width: 20, height: 20))
    }

    /// Rows `none`, `leadingTrailing`, `all` → x 82.667 (82.5 snapped to
    /// thirds), y +40: an axis with neither or both edges is centred.
    /// `leading.absolute5` → [35, +45]; `bottom.fractional0_5` → y +90;
    /// `top.absoluteY-7` → y −7.
    func testCentredAxesAndSingleEdges() {
        let cv = collection([
            Case(size: badge20, container: OpenUIKit.NSCollectionLayoutAnchor(edges: [])),
            Case(size: badge20, container: OpenUIKit.NSCollectionLayoutAnchor(edges: [.leading, .trailing])),
            Case(size: badge20, container: OpenUIKit.NSCollectionLayoutAnchor(edges: .all)),
            Case(size: badge20, container: OpenUIKit.NSCollectionLayoutAnchor(
                edges: [.leading], absoluteOffset: CGPoint(x: 5, y: 5))),
            Case(size: badge20, container: OpenUIKit.NSCollectionLayoutAnchor(
                edges: [.bottom], fractionalOffset: CGPoint(x: 0, y: 0.5))),
            Case(size: badge20, container: OpenUIKit.NSCollectionLayoutAnchor(
                edges: [.top], absoluteOffset: CGPoint(x: 0, y: -7))),
        ])
        let third = 248.0 / 3
        for s in 0..<3 {
            let f = try! XCTUnwrap(supp(cv, s))
            XCTAssertEqual(f.minX, third, accuracy: 0.001, "section \(s)")
            XCTAssertEqual(f.minY, 20 + 180 * CGFloat(s) + 40, accuracy: 0.001, "section \(s)")
            XCTAssertEqual(f.size, CGSize(width: 20, height: 20))
        }
        XCTAssertEqual(supp(cv, 3), CGRect(x: 35, y: 20 + 540 + 45, width: 20, height: 20))
        XCTAssertEqual(supp(cv, 4)?.minY, 20 + 720 + 90)
        XCTAssertEqual(supp(cv, 4)?.minX ?? 0, third, accuracy: 0.001)
        XCTAssertEqual(supp(cv, 5)?.minY, 20 + 900 - 7)
    }

    /// Rows `topTrailing.itemBottomLeading` [155, y−20],
    /// `…itemAbs3_4` [158, y−16], `topTrailing.itemNone.fractional`
    /// [155, y]: the item anchor chooses which point of the badge lands on
    /// the container's top-trailing corner (155, y), plus its own offset.
    func testItemAnchorSelectsTheBadgePoint() {
        let corner = OpenUIKit.NSCollectionLayoutAnchor(edges: [.top, .trailing])
        let cv = collection([
            Case(size: badge20, container: corner,
                 item: OpenUIKit.NSCollectionLayoutAnchor(edges: [.bottom, .leading])),
            Case(size: badge20, container: corner,
                 item: OpenUIKit.NSCollectionLayoutAnchor(edges: [.bottom, .leading],
                                                          absoluteOffset: CGPoint(x: 3, y: 4))),
            Case(size: badge20, container: corner,
                 item: OpenUIKit.NSCollectionLayoutAnchor(edges: [],
                                                          fractionalOffset: CGPoint(x: 0.5, y: 0.5))),
        ])
        XCTAssertEqual(supp(cv, 0), CGRect(x: 155, y: 0, width: 20, height: 20))
        XCTAssertEqual(supp(cv, 1), CGRect(x: 158, y: 200 - 16, width: 20, height: 20))
        XCTAssertEqual(supp(cv, 2), CGRect(x: 155, y: 380, width: 20, height: 20))
    }

    /// Row `topTrailing.insets10`: item [40, y, 105, 80] and badge [125, y]:
    /// the container is the item's INSET frame. Row
    /// `bottomTrailing.fractionalSize`: fractionalWidth(0.5) ×
    /// fractionalHeight(0.25) resolves against that container → height 25,
    /// maxX 155, y +75; the 3x origin snap gives [92.667, 62.333].
    func testContainerIsInsetFrameAndFractionalSizes() {
        let cv = collection([
            Case(size: badge20, container: OpenUIKit.NSCollectionLayoutAnchor(edges: [.top, .trailing]),
                 insets: OpenUIKit.NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)),
            Case(size: Size(widthDimension: Dim.fractionalWidth(0.5), heightDimension: Dim.fractionalHeight(0.25)),
                 container: OpenUIKit.NSCollectionLayoutAnchor(edges: [.bottom, .trailing])),
        ])
        // Section 12 in the transcript: item [40, 2190, 105, 80] for a
        // section at 2160 + 20; here section 0 → 20 + 10.
        XCTAssertEqual(item(cv, 0), CGRect(x: 40, y: 30, width: 105, height: 80))
        XCTAssertEqual(supp(cv, 0), CGRect(x: 125, y: 30, width: 20, height: 20))
        let f = try! XCTUnwrap(supp(cv, 1))
        XCTAssertEqual(f.minX, 278.0 / 3, accuracy: 0.001)
        XCTAssertEqual(f.maxX, 155, accuracy: 0.001)
        XCTAssertEqual(f.minY, 200 + 75)
        XCTAssertEqual(f.height, 25)
    }

    /// Row `anchors.ltr.elementsIn200` / `visibleBadges`: both badges of
    /// the first row are tiled (two views of the kind at their own index
    /// paths) and `contentSize` is unchanged by badges (2660 for 15
    /// sections: 15 × 140 + 14 × 40).
    func testBadgesAreTiledPerItemAndDoNotGrowContent() {
        var cases: [Case] = []
        for _ in 0..<15 {
            cases.append(Case(size: badge20,
                              container: OpenUIKit.NSCollectionLayoutAnchor(edges: [.top, .trailing])))
        }
        let cv = collection(cases)
        XCTAssertEqual(cv.contentSize, CGSize(width: 300, height: 2660))
        let badges = cv.visibleSupplementaryViews(ofKind: kind)
        XCTAssertEqual(badges.count, 8, "4 rows × 2 badges within 600 pt")
        XCTAssertEqual(badges[0].frame, CGRect(x: 135, y: 20, width: 20, height: 20))
        XCTAssertEqual(badges[1].frame, CGRect(x: 280, y: 20, width: 20, height: 20))
        XCTAssertTrue(cv.supplementaryView(forElementKind: kind, at: IndexPath(item: 1, section: 0)) === badges[1])
        let elems = cv.collectionViewLayout.layoutAttributesForElements(
            in: CGRect(x: 0, y: 0, width: 300, height: 200)) ?? []
        XCTAssertEqual(elems.filter { $0.representedElementKind == kind }.count, 2)
        XCTAssertEqual(elems.filter { $0.representedElementKind == nil }.count, 2)
    }
}
