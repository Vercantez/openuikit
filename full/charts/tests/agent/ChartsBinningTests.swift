import Foundation
@_spi(OpenUIKitHost) import Charts

private struct ChartBinningFixedRNG: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        return state
    }
}

private enum ChartFixtureStatus: String, Plottable {
    case open
    typealias PrimitivePlottable = String
}

func testNumberBinsThresholdsCollection() {
    let bins = NumberBins(thresholds: [0.0, 5.0, 10.0])
    precondition(bins.startIndex == 0)
    precondition(bins.endIndex == 2)
    precondition(bins.count == 2)
    precondition(bins.index(after: 0) == 1)
    precondition(bins.index(before: 2) == 1)
    let first: NumberBins<Double>.Element = bins[0]
    precondition(first.lowerBound == 0)
    precondition(first.upperBound == 5)
    precondition(bins[1].lowerBound == 5)
    precondition(bins[1].upperBound == 10)
    let _: NumberBins<Double>.Index = bins.startIndex
    let slice: NumberBins<Double>.SubSequence = bins.prefix(1)
    precondition(slice.count == 1)
    let _: NumberBins<Double>.Indices = bins.indices
    var iterator: NumberBins<Double>.Iterator = bins.makeIterator()
    precondition(iterator.next()?.lowerBound == 0)
    precondition(bins == NumberBins(thresholds: [0.0, 5.0, 10.0]))
    precondition(bins != NumberBins(thresholds: [0.0, 1.0]))
}

func testNumberBinsRangeCountFloating() {
    let bins = NumberBins<Double>(range: 0.0...10.0, count: 5)
    precondition(bins.thresholds.count == 6)
    precondition(bins.thresholds.first == 0)
    precondition(bins.thresholds.last == 10)
    precondition(abs(bins.thresholds[2] - 4) < 0.0000001)
    precondition(bins.count == 5)
}

func testNumberBinsRangeCountInteger() {
    let bins = NumberBins<Int>(range: 0...10, count: 5)
    precondition(bins.thresholds == [0, 2, 4, 6, 8, 10])
    precondition(bins.count == 5)
}

func testNumberBinsSizeRangeFloating() {
    let bins = NumberBins<Double>(size: 3.0, range: 0.0...10.0)
    precondition(bins.thresholds == [0, 3, 6, 9, 12])
    precondition(bins.count == 4)
}

func testNumberBinsSizeRangeInteger() {
    let bins = NumberBins<Int>(size: 3, range: 0...10)
    precondition(bins.thresholds == [0, 3, 6, 9, 12])
}

func testNumberBinsDesiredCountNiceDomain() {
    let floating = NumberBins<Double>(range: 0.2...9.7, desiredCount: 5, minimumStride: 0)
    precondition(floating.thresholds == [0, 2, 4, 6, 8, 10])
    let integers = NumberBins<Int>(range: 0...10, desiredCount: 5, minimumStride: 0)
    precondition(integers.thresholds == [0, 2, 4, 6, 8, 10])
    let minStride = NumberBins<Double>(range: 0.0...10.0, desiredCount: 10, minimumStride: 5)
    precondition(minStride.thresholds == [0, 5, 10])
}

func testNumberBinsDataInference() {
    let floating = NumberBins<Double>(data: [0.2, 4.0, 9.7], desiredCount: 5, minimumStride: 0)
    precondition(floating.thresholds == [0, 2, 4, 6, 8, 10])
    let integers = NumberBins<Int>(data: [0, 4, 10], desiredCount: 5, minimumStride: 0)
    precondition(integers.thresholds == [0, 2, 4, 6, 8, 10])
    let empty = NumberBins<Double>(data: [], desiredCount: 5)
    precondition(empty.thresholds.isEmpty)
    precondition(empty.isEmpty)
}

func testNumberBinsIndexFor() {
    let bins = NumberBins(thresholds: [0.0, 5.0, 10.0])
    precondition(bins.index(for: -1) == 0)
    precondition(bins.index(for: 0) == 0)
    precondition(bins.index(for: 4.9) == 0)
    precondition(bins.index(for: 5) == 1)
    precondition(bins.index(for: 10) == 1)
    precondition(bins.index(for: 11) == 1)
    let integers = NumberBins(thresholds: [0, 5, 10])
    precondition(integers.index(for: 5) == 1)
}

func testNumberBinsHistogramBarPixels() {
    let bins = NumberBins<Double>(range: 0.0...10.0, count: 2)
    precondition(bins.thresholds == [0, 5, 10])
    let data: [Double] = [1, 2, 3, 8, 9]
    var counts = [0, 0]
    for value in data {
        counts[bins.index(for: value)] += 1
    }
    precondition(counts == [3, 2])
    let chart = Chart {
        BarMark(x: .value("bin", "low"), y: .value("n", 3), stacking: .unstacked)
        BarMark(x: .value("bin", "high"), y: .value("n", 2), stacking: .unstacked)
    }
    .chartYScale(domain: 0...4)
    let plot = ChartFixedPlotFixture.plotArea
    let placed = chart.placedMarks(plotArea: plot)
    let bars = placed.filter { $0.kind == .bar }
    precondition(bars.count == 2)
    // Category scale on 100-wide plot, two bands: width 50, inset 4.
    // low: x=4, width=42; high: x=54, width=42.
    // Y domain 0...4 inverted over 0...40: y=3 → 10, height 30; y=2 → 20, height 20.
    precondition(abs(bars[0].frame.minX - 4) < 0.0001)
    precondition(abs(bars[0].frame.width - 42) < 0.0001)
    precondition(abs(bars[0].frame.minY - 10) < 0.0001)
    precondition(abs(bars[0].frame.height - 30) < 0.0001)
    precondition(abs(bars[1].frame.minX - 54) < 0.0001)
    precondition(abs(bars[1].frame.width - 42) < 0.0001)
    precondition(abs(bars[1].frame.minY - 20) < 0.0001)
    precondition(abs(bars[1].frame.height - 20) < 0.0001)
    let proxy = chart.resolvedProxy(plotArea: plot)
    precondition(abs((proxy.position(forY: 0) ?? -1) - 40) < 0.0001)
    precondition(abs((proxy.position(forY: 4) ?? -1) - 0) < 0.0001)
}

func testNumberBinsCollectionAlgorithms() {
    let bins = NumberBins(thresholds: [0.0, 5.0, 10.0, 15.0])
    precondition(bins.allSatisfy { $0.lowerBound >= 0 })
    let compacted = bins.compactMap { $0.lowerBound == 5 ? $0.upperBound : nil }
    precondition(compacted == [10])
    let enumerated = Array(bins.enumerated())
    precondition(enumerated.count == 3)
    precondition(enumerated[0].offset == 0)
    precondition(
        bins.elementsEqual(NumberBins(thresholds: [0.0, 5.0, 10.0, 15.0]), by: { $0.lowerBound == $1.lowerBound })
    )
    precondition(
        bins.lexicographicallyPrecedes(NumberBins(thresholds: [1.0, 6.0, 11.0, 16.0]), by: { $0.lowerBound < $1.lowerBound })
    )
    let contiguous: Int? = bins.withContiguousStorageIfAvailable { $0.count }
    _ = contiguous
    let mapped = bins.map { $0.lowerBound }
    precondition(mapped == [0, 5, 10])
    precondition(bins.max(by: { $0.lowerBound < $1.lowerBound })?.lowerBound == 10)
    precondition(bins.min(by: { $0.lowerBound < $1.lowerBound })?.lowerBound == 0)
    let lazyLower = Array(bins.lazy.map { $0.lowerBound })
    precondition(lazyLower == [0, 5, 10])
    precondition(bins.count(where: { $0.lowerBound >= 5 }) == 2)
    precondition(bins.first(where: { $0.lowerBound == 5 })?.upperBound == 10)
    let filtered = bins.filter { $0.lowerBound > 0 }
    precondition(filtered.count == 2)
    let reduced = bins.reduce(0.0) { $0 + $1.lowerBound }
    precondition(reduced == 15)
    let into = bins.reduce(into: 0.0) { $0 += $1.lowerBound }
    precondition(into == 15)
    let sorted = bins.sorted(by: { $0.lowerBound > $1.lowerBound })
    precondition(sorted.first?.lowerBound == 10)
    precondition(bins.starts(with: [bins[0]], by: { $0.lowerBound == $1.lowerBound }))
    let flat = bins.flatMap { [$0.lowerBound, $0.upperBound] }
    precondition(flat == [0, 5, 5, 10, 10, 15])
    var seen = 0
    bins.forEach { _ in seen += 1 }
    precondition(seen == 3)
    precondition(bins.contains(where: { $0.upperBound == 15 }))
    precondition(bins.reversed().first?.lowerBound == 10)
    var rng = ChartBinningFixedRNG(state: 1)
    precondition(bins.shuffled(using: &rng).count == 3)
    precondition(bins.shuffled().count == 3)
}

func testNumberBinsCollectionSlicing() {
    let bins = NumberBins(thresholds: [0.0, 5.0, 10.0, 15.0])
    precondition(bins.firstIndex(where: { $0.lowerBound == 10 }) == 2)
    var rng = ChartBinningFixedRNG(state: 2)
    precondition(bins.randomElement(using: &rng) != nil)
    precondition(bins.randomElement() != nil)
    precondition(bins.underestimatedCount == 3)
    precondition(bins.drop(while: { $0.lowerBound == 0 }).count == 2)
    precondition(bins.first?.lowerBound == 0)
    precondition(bins.index(0, offsetBy: 2) == 2)
    precondition(bins.index(0, offsetBy: 5, limitedBy: 2) == nil)
    let split = bins.split(maxSplits: 1, omittingEmptySubsequences: true, whereSeparator: { $0.lowerBound == 5 })
    precondition(split.count == 2)
    precondition(bins.prefix(upTo: 1).count == 1)
    precondition(bins.prefix(while: { $0.lowerBound < 10 }).count == 2)
    precondition(bins.prefix(through: 1).count == 2)
    precondition(bins.prefix(1).count == 1)
    precondition(bins.suffix(from: 2).count == 1)
    precondition(bins.suffix(1).count == 1)
    precondition(bins.indices(where: { $0.lowerBound >= 5 }).isEmpty == false)
    precondition(!bins.isEmpty)
    precondition(bins.distance(from: 0, to: 2) == 2)
    precondition(bins.dropLast(1).count == 2)
    precondition(bins.dropFirst(1).count == 2)
    var after = 0
    bins.formIndex(after: &after)
    precondition(after == 1)
    var offset = 0
    bins.formIndex(&offset, offsetBy: 2)
    precondition(offset == 2)
    var limited = 0
    let moved = bins.formIndex(&limited, offsetBy: 9, limitedBy: 2)
    precondition(moved == false)
    precondition(Array(bins.indices) == [0, 1, 2])
    let trimmed = bins.trimmingPrefix(while: { $0.lowerBound == 0 })
    precondition(trimmed.first?.lowerBound == 5)
    let removed = bins.removingSubranges(RangeSet(0..<1))
    precondition(removed.count == 2)
}

func testDateBinsThresholdsCollection() {
    let start = Date(timeIntervalSinceReferenceDate: 0)
    let mid = Date(timeIntervalSinceReferenceDate: 5)
    let end = Date(timeIntervalSinceReferenceDate: 10)
    let bins = DateBins(thresholds: [start, mid, end])
    precondition(bins.thresholds.count == 3)
    precondition(bins.startIndex == 0)
    precondition(bins.endIndex == 2)
    precondition(bins.count == 2)
    precondition(bins.index(after: 0) == 1)
    precondition(bins[0].lowerBound == start)
    precondition(bins[0].upperBound == mid)
    let _: DateBins.Index = bins.startIndex
    let _: DateBins.Element = bins[0]
    let _: DateBins.SubSequence = bins.prefix(1)
    let _: DateBins.Indices = bins.indices
    var iterator: DateBins.Iterator = bins.makeIterator()
    precondition(iterator.next()?.lowerBound == start)
    precondition(bins == DateBins(thresholds: [start, mid, end]))
    precondition(bins != DateBins(thresholds: [start]))
}

func testDateBinsTimeInterval() {
    let start = Date(timeIntervalSinceReferenceDate: 0)
    let end = Date(timeIntervalSinceReferenceDate: 10)
    let bins = DateBins(timeInterval: 5, range: start...end)
    precondition(bins.thresholds.count == 3)
    precondition(bins.thresholds[1].timeIntervalSinceReferenceDate == 5)
    precondition(bins.count == 2)
}

func testDateBinsUnitStride() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let start = Date(timeIntervalSinceReferenceDate: 0)
    let end = Date(timeIntervalSinceReferenceDate: 172800)
    let bins = DateBins(unit: .day, by: 1, range: start...end, calendar: calendar)
    precondition(bins.count >= 2)
    precondition(bins.thresholds.first == start)
}

func testDateBinsDesiredCount() {
    let start = Date(timeIntervalSinceReferenceDate: 0)
    let end = Date(timeIntervalSinceReferenceDate: 100)
    let bins = DateBins(range: start...end, desiredCount: 4, calendar: Calendar(identifier: .gregorian))
    precondition(bins.thresholds.count == 5)
    precondition(bins.thresholds.first == start)
    precondition(bins.thresholds.last == end)
    precondition(abs(bins.thresholds[2].timeIntervalSinceReferenceDate - 50) < 0.0001)
}

func testDateBinsDataInference() {
    let dates = [
        Date(timeIntervalSinceReferenceDate: 0),
        Date(timeIntervalSinceReferenceDate: 40),
        Date(timeIntervalSinceReferenceDate: 100),
    ]
    let bins = DateBins(data: dates, desiredCount: 4)
    precondition(bins.thresholds.count == 5)
    precondition(bins.thresholds.first?.timeIntervalSinceReferenceDate == 0)
    precondition(bins.thresholds.last?.timeIntervalSinceReferenceDate == 100)
}

func testDateBinsIndexFor() {
    let start = Date(timeIntervalSinceReferenceDate: 0)
    let mid = Date(timeIntervalSinceReferenceDate: 5)
    let end = Date(timeIntervalSinceReferenceDate: 10)
    let bins = DateBins(thresholds: [start, mid, end])
    precondition(bins.index(for: Date(timeIntervalSinceReferenceDate: -1)) == 0)
    precondition(bins.index(for: start) == 0)
    precondition(bins.index(for: Date(timeIntervalSinceReferenceDate: 4.9)) == 0)
    precondition(bins.index(for: mid) == 1)
    precondition(bins.index(for: end) == 1)
}

func testDateBinsThresholdPixels() {
    let start = Date(timeIntervalSinceReferenceDate: 0)
    let end = Date(timeIntervalSinceReferenceDate: 100)
    let bins = DateBins(timeInterval: 50, range: start...end)
    let chart = Chart {
        RuleMark(x: .value("edge", bins.thresholds[1]))
    }
    .chartXScale(domain: 0...100)
    .chartYScale(domain: 0...1)
    let proxy = chart.resolvedProxy(plotArea: ChartFixedPlotFixture.plotArea)
    precondition(abs((proxy.position(forX: bins.thresholds[1]) ?? -1) - 50) < 0.0001)
    let placed = chart.placedMarks(plotArea: ChartFixedPlotFixture.plotArea)
    let rule = placed.first { $0.kind == .rule }
    precondition(abs((rule?.points.first?.x ?? -1) - 50) < 0.0001)
}

func testDateBinsCollectionAlgorithms() {
    let bins = DateBins(thresholds: [
        Date(timeIntervalSinceReferenceDate: 0),
        Date(timeIntervalSinceReferenceDate: 5),
        Date(timeIntervalSinceReferenceDate: 10),
        Date(timeIntervalSinceReferenceDate: 15),
    ])
    precondition(bins.allSatisfy { $0.lowerBound.timeIntervalSinceReferenceDate >= 0 })
    let compacted = bins.compactMap { $0.lowerBound.timeIntervalSinceReferenceDate == 5 ? $0.upperBound : nil }
    precondition(compacted.count == 1)
    precondition(Array(bins.enumerated()).count == 3)
    precondition(
        bins.elementsEqual(
            DateBins(thresholds: [
                Date(timeIntervalSinceReferenceDate: 0),
                Date(timeIntervalSinceReferenceDate: 5),
                Date(timeIntervalSinceReferenceDate: 10),
                Date(timeIntervalSinceReferenceDate: 15),
            ]),
            by: { $0.lowerBound == $1.lowerBound }
        )
    )
    precondition(
        bins.lexicographicallyPrecedes(
            DateBins(thresholds: [
                Date(timeIntervalSinceReferenceDate: 1),
                Date(timeIntervalSinceReferenceDate: 6),
                Date(timeIntervalSinceReferenceDate: 11),
                Date(timeIntervalSinceReferenceDate: 16),
            ]),
            by: { $0.lowerBound < $1.lowerBound }
        )
    )
    _ = bins.withContiguousStorageIfAvailable { $0.count }
    precondition(bins.map { $0.lowerBound.timeIntervalSinceReferenceDate } == [0, 5, 10])
    precondition(bins.max(by: { $0.lowerBound < $1.lowerBound })?.lowerBound.timeIntervalSinceReferenceDate == 10)
    precondition(bins.min(by: { $0.lowerBound < $1.lowerBound })?.lowerBound.timeIntervalSinceReferenceDate == 0)
    precondition(Array(bins.lazy.map { $0.lowerBound }).count == 3)
    precondition(bins.count(where: { $0.lowerBound.timeIntervalSinceReferenceDate >= 5 }) == 2)
    precondition(bins.first(where: { $0.lowerBound.timeIntervalSinceReferenceDate == 5 }) != nil)
    precondition(bins.filter { $0.lowerBound.timeIntervalSinceReferenceDate > 0 }.count == 2)
    precondition(bins.reduce(0.0) { $0 + $1.lowerBound.timeIntervalSinceReferenceDate } == 15)
    precondition(bins.reduce(into: 0.0) { $0 += $1.lowerBound.timeIntervalSinceReferenceDate } == 15)
    precondition(bins.sorted(by: { $0.lowerBound > $1.lowerBound }).first?.lowerBound.timeIntervalSinceReferenceDate == 10)
    precondition(bins.starts(with: [bins[0]], by: { $0.lowerBound == $1.lowerBound }))
    precondition(bins.flatMap { [$0.lowerBound] }.count == 3)
    var seen = 0
    bins.forEach { _ in seen += 1 }
    precondition(seen == 3)
    precondition(bins.contains(where: { $0.upperBound.timeIntervalSinceReferenceDate == 15 }))
    precondition(bins.reversed().first?.lowerBound.timeIntervalSinceReferenceDate == 10)
    var rng = ChartBinningFixedRNG(state: 3)
    precondition(bins.shuffled(using: &rng).count == 3)
    precondition(bins.shuffled().count == 3)
}

func testDateBinsCollectionSlicing() {
    let bins = DateBins(thresholds: [
        Date(timeIntervalSinceReferenceDate: 0),
        Date(timeIntervalSinceReferenceDate: 5),
        Date(timeIntervalSinceReferenceDate: 10),
        Date(timeIntervalSinceReferenceDate: 15),
    ])
    precondition(bins.firstIndex(where: { $0.lowerBound.timeIntervalSinceReferenceDate == 10 }) == 2)
    var rng = ChartBinningFixedRNG(state: 4)
    precondition(bins.randomElement(using: &rng) != nil)
    precondition(bins.randomElement() != nil)
    precondition(bins.underestimatedCount == 3)
    precondition(bins.drop(while: { $0.lowerBound.timeIntervalSinceReferenceDate == 0 }).count == 2)
    precondition(bins.first?.lowerBound.timeIntervalSinceReferenceDate == 0)
    precondition(bins.index(0, offsetBy: 2) == 2)
    precondition(bins.index(0, offsetBy: 5, limitedBy: 2) == nil)
    precondition(bins.split(maxSplits: 1, omittingEmptySubsequences: true, whereSeparator: { $0.lowerBound.timeIntervalSinceReferenceDate == 5 }).count == 2)
    precondition(bins.prefix(upTo: 1).count == 1)
    precondition(bins.prefix(while: { $0.lowerBound.timeIntervalSinceReferenceDate < 10 }).count == 2)
    precondition(bins.prefix(through: 1).count == 2)
    precondition(bins.prefix(1).count == 1)
    precondition(bins.suffix(from: 2).count == 1)
    precondition(bins.suffix(1).count == 1)
    precondition(!bins.indices(where: { $0.lowerBound.timeIntervalSinceReferenceDate >= 5 }).isEmpty)
    precondition(!bins.isEmpty)
    precondition(bins.distance(from: 0, to: 2) == 2)
    precondition(bins.dropLast(1).count == 2)
    precondition(bins.dropFirst(1).count == 2)
    var after = 0
    bins.formIndex(after: &after)
    precondition(after == 1)
    var offset = 0
    bins.formIndex(&offset, offsetBy: 2)
    precondition(offset == 2)
    var limited = 0
    precondition(bins.formIndex(&limited, offsetBy: 9, limitedBy: 2) == false)
    precondition(Array(bins.indices) == [0, 1, 2])
    precondition(bins.trimmingPrefix(while: { $0.lowerBound.timeIntervalSinceReferenceDate == 0 }).first?.lowerBound.timeIntervalSinceReferenceDate == 5)
    precondition(bins.removingSubranges(RangeSet(0..<1)).count == 2)
}

func testChartBinRangeContainsRelativeAndPattern() {
    let range = ChartBinRange(uncheckedBounds: (lower: 0, upper: 10))
    precondition(range.contains(0))
    precondition(range.contains(9))
    precondition(!range.contains(10))
    precondition(!range.contains(-1))
    let relative = ChartBinRange(uncheckedBounds: (lower: 1, upper: 3)).relative(to: ["a", "b", "c", "d"])
    precondition(relative == 1..<3)
    precondition(ChartBinRange(uncheckedBounds: (lower: 0, upper: 5)) ~= 2)
    precondition(!(ChartBinRange(uncheckedBounds: (lower: 0, upper: 5)) ~= 5))
}

func testPrimitivePlottableProtocolNumericWitnesses() {
    func roundTrip<T: PrimitivePlottableProtocol & Equatable>(_ value: T) {
        precondition(value.primitivePlottable == value)
        precondition(T(primitivePlottable: value) == value)
    }
    roundTrip(7)
    roundTrip(Int8(3))
    roundTrip(Int16(3))
    roundTrip(Int32(3))
    roundTrip(Int64(3))
    roundTrip(UInt(3))
    roundTrip(UInt8(3))
    roundTrip(UInt16(3))
    roundTrip(UInt32(3))
    roundTrip(UInt64(3))
    roundTrip(Float(1.5))
    roundTrip(Float16(1.25))
    roundTrip(2.5)
}

func testPrimitivePlottableProtocolStringDateWitnesses() {
    precondition(("A" as String).primitivePlottable == "A")
    precondition(String(primitivePlottable: "A") == "A")
    let day = Date(timeIntervalSinceReferenceDate: 9)
    precondition(day.primitivePlottable == day)
    precondition(Date(primitivePlottable: day) == day)
}

func testDecimalPlottableRoundTrip() {
    let value = Decimal(12.5)
    precondition(value.primitivePlottable == 12.5)
    precondition(Decimal(primitivePlottable: 12.5) == Decimal(12.5))
    precondition(chartEncode(value) == .number(12.5))
}

func testPlottableStringRawValueEnum() {
    precondition(ChartFixtureStatus.open.primitivePlottable == "open")
    precondition(ChartFixtureStatus(primitivePlottable: "open") == .open)
    precondition(ChartFixtureStatus(primitivePlottable: "missing") == nil)
}

func testFloat16PlottableEncoding() {
    let encoded = chartEncode(Float16(4))
    precondition(encoded == .number(4))
    precondition(chartDecode(encoded!, as: Float16.self) == Float16(4))
}

func testNeverPrimitivePlottableTypealias() {
    precondition(Never.PrimitivePlottable.self == Never.self)
}
