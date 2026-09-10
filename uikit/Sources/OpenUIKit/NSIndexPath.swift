// NSIndexPath — Foundation's class plus UIKit's two-component conveniences.
// Owner: foundation-types module. Kept in its own file WITHOUT AppKit
// imported: FoundationTypes.swift imports AppKit on macOS, where AppKit's
// NSCollectionView category already declares `indexPathForItem:inSection:`,
// `item` and `section` on NSIndexPath. A module that imports OpenUIKit but
// not AppKit (the Catalyst apps, every test target) does not see that
// category's initializer, so the port declares it itself; declaring it in
// a file that also imports AppKit would collide with the category.
#if canImport(Foundation)
import Foundation

/// Foundation's `NSIndexPath` class. UIKit does not declare it either:
/// `NSIndexPath+UIKitAdditions.h` adds `indexPathForRow:inSection:`,
/// `indexPathForItem:inSection:`, `section`, `row` and `item` to
/// Foundation's class, which is what the extension below does. It lives
/// here, next to `IndexPath`, because the type is Foundation's; only the
/// two-component conveniences are UIKit's.
///
/// MEASURED (iOS 26.1, signallastrowsprobe `indexPath`): `NSIndexPath(item:
/// 3, section: 1)` has `length` 2, indexes [1, 3], `section` 1, `item` 3
/// and `row` 3 (same slot); `NSIndexPath(row: 4, section: 2)` reads `item`
/// 4; `as IndexPath` bridges to [section, item] with `count` 2 and equals
/// `IndexPath(item: 3, section: 1)`; the round trip back to `NSIndexPath`
/// keeps both components. Signal-iOS demand (2 uses): the two
/// initializers followed by `as IndexPath`.
public typealias NSIndexPath = Foundation.NSIndexPath

extension NSIndexPath {
    /// Table-view index path, stored `[section, row]` like UIKit's.
    public convenience init(row: Int, section: Int) {
        self.init(indexes: [section, row], length: 2)
    }
    /// The row component — the same slot as `item`, exactly like UIKit.
    public var row: Int { length > 1 ? index(atPosition: 1) : 0 }

    /// Collection-view index path, stored `[section, item]`. MEASURED
    /// (swift test, macOS 26.5 / Xcode 26.1): a test target importing only
    /// XCTest and OpenUIKit does NOT see AppKit's `indexPathForItem:inSection:`
    /// initializer ("incorrect argument label … expected 'row:section:'"),
    /// while it DOES see AppKit's `item` / `section` properties ("ambiguous
    /// use of 'item'" once the port declared them too). So the initializer
    /// is declared on every platform and the two properties only where
    /// AppKit is absent.
    public convenience init(item: Int, section: Int) {
        self.init(indexes: [section, item], length: 2)
    }
#if !canImport(AppKit)
    public var section: Int { length > 0 ? index(atPosition: 0) : 0 }
    public var item: Int { length > 1 ? index(atPosition: 1) : 0 }
#endif
}

#endif

