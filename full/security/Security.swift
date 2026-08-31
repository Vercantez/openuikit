@_exported import Foundation

public typealias OSStatus = Int32

public let errSecSuccess: OSStatus = 0
#if OPENUIKIT_PORTABLE_FOUNDATION
// Darwin exposes this historical spelling through its C overlays.  The
// portable Foundation does not, but unchanged keychain clients still use it.
public let noErr: OSStatus = errSecSuccess
#endif
public let errSecUnimplemented: OSStatus = -4
public let errSecIO: OSStatus = -36
public let errSecParam: OSStatus = -50
public let errSecInvalidValue: OSStatus = errSecParam
public let errSecAllocate: OSStatus = -108
public let errSecNotAvailable: OSStatus = -25_291
public let errSecAuthFailed: OSStatus = -25_293
public let errSecDuplicateItem: OSStatus = -25_299
public let errSecItemNotFound: OSStatus = -25_300
public let errSecInvalidEncoding: OSStatus = -67_853

public let kSecClass = "class" as CFString
public let kSecClassGenericPassword = "genp" as CFString
public let kSecAttrAccount = "acct" as CFString
public let kSecAttrService = "svce" as CFString
public let kSecAttrAccessGroup = "agrp" as CFString
public let kSecAttrAccessible = "pdmn" as CFString
public let kSecAttrSynchronizable = "sync" as CFString
public let kSecAttrSynchronizableAny = "sync-any" as CFString
public let kSecValueData = "v_Data" as CFString
public let kSecMatchLimit = "m_Limit" as CFString
public let kSecMatchLimitOne = "m_LimitOne" as CFString
public let kSecMatchLimitAll = "m_LimitAll" as CFString
public let kSecReturnData = "r_Data" as CFString
public let kSecReturnAttributes = "r_Attributes" as CFString
public let kSecReturnPersistentRef = "r_PersistentRef" as CFString

public let kSecAttrAccessibleWhenUnlocked = "ak" as CFString
public let kSecAttrAccessibleWhenUnlockedThisDeviceOnly = "akpu" as CFString
public let kSecAttrAccessibleAfterFirstUnlock = "ck" as CFString
public let kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly = "cku" as CFString
public let kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly = "akpu-passcode" as CFString

private let _securityControlKeys: Set<String> = [
    kSecMatchLimit as String,
    kSecReturnData as String,
    kSecReturnAttributes as String,
    kSecReturnPersistentRef as String,
]

private final class _PortableKeychain: @unchecked Sendable {
    static let shared = _PortableKeychain()
    let lock = NSLock()
    var items: [[String: Any]] = []
}

private func _securityDictionary(_ value: CFDictionary) -> [String: Any] {
#if OPENUIKIT_PORTABLE_FOUNDATION
    return value
#else
    let bridged = value as NSDictionary
    var result: [String: Any] = [:]
    bridged.forEach { rawKey, rawValue in
        if let key = rawKey as? String {
            result[key] = rawValue
        }
    }
    return result
#endif
}

private func _securityCFDictionary(_ value: [String: Any]) -> [CFString: Any] {
    var result: [CFString: Any] = [:]
    for (key, item) in value {
        result[key as CFString] = item
    }
    return result
}

private func _securityEqual(_ lhs: Any, _ rhs: Any) -> Bool {
    if let lhs = lhs as? String, let rhs = rhs as? String { return lhs == rhs }
    if let lhs = lhs as? Bool, let rhs = rhs as? Bool { return lhs == rhs }
    if let lhs = lhs as? Int, let rhs = rhs as? Int { return lhs == rhs }
    if let lhs = lhs as? Data, let rhs = rhs as? Data { return lhs == rhs }
    return String(describing: lhs) == String(describing: rhs)
}

private func _securityMatches(_ item: [String: Any], query: [String: Any]) -> Bool {
    for (key, expected) in query where !_securityControlKeys.contains(key) {
        if key == (kSecAttrSynchronizable as String),
           let value = expected as? String,
           value == (kSecAttrSynchronizableAny as String) {
            continue
        }
        guard let actual = item[key], _securityEqual(actual, expected) else {
            return false
        }
    }
    return true
}

private func _securityIdentityMatches(
    _ item: [String: Any], candidate: [String: Any]
) -> Bool {
    for key in [
        kSecClass as String,
        kSecAttrAccount as String,
        kSecAttrService as String,
        kSecAttrAccessGroup as String,
        kSecAttrSynchronizable as String,
    ] {
        switch (item[key], candidate[key]) {
        case (nil, nil): continue
        case let (lhs?, rhs?) where _securityEqual(lhs, rhs): continue
        default: return false
        }
    }
    return true
}

@discardableResult
public func SecItemAdd(
    _ attributes: CFDictionary,
    _ result: UnsafeMutablePointer<CFTypeRef?>?
) -> OSStatus {
    let candidate = _securityDictionary(attributes)
    guard candidate[kSecClass as String] != nil,
          candidate[kSecValueData as String] is Data else {
        return errSecParam
    }
    let store = _PortableKeychain.shared
    store.lock.lock()
    defer { store.lock.unlock() }
    if store.items.contains(where: { _securityIdentityMatches($0, candidate: candidate) }) {
        return errSecDuplicateItem
    }
    store.items.append(candidate)
    result?.pointee = nil
    return errSecSuccess
}

@discardableResult
public func SecItemUpdate(
    _ query: CFDictionary,
    _ attributesToUpdate: CFDictionary
) -> OSStatus {
    let query = _securityDictionary(query)
    let updates = _securityDictionary(attributesToUpdate)
    let store = _PortableKeychain.shared
    store.lock.lock()
    defer { store.lock.unlock() }
    var matched = false
    for index in store.items.indices where _securityMatches(store.items[index], query: query) {
        matched = true
        for (key, value) in updates { store.items[index][key] = value }
    }
    return matched ? errSecSuccess : errSecItemNotFound
}

@discardableResult
public func SecItemDelete(_ query: CFDictionary) -> OSStatus {
    let query = _securityDictionary(query)
    let store = _PortableKeychain.shared
    store.lock.lock()
    defer { store.lock.unlock() }
    let originalCount = store.items.count
    store.items.removeAll { _securityMatches($0, query: query) }
    return store.items.count == originalCount ? errSecItemNotFound : errSecSuccess
}

@discardableResult
public func SecItemCopyMatching(
    _ query: CFDictionary,
    _ result: UnsafeMutablePointer<CFTypeRef?>?
) -> OSStatus {
    let query = _securityDictionary(query)
    let store = _PortableKeychain.shared
    store.lock.lock()
    defer { store.lock.unlock() }
    let matches = store.items.filter { _securityMatches($0, query: query) }
    guard !matches.isEmpty else {
        result?.pointee = nil
        return errSecItemNotFound
    }
    guard let result else { return errSecSuccess }
    let wantsAll = (query[kSecMatchLimit as String] as? String)
        == (kSecMatchLimitAll as String)
    let wantsAttributes = (query[kSecReturnAttributes as String] as? Bool) == true
    let wantsReference = (query[kSecReturnPersistentRef as String] as? Bool) == true
    let wantsData = (query[kSecReturnData as String] as? Bool) == true
    if wantsAll {
        result.pointee = matches.map(_securityCFDictionary) as CFTypeRef
    } else if wantsReference {
        let account = matches[0][kSecAttrAccount as String] as? String ?? ""
        result.pointee = Data(account.utf8) as CFTypeRef
    } else if wantsAttributes {
        result.pointee = _securityCFDictionary(matches[0]) as CFTypeRef
    } else if wantsData, let data = matches[0][kSecValueData as String] as? Data {
        result.pointee = data as CFTypeRef
    } else {
        result.pointee = _securityCFDictionary(matches[0]) as CFTypeRef
    }
    return errSecSuccess
}

public typealias SecRandomRef = OpaquePointer
public let kSecRandomDefault: SecRandomRef? = nil

@discardableResult
public func SecRandomCopyBytes(
    _ random: SecRandomRef?,
    _ count: Int,
    _ bytes: UnsafeMutableRawPointer
) -> OSStatus {
    guard count >= 0 else { return errSecParam }
    _ = random
    var generator = SystemRandomNumberGenerator()
    let buffer = bytes.bindMemory(to: UInt8.self, capacity: count)
    for index in 0..<count {
        buffer[index] = UInt8.random(in: .min ... .max, using: &generator)
    }
    return errSecSuccess
}

public func SecCopyErrorMessageString(
    _ status: OSStatus,
    _ reserved: UnsafeMutableRawPointer?
) -> CFString? {
    _ = reserved
    let message: String
    switch status {
    case errSecSuccess: message = "No error."
    case errSecNotAvailable: message = "Security service is unavailable."
    case errSecAuthFailed: message = "Authorization failed."
    case errSecDuplicateItem: message = "The item already exists."
    case errSecItemNotFound: message = "The item cannot be found."
    case errSecInvalidEncoding: message = "The item has invalid encoding."
    case errSecParam: message = "One or more parameters are invalid."
    case errSecIO: message = "An input/output error occurred."
    default: message = "Security error \(status)."
    }
    return message as CFString
}

public struct SecCSFlags: OptionSet, Sendable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
}

public final class SecStaticCode: @unchecked Sendable {
    fileprivate init() {}
}

public final class SecRequirement: @unchecked Sendable {
    fileprivate init() {}
}

public func SecStaticCodeCreateWithPath(
    _ path: CFURL,
    _ flags: SecCSFlags,
    _ staticCode: UnsafeMutablePointer<SecStaticCode?>
) -> OSStatus {
    _ = path
    _ = flags
    staticCode.pointee = nil
    return errSecNotAvailable
}

public func SecRequirementCreateWithString(
    _ text: CFString,
    _ flags: SecCSFlags,
    _ requirement: UnsafeMutablePointer<SecRequirement?>
) -> OSStatus {
    _ = text
    _ = flags
    requirement.pointee = nil
    return errSecNotAvailable
}

public func SecStaticCodeCheckValidity(
    _ staticCode: SecStaticCode,
    _ flags: SecCSFlags,
    _ requirement: SecRequirement?
) -> OSStatus {
    _ = staticCode
    _ = flags
    _ = requirement
    return errSecNotAvailable
}
