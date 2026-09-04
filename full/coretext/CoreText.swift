import CoreFoundation
import Foundation

public let kCTFontManagerErrorDomain: CFString = _ctCFString("com.apple.CoreText.CTFontManagerErrorDomain")
public let kCTFontManagerErrorFontURLsKey: CFString = _ctCFString("CTFontManagerErrorFontURLs")
public let kCTFontManagerErrorFontDescriptorsKey: CFString = _ctCFString("CTFontManagerErrorFontDescriptors")
public let kCTFontManagerErrorFontAssetNameKey: CFString = _ctCFString("CTFontManagerErrorFontAssetName")

public enum CTFontManagerScope: UInt32, Sendable, Hashable {
    case none = 0
    case process = 1
    case persistent = 2
    case session = 3

    public static var user: CTFontManagerScope { .persistent }
}

public enum CTFontManagerError: Int, Error, Sendable, Hashable {
    case fileNotFound = 101
    case insufficientPermissions = 102
    case unrecognizedFormat = 103
    case invalidFontData = 104
    case alreadyRegistered = 105
    case exceededResourceLimit = 106
    case assetNotFound = 107
    case notRegistered = 201
    case inUse = 202
    case systemRequired = 203
    case registrationFailed = 301
    case missingEntitlement = 302
    case insufficientInfo = 303
    case cancelledByUser = 304
    case duplicatedName = 305
    case invalidFilePath = 306
    case unsupportedScope = 307
}

final class _PortableFontRegistration: @unchecked Sendable {
    static let shared = _PortableFontRegistration()
    let lock = NSLock()
    var records: [(URL, Data)] = []
}

func _setFontRegistrationError(
    _ destination: UnsafeMutablePointer<Unmanaged<CFError>?>?,
    code: CTFontManagerError,
    url: URL
) {
    guard let destination else { return }
    let value = NSError(
        domain: _ctString(kCTFontManagerErrorDomain),
        code: code.rawValue,
        userInfo: [_ctString(kCTFontManagerErrorFontURLsKey): [url]]
    )
    let cfError = _ctCFError(value)
    destination.pointee = Unmanaged.passRetained(cfError)
}

func _isRecognizedFont(_ data: Data) -> Bool {
    guard data.count >= 12 else { return false }
    return data.withUnsafeBytes { bytes in
        guard let base = bytes.bindMemory(to: UInt8.self).baseAddress else {
            return false
        }
        let signature = (UInt32(base[0]) << 24) | (UInt32(base[1]) << 16)
            | (UInt32(base[2]) << 8) | UInt32(base[3])
        return signature == 0x00010000
            || signature == 0x4F54544F // OTTO
            || signature == 0x74727565 // true
            || signature == 0x74746366 // ttcf
    }
}

public func CTFontManagerRegisterFontsForURL(
    _ fontURL: CFURL,
    _ scope: CTFontManagerScope,
    _ errorOut: UnsafeMutablePointer<Unmanaged<CFError>?>?
) -> Bool {
    let url = _ctURL(fontURL).standardizedFileURL
    guard scope == .process else {
        _setFontRegistrationError(errorOut, code: .unsupportedScope, url: url)
        return false
    }
    guard url.isFileURL else {
        _setFontRegistrationError(errorOut, code: .invalidFilePath, url: url)
        return false
    }
    let data: Data
    do {
        data = try Data(contentsOf: url)
    } catch {
        _setFontRegistrationError(errorOut, code: .fileNotFound, url: url)
        return false
    }
    guard _isRecognizedFont(data) else {
        _setFontRegistrationError(errorOut, code: .unrecognizedFormat, url: url)
        return false
    }

    let registry = _PortableFontRegistration.shared
    registry.lock.lock()
    defer { registry.lock.unlock() }
    if registry.records.contains(where: { $0.0 == url }) {
        _setFontRegistrationError(errorOut, code: .alreadyRegistered, url: url)
        return false
    }
    registry.records.append((url, data))
    errorOut?.pointee = nil
    return true
}

public func CTFontManagerUnregisterFontsForURL(
    _ fontURL: CFURL,
    _ scope: CTFontManagerScope,
    _ errorOut: UnsafeMutablePointer<Unmanaged<CFError>?>?
) -> Bool {
    let url = _ctURL(fontURL).standardizedFileURL
    guard scope == .process else {
        _setFontRegistrationError(errorOut, code: .unsupportedScope, url: url)
        return false
    }
    let registry = _PortableFontRegistration.shared
    registry.lock.lock()
    defer { registry.lock.unlock() }
    guard let index = registry.records.firstIndex(where: { $0.0 == url }) else {
        _setFontRegistrationError(errorOut, code: .notRegistered, url: url)
        return false
    }
    registry.records.remove(at: index)
    errorOut?.pointee = nil
    return true
}

public func CTFontManagerRegisterFontsForURLs(
    _ fontURLs: CFArray,
    _ scope: CTFontManagerScope,
    _ errors: UnsafeMutablePointer<Unmanaged<CFArray>?>?
) -> Bool {
    let urls = (_ctNSArray(fontURLs)).compactMap { $0 as? URL }
    var failed: [NSError] = []
    for url in urls {
        var unmanaged: Unmanaged<CFError>?
        if !CTFontManagerRegisterFontsForURL(_ctCFURL(url), scope, &unmanaged) {
            if let unmanaged {
                failed.append(_ctNSError(unmanaged.takeRetainedValue()))
            }
        }
    }
    if failed.isEmpty {
        errors?.pointee = nil
        return true
    }
    let array = _ctCFArray(failed as NSArray)
    errors?.pointee = Unmanaged.passRetained(array)
    return false
}

public func CTFontManagerUnregisterFontsForURLs(
    _ fontURLs: CFArray,
    _ scope: CTFontManagerScope,
    _ errors: UnsafeMutablePointer<Unmanaged<CFArray>?>?
) -> Bool {
    let urls = (_ctNSArray(fontURLs)).compactMap { $0 as? URL }
    var failed: [NSError] = []
    for url in urls {
        var unmanaged: Unmanaged<CFError>?
        if !CTFontManagerUnregisterFontsForURL(_ctCFURL(url), scope, &unmanaged) {
            if let unmanaged {
                failed.append(_ctNSError(unmanaged.takeRetainedValue()))
            }
        }
    }
    if failed.isEmpty {
        errors?.pointee = nil
        return true
    }
    errors?.pointee = Unmanaged.passRetained(_ctCFArray(failed as NSArray))
    return false
}

public func CTFontManagerCopyAvailableFontFamilyNames() -> CFArray {
    let names = _portableAvailableFamilyNames()
    return _ctCFArray(names as NSArray)
}

public func CTFontManagerCopyAvailablePostScriptNames() -> CFArray {
    let names = _portableAvailablePostScriptNames()
    return _ctCFArray(names as NSArray)
}

public func CTFontManagerCopyRegisteredFontDescriptors(
    _ scope: CTFontManagerScope,
    _ enabled: Bool
) -> CFArray {
    _ = enabled
    guard scope == .process || scope == .none else {
        return _ctEmptyCFArray()
    }
    return _ctCFArray(_portableRegisteredDescriptors() as NSArray)
}

public func CTFontManagerCreateFontDescriptorsFromURL(_ fileURL: CFURL) -> CFArray? {
    let url = _ctURL(fileURL).standardizedFileURL
    guard url.isFileURL, let data = try? Data(contentsOf: url), _isRecognizedFont(data) else {
        return nil
    }
    let parsed = _SFNTMetrics.parse(data: data)
    let descriptor = CTFontDescriptor(
        attributes: [
            _ctString(kCTFontURLAttribute): url,
            _ctString(kCTFontNameAttribute): parsed.postScriptName,
            _ctString(kCTFontFamilyNameAttribute): parsed.familyName,
            _ctString(kCTFontDisplayNameAttribute): parsed.fullName,
        ]
    )
    return _ctCFArray([descriptor] as NSArray)
}

public func CTFontManagerCreateFontDescriptorFromData(_ data: CFData) -> CTFontDescriptor? {
    let bytes = _ctData(data)
    guard _isRecognizedFont(bytes) else { return nil }
    let parsed = _SFNTMetrics.parse(data: bytes)
    return CTFontDescriptor(
        attributes: [
            _ctString(kCTFontNameAttribute): parsed.postScriptName,
            _ctString(kCTFontFamilyNameAttribute): parsed.familyName,
            _ctString(kCTFontDisplayNameAttribute): parsed.fullName,
        ]
    )
}

public func CTFontManagerCreateFontDescriptorsFromData(_ data: CFData) -> CFArray {
    if let descriptor = CTFontManagerCreateFontDescriptorFromData(data) {
        return _ctCFArray([descriptor] as NSArray)
    }
    return _ctEmptyCFArray()
}

public func CTFontManagerRegisterFontURLs(
    _ fontURLs: CFArray,
    _ scope: CTFontManagerScope,
    _ enabled: Bool,
    _ registrationHandler: ((CFArray, Bool) -> Bool)?
) {
    _ = enabled
    var errors: Unmanaged<CFArray>?
    let ok = CTFontManagerRegisterFontsForURLs(fontURLs, scope, &errors)
    if let registrationHandler {
        let payload = (errors?.takeRetainedValue() ?? _ctEmptyCFArray())
        _ = registrationHandler(payload, ok)
    } else {
        _ = errors?.takeRetainedValue()
    }
}

public func CTFontManagerUnregisterFontURLs(
    _ fontURLs: CFArray,
    _ scope: CTFontManagerScope,
    _ registrationHandler: ((CFArray, Bool) -> Bool)?
) {
    var errors: Unmanaged<CFArray>?
    let ok = CTFontManagerUnregisterFontsForURLs(fontURLs, scope, &errors)
    if let registrationHandler {
        let payload = (errors?.takeRetainedValue() ?? _ctEmptyCFArray())
        _ = registrationHandler(payload, ok)
    } else {
        _ = errors?.takeRetainedValue()
    }
}

public func CTFontManagerRegisterFontDescriptors(
    _ fontDescriptors: CFArray,
    _ scope: CTFontManagerScope,
    _ enabled: Bool,
    _ registrationHandler: ((CFArray, Bool) -> Bool)?
) {
    _ = (fontDescriptors, enabled)
    guard scope == .process else {
        _ = registrationHandler?(_ctEmptyCFArray(), false)
        return
    }
    _ = registrationHandler?(fontDescriptors, true)
}

public func CTFontManagerUnregisterFontDescriptors(
    _ fontDescriptors: CFArray,
    _ scope: CTFontManagerScope,
    _ registrationHandler: ((CFArray, Bool) -> Bool)?
) {
    _ = (fontDescriptors, scope)
    _ = registrationHandler?(fontDescriptors, true)
}

public func CTFontManagerRegisterFontsWithAssetNames(
    _ fontAssetNames: CFArray,
    _ bundle: CFBundle?,
    _ scope: CTFontManagerScope,
    _ enabled: Bool,
    _ registrationHandler: ((CFArray, Bool) -> Bool)?
) {
    _ = (fontAssetNames, bundle, scope, enabled)
    _ = registrationHandler?(_ctEmptyCFArray(), false)
}

public func CTFontManagerRequestFonts(
    _ fontDescriptors: CFArray,
    _ completionHandler: @escaping (CFArray) -> Void
) {
    completionHandler(fontDescriptors)
}

public func CTGetCoreTextVersion() -> UInt32 {
    UInt32(bitPattern: kCTVersionNumber11_0)
}

func _portableAvailableFamilyNames() -> [String] {
    let registry = _PortableFontRegistration.shared
    registry.lock.lock()
    defer { registry.lock.unlock() }
    var names = Set<String>()
    names.insert(_PortableMetrics.familyName)
    for (_, data) in registry.records {
        names.insert(_SFNTMetrics.parse(data: data).familyName)
    }
    return names.sorted()
}

func _portableAvailablePostScriptNames() -> [String] {
    let registry = _PortableFontRegistration.shared
    registry.lock.lock()
    defer { registry.lock.unlock() }
    var names = Set<String>()
    names.insert(_PortableMetrics.postScriptName)
    for (_, data) in registry.records {
        names.insert(_SFNTMetrics.parse(data: data).postScriptName)
    }
    return names.sorted()
}

func _portableRegisteredDescriptors() -> [CTFontDescriptor] {
    let registry = _PortableFontRegistration.shared
    registry.lock.lock()
    defer { registry.lock.unlock() }
    return registry.records.map { url, data in
        let parsed = _SFNTMetrics.parse(data: data)
        return CTFontDescriptor(
            attributes: [
                _ctString(kCTFontURLAttribute): url,
                _ctString(kCTFontNameAttribute): parsed.postScriptName,
                _ctString(kCTFontFamilyNameAttribute): parsed.familyName,
                _ctString(kCTFontDisplayNameAttribute): parsed.fullName,
            ]
        )
    }
}

func _portableCopyRegisteredData() -> [Data] {
    let registry = _PortableFontRegistration.shared
    registry.lock.lock()
    defer { registry.lock.unlock() }
    return registry.records.map(\.1)
}
