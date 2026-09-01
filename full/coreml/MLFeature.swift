import Foundation

extension MLFeatureValue {
    public struct ImageOption: RawRepresentable, Hashable, Sendable {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }

        public static let cropAndScale = ImageOption(rawValue: "MLFeatureValueImageOptionCropAndScale")
        public static let cropRect = ImageOption(rawValue: "MLFeatureValueImageOptionCropRect")
    }
}

private enum MLFeaturePayload {
    case invalid
    case undefined(MLFeatureType)
    case int64(Int64)
    case double(Double)
    case string(String)
    case multiArray(MLMultiArray)
    case dictionary([AnyHashable: NSNumber])
    case sequence(MLSequence)
}

open class MLFeatureValue: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    private let payload: MLFeaturePayload

    public var type: MLFeatureType {
        switch payload {
        case .invalid: return .invalid
        case .undefined(let type): return type
        case .int64: return .int64
        case .double: return .double
        case .string: return .string
        case .multiArray: return .multiArray
        case .dictionary: return .dictionary
        case .sequence: return .sequence
        }
    }

    public var isUndefined: Bool {
        if case .undefined = payload { return true }
        return false
    }

    public var int64Value: Int64 {
        if case .int64(let value) = payload { return value }
        return 0
    }

    public var doubleValue: Double {
        if case .double(let value) = payload { return value }
        return 0
    }

    public var stringValue: String {
        if case .string(let value) = payload { return value }
        return ""
    }

    public var multiArrayValue: MLMultiArray? {
        if case .multiArray(let value) = payload { return value }
        return nil
    }

    public var dictionaryValue: [AnyHashable: NSNumber] {
        if case .dictionary(let value) = payload { return value }
        return [:]
    }

    public var sequenceValue: MLSequence? {
        if case .sequence(let value) = payload { return value }
        return nil
    }

    public convenience init(int64 value: Int64) {
        self.init(payload: .int64(value))
    }

    public convenience init(double value: Double) {
        self.init(payload: .double(value))
    }

    public convenience init(string value: String) {
        self.init(payload: .string(value))
    }

    public convenience init(multiArray value: MLMultiArray) {
        self.init(payload: .multiArray(value))
    }

    public convenience init(sequence: MLSequence) {
        self.init(payload: .sequence(sequence))
    }

    public convenience init(undefined type: MLFeatureType) {
        self.init(payload: .undefined(type))
    }

    public convenience init(dictionary value: [AnyHashable: NSNumber]) throws {
        let keys = Array(value.keys)
        let allString = keys.allSatisfy { $0 is String }
        let allInt = keys.allSatisfy { $0 is Int || $0 is Int64 || $0 is NSNumber }
        guard allString || allInt else {
            throw coreMLError(.featureType, "MLFeatureValue dictionary keys must be all String or all integer.")
        }
        self.init(payload: .dictionary(value))
    }

    public convenience init<Scalar>(shapedArray: MLShapedArray<Scalar>) where Scalar: MLShapedArrayScalar {
        self.init(multiArray: MLMultiArray(shapedArray))
    }

    public convenience init(_ value: MLSendableFeatureValue) {
        if value.isUndefined {
            self.init(undefined: value.type)
            return
        }
        switch value.type {
        case .int64:
            self.init(int64: Int64(value.integerValue ?? 0))
        case .double:
            self.init(double: value.doubleValue ?? 0)
        case .string:
            self.init(string: value.stringValue ?? "")
        case .dictionary:
            if let stringDictionary = value.stringDictionaryValue {
                let mapped = Dictionary(uniqueKeysWithValues: stringDictionary.map { ($0.key as AnyHashable, NSNumber(value: $0.value)) })
                try! self.init(dictionary: mapped)
            } else if let integerDictionary = value.integerDictionaryValue {
                let mapped = Dictionary(uniqueKeysWithValues: integerDictionary.map { ($0.key as AnyHashable, NSNumber(value: $0.value)) })
                try! self.init(dictionary: mapped)
            } else {
                self.init(payload: .invalid)
            }
        default:
            self.init(payload: .invalid)
        }
    }

    private init(payload: MLFeaturePayload) {
        self.payload = payload
        super.init()
    }

    public required init?(coder: NSCoder) {
        return nil
    }

    open func encode(with coder: NSCoder) {}

    public func isEqual(to value: MLFeatureValue) -> Bool {
        guard type == value.type, isUndefined == value.isUndefined else { return false }
        if isUndefined { return true }
        switch (payload, value.payload) {
        case (.int64(let lhs), .int64(let rhs)):
            return lhs == rhs
        case (.double(let lhs), .double(let rhs)):
            return lhs == rhs
        case (.string(let lhs), .string(let rhs)):
            return lhs == rhs
        case (.multiArray(let lhs), .multiArray(let rhs)):
            guard lhs.count == rhs.count, lhs.dataType == rhs.dataType else { return false }
            return lhs.withUnsafeBytes { left in
                rhs.withUnsafeBytes { right in
                    left.elementsEqual(right)
                }
            }
        case (.dictionary(let lhs), .dictionary(let rhs)):
            return NSDictionary(dictionary: lhs).isEqual(to: rhs)
        case (.sequence(let lhs), .sequence(let rhs)):
            return lhs.type == rhs.type
                && lhs.stringValues == rhs.stringValues
                && lhs.int64Values == rhs.int64Values
        default:
            return false
        }
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? MLFeatureValue else { return false }
        return isEqual(to: other)
    }

    public func shapedArrayValue<Scalar>(of type: Scalar.Type) -> MLShapedArray<Scalar>? where Scalar: MLShapedArrayScalar {
        guard let multiArray = multiArrayValue, Scalar.multiArrayDataType == multiArray.dataType else {
            return nil
        }
        return MLShapedArray(multiArray)
    }
}

open class MLSequence: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public private(set) var type: MLFeatureType
    public private(set) var int64Values: [NSNumber]
    public private(set) var stringValues: [String]

    public convenience init(empty type: MLFeatureType) {
        self.init(type: type, int64Values: [], stringValues: [])
    }

    public convenience init(int64s int64Values: [NSNumber]) {
        self.init(type: .int64, int64Values: int64Values, stringValues: [])
    }

    public convenience init(int64Array int64Values: [NSNumber]) {
        self.init(int64s: int64Values)
    }

    public convenience init(strings stringValues: [String]) {
        self.init(type: .string, int64Values: [], stringValues: stringValues)
    }

    public convenience init(stringArray stringValues: [String]) {
        self.init(strings: stringValues)
    }

    private init(type: MLFeatureType, int64Values: [NSNumber], stringValues: [String]) {
        self.type = type
        self.int64Values = int64Values
        self.stringValues = stringValues
        super.init()
    }

    public required init?(coder: NSCoder) {
        return nil
    }

    open func encode(with coder: NSCoder) {}
}

public struct MLSendableFeatureValue: Hashable, Sendable {
    public let type: MLFeatureType
    public let isUndefined: Bool
    public let integerValue: Int?
    public let doubleValue: Double?
    public let floatValue: Float?
    public let float16Value: Float16?
    public let stringValue: String?
    public let stringArrayValue: [String]?
    public let stringDictionaryValue: [String: Double]?
    public let integerDictionaryValue: [Int: Double]?

    public var isScalar: Bool {
        switch type {
        case .int64, .double: return !isUndefined
        default: return false
        }
    }

    public var isShapedArray: Bool { type == .multiArray && !isUndefined }

    public var debugDescription: String {
        "MLSendableFeatureValue(type: \(type), undefined: \(isUndefined))"
    }

    public init(undefined type: MLFeatureType) {
        self.type = type
        self.isUndefined = true
        self.integerValue = nil
        self.doubleValue = nil
        self.floatValue = nil
        self.float16Value = nil
        self.stringValue = nil
        self.stringArrayValue = nil
        self.stringDictionaryValue = nil
        self.integerDictionaryValue = nil
    }

    public init(_ value: String) {
        self.type = .string
        self.isUndefined = false
        self.integerValue = nil
        self.doubleValue = nil
        self.floatValue = nil
        self.float16Value = nil
        self.stringValue = value
        self.stringArrayValue = nil
        self.stringDictionaryValue = nil
        self.integerDictionaryValue = nil
    }

    public init(_ value: Double) {
        self.type = .double
        self.isUndefined = false
        self.integerValue = nil
        self.doubleValue = value
        self.floatValue = Float(value)
        self.float16Value = Float16(value)
        self.stringValue = nil
        self.stringArrayValue = nil
        self.stringDictionaryValue = nil
        self.integerDictionaryValue = nil
    }

    public init(_ value: Float) {
        self.init(Double(value))
    }

    public init(_ value: Float16) {
        self.init(Double(value))
    }

    public init(_ value: Int) {
        self.type = .int64
        self.isUndefined = false
        self.integerValue = value
        self.doubleValue = Double(value)
        self.floatValue = Float(value)
        self.float16Value = Float16(value)
        self.stringValue = nil
        self.stringArrayValue = nil
        self.stringDictionaryValue = nil
        self.integerDictionaryValue = nil
    }

    public init(_ value: Int32) {
        self.init(Int(value))
    }

    public init(_ value: [String]) {
        self.type = .sequence
        self.isUndefined = false
        self.integerValue = nil
        self.doubleValue = nil
        self.floatValue = nil
        self.float16Value = nil
        self.stringValue = nil
        self.stringArrayValue = value
        self.stringDictionaryValue = nil
        self.integerDictionaryValue = nil
    }

    public init(_ value: [String: Double]) {
        self.type = .dictionary
        self.isUndefined = false
        self.integerValue = nil
        self.doubleValue = nil
        self.floatValue = nil
        self.float16Value = nil
        self.stringValue = nil
        self.stringArrayValue = nil
        self.stringDictionaryValue = value
        self.integerDictionaryValue = nil
    }

    public init(_ value: [String: Int]) {
        self.init(Dictionary(uniqueKeysWithValues: value.map { ($0.key, Double($0.value)) }))
    }

    public init(_ value: [Int: Double]) {
        self.type = .dictionary
        self.isUndefined = false
        self.integerValue = nil
        self.doubleValue = nil
        self.floatValue = nil
        self.float16Value = nil
        self.stringValue = nil
        self.stringArrayValue = nil
        self.stringDictionaryValue = nil
        self.integerDictionaryValue = value
    }

    public init(_ value: [Int: Int]) {
        self.init(Dictionary(uniqueKeysWithValues: value.map { ($0.key, Double($0.value)) }))
    }

    public init?(_ value: MLFeatureValue) {
        self.type = value.type
        self.isUndefined = value.isUndefined
        switch value.type {
        case .int64:
            self.integerValue = Int(value.int64Value)
            self.doubleValue = Double(value.int64Value)
            self.floatValue = Float(value.int64Value)
            self.float16Value = Float16(value.int64Value)
            self.stringValue = nil
            self.stringArrayValue = nil
            self.stringDictionaryValue = nil
            self.integerDictionaryValue = nil
        case .double:
            self.integerValue = nil
            self.doubleValue = value.doubleValue
            self.floatValue = Float(value.doubleValue)
            self.float16Value = Float16(value.doubleValue)
            self.stringValue = nil
            self.stringArrayValue = nil
            self.stringDictionaryValue = nil
            self.integerDictionaryValue = nil
        case .string:
            self.integerValue = nil
            self.doubleValue = nil
            self.floatValue = nil
            self.float16Value = nil
            self.stringValue = value.stringValue
            self.stringArrayValue = nil
            self.stringDictionaryValue = nil
            self.integerDictionaryValue = nil
        case .dictionary:
            var strings: [String: Double] = [:]
            var ints: [Int: Double] = [:]
            for (key, number) in value.dictionaryValue {
                if let string = key as? String {
                    strings[string] = number.doubleValue
                } else if let int = key as? Int {
                    ints[int] = number.doubleValue
                } else if let numberKey = key as? NSNumber {
                    ints[numberKey.intValue] = number.doubleValue
                }
            }
            self.integerValue = nil
            self.doubleValue = nil
            self.floatValue = nil
            self.float16Value = nil
            self.stringValue = nil
            self.stringArrayValue = nil
            self.stringDictionaryValue = strings.isEmpty ? nil : strings
            self.integerDictionaryValue = ints.isEmpty ? nil : ints
        case .sequence:
            self.integerValue = nil
            self.doubleValue = nil
            self.floatValue = nil
            self.float16Value = nil
            self.stringValue = nil
            self.stringArrayValue = value.sequenceValue?.stringValues
            self.stringDictionaryValue = nil
            self.integerDictionaryValue = nil
        default:
            return nil
        }
    }

    public init<Scalar>(_ value: MLShapedArray<Scalar>) where Scalar: MLShapedArrayScalar {
        self.type = .multiArray
        self.isUndefined = false
        self.integerValue = nil
        self.doubleValue = nil
        self.floatValue = nil
        self.float16Value = nil
        self.stringValue = nil
        self.stringArrayValue = nil
        self.stringDictionaryValue = nil
        self.integerDictionaryValue = nil
        _ = value
    }

    public func shapedArrayValue<Scalar>(of type: Scalar.Type) -> MLShapedArray<Scalar>? where Scalar: MLShapedArrayScalar {
        nil
    }
}

open class MLDictionaryFeatureProvider: NSObject, MLFeatureProvider, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public private(set) var dictionary: [String: MLFeatureValue]

    public var featureNames: Set<String> { Set(dictionary.keys) }

    public init(dictionary: [String: Any]) throws {
        var converted: [String: MLFeatureValue] = [:]
        for (name, raw) in dictionary {
            converted[name] = try MLDictionaryFeatureProvider.featureValue(from: raw)
        }
        self.dictionary = converted
        super.init()
    }

    public subscript(featureName: String) -> MLFeatureValue? {
        dictionary[featureName]
    }

    public func featureValue(for featureName: String) -> MLFeatureValue? {
        dictionary[featureName]
    }

    public required init?(coder: NSCoder) {
        return nil
    }

    open func encode(with coder: NSCoder) {}

    private static func featureValue(from raw: Any) throws -> MLFeatureValue {
        switch raw {
        case let value as MLFeatureValue:
            return value
        case let value as MLMultiArray:
            return MLFeatureValue(multiArray: value)
        case let value as MLSequence:
            return MLFeatureValue(sequence: value)
        case let value as String:
            return MLFeatureValue(string: value)
        case let value as Int:
            return MLFeatureValue(int64: Int64(value))
        case let value as Int64:
            return MLFeatureValue(int64: value)
        case let value as Double:
            return MLFeatureValue(double: value)
        case let value as Float:
            return MLFeatureValue(double: Double(value))
        case let value as NSNumber:
            let typeEncoding = String(cString: value.objCType)
            if typeEncoding == "f" || typeEncoding == "d" {
                return MLFeatureValue(double: value.doubleValue)
            }
            return MLFeatureValue(int64: value.int64Value)
        default:
            throw coreMLError(.featureType, "Unsupported MLDictionaryFeatureProvider value type.")
        }
    }
}

open class MLArrayBatchProvider: NSObject, MLBatchProvider {
    public private(set) var array: [any MLFeatureProvider]

    public var count: Int { array.count }

    public init(array: [any MLFeatureProvider]) {
        self.array = array
        super.init()
    }

    public convenience init(featureProviderArray array: [any MLFeatureProvider]) {
        self.init(array: array)
    }

    public init(dictionary: [String: [Any]]) throws {
        let lengths = Set(dictionary.values.map(\.count))
        guard lengths.count <= 1 else {
            throw coreMLError(.featureType, "MLArrayBatchProvider dictionary columns must have equal length.")
        }
        let rowCount = dictionary.values.first?.count ?? 0
        var rows: [any MLFeatureProvider] = []
        rows.reserveCapacity(rowCount)
        for row in 0..<rowCount {
            var values: [String: Any] = [:]
            for (name, column) in dictionary {
                values[name] = column[row]
            }
            rows.append(try MLDictionaryFeatureProvider(dictionary: values))
        }
        self.array = rows
        super.init()
    }

    public func features(at index: Int) -> any MLFeatureProvider {
        array[index]
    }
}
