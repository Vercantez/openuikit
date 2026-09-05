import PencilKit
import Foundation

func testPKStrokePathCollectionBasics() {
    let path = PKStrokePath(
        controlPoints: [pkMakePoint(0, 0), pkMakePoint(1, 1), pkMakePoint(2, 0)],
        creationDate: Date(timeIntervalSince1970: 0)
    )
    pkExpectEqual(path.count, 3, "count")
    pkExpect(!path.isEmpty, "not empty")
    pkExpectEqual(path.first?.location.x, 0, "first")
    pkExpectEqual(path.last?.location.x, 2, "last")
    pkExpectEqual(path.underestimatedCount, 3, "underestimated")
    var index = path.startIndex
    path.formIndex(after: &index)
    pkExpectEqual(index, 1, "form after")
    path.formIndex(before: &index)
    pkExpectEqual(index, 0, "form before")
    path.formIndex(&index, offsetBy: 2)
    pkExpectEqual(index, 2, "form offset")
    var limited = 0
    let moved = path.formIndex(&limited, offsetBy: 10, limitedBy: 2)
    pkExpect(!moved || limited <= 2, "limited")
    pkExpectEqual(path.index(0, offsetBy: 1, limitedBy: 2), 1, "index limited")
    let iterator = path.makeIterator()
    _ = iterator
}

func testPKStrokePathMapFilterReduce() {
    let path = PKStrokePath(
        controlPoints: [pkMakePoint(0, 0), pkMakePoint(2, 0), pkMakePoint(4, 0)],
        creationDate: Date(timeIntervalSince1970: 0)
    )
    let xs = path.map { $0.location.x }
    pkExpectEqual(xs, [0, 2, 4], "map")
    let filtered = path.filter { $0.location.x > 0 }
    pkExpectEqual(filtered.count, 2, "filter")
    let compact = path.compactMap { $0.location.x > 0 ? $0.location.x : nil }
    pkExpectEqual(compact, [2, 4], "compactMap")
    let flat = path.flatMap { [$0.location.x] }
    pkExpectEqual(flat, [0, 2, 4], "flatMap")
    let sum = path.reduce(0 as CGFloat) { $0 + $1.location.x }
    pkExpectEqual(sum, 6, "reduce")
    let into = path.reduce(into: 0 as CGFloat) { $0 += $1.location.x }
    pkExpectEqual(into, 6, "reduce into")
    pkExpect(path.allSatisfy { $0.opacity == 1 }, "allSatisfy")
    pkExpect(path.contains(where: { $0.location.x == 2 }), "contains")
    pkExpectEqual(path.count(where: { $0.location.x > 0 }), 2, "count where")
    var visits = 0
    path.forEach { _ in visits += 1 }
    pkExpectEqual(visits, 3, "forEach")
}

func testPKStrokePathPrefixSuffixDrop() {
    let path = PKStrokePath(
        controlPoints: [pkMakePoint(0, 0), pkMakePoint(1, 0), pkMakePoint(2, 0), pkMakePoint(3, 0)],
        creationDate: Date(timeIntervalSince1970: 0)
    )
    pkExpectEqual(path.prefix(2).count, 2, "prefix")
    pkExpectEqual(path.suffix(2).count, 2, "suffix")
    pkExpectEqual(path.dropFirst(1).count, 3, "dropFirst")
    pkExpectEqual(path.dropLast(1).count, 3, "dropLast")
    pkExpectEqual(path.prefix(upTo: 2).count, 2, "prefix upTo")
    pkExpectEqual(path.prefix(through: 1).count, 2, "prefix through")
    pkExpectEqual(path.suffix(from: 2).count, 2, "suffix from")
    pkExpectEqual(Array(path.drop(while: { $0.location.x < 2 })).count, 2, "drop while")
    pkExpectEqual(path.prefix(while: { $0.location.x < 2 }).count, 2, "prefix while")
    let split = path.split(maxSplits: 1, omittingEmptySubsequences: true, whereSeparator: { $0.location.x == 1 })
    pkExpect(split.count >= 1, "split")
}

func testPKStrokePathContainsAndFirstLast() {
    let path = PKStrokePath(
        controlPoints: [pkMakePoint(0, 0), pkMakePoint(5, 0), pkMakePoint(9, 0)],
        creationDate: Date(timeIntervalSince1970: 0)
    )
    pkExpectEqual(path.first(where: { $0.location.x > 0 })?.location.x, 5, "first where")
    pkExpectEqual(path.last(where: { $0.location.x < 9 })?.location.x, 5, "last where")
    pkExpectEqual(path.firstIndex(where: { $0.location.x == 5 }), 1, "firstIndex")
    pkExpectEqual(path.lastIndex(where: { $0.location.x == 5 }), 1, "lastIndex")
    let enumerated = Array(path.enumerated())
    pkExpectEqual(enumerated.count, 3, "enumerated")
    let reversed = Array(path.reversed())
    pkExpectEqual(reversed.first?.location.x, 9, "reversed")
    let sorted = path.sorted(by: { $0.location.x > $1.location.x })
    pkExpectEqual(sorted.first?.location.x, 9, "sorted")
    pkExpectEqual(path.max(by: { $0.location.x < $1.location.x })?.location.x, 9, "max")
    pkExpectEqual(path.min(by: { $0.location.x < $1.location.x })?.location.x, 0, "min")
    pkExpect(path.elementsEqual(path, by: { $0.location == $1.location }), "elementsEqual")
    pkExpect(path.starts(with: [pkMakePoint(0, 0)], by: { $0.location == $1.location }), "starts")
    _ = path.lazy
    _ = path.withContiguousStorageIfAvailable { $0.count }
}

func testPKStrokePathSliceIteration() {
    let path = PKStrokePath(
        controlPoints: [pkMakePoint(0, 0, time: 0), pkMakePoint(10, 0, time: 1)],
        creationDate: Date(timeIntervalSince1970: 0)
    )
    var parametric: [CGFloat] = []
    var slice = path.interpolatedPoints(in: 0...1, by: .parametricStep(0.5))
    while let point = slice.next() {
        parametric.append(point.location.x)
    }
    pkExpect(parametric.count >= 2, "parametric points \(parametric)")
    pkExpectEqual(parametric.first, 0, "start at 0")
    let distanceSlice = path.interpolatedPoints(by: .distance(5))
    let distancePoints = Array(distanceSlice)
    pkExpect(distancePoints.count >= 2, "distance slice")
    let timeSlice = path.interpolatedPoints(in: nil, by: .time(0.5))
    pkExpect(Array(timeSlice).count >= 2, "time slice")
    let copy = path.interpolatedPoints(in: 0...1, by: .parametricStep(1))
    _ = copy.makeIterator()
}

func testPKStrokePathSliceMapFilter() {
    let path = PKStrokePath(
        controlPoints: [pkMakePoint(0, 0), pkMakePoint(4, 0), pkMakePoint(8, 0)],
        creationDate: Date(timeIntervalSince1970: 0)
    )
    let slice = path.interpolatedPoints(in: 0...2, by: .parametricStep(1))
    let mapped = slice.map { $0.location.x }
    pkExpect(mapped.count >= 2, "slice map")
    pkExpect(slice.contains(where: { $0.location.x == 0 }), "slice contains")
    pkExpect(Array(slice.filter { $0.location.x >= 0 }).count >= 1, "slice filter")
    pkExpect(slice.allSatisfy { $0.opacity == 1 }, "slice allSatisfy")
    _ = slice.compactMap { Optional($0.location.x) }
    _ = slice.reduce(0 as CGFloat) { $0 + $1.location.x }
    _ = slice.reduce(into: 0 as CGFloat) { $0 += $1.location.x }
    _ = slice.sorted(by: { $0.location.x < $1.location.x })
    _ = slice.min(by: { $0.location.x < $1.location.x })
    _ = slice.max(by: { $0.location.x < $1.location.x })
    _ = Array(slice.prefix(1))
    _ = slice.suffix(1)
    _ = slice.dropFirst()
    _ = slice.dropLast()
    _ = slice.reversed()
    _ = slice.enumerated()
    _ = slice.lazy
    _ = slice.underestimatedCount
    _ = slice.first(where: { $0.location.x >= 0 })
    _ = slice.count(where: { $0.opacity == 1 })
    slice.forEach { _ in }
    _ = slice.flatMap { [$0.location.x] }
    _ = slice.elementsEqual(slice, by: { $0.location == $1.location })
    _ = slice.starts(with: [], by: { _, _ in true })
    _ = slice.lexicographicallyPrecedes(slice, by: { $0.location.x < $1.location.x })
    _ = path.lexicographicallyPrecedes(path, by: { $0.location.x < $1.location.x })
    _ = slice.shuffled()
    var generator = SystemRandomNumberGenerator()
    _ = slice.shuffled(using: &generator)
    _ = path.shuffled()
    _ = path.shuffled(using: &generator)
    _ = path.randomElement()
    _ = path.randomElement(using: &generator)
}
