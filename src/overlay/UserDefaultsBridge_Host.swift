//===----------------------------------------------------------------------===//
// The HOST-ORACLE half of UserDefaults' CoreFoundation seam.
//
// COMPILED ONLY WHEN UD_HOST_ORACLE IS DEFINED. Its counterpart,
// UserDefaultsBridge_Guest.swift, is compiled only when it is not. The two
// implement the same internal API and are never both in a build.
//
// WHY TWO FILES RATHER THAN TWO BRANCHES OF ONE. The oracle scores this port
// against real Foundation, so its two columns must be INDEPENDENTLY DERIVED.
// A single bridge compiled into both configurations would make the comparison
// share source with itself, and a bug in the shared part would agree with
// itself on every row. Separate files make that structural instead of
// disciplinary: neither build can accidentally see the other's source.
//
// This half is deliberately THIN. On the host, real Foundation already bridges
// Swift values to CF, so the seam is mostly `as CFString` and `as AnyObject` --
// which is exactly what the port used to do inline. Nothing here is new
// behaviour; it is the same calls behind the same names the guest half
// implements the hard way.
//===----------------------------------------------------------------------===//

#if UD_HOST_ORACLE

import Foundation

internal typealias UDCFString = CFString

internal func _udCFString(_ s: String) -> UDCFString? { s as CFString }

internal func _udSwiftString(_ cf: UDCFString) -> String? { cf as String }

internal func _udCurrentApplication() -> UDCFString {
    kCFPreferencesCurrentApplication
}

internal func _udCopyValue(_ key: String, _ appID: UDCFString) -> Any? {
    guard let cf = CFPreferencesCopyAppValue(key as CFString, appID) else { return nil }
    return UserDefaults._fromCFAny(cf)
}

internal func _udSetValue(_ value: Any?, _ key: String, _ appID: UDCFString) {
    guard let value = value else {
        CFPreferencesSetAppValue(key as CFString, nil, appID)
        return
    }
    guard let cf = _UDPlist.toCF(value) else {
        // Same trap as the guest half, for the same reason: dropping a write
        // is indistinguishable from performing one.
        fatalError("UserDefaults: value of type \(type(of: value)) is not a "
                 + "property-list type and cannot be stored for key '\(key)'")
    }
    CFPreferencesSetAppValue(key as CFString, cf, appID)
}

internal func _udSynchronize(_ appID: UDCFString) -> Bool {
    CFPreferencesAppSynchronize(appID)
}

internal func _udAddSuite(_ suite: String) {
    CFPreferencesAddSuitePreferencesToApp(kCFPreferencesCurrentApplication,
                                          suite as CFString)
}

internal func _udRemoveSuite(_ suite: String) {
    CFPreferencesRemoveSuitePreferencesFromApp(kCFPreferencesCurrentApplication,
                                               suite as CFString)
}

/// The domain enumeration, which only the host half implements today.
///
/// STATED, NOT HIDDEN: the guest half returns an empty dictionary, so
/// `dictionaryRepresentation()` and `persistentDomain(forName:)` are
/// host-only until the guest bridge marshals CFArray and CFDictionary. Those
/// two members are 12 and 32 uses in the corpus against `set`'s 658, which is
/// why they are behind the value types and not in front of them.
internal func _udCopyAll(_ appID: UDCFString) -> [String: Any] {
    guard let keys = CFPreferencesCopyKeyList(appID, kCFPreferencesCurrentUser,
                                              kCFPreferencesAnyHost) as? [String],
          let vals = CFPreferencesCopyMultiple(keys as CFArray, appID,
                                               kCFPreferencesCurrentUser,
                                               kCFPreferencesAnyHost) as? [String: Any]
    else { return [:] }
    var out: [String: Any] = [:]
    for (k, v) in vals { out[k] = UserDefaults._fromCFAny(v) }
    return out
}

// MARK: - Marshalling, host-only
//
// MOVED HERE FROM UserDefaults.swift, because only this configuration uses it:
// it is written in terms of NSNumber and CFGetTypeID, which real Foundation
// supplies and the guest configuration does not have. The guest half does its
// own marshalling against the declared C surface, which is the whole point of
// the seam -- two independent derivations, not one shared one.

/// The set of types CFPreferences can store. Kept explicit rather than
/// inferred, because `set(_:forKey:)` has to REFUSE anything else — Darwin
/// raises, and silently dropping a value is the failure mode this project
/// keeps finding (`succeeds-and-does-nothing`).
internal enum _UDPlist {

    /// Convert a Swift value to something CFPreferences will accept.
    ///
    /// Upstream routes this through corelibs' own `__SwiftValue.store`, a
    /// boxing class that exists only in corelibs (`Bridging.swift:73`) because
    /// corelibs' NSNumber does not bridge. DEVIATION (structural, not
    /// behavioural): we run on a real Objective-C runtime with real
    /// `_ObjectiveCBridgeable`, so `as AnyObject` is the boxing, and
    /// `__SwiftValue` must not be ported.
    static func toCF(_ value: Any) -> AnyObject? {
        switch value {
        case let v as String:  return v as AnyObject
        case let v as Bool:    return v as AnyObject   // BEFORE the integers:
                                                       // Bool is expressible as
                                                       // Int and would fold
        case let v as Int:     return v as AnyObject
        case let v as Int8:    return Int(v) as AnyObject
        case let v as Int16:   return Int(v) as AnyObject
        case let v as Int32:   return Int(v) as AnyObject
        case let v as Int64:   return Int(v) as AnyObject
        case let v as UInt8:   return Int(v) as AnyObject
        case let v as UInt16:  return Int(v) as AnyObject
        case let v as UInt32:  return Int(v) as AnyObject
        case let v as UInt64:  return Int(bitPattern: UInt(v)) as AnyObject
        case let v as UInt:    return Int(bitPattern: v) as AnyObject
        case let v as Float:   return Double(v) as AnyObject
        case let v as Double:  return v as AnyObject
        case let v as Data:    return v as AnyObject
        case let v as Date:    return v as AnyObject
        case let v as [Any]:
            var out: [AnyObject] = []
            out.reserveCapacity(v.count)
            for e in v {
                guard let c = toCF(e) else { return nil }
                out.append(c)
            }
            return out as AnyObject
        case let v as [String: Any]:
            var out: [String: AnyObject] = [:]
            for (k, e) in v {
                guard let c = toCF(e) else { return nil }
                out[k] = c
            }
            return out as AnyObject
        case let v as [AnyHashable: Any]:
            // Darwin requires plist dictionary keys to be strings.
            var out: [String: AnyObject] = [:]
            for (k, e) in v {
                guard let ks = k.base as? String, let c = toCF(e) else { return nil }
                out[ks] = c
            }
            return out as AnyObject
        default:
            return nil
        }
    }
}

// MARK: - CF -> Swift

extension UserDefaults {

    /// Unbox a CFPropertyList into Swift values.
    ///
    /// Upstream calls `__SwiftValue.fetch` and then `_unboxingNSNumbers`, which
    /// leans on corelibs' `NSNumber._swiftValueOfOptimalType`. Neither exists
    /// here. On a real ObjC runtime the bridge does this, but the BOOLEAN case
    /// has to be handled before the numeric one or `true` folds to `1` — the
    /// NSNumber folding hazard.
    static func _fromCF(_ cf: CFTypeRef) -> Any? {
        _fromCFAny(cf)
    }

    static func _fromCFAny(_ v: Any) -> Any {
        #if UD_HOST_ORACLE
        // Distinguish CFBoolean from CFNumber BEFORE any numeric cast.
        // Measured (BEHAV §1): a stored `true` comes back as __NSCFBoolean and
        // a stored `1` as __NSCFNumber, and they must not fold together.
        if CFGetTypeID(v as CFTypeRef) == CFBooleanGetTypeID() {
            return CFBooleanGetValue((v as! CFBoolean))
        }
        #endif
        switch v {
        case let n as NSNumber:
            if CFGetTypeID(n as CFTypeRef) == CFBooleanGetTypeID() {
                return CFBooleanGetValue(unsafeBitCast(n, to: CFBoolean.self))
            }
            let t = CFNumberGetType(n as CFNumber)
            switch t {
            case .float32Type, .float64Type, .floatType, .doubleType, .cgFloatType:
                return n.doubleValue
            default:
                return n.intValue
            }
        case let s as String: return s
        case let d as Data:   return d
        case let d as Date:   return d
        case let a as [Any]:  return a.map { _fromCFAny($0) }
        case let d as [String: Any]:
            var out: [String: Any] = [:]
            for (k, e) in d { out[k] = _fromCFAny(e) }
            return out
        default: return v
        }
    }
}

#endif  // UD_HOST_ORACLE
