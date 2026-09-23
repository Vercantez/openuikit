import XCTest
@testable import OpenUIKit

/// Separators of an insetGrouped list of plain cells. MEASURED
/// Tools/oracle2/listseparatorprobe/transcript-ios26.1.txt (iPhone 16 /
/// iOS 26.1, two sections of four 50.33 pt rows): the separators are
/// `_UICollectionViewListSeparatorView`s, direct subviews of the collection
/// view above the cells, 1 pt tall, `separatorColor`.
///   * VARIANT=default: bottom separators on rows 0-2 of each section at the
///     cell's maxY - 1, [32, y, 329, 1] (16 in from both cell edges);
///   * VARIANT=nnw (NetNewsWire's itemSeparatorHandler): top separators on
///     rows 1-3 at the cell's minY, [64, y, 313, 1].
#if !os(Linux)
@MainActor
#endif
final class ListPlainSeparatorTests: XCTestCase {
    final class Row: UICollectionViewCell {
        let label = UILabel()
        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .secondarySystemGroupedBackground
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
        func numberOfSections(in collectionView: UICollectionView) -> Int { 2 }
        func collectionView(_ cv: UICollectionView, numberOfItemsInSection s: Int) -> Int { 4 }
        func collectionView(_ cv: UICollectionView, cellForItemAt ip: IndexPath) -> UICollectionViewCell {
            let c = cv.dequeueReusableCell(withReuseIdentifier: "row", for: ip) as! Row
            c.label.text = "Row \(ip.section).\(ip.item)"
            return c
        }
    }

    private func separators(nnwHandler: Bool) -> (UICollectionView, [UIView], Source) {
        var cfg = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        if nnwHandler {
            cfg.itemSeparatorHandler = { indexPath, section in
                var c = section
                c.bottomSeparatorVisibility = .hidden
                c.topSeparatorVisibility = indexPath.row == 0 ? .hidden : .visible
                c.topSeparatorInsets = NSDirectionalEdgeInsets(top: 0, leading: 48, bottom: 0, trailing: 0)
                return c
            }
        }
        let cv = UICollectionView(frame: CGRect(x: 0, y: 0, width: 393, height: 852),
                                  collectionViewLayout: UICollectionViewCompositionalLayout.list(using: cfg))
        cv.register(Row.self, forCellWithReuseIdentifier: "row")
        let source = Source()
        cv.dataSource = source
        cv.layoutIfNeeded()
        let seps = cv.subviews.filter { $0 is _UICollectionViewListSeparatorView }
            .sorted { $0.frame.minY < $1.frame.minY }
        return (cv, seps, source)
    }

    func testDefaultSeparatorsSitUnderEveryRowButTheLast() throws {
        let (cv, seps, source) = separators(nnwHandler: false)
        withExtendedLifetime(source) {}
        XCTAssertEqual(seps.count, 6)
        for section in 0..<2 {
            for item in 0..<3 {
                let cell = try XCTUnwrap(cv.cellForItem(at: IndexPath(item: item, section: section)))
                let sep = seps[section * 3 + item]
                XCTAssertEqual(sep.frame, CGRect(x: 32, y: cell.frame.maxY - 1, width: 329, height: 1))
                XCTAssertEqual(sep.backgroundColor, .separator)
                XCTAssertGreaterThan(cv.subviews.firstIndex(of: sep)!, cv.subviews.firstIndex(of: cell)!)
            }
        }
    }

    func testNetNewsWireHandlerDrawsTopSeparatorsFromTheSecondRow() throws {
        let (cv, seps, source) = separators(nnwHandler: true)
        withExtendedLifetime(source) {}
        XCTAssertEqual(seps.count, 6)
        for section in 0..<2 {
            for item in 1..<4 {
                let cell = try XCTUnwrap(cv.cellForItem(at: IndexPath(item: item, section: section)))
                let sep = seps[section * 3 + item - 1]
                XCTAssertEqual(sep.frame, CGRect(x: 64, y: cell.frame.minY, width: 313, height: 1))
            }
        }
    }
}
