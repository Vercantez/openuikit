@_exported import Foundation
#if os(Linux)
import Glibc
#endif

public typealias OSStatus = Int32

public let errSecSuccess: OSStatus = 0
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
public let kSecAttrSynchronizableAny = "syna" as CFString
public let kSecValueData = "v_Data" as CFString
public let kSecMatchLimit = "m_Limit" as CFString
public let kSecMatchLimitOne = "m_LimitOne" as CFString
public let kSecMatchLimitAll = "m_LimitAll" as CFString
public let kSecReturnData = "r_Data" as CFString
public let kSecReturnAttributes = "r_Attributes" as CFString
public let kSecReturnPersistentRef = "r_PersistentRef" as CFString

public let kSecAttrAccessibleWhenUnlocked = "ak" as CFString
public let kSecAttrAccessibleWhenUnlockedThisDeviceOnly = "aku" as CFString
public let kSecAttrAccessibleAfterFirstUnlock = "ck" as CFString
public let kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly = "cku" as CFString
public let kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly = "akpu" as CFString

private let _securityQueryOnlyKeys: Set<String> = [
    kSecMatchLimit as String,
    kSecMatchLimitOne as String,
    kSecMatchLimitAll as String,
    kSecMatchCaseInsensitive as String,
    kSecMatchEmailAddressIfPresent as String,
    kSecMatchHostOrSubdomainOfHost as String,
    kSecMatchIssuers as String,
    kSecMatchItemList as String,
    kSecMatchPolicy as String,
    kSecMatchSearchList as String,
    kSecMatchSubjectContains as String,
    kSecMatchTrustedOnly as String,
    kSecMatchValidOnDate as String,
    kSecReturnData as String,
    kSecReturnAttributes as String,
    kSecReturnPersistentRef as String,
    kSecReturnRef as String,
    kSecUseDataProtectionKeychain as String,
    kSecUseItemList as String,
    kSecUseAuthenticationUI as String,
    kSecUseAuthenticationContext as String,
    kSecUseNoAuthenticationUI as String,
    kSecUseOperationPrompt as String,
    kSecValuePersistentRef as String,
]

private final class _PortableKeychain: @unchecked Sendable {
    static let shared = _PortableKeychain()
    let lock = NSLock()
    var items: [[String: Any]] = []
    var loaded = false
    var loadedPath: String?

    var directory: URL {
        var override: String?
        "OPENUIKIT_KEYCHAIN_PATH".withCString { name in
            if let raw = getenv(name) {
                override = String(cString: raw)
            }
        }
        if let override, !override.isEmpty {
            return URL(fileURLWithPath: override, isDirectory: true)
        }
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return base.appendingPathComponent("OpenUIKit", isDirectory: true)
            .appendingPathComponent("keychain", isDirectory: true)
    }

    var storeURL: URL { directory.appendingPathComponent("store.bin") }
    var keyURL: URL { directory.appendingPathComponent("store.key") }

    func loadIfNeeded() {
        let path = directory.path
        if loaded, loadedPath == path { return }
        loaded = true
        loadedPath = path
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        guard let blob = try? Data(contentsOf: storeURL), blob.count > 32,
              let key = try? Data(contentsOf: keyURL), key.count == 32 else {
            items = []
            return
        }
        let nonce = Array(blob.prefix(12))
        let tag = Array(blob.suffix(16))
        let cipher = Array(blob.dropFirst(12).dropLast(16))
        guard let plain = _secAESGCMOpen(key: Array(key), nonce: nonce, ciphertext: cipher, tag: tag),
              let json = try? JSONSerialization.jsonObject(with: Data(plain)) as? [[String: Any]] else {
            items = []
            return
        }
        items = json.map(_securityDecodeItem)
    }

    func persist() {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var key = (try? Data(contentsOf: keyURL)) ?? Data()
        if key.count != 32 {
            key = Data(_secRandomBytes(32))
            try? key.write(to: keyURL, options: .atomic)
        }
        let encoded = items.map(_securityEncodeItem)
        guard JSONSerialization.isValidJSONObject(encoded),
              let json = try? JSONSerialization.data(withJSONObject: encoded, options: []) else { return }
        let nonce = _secRandomBytes(12)
        let (cipher, tag) = _secAESGCMSeal(key: Array(key), nonce: nonce, plaintext: Array(json))
        var blob = Data(nonce)
        blob.append(contentsOf: cipher)
        blob.append(contentsOf: tag)
        try? blob.write(to: storeURL, options: .atomic)
    }
}

private func _securityEncodeItem(_ item: [String: Any]) -> [String: Any] {
    var out: [String: Any] = [:]
    for (key, value) in item {
        if let data = value as? Data {
            out[key] = ["$data": data.base64EncodedString()]
        } else if let date = value as? Date {
            out[key] = ["$date": date.timeIntervalSince1970]
        } else if let control = value as? SecAccessControl {
            out[key] = [
                "$acl": [
                    "protection": control.protection,
                    "flags": Int(control.flags.rawValue),
                ]
            ]
        } else if value is SecKey || value is SecCertificate || value is SecIdentity {
            continue
        } else if value is Bool || value is Int || value is String {
            out[key] = value
        } else if let number = value as? NSNumber {
            out[key] = number
        }
    }
    return out
}

private func _securityDecodeItem(_ item: [String: Any]) -> [String: Any] {
    var out: [String: Any] = [:]
    for (key, value) in item {
        if let box = value as? [String: Any], let b64 = box["$data"] as? String, let data = Data(base64Encoded: b64) {
            out[key] = data
        } else if let box = value as? [String: Any], let interval = box["$date"] as? Double {
            out[key] = Date(timeIntervalSince1970: interval)
        } else if let box = value as? [String: Any], let acl = box["$acl"] as? [String: Any],
                  let protection = acl["protection"] as? String {
            let flags = _secInt(acl["flags"]) ?? 0
            out[key] = SecAccessControl(
                protection: protection,
                flags: SecAccessControlCreateFlags(rawValue: CFOptionFlags(flags))
            )
        } else {
            out[key] = value
        }
    }
    return out
}

private func _securityDictionary(_ value: CFDictionary) -> [String: Any] {
    value
}

private func _securityCFDictionary(_ value: [String: Any]) -> [CFString: Any] {
    var result: [CFString: Any] = [:]
    for (key, item) in value {
        if key == (kSecValueData as String) { continue }
        result[key as CFString] = item
    }
    return result
}

private func _securityEqual(_ lhs: Any, _ rhs: Any) -> Bool {
    if let lhs = lhs as? String, let rhs = rhs as? String { return lhs == rhs }
    if let lhs = lhs as? Bool, let rhs = rhs as? Bool { return lhs == rhs }
    if let lhs = lhs as? Int, let rhs = rhs as? Int { return lhs == rhs }
    if let lhs = lhs as? Data, let rhs = rhs as? Data { return lhs == rhs }
    if let lhs = _secInt(lhs), let rhs = _secInt(rhs) { return lhs == rhs }
    return String(describing: lhs) == String(describing: rhs)
}

private func _securityMatches(_ item: [String: Any], query: [String: Any]) -> Bool {
    if let pref = query[kSecValuePersistentRef as String] as? Data,
       let itemPref = item["_pref"] as? Data, pref != itemPref {
        return false
    }
    for (key, expected) in query where !_securityQueryOnlyKeys.contains(key) {
        if key == (kSecAttrSynchronizable as String),
           let value = expected as? String,
           value == (kSecAttrSynchronizableAny as String) {
            continue
        }
        if key == (kSecValueData as String) { continue }
        if key == (kSecValueRef as String) { continue }
        guard let actual = item[key], _securityEqual(actual, expected) else {
            return false
        }
    }
    return true
}

private func _securityIdentityKeys(_ itemClass: String) -> [String] {
    switch itemClass {
    case kSecClassInternetPassword:
        return [
            kSecClass, kSecAttrAccount, kSecAttrServer,
            kSecAttrProtocol, kSecAttrPort, kSecAttrPath,
            kSecAttrAccessGroup, kSecAttrSynchronizable,
        ]
    case kSecClassKey:
        return [
            kSecClass, kSecAttrApplicationLabel, kSecAttrApplicationTag,
            kSecAttrKeyClass, kSecAttrKeyType, kSecAttrAccessGroup,
        ]
    case kSecClassCertificate:
        return [
            kSecClass, kSecAttrIssuer, kSecAttrSerialNumber,
            kSecAttrAccessGroup,
        ]
    case kSecClassIdentity:
        return [
            kSecClass, kSecAttrIssuer, kSecAttrSerialNumber,
            kSecAttrAccessGroup,
        ]
    default:
        return [
            kSecClass, kSecAttrAccount, kSecAttrService,
            kSecAttrAccessGroup, kSecAttrSynchronizable,
        ]
    }
}

private func _securityIdentityMatches(
    _ item: [String: Any], candidate: [String: Any]
) -> Bool {
    let itemClass = (candidate[kSecClass as String] as? String)
        ?? (item[kSecClass as String] as? String)
        ?? (kSecClassGenericPassword as String)
    for key in _securityIdentityKeys(itemClass) {
        switch (item[key], candidate[key]) {
        case (nil, nil): continue
        case let (lhs?, rhs?) where _securityEqual(lhs, rhs): continue
        default: return false
        }
    }
    return true
}

private func _securityAuthFailed(_ item: [String: Any]) -> Bool {
    if let control = item[kSecAttrAccessControl as String] as? SecAccessControl {
        return control.requiresBiometry
    }
    return false
}

@discardableResult
public func SecItemAdd(
    _ attributes: CFDictionary,
    _ result: UnsafeMutablePointer<CFTypeRef?>?
) -> OSStatus {
    var candidate = _securityDictionary(attributes)
    guard let itemClass = candidate[kSecClass as String] as? String else {
        return errSecParam
    }
    let allowed: Set<String> = [
        kSecClassGenericPassword as String,
        kSecClassInternetPassword as String,
        kSecClassKey as String,
        kSecClassCertificate as String,
        kSecClassIdentity as String,
    ]
    guard allowed.contains(itemClass) else { return errSecParam }
    if candidate[kSecValueData as String] == nil, candidate[kSecValueRef as String] == nil {
        return errSecParam
    }
    if candidate[kSecValueData as String] != nil, !(candidate[kSecValueData as String] is Data) {
        return errSecParam
    }
    let now = Date()
    if candidate[kSecAttrCreationDate as String] == nil { candidate[kSecAttrCreationDate as String] = now }
    candidate[kSecAttrModificationDate as String] = now
    let pref = Data(_secRandomBytes(16))
    candidate["_pref"] = pref
    let store = _PortableKeychain.shared
    store.lock.lock()
    defer { store.lock.unlock() }
    store.loadIfNeeded()
    if store.items.contains(where: { _securityIdentityMatches($0, candidate: candidate) }) {
        return errSecDuplicateItem
    }
    store.items.append(candidate)
    store.persist()
    if let result {
        if _secBool(candidate[kSecReturnPersistentRef as String]) {
            result.pointee = pref as CFTypeRef
        } else if _secBool(candidate[kSecReturnData as String]),
                  let data = candidate[kSecValueData as String] as? Data {
            result.pointee = data as CFTypeRef
        } else {
            result.pointee = nil
        }
    }
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
    store.loadIfNeeded()
    var matched = false
    var authFailed = false
    for index in store.items.indices where _securityMatches(store.items[index], query: query) {
        if _securityAuthFailed(store.items[index]) { authFailed = true; continue }
        matched = true
        for (key, value) in updates { store.items[index][key] = value }
        store.items[index][kSecAttrModificationDate as String] = Date()
    }
    if authFailed && !matched { return errSecAuthFailed }
    guard matched else { return errSecItemNotFound }
    store.persist()
    return errSecSuccess
}

@discardableResult
public func SecItemDelete(_ query: CFDictionary) -> OSStatus {
    let query = _securityDictionary(query)
    let store = _PortableKeychain.shared
    store.lock.lock()
    defer { store.lock.unlock() }
    store.loadIfNeeded()
    let originalCount = store.items.count
    var authFailed = false
    store.items.removeAll { item in
        guard _securityMatches(item, query: query) else { return false }
        if _securityAuthFailed(item) { authFailed = true; return false }
        return true
    }
    if store.items.count == originalCount {
        return authFailed ? errSecAuthFailed : errSecItemNotFound
    }
    store.persist()
    return errSecSuccess
}

private func _securityShape(_ item: [String: Any], query: [String: Any]) -> CFTypeRef {
    let wantsAttributes = _secBool(query[kSecReturnAttributes as String])
    let wantsReference = _secBool(query[kSecReturnRef as String])
    let wantsPersistent = _secBool(query[kSecReturnPersistentRef as String])
    let wantsData = _secBool(query[kSecReturnData as String])
    var bag: [String: Any] = [:]
    if wantsData, let data = item[kSecValueData as String] as? Data {
        bag[kSecValueData as String] = data
    }
    if wantsAttributes {
        for (key, value) in _securityCFDictionary(item) {
            bag[key as String] = value
        }
    }
    if wantsPersistent, let pref = item["_pref"] as? Data {
        bag[kSecValuePersistentRef as String] = pref
    }
    if wantsReference, let ref = _securityMakeRef(item) {
        bag[kSecValueRef as String] = ref
    }
    let flags = [wantsData, wantsAttributes, wantsReference, wantsPersistent].filter { $0 }.count
    if flags == 0 {
        if let data = item[kSecValueData as String] as? Data { return data as CFTypeRef }
        return _securityCFDictionary(item) as CFTypeRef
    }
    if flags == 1 {
        if wantsData, let data = item[kSecValueData as String] as? Data { return data as CFTypeRef }
        if wantsPersistent, let pref = item["_pref"] as? Data { return pref as CFTypeRef }
        if wantsReference, let ref = _securityMakeRef(item) { return ref }
        return _securityCFDictionary(item) as CFTypeRef
    }
    return bag as CFTypeRef
}

private func _securityMakeRef(_ item: [String: Any]) -> CFTypeRef? {
    let itemClass = item[kSecClass as String] as? String
    if itemClass == (kSecClassCertificate as String), let data = item[kSecValueData as String] as? Data {
        return SecCertificateCreateWithData(nil, data)
    }
    if itemClass == (kSecClassKey as String), let data = item[kSecValueData as String] as? Data {
        var attrs: [String: Any] = item
        attrs[kSecAttrKeyClass as String] = item[kSecAttrKeyClass as String] ?? kSecAttrKeyClassPrivate
        attrs[kSecAttrKeyType as String] = item[kSecAttrKeyType as String] ?? kSecAttrKeyTypeRSA
        return SecKeyCreateWithData(data, attrs as CFDictionary, nil)
    }
    return _securityCFDictionary(item) as CFTypeRef
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
    store.loadIfNeeded()
    var matches = store.items.filter { _securityMatches($0, query: query) }
    if matches.contains(where: { _securityAuthFailed($0) }) {
        result?.pointee = nil
        return errSecAuthFailed
    }
    guard !matches.isEmpty else {
        result?.pointee = nil
        return errSecItemNotFound
    }
    guard let result else { return errSecSuccess }
    let wantsAll = (query[kSecMatchLimit as String] as? String) == (kSecMatchLimitAll as String)
        || _securityEqual(query[kSecMatchLimit as String] as Any? ?? "", kSecMatchLimitAll)
    if !wantsAll { matches = Array(matches.prefix(1)) }
    if wantsAll {
        result.pointee = matches.map { _securityShape($0, query: query) } as CFTypeRef
    } else {
        result.pointee = _securityShape(matches[0], query: query)
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
    let filled = _secRandomBytes(count)
    let buffer = bytes.bindMemory(to: UInt8.self, capacity: count)
    for index in 0..<count { buffer[index] = filled[index] }
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
