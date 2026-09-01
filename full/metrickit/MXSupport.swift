import Foundation

enum MXSerialization {
    static let emptyJSON = Data("{}".utf8)

    static func jsonData(from dictionary: [AnyHashable: Any]) -> Data {
        let object = jsonObject(dictionary)
        guard JSONSerialization.isValidJSONObject(object) else {
            return emptyJSON
        }
        return (try? JSONSerialization.data(withJSONObject: object, options: [])) ?? emptyJSON
    }

    static func jsonObject(_ value: Any) -> Any {
        switch value {
        case let dict as [AnyHashable: Any]:
            var out: [String: Any] = [:]
            out.reserveCapacity(dict.count)
            for (key, nested) in dict {
                out[String(describing: key)] = jsonObject(nested)
            }
            return out
        case let array as [Any]:
            return array.map(jsonObject)
        case let measurement as any MXJSONMeasurement:
            return measurement.mx_json
        case let date as Date:
            return date.timeIntervalSince1970
        case let data as Data:
            return data.base64EncodedString()
        case let number as NSNumber:
            return number
        case let string as String:
            return string
        case is NSNull:
            return NSNull()
        default:
            if let optional = value as? any OptionalProtocol, optional.isNil {
                return NSNull()
            }
            return value
        }
    }

    static func measurement<UnitType: Unit>(_ measurement: Measurement<UnitType>) -> [String: Any] {
        ["value": measurement.value, "unit": measurement.unit.symbol]
    }
}

private protocol MXJSONMeasurement {
    var mx_json: [String: Any] { get }
}

extension Measurement: MXJSONMeasurement {
    fileprivate var mx_json: [String: Any] {
        ["value": value, "unit": unit.symbol]
    }
}

private protocol OptionalProtocol {
    var isNil: Bool { get }
}

extension Optional: OptionalProtocol {
    fileprivate var isNil: Bool { self == nil }
}

func mxFailClosedEncode(_ coder: NSCoder) {
    _ = coder
}

open class MXUnitAveragePixelLuminance: Dimension, @unchecked Sendable {
    private static let _apl = MXUnitAveragePixelLuminance(
        symbol: "apl",
        converter: UnitConverterLinear(coefficient: 1.0)
    )

    open class var apl: MXUnitAveragePixelLuminance { _apl }

    open override class func baseUnit() -> Self {
        unsafeDowncast(_apl, to: Self.self)
    }
}

open class MXUnitSignalBars: Dimension, @unchecked Sendable {
    private static let _bars = MXUnitSignalBars(
        symbol: "bars",
        converter: UnitConverterLinear(coefficient: 1.0)
    )

    open class var bars: MXUnitSignalBars { _bars }

    open override class func baseUnit() -> Self {
        unsafeDowncast(_bars, to: Self.self)
    }
}

open class MXAverage<UnitType: Unit>: NSObject, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    private let _averageMeasurement: Measurement<UnitType>
    private let _sampleCount: Int
    private let _standardDeviation: Double

    open var averageMeasurement: Measurement<UnitType> { _averageMeasurement }
    open var sampleCount: Int { _sampleCount }
    open var standardDeviation: Double { _standardDeviation }

    @_spi(OpenUIKitHost)
    public init(
        averageMeasurement: Measurement<UnitType>,
        sampleCount: Int = 0,
        standardDeviation: Double = 0
    ) {
        self._averageMeasurement = averageMeasurement
        self._sampleCount = sampleCount
        self._standardDeviation = standardDeviation
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open func encode(with coder: NSCoder) {
        mxFailClosedEncode(coder)
    }
}

open class MXHistogramBucket<UnitType: Unit>: NSObject, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    private let _bucketStart: Measurement<UnitType>
    private let _bucketEnd: Measurement<UnitType>
    private let _bucketCount: Int

    open var bucketStart: Measurement<UnitType> { _bucketStart }
    open var bucketEnd: Measurement<UnitType> { _bucketEnd }
    open var bucketCount: Int { _bucketCount }

    @_spi(OpenUIKitHost)
    public init(
        bucketStart: Measurement<UnitType>,
        bucketEnd: Measurement<UnitType>,
        bucketCount: Int
    ) {
        self._bucketStart = bucketStart
        self._bucketEnd = bucketEnd
        self._bucketCount = bucketCount
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open func encode(with coder: NSCoder) {
        mxFailClosedEncode(coder)
    }
}

open class MXHistogram<UnitType: Unit>: NSObject, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    private let buckets: [MXHistogramBucket<UnitType>]

    open var totalBucketCount: Int { buckets.count }

    open var bucketEnumerator: NSEnumerator {
        NSArray(array: buckets).objectEnumerator()
    }

    @_spi(OpenUIKitHost)
    public init(buckets: [MXHistogramBucket<UnitType>] = []) {
        self.buckets = buckets
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open func encode(with coder: NSCoder) {
        mxFailClosedEncode(coder)
    }
}
