// UICollectionView tests (M13).
//
// Three groups:
//   1. FlowLayoutMeasuredTests — every frame here is a TRANSCRIPT of real
//      UIKit's answer, captured with `scripts/flow_probe.sh` (iOS 26 Mac
//      Catalyst, 20 configurations). This is the oracle for the geometry the
//      fixture scenes cannot isolate (spacing distribution on partial lines,
//      phantom fill, pixel snapping, cross-axis centering).
//   2. CollectionViewReuseTests — the reuse gate, mirroring
//      TableViewTests: a 10k-item sweep must instantiate ~one screenful.
//   3. CollectionViewBehaviourTests — selection, tiling, batch updates.
import XCTest
import Foundation
@testable import OpenUIKit

// XCTest re-exports Foundation/CoreGraphics on Darwin; pin the portable types.
private typealias CGFloat = OpenUIKit.CGFloat
private typealias CGPoint = OpenUIKit.CGPoint
private typealias CGSize = OpenUIKit.CGSize
private typealias CGRect = OpenUIKit.CGRect
private typealias IndexPath = OpenUIKit.IndexPath
private typealias UIEdgeInsets = OpenUIKit.UIEdgeInsets

// MARK: - Shared drivers

private final class FlowSource: UICollectionViewDataSource,
                               UICollectionViewDelegateFlowLayout {
    var counts: [Int]
    var sizeFor: ((IndexPath) -> CGSize)?
    init(_ counts: [Int], sizeFor: ((IndexPath) -> CGSize)? = nil) {
        self.counts = counts
        self.sizeFor = sizeFor
    }
    func numberOfSections(in collectionView: UICollectionView) -> Int { counts.count }
    func collectionView(_ cv: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        counts[section]
    }
    func collectionView(_ cv: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        cv.dequeueReusableCell(withReuseIdentifier: "c", for: indexPath)
    }
    func collectionView(_ cv: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        cv.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "s",
                                            for: indexPath)
    }
    func collectionView(_ cv: UICollectionView, layout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        sizeFor?(indexPath) ?? (layout as! UICollectionViewFlowLayout).itemSize
    }
}

/// Data sources are held WEAKLY by the collection view (UIKit semantics), so
/// the tests keep them alive here.
private var keptSources: [FlowSource] = []

private func makeCollection(width: CGFloat, height: CGFloat, counts: [Int],
                            sizeFor: ((IndexPath) -> CGSize)? = nil,
                            configure: (UICollectionViewFlowLayout) -> Void)
    -> (UICollectionView, FlowSource) {
    let layout = UICollectionViewFlowLayout()
    configure(layout)
    let cv = UICollectionView(frame: CGRect(x: 0, y: 0, width: width, height: height),
                              collectionViewLayout: layout)
    cv.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "c")
    cv.register(UICollectionReusableView.self,
                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                withReuseIdentifier: "s")
    cv.register(UICollectionReusableView.self,
                forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                withReuseIdentifier: "s")
    let src = FlowSource(counts, sizeFor: sizeFor)
    keptSources.append(src)
    cv.dataSource = src
    cv.delegate = src
    cv.layoutIfNeeded()
    return (cv, src)
}

// MARK: - 1. Measured flow-layout geometry

final class FlowLayoutMeasuredTests: XCTestCase {
    override func setUp() {
        super.setUp()
        TextTestSupport.configureResourceRoot()
    }

    private func assertItems(_ cv: UICollectionView, _ expected: [(Int, Int, CGRect)],
                             file: StaticString = #filePath, line: UInt = #line) {
        for (s, i, rect) in expected {
            guard let a = cv.collectionViewLayout
                .layoutAttributesForItem(at: IndexPath(item: i, section: s)) else {
                XCTFail("no attributes for [\(s),\(i)]", file: file, line: line)
                continue
            }
            XCTAssertEqual(a.frame.minX, rect.minX, accuracy: 0.001,
                           "[\(s),\(i)].x", file: file, line: line)
            XCTAssertEqual(a.frame.minY, rect.minY, accuracy: 0.001,
                           "[\(s),\(i)].y", file: file, line: line)
            XCTAssertEqual(a.frame.width, rect.width, accuracy: 0.001,
                           "[\(s),\(i)].w", file: file, line: line)
            XCTAssertEqual(a.frame.height, rect.height, accuracy: 0.001,
                           "[\(s),\(i)].h", file: file, line: line)
        }
    }

    private func assertSupplementary(_ cv: UICollectionView, kind: String, section: Int,
                                     _ rect: CGRect?,
                                     file: StaticString = #filePath, line: UInt = #line) {
        let a = cv.collectionViewLayout.layoutAttributesForSupplementaryView(
            ofKind: kind, at: IndexPath(item: 0, section: section))
        guard let rect else {
            XCTAssertNil(a, "expected no \(kind) in section \(section)", file: file, line: line)
            return
        }
        XCTAssertEqual(a?.frame.minX, rect.minX, file: file, line: line)
        XCTAssertEqual(a?.frame.minY, rect.minY, file: file, line: line)
        XCTAssertEqual(a?.frame.width, rect.width, file: file, line: line)
        XCTAssertEqual(a?.frame.height, rect.height, file: file, line: line)
    }

    /// Probe A: three items per line, leftover distributed (the last item on
    /// a full line ends flush with the content edge).
    func testFullLineDistributesLeftoverSpacing() {
        let (cv, _) = makeCollection(width: 375, height: 400, counts: [7]) { l in
            l.itemSize = CGSize(width: 100, height: 60)
            l.minimumLineSpacing = 10
            l.minimumInteritemSpacing = 10
            l.sectionInset = .zero
        }
        assertItems(cv, [
            (0, 0, CGRect(x: 0, y: 0, width: 100, height: 60)),
            (0, 1, CGRect(x: 137.5, y: 0, width: 100, height: 60)),
            (0, 2, CGRect(x: 275, y: 0, width: 100, height: 60)),
            (0, 3, CGRect(x: 0, y: 70, width: 100, height: 60)),
            (0, 5, CGRect(x: 275, y: 70, width: 100, height: 60)),
            (0, 6, CGRect(x: 0, y: 140, width: 100, height: 60)),
        ])
        XCTAssertEqual(cv.contentSize.height, 200, accuracy: 0.001)
    }

    /// Probe B: section insets shrink the available line.
    func testSectionInsetsShrinkTheLine() {
        let (cv, _) = makeCollection(width: 375, height: 400, counts: [7]) { l in
            l.itemSize = CGSize(width: 100, height: 60)
            l.minimumLineSpacing = 10
            l.minimumInteritemSpacing = 10
            l.sectionInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        }
        assertItems(cv, [
            (0, 0, CGRect(x: 16, y: 8, width: 100, height: 60)),
            (0, 1, CGRect(x: 137.5, y: 8, width: 100, height: 60)),
            (0, 2, CGRect(x: 259, y: 8, width: 100, height: 60)),
            (0, 6, CGRect(x: 16, y: 148, width: 100, height: 60)),
        ])
        XCTAssertEqual(cv.contentSize.height, 216, accuracy: 0.001)
    }

    /// Probe C: an EXACT fit (3x115 + 2x15 = 375) must not spill to the next
    /// line — the packing test carries an epsilon for exactly this.
    func testExactFitKeepsThreePerLine() {
        let (cv, _) = makeCollection(width: 375, height: 400, counts: [5]) { l in
            l.itemSize = CGSize(width: 115, height: 50)
            l.minimumLineSpacing = 12
            l.minimumInteritemSpacing = 15
            l.sectionInset = .zero
        }
        assertItems(cv, [
            (0, 0, CGRect(x: 0, y: 0, width: 115, height: 50)),
            (0, 1, CGRect(x: 130, y: 0, width: 115, height: 50)),
            (0, 2, CGRect(x: 260, y: 0, width: 115, height: 50)),
            (0, 3, CGRect(x: 0, y: 62, width: 115, height: 50)),
            (0, 4, CGRect(x: 130, y: 62, width: 115, height: 50)),
        ])
        XCTAssertEqual(cv.contentSize.height, 112, accuracy: 0.001)
    }

    /// Probe D: headers/footers span the full width, insets apply only to the
    /// items — and a partial line is snapped to the pixel grid (10.333 pt
    /// spacing lands on 102.5 / 192.5, not 102.333 / 192.667).
    func testHeadersFootersAndPixelSnapping() {
        let (cv, _) = makeCollection(width: 375, height: 400, counts: [3, 2]) { l in
            l.itemSize = CGSize(width: 80, height: 40)
            l.minimumLineSpacing = 10
            l.minimumInteritemSpacing = 10
            l.sectionInset = UIEdgeInsets(top: 4, left: 12, bottom: 6, right: 12)
            l.headerReferenceSize = CGSize(width: 0, height: 30)
            l.footerReferenceSize = CGSize(width: 0, height: 20)
        }
        assertSupplementary(cv, kind: UICollectionView.elementKindSectionHeader, section: 0,
                            CGRect(x: 0, y: 0, width: 375, height: 30))
        assertSupplementary(cv, kind: UICollectionView.elementKindSectionFooter, section: 0,
                            CGRect(x: 0, y: 80, width: 375, height: 20))
        assertSupplementary(cv, kind: UICollectionView.elementKindSectionHeader, section: 1,
                            CGRect(x: 0, y: 100, width: 375, height: 30))
        assertSupplementary(cv, kind: UICollectionView.elementKindSectionFooter, section: 1,
                            CGRect(x: 0, y: 180, width: 375, height: 20))
        assertItems(cv, [
            (0, 0, CGRect(x: 12, y: 34, width: 80, height: 40)),
            (0, 1, CGRect(x: 102.5, y: 34, width: 80, height: 40)),
            (0, 2, CGRect(x: 192.5, y: 34, width: 80, height: 40)),
            (1, 0, CGRect(x: 12, y: 134, width: 80, height: 40)),
            (1, 1, CGRect(x: 102.5, y: 134, width: 80, height: 40)),
        ])
        XCTAssertEqual(cv.contentSize.height, 200, accuracy: 0.001)
    }

    /// Probe E: horizontal scrolling packs COLUMNS — minimumInteritemSpacing
    /// runs down the column, minimumLineSpacing between columns.
    func testHorizontalDirectionPacksColumns() {
        let (cv, _) = makeCollection(width: 375, height: 220, counts: [7]) { l in
            l.scrollDirection = .horizontal
            l.itemSize = CGSize(width: 90, height: 70)
            l.minimumLineSpacing = 10
            l.minimumInteritemSpacing = 10
            l.sectionInset = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        }
        assertItems(cv, [
            (0, 0, CGRect(x: 12, y: 8, width: 90, height: 70)),
            (0, 1, CGRect(x: 12, y: 142, width: 90, height: 70)),
            (0, 2, CGRect(x: 112, y: 8, width: 90, height: 70)),
            (0, 5, CGRect(x: 212, y: 142, width: 90, height: 70)),
            (0, 6, CGRect(x: 312, y: 8, width: 90, height: 70)),
        ])
        XCTAssertEqual(cv.contentSize.width, 414, accuracy: 0.001)
        XCTAssertEqual(cv.contentSize.height, 220, accuracy: 0.001)
    }

    /// Probe F: horizontal headers/footers span the full height and consume
    /// main-axis extent between sections.
    func testHorizontalHeadersAndFooters() {
        let (cv, _) = makeCollection(width: 375, height: 200, counts: [3, 2]) { l in
            l.scrollDirection = .horizontal
            l.itemSize = CGSize(width: 90, height: 70)
            l.minimumLineSpacing = 10
            l.minimumInteritemSpacing = 10
            l.sectionInset = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
            l.headerReferenceSize = CGSize(width: 40, height: 0)
            l.footerReferenceSize = CGSize(width: 20, height: 0)
        }
        assertSupplementary(cv, kind: UICollectionView.elementKindSectionHeader, section: 0,
                            CGRect(x: 0, y: 0, width: 40, height: 200))
        assertSupplementary(cv, kind: UICollectionView.elementKindSectionFooter, section: 0,
                            CGRect(x: 254, y: 0, width: 20, height: 200))
        assertSupplementary(cv, kind: UICollectionView.elementKindSectionHeader, section: 1,
                            CGRect(x: 274, y: 0, width: 40, height: 200))
        assertSupplementary(cv, kind: UICollectionView.elementKindSectionFooter, section: 1,
                            CGRect(x: 428, y: 0, width: 20, height: 200))
        assertItems(cv, [
            (0, 0, CGRect(x: 52, y: 8, width: 90, height: 70)),
            (0, 1, CGRect(x: 52, y: 122, width: 90, height: 70)),
            (0, 2, CGRect(x: 152, y: 8, width: 90, height: 70)),
            (1, 0, CGRect(x: 326, y: 8, width: 90, height: 70)),
            (1, 1, CGRect(x: 326, y: 122, width: 90, height: 70)),
        ])
        XCTAssertEqual(cv.contentSize.width, 448, accuracy: 0.001)
    }

    /// Probes G/K: when only one item fits per line it is CENTERED — even
    /// when it is wider than the line (UIKit's negative origin).
    func testSingleItemPerLineIsCentered() {
        let (wide, _) = makeCollection(width: 200, height: 300, counts: [3]) { l in
            l.itemSize = CGSize(width: 250, height: 40)
            l.minimumLineSpacing = 6
            l.minimumInteritemSpacing = 6
            l.sectionInset = .zero
        }
        assertItems(wide, [
            (0, 0, CGRect(x: -25, y: 0, width: 250, height: 40)),
            (0, 1, CGRect(x: -25, y: 46, width: 250, height: 40)),
            (0, 2, CGRect(x: -25, y: 92, width: 250, height: 40)),
        ])
        XCTAssertEqual(wide.contentSize.height, 132, accuracy: 0.001)

        let (narrow, _) = makeCollection(width: 200, height: 300, counts: [2]) { l in
            l.itemSize = CGSize(width: 150, height: 40)
            l.minimumLineSpacing = 6
            l.minimumInteritemSpacing = 10
            l.sectionInset = .zero
        }
        assertItems(narrow, [
            (0, 0, CGRect(x: 25, y: 0, width: 150, height: 40)),
            (0, 1, CGRect(x: 25, y: 46, width: 150, height: 40)),
        ])
    }

    /// Probes H/L/N: a LAST line is spaced as if it were full — phantom
    /// items of the last item's size are appended before the leftover is
    /// distributed. Four 50 pt items in 375 pt land 15 pt apart (a full line
    /// of six), NOT 10 pt (the minimum) and NOT spread across the width.
    func testLastLineIsSpacedAsIfFull() {
        let (four, _) = makeCollection(width: 375, height: 300, counts: [4]) { l in
            l.itemSize = CGSize(width: 50, height: 50)
        }
        assertItems(four, [
            (0, 0, CGRect(x: 0, y: 0, width: 50, height: 50)),
            (0, 1, CGRect(x: 65, y: 0, width: 50, height: 50)),
            (0, 2, CGRect(x: 130, y: 0, width: 50, height: 50)),
            (0, 3, CGRect(x: 195, y: 0, width: 50, height: 50)),
        ])

        let (single, _) = makeCollection(width: 200, height: 300, counts: [1]) { l in
            l.itemSize = CGSize(width: 90, height: 40)
            l.minimumLineSpacing = 6
            l.minimumInteritemSpacing = 10
            l.sectionInset = .zero
        }
        // Capacity 2, so the lone item is left-aligned, not centered.
        assertItems(single, [(0, 0, CGRect(x: 0, y: 0, width: 90, height: 40))])

        let (two, _) = makeCollection(width: 375, height: 300, counts: [2]) { l in
            l.itemSize = CGSize(width: 80, height: 40)
            l.headerReferenceSize = .zero
            l.footerReferenceSize = CGSize(width: 0, height: 12)
            l.sectionInset = .zero
        }
        assertItems(two, [
            (0, 0, CGRect(x: 0, y: 0, width: 80, height: 40)),
            (0, 1, CGRect(x: 98.5, y: 0, width: 80, height: 40)),
        ])
        // A zero reference size means NO supplementary view at all.
        assertSupplementary(two, kind: UICollectionView.elementKindSectionHeader,
                            section: 0, nil)
        assertSupplementary(two, kind: UICollectionView.elementKindSectionFooter, section: 0,
                            CGRect(x: 0, y: 40, width: 375, height: 12))
        XCTAssertEqual(two.contentSize.height, 52, accuracy: 0.001)
    }

    /// Probe I: fractional item sizes round to the pixel grid (131.75 -> 132)
    /// while the sizes themselves stay exact.
    func testFractionalItemSizesSnapPositionsNotSizes() {
        let (cv, _) = makeCollection(width: 375, height: 300, counts: [6]) { l in
            l.itemSize = CGSize(width: 111.5, height: 44.25)
            l.minimumLineSpacing = 8
            l.minimumInteritemSpacing = 7
            l.sectionInset = UIEdgeInsets(top: 5, left: 9, bottom: 5, right: 9)
        }
        assertItems(cv, [
            (0, 0, CGRect(x: 9, y: 5, width: 111.5, height: 44.25)),
            (0, 1, CGRect(x: 132, y: 5, width: 111.5, height: 44.25)),
            (0, 2, CGRect(x: 254.5, y: 5, width: 111.5, height: 44.25)),
            (0, 3, CGRect(x: 9, y: 57.5, width: 111.5, height: 44.25)),
            (0, 5, CGRect(x: 254.5, y: 57.5, width: 111.5, height: 44.25)),
        ])
        XCTAssertEqual(cv.contentSize.height, 106.5, accuracy: 0.001)
    }

    /// Probe J: an EMPTY section still contributes its header, both insets
    /// and its footer.
    func testEmptySectionKeepsItsChrome() {
        let (cv, _) = makeCollection(width: 375, height: 300, counts: [1, 0, 1]) { l in
            l.itemSize = CGSize(width: 80, height: 40)
            l.minimumLineSpacing = 10
            l.minimumInteritemSpacing = 10
            l.sectionInset = UIEdgeInsets(top: 4, left: 12, bottom: 6, right: 12)
            l.headerReferenceSize = CGSize(width: 0, height: 30)
            l.footerReferenceSize = CGSize(width: 0, height: 20)
        }
        assertSupplementary(cv, kind: UICollectionView.elementKindSectionHeader, section: 1,
                            CGRect(x: 0, y: 100, width: 375, height: 30))
        assertSupplementary(cv, kind: UICollectionView.elementKindSectionFooter, section: 1,
                            CGRect(x: 0, y: 140, width: 375, height: 20))
        assertSupplementary(cv, kind: UICollectionView.elementKindSectionHeader, section: 2,
                            CGRect(x: 0, y: 160, width: 375, height: 30))
        assertItems(cv, [(2, 0, CGRect(x: 12, y: 194, width: 80, height: 40))])
        XCTAssertEqual(cv.contentSize.height, 260, accuracy: 0.001)
    }

    /// Probes M/Q: delegate-supplied variable sizes — a line's extent is its
    /// TALLEST item and the shorter ones are centered across it; full lines
    /// justify across their actual items.
    func testVariableItemSizes() {
        let widths: [CGFloat] = [120, 100, 90, 200, 60, 150]
        let heights: [CGFloat] = [40, 55, 40, 30, 40, 40]
        let (cv, _) = makeCollection(width: 375, height: 400, counts: [6], sizeFor: { ip in
            CGSize(width: widths[ip.item], height: heights[ip.item])
        }) { l in
            l.minimumLineSpacing = 10
            l.minimumInteritemSpacing = 8
            l.sectionInset = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        }
        assertItems(cv, [
            (0, 0, CGRect(x: 10, y: 12.5, width: 120, height: 40)),
            (0, 1, CGRect(x: 152.5, y: 5, width: 100, height: 55)),
            (0, 2, CGRect(x: 275, y: 12.5, width: 90, height: 40)),
            (0, 3, CGRect(x: 10, y: 75, width: 200, height: 30)),
            (0, 4, CGRect(x: 305, y: 70, width: 60, height: 40)),
            (0, 5, CGRect(x: 10, y: 120, width: 150, height: 40)),
        ])
        XCTAssertEqual(cv.contentSize.height, 165, accuracy: 0.001)

        let (tall, _) = makeCollection(width: 375, height: 400, counts: [4], sizeFor: { ip in
            CGSize(width: 80, height: ip.item == 1 ? 90 : 40)
        }) { l in
            l.minimumLineSpacing = 10
            l.minimumInteritemSpacing = 10
            l.sectionInset = .zero
        }
        assertItems(tall, [
            (0, 0, CGRect(x: 0, y: 25, width: 80, height: 40)),
            (0, 1, CGRect(x: 90, y: 0, width: 80, height: 90)),
            (0, 2, CGRect(x: 180, y: 25, width: 80, height: 40)),
            (0, 3, CGRect(x: 270, y: 25, width: 80, height: 40)),
        ])
        XCTAssertEqual(tall.contentSize.height, 90, accuracy: 0.001)
    }

    /// Probes AA/AB: a LAST line whose items differ in size (in EITHER
    /// dimension) drops back to the plain minimum spacing — the phantom fill
    /// applies only to a uniform line. The `tall` case above is the
    /// height-only version; this is the width version.
    func testMixedSizeLastLineUsesTheMinimumSpacing() {
        let widths: [CGFloat] = [80, 100, 60]
        let (cv, _) = makeCollection(width: 375, height: 300, counts: [3], sizeFor: { ip in
            CGSize(width: widths[ip.item], height: 40)
        }) { l in
            l.itemSize = CGSize(width: 80, height: 40)
            l.minimumLineSpacing = 10
            l.minimumInteritemSpacing = 10
            l.sectionInset = .zero
        }
        assertItems(cv, [
            (0, 0, CGRect(x: 0, y: 0, width: 80, height: 40)),
            (0, 1, CGRect(x: 90, y: 0, width: 100, height: 40)),
            (0, 2, CGRect(x: 200, y: 0, width: 60, height: 40)),
        ])
    }

    /// Probes X/Y/Z: uniform sizes get the phantom fill whether they come
    /// from `itemSize`, from a delegate that echoes it, or from a delegate
    /// that returns something else entirely.
    func testUniformLineIsPhantomFilledWhereverTheSizeCameFrom() {
        let expected: [(Int, Int, CGRect)] = [
            (0, 0, CGRect(x: 0, y: 0, width: 80, height: 40)),
            (0, 1, CGRect(x: 98.5, y: 0, width: 80, height: 40)),
            (0, 2, CGRect(x: 196.5, y: 0, width: 80, height: 40)),
            (0, 3, CGRect(x: 295, y: 0, width: 80, height: 40)),
        ]
        // Delegate size, layout.itemSize left at the 50x50 default.
        let (a, _) = makeCollection(width: 375, height: 300, counts: [4],
                                    sizeFor: { _ in CGSize(width: 80, height: 40) }) { l in
            l.sectionInset = .zero
        }
        assertItems(a, expected)
        // No delegate size at all.
        let (b, _) = makeCollection(width: 375, height: 300, counts: [4]) { l in
            l.itemSize = CGSize(width: 80, height: 40)
            l.sectionInset = .zero
        }
        assertItems(b, expected)
    }

    /// Probe AD: a FULL line justifies across its actual items even when they
    /// differ in size, and probe AE: uniformity is decided per LINE, not per
    /// section (and sections butt together with no line spacing between).
    func testFullMixedLineJustifiesAndUniformityIsPerLine() {
        let (full, _) = makeCollection(width: 375, height: 300, counts: [5], sizeFor: { ip in
            CGSize(width: 80, height: ip.item == 1 ? 90 : 40)
        }) { l in
            l.itemSize = CGSize(width: 80, height: 40)
            l.sectionInset = .zero
        }
        assertItems(full, [
            (0, 0, CGRect(x: 0, y: 25, width: 80, height: 40)),
            (0, 1, CGRect(x: 98.5, y: 0, width: 80, height: 90)),
            (0, 3, CGRect(x: 295, y: 25, width: 80, height: 40)),
            (0, 4, CGRect(x: 0, y: 100, width: 80, height: 40)),
        ])
        XCTAssertEqual(full.contentSize.height, 140, accuracy: 0.001)

        let (mixed, _) = makeCollection(width: 375, height: 400, counts: [3, 3],
                                        sizeFor: { ip in
            CGSize(width: 80, height: (ip.section == 1 && ip.item == 1) ? 90 : 40)
        }) { l in
            l.itemSize = CGSize(width: 80, height: 40)
            l.sectionInset = .zero
        }
        assertItems(mixed, [
            (0, 1, CGRect(x: 98.5, y: 0, width: 80, height: 40)),
            (0, 2, CGRect(x: 196.5, y: 0, width: 80, height: 40)),
            (1, 0, CGRect(x: 0, y: 65, width: 80, height: 40)),
            (1, 1, CGRect(x: 90, y: 40, width: 80, height: 90)),
            (1, 2, CGRect(x: 180, y: 65, width: 80, height: 40)),
        ])
        XCTAssertEqual(mixed.contentSize.height, 130, accuracy: 0.001)
    }
}

// MARK: - 2. Reuse

/// Counts instances so reuse can be proven (mirrors TableViewTests).
private final class CountingItemCell: UICollectionViewCell {
    static var created = 0
    required init(frame: CGRect = .zero) {
        CountingItemCell.created += 1
        super.init(frame: frame)
    }
}

private final class BigGridSource: UICollectionViewDataSource {
    var items = 10_000
    func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }
    func collectionView(_ cv: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items
    }
    func collectionView(_ cv: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        cv.dequeueReusableCell(withReuseIdentifier: "item", for: indexPath)
    }
}

final class CollectionViewReuseTests: XCTestCase {
    override func setUp() {
        super.setUp()
        TextTestSupport.configureResourceRoot()
        CountingItemCell.created = 0
    }

    /// The reuse gate: sweeping a 10k-item grid end to end must never
    /// instantiate more than roughly one screenful of cells.
    func testTenThousandItemScrollInstantiatesOnlyVisibleCells() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 100, height: 100)
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.sectionInset = .zero
        let cv = UICollectionView(frame: CGRect(x: 0, y: 0, width: 375, height: 600),
                                  collectionViewLayout: layout)
        cv.register(CountingItemCell.self, forCellWithReuseIdentifier: "item")
        let source = BigGridSource()
        cv.dataSource = source
        cv.layoutIfNeeded()

        // 3 items per line, 10_000 items -> 3334 lines of 110 pt (the last
        // line has no trailing gap).
        let lines = 3334
        XCTAssertEqual(cv.contentSize.height,
                       CGFloat(lines) * 100 + CGFloat(lines - 1) * 10, accuracy: 0.001)

        // Fully visible lines + the two partial ones at the edges, 3 wide.
        let maxVisible = (Int((600 / 110.0).rounded(.up)) + 1) * 3
        XCTAssertLessThanOrEqual(cv.visibleCells.count, maxVisible)
        XCTAssertGreaterThan(cv.visibleCells.count, 0)

        let maxOffset = cv.contentSize.height - 600
        var y: CGFloat = 0
        while y < maxOffset {
            cv.contentOffset = CGPoint(x: 0, y: y)
            XCTAssertLessThanOrEqual(cv.visibleCells.count, maxVisible)
            y += 600
        }
        for step in 0..<200 {
            cv.contentOffset = CGPoint(x: 0, y: CGFloat(step) * 27.5)
        }
        XCTAssertLessThanOrEqual(
            CountingItemCell.created, maxVisible + 3,
            "reuse failed: \(CountingItemCell.created) cells created for a \(maxVisible)-cell viewport")
    }

    func testDequeueRecyclesAndPreparesForReuse() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 100, height: 100)
        let cv = UICollectionView(frame: CGRect(x: 0, y: 0, width: 375, height: 200),
                                  collectionViewLayout: layout)
        cv.register(CountingItemCell.self, forCellWithReuseIdentifier: "item")
        let source = BigGridSource()
        cv.dataSource = source
        cv.layoutIfNeeded()

        guard let first = cv.cellForItem(at: IndexPath(item: 0, section: 0)) else {
            return XCTFail("item 0 not tiled")
        }
        first.isSelected = true
        cv.contentOffset = CGPoint(x: 0, y: 4000)
        XCTAssertNil(cv.cellForItem(at: IndexPath(item: 0, section: 0)))
        XCTAssertTrue(cv.visibleCells.contains { $0 === first },
                      "expected the retired cell to be reused for an incoming item")
        XCTAssertFalse(first.isSelected, "prepareForReuse must clear selection")
    }

    /// Headers and footers registered under the SAME identifier keep
    /// separate pools (the reason the registry is per kind).
    func testSupplementaryPoolsAreKeyedByKind() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 100, height: 40)
        layout.headerReferenceSize = CGSize(width: 0, height: 30)
        layout.footerReferenceSize = CGSize(width: 0, height: 20)
        let cv = UICollectionView(frame: CGRect(x: 0, y: 0, width: 375, height: 300),
                                  collectionViewLayout: layout)
        cv.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "c")
        cv.register(HeaderView.self,
                    forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                    withReuseIdentifier: "s")
        cv.register(FooterView.self,
                    forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                    withReuseIdentifier: "s")
        let src = FlowSource([1, 1, 1, 1, 1, 1, 1, 1])
        keptSources.append(src)
        cv.dataSource = src
        cv.delegate = src
        cv.layoutIfNeeded()
        cv.contentOffset = CGPoint(x: 0, y: 400)
        cv.contentOffset = .zero
        let header = cv.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader,
                                          at: IndexPath(item: 0, section: 0))
        let footer = cv.supplementaryView(forElementKind: UICollectionView.elementKindSectionFooter,
                                          at: IndexPath(item: 0, section: 0))
        XCTAssertTrue(header is HeaderView)
        XCTAssertTrue(footer is FooterView)
    }
}

private final class HeaderView: UICollectionReusableView {
    required init(frame: CGRect = .zero) { super.init(frame: frame) }
}
private final class FooterView: UICollectionReusableView {
    required init(frame: CGRect = .zero) { super.init(frame: frame) }
}

// MARK: - 3. Behaviour

private final class RecordingDelegate: UICollectionViewDelegate {
    var selected: [IndexPath] = []
    var deselected: [IndexPath] = []
    var displayed: [IndexPath] = []
    func collectionView(_ cv: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selected.append(indexPath)
    }
    func collectionView(_ cv: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        deselected.append(indexPath)
    }
    func collectionView(_ cv: UICollectionView, willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        displayed.append(indexPath)
    }
}

final class CollectionViewBehaviourTests: XCTestCase {
    override func setUp() {
        super.setUp()
        TextTestSupport.configureResourceRoot()
    }

    func testTilingCreatesOnlyVisibleElementsAndTracksIndexPaths() {
        let (cv, _) = makeCollection(width: 375, height: 200, counts: [4, 4]) { l in
            l.itemSize = CGSize(width: 100, height: 100)
            l.headerReferenceSize = CGSize(width: 0, height: 30)
        }
        XCTAssertEqual(cv.numberOfSections, 2)
        XCTAssertEqual(cv.numberOfItems(inSection: 1), 4)
        XCTAssertNotNil(cv.supplementaryView(
            forElementKind: UICollectionView.elementKindSectionHeader,
            at: IndexPath(item: 0, section: 0)))
        XCTAssertNil(cv.supplementaryView(
            forElementKind: UICollectionView.elementKindSectionHeader,
            at: IndexPath(item: 0, section: 1)),
            "section 1's header is below the viewport and must not be built")
        guard let cell = cv.cellForItem(at: IndexPath(item: 1, section: 0)) else {
            return XCTFail("item [0,1] not tiled")
        }
        XCTAssertEqual(cv.indexPath(for: cell), IndexPath(item: 1, section: 0))
        XCTAssertEqual(cv.indexPathForItem(at: CGPoint(x: 10, y: 40)),
                       IndexPath(item: 0, section: 0))
        XCTAssertNil(cv.indexPathForItem(at: CGPoint(x: 10, y: 5)),
                     "the header area holds no item")
    }

    func testTapSelectsAndFiresDelegate() {
        let (cv, _) = makeCollection(width: 375, height: 400, counts: [6]) { l in
            l.itemSize = CGSize(width: 100, height: 100)
        }
        let recorder = RecordingDelegate()
        cv.delegate = recorder
        cv.layoutIfNeeded()

        guard let a = cv.cellForItem(at: IndexPath(item: 0, section: 0)),
              let b = cv.cellForItem(at: IndexPath(item: 1, section: 0)) else {
            return XCTFail("cells not tiled")
        }
        a.touchesBegan([], with: nil)
        XCTAssertTrue(a.isHighlighted)
        a.touchesEnded([], with: nil)
        XCTAssertTrue(a.isSelected)
        XCTAssertEqual(recorder.selected, [IndexPath(item: 0, section: 0)])
        XCTAssertEqual(cv.indexPathsForSelectedItems, [IndexPath(item: 0, section: 0)])

        b.touchesBegan([], with: nil)
        b.touchesEnded([], with: nil)
        XCTAssertFalse(a.isSelected, "single selection must clear the previous cell")
        XCTAssertEqual(recorder.deselected, [IndexPath(item: 0, section: 0)])
        XCTAssertEqual(cv.indexPathsForSelectedItems, [IndexPath(item: 1, section: 0)])

        cv.deselectItem(at: IndexPath(item: 1, section: 0), animated: false)
        XCTAssertNil(cv.indexPathsForSelectedItems)
        XCTAssertFalse(b.isSelected)
    }

    func testMultipleSelectionTogglesOnTap() {
        let (cv, _) = makeCollection(width: 375, height: 400, counts: [6]) { l in
            l.itemSize = CGSize(width: 100, height: 100)
        }
        cv.allowsMultipleSelection = true
        guard let a = cv.cellForItem(at: IndexPath(item: 0, section: 0)),
              let b = cv.cellForItem(at: IndexPath(item: 1, section: 0)) else {
            return XCTFail("cells not tiled")
        }
        for cell in [a, b] {
            cell.touchesBegan([], with: nil)
            cell.touchesEnded([], with: nil)
        }
        XCTAssertEqual(cv.indexPathsForSelectedItems?.count, 2)
        a.touchesBegan([], with: nil)
        a.touchesEnded([], with: nil)
        XCTAssertEqual(cv.indexPathsForSelectedItems, [IndexPath(item: 1, section: 0)])
    }

    /// Selection survives recycling: a selected cell scrolled away and back
    /// comes back selected (the collection re-applies it on tiling).
    func testSelectionSurvivesRecycling() {
        let (cv, _) = makeCollection(width: 375, height: 200, counts: [60]) { l in
            l.itemSize = CGSize(width: 100, height: 100)
        }
        cv.selectItem(at: IndexPath(item: 0, section: 0), animated: false)
        cv.contentOffset = CGPoint(x: 0, y: 1500)
        cv.contentOffset = .zero
        XCTAssertEqual(cv.cellForItem(at: IndexPath(item: 0, section: 0))?.isSelected, true)
    }

    func testPerformBatchUpdatesAppliesTheNewData() {
        let (cv, src) = makeCollection(width: 375, height: 400, counts: [4]) { l in
            l.itemSize = CGSize(width: 100, height: 100)
        }
        XCTAssertEqual(cv.numberOfItems(inSection: 0), 4)
        var finished = false
        cv.performBatchUpdates({ src.counts = [9] }, completion: { finished = $0 })
        XCTAssertTrue(finished)
        XCTAssertEqual(cv.numberOfItems(inSection: 0), 9)
        XCTAssertEqual(cv.contentSize.height, 3 * 100 + 2 * 10, accuracy: 0.001)
    }

    /// A width change relayouts; scrolling alone does not.
    func testBoundsWidthChangeInvalidatesTheLayout() {
        let (cv, _) = makeCollection(width: 375, height: 300, counts: [6]) { l in
            l.itemSize = CGSize(width: 100, height: 100)
            l.sectionInset = .zero
        }
        XCTAssertEqual(cv.layoutAttributesForItem(at: IndexPath(item: 3, section: 0))?.frame.minY,
                       110)
        cv.frame = CGRect(x: 0, y: 0, width: 220, height: 300)
        cv.layoutIfNeeded()
        // 220 pt fits only two 100 pt items per line, so six items now need
        // three lines instead of two.
        XCTAssertEqual(cv.layoutAttributesForItem(at: IndexPath(item: 2, section: 0))?.frame.minY,
                       110)
        XCTAssertEqual(cv.layoutAttributesForItem(at: IndexPath(item: 4, section: 0))?.frame.minY,
                       220)
        XCTAssertEqual(cv.contentSize.height, 3 * 100 + 2 * 10, accuracy: 0.001)
    }

    func testScrollToItemBringsItIntoView() {
        let (cv, _) = makeCollection(width: 375, height: 200, counts: [60]) { l in
            l.itemSize = CGSize(width: 100, height: 100)
        }
        cv.scrollToItem(at: IndexPath(item: 30, section: 0), at: .top, animated: false)
        let frame = cv.layoutAttributesForItem(at: IndexPath(item: 30, section: 0))!.frame
        XCTAssertEqual(cv.contentOffset.y, frame.minY, accuracy: 0.001)
        XCTAssertNotNil(cv.cellForItem(at: IndexPath(item: 30, section: 0)))
    }
}
