import BackgroundTasks
import CoreSpotlight
import Foundation
import UniformTypeIdentifiers

func configureBackgroundWork() async throws {
  _ = BGTaskScheduler.shared.register(
    forTaskWithIdentifier: "org.example.refresh",
    using: nil
  ) { task in
    task.expirationHandler = {}
    task.setTaskCompleted(success: true)
  }

  let refresh = BGAppRefreshTaskRequest(identifier: "org.example.refresh")
  refresh.earliestBeginDate = Date(timeIntervalSinceNow: 30)
  try BGTaskScheduler.shared.submit(refresh)

  let processing = BGProcessingTaskRequest(identifier: "org.example.process")
  processing.requiresNetworkConnectivity = true
  processing.requiresExternalPower = false
  try BGTaskScheduler.shared.submit(processing)

  _ = await BGTaskScheduler.shared.pendingTaskRequests()
  BGTaskScheduler.shared.getPendingTaskRequests { requests in
    _ = requests.map(\.identifier)
  }
  BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: refresh.identifier)
  _ = BGTaskScheduler.Error.Code.notPermitted.rawValue
}

func indexCorpusShapedItems() async throws {
  let attributes = CSSearchableItemAttributeSet(contentType: UTType.text)
  attributes.title = "Title"
  attributes.contentDescription = "Body"
  attributes.keywords = ["one", "two"]
  attributes.alternateNames = ["alternate"]
  attributes.thumbnailData = Data([1, 2, 3])
  attributes.thumbnailURL = URL(fileURLWithPath: "/tmp/thumbnail")
  attributes.lastUsedDate = Date()
  attributes.metadataModificationDate = Date()
  attributes.duration = 42
  attributes.streamable = 0
  attributes.deliveryType = 0
  attributes.local = 1
  attributes.codecs = ["h264"]
  attributes.languages = ["en"]
  attributes.pixelWidth = 1920
  attributes.pixelHeight = 1080
  attributes.authors = [
    CSPerson(displayName: "Author", handles: [], handleIdentifier: "author")
  ]

  let item = CSSearchableItem(
    uniqueIdentifier: "item",
    domainIdentifier: "domain",
    attributeSet: attributes
  )
  item.expirationDate = Date(timeIntervalSinceNow: 60)
  let named = CSSearchableIndex(name: "Corpus")
  try await named.indexSearchableItems([item])
  try await named.deleteSearchableItems(withIdentifiers: ["item"])
  named.deleteSearchableItems(withDomainIdentifiers: ["domain"]) { _ in }
  named.deleteAllSearchableItems(completionHandler: nil)
  _ = CSSearchableItemActionType
  _ = CSSearchableItemActivityIdentifier
  _ = CSSearchQueryString
}
