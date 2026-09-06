import CoreFoundation
import Foundation

// Linux Foundation does not toll-free-bridge with `as`. These helpers match
// the CoreText/MediaAccessibility host pattern and are not a second
// CoreFoundation identity.

@inline(__always)
func _csCFString(_ value: String) -> CFString {
    unsafeBitCast(value as NSString, to: CFString.self)
}

@inline(__always)
func _csString(_ value: CFString) -> String {
    unsafeBitCast(value, to: NSString.self) as String
}

@inline(__always)
func _csCFData(_ data: Data) -> CFData {
    unsafeBitCast(data as NSData, to: CFData.self)
}

@inline(__always)
func _csData(_ data: CFData) -> Data {
    unsafeBitCast(data, to: NSData.self) as Data
}

@inline(__always)
func _csCFURL(_ url: URL) -> CFURL {
    unsafeBitCast(url as NSURL, to: CFURL.self)
}

@inline(__always)
func _csURL(_ url: CFURL) -> URL {
    unsafeBitCast(url, to: NSURL.self) as URL
}

@inline(__always)
func _csCFArray(_ array: NSArray) -> CFArray {
    unsafeBitCast(array, to: CFArray.self)
}

@inline(__always)
func _csNSArray(_ array: CFArray) -> NSArray {
    unsafeBitCast(array, to: NSArray.self)
}

@inline(__always)
func _csCFDictionary(_ dictionary: NSDictionary) -> CFDictionary {
    unsafeBitCast(dictionary, to: CFDictionary.self)
}

@inline(__always)
func _csNSDictionary(_ dictionary: CFDictionary) -> NSDictionary {
    unsafeBitCast(dictionary, to: NSDictionary.self)
}

@inline(__always)
func _csCFError(_ error: NSError) -> CFError {
    unsafeBitCast(error, to: CFError.self)
}

@inline(__always)
func _csNSError(_ error: CFError) -> NSError {
    unsafeBitCast(error, to: NSError.self)
}

@inline(__always)
func _csPassString(_ value: String) -> Unmanaged<CFString> {
    Unmanaged.passUnretained(_csCFString(value))
}

let kColorSyncLinuxErrorDomain = "com.apple.ColorSync.error"

enum _CSErrorCode: Int {
    case invalidData = 1
    case unsupported = 2
    case missingResource = 3
    case invalidArgument = 4
}

func _csWriteError(
    _ destination: UnsafeMutablePointer<Unmanaged<CFError>?>?,
    code: _CSErrorCode,
    message: String
) {
    guard let destination else { return }
    let error = NSError(
        domain: kColorSyncLinuxErrorDomain,
        code: code.rawValue,
        userInfo: [NSLocalizedDescriptionKey: message]
    )
    destination.pointee = Unmanaged.passRetained(_csCFError(error))
}

func _csInternedString(_ value: String) -> CFString {
    _CSStringIntern.shared.intern(value)
}

final class _CSStringIntern: @unchecked Sendable {
    static let shared = _CSStringIntern()
    private let lock = NSLock()
    private var table: [String: CFString] = [:]

    func intern(_ value: String) -> CFString {
        lock.lock()
        defer { lock.unlock() }
        if let existing = table[value] {
            return existing
        }
        let stored = _csCFString(value)
        table[value] = stored
        return stored
    }
}

func _csConstant(_ value: String) -> Unmanaged<CFString>! {
    Unmanaged.passUnretained(_csInternedString(value))
}
