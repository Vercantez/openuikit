import Foundation
import CryptoTokenKit

/// Isolated-host identity probe. Real Foundation values pass through
/// CryptoTokenKit APIs. The sealed host gate does not compile this file.
func cryptoTokenKitDependencyIdentityProbe() {
    let payload = Data([0xAA, 0xBB])
    let record = TKBERTLVRecord(tag: 0x5A, value: payload)
    precondition(record.value == payload)
    precondition(record.data == Data([0x5A, 0x02, 0xAA, 0xBB]))

    let format = TKSmartCardPINFormat()
    format.maxPINLength = 8
    precondition(format.maxPINLength == 8)

    let domain: String = TKErrorDomain
    let bridged = TKError(.objectNotFound, userInfo: ["foundation": domain])
    precondition(bridged.userInfo["foundation"] as? String == domain)
    let ns = bridged as NSError
    precondition(ns.domain == TKErrorDomain)

    let objectID: NSNumber = NSNumber(value: 9)
    let item = TKTokenKeychainItem(objectID: objectID)
    item.label = "identity"
    precondition((item.objectID as? NSNumber) == objectID)
    precondition(item.label == "identity")
}

#if CRYPTOTOKENKIT_IDENTITY_MAIN
cryptoTokenKitDependencyIdentityProbe()
print("CRYPTOTOKENKIT_DEPENDENCY_IDENTITY_OK")
#endif
