import Foundation
import CoreSpotlight

#if false
import Foundation
#endif

/// Identity probe for the later clean EC2 integration build. Isolated host
/// compilation does not execute this file.
func coreSpotlightDependencyIdentityProbe() {
  let attributes = CSSearchableItemAttributeSet(itemContentType: "public.text")
  attributes.title = "Foundation identity"
  attributes.lastUsedDate = Date(timeIntervalSince1970: 1)
  attributes.thumbnailData = Data([0x0, 0x1])
  attributes.contentURL = URL(fileURLWithPath: "/tmp/corespotlight-identity")
  let item = CSSearchableItem(
    uniqueIdentifier: "foundation-identity",
    domainIdentifier: "identity",
    attributeSet: attributes
  )
  item.expirationDate = Date(timeIntervalSinceNow: 60)
  let index = CSSearchableIndex(name: "identity-probe")
  index.indexSearchableItems([item]) { error in
    _ = error
  }
  index.beginBatch()
  let state = Data("identity-state".utf8)
  index.endIndexBatch(expectedClientState: nil, newClientState: state) { _ in }
  index.fetchLastClientState { data, error in
    _ = (data, error)
  }
  let person = CSPerson(
    displayName: "Identity",
    handles: ["identity@example.com"],
    handleIdentifier: "email"
  )
  attributes.authors = [person]
  _ = CSIndexErrorDomain
  _ = FileProtectionType.complete
  _ = CSSearchableIndex(name: "protected", protectionClass: .complete)
}

#if CORESPOTLIGHT_IDENTITY_MAIN
coreSpotlightDependencyIdentityProbe()
print("CORESPOTLIGHT_DEPENDENCY_IDENTITY_OK")
#endif
