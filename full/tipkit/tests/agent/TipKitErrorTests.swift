@_spi(OpenUIKitHost) import TipKit
import Foundation

func testTipKitErrorIdentities() {
    let configured = TipKitError.tipsDatastoreAlreadyConfigured
    let entitlements = TipKitError.missingGroupContainerEntitlements
    let predicate = TipKitError.invalidPredicateValueType
    precondition(configured == TipKitError.tipsDatastoreAlreadyConfigured)
    precondition(configured != entitlements)
    precondition(entitlements != predicate)
    precondition(configured.description == "tipsDatastoreAlreadyConfigured")
    precondition(configured.errorDescription == "tipsDatastoreAlreadyConfigured")
    precondition(configured.failureReason == nil)
    precondition(configured.helpAnchor == nil)
    precondition(configured.recoverySuggestion == nil)
    precondition(!configured.localizedDescription.isEmpty)
    var hasher = Hasher()
    configured.hash(into: &hasher)
    _ = configured.hashValue
    _ = entitlements.hashValue
    _ = predicate.hashValue
}
