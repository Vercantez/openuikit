import Foundation
import IdentityLookup

func testLiveCallerIDLookupExtensionContextStoresFields() {
    let service = URL(string: "https://pir.example.invalid/service")!
    let issuer = URL(string: "https://pir.example.invalid/token")!
    let token = Data("tier-token".utf8)
    let context = LiveCallerIDLookupExtensionContext(
        serviceURL: service,
        tokenIssuerURL: issuer,
        userTierToken: token
    )
    precondition(context.serviceURL == service)
    precondition(context.tokenIssuerURL == issuer)
    precondition(context.userTierToken == token)
}

func testLiveCallerIDLookupExtensionContextEqualityAndHash() {
    let service = URL(string: "https://pir.example.invalid/a")!
    let issuer = URL(string: "https://pir.example.invalid/b")!
    let token = Data([0xAA, 0xBB])
    let left = LiveCallerIDLookupExtensionContext(
        serviceURL: service,
        tokenIssuerURL: issuer,
        userTierToken: token
    )
    let right = LiveCallerIDLookupExtensionContext(
        serviceURL: service,
        tokenIssuerURL: issuer,
        userTierToken: token
    )
    let other = LiveCallerIDLookupExtensionContext(
        serviceURL: service,
        tokenIssuerURL: issuer,
        userTierToken: Data("other".utf8)
    )
    precondition(left == right)
    precondition(left != other)
    precondition(left.hashValue == right.hashValue)
    var hasher = Hasher()
    left.hash(into: &hasher)
    _ = hasher.finalize()
}

func testLiveCallerIDLookupExtensionContextCodableRoundTrip() {
    let original = LiveCallerIDLookupExtensionContext(
        serviceURL: URL(string: "https://pir.example.invalid/svc")!,
        tokenIssuerURL: URL(string: "https://pir.example.invalid/iss")!,
        userTierToken: Data("abc".utf8)
    )
    let encoded = try! JSONEncoder().encode(original)
    let decoded = try! JSONDecoder().decode(
        LiveCallerIDLookupExtensionContext.self,
        from: encoded
    )
    precondition(decoded == original)
}

func testLiveCallerIDLookupManagerSharedAndStatus() {
    let manager = LiveCallerIDLookupManager.shared
    precondition(manager === LiveCallerIDLookupManager.shared)
    precondition(manager.status(forExtensionWithIdentifier: "com.example.lookup") == .disabled)
    precondition(manager.status(forExtensionWithIdentifier: "") == .disabled)
}

func testLiveCallerIDLookupProtocolContext() {
    struct Probe: LiveCallerIDLookupProtocol {
        var context: LiveCallerIDLookupExtensionContext
    }
    let context = LiveCallerIDLookupExtensionContext(
        serviceURL: URL(string: "https://pir.example.invalid/svc")!,
        tokenIssuerURL: URL(string: "https://pir.example.invalid/iss")!,
        userTierToken: Data()
    )
    let probe = Probe(context: context)
    precondition(probe.context == context)
    let _: any LiveCallerIDLookupExtensionConfiguration = probe.configuration
}

func testLiveLookupNSSetTypealiases() {
    let empty = NSSet()
    let storeSet: LiveLookupStoreFoundationFrameworkSet = empty
    let dbSet: LiveLookupDBExtensionCoreDataPropertiesSet = empty
    let identitySet: IdentityInfoCoreDataPropertiesSet = empty
    let blockingSet: BlockingInfoCoreDataPropertiesSet = empty
    precondition(storeSet.count == 0)
    precondition(dbSet.count == 0)
    precondition(identitySet.count == 0)
    precondition(blockingSet.count == 0)
}

func testExtensionPointNameIsEmptyUntilOracle() {
    precondition(extensionPointName == "")
}
