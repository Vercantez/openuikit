import XCTest
@testable import OpenUIKit

/// A storyboard collection view controller (NetNewsWire's feed list shape:
/// fixtures/splitstoryboard/Base.lproj/Collection.storyboard, ibtool, archives the same
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

    private final class OneItemSource: NSObject, UICollectionViewDataSource {
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { 1 }
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            collectionView.dequeueReusableCell(withReuseIdentifier: "FeedCell", for: indexPath)
        }
    }

    /// The prototype's archived content view (`UIContentView`) is the cell's
    /// own contentView, so its constraints size the row: 20.33 (the body
    /// label) + 15 + 15 = 50.33, as NetNewsWire's feed rows measure on iOS
    /// 26.1. The storyboard lives in Base.lproj, so IB archives its text as
    /// NSLocalizableString (the controller title "Feeds").
    func testPrototypeContentViewIsBoundAndSelfSizesAListRow() throws {
        let fixtures = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("fixtures/splitstoryboard").path
        let saved = OpenUIKitRuntime.nibSearchPaths
        let savedCut = OpenUIKitRuntime.systemFontCut
        OpenUIKitRuntime.nibSearchPaths = [fixtures]
        OpenUIKitRuntime.systemFontCut = .iOS
        let savedBounds = UIScreen.main.bounds, savedScale = UIScreen.main.scale
        UIScreen.main._hostConfigure(bounds: CGRect(x: 0, y: 0, width: 393, height: 852), scale: 3)
        let savedTraits = UITraitCollection.current
        UITraitCollection.current = UITraitCollection(userInterfaceStyle: .light, displayScale: 3,
                                                      preferredContentSizeCategory: .large,
                                                      userInterfaceIdiom: .phone)
        defer {
            UITraitCollection.current = savedTraits
            OpenUIKitRuntime.nibSearchPaths = saved; OpenUIKitRuntime.systemFontCut = savedCut
            UIScreen.main._hostConfigure(bounds: savedBounds, scale: savedScale)
        }
        let controller = try XCTUnwrap(UIStoryboard(name: "Collection", bundle: nil)
            .instantiateInitialViewController() as? UICollectionViewController)
        XCTAssertEqual(controller.title, "Feeds", "NSLocalizableString decodes to its text")
        let collection = try XCTUnwrap(controller.collectionView)
        let cell = collection.dequeueReusableCell(withReuseIdentifier: "FeedCell",
                                                  for: IndexPath(item: 0, section: 0))
        let label = try XCTUnwrap(cell.contentView.subviews.compactMap { $0 as? UILabel }.first)
        XCTAssertEqual(label.text, "Feed Title")

        let source = OneItemSource()
        collection.dataSource = source
        collection.setCollectionViewLayout(UICollectionViewCompositionalLayout.list(
            using: .init(appearance: .insetGrouped)), animated: false)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        collection.layoutIfNeeded()
        collection.layoutIfNeeded()
        let row = try XCTUnwrap(collection.cellForItem(at: IndexPath(item: 0, section: 0)))
        XCTAssertEqual(row.frame.height, 50.333, accuracy: 0.01)
        withExtendedLifetime(source) {}
    }
}
