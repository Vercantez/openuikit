// Project-owned JSONSerialization facade built on FoundationEssentials'
// production JSON encoder/decoder. It accepts and returns the heterogeneous
// Swift object graphs used by Foundation clients; no transport or app-specific
// schema is embedded here.

import FoundationEssentials

public let NSJSONSerializationErrorIndex = "NSJSONSerializationErrorIndex"

open class JSONSerialization {
    public struct ReadingOptions: OptionSet, Sendable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }

        public static let mutableContainers = ReadingOptions(rawValue: 1 << 0)
        public static let mutableLeaves = ReadingOptions(rawValue: 1 << 1)
        public static let fragmentsAllowed = ReadingOptions(rawValue: 1 << 2)
        @available(*, deprecated, renamed: "fragmentsAllowed")
        public static let allowFragments = ReadingOptions.fragmentsAllowed
    }

    public struct WritingOptions: OptionSet, Sendable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }

        public static let prettyPrinted = WritingOptions(rawValue: 1 << 0)
        public static let sortedKeys = WritingOptions(rawValue: 1 << 1)
        public static let fragmentsAllowed = WritingOptions(rawValue: 1 << 2)
        public static let withoutEscapingSlashes = WritingOptions(rawValue: 1 << 3)
    }

    open class func isValidJSONObject(_ obj: Any) -> Bool {
        guard obj is [Any] || obj is [String: Any] || obj is [AnyHashable: Any]
        else { return false }
        return _foundationGuestJSONValue(obj) != nil
    }

    open class func jsonObject(
        with data: Data,
        options opt: ReadingOptions = []
    ) throws -> Any {
        do {
            let value = try JSONDecoder().decode(_FoundationGuestJSONValue.self, from: data)
            if !opt.contains(.fragmentsAllowed), !value.isContainer {
                throw _foundationGuestJSONError(
                    "JSON text did not start with array or object and option to allow fragments not set."
                )
            }
            // Swift arrays and dictionaries are mutable value containers after
            // a caller casts them to `var`. This supplies the exact corpus call
            // shape for mutableContainers/mutableLeaves without inventing an
            // incompatible parallel NSMutableDictionary identity.
            return value.foundationValue
        } catch let error as NSError {
            throw error
        } catch {
            throw _foundationGuestJSONError(
                "The data is not in the correct format.",
                underlying: error
            )
        }
    }

    open class func data(
        withJSONObject obj: Any,
        options opt: WritingOptions = []
    ) throws -> Data {
        guard let value = _foundationGuestJSONValue(obj) else {
            throw _foundationGuestJSONError("Invalid object cannot be serialized to JSON.")
        }
        guard opt.contains(.fragmentsAllowed) || value.isContainer else {
            throw _foundationGuestJSONError(
                "Top-level object was not array or dictionary and fragments option was not set."
            )
        }

        let encoder = JSONEncoder()
        var formatting: JSONEncoder.OutputFormatting = []
        if opt.contains(.prettyPrinted) { formatting.insert(.prettyPrinted) }
        if opt.contains(.sortedKeys) { formatting.insert(.sortedKeys) }
        if opt.contains(.withoutEscapingSlashes) {
            formatting.insert(.withoutEscapingSlashes)
        }
        encoder.outputFormatting = formatting
        do {
            return try encoder.encode(value)
        } catch {
            throw _foundationGuestJSONError(
                "Invalid object cannot be serialized to JSON.",
                underlying: error
            )
        }
    }
}

private enum _FoundationGuestJSONValue: Codable {
    case null
    case bool(Bool)
    case integer(Int64)
    case unsignedInteger(UInt64)
    case number(Double)
    case string(String)
    case array([_FoundationGuestJSONValue])
    case object([String: _FoundationGuestJSONValue])

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self = .null; return }
        if let value = try? container.decode(Bool.self) {
            self = .bool(value); return
        }
        if let value = try? container.decode(Int64.self) {
            self = .integer(value); return
        }
        if let value = try? container.decode(UInt64.self) {
            self = .unsignedInteger(value); return
        }
        if let value = try? container.decode(Double.self), value.isFinite {
            self = .number(value); return
        }
        if let value = try? container.decode(String.self) {
            self = .string(value); return
        }
        if let value = try? container.decode([_FoundationGuestJSONValue].self) {
            self = .array(value); return
        }
        if let value = try? container.decode([String: _FoundationGuestJSONValue].self) {
            self = .object(value); return
        }
        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Unsupported JSON value"
        )
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null: try container.encodeNil()
        case .bool(let value): try container.encode(value)
        case .integer(let value): try container.encode(value)
        case .unsignedInteger(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .string(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        }
    }

    var isContainer: Bool {
        switch self {
        case .array, .object: true
        default: false
        }
    }

    var foundationValue: Any {
        switch self {
        case .null:
            return NSNull()
        case .bool(let value):
            return NSNumber(value: value)
        case .integer(let value):
            return NSNumber(value: value)
        case .unsignedInteger(let value):
            return NSNumber(value: value)
        case .number(let value):
            return NSNumber(value: value)
        case .string(let value):
            return value
        case .array(let values):
            return values.map(\.foundationValue)
        case .object(let values):
            return values.mapValues(\.foundationValue)
        }
    }
}

private func _foundationGuestJSONValue(_ value: Any) -> _FoundationGuestJSONValue? {
    if value is NSNull { return .null }
    if let value = value as? NSNumber {
        if value._foundationGuestIsBoolean { return .bool(value.boolValue) }
        if value._foundationGuestIsFloatingPoint {
            let number = value.doubleValue
            return number.isFinite ? .number(number) : nil
        }
        if value._foundationGuestIsUnsigned {
            return .unsignedInteger(value.uint64Value)
        }
        return .integer(value.int64Value)
    }
    if let value = value as? Bool { return .bool(value) }
    if let value = value as? Int { return .integer(Int64(value)) }
    if let value = value as? Int8 { return .integer(Int64(value)) }
    if let value = value as? Int16 { return .integer(Int64(value)) }
    if let value = value as? Int32 { return .integer(Int64(value)) }
    if let value = value as? Int64 { return .integer(value) }
    if let value = value as? UInt { return .unsignedInteger(UInt64(value)) }
    if let value = value as? UInt8 { return .unsignedInteger(UInt64(value)) }
    if let value = value as? UInt16 { return .unsignedInteger(UInt64(value)) }
    if let value = value as? UInt32 { return .unsignedInteger(UInt64(value)) }
    if let value = value as? UInt64 { return .unsignedInteger(value) }
    if let value = value as? Float, value.isFinite { return .number(Double(value)) }
    if let value = value as? Double, value.isFinite { return .number(value) }
    if let value = value as? String { return .string(value) }
    if let value = value as? [Any] {
        var result: [_FoundationGuestJSONValue] = []
        result.reserveCapacity(value.count)
        for element in value {
            guard let element = _foundationGuestJSONValue(element) else { return nil }
            result.append(element)
        }
        return .array(result)
    }
    if let value = value as? [String: Any] {
        var result: [String: _FoundationGuestJSONValue] = [:]
        result.reserveCapacity(value.count)
        for (key, element) in value {
            guard let element = _foundationGuestJSONValue(element) else { return nil }
            result[key] = element
        }
        return .object(result)
    }
    if let value = value as? [AnyHashable: Any] {
        var result: [String: _FoundationGuestJSONValue] = [:]
        result.reserveCapacity(value.count)
        for (key, element) in value {
            guard let key = key.base as? String,
                  let element = _foundationGuestJSONValue(element) else { return nil }
            result[key] = element
        }
        return .object(result)
    }
    return nil
}

private func _foundationGuestJSONError(
    _ debugDescription: String,
    underlying: (any Error)? = nil
) -> NSError {
    var userInfo: [String: Any] = [NSDebugDescriptionErrorKey: debugDescription]
    if let underlying { userInfo[NSUnderlyingErrorKey] = underlying }
    return NSError(
        domain: NSCocoaErrorDomain,
        code: NSPropertyListReadCorruptError,
        userInfo: userInfo
    )
}
