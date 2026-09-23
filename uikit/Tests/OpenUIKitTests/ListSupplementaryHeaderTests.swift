import XCTest
@testable import OpenUIKit

/// An insetGrouped list with supplementary section headers (NetNewsWire's
/// feed list). MEASURED Tools/oracle2/listheaderprobe/transcript-ios26.1.txt,
/// iPhone 16 / iOS 26.1, same classes as the probe.
@MainActor
final class ListSupplementaryHeaderTests: XCTestCase {
    final class Header: UICollectionReusableView {
        let label = UILabel()
        override init(frame: CGRect) {
            super.init(frame: frame)
            label.font = .preferredFont(forTextStyle: .headline)
            label.translatesAutoresizingMaskIntoConstraints = false
            addSubview(label)
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: topAnchor, constant: 8),
                bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 8),
                label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            ])
        }
        required init?(coder: NSCoder) { fatalError() }
    }

    final class Row: UICollectionViewCell {
        let label = UILabel()
        override init(frame: CGRect) {
            super.init(frame: frame)
            label.font = .preferredFont(forTextStyle: .body)
            label.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(label)
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15),
                contentView.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 15),
                label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 48),
            ])
        }
        required init?(coder: NSCoder) { fatalError() }
    }

    final class Source: NSObject, UICollectionViewDataSource {
        var cellBackgroundColor: UIColor?
        func numberOfSections(in collectionView: UICollectionView) -> Int { 2 }
        func collectionView(_ cv: UICollectionView, numberOfItemsInSection s: Int) -> Int { 3 }
        func collectionView(_ cv: UICollectionView, cellForItemAt ip: IndexPath) -> UICollectionViewCell {
            let c = cv.dequeueReusableCell(withReuseIdentifier: "row", for: ip) as! Row
            c.label.text = "Row \(ip.section).\(ip.item)"
            if let color = cellBackgroundColor { c.backgroundColor = color }
            return c
        }
        func collectionView(_ cv: UICollectionView, viewForSupplementaryElementOfKind kind: String,
                            at ip: IndexPath) -> UICollectionReusableView {
            let h = cv.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "hdr", for: ip) as! Header
            h.label.text = "Section \(ip.section)"
            return h
        }
    }

    /// Lays the probe's list out in a 393 x 852 @3x phone window and hands
    /// the collection view to `body`.
    private func withProbeList(cellBackgroundColor: UIColor? = nil,
                               _ body: (UICollectionView) throws -> Void) throws {
        let savedCut = OpenUIKitRuntime.systemFontCut
        let savedTraits = UITraitCollection.current
        let savedBounds = UIScreen.main.bounds, savedScale = UIScreen.main.scale
        OpenUIKitRuntime.systemFontCut = .iOS
        UIScreen.main._hostConfigure(bounds: CGRect(x: 0, y: 0, width: 393, height: 852), scale: 3)
        UITraitCollection.current = UITraitCollection(userInterfaceStyle: .light, displayScale: 3,
                                                      preferredContentSizeCategory: .large,
                                                      userInterfaceIdiom: .phone)
        defer {
            OpenUIKitRuntime.systemFontCut = savedCut
            UITraitCollection.current = savedTraits
            UIScreen.main._hostConfigure(bounds: savedBounds, scale: savedScale)
        }
        var cfg = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        cfg.headerMode = .supplementary
        let cv = UICollectionView(frame: CGRect(x: 0, y: 0, width: 393, height: 852),
                                  collectionViewLayout: UICollectionViewCompositionalLayout.list(using: cfg))
        cv.register(Row.self, forCellWithReuseIdentifier: "row")
        cv.register(Header.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                    withReuseIdentifier: "hdr")
        let source = Source()
        source.cellBackgroundColor = cellBackgroundColor
        cv.dataSource = source
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        window.addSubview(cv)
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        for _ in 0..<3 { cv.layoutIfNeeded() }
        try body(cv)
        withExtendedLifetime(source) {}
    }

    /// header0 [16, 0, 361, 36.33] (self-sized: 8 + 20.33 + 8), rows 50.33
    /// from y 36.33, header1 at y 205 (17.67 below the first section's last
    /// row at 187.33).
    func testHeadersSelfSizeAndSitAboveTheirRows() throws {
        try withProbeList { cv in
            let kind = UICollectionView.elementKindSectionHeader
            let h0 = try XCTUnwrap(cv.supplementaryView(forElementKind: kind, at: IndexPath(item: 0, section: 0)))
            let h1 = try XCTUnwrap(cv.supplementaryView(forElementKind: kind, at: IndexPath(item: 0, section: 1)))
            XCTAssertEqual(h0.frame.minY, 0, accuracy: 0.01)
            XCTAssertEqual(h0.frame.height, 36.333, accuracy: 0.01)
            let c00 = try XCTUnwrap(cv.cellForItem(at: IndexPath(item: 0, section: 0)))
            XCTAssertEqual(c00.frame.minY, 36.333, accuracy: 0.01)
            XCTAssertEqual(c00.frame.height, 50.333, accuracy: 0.01)
            let c02 = try XCTUnwrap(cv.cellForItem(at: IndexPath(item: 2, section: 0)))
            XCTAssertEqual(c02.frame.maxY, 187.333, accuracy: 0.01)
            XCTAssertEqual(h1.frame.minY, 205, accuracy: 0.01)
            XCTAssertEqual(h1.frame.height, 36.333, accuracy: 0.01)
            let c10 = try XCTUnwrap(cv.cellForItem(at: IndexPath(item: 0, section: 1)))
            XCTAssertEqual(c10.frame.minY, 241.333, accuracy: 0.01)
        }
    }

    /// CELL_BG=0 and CELL_BG=1 (the cell also sets its own backgroundColor,
    /// as NetNewsWire's FeedCell nib does) measure the same: UIKit rounds the
    /// plain cell itself. First row `cornerConfiguration` top pair
    /// `.fixed(26)` (layer maskedCorners 3), middle row `.unspecified` (0), last
    /// row bottom pair (12); every row clips to bounds; `layer.cornerRadius`
    /// stays 0.
    func testInsetGroupedPlainCellsRoundTheirSectionCorners() throws {
        for color in [nil, UIColor.secondarySystemGroupedBackground] {
            try withProbeList(cellBackgroundColor: color) { cv in
                let r: UICornerRadius = .fixed(26)
                let expected: [(UICornerConfiguration, UInt)] = [
                    (.corners(topLeftRadius: r, topRightRadius: r, bottomLeftRadius: nil, bottomRightRadius: nil), 3),
                    (.corners(topLeftRadius: nil, topRightRadius: nil, bottomLeftRadius: nil, bottomRightRadius: nil), 0),
                    (.corners(topLeftRadius: nil, topRightRadius: nil, bottomLeftRadius: r, bottomRightRadius: r), 12),
                ]
                for (item, (configuration, mask)) in expected.enumerated() {
                    let cell = try XCTUnwrap(cv.cellForItem(at: IndexPath(item: item, section: 0)))
                    let what = "row \(item), cell backgroundColor \(color == nil ? "nil" : "set")"
                    XCTAssertEqual(cell.cornerConfiguration, configuration, what)
                    XCTAssertTrue(cell.clipsToBounds, what)
                    XCTAssertEqual(cell.layer.cornerRadius, 0, what)
                    XCTAssertEqual(UInt(cell.layer.maskedCorners.rawValue), mask, what)
                }
            }
        }
    }
}
