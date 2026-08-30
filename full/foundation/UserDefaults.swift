// Persistent, property-list-shaped UserDefaults for Linux-hosted Mach-O
// guests. This is a project-owned storage backend informed by the committed
// Apple differential oracle under full/oracle-userdefaults/. It deliberately
// uses FoundationEssentials values and a private JSON envelope, avoiding a
// dependency on the not-yet-shipping CoreFoundation preferences daemon.

#if FOUNDATION_GUEST_SERVICES_HOST
import Foundation
#else
import FoundationEssentials
#endif
import Synchronization
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

private func _userDefaultsRename(
    _ from: UnsafePointer<CChar>,
    _ to: UnsafePointer<CChar>
) -> Int32 {
#if canImport(Darwin)
    return Darwin.rename(from, to)
#elseif canImport(Glibc)
    return Glibc.rename(from, to)
#else
    return -1
#endif
}

private func _userDefaultsUnlink(_ path: UnsafePointer<CChar>) -> Int32 {
#if canImport(Darwin)
    return Darwin.unlink(path)
#elseif canImport(Glibc)
    return Glibc.unlink(path)
#else
    return -1
#endif
}

open class UserDefaults {
    private static let _domains = Mutex<[String: [String: _UDStored]]>([:])
    private static let _registered = Mutex<[String: _UDStored]>([:])
    private static let _standard = UserDefaults()

    private let _domain: String
    private let _additionalSuites = Mutex<[String]>([])
    private let _volatile = Mutex<[String: [String: _UDStored]]>([:])

    open class var standard: UserDefaults { _standard }

    open class func resetStandardUserDefaults() {
        _domains.withLock { _ = $0.removeValue(forKey: _applicationDomain) }
    }

    public convenience init() {
        self.init(suiteName: nil)!
    }

    public init?(suiteName suitename: String?) {
        _domain = suitename ?? Self._applicationDomain
    }

    open func object(forKey defaultName: String) -> Any? {
        if let value = _volatile.withLock({ $0[Self.argumentDomain]?[defaultName] }) {
            return value.value
        }
        if let value = Self._value(forKey: defaultName, domain: _domain) {
            return value.value
        }
        for suite in _additionalSuites.withLock({ $0 }) {
            if let value = Self._value(forKey: defaultName, domain: suite) {
                return value.value
            }
        }
        return Self._registered.withLock { $0[defaultName]?.value }
    }

    /// KVC-era spelling retained by Foundation's public UserDefaults surface.
    /// This is an alias for `object(forKey:)`; the portable preferences store
    /// does not claim general NSObject key-value coding.
    open func value(forKey key: String) -> Any? {
        object(forKey: key)
    }

    open func set(_ value: Any?, forKey defaultName: String) {
        guard let value else {
            removeObject(forKey: defaultName)
            return
        }
        guard let stored = _UDStored(value) else {
            preconditionFailure(
                "UserDefaults cannot store value of type \(type(of: value)) " +
                "for key '\(defaultName)'"
            )
        }
        Self._mutate(domain: _domain) { $0[defaultName] = stored }
    }

    open func removeObject(forKey defaultName: String) {
        Self._mutate(domain: _domain) { _ = $0.removeValue(forKey: defaultName) }
    }

    open func string(forKey defaultName: String) -> String? {
        switch object(forKey: defaultName) {
        case let value as String: return value
        case let value as Bool: return value ? "1" : "0"
        case let value as Int: return String(value)
        case let value as Double: return String(value)
        case let value as Float: return String(value)
        default: return nil
        }
    }

    open func array(forKey defaultName: String) -> [Any]? {
        object(forKey: defaultName) as? [Any]
    }

    open func dictionary(forKey defaultName: String) -> [String: Any]? {
        object(forKey: defaultName) as? [String: Any]
    }

    open func data(forKey defaultName: String) -> Data? {
        object(forKey: defaultName) as? Data
    }

    open func stringArray(forKey defaultName: String) -> [String]? {
        object(forKey: defaultName) as? [String]
    }

    open func integer(forKey defaultName: String) -> Int {
        switch object(forKey: defaultName) {
        case let value as Bool: return value ? 1 : 0
        case let value as Int: return value
        case let value as UInt: return Int(clamping: value)
        case let value as Double: return Int(value)
        case let value as Float: return Int(value)
        case let value as String: return Self._strictInteger(value)
        default: return 0
        }
    }

    open func double(forKey defaultName: String) -> Double {
        switch object(forKey: defaultName) {
        case let value as Bool: return value ? 1 : 0
        case let value as Int: return Double(value)
        case let value as UInt: return Double(value)
        case let value as Double: return value
        case let value as Float: return Double(value)
        case let value as String: return Double(value) ?? 0
        default: return 0
        }
    }

    open func float(forKey defaultName: String) -> Float {
        Float(double(forKey: defaultName))
    }

    open func bool(forKey defaultName: String) -> Bool {
        switch object(forKey: defaultName) {
        case let value as Bool: return value
        case let value as Int: return value != 0
        case let value as UInt: return value != 0
        case let value as Double: return value != 0
        case let value as Float: return value != 0
        case let value as String:
            return value == "1" || value == "YES" || value == "Yes" ||
                value == "yes" || value == "TRUE" || value == "True" ||
                value == "true"
        default: return false
        }
    }

    open func url(forKey defaultName: String) -> URL? {
        switch object(forKey: defaultName) {
        case let value as URL: return value
        case let value as String: return URL(fileURLWithPath: value)
        default: return nil
        }
    }

    open func set(_ value: Int, forKey defaultName: String) { set(value as Any, forKey: defaultName) }
    open func set(_ value: Float, forKey defaultName: String) { set(value as Any, forKey: defaultName) }
    open func set(_ value: Double, forKey defaultName: String) { set(value as Any, forKey: defaultName) }
    open func set(_ value: Bool, forKey defaultName: String) { set(value as Any, forKey: defaultName) }
    open func set(_ url: URL?, forKey defaultName: String) { set(url as Any?, forKey: defaultName) }

    open func register(defaults registrationDictionary: [String: Any]) {
        var converted: [String: _UDStored] = [:]
        for (key, value) in registrationDictionary {
            guard let stored = _UDStored(value) else {
                preconditionFailure(
                    "UserDefaults cannot register value of type \(type(of: value)) " +
                    "for key '\(key)'"
                )
            }
            converted[key] = stored
        }
        Self._registered.withLock { state in
            for (key, value) in converted { state[key] = value }
        }
    }

    open func addSuite(named suiteName: String) {
        _additionalSuites.withLock { suites in
            if !suites.contains(suiteName) { suites.append(suiteName) }
        }
    }

    open func removeSuite(named suiteName: String) {
        _additionalSuites.withLock { suites in
            suites.removeAll { $0 == suiteName }
        }
    }

    open func dictionaryRepresentation() -> [String: Any] {
        var result = Self._registered.withLock { $0.mapValues(\.value) }
        for suite in _additionalSuites.withLock({ $0 }).reversed() {
            for (key, value) in Self._domainValues(suite) { result[key] = value.value }
        }
        for (key, value) in Self._domainValues(_domain) { result[key] = value.value }
        for (key, value) in _volatile.withLock({ $0[Self.argumentDomain] ?? [:] }) {
            result[key] = value.value
        }
        return result
    }

    open func persistentDomain(forName domainName: String) -> [String: Any]? {
        Self._domainValues(domainName).mapValues(\.value)
    }

    open func setPersistentDomain(_ domain: [String: Any], forName domainName: String) {
        var converted: [String: _UDStored] = [:]
        for (key, value) in domain {
            guard let stored = _UDStored(value) else {
                preconditionFailure("UserDefaults persistent domain contains a non-property-list value")
            }
            converted[key] = stored
        }
        Self._replace(domain: domainName, with: converted)
    }

    open func removePersistentDomain(forName domainName: String) {
        Self._replace(domain: domainName, with: [:])
    }

    open var volatileDomainNames: [String] {
        var names = _volatile.withLock { Array($0.keys) }
        if !names.contains(Self.registrationDomain) { names.append(Self.registrationDomain) }
        if !names.contains(Self.argumentDomain) { names.append(Self.argumentDomain) }
        return names.sorted()
    }

    open func volatileDomain(forName domainName: String) -> [String: Any] {
        if domainName == Self.registrationDomain {
            return Self._registered.withLock { $0.mapValues(\.value) }
        }
        return _volatile.withLock { ($0[domainName] ?? [:]).mapValues(\.value) }
    }

    open func setVolatileDomain(_ domain: [String: Any], forName domainName: String) {
        var converted: [String: _UDStored] = [:]
        for (key, value) in domain {
            guard let stored = _UDStored(value) else {
                preconditionFailure("UserDefaults volatile domain contains a non-property-list value")
            }
            converted[key] = stored
        }
        _volatile.withLock { $0[domainName] = converted }
    }

    open func removeVolatileDomain(forName domainName: String) {
        _volatile.withLock { _ = $0.removeValue(forKey: domainName) }
    }

    @discardableResult
    open func synchronize() -> Bool {
        Self._persist(Self._domainValues(_domain), domain: _domain)
    }

    open func objectIsForced(forKey key: String) -> Bool { false }
    open func objectIsForced(forKey key: String, inDomain domain: String) -> Bool { false }

    public static let globalDomain = "NSGlobalDomain"
    public static let argumentDomain = "NSArgumentDomain"
    public static let registrationDomain = "NSRegistrationDomain"

    private static var _applicationDomain: String {
        let executable = CommandLine.arguments.first?.split(separator: "/").last
        return executable.map(String.init) ?? "application"
    }

    private static func _domainValues(_ domain: String) -> [String: _UDStored] {
        _domains.withLock { domains in
            if let loaded = domains[domain] { return loaded }
            let loaded = _load(domain: domain)
            domains[domain] = loaded
            return loaded
        }
    }

    private static func _value(forKey key: String, domain: String) -> _UDStored? {
        _domainValues(domain)[key]
    }

    private static func _mutate(
        domain: String,
        _ body: (inout [String: _UDStored]) -> Void
    ) {
        let snapshot = _domains.withLock { domains -> [String: _UDStored] in
            var values = domains[domain] ?? _load(domain: domain)
            body(&values)
            domains[domain] = values
            return values
        }
        _ = _persist(snapshot, domain: domain)
    }

    private static func _replace(domain: String, with values: [String: _UDStored]) {
        _domains.withLock { $0[domain] = values }
        _ = _persist(values, domain: domain)
    }

    private static func _load(domain: String) -> [String: _UDStored] {
        guard let data = try? Data(contentsOf: _fileURL(domain: domain)) else { return [:] }
        return (try? JSONDecoder().decode([String: _UDStored].self, from: data)) ?? [:]
    }

    private static func _persist(_ values: [String: _UDStored], domain: String) -> Bool {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(values) else { return false }
        return _atomicWrite(data, to: _fileURL(domain: domain))
    }

    private static func _atomicWrite(_ data: Data, to destination: URL) -> Bool {
        let destinationPath = destination.path
        let temporaryPath = destinationPath + "." + UUID().uuidString + ".tmp"
        let temporaryURL = URL(fileURLWithPath: temporaryPath)

        do {
            // A non-atomic Data write fsyncs this uniquely named file. Publish
            // it atomically with same-directory rename, avoiding the upstream
            // Data.atomic mktemp dependency absent from machorun's libSystem.
            try data.write(to: temporaryURL)
        } catch {
            temporaryPath.withCString { _ = _userDefaultsUnlink($0) }
            return false
        }

        let renamed = temporaryPath.withCString { source in
            destinationPath.withCString { target in
                _userDefaultsRename(source, target)
            }
        }
        if renamed == 0 { return true }
        temporaryPath.withCString { _ = _userDefaultsUnlink($0) }
        return false
    }

    private static func _fileURL(domain: String) -> URL {
        let safe = domain.unicodeScalars.map { scalar -> Character in
            let value = scalar.value
            let accepted = (48...57).contains(value) || (65...90).contains(value) ||
                (97...122).contains(value) || value == 45 || value == 46 || value == 95
            return accepted ? Character(String(scalar)) : "_"
        }
        return URL(fileURLWithPath: "/tmp/open-foundation-userdefaults-" + String(safe) + ".json")
    }

    private static func _strictInteger(_ string: String) -> Int {
        var text = string
        while text.first == " " || text.first == "\t" || text.first == "\n" || text.first == "\r" {
            text.removeFirst()
        }
        var sign = 1
        if text.first == "+" || text.first == "-" {
            if text.first == "-" { sign = -1 }
            text.removeFirst()
            while text.first == " " || text.first == "\t" { text.removeFirst() }
        }
        guard !text.isEmpty, text.allSatisfy({ $0.isASCII && $0.isNumber }) else {
            return 0
        }
        let limit: UInt64 = sign < 0 ? 2_147_483_648 : 2_147_483_647
        var magnitude: UInt64 = 0
        for character in text {
            let digit = UInt64(character.wholeNumberValue ?? 0)
            if magnitude > (limit - digit) / 10 {
                magnitude = limit
                break
            }
            magnitude = magnitude * 10 + digit
        }
        return sign < 0 ? -Int(magnitude) : Int(magnitude)
    }
}

private indirect enum _UDStored: Codable, Sendable {
    case string(String)
    case bool(Bool)
    case int(Int64)
    case uint(UInt64)
    case double(Double)
    case data(Data)
    case date(Date)
    case url(String, Bool)
    case array([_UDStored])
    case dictionary([String: _UDStored])

    init?(_ value: Any) {
        switch value {
        case let value as String: self = .string(value)
        case let value as Bool: self = .bool(value)
        case let value as Int: self = .int(Int64(value))
        case let value as Int8: self = .int(Int64(value))
        case let value as Int16: self = .int(Int64(value))
        case let value as Int32: self = .int(Int64(value))
        case let value as Int64: self = .int(value)
        case let value as UInt: self = .uint(UInt64(value))
        case let value as UInt8: self = .uint(UInt64(value))
        case let value as UInt16: self = .uint(UInt64(value))
        case let value as UInt32: self = .uint(UInt64(value))
        case let value as UInt64: self = .uint(value)
        case let value as Float: self = .double(Double(value))
        case let value as Double: self = .double(value)
        case let value as Data: self = .data(value)
        case let value as Date: self = .date(value)
        case let value as URL: self = .url(value.absoluteString, value.isFileURL)
        case let values as [Any]:
            var converted: [_UDStored] = []
            converted.reserveCapacity(values.count)
            for value in values {
                guard let stored = _UDStored(value) else { return nil }
                converted.append(stored)
            }
            self = .array(converted)
        case let values as [String: Any]:
            var converted: [String: _UDStored] = [:]
            for (key, value) in values {
                guard let stored = _UDStored(value) else { return nil }
                converted[key] = stored
            }
            self = .dictionary(converted)
        default: return nil
        }
    }

    var value: Any {
        switch self {
        case let .string(value): return value
        case let .bool(value): return value
        case let .int(value): return Int(value)
        case let .uint(value): return UInt(value)
        case let .double(value): return value
        case let .data(value): return value
        case let .date(value): return value
        case let .url(value, _): return URL(string: value) ?? value
        case let .array(values): return values.map(\.value)
        case let .dictionary(values): return values.mapValues(\.value)
        }
    }
}
