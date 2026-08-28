// Foundation types UIKit vends, plus the UIKit-owned conveniences on them.
// Owner: app-compat cluster (M15 — docs/APP_COMPAT.md "Foundation coexistence").
//
// WHAT CHANGED, AND WHY
// ---------------------
// Until M15 OpenUIKit declared its OWN `IndexPath`, `NSRange`,
// `NSRangePointer` and `TimeInterval`, because the library imported no
// Foundation at all. docs/APP_COMPAT.md then measured what that cost: an app
// that imports BOTH OpenUIKit and Foundation — which every real app does,
// because its model layer is Foundation — saw two types of each name and the
// compiler refused to pick one.
//
// The collision was never missing API. It was duplicate NAMES. So the library
// imports Foundation here and re-exports Foundation's own types under the
// names UIKit uses; `Bundle` follows the same rule for UIViewController's nib
// API. `typealias` is what makes that work: unqualified lookup
// that finds a typealias AND the type it aliases resolves to ONE declaration,
// so `import Foundation` + `import OpenUIKit` in one file is unambiguous — and
// unlike the old shadowing, an `IndexPath` built by an app's model layer IS
// the one `tableView(_:cellForRowAt:)` receives.
//
// Aliasing rather than `@_exported import Foundation` is deliberate: it puts
// the names in OpenUIKit's namespace, so the other ~100 source files keep
// compiling without a per-file Foundation import, and OpenCoreGraphics'
// `CGAffineTransform` / `CGColor` never have to fight CoreGraphics' for the
// name on Darwin (docs/PORTABILITY.md).
//
// WHAT IS DELIBERATELY *NOT* ALIASED
// ----------------------------------
// Four families keep OpenUIKit's own implementation. Each has a measured
// reason, reproduced in docs/KNOWN_GAPS.md "Foundation coexistence":
//
//   * `CGAffineTransform` — Foundation has none on Linux, so there is no
//     collision to remove, and one shared implementation is what keeps the
//     Linux render byte-identical (its `init(rotationAngle:)` uses the
//     library's own series, not libm).
//   * `NSAttributedString` / `NSMutableAttributedString` — MEASURED: on
//     swift 6.2 Linux, `NSMutableAttributedString.addAttribute` TRAPS the
//     second time a plain Swift value is stored for a key, because run
//     coalescing calls `isEqual` on the boxed value. Every OpenUIKit
//     attribute value (UIFont, UIColor, CGFloat, NSParagraphStyle) is a plain
//     Swift value. Foundation's attributed string cannot hold UIKit's
//     attributes on the target platform.
//   * `Notification` / `NotificationCenter` — its selector form has to
//     dispatch through OpenUIKit's portable `SelectorDispatching`
//     (docs/OBJC_RUNTIME.md): Swift ObjC interop does not exist on Linux, so
//     corelibs-Foundation has no `addObserver(_:selector:name:object:)` at
//     all, and that spelling is the one real apps use most. Foundation's
//     block form also measurably diverges on Linux (an observer registered
//     with a non-NSObject `object:` filter never fires).
//   * `Timer` / `RunLoop` — they run on the SCRIPTED host clock
//     (`UIWindow.tick(timestamp:)`), not a wall clock. Foundation's run on
//     `Date`, which would put wall-clock time into the frame loop and end
//     byte-identical rendering. See Timer.swift.

#if canImport(Foundation)
import Foundation

#if canImport(AppKit)
// macOS ONLY, and only because of the oracle/dev platform: AppKit already
// extends Foundation's `IndexPath` with `init(item:section:)`, `.item` and
// `.section` — the same `[section, item]` storage UIKit uses — and XCTest
// drags AppKit into every test target. If OpenUIKit declared those three as
// well, every `indexPath.section` in a test would be ambiguous between two
// identical members. So on macOS we import AppKit's and declare only the
// `row` spelling it lacks; on Linux, where there is no AppKit, OpenUIKit
// declares all of them. Nothing else in the library touches AppKit.
import AppKit
#endif

// MARK: - IndexPath

/// Foundation's `IndexPath`. Real UIKit does not declare its own either — it
/// adds the two-component conveniences below to Foundation's type, which is
/// exactly what this extension does.
public typealias IndexPath = Foundation.IndexPath

extension IndexPath {
    /// Table-view index path, stored `[section, row]` like UIKit's.
    public init(row: Int, section: Int) { self.init(indexes: [section, row]) }
    /// The row component of a table-view index path — the same slot as
    /// `item`, exactly like UIKit.
    public var row: Int { count > 1 ? self[1] : 0 }

#if !canImport(AppKit)
    /// Collection-view index path, stored `[section, item]`.
    public init(item: Int, section: Int) { self.init(indexes: [section, item]) }

    /// The section component. UIKit traps on an index path too short to have
    /// one; reporting 0 keeps a malformed path from taking down a layout
    /// pass, and nothing in OpenUIKit produces one.
    public var section: Int { count > 0 ? self[0] : 0 }
    /// The item component of a collection-view index path.
    public var item: Int { count > 1 ? self[1] : 0 }
#endif
}

// MARK: - Ranges and time

/// Foundation's `NSRange`: `location`/`length` in UTF-16 code units, with
/// `upperBound`, `lowerBound` and `contains(_:)` already on it.
public typealias NSRange = Foundation.NSRange
public typealias NSRangePointer = Foundation.NSRangePointer

/// Foundation's `TimeInterval` (`Double`, seconds). OpenUIKit's clock is the
/// host tick timestamp, not a wall clock — the UNIT is all that is shared.
public typealias TimeInterval = Foundation.TimeInterval

// MARK: - Bundle

/// Foundation's resource bundle type. UIViewController's nib initializer
/// exposes it even when the controller is otherwise entirely programmatic.
public typealias Bundle = Foundation.Bundle

#else

/// Foundation-free renderer builds still compile the complete OpenUIKit
/// module. They cannot load resources or nibs, but they need the identity and
/// `main` spelling carried by UIViewController's public initializer surface.
/// A real application build compiles the branch above against Foundation.
public final class Bundle: @unchecked Sendable {
    public static let main = Bundle()
    private init() {}
}

#endif
