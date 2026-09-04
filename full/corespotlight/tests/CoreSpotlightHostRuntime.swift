import Foundation
import UniformTypeIdentifiers
@_spi(OpenUIKitHost) import CoreSpotlight

@main
private struct CoreSpotlightHostRuntime {
  static func main() async {
    let index = CSSearchableIndex.default()
    index._resetPortableState()
    precondition(CSSearchableIndex.isIndexingAvailable())

    let article = CSSearchableItemAttributeSet(contentType: .text)
    article.title = "Portable Swift runtime"
    article.contentDescription = "Run unchanged iOS applications on Linux"
    article.keywords = ["Swift", "Linux", "UIKit"]
    article.alternateNames = ["Open UIKit platform"]
    article.lastUsedDate = Date(timeIntervalSince1970: 42)
    article.authors = [
      CSPerson(displayName: "Open Source", handles: [], handleIdentifier: "oss")
    ]
    let first = CSSearchableItem(
      uniqueIdentifier: "article-1",
      domainIdentifier: "articles",
      attributeSet: article
    )

    var callbackCount = 0
    index.indexSearchableItems([first]) { error in
      precondition(error == nil)
      callbackCount += 1
    }
    precondition(callbackCount == 1)
    article.title = "mutated after indexing"
    precondition(index._allPortableItems()[0].attributeSet.title == "Portable Swift runtime")
    precondition(index._searchPortable("swift linux").map(\.uniqueIdentifier) == ["article-1"])

    let noteAttributes = CSSearchableItemAttributeSet(
      itemContentType: UTType.plainText.identifier
    )
    noteAttributes.title = "Background scheduler notes"
    noteAttributes.contentDescription = "Durable framework state"
    let note = CSSearchableItem(
      uniqueIdentifier: "note-1",
      domainIdentifier: "notes",
      attributeSet: noteAttributes
    )
    try! await index.indexSearchableItems([note])
    precondition(index._allPortableItems().count == 2)
    try! await index.deleteSearchableItems(withDomainIdentifiers: ["articles"])
    precondition(index._allPortableItems().map(\.uniqueIdentifier) == ["note-1"])

    let expiredAttributes = CSSearchableItemAttributeSet(contentType: .data)
    expiredAttributes.title = "Expired"
    let expired = CSSearchableItem(
      uniqueIdentifier: "expired",
      domainIdentifier: "notes",
      attributeSet: expiredAttributes
    )
    expired.expirationDate = .distantPast
    try! await index.indexSearchableItems([expired])
    precondition(index._allPortableItems().map(\.uniqueIdentifier) == ["note-1"])

    index.beginIndexBatch()
    let state = Data([1, 2, 3])
    index.endIndexBatch(expectedClientState: nil, newClientState: state) {
      precondition($0 == nil)
    }
    var fetchedState: Data?
    index.fetchLastClientState { data, error in
      precondition(error == nil)
      fetchedState = data
    }
    precondition(fetchedState == state)

    let named = CSSearchableIndex(name: "entities")
    named._resetPortableState()
    try! await named.indexAppEntities(["light.kitchen", "cover.office"])
    try! await named.deleteAppEntities(
      identifiedBy: ["cover.office"],
      ofType: String.self
    )
    let entityCounts = named._portableAppEntityMutationCounts
    precondition(entityCounts.writes == 2)
    precondition(entityCounts.deletes == 1)
    precondition(index._allPortableItems().count == 1)

    do {
      let invalid = CSSearchableItem(
        uniqueIdentifier: nil,
        domainIdentifier: nil,
        attributeSet: CSSearchableItemAttributeSet(contentType: .item)
      )
      try await index.indexSearchableItems([invalid])
      preconditionFailure("missing identifier was accepted")
    } catch let error as CSIndexError {
      precondition(error.code == .invalidItemError)
    } catch {
      preconditionFailure("unexpected CoreSpotlight error")
    }

    try! await index.deleteAllSearchableItems()
    precondition(index._allPortableItems().isEmpty)
    print(
      "CORESPOTLIGHT_HOST_OK index=named,isolated crud=sync,async,domain,all "
        + "snapshots=owned query=terms expiry=filtered batch=client-state "
        + "app-entities=index,delete"
    )
  }
}
