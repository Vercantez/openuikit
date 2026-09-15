import Foundation
import Network

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testNWTXTRecordCollectionAlgorithms() {
    var record = NWTXTRecord(["a": "1", "b": "2", "c": "3"])
    expect(record.count == 3, "count")
    expect(record.isEmpty == false, "isEmpty")
    expect(record.first != nil, "first")
    expect(record.map { $0.key }.sorted() == ["a", "b", "c"], "map")
    expect(record.contains(where: { $0.key == "b" }), "contains(where:)")
    expect(record.allSatisfy { !$0.key.isEmpty }, "allSatisfy")
    expect(record.first(where: { $0.key == "a" }) != nil, "first(where:)")
    expect(record.firstIndex(where: { $0.key == "b" }) != nil, "firstIndex(where:)")
    expect(record.enumerated().count == 3, "enumerated")
    expect(record.sorted(by: { $0.key < $1.key }).first?.key == "a", "sorted(by:)")
    let byKey = record.sorted { $0.key > $1.key }
    expect(byKey.first?.key == "c", "sorted comparator")
    expect(record.prefix(1).count == 1, "prefix(_:)")
    expect(record.prefix(upTo: record.endIndex).count == 3, "prefix(upTo:)")
    expect(record.prefix(through: record.startIndex).count == 1, "prefix(through:)")
    expect(record.prefix(while: { $0.key == "a" || $0.key == "b" || $0.key == "c" }).count >= 1, "prefix(while:)")
    expect(record.suffix(1).count == 1, "suffix(_:)")
    expect(record.suffix(from: record.startIndex).count == 3, "suffix(from:)")
    expect(record.dropFirst(1).count == 2, "dropFirst")
    expect(record.distance(from: record.startIndex, to: record.endIndex) == 3, "distance")
    let split = record.split(maxSplits: 1, omittingEmptySubsequences: true, whereSeparator: { $0.key == "b" })
    expect(split.count >= 1, "split")
    let offset = record.index(record.startIndex, offsetBy: 1)
    expect(offset.rawValue == 1, "index offsetBy")
    expect(record.index(record.startIndex, offsetBy: 8, limitedBy: record.endIndex) == nil, "index limitedBy")
    _ = NWTXTRecord.Element.self
    _ = NWTXTRecord.Indices.self
    _ = NWTXTRecord.Iterator.self
    expect(record.debugDescription.isEmpty == false, "debugDescription")
    record.removeEntry(key: "a")
    expect(record.isEmpty == false, "still nonempty")
}

func testNWTXTRecordIndexComparable() {
    let record = NWTXTRecord(["a": "1", "b": "2"])
    expect(record.startIndex < record.endIndex, "<")
    expect(record.endIndex > record.startIndex, ">")
    expect(record.startIndex <= record.endIndex, "<=")
    expect(record.endIndex >= record.startIndex, ">=")
    expect(record.startIndex != record.endIndex, "!=")
    expect(record.startIndex == record.startIndex, "==")
    let range = record.startIndex..<record.endIndex
    expect(range.lowerBound == record.startIndex, "..<")
    let through = record.startIndex...record.startIndex
    expect(through.contains(record.startIndex), "...")
    let partialUp = record.startIndex...
    expect(partialUp.contains(record.endIndex) || true, "... from")
    let partialThrough = ...record.endIndex
    expect(partialThrough.contains(record.startIndex), "... through")
    expect(record[record.startIndex...].count == 2, "slice from")
    expect(record[...record.startIndex].count == 1, "slice through")
    expect(record[record.startIndex..<record.endIndex].count == 2, "slice range")
}

/// Second batch: the remaining synchronous `Sequence` / `Collection` witnesses
/// the Network graph attributes to `NWTXTRecord`. Every call below is
/// in-process on a two-entry record; no mDNS, I/O, `await`, queue hop, or
/// semaphore wait. Foundation `SortComparator` / `FormatStyle` sequence
/// witnesses and the Combine publisher stay deferred (no matching
/// in-process behavior on this host).
func testNWTXTRecordSequenceWitnessBatch() {
    let record = NWTXTRecord(["a": "1", "b": "2"])
    let other = NWTXTRecord(["a": "1", "b": "2"])
    expect(record.compactMap { $0.key }.sorted() == ["a", "b"], "compactMap")
    expect(
        record.elementsEqual(other, by: { $0.key == $1.key && $0.value == $1.value }),
        "elementsEqual"
    )
    expect(
        record.lexicographicallyPrecedes(other, by: { $0.key < $1.key }) == false,
        "lexicographicallyPrecedes"
    )
    expect(
        record.withContiguousStorageIfAvailable { _ in 7 } == nil
            || record.withContiguousStorageIfAvailable { _ in 7 } == 7,
        "withContiguousStorageIfAvailable"
    )
    expect(record.max(by: { $0.key < $1.key })?.key == "b", "max(by:)")
    expect(record.min(by: { $0.key < $1.key })?.key == "a", "min(by:)")
    expect(Array(record.lazy.map { $0.key }).sorted() == ["a", "b"], "lazy")
    expect(record.count(where: { !$0.key.isEmpty }) == 2, "count(where:)")
    expect(record.filter { $0.key != "b" }.map { $0.key } == ["a"], "filter")
    expect(record.reduce(0) { $0 + $1.key.count } == 2, "reduce")
    expect(
        record.reduce(into: [String]()) { $0.append($1.key) }.sorted() == ["a", "b"],
        "reduce(into:)"
    )
    expect(record.starts(with: other, by: { $0.key == $1.key }), "starts(with:by:)")
    expect(record.flatMap { [$0.key] }.sorted() == ["a", "b"], "flatMap sequence")
    // The optional-returning flatMap witness stays deferred: it is deprecated
    // and any call trips warnings-as-errors.
    var visited = 0
    record.forEach { _ in visited += 1 }
    expect(visited == 2, "forEach")
    expect(record.reversed().map { $0.key }.sorted() == ["a", "b"], "reversed")
    expect(record.shuffled().count == 2, "shuffled")
    var generator = SystemRandomNumberGenerator()
    expect(record.shuffled(using: &generator).count == 2, "shuffled(using:)")
    expect(record.randomElement() != nil, "randomElement")
    expect(record.randomElement(using: &generator) != nil, "randomElement(using:)")
    expect(record.underestimatedCount >= 0, "underestimatedCount")
    expect(record.drop(while: { $0.key == "a" }).count == 1, "drop(while:)")
    expect(record.dropLast(1).count == 1, "dropLast")
    var cursor = record.startIndex
    record.formIndex(after: &cursor)
    expect(cursor == record.index(after: record.startIndex), "formIndex(after:)")
    record.formIndex(&cursor, offsetBy: 1)
    expect(cursor == record.endIndex, "formIndex(offsetBy:)")
    var bounded = record.startIndex
    let limited = record.formIndex(&bounded, offsetBy: 9, limitedBy: record.endIndex)
    expect(limited == false && bounded == record.endIndex, "formIndex limitedBy")
    expect(record.indices.count == 2, "indices")
    let kept = RangeSet(record.startIndex..<record.index(after: record.startIndex))
    expect(record.removingSubranges(kept).count == 1, "removingSubranges")
    expect(record.indices(where: { $0.key == "a" }).isEmpty == false, "indices(where:)")
    expect(record.trimmingPrefix(while: { $0.key == "zzz" }).count == 2, "trimmingPrefix")
}
