import Foundation
import Security

func securityDependencyIdentityProbe() {
    let data = Data("identity".utf8)
    let attributes: [String: Any] = [
        kSecClass: kSecClassGenericPassword,
        kSecAttrAccount: "dependency-account",
        kSecAttrService: "dependency-service",
        kSecValueData: data,
    ]
    _ = SecItemDelete(attributes as CFDictionary)
    let status = SecItemAdd(attributes as CFDictionary, nil)
    precondition(status == errSecSuccess || status == errSecDuplicateItem)
    let message = SecCopyErrorMessageString(errSecSuccess, nil)
    precondition((message as String?) == "No error.")
}

#if SECURITY_IDENTITY_MAIN
securityDependencyIdentityProbe()
print("SECURITY_DEPENDENCY_IDENTITY_OK")
#endif
