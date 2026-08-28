//===----------------------------------------------------------------------===//
// The GUEST half of UserDefaults' CoreFoundation seam.
//
// COMPILED ONLY WHEN UD_HOST_ORACLE IS NOT DEFINED, and its host counterpart
// (UserDefaultsBridge_Host.swift) is compiled only when it IS. The two files
// implement the same internal API and are never both in a build.
//
// THAT SEPARATION IS A CONDITION ON THIS WORK, NOT AN AESTHETIC. The oracle
// scores this port against real Foundation, so its two columns have to be
// INDEPENDENTLY DERIVED. If one bridge compiled into both configurations, the
// comparison would start sharing source with itself, and a bug in the shared
// part would agree with itself on every row. Splitting by file rather than by
// `#if` inside one file makes that structural: the host build never sees this
// source at all.
//===----------------------------------------------------------------------===//

#if !UD_HOST_ORACLE

import FoundationEssentials
import CFPreferencesMinimal
import UDPlatformMinimal

// The guest speaks to OUR CoreFoundation through the declared surface in
// include/CFPreferencesMinimal.h -- deliberately NOT `import CoreFoundation`,
// which resolves to Apple's Swift overlay and would bind the compiler to a
// CoreFoundation we do not link. See that header for the measurement.
internal typealias UDCFString = FMCFStringRef

// MARK: - Strings

/// Swift String -> FMCFStringRef.
///
/// ENCODING IS EXPLICIT AND THAT IS THE POINT. `CFStringCreateWithBytes` takes
/// the encoding and an isExternalRepresentation flag; passing UTF-8 with the
/// flag FALSE means "these bytes are UTF-8 and carry no BOM". Passing it TRUE
/// would make CF look for a byte-order mark and, finding none, still succeed --
/// silently accepting a different contract than the one Swift's UTF-8 view
/// provides. The step-4 fixtures put a non-ASCII key through this path so the
/// encoding is measured rather than assumed; an ASCII-only corpus would pass
/// with almost any encoding argument.
internal func _udCFString(_ s: String) -> UDCFString? {
    var bytes = Array(s.utf8)
    let n = bytes.count
    return bytes.withUnsafeMutableBufferPointer { buf in
        CFStringCreateWithBytes(nil, buf.baseAddress, FMCFIndex(n),
                                FMCFStringEncoding(kCFStringEncodingUTF8), 0)
    }
}

/// FMCFStringRef -> Swift String.
///
/// Two-pass, because CFStringGetCString needs a buffer and CFStringGetLength is
/// in UTF-16 units, not bytes. Four bytes per unit is the worst case for UTF-8
/// plus one for the terminator; a short buffer makes CFStringGetCString return
/// false rather than truncate, which is why the failure is a nil and not a
/// clipped string.
internal func _udSwiftString(_ cf: UDCFString) -> String? {
    let units = CFStringGetLength(cf)
    let cap = Int(units) * 4 + 1
    var buf = [CChar](repeating: 0, count: cap)
    let ok = buf.withUnsafeMutableBufferPointer { b -> CFBoolean_t in
        CFStringGetCString(cf, b.baseAddress, FMCFIndex(cap),
                           FMCFStringEncoding(kCFStringEncodingUTF8))
    }
    guard ok != 0 else { return nil }
    return String(cString: buf)
}

// MARK: - Values

/// Swift value -> a CF object CFPreferences will store.
///
/// BOOL IS TESTED BEFORE THE INTEGERS, and CFBoolean is a distinct CF type from
/// CFNumber. This is the NSNumber folding hazard at the C level: a CFNumber
/// holding 1 and kCFBooleanTrue are different objects with different type IDs,
/// and collapsing them turns a stored `true` into a stored `1` -- which the
/// Darwin oracle can see, because `object(forKey:)` reports the dynamic type.
internal func _udToCF(_ value: Any) -> FMCFTypeRef? {
    switch value {
    case let v as Bool:
        return UnsafeRawPointer(v ? kCFBooleanTrue : kCFBooleanFalse)
    case let v as String:
        return _udCFString(v).map { UnsafeRawPointer($0) }
    case let v as Int:
        var x = Int64(v)
        return CFNumberCreate(nil, FMCFIndex(kCFNumberSInt64Type), &x).map { UnsafeRawPointer($0) }
    case let v as Double:
        var x = v
        return CFNumberCreate(nil, FMCFIndex(kCFNumberFloat64Type), &x).map { UnsafeRawPointer($0) }
    case let v as Float:
        var x = Double(v)
        return CFNumberCreate(nil, FMCFIndex(kCFNumberFloat64Type), &x).map { UnsafeRawPointer($0) }
    default:
        // LOUD, NOT SILENT, and the scope is stated rather than implied.
        // Data, Date, Array and Dictionary are real plist types this bridge
        // does not marshal yet; returning nil here would reach set()'s
        // "not a property-list type" trap and blame the CALLER for a gap in
        // the bridge. The census puts these behind the four types above
        // (set/bool/string/integer are 76% of all member demand), which is why
        // they are second and not first -- not because they are optional.
        _UDUnimplemented("the guest CF bridge does not marshal "
                       + "\(type(of: value)) yet; implemented: Bool, String, "
                       + "Int, Double, Float")
    }
}

/// A CF object from CFPreferences -> a Swift value.
///
/// Type-ID dispatch, because that is what CF itself uses and it is the only
/// thing that distinguishes CFBoolean from CFNumber. Reading the boolean case
/// first mirrors _udToCF, so a round trip cannot fold in one direction only.
internal func _udFromCF(_ cf: FMCFTypeRef) -> Any? {
    let id = CFGetTypeID(cf)
    if id == CFBooleanGetTypeID() {
        return CFBooleanGetValue(OpaquePointer(cf)) != 0
    }
    if id == CFNumberGetTypeID() {
        let n = OpaquePointer(cf)
        if CFNumberIsFloatType(n) != 0 {
            var d = Double(0)
            _ = CFNumberGetValue(n, FMCFIndex(kCFNumberFloat64Type), &d)
            return d
        }
        var i = Int64(0)
        _ = CFNumberGetValue(n, FMCFIndex(kCFNumberSInt64Type), &i)
        return Int(i)
    }
    if id == CFStringGetTypeID() {
        return _udSwiftString(OpaquePointer(cf))
    }
    // Reported rather than dropped: an unmarshalled type read back as nil is
    // indistinguishable from an absent key, which is the answer this project
    // keeps finding people accept by accident.
    _UDUnimplemented("the guest CF bridge cannot read CF type id \(id) yet; "
                   + "implemented: CFBoolean, CFNumber, CFString")
}

// MARK: - The preferences calls

internal func _udCurrentApplication() -> UDCFString {
    kCFPreferencesCurrentApplication
}

internal func _udCopyValue(_ key: String, _ appID: UDCFString) -> Any? {
    guard let k = _udCFString(key) else { return nil }
    defer { CFRelease(UnsafeRawPointer(k)) }
    guard let v = CFPreferencesCopyAppValue(k, appID) else { return nil }
    defer { CFRelease(v) }          // CopyAppValue returns +1
    return _udFromCF(v)
}

internal func _udSetValue(_ value: Any?, _ key: String, _ appID: UDCFString) {
    guard let k = _udCFString(key) else { return }
    defer { CFRelease(UnsafeRawPointer(k)) }
    guard let value = value else {
        CFPreferencesSetAppValue(k, nil, appID)
        return
    }
    guard let v = _udToCF(value) else { return }
    CFPreferencesSetAppValue(k, v, appID)
}

internal func _udSynchronize(_ appID: UDCFString) -> Bool {
    CFPreferencesAppSynchronize(appID) != 0
}

internal func _udAddSuite(_ suite: String) {
    guard let s = _udCFString(suite) else { return }
    defer { CFRelease(UnsafeRawPointer(s)) }
    CFPreferencesAddSuitePreferencesToApp(kCFPreferencesCurrentApplication, s)
}

internal func _udRemoveSuite(_ suite: String) {
    guard let s = _udCFString(suite) else { return }
    defer { CFRelease(UnsafeRawPointer(s)) }
    CFPreferencesRemoveSuitePreferencesFromApp(kCFPreferencesCurrentApplication, s)
}

/// The domain enumeration.
///
/// EMPTY, AND SAID SO RATHER THAN LEFT TO BE DISCOVERED. Reading the whole
/// domain needs CFArray and CFDictionary marshalling, which this bridge does
/// not do yet. It returns empty rather than aborting because
/// `dictionaryRepresentation()` returning {} is a legible wrong answer a caller
/// can notice, whereas aborting would take down a runner that merely touched a
/// method it does not depend on -- and because the two members that use it are
/// 12 and 32 uses in the corpus against `set`'s 658.
///
/// A caller that needs it will see an empty dictionary where the host oracle
/// sees a populated one, which is exactly the row the scoreboard should fail
/// on. Do not "fix" it by making the host side empty too.
internal func _udCopyAll(_ appID: UDCFString) -> [String: Any] { [:] }


// MARK: - The libc surface, declared not imported
//
// Same rule as the CF side: `import Darwin` would pull Apple's Swift Darwin
// OVERLAY DYLIBS into the load graph, and those depend on Apple's Foundation.
// See include/UDPlatformMinimal.h.

internal typealias _UDMutexStorage = ud_pthread_mutex_t
internal func _udMutexInit(_ m: inout _UDMutexStorage)    { _ = ud_pthread_mutex_init(&m, nil) }
internal func _udMutexDestroy(_ m: inout _UDMutexStorage) { _ = ud_pthread_mutex_destroy(&m) }
internal func _udMutexLock(_ m: inout _UDMutexStorage)    { _ = ud_pthread_mutex_lock(&m) }
internal func _udMutexUnlock(_ m: inout _UDMutexStorage)  { _ = ud_pthread_mutex_unlock(&m) }

internal func _udVsnprintf(_ buf: UnsafeMutablePointer<CChar>?, _ n: Int,
                           _ fmt: String, _ va: CVaListPointer) {
    _ = fmt.withCString { f in ud_vsnprintf(buf, n, f, va) }
}
internal func _udGetenv(_ name: String) -> UnsafeMutablePointer<CChar>? {
    name.withCString { ud_getenv($0) }
}
internal func _udWriteStderr(_ p: UnsafePointer<CChar>) {
    _ = ud_write(2, p, ud_strlen(p))
}

#endif  // !UD_HOST_ORACLE
