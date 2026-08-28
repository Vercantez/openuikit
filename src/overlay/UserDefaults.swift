//===----------------------------------------------------------------------===//
//
// UserDefaults — ported from swift-corelibs-foundation
// (Sources/Foundation/UserDefaults.swift, release/6.2, Apache 2.0 with the
// Runtime Library Exception), over CoreFoundation's CFPreferences.
//
// #78 / ladder rung 1: UserDefaults is referenced by 20 of 20 apps in the
// pinned corpus, 2,586 uses, with nothing behind it.
//
//===----------------------------------------------------------------------===//
//
// THIS IS A PORT WITH DELIBERATE, MEASURED DEVIATIONS FROM UPSTREAM.
//
// swift-corelibs-foundation's UserDefaults is not a record of Darwin's
// behaviour — it is a clean-room reimplementation over CFPreferences that only
// ever runs on Linux, where nothing compares it to Apple's. Probing real macOS
// 26.5.2 Foundation found it disagreeing with Darwin on 19 of 42 string rows.
//
// Every deviation below cites the probe row that justifies it, by file. The
// goldens live in ~/swift-macho-linux/full/oracle-userdefaults/:
//
//     darwin-rules-2026-08-27.txt       the exact grammars (cited as RULES)
//     darwin-coercion-2026-08-27.txt    the 42-row string grid (cited as GRID)
//     darwin-behaviour-2026-08-27.txt   round-trips, layering, storage (BEHAV)
//     darwin-domains-2026-08-27.txt     domain composition (DOMAINS)
//
// A deviation without a citation is a bug. Do not "fix" one back to upstream
// without re-running the probe that put it here.
//
//===----------------------------------------------------------------------===//

#if UD_HOST_ORACLE
// Host-oracle configuration: real Foundation supplies Data/Date/URL and
// re-exports CoreFoundation. The module is built as `PortedUserDefaults`, so
// this type is `PortedUserDefaults.UserDefaults` and coexists in one process
// with the real `Foundation.UserDefaults` it is graded against.
import Foundation
#else
// Target configuration: this file is part of the Foundation overlay, over our
// own CF. Data/Date/URL come from the FoundationEssentials port.
//
// NOTE THE ABSENCE OF `import CoreFoundation`. It would resolve to APPLE'S
// CoreFoundation Swift overlay -- measured: arm64e-apple-macos26.1, built by a
// different compiler than the one here -- while this build LINKS OURS. Every
// CF call now goes through the seam in UserDefaultsBridge_Guest.swift, which
// talks to our CF through a declared C surface. See include/CFPreferencesMinimal.h.
import FoundationEssentials
// Darwin for pthread: the host half gets it via Foundation's re-export, the
// guest half has to ask. The FE sysroot has the module -- that is what
// `canImport(Darwin) == true` means for this port (see #58's route (A)).
import Darwin
#endif

// MARK: - The value model

// MARK: -

open class UserDefaults {

    /// The registration domain is PROCESS-WIDE, not per-instance and not
    /// per-suite. Measured (BEHAV §7): `register(defaults:)` called on a *suite*
    /// instance changed what `UserDefaults.standard` returned for that key —
    /// `standard.object(forKey: "k_string")` came back "register-should-LOSE",
    /// a value registered through a suite. Upstream models this the same way
    /// (a file-private global), and upstream is right here.
    private static let _registered = _UDLock<[String: Any]>([:])

    /// Suite name, or nil for the application domain.
    private let _suite: String?

    /// The CFPreferences application ID this instance reads and writes.
    ///
    /// HAZARD, and it is the silent-plausible kind: when `suiteName` is nil we
    /// pass `kCFPreferencesCurrentApplication`, and `CFPreferences.c:439-442`
    /// resolves that through `CFBundleGetIdentifier(CFBundleGetMainBundle())`
    /// **falling back to `_CFProcessNameString()` when the bundle has no
    /// identifier**. Every in-process read still passes in that case; only the
    /// plist FILENAME is wrong. The oracle therefore drives explicit suites and
    /// asserts the on-disk filename — see `full/oracle-userdefaults/`.
    private var _appID: UDCFString {
        if let s = _suite, let cf = _udCFString(s) { return cf }
        return _udCurrentApplication()
    }

    // MARK: Construction

    open class var standard: UserDefaults { _standard }
    private static let _standard = UserDefaults()

    /// Upstream is a no-op here and so are we; there is nothing cached to reset.
    open class func resetStandardUserDefaults() {}

    public convenience init() {
        self.init(suiteName: nil)!
    }

    public init?(suiteName suitename: String?) {
        _suite = suitename
    }

    // MARK: - object / set / remove — the three the rest are built on

    open func object(forKey defaultName: String) -> Any? {
        // Argument domain wins over everything, then the store, then the
        // registration domain. Measured (BEHAV §5, §6): a value that was `set`
        // beats a registered one, and `removeObject` FALLS BACK to the
        // registered value rather than to nil.
        if let v = _volatile.withLock({ $0[UserDefaults.argumentDomain]?[defaultName] }) {
            return v
        }
        if let v = _udCopyValue(defaultName, _appID) {
            return v
        }
        return UserDefaults._registered.withLock { $0[defaultName] }
    }

    open func set(_ value: Any?, forKey defaultName: String) {
        guard let value = value else {
            // Measured (RULES, "set(nil) vs removeObject"): set(nil) and
            // removeObject are the same operation.
            removeObject(forKey: defaultName)
            return
        }

        if let url = value as? URL {
            set(url, forKey: defaultName)
            return
        }

        // The seam traps on a non-plist value rather than dropping the write,
        // because a dropped write is indistinguishable from a performed one.
        _udSetValue(value, defaultName, _appID)
    }

    open func removeObject(forKey defaultName: String) {
        _udSetValue(nil, defaultName, _appID)
    }

    // MARK: - The typed getters
    //
    // THIS IS WHERE THE PORT DIVERGES FROM UPSTREAM MOST, AND ON PURPOSE.
    //
    // Upstream implements every string case as an NSString conversion:
    //     integer -> NSString(string:).integerValue
    //     bool    -> NSString(string:).boolValue
    //     double  -> NSString(string:).doubleValue
    // Measured (GRID): those disagree with real Foundation on 19 of 42 rows.
    // The rules below are Darwin's, pinned in RULES. They are CFString's
    // numeric conversions, not NSString's, and they are not interchangeable.

    open func string(forKey defaultName: String) -> String? {
        switch object(forKey: defaultName) {
        case let v as String: return v
        case let v as Bool:   return v ? "1" : "0"   // RULES: true -> "1"
        case let v as Int:    return String(v)
        case let v as Double: return UserDefaults._describe(v)
        case let v as Float:  return UserDefaults._describe(Double(v))
        default:              return nil             // GRID: Data/Date/array/dict -> nil
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
        // Measured (RULES): a MIXED array returns nil, not the string members.
        // `["a", 1, "b"]` -> array() is 3 elements, stringArray() is nil.
        object(forKey: defaultName) as? [String]
    }

    open func integer(forKey defaultName: String) -> Int {
        switch object(forKey: defaultName) {
        case let v as Bool:   return v ? 1 : 0
        case let v as Int:    return v          // RULES: NO clamp on a stored
                                                // number — Int.max round-trips
        case let v as Double: return Int(v)     // RULES: truncates toward zero
        case let v as Float:  return Int(v)
        case let v as String: return Int(UserDefaults._cfIntValue(v))
        default:              return 0          // GRID: absent/Data/Date/array -> 0
        }
    }

    open func double(forKey defaultName: String) -> Double {
        switch object(forKey: defaultName) {
        case let v as Bool:   return v ? 1 : 0
        case let v as Int:    return Double(v)
        case let v as Double: return v
        case let v as Float:  return Double(v)
        case let v as String: return UserDefaults._cfDoubleValue(v)
        default:              return 0
        }
    }

    open func float(forKey defaultName: String) -> Float {
        // RULES: float() is double() narrowed — float("3.14159265358979") is
        // 3.1415927, the Float rounding of the Double answer.
        Float(double(forKey: defaultName))
    }

    open func bool(forKey defaultName: String) -> Bool {
        switch object(forKey: defaultName) {
        case let v as Bool:   return v
        case let v as Int:    return v != 0     // GRID: 2 -> true, -1 -> true
        case let v as Double: return v != 0     // GRID: 0.4 -> true
        case let v as Float:  return v != 0
        case let v as String: return UserDefaults._cfBoolValue(v)
        default:              return false
        }
    }

    open func url(forKey defaultName: String) -> URL? {
        switch object(forKey: defaultName) {
        case let v as String:
            // BEHAV §4: a plain string is read as a FILE path, tilde-expanded,
            // resolved against the working directory if relative.
            return URL(fileURLWithPath: UserDefaults._expandingTilde(v))
        case is Data:
            // DEVIATION FROM UPSTREAM, DELIBERATELY LOUD RATHER THAN WRONG.
            //
            // Darwin stores a NON-FILE URL as an ARCHIVED NSURL (BEHAV §4:
            // https://example.com/a?b=c came back as 263 bytes of bplist00) and
            // unarchives it here. That needs NSKeyedUnarchiver, which this
            // stack does not have.
            //
            // Upstream would reach the same line. We refuse instead of
            // guessing, because the alternative — returning nil — is
            // indistinguishable from "no such key" and would be a silent wrong
            // answer.
            //
            // SCOPE, measured: `url(forKey:)` is 1 of 20 apps in the corpus.
            // Deliberately NOT a reason to port NSKeyedUnarchiver.
            _UDUnimplemented("url(forKey:) on an archived (non-file) URL "
                           + "requires NSKeyedUnarchiver, which is not built. "
                           + "key='\(defaultName)'")
        default:
            return nil                          // BEHAV §4: url(k_int) -> nil
        }
    }

    // MARK: - Typed setters

    open func set(_ value: Int, forKey defaultName: String) {
        _udSetValue(value, defaultName, _appID)
    }
    open func set(_ value: Float, forKey defaultName: String) {
        _udSetValue(Double(value), defaultName, _appID)
    }
    open func set(_ value: Double, forKey defaultName: String) {
        _udSetValue(value, defaultName, _appID)
    }
    open func set(_ value: Bool, forKey defaultName: String) {
        _udSetValue(value, defaultName, _appID)
    }

    open func set(_ url: URL?, forKey defaultName: String) {
        guard let url = url else {
            removeObject(forKey: defaultName)
            return
        }
        // DEVIATION FROM UPSTREAM. Measured (BEHAV §4):
        //   file URL     -> stored as a bare PATH STRING ("/tmp/x")
        //   non-file URL -> stored as ARCHIVED Data (263 bytes of bplist00)
        //
        // Upstream stores `url.path` for anything that is not a file
        // *reference* URL, so `https://example.com/a?b=c` would be stored as
        // "/a" and read back as `file:///a` — a wrong value that looks like a
        // right one.
        //
        // Upstream's file-reference branch is additionally guarded by
        // `#if os(macOS) || os(iOS)`, which is DEAD on corelibs' Linux and LIVE
        // for us: we build arm64-apple-macos. A straight port would have
        // silently switched that branch on.
        if url.isFileURL {
            _udSetValue(url.path, defaultName, _appID)
        } else {
            _UDUnimplemented("set(_ url:forKey:) on a non-file URL requires "
                           + "NSKeyedArchiver to match Darwin's archived form; "
                           + "storing url.path (upstream's behaviour) would "
                           + "silently record '\(url.path)'. key='\(defaultName)'")
        }
    }

    // MARK: - Registration

    open func register(defaults registrationDictionary: [String: Any]) {
        UserDefaults._registered.withLock {
            for (k, v) in registrationDictionary { $0[k] = v }
        }
    }

    // MARK: - Suites

    open func addSuite(named suiteName: String) {
        _udAddSuite(suiteName)
    }

    open func removeSuite(named suiteName: String) {
        _udRemoveSuite(suiteName)
    }

    // MARK: - Domains

    open func dictionaryRepresentation() -> [String: Any] {
        // DEVIATION FROM UPSTREAM, and the deviation is a SUBSET, stated.
        //
        // Measured (DOMAINS): on Darwin this returns the whole SEARCH LIST —
        // suite + NSGlobalDomain + registration + argument. On one instance it
        // was 81 keys against persistentDomain(forName:)'s 2, and 52 of the 79
        // extras were NSGlobalDomain.
        //
        // Upstream returns app-domain + registration only, i.e. it omits the
        // global domain. We match upstream HERE, not Darwin, because there is
        // no system NSGlobalDomain on this target — the honest difference is
        // that our global domain is EMPTY, not that we skip it. If one ever
        // exists, this is the line that has to learn about it.
        var out: [String: Any] = UserDefaults._registered.withLock { $0 }
        for (k, v) in _udCopyAll(_appID) { out[k] = v }
        for (k, v) in _volatile.withLock({ $0[UserDefaults.argumentDomain] ?? [:] }) {
            out[k] = v
        }
        return out
    }

    private func _persistentOnly() -> [String: Any] {
        var out: [String: Any] = [:]
        for (k, v) in _udCopyAll(_appID) { out[k] = v }
        return out
    }

    open func persistentDomain(forName domainName: String) -> [String: Any]? {
        // Measured (BEHAV §5): registered values are NOT in the persistent
        // domain, only the ones on disk.
        UserDefaults(suiteName: domainName)?._persistentOnly()
    }

    open func setPersistentDomain(_ domain: [String: Any], forName domainName: String) {
        guard let d = UserDefaults(suiteName: domainName) else { return }
        for key in d._persistentOnly().keys { d.removeObject(forKey: key) }
        for (k, v) in domain { d.set(v, forKey: k) }
        _ = d.synchronize()
    }

    open func removePersistentDomain(forName domainName: String) {
        guard let d = UserDefaults(suiteName: domainName) else { return }
        for key in d._persistentOnly().keys { d.removeObject(forKey: key) }
        _ = d.synchronize()
    }

    // MARK: - Volatile domains

    private let _volatile = _UDLock<[String: [String: Any]]>([:])

    open var volatileDomainNames: [String] {
        // Measured (DOMAINS): Darwin reports ["NSRegistrationDomain",
        // "NSArgumentDomain"]. Upstream reports only what it put in its own
        // dictionary, which excludes the registration domain because upstream
        // keeps registrations somewhere else. Zero corpus uses; matching
        // Darwin is free, so we do.
        var names = Set(_volatile.withLock { Array($0.keys) })
        names.insert(UserDefaults.registrationDomain)
        names.insert(UserDefaults.argumentDomain)
        return Array(names).sorted()
    }

    open func volatileDomain(forName domainName: String) -> [String: Any] {
        if domainName == UserDefaults.registrationDomain {
            return UserDefaults._registered.withLock { $0 }
        }
        return _volatile.withLock { $0[domainName] ?? [:] }
    }

    open func setVolatileDomain(_ domain: [String: Any], forName domainName: String) {
        _volatile.withLock {
            var d = $0[domainName] ?? [:]
            for (k, v) in domain { d[k] = v }
            $0[domainName] = d
        }
    }

    open func removeVolatileDomain(forName domainName: String) {
        _volatile.withLock { _ = $0.removeValue(forKey: domainName) }
    }

    // MARK: -

    @discardableResult
    open func synchronize() -> Bool {
        _udSynchronize(_appID)
    }

    open func objectIsForced(forKey key: String) -> Bool { false }
    open func objectIsForced(forKey key: String, inDomain domain: String) -> Bool { false }
}

// MARK: - Domain names

extension UserDefaults {
    public static let globalDomain: String = "NSGlobalDomain"
    public static let argumentDomain: String = "NSArgumentDomain"
    public static let registrationDomain: String = "NSRegistrationDomain"
}

// MARK: - The measured conversions
//
// These are CFString's numeric conversions, reproduced from measurement rather
// than from CF's source, because the point is to match what Darwin ANSWERS.
// Each cites its rows in darwin-rules-2026-08-27.txt.

extension UserDefaults {

    /// Darwin's `integer(forKey:)` on a String. RULES §"INTEGER":
    ///
    ///   - leading whitespace skipped              " 123" -> 123, "\t123" -> 123
    ///   - optional sign, AND WHITESPACE MAY FOLLOW THE SIGN
    ///                                             "- 7" -> -7, "+ 7" -> 7
    ///   - one or more digits, then END OF STRING  "123\t" -> 0, "2147483647x" -> 0
    ///   - leading zeroes fine                     "007" -> 7
    ///   - **saturates to Int32**                  "2147483648"  -> 2147483647
    ///                                             "-2147483649" -> -2147483648
    ///   - no sign alone, no double sign           "+" -> 0, "--7" -> 0
    ///   - no hex, no exponent, no underscores     "0x10" -> 0, "1e3" -> 0, "1_000" -> 0
    ///
    /// The Int32 saturation is the row nobody would predict from the header,
    /// and it applies ONLY to the string path: a stored Int.max round-trips
    /// intact through `integer(forKey:)`.
    static func _cfIntValue(_ s: String) -> Int32 {
        var i = s.startIndex
        let end = s.endIndex
        while i < end, s[i] == " " || s[i] == "\t" || s[i] == "\n" || s[i] == "\r" {
            i = s.index(after: i)
        }
        var negative = false
        if i < end, s[i] == "+" || s[i] == "-" {
            negative = (s[i] == "-")
            i = s.index(after: i)
            // RULES: "- 7" -> -7. Whitespace after the sign is accepted.
            while i < end, s[i] == " " || s[i] == "\t" { i = s.index(after: i) }
        }
        guard i < end, s[i].isASCII, s[i].isNumber else { return 0 }
        var magnitude: Int64 = 0
        var saturated = false
        while i < end, let d = s[i].wholeNumberValue, s[i].isASCII, s[i].isNumber {
            if !saturated {
                magnitude = magnitude * 10 + Int64(d)
                if magnitude > 4_294_967_296 { saturated = true }
            }
            i = s.index(after: i)
        }
        // RULES: trailing anything at all -> 0. Not a prefix parse.
        guard i == end else { return 0 }
        if saturated { return negative ? Int32.min : Int32.max }
        let signed = negative ? -magnitude : magnitude
        if signed > Int64(Int32.max) { return Int32.max }
        if signed < Int64(Int32.min) { return Int32.min }
        return Int32(signed)
    }

    /// Darwin's `double(forKey:)` on a String. RULES §"DOUBLE":
    ///
    ///   - PREFIX parse, unlike integer  "123 " -> 123, "1banana" -> 1, "1e" -> 1
    ///   - leading whitespace skipped    " 123" -> 123
    ///   - decimal only, NO hex          "0x10" -> 0, "0X10" -> 0
    ///   - exponent accepted             "1e3" -> 1000, "1E3" -> 1000
    ///   - bare dot either side          ".5" -> 0.5, "5." -> 5
    ///   - NO inf/nan words              "inf" -> 0, "nan" -> 0, "-inf" -> 0
    ///   - overflow goes to inf          "1e400" -> inf
    ///   - no thousands separator        "1,5" -> 1
    static func _cfDoubleValue(_ s: String) -> Double {
        let u = Array(s.utf8)
        var i = 0
        while i < u.count, u[i] == 0x20 || u[i] == 0x09 || u[i] == 0x0A || u[i] == 0x0D { i += 1 }
        let start = i
        if i < u.count, u[i] == 0x2B || u[i] == 0x2D { i += 1 }
        var sawDigit = false
        while i < u.count, u[i] >= 0x30, u[i] <= 0x39 { i += 1; sawDigit = true }
        if i < u.count, u[i] == 0x2E {                       // '.'
            i += 1
            while i < u.count, u[i] >= 0x30, u[i] <= 0x39 { i += 1; sawDigit = true }
        }
        guard sawDigit else { return 0 }                     // RULES: "inf"/"nan" -> 0
        var mantissaEnd = i
        if i < u.count, u[i] == 0x65 || u[i] == 0x45 {       // 'e' / 'E'
            var j = i + 1
            if j < u.count, u[j] == 0x2B || u[j] == 0x2D { j += 1 }
            var expDigits = false
            while j < u.count, u[j] >= 0x30, u[j] <= 0x39 { j += 1; expDigits = true }
            // RULES: "1e" -> 1. A dangling exponent is not part of the number.
            if expDigits { mantissaEnd = j }
        }
        let text = String(decoding: u[start..<mantissaEnd], as: UTF8.self)
        return Double(text) ?? 0
    }

    /// Darwin's `bool(forKey:)` on a String. RULES §"BOOL":
    ///
    /// True for EXACTLY the whole string "1", or a case-insensitive whole-string
    /// "yes" or "true". Everything else is false — including " 1", "1 ", "01",
    /// "1.0", "+1", "2", "-1", "123", "Y", "T", "yess", "truex", "yes ", "YES\n".
    ///
    /// This is NOT `NSString.boolValue`, which upstream calls and which answers
    /// true to every one of those. It is also not "the integer value is
    /// nonzero", which would accept "2" and "01".
    static func _cfBoolValue(_ s: String) -> Bool {
        if s == "1" { return true }
        let l = s.lowercased()
        return l == "yes" || l == "true"
    }

    /// `string(forKey:)` on a stored Double. RULES §"string(forKey:) on
    /// numbers": 1.0 -> "1", 0.1 -> "0.1", 1.5 -> "1.5", 1e21 -> "1e+21",
    /// -0.0 -> "-0". That is CFNumber's `%g`-family formatting at 16
    /// significant digits, which is what NSNumber.stringValue produces — the
    /// one place upstream's NSNumber route was already right.
    /// Implemented with vsnprintf rather than String(format:) because
    /// String(format:) is FOUNDATION's, not FoundationEssentials', so it does
    /// not exist in the guest configuration -- and because "%0.16g" IS a C
    /// format string, so this is the same call one layer less indirect.
    ///
    /// SHARED BETWEEN BOTH CONFIGURATIONS ON PURPOSE, unlike the CF seam. The
    /// coercion table is the thing under test; both columns of the scoreboard
    /// are the SAME port graded against DARWIN, not against each other. It is
    /// the bridge that must be independently derived, not the behaviour.
    static func _describe(_ v: Double) -> String {
        var buf = [CChar](repeating: 0, count: 64)
        _ = buf.withUnsafeMutableBufferPointer { b in
            withVaList([v]) { va in
                vsnprintf(b.baseAddress, 64, "%0.16g", va)
            }
        }
        return String(cString: buf)
    }

    static func _expandingTilde(_ path: String) -> String {
        guard path.hasPrefix("~") else { return path }
        let home = _UDHomeDirectory()
        if path == "~" { return home }
        if path.hasPrefix("~/") { return home + String(path.dropFirst(1)) }
        return path                       // ~user is not resolved here
    }
}


// MARK: - Small dependencies, kept local on purpose
//
// Upstream uses NSLock (corelibs, ABSENT here) and Mutex from Synchronization.
// A ~30-line lock avoids taking a dependency for two call sites.

internal final class _UDLock<Value>: @unchecked Sendable {
    private var _value: Value
    private let _lock = _UDMutex()
    init(_ value: Value) { _value = value }
    func withLock<R>(_ body: (inout Value) throws -> R) rethrows -> R {
        _lock.lock(); defer { _lock.unlock() }
        return try body(&_value)
    }
}

internal final class _UDMutex: @unchecked Sendable {
    private var m = pthread_mutex_t()
    init() { pthread_mutex_init(&m, nil) }
    deinit { pthread_mutex_destroy(&m) }
    func lock() { pthread_mutex_lock(&m) }
    func unlock() { pthread_mutex_unlock(&m) }
}

internal func _UDHomeDirectory() -> String {
    if let h = getenv("HOME") { return String(cString: h) }
    return "/"
}

/// Loud, naming itself, on fd 2 — the shape `fm_unimplemented.c` uses. A stub
/// that returns is indistinguishable from one that works.
internal func _UDUnimplemented(_ what: String) -> Never {
    let msg = "UNIMPLEMENTED (UserDefaults): \(what)\n"
    msg.withCString { p in _ = write(2, p, strlen(p)) }
    fatalError(msg)
}
