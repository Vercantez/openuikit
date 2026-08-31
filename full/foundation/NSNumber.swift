// Project-owned NSNumber value bridge for the standalone Foundation guest.
// It provides the reference identity and scalar conversion surface used by
// generated Intents code, JSON graphs, animation key times, and framework APIs.

import FoundationEssentials
import ObjectiveC
#if canImport(OpenCoreGraphics)
import OpenCoreGraphics
#endif

open class NSNumber: NSObject, CustomStringConvertible,
    ExpressibleByBooleanLiteral, ExpressibleByIntegerLiteral,
    ExpressibleByFloatLiteral, @unchecked Sendable {
    private enum Storage {
        case boolean(Bool)
        case signed(Int64)
        case unsigned(UInt64)
        case floating(Double)
        case decimal(Decimal)
    }

    private let storage: Storage

    private init(storage: Storage) {
        self.storage = storage
        super.init()
    }

    public convenience required init(booleanLiteral value: Bool) {
        self.init(value: value)
    }

    public convenience required init(integerLiteral value: Int) {
        self.init(value: value)
    }

    public convenience required init(floatLiteral value: Double) {
        self.init(value: value)
    }

    public convenience init(value: Bool) {
        self.init(storage: .boolean(value))
    }

    public convenience init<T: BinaryInteger>(value: T) {
        if T.isSigned {
            self.init(storage: .signed(Int64(clamping: value)))
        } else {
            self.init(storage: .unsigned(UInt64(clamping: value)))
        }
    }

    public convenience init<T: BinaryFloatingPoint>(value: T) {
        self.init(storage: .floating(Double(value)))
    }

    public convenience init(value: Decimal) {
        self.init(storage: .decimal(value))
    }

    open var boolValue: Bool {
        switch storage {
        case .boolean(let value): value
        case .signed(let value): value != 0
        case .unsigned(let value): value != 0
        case .floating(let value): value != 0
        case .decimal(let value): value != .zero
        }
    }

    open var intValue: Int { _signedValue(Int.self) }
    open var integerValue: Int { intValue }
    open var int8Value: Int8 { _signedValue(Int8.self) }
    open var charValue: Int8 { int8Value }
    open var int16Value: Int16 { _signedValue(Int16.self) }
    open var shortValue: Int16 { int16Value }
    open var int32Value: Int32 { _signedValue(Int32.self) }
    open var int64Value: Int64 { _signedValue(Int64.self) }
    open var longValue: Int { intValue }
    open var longLongValue: Int64 { int64Value }

    open var uintValue: UInt { _unsignedValue(UInt.self) }
    open var uint8Value: UInt8 { _unsignedValue(UInt8.self) }
    open var unsignedCharValue: UInt8 { uint8Value }
    open var uint16Value: UInt16 { _unsignedValue(UInt16.self) }
    open var unsignedShortValue: UInt16 { uint16Value }
    open var uint32Value: UInt32 { _unsignedValue(UInt32.self) }
    open var uint64Value: UInt64 { _unsignedValue(UInt64.self) }
    open var unsignedIntegerValue: UInt { uintValue }
    open var unsignedLongValue: UInt { uintValue }
    open var unsignedLongLongValue: UInt64 { uint64Value }

    open var floatValue: Float { Float(doubleValue) }
    open var doubleValue: Double {
        switch storage {
        case .boolean(let value): value ? 1 : 0
        case .signed(let value): Double(value)
        case .unsigned(let value): Double(value)
        case .floating(let value): value
        case .decimal(let value): Double(String(describing: value)) ?? 0
        }
    }

    open var decimalValue: Decimal {
        switch storage {
        case .boolean(let value): Decimal(value ? 1 : 0)
        case .signed(let value): Decimal(value)
        case .unsigned(let value): Decimal(value)
        case .floating(let value): Decimal(value)
        case .decimal(let value): value
        }
    }

    open var stringValue: String {
        switch storage {
        case .boolean(let value): return value ? "1" : "0"
        case .signed(let value): return String(value)
        case .unsigned(let value): return String(value)
        case .floating(let value):
            if value.isFinite,
               value.rounded(.towardZero) == value,
               value >= Double(Int64.min), value < Double(Int64.max) {
                return String(Int64(value))
            }
            return String(value)
        case .decimal(let value): return String(describing: value)
        }
    }

    open func compare(_ otherNumber: NSNumber) -> ComparisonResult {
        if _numericEqual(otherNumber) { return .orderedSame }
        return doubleValue < otherNumber.doubleValue
            ? .orderedAscending
            : .orderedDescending
    }

    open func isEqual(to number: NSNumber) -> Bool {
        _numericEqual(number)
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let number = object as? NSNumber else { return false }
        return _numericEqual(number)
    }

    open override var hash: Int {
        var hasher = Hasher()
        if doubleValue == 0 { hasher.combine(0.0) }
        else { hasher.combine(doubleValue) }
        return hasher.finalize()
    }

    open var description: String { stringValue }

    internal var _foundationGuestIsBoolean: Bool {
        if case .boolean = storage { return true }
        return false
    }

    internal var _foundationGuestIsFloatingPoint: Bool {
        switch storage {
        case .floating, .decimal: true
        default: false
        }
    }

    internal var _foundationGuestIsUnsigned: Bool {
        if case .unsigned = storage { return true }
        return false
    }

    internal func _foundationGuestExactInteger<T: FixedWidthInteger>(
        _ type: T.Type
    ) -> T? {
        switch storage {
        case .boolean(let value): return T(exactly: value ? 1 : 0)
        case .signed(let value): return T(exactly: value)
        case .unsigned(let value): return T(exactly: value)
        case .floating(let value): return T(exactly: value)
        case .decimal: return T(exactly: doubleValue)
        }
    }

    internal func _foundationGuestExactFloating<T: BinaryFloatingPoint>(
        _ type: T.Type
    ) -> T? {
        T(exactly: doubleValue)
    }

    internal var _foundationGuestExactBool: Bool? {
        switch storage {
        case .boolean(let value): return value
        default:
            if doubleValue == 0 { return false }
            if doubleValue == 1 { return true }
            return nil
        }
    }

    private func _numericEqual(_ other: NSNumber) -> Bool {
        switch (storage, other.storage) {
        case (.signed(let lhs), .signed(let rhs)): return lhs == rhs
        case (.unsigned(let lhs), .unsigned(let rhs)): return lhs == rhs
        case (.signed(let lhs), .unsigned(let rhs)):
            return lhs >= 0 && UInt64(lhs) == rhs
        case (.unsigned(let lhs), .signed(let rhs)):
            return rhs >= 0 && lhs == UInt64(rhs)
        case (.boolean(let lhs), .boolean(let rhs)): return lhs == rhs
        default: return doubleValue == other.doubleValue
        }
    }

    private func _signedValue<T: FixedWidthInteger>(_ type: T.Type) -> T {
        switch storage {
        case .boolean(let value): return value ? 1 : 0
        case .signed(let value): return T(truncatingIfNeeded: value)
        case .unsigned(let value): return T(truncatingIfNeeded: value)
        case .floating(let value): return _clampedFloating(value, as: type)
        case .decimal: return _clampedFloating(doubleValue, as: type)
        }
    }

    private func _unsignedValue<T: FixedWidthInteger & UnsignedInteger>(
        _ type: T.Type
    ) -> T {
        switch storage {
        case .boolean(let value): return value ? 1 : 0
        case .signed(let value): return T(truncatingIfNeeded: value)
        case .unsigned(let value): return T(truncatingIfNeeded: value)
        case .floating(let value): return _unsignedValueFromDouble(value, as: type)
        case .decimal: return _unsignedValueFromDouble(doubleValue, as: type)
        }
    }

    private func _unsignedValueFromDouble<T: FixedWidthInteger & UnsignedInteger>(
        _ value: Double,
        as type: T.Type
    ) -> T {
        if value.isNaN { return 0 }
        if value == -.infinity { return 0 }
        if value < 0 {
            if value.rounded(.towardZero) == value,
               value >= Double(Int64.min) {
                return T(truncatingIfNeeded: Int64(value))
            }
            return T.max
        }
        if value >= Double(T.max) { return T.max }
        return T(value)
    }

    private func _clampedFloating<T: FixedWidthInteger>(
        _ value: Double,
        as type: T.Type
    ) -> T {
        if value.isNaN { return 0 }
        if value <= Double(T.min) { return T.min }
        if value >= Double(T.max) { return T.max }
        return T(value)
    }
}

// MARK: - Swift numeric bridging

extension Int8: _ObjectiveCBridgeable {
    public typealias _ObjectiveCType = NSNumber
    @available(swift, deprecated: 4, renamed: "init(truncating:)")
    public init(_ number: NSNumber) { self.init(truncating: number) }
    public init(truncating number: NSNumber) { self = number.int8Value }
    public init?(exactly number: NSNumber) {
        guard let value = number._foundationGuestExactInteger(Self.self) else { return nil }
        self = value
    }
    @_semantics("convertToObjectiveC") public func _bridgeToObjectiveC() -> NSNumber { NSNumber(value: self) }
    public static func _forceBridgeFromObjectiveC(_ x: NSNumber, result: inout Int8?) { result = Int8(exactly: x)! }
    public static func _conditionallyBridgeFromObjectiveC(_ x: NSNumber, result: inout Int8?) -> Bool { result = Int8(exactly: x); return result != nil }
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSNumber?) -> Int8 { source.map { Int8(truncating: $0) } ?? 0 }
}

extension UInt8: _ObjectiveCBridgeable {
    public typealias _ObjectiveCType = NSNumber
    @available(swift, deprecated: 4, renamed: "init(truncating:)")
    public init(_ number: NSNumber) { self.init(truncating: number) }
    public init(truncating number: NSNumber) { self = number.uint8Value }
    public init?(exactly number: NSNumber) { guard let value = number._foundationGuestExactInteger(Self.self) else { return nil }; self = value }
    @_semantics("convertToObjectiveC") public func _bridgeToObjectiveC() -> NSNumber { NSNumber(value: self) }
    public static func _forceBridgeFromObjectiveC(_ x: NSNumber, result: inout UInt8?) { result = UInt8(exactly: x)! }
    public static func _conditionallyBridgeFromObjectiveC(_ x: NSNumber, result: inout UInt8?) -> Bool { result = UInt8(exactly: x); return result != nil }
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSNumber?) -> UInt8 { source.map { UInt8(truncating: $0) } ?? 0 }
}

extension Int16: _ObjectiveCBridgeable {
    public typealias _ObjectiveCType = NSNumber
    @available(swift, deprecated: 4, renamed: "init(truncating:)")
    public init(_ number: NSNumber) { self.init(truncating: number) }
    public init(truncating number: NSNumber) { self = number.int16Value }
    public init?(exactly number: NSNumber) { guard let value = number._foundationGuestExactInteger(Self.self) else { return nil }; self = value }
    @_semantics("convertToObjectiveC") public func _bridgeToObjectiveC() -> NSNumber { NSNumber(value: self) }
    public static func _forceBridgeFromObjectiveC(_ x: NSNumber, result: inout Int16?) { result = Int16(exactly: x)! }
    public static func _conditionallyBridgeFromObjectiveC(_ x: NSNumber, result: inout Int16?) -> Bool { result = Int16(exactly: x); return result != nil }
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSNumber?) -> Int16 { source.map { Int16(truncating: $0) } ?? 0 }
}

extension UInt16: _ObjectiveCBridgeable {
    public typealias _ObjectiveCType = NSNumber
    @available(swift, deprecated: 4, renamed: "init(truncating:)")
    public init(_ number: NSNumber) { self.init(truncating: number) }
    public init(truncating number: NSNumber) { self = number.uint16Value }
    public init?(exactly number: NSNumber) { guard let value = number._foundationGuestExactInteger(Self.self) else { return nil }; self = value }
    @_semantics("convertToObjectiveC") public func _bridgeToObjectiveC() -> NSNumber { NSNumber(value: self) }
    public static func _forceBridgeFromObjectiveC(_ x: NSNumber, result: inout UInt16?) { result = UInt16(exactly: x)! }
    public static func _conditionallyBridgeFromObjectiveC(_ x: NSNumber, result: inout UInt16?) -> Bool { result = UInt16(exactly: x); return result != nil }
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSNumber?) -> UInt16 { source.map { UInt16(truncating: $0) } ?? 0 }
}

extension Int32: _ObjectiveCBridgeable {
    public typealias _ObjectiveCType = NSNumber
    @available(swift, deprecated: 4, renamed: "init(truncating:)")
    public init(_ number: NSNumber) { self.init(truncating: number) }
    public init(truncating number: NSNumber) { self = number.int32Value }
    public init?(exactly number: NSNumber) { guard let value = number._foundationGuestExactInteger(Self.self) else { return nil }; self = value }
    @_semantics("convertToObjectiveC") public func _bridgeToObjectiveC() -> NSNumber { NSNumber(value: self) }
    public static func _forceBridgeFromObjectiveC(_ x: NSNumber, result: inout Int32?) { result = Int32(exactly: x)! }
    public static func _conditionallyBridgeFromObjectiveC(_ x: NSNumber, result: inout Int32?) -> Bool { result = Int32(exactly: x); return result != nil }
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSNumber?) -> Int32 { source.map { Int32(truncating: $0) } ?? 0 }
}

extension UInt32: _ObjectiveCBridgeable {
    public typealias _ObjectiveCType = NSNumber
    @available(swift, deprecated: 4, renamed: "init(truncating:)")
    public init(_ number: NSNumber) { self.init(truncating: number) }
    public init(truncating number: NSNumber) { self = number.uint32Value }
    public init?(exactly number: NSNumber) { guard let value = number._foundationGuestExactInteger(Self.self) else { return nil }; self = value }
    @_semantics("convertToObjectiveC") public func _bridgeToObjectiveC() -> NSNumber { NSNumber(value: self) }
    public static func _forceBridgeFromObjectiveC(_ x: NSNumber, result: inout UInt32?) { result = UInt32(exactly: x)! }
    public static func _conditionallyBridgeFromObjectiveC(_ x: NSNumber, result: inout UInt32?) -> Bool { result = UInt32(exactly: x); return result != nil }
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSNumber?) -> UInt32 { source.map { UInt32(truncating: $0) } ?? 0 }
}

extension Int64: _ObjectiveCBridgeable {
    public typealias _ObjectiveCType = NSNumber
    @available(swift, deprecated: 4, renamed: "init(truncating:)")
    public init(_ number: NSNumber) { self.init(truncating: number) }
    public init(truncating number: NSNumber) { self = number.int64Value }
    public init?(exactly number: NSNumber) { guard let value = number._foundationGuestExactInteger(Self.self) else { return nil }; self = value }
    @_semantics("convertToObjectiveC") public func _bridgeToObjectiveC() -> NSNumber { NSNumber(value: self) }
    public static func _forceBridgeFromObjectiveC(_ x: NSNumber, result: inout Int64?) { result = Int64(exactly: x)! }
    public static func _conditionallyBridgeFromObjectiveC(_ x: NSNumber, result: inout Int64?) -> Bool { result = Int64(exactly: x); return result != nil }
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSNumber?) -> Int64 { source?.int64Value ?? 0 }
}

extension UInt64: _ObjectiveCBridgeable {
    public typealias _ObjectiveCType = NSNumber
    @available(swift, deprecated: 4, renamed: "init(truncating:)")
    public init(_ number: NSNumber) { self.init(truncating: number) }
    public init(truncating number: NSNumber) { self = number.uint64Value }
    public init?(exactly number: NSNumber) { guard let value = number._foundationGuestExactInteger(Self.self) else { return nil }; self = value }
    @_semantics("convertToObjectiveC") public func _bridgeToObjectiveC() -> NSNumber { NSNumber(value: self) }
    public static func _forceBridgeFromObjectiveC(_ x: NSNumber, result: inout UInt64?) { result = UInt64(exactly: x)! }
    public static func _conditionallyBridgeFromObjectiveC(_ x: NSNumber, result: inout UInt64?) -> Bool { result = UInt64(exactly: x); return result != nil }
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSNumber?) -> UInt64 { source?.uint64Value ?? 0 }
}

extension Int: _ObjectiveCBridgeable {
    public typealias _ObjectiveCType = NSNumber
    @available(swift, deprecated: 4, renamed: "init(truncating:)")
    public init(_ number: NSNumber) { self.init(truncating: number) }
    public init(truncating number: NSNumber) { self = number.intValue }
    public init?(exactly number: NSNumber) { guard let value = number._foundationGuestExactInteger(Self.self) else { return nil }; self = value }
    @_semantics("convertToObjectiveC") public func _bridgeToObjectiveC() -> NSNumber { NSNumber(value: self) }
    public static func _forceBridgeFromObjectiveC(_ x: NSNumber, result: inout Int?) { result = Int(exactly: x)! }
    public static func _conditionallyBridgeFromObjectiveC(_ x: NSNumber, result: inout Int?) -> Bool { result = Int(exactly: x); return result != nil }
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSNumber?) -> Int { source?.intValue ?? 0 }
}

extension UInt: _ObjectiveCBridgeable {
    public typealias _ObjectiveCType = NSNumber
    @available(swift, deprecated: 4, renamed: "init(truncating:)")
    public init(_ number: NSNumber) { self.init(truncating: number) }
    public init(truncating number: NSNumber) { self = number.uintValue }
    public init?(exactly number: NSNumber) { guard let value = number._foundationGuestExactInteger(Self.self) else { return nil }; self = value }
    @_semantics("convertToObjectiveC") public func _bridgeToObjectiveC() -> NSNumber { NSNumber(value: self) }
    public static func _forceBridgeFromObjectiveC(_ x: NSNumber, result: inout UInt?) { result = UInt(exactly: x)! }
    public static func _conditionallyBridgeFromObjectiveC(_ x: NSNumber, result: inout UInt?) -> Bool { result = UInt(exactly: x); return result != nil }
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSNumber?) -> UInt { source?.uintValue ?? 0 }
}

extension Float: _ObjectiveCBridgeable {
    public typealias _ObjectiveCType = NSNumber
    @available(swift, deprecated: 4, renamed: "init(truncating:)")
    public init(_ number: NSNumber) { self.init(truncating: number) }
    public init(truncating number: NSNumber) { self = number.floatValue }
    public init?(exactly number: NSNumber) { guard let value = number._foundationGuestExactFloating(Self.self) else { return nil }; self = value }
    @_semantics("convertToObjectiveC") public func _bridgeToObjectiveC() -> NSNumber { NSNumber(value: self) }
    public static func _forceBridgeFromObjectiveC(_ x: NSNumber, result: inout Float?) { result = Float(exactly: x)! }
    public static func _conditionallyBridgeFromObjectiveC(_ x: NSNumber, result: inout Float?) -> Bool { result = Float(exactly: x); return result != nil }
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSNumber?) -> Float { source?.floatValue ?? 0 }
}

extension Double: _ObjectiveCBridgeable {
    public typealias _ObjectiveCType = NSNumber
    @available(swift, deprecated: 4, renamed: "init(truncating:)")
    public init(_ number: NSNumber) { self.init(truncating: number) }
    public init(truncating number: NSNumber) { self = number.doubleValue }
    public init?(exactly number: NSNumber) { guard let value = number._foundationGuestExactFloating(Self.self) else { return nil }; self = value }
    @_semantics("convertToObjectiveC") public func _bridgeToObjectiveC() -> NSNumber { NSNumber(value: self) }
    public static func _forceBridgeFromObjectiveC(_ x: NSNumber, result: inout Double?) { result = Double(exactly: x)! }
    public static func _conditionallyBridgeFromObjectiveC(_ x: NSNumber, result: inout Double?) -> Bool { result = Double(exactly: x); return result != nil }
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSNumber?) -> Double { source?.doubleValue ?? 0 }
}

// CGFloat is a distinct CoreFoundation value type even on 64-bit Darwin; it
// is not a typealias for Double.  Apple's Foundation overlay supplies this
// bridge.  The guest overlay must do the same so unchanged UIKit and
// QuartzCore clients can use ordinary `value as NSNumber` coercions.
#if canImport(OpenCoreGraphics)
extension CGFloat: _ObjectiveCBridgeable {
    public typealias _ObjectiveCType = NSNumber
    @available(swift, deprecated: 4, renamed: "init(truncating:)")
    public init(_ number: NSNumber) { self.init(truncating: number) }
    public init(truncating number: NSNumber) { self.init(number.doubleValue) }
    public init?(exactly number: NSNumber) {
        guard let value = number._foundationGuestExactFloating(Self.self) else {
            return nil
        }
        self = value
    }
    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSNumber { NSNumber(value: self) }
    public static func _forceBridgeFromObjectiveC(
        _ x: NSNumber,
        result: inout CGFloat?
    ) {
        result = CGFloat(exactly: x)!
    }
    public static func _conditionallyBridgeFromObjectiveC(
        _ x: NSNumber,
        result: inout CGFloat?
    ) -> Bool {
        result = CGFloat(exactly: x)
        return result != nil
    }
    public static func _unconditionallyBridgeFromObjectiveC(
        _ source: NSNumber?
    ) -> CGFloat {
        CGFloat(source?.doubleValue ?? 0)
    }
}
#endif

extension Bool: _ObjectiveCBridgeable {
    public typealias _ObjectiveCType = NSNumber
    @available(swift, deprecated: 4, renamed: "init(truncating:)")
    public init(_ number: NSNumber) { self.init(truncating: number) }
    public init(truncating number: NSNumber) { self = number.boolValue }
    public init?(exactly number: NSNumber) { guard let value = number._foundationGuestExactBool else { return nil }; self = value }
    @_semantics("convertToObjectiveC") public func _bridgeToObjectiveC() -> NSNumber { NSNumber(value: self) }
    public static func _forceBridgeFromObjectiveC(_ x: NSNumber, result: inout Bool?) { result = Bool(exactly: x)! }
    public static func _conditionallyBridgeFromObjectiveC(_ x: NSNumber, result: inout Bool?) -> Bool { result = Bool(exactly: x); return result != nil }
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSNumber?) -> Bool { source?.boolValue ?? false }
}
