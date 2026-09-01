import Foundation
import UniformTypeIdentifiers

public let CSSearchableItemActionType =
  "com.apple.corespotlightitem"
public let CSSearchableItemActivityIdentifier =
  "kCSSearchableItemActivityIdentifier"
public let CSSearchQueryString = "kCSSearchQueryString"

public final class CSPerson: NSObject, @unchecked Sendable {
  public let displayName: String
  public let handles: [String]
  public let handleIdentifier: String

  public init(
    displayName: String,
    handles: [String],
    handleIdentifier: String
  ) {
    self.displayName = displayName
    self.handles = handles
    self.handleIdentifier = handleIdentifier
    super.init()
  }
}

open class CSSearchableItemAttributeSet: NSObject, @unchecked Sendable {
  public let itemContentType: String

  public var title: String?
  public var displayName: String?
  public var alternateNames: [String]?
  public var contentDescription: String?
  public var keywords: [String]?
  public var relatedUniqueIdentifier: String?
  public var thumbnailData: Data?
  public var thumbnailURL: URL?
  public var contentURL: URL?
  public var contentType: String?
  public var htmlContentData: Data?
  public var textContent: String?
  public var authors: [CSPerson]?
  public var creator: String?
  public var organizations: [String]?
  public var recipients: [CSPerson]?
  public var recipientEmailAddresses: [String]?
  public var emailAddresses: [String]?
  public var phoneNumbers: [String]?
  public var namedLocation: String?
  public var latitude: NSNumber?
  public var longitude: NSNumber?

  public var path: String?
  public var fileSize: NSNumber?
  public var fileExtension: String?
  public var addedDate: Date?
  public var contentCreationDate: Date?
  public var contentModificationDate: Date?
  public var metadataModificationDate: Date?
  public var lastUsedDate: Date?

  public var duration: NSNumber?
  public var streamable: NSNumber?
  public var deliveryType: NSNumber?
  public var local: NSNumber?
  public var playCount: NSNumber?
  public var codecs: [String]?
  public var languages: [String]?
  public var pixelWidth: NSNumber?
  public var pixelHeight: NSNumber?
  public var videoBitRate: NSNumber?
  public var audioBitRate: NSNumber?
  public var audioChannelCount: NSNumber?
  public var audioSampleRate: NSNumber?
  public var genre: String?
  public var musicalGenre: String?
  public var artist: String?
  public var performers: [String]?
  public var audioTrackNumber: NSNumber?
  public var album: String?

  public init(itemContentType: String) {
    self.itemContentType = itemContentType
    contentType = itemContentType
    super.init()
  }

  public convenience init(contentType: UTType) {
    self.init(itemContentType: contentType.identifier)
  }

  /// AppIntents uses this hook for IndexedEntity association. The portable
  /// index retains the priority as metadata without requiring a circular
  /// CoreSpotlight -> AppIntents module dependency.
  public func associateAppEntity<Entity>(
    _ entity: Entity,
    priority: Int = 0
  ) {
    _ = entity
    _portableEntityPriority = priority
  }

  @_spi(OpenUIKitHost)
  public private(set) var _portableEntityPriority: Int?

  fileprivate func portableCopy() -> CSSearchableItemAttributeSet {
    let copy = CSSearchableItemAttributeSet(itemContentType: itemContentType)
    copy.title = title
    copy.displayName = displayName
    copy.alternateNames = alternateNames
    copy.contentDescription = contentDescription
    copy.keywords = keywords
    copy.relatedUniqueIdentifier = relatedUniqueIdentifier
    copy.thumbnailData = thumbnailData
    copy.thumbnailURL = thumbnailURL
    copy.contentURL = contentURL
    copy.contentType = contentType
    copy.htmlContentData = htmlContentData
    copy.textContent = textContent
    copy.authors = authors
    copy.creator = creator
    copy.organizations = organizations
    copy.recipients = recipients
    copy.recipientEmailAddresses = recipientEmailAddresses
    copy.emailAddresses = emailAddresses
    copy.phoneNumbers = phoneNumbers
    copy.namedLocation = namedLocation
    copy.latitude = latitude
    copy.longitude = longitude
    copy.path = path
    copy.fileSize = fileSize
    copy.fileExtension = fileExtension
    copy.addedDate = addedDate
    copy.contentCreationDate = contentCreationDate
    copy.contentModificationDate = contentModificationDate
    copy.metadataModificationDate = metadataModificationDate
    copy.lastUsedDate = lastUsedDate
    copy.duration = duration
    copy.streamable = streamable
    copy.deliveryType = deliveryType
    copy.local = local
    copy.playCount = playCount
    copy.codecs = codecs
    copy.languages = languages
    copy.pixelWidth = pixelWidth
    copy.pixelHeight = pixelHeight
    copy.videoBitRate = videoBitRate
    copy.audioBitRate = audioBitRate
    copy.audioChannelCount = audioChannelCount
    copy.audioSampleRate = audioSampleRate
    copy.genre = genre
    copy.musicalGenre = musicalGenre
    copy.artist = artist
    copy.performers = performers
    copy.audioTrackNumber = audioTrackNumber
    copy.album = album
    copy._portableEntityPriority = _portableEntityPriority
    return copy
  }
}

public final class CSSearchableItem: NSObject, @unchecked Sendable {
  public let uniqueIdentifier: String?
  public let domainIdentifier: String?
  public let attributeSet: CSSearchableItemAttributeSet
  public var expirationDate: Date?

  public init(
    uniqueIdentifier: String?,
    domainIdentifier: String?,
    attributeSet: CSSearchableItemAttributeSet
  ) {
    self.uniqueIdentifier = uniqueIdentifier
    self.domainIdentifier = domainIdentifier
    self.attributeSet = attributeSet
    super.init()
  }

  fileprivate func portableCopy() -> CSSearchableItem {
    let copy = CSSearchableItem(
      uniqueIdentifier: uniqueIdentifier,
      domainIdentifier: domainIdentifier,
      attributeSet: attributeSet.portableCopy()
    )
    copy.expirationDate = expirationDate
    return copy
  }
}

public enum CSIndexError: Swift.Error, Equatable, Sendable {
  case missingUniqueIdentifier
}

private final class _CSIndexStorage: @unchecked Sendable {
  let lock = NSLock()
  var items: [String: CSSearchableItem] = [:]
  var clientState: Data?
  var appEntityWrites = 0
  var appEntityDeletes = 0

  func recordAppEntityWrites(_ count: Int) {
    lock.lock()
    appEntityWrites += count
    lock.unlock()
  }

  func recordAppEntityDeletes(_ count: Int) {
    lock.lock()
    appEntityDeletes += count
    lock.unlock()
  }
}

public final class CSSearchableIndex: NSObject, @unchecked Sendable {
  private nonisolated(unsafe) static var registryLock = NSLock()
  private nonisolated(unsafe) static var registry: [String: _CSIndexStorage] = [:]
  private static let defaultIndex = CSSearchableIndex(name: "default")

  public let name: String
  private let storage: _CSIndexStorage

  public static func `default`() -> CSSearchableIndex { defaultIndex }
  public static func isIndexingAvailable() -> Bool { true }

  public init(name: String) {
    self.name = name
    Self.registryLock.lock()
    if let existing = Self.registry[name] {
      storage = existing
    } else {
      let created = _CSIndexStorage()
      Self.registry[name] = created
      storage = created
    }
    Self.registryLock.unlock()
    super.init()
  }

  public func indexSearchableItems(
    _ searchableItems: [CSSearchableItem],
    completionHandler: ((Swift.Error?) -> Void)? = nil
  ) {
    do {
      try index(searchableItems)
      completionHandler?(nil)
    } catch {
      completionHandler?(error)
    }
  }

  public func indexSearchableItems(
    _ searchableItems: [CSSearchableItem]
  ) async throws {
    try index(searchableItems)
  }

  private func index(_ searchableItems: [CSSearchableItem]) throws {
    let copies = try searchableItems.map { item -> (String, CSSearchableItem) in
      guard let identifier = item.uniqueIdentifier, !identifier.isEmpty else {
        throw CSIndexError.missingUniqueIdentifier
      }
      return (identifier, item.portableCopy())
    }
    storage.lock.lock()
    for (identifier, item) in copies {
      storage.items[identifier] = item
    }
    storage.lock.unlock()
  }

  public func deleteSearchableItems(
    withIdentifiers identifiers: [String],
    completionHandler: ((Swift.Error?) -> Void)? = nil
  ) {
    storage.lock.lock()
    identifiers.forEach { storage.items.removeValue(forKey: $0) }
    storage.lock.unlock()
    completionHandler?(nil)
  }

  public func deleteSearchableItems(
    withIdentifiers identifiers: [String]
  ) async throws {
    deleteSearchableItems(withIdentifiers: identifiers, completionHandler: nil)
  }

  public func deleteSearchableItems(
    withDomainIdentifiers domainIdentifiers: [String],
    completionHandler: ((Swift.Error?) -> Void)? = nil
  ) {
    let domains = Set(domainIdentifiers)
    storage.lock.lock()
    storage.items = storage.items.filter {
      guard let domain = $0.value.domainIdentifier else { return true }
      return !domains.contains(domain)
    }
    storage.lock.unlock()
    completionHandler?(nil)
  }

  public func deleteSearchableItems(
    withDomainIdentifiers domainIdentifiers: [String]
  ) async throws {
    deleteSearchableItems(
      withDomainIdentifiers: domainIdentifiers,
      completionHandler: nil
    )
  }

  public func deleteAllSearchableItems(
    completionHandler: ((Swift.Error?) -> Void)? = nil
  ) {
    storage.lock.lock()
    storage.items.removeAll()
    storage.lock.unlock()
    completionHandler?(nil)
  }

  public func deleteAllSearchableItems() async throws {
    deleteAllSearchableItems(completionHandler: nil)
  }

  public func beginIndexBatch() {}

  public func endIndexBatch(
    expectedClientState: Data?,
    newClientState: Data,
    completionHandler: ((Swift.Error?) -> Void)? = nil
  ) {
    storage.lock.lock()
    let matches = expectedClientState == nil
      || storage.clientState == expectedClientState
    if matches { storage.clientState = newClientState }
    storage.lock.unlock()
    completionHandler?(matches ? nil : CSIndexError.missingUniqueIdentifier)
  }

  public func fetchLastClientState(
    completionHandler: @escaping (Data?, Swift.Error?) -> Void
  ) {
    storage.lock.lock()
    let result = storage.clientState
    storage.lock.unlock()
    completionHandler(result, nil)
  }

  public func indexAppEntities<Entity>(_ entities: [Entity]) async throws {
    storage.recordAppEntityWrites(entities.count)
  }

  public func deleteAppEntities<Entity>(
    identifiedBy identifiers: [String],
    ofType entityType: Entity.Type
  ) async throws {
    _ = entityType
    storage.recordAppEntityDeletes(identifiers.count)
  }

  @_spi(OpenUIKitHost)
  public func _allPortableItems() -> [CSSearchableItem] {
    storage.lock.lock()
    let result = storage.items.values
      .filter { ($0.expirationDate ?? .distantFuture) > Date() }
      .map { $0.portableCopy() }
      .sorted { ($0.uniqueIdentifier ?? "") < ($1.uniqueIdentifier ?? "") }
    storage.lock.unlock()
    return result
  }

  @_spi(OpenUIKitHost)
  public func _searchPortable(_ query: String) -> [CSSearchableItem] {
    let terms = query.lowercased().split(whereSeparator: { $0.isWhitespace })
    guard !terms.isEmpty else { return _allPortableItems() }
    return _allPortableItems().filter { item in
      let attributes = item.attributeSet
      let haystack = ([
        attributes.title,
        attributes.displayName,
        attributes.contentDescription,
        attributes.textContent,
      ].compactMap { $0 }
        + (attributes.keywords ?? [])
        + (attributes.alternateNames ?? []))
        .joined(separator: " ").lowercased()
      return terms.allSatisfy { haystack.contains($0) }
    }
  }

  @_spi(OpenUIKitHost)
  public var _portableAppEntityMutationCounts: (writes: Int, deletes: Int) {
    storage.lock.lock()
    let result = (storage.appEntityWrites, storage.appEntityDeletes)
    storage.lock.unlock()
    return result
  }

  @_spi(OpenUIKitHost)
  public func _resetPortableState() {
    storage.lock.lock()
    storage.items.removeAll()
    storage.clientState = nil
    storage.appEntityWrites = 0
    storage.appEntityDeletes = 0
    storage.lock.unlock()
  }
}
