// FoundationNames.swift -- the four names OpenUIKit gets from Foundation.
//
// PROVENANCE: every declaration below is OpenUIKit's OWN code, lifted verbatim
// from the commit that deleted it. `~/uikit` is not edited; this file only
// restores what M15 removed.
//
//   NSRange, NSRangePointer, NSMakeRange   <- ec1d318^:Sources/OpenUIKit/NSAttributedString.swift
//   IndexPath                              <- ec1d318^:Sources/OpenUIKit/UITableView.swift
//   IndexPath.init(item:section:), .item   <- ec1d318^:Sources/OpenUIKit/UICollectionView.swift
//   TimeInterval                           <- ec1d318^:Sources/OpenUIKit/UITouch.swift
//
// WHY THIS FILE EXISTS. Sources/OpenUIKit/FoundationTypes.swift declares these
// four as typealiases to Foundation's, and its ENTIRE body sits inside
// `#if canImport(Foundation)`. The staged Darwin sysroot has no
// Foundation.swiftmodule, so `canImport(Foundation)` is false, that file
// compiles to nothing, and the names are simply undefined. Every other
// Foundation-conditional site in the library already has a working `#else`
// freestanding branch -- this was the one hole, and M15's own commit message
// says why it is only a hole and not a dependency: "IndexPath, NSRange /
// NSRangePointer / NSMakeRange and TimeInterval were declared by OpenUIKit
// only because the library imported no Foundation."
//
// So this is not a reimplementation of Foundation and it is not a stub. It is
// the library's previous definitions, restored under the same names, which is
// exactly what docs/UIKIT_SLICE.md §5 predicted the full module would need
// ("the IndexPath/NSRange/TimeInterval typealiases (3 lines)").

// MARK: - NSRange

public struct NSRange: Equatable, Hashable, Sendable {
    public var location: Int
    public var length: Int
    public init(location: Int, length: Int) {
        self.location = location
        self.length = length
    }
    public init() { self.init(location: 0, length: 0) }
    public var upperBound: Int { location + length }
    public var lowerBound: Int { location }
    public func contains(_ i: Int) -> Bool { i >= location && i < location + length }
    /// Foundation's "not found" sentinel.
    public static let notFound = NSRange(location: Int.max, length: 0)
}

public typealias NSRangePointer = UnsafeMutablePointer<NSRange>

public func NSMakeRange(_ loc: Int, _ len: Int) -> NSRange {
    NSRange(location: loc, length: len)
}

// MARK: - IndexPath

public struct IndexPath: Hashable, Comparable, Sendable {
    public var section: Int
    public var row: Int
    public init(row: Int, section: Int) {
        self.row = row
        self.section = section
    }
    public static func < (a: IndexPath, b: IndexPath) -> Bool {
        (a.section, a.row) < (b.section, b.row)
    }
}

public extension IndexPath {
    /// UIKit spells a collection view's index paths `item`/`section` and a
    /// table's `row`/`section`; both are the same storage.
    init(item: Int, section: Int) {
        self.init(row: item, section: section)
    }
    var item: Int {
        get { row }
        set { row = newValue }
    }
}

// NSCoder is deliberately NOT here. The app path needs it, the render path
// never does, and it is supplied by full/appshim/Foundation.swift on the
// app-only include path -- because that is where a real app gets it (real
// UIKit re-exports Foundation). Declaring it in both places is ambiguous, and
// the compiler says so.

// MARK: - Time

public typealias TimeInterval = Double
