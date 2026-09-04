import Dispatch
import Foundation
@_spi(OpenUIKitHost) import CoreSpotlight

private final class CSLocked<Value>: @unchecked Sendable {
  private let lock = NSLock()
  private var value: Value

  init(_ value: Value) {
    self.value = value
  }

  func load() -> Value {
    lock.lock()
    defer { lock.unlock() }
    return value
  }

  func store(_ value: Value) {
    lock.lock()
    self.value = value
    lock.unlock()
  }
}

private func csAwait<T>(_ body: @escaping () async throws -> T) -> Result<T, Error> {
  let semaphore = DispatchSemaphore(value: 0)
  let box = CSLocked<Result<T, Error>?>(nil)
  Task {
    do {
      box.store(.success(try await body()))
    } catch {
      box.store(.failure(error))
    }
    semaphore.signal()
  }
  semaphore.wait()
  guard let result = box.load() else {
    preconditionFailure("async probe did not complete")
  }
  return result
}

private func csResetDefaultIndex() {
  CSSearchableIndex.default()._resetPortableState()
}

private func csSampleAttributes(
  title: String = "Portable Swift runtime",
  extra: String? = nil
) -> CSSearchableItemAttributeSet {
  let attributes = CSSearchableItemAttributeSet(itemContentType: "public.text")
  attributes.title = title
  attributes.displayName = title
  attributes.contentDescription = extra ?? "Linux spotlight probe"
  attributes.keywords = ["Swift", "Linux"]
  attributes.alternateNames = ["Open UIKit"]
  attributes.textContent = extra
  return attributes
}

private func csSampleItem(
  id: String,
  domain: String = "articles",
  title: String = "Portable Swift runtime"
) -> CSSearchableItem {
  CSSearchableItem(
    uniqueIdentifier: id,
    domainIdentifier: domain,
    attributeSet: csSampleAttributes(title: title)
  )
}

private func csRoundTrip<T: NSObject & NSSecureCoding>(_ value: T) -> T {
  let data = try! NSKeyedArchiver.archivedData(
    withRootObject: value,
    requiringSecureCoding: true
  )
  guard let restored = try? NSKeyedUnarchiver.unarchivedObject(ofClass: T.self, from: data) else {
    preconditionFailure("secure coding round-trip failed for \(T.self)")
  }
  return restored
}

func testConstants() {
  precondition(CSSearchableItemActionType == "com.apple.corespotlightitem")
  precondition(CSSearchableItemActivityIdentifier == "kCSSearchableItemActivityIdentifier")
  precondition(CSSearchQueryString == "kCSSearchQueryString")
  precondition(CSQueryContinuationActionType == "CSQueryContinuationActionType")
  precondition(CSActionIdentifier == "CSActionIdentifier")
  precondition(CSIndexErrorDomain == "CSIndexErrorDomain")
  precondition(CSSearchQueryErrorDomain == "CSSearchQueryErrorDomain")
  precondition(CSMailboxInbox == "CSMailboxInbox")
  precondition(CSMailboxDrafts == "CSMailboxDrafts")
  precondition(CSMailboxSent == "CSMailboxSent")
  precondition(CSMailboxJunk == "CSMailboxJunk")
  precondition(CSMailboxTrash == "CSMailboxTrash")
  precondition(CSMailboxArchive == "CSMailboxArchive")
}

func testSuggestionHighlightKey() {
  precondition(
    NSAttributedString.Key.suggestionHighlight.rawValue
      == "CSSuggestionHighlightAttributeName"
  )
}

func testIndexErrorCodes() {
  precondition(CSIndexError.Code.unknownError.rawValue == -1)
  precondition(CSIndexError.Code.indexUnavailableError.rawValue == -1000)
  precondition(CSIndexError.Code.invalidItemError.rawValue == -1001)
  precondition(CSIndexError.Code.invalidClientStateError.rawValue == -1002)
  precondition(CSIndexError.Code.remoteConnectionError.rawValue == -1003)
  precondition(CSIndexError.Code.quotaExceeded.rawValue == -1004)
  precondition(CSIndexError.Code.indexingUnsupported.rawValue == -1005)
  precondition(CSIndexError.Code.mismatchedClientState.rawValue == -1006)
  precondition(CSIndexError.unknownError == .unknownError)
  precondition(CSIndexError.indexUnavailableError == .indexUnavailableError)
  precondition(CSIndexError.invalidItemError == .invalidItemError)
  precondition(CSIndexError.invalidClientStateError == .invalidClientStateError)
  precondition(CSIndexError.remoteConnectionError == .remoteConnectionError)
  precondition(CSIndexError.quotaExceeded == .quotaExceeded)
  precondition(CSIndexError.indexingUnsupported == .indexingUnsupported)
  precondition(CSIndexError.mismatchedClientState == .mismatchedClientState)
  precondition(CSIndexError.Code(rawValue: -1001) == .invalidItemError)
  precondition(CSIndexError.Code(rawValue: 0) == nil)
  precondition(CSIndexError.errorDomain == CSIndexErrorDomain)
  precondition(CSIndexError._nsErrorDomain == CSIndexErrorDomain)
}

func testIndexErrorEqualityAndHash() {
  let empty = CSIndexError(.invalidItemError)
  precondition(empty.code == .invalidItemError)
  precondition(empty.errorCode == -1001)
  precondition(empty.userInfo.isEmpty)
  precondition(empty.errorUserInfo.isEmpty)
  precondition(!empty.localizedDescription.isEmpty)
  let tagged = CSIndexError(.invalidItemError, userInfo: ["sentinel": "value"])
  precondition(tagged.userInfo["sentinel"] as? String == "value")
  precondition(empty == CSIndexError(.invalidItemError))
  precondition(tagged != empty)
  precondition(empty.hashValue == CSIndexError(.invalidItemError).hashValue)
  var hasher = Hasher()
  empty.hash(into: &hasher)
  _ = hasher.finalize()
  var codeHasher = Hasher()
  CSIndexError.Code.quotaExceeded.hash(into: &codeHasher)
  _ = codeHasher.finalize()
  precondition(
    CSIndexError.Code.quotaExceeded.hashValue == CSIndexError.Code.quotaExceeded.hashValue
  )
}

func testIndexErrorPatternMatch() {
  do {
    throw CSIndexError(.mismatchedClientState)
  } catch CSIndexError.mismatchedClientState {
  } catch {
    preconditionFailure("pattern match missed CSIndexError.Code")
  }
}

func testSearchQueryErrorCodes() {
  precondition(CSSearchQueryError.Code.unknown.rawValue == -2000)
  precondition(CSSearchQueryError.Code.indexUnreachable.rawValue == -2001)
  precondition(CSSearchQueryError.Code.invalidQuery.rawValue == -2002)
  precondition(CSSearchQueryError.Code.cancelled.rawValue == -2003)
  precondition(CSSearchQueryError.unknown == .unknown)
  precondition(CSSearchQueryError.indexUnreachable == .indexUnreachable)
  precondition(CSSearchQueryError.invalidQuery == .invalidQuery)
  precondition(CSSearchQueryError.cancelled == .cancelled)
  precondition(CSSearchQueryError.Code(rawValue: -2002) == .invalidQuery)
  precondition(CSSearchQueryError.errorDomain == CSSearchQueryErrorDomain)
  let error = CSSearchQueryError(.cancelled, userInfo: ["reason": "probe"])
  precondition(error.code == .cancelled)
  precondition(error.errorCode == -2003)
  precondition(error.userInfo["reason"] as? String == "probe")
  precondition(error == CSSearchQueryError(.cancelled, userInfo: ["reason": "probe"]))
  precondition(error != CSSearchQueryError(.cancelled))
  var hasher = Hasher()
  error.hash(into: &hasher)
  CSSearchQueryError.Code.unknown.hash(into: &hasher)
  _ = hasher.finalize()
  do {
    throw CSSearchQueryError(.invalidQuery)
  } catch CSSearchQueryError.invalidQuery {
  } catch {
    preconditionFailure("query error pattern match failed")
  }
}

func testPersonAndContactIdentifier() {
  let person = CSPerson(
    displayName: "Ada",
    handles: ["ada@example.com"],
    handleIdentifier: "email"
  )
  precondition(person.displayName == "Ada")
  precondition(person.handles == ["ada@example.com"])
  precondition(person.handleIdentifier == "email")
  precondition(person.contactIdentifier == nil)
  person.contactIdentifier = "contact-1"
  precondition(person.contactIdentifier == "contact-1")
  let anonymous = CSPerson(displayName: nil, handles: [], handleIdentifier: "unknown")
  precondition(anonymous.displayName == nil)
  let restored = csRoundTrip(person)
  precondition(restored.displayName == "Ada")
  precondition(restored.handles == ["ada@example.com"])
  precondition(restored.handleIdentifier == "email")
  precondition(restored.contactIdentifier == "contact-1")
}

func testCustomAttributeKey() {
  precondition(CSCustomAttributeKey(keyName: "") == nil)
  let key = CSCustomAttributeKey(keyName: "org.example.tag")
  precondition(key != nil)
  precondition(key!.keyName == "org.example.tag")
  precondition(key!.isSearchable)
  precondition(!key!.isSearchableByDefault)
  precondition(!key!.isUnique)
  precondition(!key!.isMultiValued)
  let full = CSCustomAttributeKey(
    keyName: "org.example.multi",
    searchable: false,
    searchableByDefault: true,
    unique: true,
    multiValued: true
  )
  precondition(full != nil)
  precondition(full!.isSearchable == false)
  precondition(full!.isSearchableByDefault)
  precondition(full!.isUnique)
  precondition(full!.isMultiValued)
  let restored = csRoundTrip(full!)
  precondition(restored.keyName == "org.example.multi")
  precondition(restored.isSearchable == false)
  precondition(restored.isUnique)
}

func testAttributeSetContentTypeInitializers() {
  let typed = CSSearchableItemAttributeSet(contentType: UTType("public.text"))
  precondition(typed.itemContentType == "public.text")
  precondition(typed.contentType == "public.text")
  let legacy = CSSearchableItemAttributeSet(itemContentType: "public.data")
  precondition(legacy.itemContentType == "public.data")
  precondition(legacy.isPriority == nil)
  precondition(legacy.textContentSummary == nil)
  precondition(legacy.likelyJunk == 0)
  precondition(legacy.actionIdentifiers.isEmpty)
}

func testAttributeSetPropertyBag() {
  let attributes = CSSearchableItemAttributeSet(itemContentType: "public.movie")
  attributes.title = "Title"
  attributes.displayName = "Display"
  attributes.alternateNames = ["Alt"]
  attributes.contentDescription = "Body"
  attributes.keywords = ["one", "two"]
  attributes.relatedUniqueIdentifier = "rel"
  attributes.thumbnailData = Data([1, 2, 3])
  attributes.thumbnailURL = URL(fileURLWithPath: "/tmp/thumb")
  attributes.contentURL = URL(fileURLWithPath: "/tmp/content")
  attributes.htmlContentData = Data([9])
  attributes.textContent = "text"
  attributes.authors = [CSPerson(displayName: "A", handles: [], handleIdentifier: "a")]
  attributes.creator = "creator"
  attributes.organizations = ["Org"]
  attributes.recipients = [CSPerson(displayName: "R", handles: [], handleIdentifier: "r")]
  attributes.recipientEmailAddresses = ["r@example.com"]
  attributes.emailAddresses = ["e@example.com"]
  attributes.phoneNumbers = ["555"]
  attributes.namedLocation = "Paris"
  attributes.latitude = 48.8
  attributes.longitude = 2.3
  attributes.path = "/tmp/file"
  attributes.fileSize = 12
  attributes.fileExtension = "mov"
  attributes.addedDate = Date(timeIntervalSince1970: 1)
  attributes.contentCreationDate = Date(timeIntervalSince1970: 2)
  attributes.contentModificationDate = Date(timeIntervalSince1970: 3)
  attributes.metadataModificationDate = Date(timeIntervalSince1970: 4)
  attributes.lastUsedDate = Date(timeIntervalSince1970: 5)
  attributes.duration = 42
  attributes.streamable = 0
  attributes.deliveryType = 1
  attributes.local = 1
  attributes.playCount = 3
  attributes.codecs = ["h264"]
  attributes.languages = ["en"]
  attributes.pixelWidth = 1920
  attributes.pixelHeight = 1080
  attributes.videoBitRate = 5000
  attributes.audioBitRate = 128
  attributes.audioChannelCount = 2
  attributes.audioSampleRate = 44100
  attributes.genre = "Drama"
  attributes.musicalGenre = "Jazz"
  attributes.artist = "Artist"
  attributes.performers = ["P"]
  attributes.audioTrackNumber = 4
  attributes.album = "Album"
  attributes.headline = "Headline"
  attributes.subject = "Subject"
  attributes.comment = "Comment"
  attributes.city = "City"
  attributes.country = "FR"
  attributes.postalCode = "75001"
  attributes.thoroughfare = "Rue"
  attributes.subThoroughfare = "1"
  attributes.fullyFormattedAddress = "1 Rue"
  attributes.stateOrProvince = "IDF"
  attributes.altitude = 30
  attributes.speed = 12
  attributes.timestamp = Date(timeIntervalSince1970: 6)
  attributes.supportsNavigation = 1
  attributes.supportsPhoneCall = 0
  attributes.rankingHint = 0.75
  attributes.userCreated = 1
  attributes.userOwned = 1
  attributes.userCurated = 0
  attributes.accountIdentifier = "acct"
  attributes.accountHandles = ["h"]
  attributes.actionIdentifiers = ["act"]
  attributes.likelyJunk = 1
  attributes.sharedItemContentType = UTType("public.movie")
  attributes.darkThumbnailURL = URL(fileURLWithPath: "/tmp/dark")
  attributes.exifVersion = "2.3"
  attributes.exifgpsVersion = "2.2"
  attributes.gpsStatus = "A"
  attributes.isoSpeed = 100
  attributes.url = URL(string: "https://example.com")
  attributes.emailHeaders = ["From": ["ada@example.com"]]
  attributes.importantDates = [Date(timeIntervalSince1970: 7)]
  attributes.providerDataTypeIdentifiers = ["public.data"]
  attributes.transcribedTextContent = "transcript"
  attributes.weakRelatedUniqueIdentifier = "weak"
  attributes.additionalRecipients = [
    CSPerson(displayName: "Bcc", handles: [], handleIdentifier: "bcc")
  ]
  attributes.primaryRecipients = [
    CSPerson(displayName: "To", handles: [], handleIdentifier: "to")
  ]
  attributes.hiddenAdditionalRecipients = [
    CSPerson(displayName: "Hidden", handles: [], handleIdentifier: "hid")
  ]

  precondition(attributes.title == "Title")
  precondition(attributes.displayName == "Display")
  precondition(attributes.alternateNames == ["Alt"])
  precondition(attributes.contentDescription == "Body")
  precondition(attributes.keywords == ["one", "two"])
  precondition(attributes.relatedUniqueIdentifier == "rel")
  precondition(attributes.thumbnailData == Data([1, 2, 3]))
  precondition(attributes.thumbnailURL?.path == "/tmp/thumb")
  precondition(attributes.contentURL?.path == "/tmp/content")
  precondition(attributes.htmlContentData == Data([9]))
  precondition(attributes.textContent == "text")
  precondition(attributes.authors?.first?.displayName == "A")
  precondition(attributes.creator == "creator")
  precondition(attributes.organizations == ["Org"])
  precondition(attributes.recipients?.first?.handleIdentifier == "r")
  precondition(attributes.recipientEmailAddresses == ["r@example.com"])
  precondition(attributes.emailAddresses == ["e@example.com"])
  precondition(attributes.phoneNumbers == ["555"])
  precondition(attributes.namedLocation == "Paris")
  precondition(attributes.latitude == 48.8)
  precondition(attributes.longitude == 2.3)
  precondition(attributes.path == "/tmp/file")
  precondition(attributes.fileSize == 12)
  precondition(attributes.fileExtension == "mov")
  precondition(attributes.duration == 42)
  precondition(attributes.pixelWidth == 1920)
  precondition(attributes.genre == "Drama")
  precondition(attributes.album == "Album")
  precondition(attributes.actionIdentifiers == ["act"])
  precondition(attributes.likelyJunk == 1)
  precondition(attributes.sharedItemContentType?.identifier == "public.movie")
  precondition(attributes.emailHeaders?["From"]?.first as? String == "ada@example.com")
  precondition(attributes.importantDates?.count == 1)
  precondition(attributes.additionalRecipients?.first?.displayName == "Bcc")
  precondition(attributes.primaryRecipients?.first?.displayName == "To")
  precondition(attributes.hiddenAdditionalRecipients?.first?.displayName == "Hidden")
  attributes.associateAppEntity("entity", priority: 7)
  precondition(attributes._portableEntityPriority == 7)
}

func testAttributeSetRemainingScalars() {
  let attributes = CSSearchableItemAttributeSet(itemContentType: "public.image")
  attributes.acquisitionMake = "Make"
  attributes.acquisitionModel = "Model"
  attributes.allDay = 1
  attributes.aperture = 2.8
  attributes.audiences = ["kids"]
  attributes.audioEncodingApplication = "enc"
  attributes.authorAddresses = ["addr"]
  attributes.authorEmailAddresses = ["a@b.c"]
  attributes.authorNames = ["Ann"]
  attributes.bitsPerSample = 8
  attributes.cameraOwner = "Owner"
  attributes.colorSpace = "sRGB"
  attributes.completionDate = Date(timeIntervalSince1970: 10)
  attributes.composer = "Comp"
  attributes.contactKeywords = ["kw"]
  attributes.containerDisplayName = "CDN"
  attributes.containerIdentifier = "CID"
  attributes.containerOrder = 2
  attributes.containerTitle = "CT"
  attributes.contentRating = 5
  attributes.contentSources = ["src"]
  attributes.contentTypeTree = ["public.image", "public.data"]
  attributes.contributors = ["C"]
  attributes.copyright = "c"
  attributes.coverage = ["world"]
  attributes.director = "Dir"
  attributes.domainIdentifier = "dom"
  attributes.downloadedDate = Date(timeIntervalSince1970: 11)
  attributes.dueDate = Date(timeIntervalSince1970: 12)
  attributes.editors = ["Ed"]
  attributes.encodingApplications = ["app"]
  attributes.endDate = Date(timeIntervalSince1970: 13)
  attributes.exposureMode = 1
  attributes.exposureProgram = "P"
  attributes.exposureTime = 0.01
  attributes.exposureTimeString = "1/100"
  attributes.fNumber = 2.2
  attributes.flashOn = 1
  attributes.focalLength = 35
  attributes.focalLength35mm = 50
  attributes.fontNames = ["Helvetica"]
  attributes.generalMIDISequence = 1
  attributes.gpsAreaInformation = "area"
  attributes.gpsdop = 1.2
  attributes.gpsDateStamp = Date(timeIntervalSince1970: 14)
  attributes.gpsDestBearing = 10
  attributes.gpsDestDistance = 20
  attributes.gpsDestLatitude = 1
  attributes.gpsDestLongitude = 2
  attributes.gpsDifferental = 0
  attributes.gpsMapDatum = "WGS84"
  attributes.gpsMeasureMode = "2"
  attributes.gpsProcessingMethod = "GPS"
  attributes.gpsTrack = 90
  attributes.hasAlphaChannel = 1
  attributes.identifier = "id"
  attributes.imageDirection = 180
  attributes.information = "info"
  attributes.instantMessageAddresses = ["im"]
  attributes.instructions = "inst"
  attributes.keySignature = "C"
  attributes.kind = "kind"
  attributes.layerNames = ["L"]
  attributes.lensModel = "lens"
  attributes.lyricist = "lyr"
  attributes.mailboxIdentifiers = [CSMailboxInbox]
  attributes.maxAperture = 1.8
  attributes.mediaTypes = ["video"]
  attributes.meteringMode = "spot"
  attributes.musicalInstrumentCategory = "keys"
  attributes.musicalInstrumentName = "piano"
  attributes.orientation = 1
  attributes.originalFormat = "fmt"
  attributes.originalSource = "src"
  attributes.pageCount = 3
  attributes.pageHeight = 11
  attributes.pageWidth = 8.5
  attributes.participants = ["p"]
  attributes.pixelCount = 100
  attributes.producer = "prod"
  attributes.profileName = "prof"
  attributes.projects = ["proj"]
  attributes.providerFileTypeIdentifiers = ["public.jpeg"]
  attributes.providerInPlaceFileTypeIdentifiers = ["public.png"]
  attributes.publishers = ["pub"]
  attributes.rating = 4
  attributes.ratingDescription = "ok"
  attributes.recipientAddresses = ["ra"]
  attributes.recipientNames = ["rn"]
  attributes.recordingDate = Date(timeIntervalSince1970: 15)
  attributes.redEyeOn = 0
  attributes.resolutionHeightDPI = 72
  attributes.resolutionWidthDPI = 72
  attributes.rights = "rights"
  attributes.role = "role"
  attributes.securityMethod = "none"
  attributes.startDate = Date(timeIntervalSince1970: 16)
  attributes.tempo = 120
  attributes.theme = "theme"
  attributes.timeSignature = "4/4"
  attributes.totalBitRate = 8000
  attributes.version = "1"
  attributes.whiteBalance = 1
  precondition(attributes.acquisitionMake == "Make")
  precondition(attributes.mailboxIdentifiers == [CSMailboxInbox])
  precondition(attributes.pageCount == 3)
  precondition(attributes.fontNames == ["Helvetica"])
  precondition(attributes.gpsMapDatum == "WGS84")
  precondition(attributes.whiteBalance == 1)
  precondition(attributes.projects == ["proj"])
}

func testAttributeSetMoveAndCoding() {
  let source = CSSearchableItemAttributeSet(itemContentType: "public.text")
  source.title = "Moved"
  source.keywords = ["k"]
  source.textContent = "body"
  source.displayName = "DN"
  let key = CSCustomAttributeKey(keyName: "org.example.color")!
  source.setValue("blue" as NSString, forCustomKey: key)
  let dest = CSSearchableItemAttributeSet(itemContentType: "public.data")
  dest.move(from: source)
  precondition(dest.title == "Moved")
  precondition(dest.keywords == ["k"])
  precondition(dest.value(forCustomKey: key) as? NSString == "blue")
  let restored = csRoundTrip(source)
  precondition(restored.itemContentType == "public.text")
  precondition(restored.title == "Moved")
  precondition(restored.displayName == "DN")
  precondition(restored.keywords == ["k"])
  precondition(restored.textContent == "body")
}

func testCustomAttributeValues() {
  let attributes = CSSearchableItemAttributeSet(itemContentType: "public.item")
  let key = CSCustomAttributeKey(
    keyName: "org.example.count",
    searchable: true,
    searchableByDefault: false,
    unique: true,
    multiValued: false
  )!
  precondition(attributes.value(forCustomKey: key) == nil)
  attributes.setValue(NSNumber(value: 9), forCustomKey: key)
  precondition((attributes.value(forCustomKey: key) as? NSNumber) == 9)
  attributes.setValue(nil, forCustomKey: key)
  precondition(attributes.value(forCustomKey: key) == nil)
}

func testSearchableItemAndUpdateOptions() {
  let attributes = csSampleAttributes()
  let item = CSSearchableItem(
    uniqueIdentifier: "article-1",
    domainIdentifier: "articles",
    attributeSet: attributes
  )
  precondition(item.uniqueIdentifier == "article-1")
  precondition(item.domainIdentifier == "articles")
  precondition(item.attributeSet.title == "Portable Swift runtime")
  precondition(item.isUpdate == false)
  precondition(item.updateListenerOptions.isEmpty)
  item.isUpdate = true
  item.updateListenerOptions = [.priority, .summarization]
  precondition(item.updateListenerOptions.contains(.priority))
  precondition(item.updateListenerOptions.contains(.summarization))
  var options: CSSearchableItem.UpdateListenerOptions = []
  precondition(options.isEmpty)
  let inserted = options.insert(.priority)
  precondition(inserted.inserted)
  precondition(options.contains(.priority))
  _ = options.update(with: .summarization)
  precondition(options.contains(.summarization))
  let union = CSSearchableItem.UpdateListenerOptions.priority.union(.summarization)
  precondition(union.contains(.priority) && union.contains(.summarization))
  let intersection = union.intersection(.priority)
  precondition(intersection == .priority)
  precondition(union.isSuperset(of: .priority))
  precondition(!union.isDisjoint(with: .summarization))
  precondition(union.subtracting(.priority).contains(.summarization))
  var mutating = union
  mutating.formUnion(.priority)
  mutating.formIntersection([.priority, .summarization])
  mutating.formSymmetricDifference(.summarization)
  mutating.subtract(.priority)
  precondition(CSSearchableItem.UpdateListenerOptions.priority.isSubset(of: union))
  precondition(CSSearchableItem.UpdateListenerOptions.priority.isStrictSubset(of: union))
  precondition(union.isStrictSuperset(of: .priority))
  let fromSequence = CSSearchableItem.UpdateListenerOptions([.priority, .summarization])
  precondition(fromSequence.contains(.priority))
  let literal: CSSearchableItem.UpdateListenerOptions = [.priority]
  precondition(literal != [])
  _ = options.remove(.priority)
  item.expirationDate = Date(timeIntervalSince1970: 99)
  item.attributeSet = csSampleAttributes(title: "replaced")
  item.uniqueIdentifier = "article-2"
  item.domainIdentifier = "notes"
  precondition(item.uniqueIdentifier == "article-2")
  precondition(item.domainIdentifier == "notes")
  precondition(item.attributeSet.title == "replaced")
  let restored = csRoundTrip(item)
  precondition(restored.uniqueIdentifier == "article-2")
  precondition(restored.attributeSet.title == "replaced")
}

func testSearchableItemCompareByRank() {
  let low = csSampleItem(id: "a")
  low.attributeSet.rankingHint = 1
  let high = csSampleItem(id: "b")
  high.attributeSet.rankingHint = 9
  precondition(high.compare(byRank: low) == .orderedAscending)
  precondition(low.compare(byRank: high) == .orderedDescending)
  let tiedA = csSampleItem(id: "a")
  let tiedB = csSampleItem(id: "b")
  precondition(tiedA.compare(byRank: tiedB) == .orderedAscending)
}

func testIndexCRUDAndQuery() {
  csResetDefaultIndex()
  let index = CSSearchableIndex.default()
  precondition(CSSearchableIndex.isIndexingAvailable())
  var callbackCount = 0
  index.indexSearchableItems([csSampleItem(id: "article-1")]) { error in
    precondition(error == nil)
    callbackCount += 1
  }
  precondition(callbackCount == 1)
  precondition(index._allPortableItems().map(\.uniqueIdentifier) == ["article-1"])
  let note = csSampleItem(id: "note-1", domain: "notes", title: "Background scheduler notes")
  let asyncIndex = csAwait { try await index.indexSearchableItems([note]) }
  guard case .success = asyncIndex else { preconditionFailure("async index failed") }
  precondition(index._searchPortable("portable").map(\.uniqueIdentifier) == ["article-1"])
  let deleted = csAwait {
    try await index.deleteSearchableItems(withDomainIdentifiers: ["articles"])
  }
  guard case .success = deleted else { preconditionFailure("domain delete failed") }
  precondition(index._allPortableItems().map(\.uniqueIdentifier) == ["note-1"])
  var identifierDelete = false
  index.deleteSearchableItems(withIdentifiers: ["note-1"]) { error in
    precondition(error == nil)
    identifierDelete = true
  }
  precondition(identifierDelete)
  precondition(index._allPortableItems().isEmpty)
}

func testIndexRejectsEmptyIdentifier() {
  csResetDefaultIndex()
  let index = CSSearchableIndex.default()
  let invalid = CSSearchableItem(
    uniqueIdentifier: nil,
    domainIdentifier: nil,
    attributeSet: CSSearchableItemAttributeSet(itemContentType: "public.item")
  )
  var seen: CSIndexError.Code?
  index.indexSearchableItems([invalid]) { error in
    seen = (error as? CSIndexError)?.code
  }
  precondition(seen == .invalidItemError)
  let asyncResult = csAwait { try await index.indexSearchableItems([invalid]) }
  guard case .failure(let error) = asyncResult else {
    preconditionFailure("empty identifier was accepted asynchronously")
  }
  precondition((error as? CSIndexError)?.code == .invalidItemError)
}

func testIndexExpirationAndNamedIsolation() {
  csResetDefaultIndex()
  let index = CSSearchableIndex.default()
  let live = csSampleItem(id: "live", domain: "notes")
  let expired = csSampleItem(id: "expired", domain: "notes", title: "Expired")
  expired.expirationDate = .distantPast
  _ = csAwait { try await index.indexSearchableItems([live, expired]) }
  precondition(index._allPortableItems().map(\.uniqueIdentifier) == ["live"])
  let named = CSSearchableIndex(name: "entities")
  named._resetPortableState()
  _ = csAwait { try await named.indexAppEntities(["light.kitchen", "cover.office"]) }
  _ = csAwait {
    try await named.deleteAppEntities(identifiedBy: ["cover.office"], ofType: String.self)
  }
  let counts = named._portableAppEntityMutationCounts
  precondition(counts.writes == 2)
  precondition(counts.deletes == 1)
  precondition(index._allPortableItems().count == 1)
}

func testIndexBatchClientState() {
  csResetDefaultIndex()
  let index = CSSearchableIndex.default()
  index.beginBatch()
  index.beginIndexBatch()
  let state = Data([1, 2, 3])
  var ended = false
  index.endIndexBatch(expectedClientState: nil, newClientState: state) { error in
    precondition(error == nil)
    ended = true
  }
  precondition(ended)
  var fetched: Data?
  index.fetchLastClientState { data, error in
    precondition(error == nil)
    fetched = data
  }
  precondition(fetched == state)
  let mismatch = csAwait {
    try await index.endIndexBatch(
      expectedClientState: Data([9]),
      newClientState: Data([4])
    )
  }
  guard case .failure(let error) = mismatch else {
    preconditionFailure("mismatched client state was accepted")
  }
  precondition((error as? CSIndexError)?.code == .mismatchedClientState)
  let endBatch = csAwait { try await index.endBatch(withClientState: Data([7])) }
  guard case .success = endBatch else { preconditionFailure("endBatch failed") }
  var latest: Data?
  index.fetchLastClientState { data, _ in latest = data }
  precondition(latest == Data([7]))
}

func testIndexDeleteAllAndFetchDataUnavailable() {
  csResetDefaultIndex()
  let index = CSSearchableIndex.default()
  _ = csAwait { try await index.indexSearchableItems([csSampleItem(id: "x")]) }
  var deleted = false
  index.deleteAllSearchableItems { error in
    precondition(error == nil)
    deleted = true
  }
  precondition(deleted)
  precondition(index._allPortableItems().isEmpty)
  _ = csAwait { try await index.indexSearchableItems([csSampleItem(id: "y")]) }
  let asyncDelete = csAwait { try await index.deleteAllSearchableItems() }
  guard case .success = asyncDelete else { preconditionFailure("delete all async failed") }
  let fetch = csAwait {
    try await index.fetchData(
      forBundleIdentifier: "org.example",
      itemIdentifier: "y",
      contentType: UTType("public.text")
    )
  }
  guard case .failure(let error) = fetch else {
    preconditionFailure("fetchData invented Apple content")
  }
  precondition((error as? CSIndexError)?.code == .indexUnavailableError)
}

func testIndexProtectionClassAndDelegate() {
  let protected = CSSearchableIndex(
    name: "protected-probe",
    protectionClass: .complete
  )
  protected._resetPortableState()
  precondition(protected.protectionClass?.rawValue == FileProtectionType.complete.rawValue)
  precondition(protected.indexDelegate == nil)
  final class ProbeDelegate: NSObject, CSSearchableIndexDelegate {
    var reindexedAll = false
    var reindexedIDs: [String] = []
    func searchableIndex(
      _ searchableIndex: CSSearchableIndex,
      reindexAllSearchableItemsWithAcknowledgementHandler acknowledgementHandler: @escaping () -> Void
    ) {
      _ = searchableIndex
      reindexedAll = true
      acknowledgementHandler()
    }

    func searchableIndex(
      _ searchableIndex: CSSearchableIndex,
      reindexSearchableItemsWithIdentifiers identifiers: [String],
      acknowledgementHandler: @escaping () -> Void
    ) {
      _ = searchableIndex
      reindexedIDs = identifiers
      acknowledgementHandler()
    }
  }
  let delegate = ProbeDelegate()
  protected.indexDelegate = delegate
  protected.indexDelegate?.searchableIndex(protected) {
    delegate.reindexedAll = true
  }
  precondition(delegate.reindexedAll)
  protected.indexDelegate?.searchableIndex(
    protected,
    reindexSearchableItemsWithIdentifiers: ["a"],
    acknowledgementHandler: {}
  )
  precondition(delegate.reindexedIDs == ["a"])
  protected.indexDelegate?.searchableIndexDidThrottle(protected)
  protected.indexDelegate?.searchableIndexDidFinishThrottle(protected)
  protected.indexDelegate?.searchableItemsDidUpdate([])
  var provided: [CSSearchableItem]?
  protected.indexDelegate?.searchableItems(forIdentifiers: ["missing"]) { items in
    provided = items
  }
  precondition(provided?.isEmpty == true)
  do {
    _ = try protected.indexDelegate?.data(
      for: protected,
      itemIdentifier: "missing",
      typeIdentifier: "public.text"
    )
    preconditionFailure("delegate data should fail closed")
  } catch let error as CSIndexError {
    precondition(error.code == .indexUnavailableError)
  } catch {
    preconditionFailure("unexpected delegate data error")
  }
  do {
    _ = try protected.indexDelegate?.fileURL(
      for: protected,
      itemIdentifier: "missing",
      typeIdentifier: "public.text",
      inPlace: false
    )
    preconditionFailure("delegate fileURL should fail closed")
  } catch let error as CSIndexError {
    precondition(error.code == .indexUnavailableError)
  } catch {
    preconditionFailure("unexpected delegate fileURL error")
  }
}

func testSearchQueryFindsPortableItems() {
  csResetDefaultIndex()
  let index = CSSearchableIndex.default()
  _ = csAwait {
    try await index.indexSearchableItems([
      csSampleItem(id: "article-1", title: "Portable Swift runtime"),
      csSampleItem(id: "note-1", domain: "notes", title: "Unrelated"),
    ])
  }
  let context = CSSearchQueryContext()
  context.fetchAttributes = ["title", "keywords"]
  context.filterQueries = ["domain == articles"]
  context.keyboardLanguage = "en"
  context.sourceOptions = .allowMail
  let query = CSSearchQuery(queryString: "swift runtime", queryContext: context)
  var found: [CSSearchableItem] = []
  var completed = false
  query.foundItemsHandler = { items in found = items }
  query.completionHandler = { error in
    precondition(error == nil)
    completed = true
  }
  precondition(!query.isCancelled)
  query.start()
  precondition(completed)
  precondition(query.foundItemCount == 1)
  precondition(found.map(\.uniqueIdentifier) == ["article-1"])
  precondition(query.queryString == "swift runtime")
  precondition(query.queryContext === context)
  precondition(context.fetchAttributes == ["title", "keywords"])
  precondition(context.keyboardLanguage == "en")
  precondition(context.sourceOptions.contains(.allowMail))
}

func testSearchQueryConvenienceAndCancel() {
  csResetDefaultIndex()
  _ = csAwait {
    try await CSSearchableIndex.default().indexSearchableItems([csSampleItem(id: "z")])
  }
  let cancelled = CSSearchQuery(queryString: "z", attributes: ["title"])
  cancelled.cancel()
  precondition(cancelled.isCancelled)
  var seen: CSSearchQueryError.Code?
  cancelled.completionHandler = { error in
    seen = (error as? CSSearchQueryError)?.code
  }
  cancelled.start()
  precondition(seen == .cancelled)
  cancelled.protectionClasses = [.complete]
  precondition(cancelled.protectionClasses.first?.rawValue == FileProtectionType.complete.rawValue)
}

func testSearchQueryResultsAsyncSequence() {
  csResetDefaultIndex()
  _ = csAwait {
    try await CSSearchableIndex.default().indexSearchableItems([
      csSampleItem(id: "a", title: "alpha probe"),
      csSampleItem(id: "b", title: "beta probe"),
    ])
  }
  let query = CSSearchQuery(queryString: "probe", queryContext: nil)
  query.start()
  let compared = csAwait { () async throws -> (CSSearchQuery.Results.Item, CSSearchQuery.Results.Item) in
    var collected: [CSSearchQuery.Results.Item] = []
    for try await item in query.results {
      collected.append(item)
    }
    precondition(collected.count == 2)
    return (collected[0], collected[1])
  }
  guard case .success(let pair) = compared else {
    preconditionFailure("async results pair failed")
  }
  let first = pair.0
  let second = pair.1
  precondition(first < second || second < first)
  precondition(first != second)
  precondition(first.hashValue == first.hashValue)
  var hasher = Hasher()
  first.hash(into: &hasher)
  _ = hasher.finalize()
  let ids = csAwait { () async throws -> [String] in
    var collected: [String] = []
    for try await item in query.results {
      collected.append(item.id)
    }
    return collected
  }
  guard case .success(let collected) = ids else {
    preconditionFailure("async results iteration failed")
  }
  precondition(collected.sorted() == ["a", "b"])
  let contains = csAwait { try await query.results.contains { $0.id == "a" } }
  guard case .success(true) = contains else {
    preconditionFailure("async contains failed")
  }
}

func testSearchQueryContextCodingAndSourceOptions() {
  let context = CSSearchQueryContext()
  context.fetchAttributes = ["title"]
  context.filterQueries = ["x"]
  context.keyboardLanguage = "fr"
  context.sourceOptions = [.allowMail]
  var options = CSSearchQueryContext.SourceOptions()
  precondition(options.isEmpty)
  _ = options.insert(.allowMail)
  precondition(options.contains(.allowMail))
  precondition(options.union(.allowMail).contains(.allowMail))
  precondition(options.intersection(.allowMail) == .allowMail)
  precondition(options.symmetricDifference([]) == .allowMail)
  var mutating: CSSearchQueryContext.SourceOptions = []
  mutating.formUnion(.allowMail)
  mutating.formIntersection(.allowMail)
  mutating.formSymmetricDifference([])
  mutating.subtract([])
  precondition(!mutating.isDisjoint(with: .allowMail))
  precondition(mutating.isSuperset(of: .allowMail))
  precondition(mutating.isSubset(of: .allowMail))
  let restored = csRoundTrip(context)
  precondition(restored.fetchAttributes == ["title"])
  precondition(restored.filterQueries == ["x"])
  precondition(restored.keyboardLanguage == "fr")
  precondition(restored.sourceOptions.contains(.allowMail))
}

func testSuggestionCodingAndCompare() {
  let encoded = CSSuggestion(kind: .custom, text: "alpha")
  let other = CSSuggestion(kind: .default, text: "beta")
  precondition(encoded.suggestionKind == .custom)
  precondition(String(encoded.localizedAttributedSuggestion.characters) == "alpha")
  precondition(encoded.compare(other) == .orderedAscending)
  precondition(encoded.compare(byRank: other) == .orderedAscending)
  precondition(CSSuggestion.SuggestionKind.none.rawValue == 0)
  precondition(CSSuggestion.SuggestionKind.custom.rawValue == 1)
  precondition(CSSuggestion.SuggestionKind.default.rawValue == 2)
  precondition(CSSuggestion.SuggestionKind(rawValue: 1) == .custom)
  var hasher = Hasher()
  CSSuggestion.SuggestionKind.custom.hash(into: &hasher)
  _ = hasher.finalize()
  precondition(
    CSSuggestion.SuggestionKind.custom.hashValue == CSSuggestion.SuggestionKind.custom.hashValue
  )
  let restored = csRoundTrip(encoded)
  precondition(restored.suggestionKind == .custom)
  precondition(String(restored.localizedAttributedSuggestion.characters) == "alpha")
}

func testUserQueryFailClosedSuggestions() {
  csResetDefaultIndex()
  _ = csAwait {
    try await CSSearchableIndex.default().indexSearchableItems([
      csSampleItem(id: "hit", title: "user query probe")
    ])
  }
  let context = CSUserQueryContext(currentSuggestion: nil)
  context.disableSemanticSearch = true
  context.enableRankedResults = false
  context.maxRankedResultCount = 0
  context.maxResultCount = 5
  context.maxSuggestionCount = 0
  CSUserQuery.prepare()
  CSUserQuery.prepareProtectionClasses([.complete])
  let query = CSUserQuery(userQueryString: "probe", userQueryContext: context)
  var suggestions: [CSSuggestion]?
  query.foundSuggestionsHandler = { suggestions = $0 }
  var foundItems: [CSSearchableItem] = []
  query.foundItemsHandler = { foundItems = $0 }
  query.start()
  precondition(suggestions?.isEmpty == true)
  precondition(query.foundSuggestionCount == 0)
  precondition(query.foundItemCount == 1)
  precondition(foundItems.map(\.uniqueIdentifier) == ["hit"])
  let responseIDs = csAwait { () async throws -> [String] in
    var collected: [String] = []
    for try await response in query.responses {
      collected.append(response.id)
    }
    return collected
  }
  guard case .success(let ids) = responseIDs else {
    preconditionFailure("user query responses failed")
  }
  precondition(ids == ["item:hit"])
  let suggestionIDs = csAwait { () async throws -> Int in
    var count = 0
    for try await _ in query.suggestions { count += 1 }
    return count
  }
  guard case .success(0) = suggestionIDs else {
    preconditionFailure("user query suggestions were not empty")
  }
  if let found = foundItems.first {
    let item = CSUserQuery.Item(item: found)
    query.userEngaged(item, visibleItems: [item], interaction: .select)
    query.userEngaged(item, visibleItems: [item], interaction: .focus)
    query.userEngaged(item, visibleItems: [item], interaction: .default)
    precondition(CSUserQuery.UserInteractionKind.default == .select)
    precondition(CSUserQuery.UserInteractionKind(rawValue: 1) == .focus)
    var hasher = Hasher()
    CSUserQuery.UserInteractionKind.select.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(item.id == "hit")
    precondition(item.item.uniqueIdentifier == "hit")
  } else {
    preconditionFailure("expected item response")
  }
}

func testUserQueryContextCoding() {
  let context = CSUserQueryContext(currentSuggestion: nil)
  context.maxResultCount = 3
  context.maxSuggestionCount = 2
  context.maxRankedResultCount = 1
  context.enableRankedResults = true
  context.disableSemanticSearch = true
  let restored = csRoundTrip(context)
  precondition(restored.maxResultCount == 3)
  precondition(restored.maxSuggestionCount == 2)
  precondition(restored.maxRankedResultCount == 1)
  precondition(restored.enableRankedResults)
  precondition(restored.disableSemanticSearch)
}

func testLocalizedString() {
  let localized = CSLocalizedString(localizedStrings: [
    "en": "Hello",
    "fr": "Bonjour",
  ])
  let value = localized.localizedString()
  precondition(value == "Hello" || value == "Bonjour" || !value.isEmpty)
  let empty = CSLocalizedString(localizedStrings: [:])
  precondition(empty.localizedString().isEmpty)
}

func testImportExtensionFailClosed() {
  let ext = CSImportExtension()
  do {
    try ext.update(
      CSSearchableItemAttributeSet(itemContentType: "public.text"),
      forFileAt: URL(fileURLWithPath: "/tmp/missing")
    )
    preconditionFailure("import extension invented success")
  } catch let error as CSIndexError {
    precondition(error.code == .indexingUnsupported)
  } catch {
    preconditionFailure("unexpected import error")
  }
}

func testIndexExtensionRequestHandler() {
  let handler = CSIndexExtensionRequestHandler()
  var acked = false
  handler.searchableIndex(CSSearchableIndex.default()) {
    acked = true
  }
  precondition(acked)
  var ids: [String] = []
  handler.searchableIndex(
    CSSearchableIndex.default(),
    reindexSearchableItemsWithIdentifiers: ["one"]
  ) {
    ids = ["one"]
  }
  precondition(ids == ["one"])
}

func testUserQueryComparableWrappers() {
  let first = CSUserQuery.Item(item: csSampleItem(id: "a"))
  let second = CSUserQuery.Item(item: csSampleItem(id: "b"))
  precondition(first < second)
  precondition(first != second)
  precondition(!(first == second))
  let encoded = CSSuggestion(kind: .none, text: "a")
  let other = CSSuggestion(kind: .none, text: "b")
  let s1 = CSUserQuery.Suggestion(suggestion: encoded)
  let s2 = CSUserQuery.Suggestion(suggestion: other)
  precondition(s1 < s2)
  precondition(s1.id == "a")
  let r1 = CSUserQuery.Response.item(first)
  let r2 = CSUserQuery.Response.suggestion(s1)
  precondition(r1 != r2)
  precondition(r1.id.hasPrefix("item:"))
  precondition(r2.id.hasPrefix("suggestion:"))
}
