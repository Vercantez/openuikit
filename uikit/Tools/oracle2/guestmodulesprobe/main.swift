// guestmodulesprobe -- modules apps import by Apple's names (CoreGraphics,
// Security) next to UIKit, the Apple side (run.sh, iOS 26.1 simulator, a
// process without keychain entitlements) and the guest side
// (Tools/guestprobes/GuestModulesProbe.probe.sh) of the same program.
import CoreGraphics
import Foundation
import Security
import UIKit

func say(_ items: Any...) { print(items.map { "\($0)" }.joined(separator: " ")) }

func coreGraphics() {
    // One declaration per name with UIKit and CoreGraphics both imported:
    // collection sugar parses as a type (cg-unify phase 4), CGContext is one type.
    var sizes = [CGSize]()
    sizes.append(CGSize(width: 20, height: 20))
    let points: [CGPoint] = [CGPoint(x: 1, y: 1)]
    let rect = CGRect(origin: .zero, size: sizes[0]).insetBy(dx: 2, dy: 3)
    say("cg.rect", Double(rect.minX), Double(rect.minY), Double(rect.width), Double(rect.height))
    let transform = CGAffineTransform(translationX: 5, y: 7).scaledBy(x: 2, y: 3)
    let moved = points[0].applying(transform)
    say("cg.transform", Double(moved.x), Double(moved.y))
    let contexts: [CGContext] = []
    say("cg.context.collection", contexts.count)
    let union = CGRect(x: 0, y: 0, width: 10, height: 10).union(CGRect(x: 5, y: -5, width: 10, height: 10))
    say("cg.union", Double(union.minX), Double(union.minY), Double(union.width), Double(union.height))
}

func keychain() {
    let base: [String: Any] = [
        kSecClass as String: kSecClassInternetPassword,
        kSecAttrServer as String: "guest-probe.invalid",
        kSecAttrAccount as String: "probe",
        kSecAttrSecurityDomain as String: "guest",
    ]
    var add = base
    add[kSecValueData as String] = Data("secret".utf8)
    add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
    say("security.add", SecItemAdd(add as CFDictionary, nil))
    var query = base
    query[kSecReturnData as String] = true
    query[kSecReturnAttributes as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    var result: AnyObject?
    let copyStatus = SecItemCopyMatching(query as CFDictionary, &result)
    say("security.copy", copyStatus, "result=\(result == nil ? "nil" : "value")")
    say("security.update", SecItemUpdate(base as CFDictionary,
                                         [kSecValueData as String: Data("x".utf8)] as CFDictionary))
    say("security.delete", SecItemDelete(base as CFDictionary))
    for status in [errSecSuccess, errSecMissingEntitlement, errSecItemNotFound, errSecDuplicateItem,
                   errSecNotAvailable, errSecAuthFailed, errSecParam, errSecIO, errSecUnimplemented,
                   errSecAllocate, errSecUserCanceled, errSecInteractionNotAllowed, errSecDecode,
                   errSecInvalidEncoding, OSStatus(12345)] {
        say("security.message", status, SecCopyErrorMessageString(status, nil) as String? ?? "nil")
    }
    var bytes = [UInt8](repeating: 0, count: 32)
    let randomStatus = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
    say("security.random", randomStatus, "nonzero=\(bytes.contains { $0 != 0 })")
}

@main
struct GuestModulesProbe {
    static func main() {
        print("guestmodulesprobe v1")
        coreGraphics()
        keychain()
        print("guestmodulesprobe done")
    }
}
