// NSUUID, NSDecimalNumber (+ NSDecimalNumberHandler), NSCharacterSet and
// NSException for the Linux-hosted Mach-O guest: the remaining Foundation
// class names of full/ladder/APP_LADDER.md §9.5's ABSENT list
// (docs/agent_reports/guest-swift-modules.md). Each is the reference-type
// face of a FoundationEssentials value (UUID, Decimal, CharacterSet) or a
// plain record (NSException); the Swift facade owns them, and
// guest-objc-foundation's headers bind to their runtime names.
//
// Contract measured on the iOS 26.1 simulator by
// uikit/Tools/oracle2/guestnamesprobe (transcript-ios26.1.txt), which the guest
// runs unchanged (uikit/Tools/guestprobes/GuestNamesProbe.probe.sh).
// NSException.raise() cannot unwind on the guest (no Objective-C exception
// unwinder under machorun): it reports the exception and traps, which is
// what an uncaught NSException does on iOS.

@_spi(SwiftCorelibsFoundation) import FoundationEssentials
import ObjectiveC

// MARK: - NSUUID

open class NSUUID: NSObject, NSCopying, @unchecked Sendable {
    fileprivate let _value: UUID

    public override init() {
        _value = UUID()
        super.init()
    }

    public init?(uuidString string: String) {
        guard let value = UUID(uuidString: string) else { return nil }
        _value = value
        super.init()
    }

    public init(uuidBytes bytes: UnsafePointer<UInt8>?) {
        guard let bytes else {
            _value = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
            super.init()
            return
        }
        _value = UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5],
                             bytes[6], bytes[7], bytes[8], bytes[9], bytes[10], bytes[11],
                             bytes[12], bytes[13], bytes[14], bytes[15]))
        super.init()
    }

    fileprivate init(_ value: UUID) {
        _value = value
        super.init()
    }

    open var uuidString: String { _value.uuidString }

    open func getBytes(_ uuid: UnsafeMutablePointer<UInt8>) {
        withUnsafeBytes(of: _value.uuid) { raw in
            for index in 0..<16 { uuid[index] = raw[index] }
        }
    }

    open override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? NSUUID { return other._value == _value }
        if let other = object as? UUID { return other == _value }
        return false
    }

    open override var hash: Int { _value.hashValue }

    open func copy(with zone: NSZone? = nil) -> Any { self }
}

extension UUID: _ObjectiveCBridgeable {
    public typealias _ObjectiveCType = NSUUID
    public func _bridgeToObjectiveC() -> NSUUID { NSUUID(self) }
    public static func _forceBridgeFromObjectiveC(_ source: NSUUID, result: inout UUID?) {
        result = source._value
    }
    public static func _conditionallyBridgeFromObjectiveC(_ source: NSUUID, result: inout UUID?) -> Bool {
        result = source._value
        return true
    }
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSUUID?) -> UUID {
        source?._value ?? UUID()
    }
}

// MARK: - NSDecimalNumber

public protocol NSDecimalNumberBehaviors {
    func roundingMode() -> NSDecimalNumber.RoundingMode
    func scale() -> Int16
}

open class NSDecimalNumber: NSNumber, @unchecked Sendable {
    public typealias RoundingMode = Decimal.RoundingMode
    public typealias CalculationError = Decimal.CalculationError

    public let _decimal: Decimal

    public init(decimal dcm: Decimal) {
        _decimal = dcm
        super.init(_guestDecimalNumber: dcm)
    }

    public required convenience init(booleanLiteral value: Bool) {
        self.init(decimal: value ? 1 : 0)
    }

    public required convenience init(integerLiteral value: Int) {
        self.init(decimal: Decimal(value))
    }

    public required convenience init(floatLiteral value: Double) {
        self.init(decimal: Decimal(value))
    }

    public convenience init(mantissa: UInt64, exponent: Int16, isNegative flag: Bool) {
        self.init(decimal: Decimal(mantissa: mantissa, exponent: exponent, isNegative: flag))
    }

    /// Parses the longest decimal prefix (like `Decimal(string:)`); no
    /// digits at all is NaN (measured "abc" → "NaN").
    public convenience init(string numberValue: String?) {
        self.init(string: numberValue, locale: nil)
    }

    public convenience init(string numberValue: String?, locale: Any?) {
        let locale = locale as? Locale
        let parsed = numberValue.flatMap { Decimal(string: $0, locale: locale) }
        self.init(decimal: parsed ?? .nan)
    }

    public convenience init(value: Int) { self.init(decimal: Decimal(value)) }
    public convenience init(value: Double) { self.init(decimal: Decimal(value)) }

    open override var decimalValue: Decimal { _decimal }

    open override var doubleValue: Double { _decimal._doubleValue }
    open override var intValue: Int { Int(truncatingIfNeeded: _decimal._int64Value) }
    open override var int64Value: Int64 { _decimal._int64Value }

    open override var description: String { stringValue }
    open override var stringValue: String { _decimal.description }

    open func description(withLocale locale: Any?) -> String {
        _decimal.toString(with: locale as? Locale)
    }

    public class var zero: NSDecimalNumber { NSDecimalNumber(decimal: 0) }
    public class var one: NSDecimalNumber { NSDecimalNumber(decimal: 1) }
    public class var notANumber: NSDecimalNumber { NSDecimalNumber(decimal: .nan) }
    public class var maximum: NSDecimalNumber { NSDecimalNumber(decimal: .greatestFiniteMagnitude) }
    public class var minimum: NSDecimalNumber { NSDecimalNumber(decimal: .leastFiniteMagnitude) }

    nonisolated(unsafe) public static var defaultBehavior: any NSDecimalNumberBehaviors =
        NSDecimalNumberHandler.default

    private func _apply(
        _ other: Decimal, _ behavior: (any NSDecimalNumberBehaviors)?,
        _ op: (UnsafeMutablePointer<Decimal>, UnsafePointer<Decimal>, UnsafePointer<Decimal>, RoundingMode) -> CalculationError
    ) -> NSDecimalNumber {
        let behavior = behavior ?? NSDecimalNumber.defaultBehavior
        var result = Decimal()
        var lhs = _decimal, rhs = other
        let error = op(&result, &lhs, &rhs, behavior.roundingMode())
        return NSDecimalNumber._finish(result, error, behavior)
    }

    fileprivate static func _finish(
        _ value: Decimal, _ error: CalculationError, _ behavior: any NSDecimalNumberBehaviors
    ) -> NSDecimalNumber {
        if error != .noError, let handler = behavior as? NSDecimalNumberHandler,
           let replacement = handler._exceptionResult(error) {
            return replacement
        }
        var value = value
        let scale = behavior.scale()
        if scale != Int16.max {
            var rounded = Decimal()
            _NSDecimalRound(&rounded, &value, Int(scale), behavior.roundingMode())
            value = rounded
        }
        return NSDecimalNumber(decimal: value)
    }

    open func adding(_ decimalNumber: NSDecimalNumber) -> NSDecimalNumber {
        adding(decimalNumber, withBehavior: nil)
    }
    open func adding(_ decimalNumber: NSDecimalNumber, withBehavior behavior: (any NSDecimalNumberBehaviors)?) -> NSDecimalNumber {
        _apply(decimalNumber._decimal, behavior, _NSDecimalAdd)
    }
    open func subtracting(_ decimalNumber: NSDecimalNumber) -> NSDecimalNumber {
        subtracting(decimalNumber, withBehavior: nil)
    }
    open func subtracting(_ decimalNumber: NSDecimalNumber, withBehavior behavior: (any NSDecimalNumberBehaviors)?) -> NSDecimalNumber {
        _apply(decimalNumber._decimal, behavior, _NSDecimalSubtract)
    }
    open func multiplying(by decimalNumber: NSDecimalNumber) -> NSDecimalNumber {
        multiplying(by: decimalNumber, withBehavior: nil)
    }
    open func multiplying(by decimalNumber: NSDecimalNumber, withBehavior behavior: (any NSDecimalNumberBehaviors)?) -> NSDecimalNumber {
        _apply(decimalNumber._decimal, behavior, _NSDecimalMultiply)
    }
    open func dividing(by decimalNumber: NSDecimalNumber) -> NSDecimalNumber {
        dividing(by: decimalNumber, withBehavior: nil)
    }
    open func dividing(by decimalNumber: NSDecimalNumber, withBehavior behavior: (any NSDecimalNumberBehaviors)?) -> NSDecimalNumber {
        _apply(decimalNumber._decimal, behavior, _NSDecimalDivide)
    }

    open func raising(toPower power: Int) -> NSDecimalNumber {
        raising(toPower: power, withBehavior: nil)
    }
    open func raising(toPower power: Int, withBehavior behavior: (any NSDecimalNumberBehaviors)?) -> NSDecimalNumber {
        let behavior = behavior ?? NSDecimalNumber.defaultBehavior
        var result = Decimal(), value = _decimal
        let error = _NSDecimalPower(&result, &value, power, behavior.roundingMode())
        return NSDecimalNumber._finish(result, error, behavior)
    }

    open func multiplying(byPowerOf10 power: Int16) -> NSDecimalNumber {
        multiplying(byPowerOf10: power, withBehavior: nil)
    }
    open func multiplying(byPowerOf10 power: Int16, withBehavior behavior: (any NSDecimalNumberBehaviors)?) -> NSDecimalNumber {
        let behavior = behavior ?? NSDecimalNumber.defaultBehavior
        var result = Decimal(), value = _decimal
        let error = _NSDecimalMultiplyByPowerOf10(&result, &value, power, behavior.roundingMode())
        return NSDecimalNumber._finish(result, error, behavior)
    }

    open func rounding(accordingToBehavior behavior: (any NSDecimalNumberBehaviors)?) -> NSDecimalNumber {
        let behavior = behavior ?? NSDecimalNumber.defaultBehavior
        var result = Decimal(), value = _decimal
        _NSDecimalRound(&result, &value, Int(behavior.scale()), behavior.roundingMode())
        return NSDecimalNumber(decimal: result)
    }

    open override func compare(_ decimalNumber: NSNumber) -> ComparisonResult {
        var lhs = _decimal
        var rhs = (decimalNumber as? NSDecimalNumber)?._decimal ?? Decimal(decimalNumber.doubleValue)
        return _NSDecimalCompare(&lhs, &rhs)
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? NSDecimalNumber else { return false }
        if _decimal.isNaN || other._decimal.isNaN { return _decimal.isNaN && other._decimal.isNaN }
        return compare(other) == .orderedSame
    }

    open override var hash: Int { _decimal.hashValue }

    public static func == (lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> Bool { lhs.isEqual(rhs) }
}

extension Decimal: _ObjectiveCBridgeable {
    public typealias _ObjectiveCType = NSDecimalNumber
    public func _bridgeToObjectiveC() -> NSDecimalNumber { NSDecimalNumber(decimal: self) }
    public static func _forceBridgeFromObjectiveC(_ source: NSDecimalNumber, result: inout Decimal?) {
        result = source._decimal
    }
    public static func _conditionallyBridgeFromObjectiveC(_ source: NSDecimalNumber, result: inout Decimal?) -> Bool {
        result = source._decimal
        return true
    }
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSDecimalNumber?) -> Decimal {
        source?._decimal ?? Decimal()
    }
}

open class NSDecimalNumberHandler: NSObject, NSDecimalNumberBehaviors, @unchecked Sendable {
    private let _roundingMode: NSDecimalNumber.RoundingMode
    private let _scale: Int16
    private let _raise: (exactness: Bool, overflow: Bool, underflow: Bool, divideByZero: Bool)

    /// Plain rounding, no scale limit, raises (traps) on overflow, underflow
    /// and division by zero.
    public class var `default`: NSDecimalNumberHandler {
        NSDecimalNumberHandler(roundingMode: .plain, scale: Int16.max, raiseOnExactness: false,
                               raiseOnOverflow: true, raiseOnUnderflow: true, raiseOnDivideByZero: true)
    }

    public init(roundingMode: NSDecimalNumber.RoundingMode, scale: Int16, raiseOnExactness exact: Bool,
                raiseOnOverflow overflow: Bool, raiseOnUnderflow underflow: Bool,
                raiseOnDivideByZero divideByZero: Bool) {
        _roundingMode = roundingMode
        _scale = scale
        _raise = (exact, overflow, underflow, divideByZero)
        super.init()
    }

    open func roundingMode() -> NSDecimalNumber.RoundingMode { _roundingMode }
    open func scale() -> Int16 { _scale }

    fileprivate func _exceptionResult(_ error: NSDecimalNumber.CalculationError) -> NSDecimalNumber? {
        let raises: Bool
        switch error {
        case .noError: return nil
        case .lossOfPrecision: raises = _raise.exactness
        case .overflow: raises = _raise.overflow
        case .underflow: raises = _raise.underflow
        case .divideByZero: raises = _raise.divideByZero
        @unknown default: raises = true
        }
        if raises {
            NSException(name: .decimalNumberOverflowException,
                        reason: "NSDecimalNumber calculation error \(error.rawValue)",
                        userInfo: nil).raise()
        }
        return error == .lossOfPrecision ? nil : NSDecimalNumber.notANumber
    }
}

// MARK: - NSCharacterSet

// Only the named sets the guest CharacterSet has (CharacterSet.swift).
extension NSCharacterSet {
    public class var whitespaces: CharacterSet { .whitespaces }
    public class var whitespacesAndNewlines: CharacterSet { .whitespacesAndNewlines }
    public class var decimalDigits: CharacterSet { .decimalDigits }
    public class var letters: CharacterSet { .letters }
    public class var lowercaseLetters: CharacterSet { .lowercaseLetters }
    public class var uppercaseLetters: CharacterSet { .uppercaseLetters }
    public class var alphanumerics: CharacterSet { .alphanumerics }
    public class var symbols: CharacterSet { .symbols }
    public class var urlUserAllowed: CharacterSet { .urlUserAllowed }
    public class var urlPasswordAllowed: CharacterSet { .urlPasswordAllowed }
    public class var urlHostAllowed: CharacterSet { .urlHostAllowed }
    public class var urlPathAllowed: CharacterSet { .urlPathAllowed }
    public class var urlQueryAllowed: CharacterSet { .urlQueryAllowed }
    public class var urlFragmentAllowed: CharacterSet { .urlFragmentAllowed }
}

// MARK: - NSException

public struct NSExceptionName: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ rawValue: String) { self.rawValue = rawValue }

    public static let genericException = NSExceptionName("NSGenericException")
    public static let rangeException = NSExceptionName("NSRangeException")
    public static let invalidArgumentException = NSExceptionName("NSInvalidArgumentException")
    public static let internalInconsistencyException = NSExceptionName("NSInternalInconsistencyException")
    public static let mallocException = NSExceptionName("NSMallocException")
    public static let objectInaccessibleException = NSExceptionName("NSObjectInaccessibleException")
    public static let objectNotAvailableException = NSExceptionName("NSObjectNotAvailableException")
    public static let destinationInvalidException = NSExceptionName("NSDestinationInvalidException")
    public static let portTimeoutException = NSExceptionName("NSPortTimeoutException")
    public static let invalidSendPortException = NSExceptionName("NSInvalidSendPortException")
    public static let invalidReceivePortException = NSExceptionName("NSInvalidReceivePortException")
    public static let portSendException = NSExceptionName("NSPortSendException")
    public static let portReceiveException = NSExceptionName("NSPortReceiveException")
    public static let characterConversionException = NSExceptionName("NSCharacterConversionException")
    public static let fileHandleOperationException = NSExceptionName("NSFileHandleOperationException")
    public static let decimalNumberExactnessException = NSExceptionName("NSDecimalNumberExactnessException")
    public static let decimalNumberOverflowException = NSExceptionName("NSDecimalNumberOverflowException")
    public static let decimalNumberUnderflowException = NSExceptionName("NSDecimalNumberUnderflowException")
    public static let decimalNumberDivideByZeroException = NSExceptionName("NSDecimalNumberDivideByZeroException")
}

open class NSException: NSObject, NSCopying, @unchecked Sendable {
    public let name: NSExceptionName
    public let reason: String?
    public let userInfo: [AnyHashable: Any]?

    public init(name aName: NSExceptionName, reason aReason: String?, userInfo aUserInfo: [AnyHashable: Any]? = nil) {
        name = aName
        reason = aReason
        userInfo = aUserInfo
        super.init()
    }

    open var callStackSymbols: [String] { Thread.callStackSymbols }
    open var callStackReturnAddresses: [NSNumber] { Thread.callStackReturnAddresses }

    /// iOS terminates on an uncaught NSException with this line on stderr;
    /// the guest has no Objective-C unwinder, so every raise is uncaught.
    open func raise() {
        let message = "*** Terminating app due to uncaught exception '\(name.rawValue)', reason: '\(reason ?? "")'\n"
        FileHandle.standardError.write(message.data(using: .utf8) ?? Data())
        fatalError(message)
    }

    open class func raise(_ name: NSExceptionName, format: String, arguments: CVaListPointer) {
        NSException(name: name, reason: format, userInfo: nil).raise()
    }

    open func copy(with zone: NSZone? = nil) -> Any { self }
}

// MARK: - PersonNameComponents

/// Foundation's name-parts value (CloudKit's CKUserIdentity.nameComponents).
/// The guest's FoundationEssentials build does not carry it; this is the
/// stored-property value type only (no PersonNameComponentsFormatter).
public struct PersonNameComponents: Hashable, Codable, Sendable {
    public var namePrefix: String?
    public var givenName: String?
    public var middleName: String?
    public var familyName: String?
    public var nameSuffix: String?
    public var nickname: String?
    public var phoneticRepresentation: PersonNameComponents? {
        get { _phonetic?.value }
        set { _phonetic = newValue.map(_Box.init) }
    }
    private var _phonetic: _Box?

    public init() {}

    public init(namePrefix: String? = nil, givenName: String? = nil, middleName: String? = nil,
                familyName: String? = nil, nameSuffix: String? = nil, nickname: String? = nil,
                phoneticRepresentation: PersonNameComponents? = nil) {
        self.namePrefix = namePrefix
        self.givenName = givenName
        self.middleName = middleName
        self.familyName = familyName
        self.nameSuffix = nameSuffix
        self.nickname = nickname
        self.phoneticRepresentation = phoneticRepresentation
    }

    private final class _Box: Hashable, Codable, @unchecked Sendable {
        let value: PersonNameComponents
        init(_ value: PersonNameComponents) { self.value = value }
        static func == (lhs: _Box, rhs: _Box) -> Bool { lhs.value == rhs.value }
        func hash(into hasher: inout Hasher) { hasher.combine(value) }
    }
}
