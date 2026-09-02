// A deliberately narrow CoreFoundation spelling bridge for Foundation-only
// clients. The returned value is FoundationEssentials.URL itself; there is no
// shadow CF object, platform-framework load, or success-without-parsing path.

import FoundationEssentials

/// The supported bridge accepts only CoreFoundation's default allocator,
/// represented by `nil`. The uninhabited type keeps unsupported custom
/// allocators from being mistaken for implemented behavior.
public enum CFAllocator: Sendable {}

public typealias CFString = String
public typealias CFURL = URL
public typealias CFDictionary = [CFString: Any]
public typealias CFMutableDictionary = CFDictionary
public typealias CFTypeRef = AnyObject
public typealias CFBoolean = Bool
public typealias CFTimeInterval = Double
public typealias CFAbsoluteTime = CFTimeInterval
@_alwaysEmitIntoClient
public var kCFAllocatorDefault: CFAllocator? { nil }
public let kCFBooleanTrue: CFBoolean = true
public let kCFBooleanFalse: CFBoolean = false

@_alwaysEmitIntoClient
public func CFBooleanGetValue(_ value: CFBoolean) -> Bool { value }

/// CoreFoundation's ABI-stable sixteen-byte UUID carrier.
public struct CFUUIDBytes: Sendable {
    public var byte0: UInt8
    public var byte1: UInt8
    public var byte2: UInt8
    public var byte3: UInt8
    public var byte4: UInt8
    public var byte5: UInt8
    public var byte6: UInt8
    public var byte7: UInt8
    public var byte8: UInt8
    public var byte9: UInt8
    public var byte10: UInt8
    public var byte11: UInt8
    public var byte12: UInt8
    public var byte13: UInt8
    public var byte14: UInt8
    public var byte15: UInt8

    public init() {
        self.init(
            byte0: 0, byte1: 0, byte2: 0, byte3: 0,
            byte4: 0, byte5: 0, byte6: 0, byte7: 0,
            byte8: 0, byte9: 0, byte10: 0, byte11: 0,
            byte12: 0, byte13: 0, byte14: 0, byte15: 0
        )
    }

    public init(
        byte0: UInt8,
        byte1: UInt8,
        byte2: UInt8,
        byte3: UInt8,
        byte4: UInt8,
        byte5: UInt8,
        byte6: UInt8,
        byte7: UInt8,
        byte8: UInt8,
        byte9: UInt8,
        byte10: UInt8,
        byte11: UInt8,
        byte12: UInt8,
        byte13: UInt8,
        byte14: UInt8,
        byte15: UInt8
    ) {
        self.byte0 = byte0
        self.byte1 = byte1
        self.byte2 = byte2
        self.byte3 = byte3
        self.byte4 = byte4
        self.byte5 = byte5
        self.byte6 = byte6
        self.byte7 = byte7
        self.byte8 = byte8
        self.byte9 = byte9
        self.byte10 = byte10
        self.byte11 = byte11
        self.byte12 = byte12
        self.byte13 = byte13
        self.byte14 = byte14
        self.byte15 = byte15
    }

    fileprivate var array: [UInt8] {
        [
            byte0, byte1, byte2, byte3,
            byte4, byte5, byte6, byte7,
            byte8, byte9, byte10, byte11,
            byte12, byte13, byte14, byte15,
        ]
    }
}

/// Immutable CoreFoundation UUID identity used by CBUUID's byte bridge.
public final class CFUUID: Hashable, @unchecked Sendable {
    fileprivate let bytes: CFUUIDBytes

    fileprivate init(bytes: CFUUIDBytes) {
        self.bytes = bytes
    }

    public static func == (lhs: CFUUID, rhs: CFUUID) -> Bool {
        lhs.bytes.array == rhs.bytes.array
    }

    public func hash(into hasher: inout Hasher) {
        for byte in bytes.array { hasher.combine(byte) }
    }
}

public func CFUUIDCreateFromUUIDBytes(
    _ allocator: CFAllocator?,
    _ bytes: CFUUIDBytes
) -> CFUUID? {
    _ = allocator
    return CFUUID(bytes: bytes)
}

public func CFUUIDGetUUIDBytes(_ uuid: CFUUID?) -> CFUUIDBytes {
    guard let uuid else {
        preconditionFailure("CFUUIDGetUUIDBytes requires a UUID")
    }
    return uuid.bytes
}

/// Creates a real URL while preserving valid percent escapes. CFURL accepts
/// square brackets outside an IPv6 authority by encoding just those brackets,
/// which is why unchanged SwiftSoup calls this API on Darwin. Other invalid
/// characters remain failures; for example, an unescaped space returns nil.
public func CFURLCreateWithString(
    _ allocator: CFAllocator?,
    _ URLString: CFString,
    _ baseURL: CFURL?
) -> CFURL? {
    _ = allocator // Only nil is constructible outside this module.
    guard let normalized = _foundationGuestCFURLNormalizedString(URLString)
    else { return nil }
    if baseURL == nil {
        return URL(
            string: normalized,
            encodingInvalidCharacters: false
        )
    }
    return URL(string: normalized, relativeTo: baseURL)
}

private func _foundationGuestCFURLNormalizedString(_ input: String) -> String? {
    let scalars = Array(input.unicodeScalars)
    var authorityStart: Int?
    if scalars.count >= 3 {
        for offset in 0...(scalars.count - 3) {
            if scalars[offset].value == 0x3A,
               scalars[offset + 1].value == 0x2F,
               scalars[offset + 2].value == 0x2F {
                authorityStart = offset + 3
                break
            }
        }
    }

    var authorityEnd = scalars.count
    if let authorityStart {
        for offset in authorityStart..<scalars.count {
            if [UInt32(0x2F), 0x3F, 0x23].contains(scalars[offset].value) {
                authorityEnd = offset
                break
            }
        }
    }

    var result = ""
    result.reserveCapacity(input.utf8.count)
    var offset = 0

    while offset < scalars.count {
        let scalar = scalars[offset]
        if scalar.value == 0x25,
           offset + 2 < scalars.count,
           _foundationGuestIsASCIIHex(scalars[offset + 1]),
           _foundationGuestIsASCIIHex(scalars[offset + 2]) {
            result.unicodeScalars.append(scalar)
            result.unicodeScalars.append(scalars[offset + 1])
            result.unicodeScalars.append(scalars[offset + 2])
            offset += 3
            continue
        }

        let inAuthority = authorityStart.map {
            offset >= $0 && offset < authorityEnd
        } ?? false
        if _foundationGuestIsCFURLAllowedASCII(scalar, inAuthority: inAuthority) {
            result.unicodeScalars.append(scalar)
        } else if scalar.value == 0x5B {
            result += "%5B"
        } else if scalar.value == 0x5D {
            result += "%5D"
        } else {
            return nil
        }
        offset += 1
    }
    return result
}

private func _foundationGuestIsASCIIHex(_ scalar: Unicode.Scalar) -> Bool {
    switch scalar.value {
    case 0x30...0x39, 0x41...0x46, 0x61...0x66: return true
    default: return false
    }
}

private func _foundationGuestIsCFURLAllowedASCII(
    _ scalar: Unicode.Scalar,
    inAuthority: Bool
) -> Bool {
    switch scalar.value {
    case 0x30...0x39, 0x41...0x5A, 0x61...0x7A:
        return true
    case 0x2D, 0x2E, 0x5F, 0x7E, // unreserved punctuation
         0x3A, 0x2F, 0x3F, 0x23, 0x40, // general delimiters
         0x21, 0x24, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x2B, 0x2C, 0x3B, 0x3D:
        return true
    case 0x5B, 0x5D: // IPv6 brackets only; elsewhere CFURL percent-encodes.
        return inAuthority
    default:
        return false
    }
}
