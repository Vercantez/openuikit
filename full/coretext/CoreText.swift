import Foundation

public let kCTFontManagerErrorDomain: CFString = "com.apple.CoreText.CTFontManagerErrorDomain"
public let kCTFontManagerErrorFontURLsKey: CFString = "CTFontManagerErrorFontURLs"
public let kCTFontManagerErrorFontDescriptorsKey: CFString = "CTFontManagerErrorFontDescriptors"
public let kCTFontManagerErrorFontAssetNameKey: CFString = "CTFontManagerErrorFontAssetName"

public enum CTFontManagerScope: UInt32, Sendable {
    case none = 0
    case process = 1
    case persistent = 2
    case session = 3
}

public enum CTFontManagerError: Int, Error, Sendable {
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

private final class _PortableFontRegistration: @unchecked Sendable {
    static let shared = _PortableFontRegistration()
    let lock = NSLock()
    var records: [(URL, Data)] = []
}

private func _setFontRegistrationError(
    _ destination: UnsafeMutablePointer<Unmanaged<CFError>?>?,
    code: CTFontManagerError,
    url: URL
) {
    guard let destination else { return }
    let value = NSError(
        domain: kCTFontManagerErrorDomain,
        code: code.rawValue,
        userInfo: [kCTFontManagerErrorFontURLsKey: [url]]
    )
    let cfError = unsafeBitCast(value, to: CFError.self)
    destination.pointee = Unmanaged.passRetained(cfError)
}

private func _isRecognizedFont(_ data: Data) -> Bool {
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
    guard scope == .process else {
        _setFontRegistrationError(errorOut, code: .unsupportedScope, url: fontURL)
        return false
    }
    let url = fontURL.standardizedFileURL
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
