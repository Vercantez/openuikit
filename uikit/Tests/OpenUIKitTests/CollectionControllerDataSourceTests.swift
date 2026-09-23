import XCTest
@testable import OpenUIKit

/// MEASURED Tools/oracle2/cvcdatasourceprobe/transcript-ios26.1.txt: a bare
/// UICollectionViewController is its collection's data source and answers
/// one section of zero items. The port trapped instead ("subclasses must
/// implement"), which killed NetNewsWire's storyboard feed controller while
/// its view loaded.
@MainActor
final class CollectionControllerDataSourceTests: XCTestCase {
    func testBareControllerAnswersZeroItems() {
        let vc = UICollectionViewController(collectionViewLayout: UICollectionViewFlowLayout())
        let cv = vc.collectionView!
        XCTAssertTrue(cv.dataSource === vc)
        XCTAssertEqual(cv.numberOfSections, 1)
        XCTAssertEqual(cv.numberOfItems(inSection: 0), 0)
        XCTAssertEqual(vc.collectionView(cv, numberOfItemsInSection: 0), 0)
        cv.frame = CGRect(x: 0, y: 0, width: 300, height: 500)
        cv.layoutIfNeeded()
        XCTAssertEqual(cv.visibleCells.count, 0)
    }
}
