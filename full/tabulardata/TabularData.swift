@_exported import Foundation

/// Linux starting point for Apple's public `TabularData` module.
///
/// Value types, CSV/JSON parsing, column arithmetic, grouping, and joins are
/// implemented here. Turi Create SFrame archives and Combine
/// `TopLevelEncoder` / `TopLevelDecoder` paths are fail-closed: those Apple
/// services are not present on the isolated Linux host.
public enum TabularDataModule {
    public static let linuxStartingPoint = "TabularData"
}

struct TabularSeededGenerator: RandomNumberGenerator {
    var state: UInt64

    init(seed: Int) {
        let raw = UInt64(bitPattern: Int64(seed))
        state = raw == 0 ? 0x9E37_79B9_7F4A_7C15 : raw
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z &>> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z &>> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z &>> 31)
    }
}

func tabularValuesEqual(_ lhs: Any?, _ rhs: Any?) -> Bool {
    switch (lhs, rhs) {
    case (nil, nil):
        return true
    case (nil, _), (_, nil):
        return false
    default:
        break
    }
    if let a = lhs as? String, let b = rhs as? String { return a == b }
    if let a = lhs as? Bool, let b = rhs as? Bool { return a == b }
    if let a = lhs as? Int, let b = rhs as? Int { return a == b }
    if let a = lhs as? Int64, let b = rhs as? Int64 { return a == b }
    if let a = lhs as? Double, let b = rhs as? Double { return a == b }
    if let a = lhs as? Float, let b = rhs as? Float { return a == b }
    if let a = lhs as? Date, let b = rhs as? Date { return a == b }
    if let a = lhs as? Data, let b = rhs as? Data { return a == b }
    if let a = lhs as? Decimal, let b = rhs as? Decimal { return a == b }
    return String(describing: lhs!) == String(describing: rhs!)
}

func tabularHash(_ value: Any?, into hasher: inout Hasher) {
    guard let value else {
        hasher.combine(0)
        return
    }
    hasher.combine(ObjectIdentifier(type(of: value)))
    switch value {
    case let v as String: hasher.combine(v)
    case let v as Bool: hasher.combine(v)
    case let v as Int: hasher.combine(v)
    case let v as Int64: hasher.combine(v)
    case let v as Double: hasher.combine(v)
    case let v as Float: hasher.combine(v)
    case let v as Date: hasher.combine(v)
    case let v as Data: hasher.combine(v)
    default: hasher.combine(String(describing: value))
    }
}

func tabularDisplay(_ value: Any?, options: FormattingOptions) -> String {
    guard let value else { return "<nil>" }
    switch value {
    case let v as String:
        return v
    case let v as Bool:
        return v ? "true" : "false"
    case let v as Int:
        return v.formatted(options.integerFormatStyle)
    case let v as Double:
        return v.formatted(options.floatingPointFormatStyle)
    case let v as Float:
        return Double(v).formatted(options.floatingPointFormatStyle)
    case let v as Date:
        return v.formatted(options.dateFormatStyle)
    case let v as Data:
        return "<\(v.count) bytes>"
    default:
        return String(describing: value)
    }
}

func tabularCSVType(of type: Any.Type) -> CSVType? {
    if type == Int.self || type == Int8.self || type == Int16.self
        || type == Int32.self || type == Int64.self
        || type == UInt.self || type == UInt8.self || type == UInt16.self
        || type == UInt32.self || type == UInt64.self
    {
        return .integer
    }
    if type == Double.self { return .double }
    if type == Float.self { return .float }
    if type == Bool.self { return .boolean }
    if type == String.self { return .string }
    if type == Date.self { return .date }
    if type == Data.self { return .data }
    return nil
}

func tabularJSONType(of type: Any.Type) -> JSONType? {
    if type == Int.self || type == Int64.self { return .integer }
    if type == Double.self || type == Float.self { return .double }
    if type == Bool.self { return .boolean }
    if type == String.self { return .string }
    if type == Date.self { return .date }
    if type == [Any].self { return .array }
    return nil
}
