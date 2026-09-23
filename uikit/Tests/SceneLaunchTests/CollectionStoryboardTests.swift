import XCTest
@testable import OpenUIKit

/// A storyboard collection view controller (NetNewsWire's feed list shape:
/// fixtures/splitstoryboard/Collection.storyboard, ibtool, archives the same
/// keys as NetNewsWire's Main.storyboard scene 6Bn-mF-MPS). Before this:
/// `UICollectionView` had no nib constructor ("class:UICollectionView"),
/// UICollectionViewController.init(coder:) dropped the coder (no nib name,
/// so loadView built a blank programmatic collection), and the prototype
/// cell / section-header nib dictionaries were not registered.
@MainActor
final class CollectionStoryboardTests: XCTestCase {
    func testStoryboardCollectionControllerUsesTheArchivedCollectionAndPrototypes() throws {
        let fixtures = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("fixtures/splitstoryboard").path
        let saved = OpenUIKitRuntime.nibSearchPaths
        OpenUIKitRuntime.nibSearchPaths = [fixtures]
        defer { OpenUIKitRuntime.nibSearchPaths = saved }
        let controller = try XCTUnwrap(UIStoryboard(name: "Collection", bundle: nil)
            .instantiateInitialViewController() as? UICollectionViewController)
        XCTAssertNotNil(controller.nibName, "the coder's scene view nib is kept")
        let collection = try XCTUnwrap(controller.collectionView)
        XCTAssertTrue(controller.view === collection, "the archived collection is the root view")
        let flow = try XCTUnwrap(collection.collectionViewLayout as? UICollectionViewFlowLayout)
        XCTAssertEqual(flow.itemSize, CGSize(width: 430, height: 54))
        XCTAssertEqual(flow.headerReferenceSize, CGSize(width: 50, height: 60))
        XCTAssertEqual(flow.sectionInset, UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
        let path = IndexPath(item: 0, section: 0)
        let cell = collection.dequeueReusableCell(withReuseIdentifier: "FeedCell", for: path)
        XCTAssertEqual(cell.reuseIdentifier, "FeedCell")
        let header = collection.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Container", for: path)
        XCTAssertEqual(header.reuseIdentifier, "Container")
    }
}
