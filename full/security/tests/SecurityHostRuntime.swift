import Security

private func require(
    _ condition: @autoclosure () -> Bool,
    _ message: String
) {
    guard condition() else {
        FileHandle.standardError.write(Data("SECURITY_HOST_FAIL \(message)\n".utf8))
        exit(1)
    }
}

private let itemClass = kSecClassGenericPassword
private let account = "portable-account"
private let service = "portable-service"
private let initial = Data("first".utf8)
private let changed = Data("second".utf8)

_ = SecItemDelete([
    kSecClass: itemClass,
    kSecAttrAccount: account,
    kSecAttrService: service,
] as CFDictionary)

let add: [CFString: Any] = [
    kSecClass: itemClass,
    kSecAttrAccount: account,
    kSecAttrService: service,
    kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock,
    kSecValueData: initial,
]
require(SecItemAdd(add as CFDictionary, nil) == errSecSuccess, "add")
require(SecItemAdd(add as CFDictionary, nil) == errSecDuplicateItem, "duplicate")

var copied: CFTypeRef?
let one: [CFString: Any] = [
    kSecClass: itemClass,
    kSecAttrAccount: account,
    kSecAttrService: service,
    kSecReturnData: true,
    kSecMatchLimit: kSecMatchLimitOne,
]
require(SecItemCopyMatching(one as CFDictionary, &copied) == errSecSuccess, "copy")
require(copied as? Data == initial, "copy bytes")

require(
    SecItemUpdate(
        one as CFDictionary,
        [kSecValueData: changed] as CFDictionary
    ) == errSecSuccess,
    "update"
)
copied = nil
require(SecItemCopyMatching(one as CFDictionary, &copied) == errSecSuccess, "recopy")
require(copied as? Data == changed, "updated bytes")

var all: CFTypeRef?
let list: [CFString: Any] = [
    kSecClass: itemClass,
    kSecAttrService: service,
    kSecReturnAttributes: true,
    kSecMatchLimit: kSecMatchLimitAll,
]
require(SecItemCopyMatching(list as CFDictionary, &all) == errSecSuccess, "list")
let attributes = all as? [[CFString: Any]]
require(attributes?.count == 1, "list count")
require(attributes?[0][kSecAttrAccount] as? String == account, "list account")

var random = [UInt8](repeating: 0, count: 32)
let randomStatus = random.withUnsafeMutableBytes {
    SecRandomCopyBytes(kSecRandomDefault, $0.count, $0.baseAddress!)
}
require(randomStatus == errSecSuccess, "random status")
require(random.contains(where: { $0 != 0 }), "random bytes")

var staticCode: SecStaticCode?
require(
    SecStaticCodeCreateWithPath(Bundle.main.bundleURL as CFURL, [], &staticCode)
        == errSecNotAvailable,
    "unsigned code boundary"
)
require(staticCode == nil, "unsigned code value")
require(
    (SecCopyErrorMessageString(errSecItemNotFound, nil) as String?)
        == "The item cannot be found.",
    "error message"
)
require(SecItemDelete(one as CFDictionary) == errSecSuccess, "delete")
copied = nil
require(
    SecItemCopyMatching(one as CFDictionary, &copied) == errSecItemNotFound,
    "deleted lookup"
)

print("SECURITY_HOST_OK keychain=crud random=system code-signing=unavailable")
