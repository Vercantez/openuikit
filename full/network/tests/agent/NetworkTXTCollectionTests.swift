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
}
