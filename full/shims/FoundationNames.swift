// FoundationNames.swift -- the Foundation value names OpenUIKit needs when
// Foundation itself is deliberately invisible to the Mach-O library build.
//
// PROVENANCE: the NSRange, IndexPath, and TimeInterval declarations below are
// OpenUIKit's OWN code, lifted verbatim from the commit that deleted them.
// `~/uikit` is not edited; this file restores what M15 removed. IndexSet is a
// new, project-owned, Foundation-free value implementation of the public Swift
// collection/set semantics documented below; it is not copied from Apple or
// swift-corelibs.
//
//   NSRange, NSRangePointer, NSMakeRange   <- ec1d318^:Sources/OpenUIKit/NSAttributedString.swift
//   IndexPath                              <- ec1d318^:Sources/OpenUIKit/UITableView.swift
//   IndexPath.init(item:section:), .item   <- ec1d318^:Sources/OpenUIKit/UICollectionView.swift
//   TimeInterval                           <- ec1d318^:Sources/OpenUIKit/UITouch.swift
//   IndexSet                               <- added for OpenUIKit 064c774's
//                                             UITableView section APIs
//
// WHY THIS FILE EXISTS. Sources/OpenUIKit/FoundationTypes.swift declares these
// as typealiases to Foundation's inside `#if canImport(Foundation)`. The staged
// Darwin sysroot has no Foundation.swiftmodule, so that condition is false;
// only the file's separate Bundle fallback compiles, and these value names are
// undefined. Every other
// Foundation-conditional site in the library already has a working `#else`
// freestanding branch -- this was the one hole, and M15's own commit message
// says why it is only a hole and not a dependency: "IndexPath, NSRange /
// NSRangePointer / NSMakeRange and TimeInterval were declared by OpenUIKit
// only because the library imported no Foundation."
//
// So this is not an attempt to recreate Foundation. The pre-M15 names are the
// library's previous definitions, restored under the same names, which is
// exactly what docs/UIKIT_SLICE.md §5 predicted the full module would need
// ("the IndexPath/NSRange/TimeInterval typealiases (3 lines)"). IndexSet is a
// deliberately value-only subset: sorted integer storage,
// BidirectionalCollection, SetAlgebra, half-open/closed range construction, and
// neighbour/range queries. Objective-C
// bridging, NSIndexSet, coding, and Foundation's range-view API remain outside
// this Foundation-free layer. Native builds that can import Foundation still
// use Foundation.IndexSet through OpenUIKit/FoundationTypes.swift instead.

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

// MARK: - IndexSet

/// A Foundation-free integer set for UIKit APIs that traffic in section
/// indexes. It follows Swift's SetAlgebra contract and Foundation.IndexSet's
/// ascending iteration and nonnegative index domain for the operations here.
/// Apple's macOS 26.1 Foundation overlay reports duplicate `insert` as newly
/// inserted; this fallback deliberately returns the SetAlgebra-mandated
/// `inserted == false` instead of preserving that measured overlay bug.
///
/// The representation is intentionally straightforward: section sets are
/// normally small, and sorted unique storage makes iteration deterministic.
/// Unlike Foundation's range-compressed representation, constructing a very
/// large contiguous range consumes memory proportional to its element count.
public struct IndexSet: Hashable, Sendable, BidirectionalCollection, SetAlgebra {
    public typealias Element = Int

    /// An opaque collection position, as in Foundation.IndexSet. It is not an
    /// integer element value: `set[2]` therefore does not become fallback-only
    /// source that fails when compiled against Foundation on iOS.
    public struct Index: Comparable, Sendable, CustomStringConvertible {
        fileprivate let offset: Int

        public static func < (lhs: Index, rhs: Index) -> Bool {
            lhs.offset < rhs.offset
        }

        public var description: String { String(offset) }
    }

    private var values: [Int]

    public init() {
        values = []
    }

    public init(integer: Int) {
        Self.requireValid(integer)
        values = [integer]
    }

    public init(integersIn range: Range<Int>) {
        Self.requireValid(range)
        values = Array(range)
    }

    public init(integersIn range: ClosedRange<Int>) {
        self.init(integersIn: Self.halfOpen(range))
    }

    public init(arrayLiteral elements: Int...) {
        values = []
        for element in elements {
            _ = insert(element)
        }
    }

    public var startIndex: Index { Index(offset: values.startIndex) }
    public var endIndex: Index { Index(offset: values.endIndex) }
    public var isEmpty: Bool { values.isEmpty }

    public subscript(position: Index) -> Int {
        values[position.offset]
    }

    public func index(after i: Index) -> Index {
        Index(offset: values.index(after: i.offset))
    }

    public func index(before i: Index) -> Index {
        Index(offset: values.index(before: i.offset))
    }

    public func index(_ i: Index, offsetBy distance: Int) -> Index {
        Index(offset: values.index(i.offset, offsetBy: distance))
    }

    public func distance(from start: Index, to end: Index) -> Int {
        values.distance(from: start.offset, to: end.offset)
    }

    public func contains(_ integer: Int) -> Bool {
        let i = insertionIndex(for: integer)
        return i < values.count && values[i] == integer
    }

    @discardableResult
    public mutating func insert(_ integer: Int) -> (inserted: Bool, memberAfterInsert: Int) {
        Self.requireValid(integer)
        let i = insertionIndex(for: integer)
        if i < values.count, values[i] == integer {
            return (false, values[i])
        }
        values.insert(integer, at: i)
        return (true, integer)
    }

    @discardableResult
    public mutating func update(with integer: Int) -> Int? {
        let result = insert(integer)
        return result.inserted ? nil : result.memberAfterInsert
    }

    @discardableResult
    public mutating func remove(_ integer: Int) -> Int? {
        let i = insertionIndex(for: integer)
        guard i < values.count, values[i] == integer else { return nil }
        return values.remove(at: i)
    }

    public func union(_ other: IndexSet) -> IndexSet {
        var result = self
        result.formUnion(other)
        return result
    }

    public mutating func formUnion(_ other: IndexSet) {
        for integer in other.values {
            _ = insert(integer)
        }
    }

    public func intersection(_ other: IndexSet) -> IndexSet {
        var result = self
        result.formIntersection(other)
        return result
    }

    public mutating func formIntersection(_ other: IndexSet) {
        values = values.filter { other.contains($0) }
    }

    public func symmetricDifference(_ other: IndexSet) -> IndexSet {
        var result = self
        result.formSymmetricDifference(other)
        return result
    }

    public mutating func formSymmetricDifference(_ other: IndexSet) {
        for integer in other.values {
            if remove(integer) == nil {
                _ = insert(integer)
            }
        }
    }

    public func integerGreaterThan(_ integer: Int) -> Int? {
        let i = insertionIndex(for: integer)
        if i < values.count, values[i] == integer {
            let next = i + 1
            return next < values.count ? values[next] : nil
        }
        return i < values.count ? values[i] : nil
    }

    public func integerLessThan(_ integer: Int) -> Int? {
        let i = insertionIndex(for: integer)
        return i > 0 ? values[i - 1] : nil
    }

    public func integerGreaterThanOrEqualTo(_ integer: Int) -> Int? {
        let i = insertionIndex(for: integer)
        return i < values.count ? values[i] : nil
    }

    public func integerLessThanOrEqualTo(_ integer: Int) -> Int? {
        let i = insertionIndex(for: integer)
        if i < values.count, values[i] == integer { return values[i] }
        return i > 0 ? values[i - 1] : nil
    }

    public func count(in range: Range<Int>) -> Int {
        Self.requireValid(range)
        let lower = insertionIndex(for: range.lowerBound)
        let upper = insertionIndex(for: range.upperBound)
        return upper - lower
    }

    public func count(in range: ClosedRange<Int>) -> Int {
        count(in: Self.halfOpen(range))
    }

    public func contains(integersIn range: Range<Int>) -> Bool {
        Self.requireValid(range)
        if range.isEmpty { return false }
        let lower = insertionIndex(for: range.lowerBound)
        let needed = range.count
        guard needed <= values.count - lower else { return false }
        for offset in 0..<needed where values[lower + offset] != range.lowerBound + offset {
            return false
        }
        return true
    }

    public func contains(integersIn range: ClosedRange<Int>) -> Bool {
        contains(integersIn: Self.halfOpen(range))
    }

    public func contains(integersIn other: IndexSet) -> Bool {
        other.values.allSatisfy(contains)
    }

    public func intersects(integersIn range: Range<Int>) -> Bool {
        Self.requireValid(range)
        guard !range.isEmpty else { return false }
        let i = insertionIndex(for: range.lowerBound)
        return i < values.count && values[i] < range.upperBound
    }

    public func intersects(integersIn range: ClosedRange<Int>) -> Bool {
        intersects(integersIn: Self.halfOpen(range))
    }

    public mutating func insert(integersIn range: Range<Int>) {
        Self.requireValid(range)
        formUnion(IndexSet(integersIn: range))
    }

    public mutating func insert(integersIn range: ClosedRange<Int>) {
        insert(integersIn: Self.halfOpen(range))
    }

    public mutating func remove(integersIn range: Range<Int>) {
        Self.requireValid(range)
        guard !range.isEmpty else { return }
        values.removeAll { range.contains($0) }
    }

    public mutating func remove(integersIn range: ClosedRange<Int>) {
        remove(integersIn: Self.halfOpen(range))
    }

    public func filteredIndexSet(
        in range: Range<Int>,
        includeInteger: (Int) throws -> Bool
    ) rethrows -> IndexSet {
        Self.requireValid(range)
        var result = IndexSet()
        for integer in values where range.contains(integer) {
            if try includeInteger(integer) {
                _ = result.insert(integer)
            }
        }
        return result
    }

    public func filteredIndexSet(
        in range: ClosedRange<Int>,
        includeInteger: (Int) throws -> Bool
    ) rethrows -> IndexSet {
        try filteredIndexSet(in: Self.halfOpen(range), includeInteger: includeInteger)
    }

    public func filteredIndexSet(
        includeInteger: (Int) throws -> Bool
    ) rethrows -> IndexSet {
        var result = IndexSet()
        for integer in values where try includeInteger(integer) {
            _ = result.insert(integer)
        }
        return result
    }

    private static func requireValid(_ integer: Int) {
        precondition(integer >= 0 && integer < Int.max,
                     "IndexSet integers must be in 0..<Int.max")
    }

    private static func requireValid(_ range: Range<Int>) {
        precondition(range.lowerBound >= 0 && range.upperBound <= Int.max,
                     "IndexSet ranges must lie within 0..<Int.max")
    }

    private static func halfOpen(_ range: ClosedRange<Int>) -> Range<Int> {
        precondition(range.lowerBound >= 0 && range.upperBound < Int.max,
                     "IndexSet ranges must lie within 0..<Int.max")
        return range.lowerBound..<(range.upperBound + 1)
    }

    private func insertionIndex(for integer: Int) -> Int {
        var low = 0
        var high = values.count
        while low < high {
            let middle = low + (high - low) / 2
            if values[middle] < integer {
                low = middle + 1
            } else {
                high = middle
            }
        }
        return low
    }
}

// NSCoder is deliberately NOT here. It is declared by OpenUIKit's own
// FoundationTypes.swift fallback because UIView's required initializer needs
// one stable identity while Foundation is hidden. The app-only
// full/appshim/Foundation.swift module aliases that same OpenUIKit.NSCoder; it
// does not introduce a rival declaration or put Foundation on the library
// search path.

// MARK: - Time

public typealias TimeInterval = Double
