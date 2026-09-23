import XCTest
@testable import OpenUIKit

/// A list layout's configuration belongs to that layout object only. It was
/// boxed by ObjectIdentifier (an address), so a plain compositional layout
/// allocated where a freed list layout lived inherited its list configuration
/// and laid out 52-pt list rows: CompositionalLayoutTests and
/// CollectionLayoutAnchorTests failed whenever they ran after
/// CellConfigurationLifecycleTests.
@MainActor
final class ListConfigurationIdentityTests: XCTestCase {
    func testAFreedListLayoutsConfigurationIsNotInheritedByANewLayout() {
        var freedAddresses: Set<ObjectIdentifier> = []
        for _ in 0..<20 {
            let list = UICollectionViewCompositionalLayout.list(
                using: .init(appearance: .insetGrouped))
            XCTAssertNotNil(list._storedListConfiguration)
            freedAddresses.insert(ObjectIdentifier(list))
        }
        var reused = 0
        for _ in 0..<200 {
            let item = OpenUIKit.NSCollectionLayoutItem(layoutSize: OpenUIKit.NSCollectionLayoutSize(
                widthDimension: OpenUIKit.NSCollectionLayoutDimension.fractionalWidth(1), heightDimension: OpenUIKit.NSCollectionLayoutDimension.absolute(44)))
            let group = OpenUIKit.NSCollectionLayoutGroup.vertical(layoutSize: OpenUIKit.NSCollectionLayoutSize(
                widthDimension: OpenUIKit.NSCollectionLayoutDimension.fractionalWidth(1), heightDimension: OpenUIKit.NSCollectionLayoutDimension.absolute(44)), subitems: [item])
            let plain = UICollectionViewCompositionalLayout(section: OpenUIKit.NSCollectionLayoutSection(group: group))
            if freedAddresses.contains(ObjectIdentifier(plain)) { reused += 1 }
            XCTAssertNil(plain._storedListConfiguration, "a plain layout has no list configuration")
        }
        // The allocator reuses freed addresses; without reuse the check above
        // proves nothing, so report it rather than pass vacuously.
        XCTAssertGreaterThan(reused, 0, "no freed list-layout address was reused")
    }
}
