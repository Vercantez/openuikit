import Foundation

#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#else
/// Module-local `UTType` lookalike for the isolated Linux host. UniformTypeIdentifiers
/// is not a seeded dependency of this lane. Darwin builds import the real module.
public struct UTType: Hashable, Sendable {
  public let identifier: String

  public init(_ identifier: String) {
    self.identifier = identifier
  }
}
#endif

public let CSSearchableItemActionType =
  "com.apple.corespotlightitem"
public let CSSearchableItemActivityIdentifier =
  "kCSSearchableItemActivityIdentifier"
public let CSSearchQueryString = "kCSSearchQueryString"
public let CSQueryContinuationActionType = "CSQueryContinuationActionType"
public let CSActionIdentifier = "CSActionIdentifier"
public let CSIndexErrorDomain = "CSIndexErrorDomain"
public let CSSearchQueryErrorDomain = "CSSearchQueryErrorDomain"
public let CSMailboxInbox = "CSMailboxInbox"
public let CSMailboxDrafts = "CSMailboxDrafts"
public let CSMailboxSent = "CSMailboxSent"
public let CSMailboxJunk = "CSMailboxJunk"
public let CSMailboxTrash = "CSMailboxTrash"
public let CSMailboxArchive = "CSMailboxArchive"

extension NSAttributedString.Key {
  public static let suggestionHighlight = NSAttributedString.Key(
    "CSSuggestionHighlightAttributeName"
  )
}

@frozen
public struct CSIndexError: Foundation._BridgedStoredNSError, @unchecked Sendable {
  public enum Code: Int, Foundation._ErrorCodeProtocol, Sendable {
    public typealias _ErrorType = CSIndexError

    case unknownError = -1
    case indexUnavailableError = -1000
    case invalidItemError = -1001
    case invalidClientStateError = -1002
    case remoteConnectionError = -1003
    case quotaExceeded = -1004
    case indexingUnsupported = -1005
    case mismatchedClientState = -1006
  }

  public let _nsError: NSError

  public init(_nsError: NSError) {
    self._nsError = _nsError
  }

  public static var _nsErrorDomain: String { CSIndexErrorDomain }

  public static var unknownError: Code { .unknownError }
  public static var indexUnavailableError: Code { .indexUnavailableError }
  public static var invalidItemError: Code { .invalidItemError }
  public static var invalidClientStateError: Code { .invalidClientStateError }
  public static var remoteConnectionError: Code { .remoteConnectionError }
  public static var quotaExceeded: Code { .quotaExceeded }
  public static var indexingUnsupported: Code { .indexingUnsupported }
  public static var mismatchedClientState: Code { .mismatchedClientState }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(_nsError.domain)
    hasher.combine(_nsError.code)
  }

  public var hashValue: Int {
    var hasher = Hasher()
    hash(into: &hasher)
    return hasher.finalize()
  }
}

@frozen
public struct CSSearchQueryError: Foundation._BridgedStoredNSError, @unchecked Sendable {
  public enum Code: Int, Foundation._ErrorCodeProtocol, Sendable {
    public typealias _ErrorType = CSSearchQueryError

    case unknown = -2000
    case indexUnreachable = -2001
    case invalidQuery = -2002
    case cancelled = -2003
  }

  public let _nsError: NSError

  public init(_nsError: NSError) {
    self._nsError = _nsError
  }

  public static var _nsErrorDomain: String { CSSearchQueryErrorDomain }

  public static var unknown: Code { .unknown }
  public static var indexUnreachable: Code { .indexUnreachable }
  public static var invalidQuery: Code { .invalidQuery }
  public static var cancelled: Code { .cancelled }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(_nsError.domain)
    hasher.combine(_nsError.code)
  }

  public var hashValue: Int {
    var hasher = Hasher()
    hash(into: &hasher)
    return hasher.finalize()
  }
}

public final class CSCustomAttributeKey: NSObject, NSSecureCoding, @unchecked Sendable {
  public let keyName: String
  public let isSearchable: Bool
  public let isSearchableByDefault: Bool
  public let isUnique: Bool
  public let isMultiValued: Bool

  public static var supportsSecureCoding: Bool { true }

  public convenience init?(keyName: String) {
    self.init(
      keyName: keyName,
      searchable: true,
      searchableByDefault: false,
      unique: false,
      multiValued: false
    )
  }

  public init?(
    keyName: String,
    searchable: Bool,
    searchableByDefault: Bool,
    unique: Bool,
    multiValued: Bool
  ) {
    guard !keyName.isEmpty else { return nil }
    self.keyName = keyName
    self.isSearchable = searchable
    self.isSearchableByDefault = searchableByDefault
    self.isUnique = unique
    self.isMultiValued = multiValued
    super.init()
  }

  public required init?(coder: NSCoder) {
    guard let keyName = coder.decodeObject(of: NSString.self, forKey: "keyName") as String?,
      !keyName.isEmpty
    else {
      return nil
    }
    self.keyName = keyName
    self.isSearchable = coder.decodeBool(forKey: "searchable")
    self.isSearchableByDefault = coder.decodeBool(forKey: "searchableByDefault")
    self.isUnique = coder.decodeBool(forKey: "unique")
    self.isMultiValued = coder.decodeBool(forKey: "multiValued")
    super.init()
  }

  public func encode(with coder: NSCoder) {
    coder.encode(keyName as NSString, forKey: "keyName")
    coder.encode(isSearchable, forKey: "searchable")
    coder.encode(isSearchableByDefault, forKey: "searchableByDefault")
    coder.encode(isUnique, forKey: "unique")
    coder.encode(isMultiValued, forKey: "multiValued")
  }
}

public final class CSPerson: NSObject, NSSecureCoding, @unchecked Sendable {
  public let displayName: String?
  public let handles: [String]
  public let handleIdentifier: String
  public var contactIdentifier: String?

  public static var supportsSecureCoding: Bool { true }

  public init(
    displayName: String?,
    handles: [String],
    handleIdentifier: String
  ) {
    self.displayName = displayName
    self.handles = handles
    self.handleIdentifier = handleIdentifier
    super.init()
  }

  public required init?(coder: NSCoder) {
    self.displayName = coder.decodeObject(of: NSString.self, forKey: "displayName") as String?
    let handles =
      coder.decodeObject(of: [NSArray.self, NSString.self], forKey: "handles") as? [String] ?? []
    self.handles = handles
    guard
      let handleIdentifier = coder.decodeObject(of: NSString.self, forKey: "handleIdentifier")
        as String?
    else {
      return nil
    }
    self.handleIdentifier = handleIdentifier
    self.contactIdentifier =
      coder.decodeObject(of: NSString.self, forKey: "contactIdentifier") as String?
    super.init()
  }

  public func encode(with coder: NSCoder) {
    coder.encode(displayName as NSString?, forKey: "displayName")
    coder.encode(handles as NSArray, forKey: "handles")
    coder.encode(handleIdentifier as NSString, forKey: "handleIdentifier")
    coder.encode(contactIdentifier as NSString?, forKey: "contactIdentifier")
  }
}

open class CSSearchableItemAttributeSet: NSObject, NSSecureCoding, @unchecked Sendable {
  public let itemContentType: String
  fileprivate var storage: [String: Any] = [:]
  fileprivate var customValues: [String: (any NSSecureCoding)?] = [:]

  public static var supportsSecureCoding: Bool { true }

  public var exifgpsVersion: String? {
    get { self.storage["exifgpsVersion"] as? String }
    set { self.storage["exifgpsVersion"] = newValue }
  }

  public var exifVersion: String? {
    get { self.storage["exifVersion"] as? String }
    set { self.storage["exifVersion"] = newValue }
  }

  public var gpsAreaInformation: String? {
    get { self.storage["gpsAreaInformation"] as? String }
    set { self.storage["gpsAreaInformation"] = newValue }
  }

  public var gpsdop: NSNumber? {
    get { self.storage["gpsdop"] as? NSNumber }
    set { self.storage["gpsdop"] = newValue }
  }

  public var gpsDateStamp: Date? {
    get { self.storage["gpsDateStamp"] as? Date }
    set { self.storage["gpsDateStamp"] = newValue }
  }

  public var gpsDestBearing: NSNumber? {
    get { self.storage["gpsDestBearing"] as? NSNumber }
    set { self.storage["gpsDestBearing"] = newValue }
  }

  public var gpsDestDistance: NSNumber? {
    get { self.storage["gpsDestDistance"] as? NSNumber }
    set { self.storage["gpsDestDistance"] = newValue }
  }

  public var gpsDestLatitude: NSNumber? {
    get { self.storage["gpsDestLatitude"] as? NSNumber }
    set { self.storage["gpsDestLatitude"] = newValue }
  }

  public var gpsDestLongitude: NSNumber? {
    get { self.storage["gpsDestLongitude"] as? NSNumber }
    set { self.storage["gpsDestLongitude"] = newValue }
  }

  public var gpsDifferental: NSNumber? {
    get { self.storage["gpsDifferental"] as? NSNumber }
    set { self.storage["gpsDifferental"] = newValue }
  }

  public var gpsMapDatum: String? {
    get { self.storage["gpsMapDatum"] as? String }
    set { self.storage["gpsMapDatum"] = newValue }
  }

  public var gpsMeasureMode: String? {
    get { self.storage["gpsMeasureMode"] as? String }
    set { self.storage["gpsMeasureMode"] = newValue }
  }

  public var gpsProcessingMethod: String? {
    get { self.storage["gpsProcessingMethod"] as? String }
    set { self.storage["gpsProcessingMethod"] = newValue }
  }

  public var gpsStatus: String? {
    get { self.storage["gpsStatus"] as? String }
    set { self.storage["gpsStatus"] = newValue }
  }

  public var gpsTrack: NSNumber? {
    get { self.storage["gpsTrack"] as? NSNumber }
    set { self.storage["gpsTrack"] = newValue }
  }

  public var htmlContentData: Data? {
    get { self.storage["htmlContentData"] as? Data }
    set { self.storage["htmlContentData"] = newValue }
  }

  public var isoSpeed: NSNumber? {
    get { self.storage["isoSpeed"] as? NSNumber }
    set { self.storage["isoSpeed"] = newValue }
  }

  public var url: URL? {
    get { self.storage["url"] as? URL }
    set { self.storage["url"] = newValue }
  }

  public var accountHandles: [String]? {
    get { self.storage["accountHandles"] as? [String] }
    set { self.storage["accountHandles"] = newValue }
  }

  public var accountIdentifier: String? {
    get { self.storage["accountIdentifier"] as? String }
    set { self.storage["accountIdentifier"] = newValue }
  }

  public var acquisitionMake: String? {
    get { self.storage["acquisitionMake"] as? String }
    set { self.storage["acquisitionMake"] = newValue }
  }

  public var acquisitionModel: String? {
    get { self.storage["acquisitionModel"] as? String }
    set { self.storage["acquisitionModel"] = newValue }
  }

  public var actionIdentifiers: [String] {
    get { (self.storage["actionIdentifiers"] as? [String]) ?? [] }
    set { self.storage["actionIdentifiers"] = newValue }
  }

  public var addedDate: Date? {
    get { self.storage["addedDate"] as? Date }
    set { self.storage["addedDate"] = newValue }
  }

  public var additionalRecipients: [CSPerson]? {
    get { self.storage["additionalRecipients"] as? [CSPerson] }
    set { self.storage["additionalRecipients"] = newValue }
  }

  public var album: String? {
    get { self.storage["album"] as? String }
    set { self.storage["album"] = newValue }
  }

  public var allDay: NSNumber? {
    get { self.storage["allDay"] as? NSNumber }
    set { self.storage["allDay"] = newValue }
  }

  public var alternateNames: [String]? {
    get { self.storage["alternateNames"] as? [String] }
    set { self.storage["alternateNames"] = newValue }
  }

  public var altitude: NSNumber? {
    get { self.storage["altitude"] as? NSNumber }
    set { self.storage["altitude"] = newValue }
  }

  public var aperture: NSNumber? {
    get { self.storage["aperture"] as? NSNumber }
    set { self.storage["aperture"] = newValue }
  }

  public var artist: String? {
    get { self.storage["artist"] as? String }
    set { self.storage["artist"] = newValue }
  }

  public var audiences: [String]? {
    get { self.storage["audiences"] as? [String] }
    set { self.storage["audiences"] = newValue }
  }

  public var audioBitRate: NSNumber? {
    get { self.storage["audioBitRate"] as? NSNumber }
    set { self.storage["audioBitRate"] = newValue }
  }

  public var audioChannelCount: NSNumber? {
    get { self.storage["audioChannelCount"] as? NSNumber }
    set { self.storage["audioChannelCount"] = newValue }
  }

  public var audioEncodingApplication: String? {
    get { self.storage["audioEncodingApplication"] as? String }
    set { self.storage["audioEncodingApplication"] = newValue }
  }

  public var audioSampleRate: NSNumber? {
    get { self.storage["audioSampleRate"] as? NSNumber }
    set { self.storage["audioSampleRate"] = newValue }
  }

  public var audioTrackNumber: NSNumber? {
    get { self.storage["audioTrackNumber"] as? NSNumber }
    set { self.storage["audioTrackNumber"] = newValue }
  }

  public var authorAddresses: [String]? {
    get { self.storage["authorAddresses"] as? [String] }
    set { self.storage["authorAddresses"] = newValue }
  }

  public var authorEmailAddresses: [String]? {
    get { self.storage["authorEmailAddresses"] as? [String] }
    set { self.storage["authorEmailAddresses"] = newValue }
  }

  public var authorNames: [String]? {
    get { self.storage["authorNames"] as? [String] }
    set { self.storage["authorNames"] = newValue }
  }

  public var authors: [CSPerson]? {
    get { self.storage["authors"] as? [CSPerson] }
    set { self.storage["authors"] = newValue }
  }

  public var bitsPerSample: NSNumber? {
    get { self.storage["bitsPerSample"] as? NSNumber }
    set { self.storage["bitsPerSample"] = newValue }
  }

  public var cameraOwner: String? {
    get { self.storage["cameraOwner"] as? String }
    set { self.storage["cameraOwner"] = newValue }
  }

  public var city: String? {
    get { self.storage["city"] as? String }
    set { self.storage["city"] = newValue }
  }

  public var codecs: [String]? {
    get { self.storage["codecs"] as? [String] }
    set { self.storage["codecs"] = newValue }
  }

  public var colorSpace: String? {
    get { self.storage["colorSpace"] as? String }
    set { self.storage["colorSpace"] = newValue }
  }

  public var comment: String? {
    get { self.storage["comment"] as? String }
    set { self.storage["comment"] = newValue }
  }

  public var completionDate: Date? {
    get { self.storage["completionDate"] as? Date }
    set { self.storage["completionDate"] = newValue }
  }

  public var composer: String? {
    get { self.storage["composer"] as? String }
    set { self.storage["composer"] = newValue }
  }

  public var contactKeywords: [String]? {
    get { self.storage["contactKeywords"] as? [String] }
    set { self.storage["contactKeywords"] = newValue }
  }

  public var containerDisplayName: String? {
    get { self.storage["containerDisplayName"] as? String }
    set { self.storage["containerDisplayName"] = newValue }
  }

  public var containerIdentifier: String? {
    get { self.storage["containerIdentifier"] as? String }
    set { self.storage["containerIdentifier"] = newValue }
  }

  public var containerOrder: NSNumber? {
    get { self.storage["containerOrder"] as? NSNumber }
    set { self.storage["containerOrder"] = newValue }
  }

  public var containerTitle: String? {
    get { self.storage["containerTitle"] as? String }
    set { self.storage["containerTitle"] = newValue }
  }

  public var contentCreationDate: Date? {
    get { self.storage["contentCreationDate"] as? Date }
    set { self.storage["contentCreationDate"] = newValue }
  }

  public var contentDescription: String? {
    get { self.storage["contentDescription"] as? String }
    set { self.storage["contentDescription"] = newValue }
  }

  public var contentModificationDate: Date? {
    get { self.storage["contentModificationDate"] as? Date }
    set { self.storage["contentModificationDate"] = newValue }
  }

  public var contentRating: NSNumber? {
    get { self.storage["contentRating"] as? NSNumber }
    set { self.storage["contentRating"] = newValue }
  }

  public var contentSources: [String]? {
    get { self.storage["contentSources"] as? [String] }
    set { self.storage["contentSources"] = newValue }
  }

  public var contentType: String? {
    get { self.storage["contentType"] as? String }
    set { self.storage["contentType"] = newValue }
  }

  public var contentTypeTree: [String]? {
    get { self.storage["contentTypeTree"] as? [String] }
    set { self.storage["contentTypeTree"] = newValue }
  }

  public var contentURL: URL? {
    get { self.storage["contentURL"] as? URL }
    set { self.storage["contentURL"] = newValue }
  }

  public var contributors: [String]? {
    get { self.storage["contributors"] as? [String] }
    set { self.storage["contributors"] = newValue }
  }

  public var copyright: String? {
    get { self.storage["copyright"] as? String }
    set { self.storage["copyright"] = newValue }
  }

  public var country: String? {
    get { self.storage["country"] as? String }
    set { self.storage["country"] = newValue }
  }

  public var coverage: [String]? {
    get { self.storage["coverage"] as? [String] }
    set { self.storage["coverage"] = newValue }
  }

  public var creator: String? {
    get { self.storage["creator"] as? String }
    set { self.storage["creator"] = newValue }
  }

  public var darkThumbnailURL: URL? {
    get { self.storage["darkThumbnailURL"] as? URL }
    set { self.storage["darkThumbnailURL"] = newValue }
  }

  public var deliveryType: NSNumber? {
    get { self.storage["deliveryType"] as? NSNumber }
    set { self.storage["deliveryType"] = newValue }
  }

  public var director: String? {
    get { self.storage["director"] as? String }
    set { self.storage["director"] = newValue }
  }

  public var displayName: String? {
    get { self.storage["displayName"] as? String }
    set { self.storage["displayName"] = newValue }
  }

  public var domainIdentifier: String? {
    get { self.storage["domainIdentifier"] as? String }
    set { self.storage["domainIdentifier"] = newValue }
  }

  public var downloadedDate: Date? {
    get { self.storage["downloadedDate"] as? Date }
    set { self.storage["downloadedDate"] = newValue }
  }

  public var dueDate: Date? {
    get { self.storage["dueDate"] as? Date }
    set { self.storage["dueDate"] = newValue }
  }

  public var duration: NSNumber? {
    get { self.storage["duration"] as? NSNumber }
    set { self.storage["duration"] = newValue }
  }

  public var editors: [String]? {
    get { self.storage["editors"] as? [String] }
    set { self.storage["editors"] = newValue }
  }

  public var emailAddresses: [String]? {
    get { self.storage["emailAddresses"] as? [String] }
    set { self.storage["emailAddresses"] = newValue }
  }

  public var emailHeaders: [String : [Any]]? {
    get { self.storage["emailHeaders"] as? [String: [Any]] }
    set { self.storage["emailHeaders"] = newValue }
  }

  public var encodingApplications: [String]? {
    get { self.storage["encodingApplications"] as? [String] }
    set { self.storage["encodingApplications"] = newValue }
  }

  public var endDate: Date? {
    get { self.storage["endDate"] as? Date }
    set { self.storage["endDate"] = newValue }
  }

  public var exposureMode: NSNumber? {
    get { self.storage["exposureMode"] as? NSNumber }
    set { self.storage["exposureMode"] = newValue }
  }

  public var exposureProgram: String? {
    get { self.storage["exposureProgram"] as? String }
    set { self.storage["exposureProgram"] = newValue }
  }

  public var exposureTime: NSNumber? {
    get { self.storage["exposureTime"] as? NSNumber }
    set { self.storage["exposureTime"] = newValue }
  }

  public var exposureTimeString: String? {
    get { self.storage["exposureTimeString"] as? String }
    set { self.storage["exposureTimeString"] = newValue }
  }

  public var fNumber: NSNumber? {
    get { self.storage["fNumber"] as? NSNumber }
    set { self.storage["fNumber"] = newValue }
  }

  public var fileSize: NSNumber? {
    get { self.storage["fileSize"] as? NSNumber }
    set { self.storage["fileSize"] = newValue }
  }

  public var flashOn: NSNumber? {
    get { self.storage["flashOn"] as? NSNumber }
    set { self.storage["flashOn"] = newValue }
  }

  public var focalLength: NSNumber? {
    get { self.storage["focalLength"] as? NSNumber }
    set { self.storage["focalLength"] = newValue }
  }

  public var focalLength35mm: NSNumber? {
    get { self.storage["focalLength35mm"] as? NSNumber }
    set { self.storage["focalLength35mm"] = newValue }
  }

  public var fontNames: [String]? {
    get { self.storage["fontNames"] as? [String] }
    set { self.storage["fontNames"] = newValue }
  }

  public var fullyFormattedAddress: String? {
    get { self.storage["fullyFormattedAddress"] as? String }
    set { self.storage["fullyFormattedAddress"] = newValue }
  }

  public var generalMIDISequence: NSNumber? {
    get { self.storage["generalMIDISequence"] as? NSNumber }
    set { self.storage["generalMIDISequence"] = newValue }
  }

  public var genre: String? {
    get { self.storage["genre"] as? String }
    set { self.storage["genre"] = newValue }
  }

  public var hasAlphaChannel: NSNumber? {
    get { self.storage["hasAlphaChannel"] as? NSNumber }
    set { self.storage["hasAlphaChannel"] = newValue }
  }

  public var headline: String? {
    get { self.storage["headline"] as? String }
    set { self.storage["headline"] = newValue }
  }

  public var hiddenAdditionalRecipients: [CSPerson]? {
    get { self.storage["hiddenAdditionalRecipients"] as? [CSPerson] }
    set { self.storage["hiddenAdditionalRecipients"] = newValue }
  }

  public var identifier: String? {
    get { self.storage["identifier"] as? String }
    set { self.storage["identifier"] = newValue }
  }

  public var imageDirection: NSNumber? {
    get { self.storage["imageDirection"] as? NSNumber }
    set { self.storage["imageDirection"] = newValue }
  }

  public var importantDates: [Date]? {
    get { self.storage["importantDates"] as? [Date] }
    set { self.storage["importantDates"] = newValue }
  }

  public var information: String? {
    get { self.storage["information"] as? String }
    set { self.storage["information"] = newValue }
  }

  public var instantMessageAddresses: [String]? {
    get { self.storage["instantMessageAddresses"] as? [String] }
    set { self.storage["instantMessageAddresses"] = newValue }
  }

  public var instructions: String? {
    get { self.storage["instructions"] as? String }
    set { self.storage["instructions"] = newValue }
  }

  public var isPriority: NSNumber? {
    self.storage["isPriority"] as? NSNumber
  }

  public var keySignature: String? {
    get { self.storage["keySignature"] as? String }
    set { self.storage["keySignature"] = newValue }
  }

  public var keywords: [String]? {
    get { self.storage["keywords"] as? [String] }
    set { self.storage["keywords"] = newValue }
  }

  public var kind: String? {
    get { self.storage["kind"] as? String }
    set { self.storage["kind"] = newValue }
  }

  public var languages: [String]? {
    get { self.storage["languages"] as? [String] }
    set { self.storage["languages"] = newValue }
  }

  public var lastUsedDate: Date? {
    get { self.storage["lastUsedDate"] as? Date }
    set { self.storage["lastUsedDate"] = newValue }
  }

  public var latitude: NSNumber? {
    get { self.storage["latitude"] as? NSNumber }
    set { self.storage["latitude"] = newValue }
  }

  public var layerNames: [String]? {
    get { self.storage["layerNames"] as? [String] }
    set { self.storage["layerNames"] = newValue }
  }

  public var lensModel: String? {
    get { self.storage["lensModel"] as? String }
    set { self.storage["lensModel"] = newValue }
  }

  public var likelyJunk: NSNumber {
    get { (self.storage["likelyJunk"] as? NSNumber) ?? 0 }
    set { self.storage["likelyJunk"] = newValue }
  }

  public var local: NSNumber? {
    get { self.storage["local"] as? NSNumber }
    set { self.storage["local"] = newValue }
  }

  public var longitude: NSNumber? {
    get { self.storage["longitude"] as? NSNumber }
    set { self.storage["longitude"] = newValue }
  }

  public var lyricist: String? {
    get { self.storage["lyricist"] as? String }
    set { self.storage["lyricist"] = newValue }
  }

  public var mailboxIdentifiers: [String]? {
    get { self.storage["mailboxIdentifiers"] as? [String] }
    set { self.storage["mailboxIdentifiers"] = newValue }
  }

  public var maxAperture: NSNumber? {
    get { self.storage["maxAperture"] as? NSNumber }
    set { self.storage["maxAperture"] = newValue }
  }

  public var mediaTypes: [String]? {
    get { self.storage["mediaTypes"] as? [String] }
    set { self.storage["mediaTypes"] = newValue }
  }

  public var metadataModificationDate: Date? {
    get { self.storage["metadataModificationDate"] as? Date }
    set { self.storage["metadataModificationDate"] = newValue }
  }

  public var meteringMode: String? {
    get { self.storage["meteringMode"] as? String }
    set { self.storage["meteringMode"] = newValue }
  }

  public var musicalGenre: String? {
    get { self.storage["musicalGenre"] as? String }
    set { self.storage["musicalGenre"] = newValue }
  }

  public var musicalInstrumentCategory: String? {
    get { self.storage["musicalInstrumentCategory"] as? String }
    set { self.storage["musicalInstrumentCategory"] = newValue }
  }

  public var musicalInstrumentName: String? {
    get { self.storage["musicalInstrumentName"] as? String }
    set { self.storage["musicalInstrumentName"] = newValue }
  }

  public var namedLocation: String? {
    get { self.storage["namedLocation"] as? String }
    set { self.storage["namedLocation"] = newValue }
  }

  public var organizations: [String]? {
    get { self.storage["organizations"] as? [String] }
    set { self.storage["organizations"] = newValue }
  }

  public var orientation: NSNumber? {
    get { self.storage["orientation"] as? NSNumber }
    set { self.storage["orientation"] = newValue }
  }

  public var originalFormat: String? {
    get { self.storage["originalFormat"] as? String }
    set { self.storage["originalFormat"] = newValue }
  }

  public var originalSource: String? {
    get { self.storage["originalSource"] as? String }
    set { self.storage["originalSource"] = newValue }
  }

  public var pageCount: NSNumber? {
    get { self.storage["pageCount"] as? NSNumber }
    set { self.storage["pageCount"] = newValue }
  }

  public var pageHeight: NSNumber? {
    get { self.storage["pageHeight"] as? NSNumber }
    set { self.storage["pageHeight"] = newValue }
  }

  public var pageWidth: NSNumber? {
    get { self.storage["pageWidth"] as? NSNumber }
    set { self.storage["pageWidth"] = newValue }
  }

  public var participants: [String]? {
    get { self.storage["participants"] as? [String] }
    set { self.storage["participants"] = newValue }
  }

  public var path: String? {
    get { self.storage["path"] as? String }
    set { self.storage["path"] = newValue }
  }

  public var performers: [String]? {
    get { self.storage["performers"] as? [String] }
    set { self.storage["performers"] = newValue }
  }

  public var phoneNumbers: [String]? {
    get { self.storage["phoneNumbers"] as? [String] }
    set { self.storage["phoneNumbers"] = newValue }
  }

  public var pixelCount: NSNumber? {
    get { self.storage["pixelCount"] as? NSNumber }
    set { self.storage["pixelCount"] = newValue }
  }

  public var pixelHeight: NSNumber? {
    get { self.storage["pixelHeight"] as? NSNumber }
    set { self.storage["pixelHeight"] = newValue }
  }

  public var pixelWidth: NSNumber? {
    get { self.storage["pixelWidth"] as? NSNumber }
    set { self.storage["pixelWidth"] = newValue }
  }

  public var playCount: NSNumber? {
    get { self.storage["playCount"] as? NSNumber }
    set { self.storage["playCount"] = newValue }
  }

  public var postalCode: String? {
    get { self.storage["postalCode"] as? String }
    set { self.storage["postalCode"] = newValue }
  }

  public var primaryRecipients: [CSPerson]? {
    get { self.storage["primaryRecipients"] as? [CSPerson] }
    set { self.storage["primaryRecipients"] = newValue }
  }

  public var producer: String? {
    get { self.storage["producer"] as? String }
    set { self.storage["producer"] = newValue }
  }

  public var profileName: String? {
    get { self.storage["profileName"] as? String }
    set { self.storage["profileName"] = newValue }
  }

  public var projects: [String]? {
    get { self.storage["projects"] as? [String] }
    set { self.storage["projects"] = newValue }
  }

  public var providerDataTypeIdentifiers: [String]? {
    get { self.storage["providerDataTypeIdentifiers"] as? [String] }
    set { self.storage["providerDataTypeIdentifiers"] = newValue }
  }

  public var providerFileTypeIdentifiers: [String]? {
    get { self.storage["providerFileTypeIdentifiers"] as? [String] }
    set { self.storage["providerFileTypeIdentifiers"] = newValue }
  }

  public var providerInPlaceFileTypeIdentifiers: [String]? {
    get { self.storage["providerInPlaceFileTypeIdentifiers"] as? [String] }
    set { self.storage["providerInPlaceFileTypeIdentifiers"] = newValue }
  }

  public var publishers: [String]? {
    get { self.storage["publishers"] as? [String] }
    set { self.storage["publishers"] = newValue }
  }

  public var rankingHint: NSNumber? {
    get { self.storage["rankingHint"] as? NSNumber }
    set { self.storage["rankingHint"] = newValue }
  }

  public var rating: NSNumber? {
    get { self.storage["rating"] as? NSNumber }
    set { self.storage["rating"] = newValue }
  }

  public var ratingDescription: String? {
    get { self.storage["ratingDescription"] as? String }
    set { self.storage["ratingDescription"] = newValue }
  }

  public var recipientAddresses: [String]? {
    get { self.storage["recipientAddresses"] as? [String] }
    set { self.storage["recipientAddresses"] = newValue }
  }

  public var recipientEmailAddresses: [String]? {
    get { self.storage["recipientEmailAddresses"] as? [String] }
    set { self.storage["recipientEmailAddresses"] = newValue }
  }

  public var recipientNames: [String]? {
    get { self.storage["recipientNames"] as? [String] }
    set { self.storage["recipientNames"] = newValue }
  }

  public var recordingDate: Date? {
    get { self.storage["recordingDate"] as? Date }
    set { self.storage["recordingDate"] = newValue }
  }

  public var redEyeOn: NSNumber? {
    get { self.storage["redEyeOn"] as? NSNumber }
    set { self.storage["redEyeOn"] = newValue }
  }

  public var relatedUniqueIdentifier: String? {
    get { self.storage["relatedUniqueIdentifier"] as? String }
    set { self.storage["relatedUniqueIdentifier"] = newValue }
  }

  public var resolutionHeightDPI: NSNumber? {
    get { self.storage["resolutionHeightDPI"] as? NSNumber }
    set { self.storage["resolutionHeightDPI"] = newValue }
  }

  public var resolutionWidthDPI: NSNumber? {
    get { self.storage["resolutionWidthDPI"] as? NSNumber }
    set { self.storage["resolutionWidthDPI"] = newValue }
  }

  public var rights: String? {
    get { self.storage["rights"] as? String }
    set { self.storage["rights"] = newValue }
  }

  public var role: String? {
    get { self.storage["role"] as? String }
    set { self.storage["role"] = newValue }
  }

  public var securityMethod: String? {
    get { self.storage["securityMethod"] as? String }
    set { self.storage["securityMethod"] = newValue }
  }

  public var sharedItemContentType: UTType? {
    get { self.storage["sharedItemContentType"] as? UTType }
    set { self.storage["sharedItemContentType"] = newValue }
  }

  public var speed: NSNumber? {
    get { self.storage["speed"] as? NSNumber }
    set { self.storage["speed"] = newValue }
  }

  public var startDate: Date? {
    get { self.storage["startDate"] as? Date }
    set { self.storage["startDate"] = newValue }
  }

  public var stateOrProvince: String? {
    get { self.storage["stateOrProvince"] as? String }
    set { self.storage["stateOrProvince"] = newValue }
  }

  public var streamable: NSNumber? {
    get { self.storage["streamable"] as? NSNumber }
    set { self.storage["streamable"] = newValue }
  }

  public var subThoroughfare: String? {
    get { self.storage["subThoroughfare"] as? String }
    set { self.storage["subThoroughfare"] = newValue }
  }

  public var subject: String? {
    get { self.storage["subject"] as? String }
    set { self.storage["subject"] = newValue }
  }

  public var supportsNavigation: NSNumber? {
    get { self.storage["supportsNavigation"] as? NSNumber }
    set { self.storage["supportsNavigation"] = newValue }
  }

  public var supportsPhoneCall: NSNumber? {
    get { self.storage["supportsPhoneCall"] as? NSNumber }
    set { self.storage["supportsPhoneCall"] = newValue }
  }

  public var tempo: NSNumber? {
    get { self.storage["tempo"] as? NSNumber }
    set { self.storage["tempo"] = newValue }
  }

  public var textContent: String? {
    get { self.storage["textContent"] as? String }
    set { self.storage["textContent"] = newValue }
  }

  public var textContentSummary: String? {
    self.storage["textContentSummary"] as? String
  }

  public var theme: String? {
    get { self.storage["theme"] as? String }
    set { self.storage["theme"] = newValue }
  }

  public var thoroughfare: String? {
    get { self.storage["thoroughfare"] as? String }
    set { self.storage["thoroughfare"] = newValue }
  }

  public var thumbnailData: Data? {
    get { self.storage["thumbnailData"] as? Data }
    set { self.storage["thumbnailData"] = newValue }
  }

  public var thumbnailURL: URL? {
    get { self.storage["thumbnailURL"] as? URL }
    set { self.storage["thumbnailURL"] = newValue }
  }

  public var timeSignature: String? {
    get { self.storage["timeSignature"] as? String }
    set { self.storage["timeSignature"] = newValue }
  }

  public var timestamp: Date? {
    get { self.storage["timestamp"] as? Date }
    set { self.storage["timestamp"] = newValue }
  }

  public var title: String? {
    get { self.storage["title"] as? String }
    set { self.storage["title"] = newValue }
  }

  public var totalBitRate: NSNumber? {
    get { self.storage["totalBitRate"] as? NSNumber }
    set { self.storage["totalBitRate"] = newValue }
  }

  public var transcribedTextContent: String? {
    get { self.storage["transcribedTextContent"] as? String }
    set { self.storage["transcribedTextContent"] = newValue }
  }

  public var userCreated: NSNumber? {
    get { self.storage["userCreated"] as? NSNumber }
    set { self.storage["userCreated"] = newValue }
  }

  public var userCurated: NSNumber? {
    get { self.storage["userCurated"] as? NSNumber }
    set { self.storage["userCurated"] = newValue }
  }

  public var userOwned: NSNumber? {
    get { self.storage["userOwned"] as? NSNumber }
    set { self.storage["userOwned"] = newValue }
  }

  public var version: String? {
    get { self.storage["version"] as? String }
    set { self.storage["version"] = newValue }
  }

  public var videoBitRate: NSNumber? {
    get { self.storage["videoBitRate"] as? NSNumber }
    set { self.storage["videoBitRate"] = newValue }
  }

  public var weakRelatedUniqueIdentifier: String? {
    get { self.storage["weakRelatedUniqueIdentifier"] as? String }
    set { self.storage["weakRelatedUniqueIdentifier"] = newValue }
  }

  public var whiteBalance: NSNumber? {
    get { self.storage["whiteBalance"] as? NSNumber }
    set { self.storage["whiteBalance"] = newValue }
  }

  public var fileExtension: String? {
    get { self.storage["fileExtension"] as? String }
    set { self.storage["fileExtension"] = newValue }
  }

  public var recipients: [CSPerson]? {
    get { self.storage["recipients"] as? [CSPerson] }
    set { self.storage["recipients"] = newValue }
  }

  public init(itemContentType: String) {
    self.itemContentType = itemContentType
    super.init()
    contentType = itemContentType
  }

  public convenience init(contentType: UTType) {
    self.init(itemContentType: contentType.identifier)
  }

  public required init?(coder: NSCoder) {
    guard
      let itemContentType = coder.decodeObject(of: NSString.self, forKey: "itemContentType")
        as String?
    else {
      return nil
    }
    self.itemContentType = itemContentType
    super.init()
    if let title = coder.decodeObject(of: NSString.self, forKey: "title") as String? {
      self.title = title
    }
    if let displayName = coder.decodeObject(of: NSString.self, forKey: "displayName") as String? {
      self.displayName = displayName
    }
    if let contentDescription = coder.decodeObject(of: NSString.self, forKey: "contentDescription")
      as String?
    {
      self.contentDescription = contentDescription
    }
    if let keywords = coder.decodeObject(of: [NSArray.self, NSString.self], forKey: "keywords")
      as? [String]
    {
      self.keywords = keywords
    }
    if let textContent = coder.decodeObject(of: NSString.self, forKey: "textContent") as String? {
      self.textContent = textContent
    }
    contentType = itemContentType
  }

  public func encode(with coder: NSCoder) {
    coder.encode(itemContentType as NSString, forKey: "itemContentType")
    coder.encode(title as NSString?, forKey: "title")
    coder.encode(displayName as NSString?, forKey: "displayName")
    coder.encode(contentDescription as NSString?, forKey: "contentDescription")
    coder.encode(keywords as NSArray?, forKey: "keywords")
    coder.encode(textContent as NSString?, forKey: "textContent")
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

  public func setValue(_ value: (any NSSecureCoding)?, forCustomKey key: CSCustomAttributeKey) {
    customValues[key.keyName] = value
  }

  public func value(forCustomKey key: CSCustomAttributeKey) -> (any NSSecureCoding)? {
    customValues[key.keyName] ?? nil
  }

  public func move(from sourceAttributeSet: CSSearchableItemAttributeSet) {
    storage = sourceAttributeSet.storage
    customValues = sourceAttributeSet.customValues
    _portableEntityPriority = sourceAttributeSet._portableEntityPriority
  }

  @_spi(OpenUIKitHost)
  public private(set) var _portableEntityPriority: Int?

  fileprivate func portableCopy() -> CSSearchableItemAttributeSet {
    let copy = CSSearchableItemAttributeSet(itemContentType: itemContentType)
    copy.storage = storage
    copy.customValues = customValues
    copy._portableEntityPriority = _portableEntityPriority
    return copy
  }
}

public final class CSSearchableItem: NSObject, NSSecureCoding, @unchecked Sendable {
  public struct UpdateListenerOptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
      self.rawValue = rawValue
    }

    public static let summarization = UpdateListenerOptions(rawValue: 1 << 1)
    public static let priority = UpdateListenerOptions(rawValue: 1 << 2)
  }

  public var uniqueIdentifier: String
  public var domainIdentifier: String?
  public var attributeSet: CSSearchableItemAttributeSet
  public var expirationDate: Date!
  public var isUpdate: Bool
  public var updateListenerOptions: UpdateListenerOptions

  public static var supportsSecureCoding: Bool { true }

  public init(
    uniqueIdentifier: String?,
    domainIdentifier: String?,
    attributeSet: CSSearchableItemAttributeSet
  ) {
    self.uniqueIdentifier = uniqueIdentifier ?? ""
    self.domainIdentifier = domainIdentifier
    self.attributeSet = attributeSet
    self.isUpdate = false
    self.updateListenerOptions = []
    super.init()
  }

  public required init?(coder: NSCoder) {
    guard
      let uniqueIdentifier = coder.decodeObject(of: NSString.self, forKey: "uniqueIdentifier")
        as String?,
      let attributeSet = coder.decodeObject(
        of: CSSearchableItemAttributeSet.self,
        forKey: "attributeSet"
      )
    else {
      return nil
    }
    self.uniqueIdentifier = uniqueIdentifier
    self.domainIdentifier = coder.decodeObject(of: NSString.self, forKey: "domainIdentifier") as String?
    self.attributeSet = attributeSet
    self.expirationDate = coder.decodeObject(of: NSDate.self, forKey: "expirationDate") as Date?
    self.isUpdate = coder.decodeBool(forKey: "isUpdate")
    self.updateListenerOptions = UpdateListenerOptions(
      rawValue: UInt(bitPattern: Int(coder.decodeInteger(forKey: "updateListenerOptions")))
    )
    super.init()
  }

  public func encode(with coder: NSCoder) {
    coder.encode(uniqueIdentifier as NSString, forKey: "uniqueIdentifier")
    coder.encode(domainIdentifier as NSString?, forKey: "domainIdentifier")
    coder.encode(attributeSet, forKey: "attributeSet")
    coder.encode(expirationDate as NSDate?, forKey: "expirationDate")
    coder.encode(isUpdate, forKey: "isUpdate")
    coder.encode(Int(updateListenerOptions.rawValue), forKey: "updateListenerOptions")
  }

  public func compare(byRank other: CSSearchableItem) -> ComparisonResult {
    let lhs = attributeSet.rankingHint?.doubleValue ?? 0
    let rhs = other.attributeSet.rankingHint?.doubleValue ?? 0
    if lhs > rhs { return .orderedAscending }
    if lhs < rhs { return .orderedDescending }
    if uniqueIdentifier < other.uniqueIdentifier { return .orderedAscending }
    if uniqueIdentifier > other.uniqueIdentifier { return .orderedDescending }
    return .orderedSame
  }

  fileprivate func portableCopy() -> CSSearchableItem {
    let copy = CSSearchableItem(
      uniqueIdentifier: uniqueIdentifier,
      domainIdentifier: domainIdentifier,
      attributeSet: attributeSet.portableCopy()
    )
    copy.expirationDate = expirationDate
    copy.isUpdate = isUpdate
    copy.updateListenerOptions = updateListenerOptions
    return copy
  }
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

public protocol CSSearchableIndexDelegate: NSObjectProtocol {
  func searchableIndex(
    _ searchableIndex: CSSearchableIndex,
    reindexAllSearchableItemsWithAcknowledgementHandler acknowledgementHandler: @escaping () -> Void
  )
  func searchableIndex(
    _ searchableIndex: CSSearchableIndex,
    reindexSearchableItemsWithIdentifiers identifiers: [String],
    acknowledgementHandler: @escaping () -> Void
  )
  func searchableIndexDidThrottle(_ searchableIndex: CSSearchableIndex)
  func searchableIndexDidFinishThrottle(_ searchableIndex: CSSearchableIndex)
  func data(
    for searchableIndex: CSSearchableIndex,
    itemIdentifier: String,
    typeIdentifier: String
  ) throws -> Data
  func fileURL(
    for searchableIndex: CSSearchableIndex,
    itemIdentifier: String,
    typeIdentifier: String,
    inPlace: Bool
  ) throws -> URL
  func searchableItemsDidUpdate(_ items: [CSSearchableItem])
  func searchableItems(
    forIdentifiers identifiers: [String],
    searchableItemsHandler: @escaping ([CSSearchableItem]) -> Void
  )
}

extension CSSearchableIndexDelegate {
  public func searchableIndexDidThrottle(_ searchableIndex: CSSearchableIndex) {
    _ = searchableIndex
  }

  public func searchableIndexDidFinishThrottle(_ searchableIndex: CSSearchableIndex) {
    _ = searchableIndex
  }

  public func data(
    for searchableIndex: CSSearchableIndex,
    itemIdentifier: String,
    typeIdentifier: String
  ) throws -> Data {
    _ = (searchableIndex, itemIdentifier, typeIdentifier)
    throw CSIndexError(.indexUnavailableError)
  }

  public func fileURL(
    for searchableIndex: CSSearchableIndex,
    itemIdentifier: String,
    typeIdentifier: String,
    inPlace: Bool
  ) throws -> URL {
    _ = (searchableIndex, itemIdentifier, typeIdentifier, inPlace)
    throw CSIndexError(.indexUnavailableError)
  }

  public func searchableItemsDidUpdate(_ items: [CSSearchableItem]) {
    _ = items
  }

  public func searchableItems(
    forIdentifiers identifiers: [String],
    searchableItemsHandler: @escaping ([CSSearchableItem]) -> Void
  ) {
    _ = identifiers
    searchableItemsHandler([])
  }
}

public final class CSSearchableIndex: NSObject, @unchecked Sendable {
  private nonisolated(unsafe) static var registryLock = NSLock()
  private nonisolated(unsafe) static var registry: [String: _CSIndexStorage] = [:]
  private static let defaultIndex = CSSearchableIndex(name: "default")

  public let name: String
  public let protectionClass: FileProtectionType?
  public weak var indexDelegate: (any CSSearchableIndexDelegate)?
  private let storage: _CSIndexStorage

  public static func `default`() -> CSSearchableIndex { defaultIndex }
  public static func isIndexingAvailable() -> Bool { true }

  public init(name: String) {
    self.name = name
    self.protectionClass = nil
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

  public init(name: String, protectionClass: FileProtectionType?) {
    self.name = name
    self.protectionClass = protectionClass
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
      guard !item.uniqueIdentifier.isEmpty else {
        throw CSIndexError(.invalidItemError)
      }
      return (item.uniqueIdentifier, item.portableCopy())
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

  public func beginBatch() {}

  public func beginIndexBatch() {
    beginBatch()
  }

  public func endBatch(withClientState clientState: Data) async throws {
    try await endIndexBatch(expectedClientState: nil, newClientState: clientState)
  }

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
    completionHandler?(matches ? nil : CSIndexError(.mismatchedClientState))
  }

  public func endIndexBatch(
    expectedClientState: Data?,
    newClientState: Data
  ) async throws {
    var captured: Swift.Error?
    endIndexBatch(
      expectedClientState: expectedClientState,
      newClientState: newClientState
    ) { error in
      captured = error
    }
    if let captured {
      throw captured
    }
  }

  public func fetchLastClientState(
    completionHandler: @escaping (Data?, Swift.Error?) -> Void
  ) {
    storage.lock.lock()
    let result = storage.clientState
    storage.lock.unlock()
    completionHandler(result, nil)
  }

  public func fetchData(
    forBundleIdentifier bundleIdentifier: String,
    itemIdentifier: String,
    contentType: UTType
  ) async throws -> Data {
    _ = (bundleIdentifier, itemIdentifier, contentType)
    throw CSIndexError(.indexUnavailableError)
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
      .sorted { $0.uniqueIdentifier < $1.uniqueIdentifier }
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

open class CSSearchQueryContext: NSObject, NSSecureCoding, @unchecked Sendable {
  public struct SourceOptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
      self.rawValue = rawValue
    }

    public static let allowMail = SourceOptions(rawValue: 1 << 0)
  }

  public var fetchAttributes: [String] = []
  public var filterQueries: [String] = []
  public var keyboardLanguage: String?
  public var sourceOptions: SourceOptions = []

  public static var supportsSecureCoding: Bool { true }

  public override init() {
    super.init()
  }

  public required init?(coder: NSCoder) {
    self.fetchAttributes =
      coder.decodeObject(of: [NSArray.self, NSString.self], forKey: "fetchAttributes") as? [String]
      ?? []
    self.filterQueries =
      coder.decodeObject(of: [NSArray.self, NSString.self], forKey: "filterQueries") as? [String]
      ?? []
    self.keyboardLanguage = coder.decodeObject(of: NSString.self, forKey: "keyboardLanguage") as String?
    self.sourceOptions = SourceOptions(
      rawValue: UInt(bitPattern: Int(coder.decodeInteger(forKey: "sourceOptions")))
    )
    super.init()
  }

  public func encode(with coder: NSCoder) {
    coder.encode(fetchAttributes as NSArray, forKey: "fetchAttributes")
    coder.encode(filterQueries as NSArray, forKey: "filterQueries")
    coder.encode(keyboardLanguage as NSString?, forKey: "keyboardLanguage")
    coder.encode(Int(sourceOptions.rawValue), forKey: "sourceOptions")
  }
}

open class CSSearchQuery: NSObject, @unchecked Sendable {
  public struct Results: AsyncSequence, Sendable {
    public typealias Element = Item
    public typealias AsyncIterator = Iterator

    public struct Item: Hashable, Comparable, Identifiable, Sendable {
      public typealias ID = String
      public let item: CSSearchableItem

      public init(item: CSSearchableItem) {
        self.item = item
      }

      public var id: String { item.uniqueIdentifier }

      public static func < (lhs: Item, rhs: Item) -> Bool {
        lhs.id < rhs.id
      }

      public static func == (lhs: Item, rhs: Item) -> Bool {
        lhs.id == rhs.id
      }

      public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
      }
    }

    public struct Iterator: AsyncIteratorProtocol {
      public typealias Element = Item
      fileprivate var remaining: [Item]

      public mutating func next() async throws -> Item? {
        guard !remaining.isEmpty else { return nil }
        return remaining.removeFirst()
      }
    }

    fileprivate var items: [Item]

    public func makeAsyncIterator() -> Iterator {
      Iterator(remaining: items)
    }
  }

  public let queryString: String
  public let queryContext: CSSearchQueryContext?
  public var protectionClasses: [FileProtectionType] = []
  public var foundItemsHandler: (([CSSearchableItem]) -> Void)?
  public var completionHandler: (((any Error)?) -> Void)?
  public private(set) var isCancelled = false
  public private(set) var foundItemCount = 0
  public private(set) var results = Results(items: [])

  private let attributes: [String]?
  private let searchIndex: CSSearchableIndex

  public convenience init(queryString: String, attributes: [String]?) {
    let context = CSSearchQueryContext()
    context.fetchAttributes = attributes ?? []
    self.init(queryString: queryString, queryContext: context)
  }

  public init(queryString: String, queryContext: CSSearchQueryContext?) {
    self.queryString = queryString
    self.queryContext = queryContext
    self.attributes = queryContext?.fetchAttributes
    self.searchIndex = CSSearchableIndex.default()
    super.init()
  }

  public func start() {
    if isCancelled {
      completionHandler?(CSSearchQueryError(.cancelled))
      return
    }
    let matches = searchIndex._searchPortable(queryString)
    foundItemCount = matches.count
    results = Results(items: matches.map { Results.Item(item: $0) })
    if !matches.isEmpty {
      foundItemsHandler?(matches)
    }
    completionHandler?(nil)
  }

  public func cancel() {
    isCancelled = true
  }
}

public final class CSSuggestion: NSObject, NSSecureCoding, @unchecked Sendable {
  public enum SuggestionKind: Int, Sendable, Hashable {
    case none = 0
    case custom = 1
    case `default` = 2
  }

  public let suggestionKind: SuggestionKind
  public let localizedAttributedSuggestion: AttributedString

  public static var supportsSecureCoding: Bool { true }

  @_spi(OpenUIKitHost)
  public init(kind: SuggestionKind, text: String) {
    self.suggestionKind = kind
    self.localizedAttributedSuggestion = AttributedString(text)
    super.init()
  }

  public required init?(coder: NSCoder) {
    let raw = coder.decodeInteger(forKey: "kind")
    guard let kind = SuggestionKind(rawValue: raw) else { return nil }
    let text = coder.decodeObject(of: NSString.self, forKey: "text") as String? ?? ""
    self.suggestionKind = kind
    self.localizedAttributedSuggestion = AttributedString(text)
    super.init()
  }

  public func encode(with coder: NSCoder) {
    coder.encode(suggestionKind.rawValue, forKey: "kind")
    coder.encode(String(localizedAttributedSuggestion.characters) as NSString, forKey: "text")
  }

  public func compare(_ other: CSSuggestion) -> ComparisonResult {
    let lhs = String(localizedAttributedSuggestion.characters)
    let rhs = String(other.localizedAttributedSuggestion.characters)
    if lhs < rhs { return .orderedAscending }
    if lhs > rhs { return .orderedDescending }
    return .orderedSame
  }

  public func compare(byRank other: CSSuggestion) -> ComparisonResult {
    compare(other)
  }
}

open class CSUserQueryContext: CSSearchQueryContext, @unchecked Sendable {
  public var disableSemanticSearch = false
  public var enableRankedResults = false
  public var maxRankedResultCount = 0
  public var maxResultCount = 0
  public var maxSuggestionCount = 0

  public init(currentSuggestion: CSSuggestion?) {
    super.init()
    _ = currentSuggestion
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    disableSemanticSearch = coder.decodeBool(forKey: "disableSemanticSearch")
    enableRankedResults = coder.decodeBool(forKey: "enableRankedResults")
    maxRankedResultCount = coder.decodeInteger(forKey: "maxRankedResultCount")
    maxResultCount = coder.decodeInteger(forKey: "maxResultCount")
    maxSuggestionCount = coder.decodeInteger(forKey: "maxSuggestionCount")
  }

  public override func encode(with coder: NSCoder) {
    super.encode(with: coder)
    coder.encode(disableSemanticSearch, forKey: "disableSemanticSearch")
    coder.encode(enableRankedResults, forKey: "enableRankedResults")
    coder.encode(maxRankedResultCount, forKey: "maxRankedResultCount")
    coder.encode(maxResultCount, forKey: "maxResultCount")
    coder.encode(maxSuggestionCount, forKey: "maxSuggestionCount")
  }
}

public final class CSUserQuery: CSSearchQuery, @unchecked Sendable {
  public enum UserInteractionKind: Int, Sendable, Hashable {
    case select = 0
    case focus = 1

    public static var `default`: UserInteractionKind { .select }
  }

  public struct Item: Hashable, Comparable, Identifiable, Sendable {
    public typealias ID = String
    public let item: CSSearchableItem

    public init(item: CSSearchableItem) {
      self.item = item
    }

    public var id: String { item.uniqueIdentifier }

    public static func < (lhs: Item, rhs: Item) -> Bool {
      lhs.id < rhs.id
    }

    public static func == (lhs: Item, rhs: Item) -> Bool {
      lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(id)
    }
  }

  public struct Suggestion: Hashable, Comparable, Identifiable, Sendable {
    public typealias ID = String
    public let suggestion: CSSuggestion

    public init(suggestion: CSSuggestion) {
      self.suggestion = suggestion
    }

    public var id: String {
      String(suggestion.localizedAttributedSuggestion.characters)
    }

    public static func < (lhs: Suggestion, rhs: Suggestion) -> Bool {
      lhs.id < rhs.id
    }

    public static func == (lhs: Suggestion, rhs: Suggestion) -> Bool {
      lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(id)
    }
  }

  public struct Suggestions: AsyncSequence, Sendable {
    public typealias Element = Suggestion
    public typealias AsyncIterator = Iterator

    public struct Iterator: AsyncIteratorProtocol {
      public typealias Element = Suggestion
      fileprivate var remaining: [Suggestion]

      public mutating func next() async throws -> Suggestion? {
        guard !remaining.isEmpty else { return nil }
        return remaining.removeFirst()
      }
    }

    fileprivate var items: [Suggestion] = []

    public func makeAsyncIterator() -> Iterator {
      Iterator(remaining: items)
    }
  }

  public enum Response: Hashable, Identifiable, Sendable {
    public typealias ID = String
    case item(Item)
    case suggestion(Suggestion)

    public var id: String {
      switch self {
      case .item(let item): return "item:" + item.id
      case .suggestion(let suggestion): return "suggestion:" + suggestion.id
      }
    }
  }

  public struct Responses: AsyncSequence, Sendable {
    public typealias Element = Response
    public typealias AsyncIterator = Iterator

    public struct Iterator: AsyncIteratorProtocol {
      public typealias Element = Response
      fileprivate var remaining: [Response]

      public mutating func next() async throws -> Response? {
        guard !remaining.isEmpty else { return nil }
        return remaining.removeFirst()
      }
    }

    fileprivate var items: [Response] = []

    public func makeAsyncIterator() -> Iterator {
      Iterator(remaining: items)
    }
  }

  public var foundSuggestionsHandler: (([CSSuggestion]) -> Void)?
  public private(set) var foundSuggestionCount = 0
  public private(set) var suggestions = Suggestions()
  public private(set) var responses = Responses()

  public init(userQueryString: String?, userQueryContext: CSUserQueryContext?) {
    super.init(queryString: userQueryString ?? "", queryContext: userQueryContext)
  }

  public static func prepare() {}

  public static func prepareProtectionClasses(_ protectionClasses: [FileProtectionType]) {
    _ = protectionClasses
  }

  public override func start() {
    foundSuggestionCount = 0
    suggestions = Suggestions()
    foundSuggestionsHandler?([])
    super.start()
    responses = Responses(
      items: results.items.map { Response.item(Item(item: $0.item)) }
    )
  }

  public func userEngaged(
    _ item: Item,
    visibleItems: [Item],
    interaction: UserInteractionKind
  ) {
    _ = (item, visibleItems, interaction)
  }

  public func userEngaged(
    _ suggestion: Suggestion,
    visibleSuggestions: [Suggestion],
    interaction: UserInteractionKind
  ) {
    _ = (suggestion, visibleSuggestions, interaction)
  }
}

public final class CSLocalizedString: NSObject, @unchecked Sendable {
  private let localizedStrings: [AnyHashable: Any]

  public init(localizedStrings: [AnyHashable: Any]) {
    self.localizedStrings = localizedStrings
    super.init()
  }

  public func localizedString() -> String {
    if let exact = localizedStrings[Locale.current.identifier] as? String {
      return exact
    }
    if let language = Locale.current.language.languageCode?.identifier,
      let match = localizedStrings[language] as? String
    {
      return match
    }
    if let first = localizedStrings.values.compactMap({ $0 as? String }).first {
      return first
    }
    return ""
  }
}

open class CSImportExtension: NSObject {
  public override init() {
    super.init()
  }

  open func update(
    _ attributes: CSSearchableItemAttributeSet,
    forFileAt contentURL: URL
  ) throws {
    _ = (attributes, contentURL)
    throw CSIndexError(.indexingUnsupported)
  }
}

open class CSIndexExtensionRequestHandler: NSObject, CSSearchableIndexDelegate {
  public override init() {
    super.init()
  }

  open func searchableIndex(
    _ searchableIndex: CSSearchableIndex,
    reindexAllSearchableItemsWithAcknowledgementHandler acknowledgementHandler: @escaping () -> Void
  ) {
    _ = searchableIndex
    acknowledgementHandler()
  }

  open func searchableIndex(
    _ searchableIndex: CSSearchableIndex,
    reindexSearchableItemsWithIdentifiers identifiers: [String],
    acknowledgementHandler: @escaping () -> Void
  ) {
    _ = (searchableIndex, identifiers)
    acknowledgementHandler()
  }
}
