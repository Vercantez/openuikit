import Foundation
import Security

/// Schema-v2 agent runtime probe. The sealed host gate compiles `*Tests.swift`
/// only; this file is for a later integration or a human runner.
public enum SecurityRuntime {
    public static func exercisePortableKeychain() {
        let itemClass = kSecClassGenericPassword
        let account = "runtime-account"
        let service = "runtime-service"
        _ = SecItemDelete([
            kSecClass: itemClass,
            kSecAttrAccount: account,
            kSecAttrService: service,
        ] as CFDictionary)
        let status = SecItemAdd(
            [
                kSecClass: itemClass,
                kSecAttrAccount: account,
                kSecAttrService: service,
                kSecValueData: Data("runtime".utf8),
            ] as CFDictionary,
            nil
        )
        precondition(status == errSecSuccess)
    }
}
