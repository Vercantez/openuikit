/// Numeric statistics for a floating-point column.
public struct NumericSummary<Element>: Hashable where Element: BinaryFloatingPoint {
    public var someCount: Int
    public var noneCount: Int
    public var mean: Element
    public var standardDeviation: Element
    public var min: Element
    public var max: Element
    public var median: Element
    public var firstQuartile: Element
    public var thirdQuartile: Element

    public var totalCount: Int { someCount + noneCount }

    public init(
        someCount: Int,
        noneCount: Int,
        mean: Element,
        standardDeviation: Element,
        min: Element,
        max: Element,
        median: Element,
        firstQuartile: Element,
        thirdQuartile: Element
    ) {
        self.someCount = someCount
        self.noneCount = noneCount
        self.mean = mean
        self.standardDeviation = standardDeviation
        self.min = min
        self.max = max
        self.median = median
        self.firstQuartile = firstQuartile
        self.thirdQuartile = thirdQuartile
    }

    public init() {
        self.init(
            someCount: 0,
            noneCount: 0,
            mean: 0,
            standardDeviation: 0,
            min: 0,
            max: 0,
            median: 0,
            firstQuartile: 0,
            thirdQuartile: 0
        )
    }

    public var debugDescription: String {
        "NumericSummary(some: \(someCount), none: \(noneCount), mean: \(mean))"
    }
}

/// Frequency statistics for a hashable column.
public struct CategoricalSummary<Element>: Hashable where Element: Hashable {
    public var someCount: Int
    public var noneCount: Int
    public var uniqueCount: Int
    public var mode: [Element]

    public var totalCount: Int { someCount + noneCount }

    public init(someCount: Int, noneCount: Int, uniqueCount: Int, mode: [Element]) {
        self.someCount = someCount
        self.noneCount = noneCount
        self.uniqueCount = uniqueCount
        self.mode = mode
    }

    public init() {
        self.init(someCount: 0, noneCount: 0, uniqueCount: 0, mode: [])
    }

    public var debugDescription: String {
        "CategoricalSummary(some: \(someCount), unique: \(uniqueCount))"
    }
}

/// Type-erased categorical summary.
public struct AnyCategoricalSummary: Equatable, Hashable {
    public var someCount: Int
    public var noneCount: Int
    public var uniqueCount: Int
    public var mode: [AnyHashable]
    public var modeType: any Any.Type

    public var totalCount: Int { someCount + noneCount }

    public init(_ summary: CategoricalSummary<AnyHashable>) {
        self.someCount = summary.someCount
        self.noneCount = summary.noneCount
        self.uniqueCount = summary.uniqueCount
        self.mode = summary.mode
        self.modeType = AnyHashable.self
    }

    public init<T>(_ summary: CategoricalSummary<T>) where T: Hashable {
        self.someCount = summary.someCount
        self.noneCount = summary.noneCount
        self.uniqueCount = summary.uniqueCount
        self.mode = summary.mode.map { AnyHashable($0) }
        self.modeType = T.self
    }

    public var debugDescription: String {
        "AnyCategoricalSummary(some: \(someCount), unique: \(uniqueCount))"
    }

    public static func == (lhs: AnyCategoricalSummary, rhs: AnyCategoricalSummary) -> Bool {
        lhs.someCount == rhs.someCount
            && lhs.noneCount == rhs.noneCount
            && lhs.uniqueCount == rhs.uniqueCount
            && lhs.mode == rhs.mode
            && ObjectIdentifier(lhs.modeType) == ObjectIdentifier(rhs.modeType)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(someCount)
        hasher.combine(noneCount)
        hasher.combine(uniqueCount)
        hasher.combine(mode)
        hasher.combine(ObjectIdentifier(modeType))
    }
}

func tabularQuantile<T: BinaryFloatingPoint>(_ sorted: [T], _ q: Double) -> T {
    guard !sorted.isEmpty else { return 0 }
    if sorted.count == 1 { return sorted[0] }
    let position = q * Double(sorted.count - 1)
    let lower = Int(position)
    let upper = min(lower + 1, sorted.count - 1)
    let fraction = T(position - Double(lower))
    return sorted[lower] + (sorted[upper] - sorted[lower]) * fraction
}

func tabularNumericSummary<T: BinaryFloatingPoint>(_ values: [T?], ddof: Int = 1) -> NumericSummary<T> {
    let present = values.compactMap { $0 }
    let noneCount = values.count - present.count
    guard !present.isEmpty else { return NumericSummary() }
    let sorted = present.sorted()
    let sum = present.reduce(into: T(0)) { $0 += $1 }
    let mean = sum / T(present.count)
    var variance = T(0)
    if present.count > ddof {
        for value in present {
            let delta = value - mean
            variance += delta * delta
        }
        variance /= T(present.count - ddof)
    }
    return NumericSummary(
        someCount: present.count,
        noneCount: noneCount,
        mean: mean,
        standardDeviation: T(variance.squareRoot()),
        min: sorted.first!,
        max: sorted.last!,
        median: tabularQuantile(sorted, 0.5),
        firstQuartile: tabularQuantile(sorted, 0.25),
        thirdQuartile: tabularQuantile(sorted, 0.75)
    )
}

func tabularCategoricalSummary<T: Hashable>(_ values: [T?]) -> CategoricalSummary<T> {
    var counts: [T: Int] = [:]
    var noneCount = 0
    for value in values {
        if let value {
            counts[value, default: 0] += 1
        } else {
            noneCount += 1
        }
    }
    let maxCount = counts.values.max() ?? 0
    let mode = counts.filter { $0.value == maxCount && maxCount > 0 }.map(\.key)
    return CategoricalSummary(
        someCount: values.count - noneCount,
        noneCount: noneCount,
        uniqueCount: counts.count,
        mode: mode
    )
}
