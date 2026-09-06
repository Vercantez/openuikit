@_exported import Foundation
public final class RCSService {
public struct Configuration: Sendable {
    public let maximumGroupSize: Int?
    public let chatRevokeTimeout: Duration?
    public let maximumTextMessageSize: Measurement<UnitInformationStorage>?
    public let fileTransferWarningSize: Measurement<UnitInformationStorage>?
    public let maximumFileTransferSize: Measurement<UnitInformationStorage>?
    public init(maximumGroupSize: Int?, chatRevokeTimeout: Duration?, maximumTextMessageSize: Measurement<UnitInformationStorage>?, fileTransferWarningSize: Measurement<UnitInformationStorage>?, maximumFileTransferSize: Measurement<UnitInformationStorage>?) {
        self.maximumGroupSize = maximumGroupSize
        self.chatRevokeTimeout = chatRevokeTimeout
        self.maximumTextMessageSize = maximumTextMessageSize
        self.fileTransferWarningSize = fileTransferWarningSize
        self.maximumFileTransferSize = maximumFileTransferSize
    }
}

public enum GroupChatEvent: Sendable {
    case subjectUpdated(RCSService.GroupChatSubjectUpdatedEvent)
    case participantsAdded(RCSService.GroupChatParticipantsAddedEvent)
    case participantsRemoved(RCSService.GroupChatParticipantsRemovedEvent)
    case ended(RCSService.GroupChatEndedEvent)
    case started(RCSService.GroupChatStartedEvent)
}

public struct FileUploadRequest: Sendable {
public struct Metadata: Sendable {
    public let fileMetadata: RCSFileTransferMetadata
    public let thumbnailMetadata: RCSFileTransferMetadata?
    public let transactionID: UUID
    public init(fileMetadata: RCSFileTransferMetadata, thumbnailMetadata: RCSFileTransferMetadata?, transactionID: UUID) {
        self.fileMetadata = fileMetadata
        self.thumbnailMetadata = thumbnailMetadata
        self.transactionID = transactionID
    }
}

    public var contentType: UTType?
    public var thumbnailURL: URL?
    public var cellularServiceID: CellularServiceID
    public var thumbnailContentType: UTType?
    public var fileURL: URL
    public init(cellularServiceID: CellularServiceID, fileURL: URL, contentType: UTType? = nil, thumbnailURL: URL? = nil, thumbnailContentType: UTType? = nil) {
        self.cellularServiceID = cellularServiceID
        self.fileURL = fileURL
        self.contentType = contentType
        self.thumbnailURL = thumbnailURL
        self.thumbnailContentType = thumbnailContentType
    }
}

public struct ReportSpamRequest: Sendable {
public enum Category: Hashable, Codable, Sendable {
    case inappropriateContent
    case spam
    case fraud
    case other
    case invalid
}

    public var fileContent: Data?
    public var reason: String?
    public var message: RCSMessage
    public var category: RCSService.ReportSpamRequest.Category?
    public init(message: RCSMessage, fileContent: Data? = nil, category: RCSService.ReportSpamRequest.Category? = nil, reason: String? = nil) {
        self.message = message
        self.fileContent = fileContent
        self.category = category
        self.reason = reason
    }
}

public struct RemoteCapabilities: Equatable, Codable, Sendable {
public enum Availability: Hashable, Codable, Sendable {
    case unavailable
    case available
}

    public let validUntil: Date?
    public let availability: RCSService.RemoteCapabilities.Availability?
    public let supportsChat: Bool
    public let isBusinessHandle: Bool
    public let alternativeHandles: [RCSHandle]
    public let supportsGeolocation: Bool
    public let supportsFileTransfer: Bool
    public init(validUntil: Date?, availability: RCSService.RemoteCapabilities.Availability?, supportsChat: Bool, isBusinessHandle: Bool, alternativeHandles: [RCSHandle], supportsGeolocation: Bool, supportsFileTransfer: Bool) {
        self.validUntil = validUntil
        self.availability = availability
        self.supportsChat = supportsChat
        self.isBusinessHandle = isBusinessHandle
        self.alternativeHandles = alternativeHandles
        self.supportsGeolocation = supportsGeolocation
        self.supportsFileTransfer = supportsFileTransfer
    }
}

public struct RemoteHandleUpdate: Sendable {
    public let isBusinessHandle: Bool
    public let newHandle: RCSHandle?
    public let capabilities: RCSService.RemoteCapabilities?
    public let cellularServiceID: CellularServiceID
    public let handle: RCSHandle
    public init(isBusinessHandle: Bool, newHandle: RCSHandle?, capabilities: RCSService.RemoteCapabilities?, cellularServiceID: CellularServiceID, handle: RCSHandle) {
        self.isBusinessHandle = isBusinessHandle
        self.newHandle = newHandle
        self.capabilities = capabilities
        self.cellularServiceID = cellularServiceID
        self.handle = handle
    }
}

public struct SuggestionResponse: Sendable {
    public var suggestion: RCSService.Business.Suggestion
    public var destination: RCSHandle
    public var cellularServiceID: CellularServiceID
    public var originatingMessageID: RCSMessageID
    public var messageID: RCSMessageID
    public init(cellularServiceID: CellularServiceID, destination: RCSHandle, messageID: RCSMessageID, originatingMessageID: RCSMessageID, suggestion: RCSService.Business.Suggestion) {
        self.cellularServiceID = cellularServiceID
        self.destination = destination
        self.messageID = messageID
        self.originatingMessageID = originatingMessageID
        self.suggestion = suggestion
    }
}

public struct FileDownloadRequest: Sendable {
public struct Metadata: Sendable {
    public let suggestedFileName: String?
    public let contentType: UTType?
    public init(suggestedFileName: String?, contentType: UTType?) {
        self.suggestedFileName = suggestedFileName
        self.contentType = contentType
    }
}

    public var destinationFileURL: URL
    public var cellularServiceID: CellularServiceID
    public var fileURL: URL
    public init(cellularServiceID: CellularServiceID, fileURL: URL, destinationFileURL: URL) {
        self.cellularServiceID = cellularServiceID
        self.fileURL = fileURL
        self.destinationFileURL = destinationFileURL
    }
}

public struct GroupChatEndedEvent: Sendable {
    public let groupHandle: RCSHandle.Group
    public let cellularServiceID: CellularServiceID
    public let endedBy: RCSHandle.URI
    public init(groupHandle: RCSHandle.Group, cellularServiceID: CellularServiceID, endedBy: RCSHandle.URI) {
        self.groupHandle = groupHandle
        self.cellularServiceID = cellularServiceID
        self.endedBy = endedBy
    }
}

public struct RevokeMessageRequest: Sendable {
    public var cellularServiceID: CellularServiceID
    public var handle: RCSHandle
    public var messageID: RCSMessageID
    public init(cellularServiceID: CellularServiceID, handle: RCSHandle, messageID: RCSMessageID) {
        self.cellularServiceID = cellularServiceID
        self.handle = handle
        self.messageID = messageID
    }
}

public struct GroupChatStartedEvent: Sendable {
    public let groupHandle: RCSHandle.Group
    public let participants: [RCSHandle.URI]
    public let cellularServiceID: CellularServiceID
    public let creator: RCSHandle.URI
    public let subject: String
    public init(groupHandle: RCSHandle.Group, participants: [RCSHandle.URI], cellularServiceID: CellularServiceID, creator: RCSHandle.URI, subject: String) {
        self.groupHandle = groupHandle
        self.participants = participants
        self.cellularServiceID = cellularServiceID
        self.creator = creator
        self.subject = subject
    }
}

public struct LeaveGroupChatRequest: Sendable {
    public var groupHandle: RCSHandle.Group
    public var cellularServiceID: CellularServiceID
    public init(cellularServiceID: CellularServiceID, groupHandle: RCSHandle.Group) {
        self.cellularServiceID = cellularServiceID
        self.groupHandle = groupHandle
    }
}

public struct ViabilityNotification: Equatable, Sendable {
    public let cellularServiceID: CellularServiceID
    public let isViable: Bool
    public init(cellularServiceID: CellularServiceID, isViable: Bool) {
        self.cellularServiceID = cellularServiceID
        self.isViable = isViable
    }
}

public struct CreateGroupChatRequest: Sendable {
public struct Result: Sendable {
    public let groupHandle: RCSHandle.Group
    public let participants: [RCSHandle.URI]
    public let subject: String?
    public init(groupHandle: RCSHandle.Group, participants: [RCSHandle.URI], subject: String?) {
        self.groupHandle = groupHandle
        self.participants = participants
        self.subject = subject
    }
}

    public var participants: [RCSHandle.URI]
    public var cellularServiceID: CellularServiceID
    public var subject: String
    public init(cellularServiceID: CellularServiceID, participants: [RCSHandle.URI], subject: String) {
        self.cellularServiceID = cellularServiceID
        self.participants = participants
        self.subject = subject
    }
}

public struct RemoteCapabilitiesRequest: Sendable {
public enum CachePolicy: Hashable, Codable, CustomStringConvertible, Sendable {
    case cacheOrRemote
    case cacheOnly
    public var description: String {
        switch self {
        case .cacheOrRemote: return "cacheOrRemote"
        case .cacheOnly: return "cacheOnly"
        }
    }
}

    public var cachePolicy: RCSService.RemoteCapabilitiesRequest.CachePolicy
    public var cellularServiceID: CellularServiceID
    public var handle: RCSHandle
    public init(cellularServiceID: CellularServiceID, handle: RCSHandle, cachePolicy: RCSService.RemoteCapabilitiesRequest.CachePolicy = .cacheOnly) {
        self.cellularServiceID = cellularServiceID
        self.handle = handle
        self.cachePolicy = cachePolicy
    }
}

public struct BusinessInformationRequest: Sendable {
public enum CachePolicy: Hashable, Codable, Sendable {
    case remoteOnly
    case cacheOrRemote
    case cacheOnly
}

    public var cachePolicy: RCSService.BusinessInformationRequest.CachePolicy
    public var cellularServiceID: CellularServiceID
    public var handle: RCSHandle.URI
    public init(cellularServiceID: CellularServiceID, handle: RCSHandle.URI, cachePolicy: RCSService.BusinessInformationRequest.CachePolicy = .cacheOrRemote) {
        self.cellularServiceID = cellularServiceID
        self.handle = handle
        self.cachePolicy = cachePolicy
    }
}

public struct IncomingMessageNotification: Equatable, Sendable {
    public let suggestions: [RCSService.Business.Suggestion]
    public let groupContext: RCSGroupContext?
    public let message: RCSMessage
    public init(suggestions: [RCSService.Business.Suggestion], groupContext: RCSGroupContext?, message: RCSMessage) {
        self.suggestions = suggestions
        self.groupContext = groupContext
        self.message = message
    }
}

public struct GroupChatSubjectUpdatedEvent: Sendable {
    public let newSubject: String
    public let groupHandle: RCSHandle.Group
    public let cellularServiceID: CellularServiceID
    public let changedBy: RCSHandle.URI
    public init(newSubject: String, groupHandle: RCSHandle.Group, cellularServiceID: CellularServiceID, changedBy: RCSHandle.URI) {
        self.newSubject = newSubject
        self.groupHandle = groupHandle
        self.cellularServiceID = cellularServiceID
        self.changedBy = changedBy
    }
}

public struct ChangeGroupChatSubjectRequest: Sendable {
    public var newSubject: String
    public var groupHandle: RCSHandle.Group
    public var cellularServiceID: CellularServiceID
    public init(cellularServiceID: CellularServiceID, groupHandle: RCSHandle.Group, newSubject: String) {
        self.cellularServiceID = cellularServiceID
        self.groupHandle = groupHandle
        self.newSubject = newSubject
    }
}

public struct AddGroupChatParticipantsRequest: Sendable {
public struct Result: Sendable {
    public let added: [RCSHandle.URI]
    public init(added: [RCSHandle.URI]) {
        self.added = added
    }
}

    public var groupHandle: RCSHandle.Group
    public var participants: [RCSHandle.URI]
    public var cellularServiceID: CellularServiceID
    public init(cellularServiceID: CellularServiceID, groupHandle: RCSHandle.Group, participants: [RCSHandle.URI]) {
        self.cellularServiceID = cellularServiceID
        self.groupHandle = groupHandle
        self.participants = participants
    }
}

public struct GroupChatParticipantsAddedEvent: Sendable {
    public let addedParticipants: [RCSHandle.URI]
    public let groupHandle: RCSHandle.Group
    public let cellularServiceID: CellularServiceID
    public let addedBy: RCSHandle.URI
    public init(addedParticipants: [RCSHandle.URI], groupHandle: RCSHandle.Group, cellularServiceID: CellularServiceID, addedBy: RCSHandle.URI) {
        self.addedParticipants = addedParticipants
        self.groupHandle = groupHandle
        self.cellularServiceID = cellularServiceID
        self.addedBy = addedBy
    }
}

public struct GroupChatParticipantsRemovedEvent: Sendable {
    public let removedParticipants: [RCSHandle.URI]
    public let groupHandle: RCSHandle.Group
    public let cellularServiceID: CellularServiceID
    public let removedCurrentUser: Bool
    public let removedBy: RCSHandle.URI
    public init(removedParticipants: [RCSHandle.URI], groupHandle: RCSHandle.Group, cellularServiceID: CellularServiceID, removedCurrentUser: Bool, removedBy: RCSHandle.URI) {
        self.removedParticipants = removedParticipants
        self.groupHandle = groupHandle
        self.cellularServiceID = cellularServiceID
        self.removedCurrentUser = removedCurrentUser
        self.removedBy = removedBy
    }
}

public struct RemoveGroupChatParticipantsRequest: Sendable {
public struct Result: Sendable {
    public let removed: [RCSHandle.URI]
    public init(removed: [RCSHandle.URI]) {
        self.removed = removed
    }
}

    public var groupHandle: RCSHandle.Group
    public var participants: [RCSHandle.URI]
    public var cellularServiceID: CellularServiceID
    public init(cellularServiceID: CellularServiceID, groupHandle: RCSHandle.Group, participants: [RCSHandle.URI]) {
        self.cellularServiceID = cellularServiceID
        self.groupHandle = groupHandle
        self.participants = participants
    }
}

public enum Error: Hashable, Codable, Swift.Error, LocalizedError, Sendable {
    case internalError
    case permanentError
    case temporaryError
    case notSupported
    case decodingFailed
    case invalidArgument
    case serviceUnavailable
    case maximumSizeExceeded
    case unknown
    case notFound
    public var errorDescription: String? {
        "Linux has no telephony messaging daemon (\(String(describing: self)))."
    }
    public var failureReason: String? { errorDescription }
    public var recoverySuggestion: String? {
        "Use a Darwin device with carrier messaging entitlements."
    }
    public var helpAnchor: String? { nil }
}

public struct Business: Codable, Sendable {
public struct MediaEntry: Equatable, Codable, Sendable {
public enum ContentType: Hashable, Codable, Sendable {
    case logo
    case other
}

public enum Label: Hashable, Codable, Sendable {
    case icon
}

    public let contentType: RCSService.Business.MediaEntry.ContentType
    public let label: RCSService.Business.MediaEntry.Label
    public let media: RCSService.Business.Media
    public init(contentType: RCSService.Business.MediaEntry.ContentType, label: RCSService.Business.MediaEntry.Label, media: RCSService.Business.Media) {
        self.contentType = contentType
        self.label = label
        self.media = media
    }
}

public enum Suggestion: Equatable, Codable, Sendable {
    case reply(RCSService.Business.SuggestedReply)
    case action(RCSService.Business.SuggestedAction)
}

public struct AddressEntry: Equatable, Codable, Sendable {
    public let label: String
    public let address: String
    public init(label: String, address: String) {
        self.label = label
        self.address = address
    }
}

public struct CardCarousel: Equatable, Codable, Sendable {
    public let styleSheetURL: URL?
    public let titleFontStyle: RCSService.Business.Card.FontStyle
    public let descriptionFontStyle: RCSService.Business.Card.FontStyle
    public let width: RCSService.Business.Card.Width
    public let contents: [RCSService.Business.Card.Content]
    public init(styleSheetURL: URL?, titleFontStyle: RCSService.Business.Card.FontStyle, descriptionFontStyle: RCSService.Business.Card.FontStyle, width: RCSService.Business.Card.Width, contents: [RCSService.Business.Card.Content]) {
        self.styleSheetURL = styleSheetURL
        self.titleFontStyle = titleFontStyle
        self.descriptionFontStyle = descriptionFontStyle
        self.width = width
        self.contents = contents
    }
}

public struct OpenURLAction: Equatable, Codable, Sendable {
public enum Detent: Hashable, Codable, Sendable {
    case mediumLarge
    case large
    case medium
}

public enum Target: Equatable, Codable, Sendable {
    case defaultBrowser
    case inApp(detent: RCSService.Business.OpenURLAction.Detent)
}

    public let url: URL
    public let target: RCSService.Business.OpenURLAction.Target
    public init(url: URL, target: RCSService.Business.OpenURLAction.Target) {
        self.url = url
        self.target = target
    }
}

public struct SuggestedReply: Equatable, Codable, Sendable {
    public let displayText: String
    public init(displayText: String) {
        self.displayText = displayText
    }
}

public struct SuggestedAction: Equatable, Codable, Sendable {
public enum Action: Equatable, Codable, Sendable {
    case composeText(RCSService.Business.ComposeTextAction)
    case sendLocation
    case showLocation(RCSService.Business.ShowLocationAction)
    case dialPhoneNumber(RCSService.Business.DialPhoneNumberAction)
    case composeRecording(RCSService.Business.ComposeRecordingAction)
    case createCalendarEvent(RCSService.Business.CreateCalendarEventAction)
    case sendDeviceSpecifics
    case enableDisplayedNotifications
    case openURL(RCSService.Business.OpenURLAction)
}

    public let displayText: String
    public let action: RCSService.Business.SuggestedAction.Action
    public init(displayText: String, action: RCSService.Business.SuggestedAction.Action) {
        self.displayText = displayText
        self.action = action
    }
}

public struct OrganizationName: Equatable, Codable, Sendable {
public enum NameType: Hashable, Codable, Sendable {
    case officialName
}

    public let displayName: String
    public let nameType: RCSService.Business.OrganizationName.NameType
    public init(displayName: String, nameType: RCSService.Business.OrganizationName.NameType) {
        self.displayName = displayName
        self.nameType = nameType
    }
}

public struct TelephoneDetails: Equatable, Codable, Sendable {
    public let phoneNumber: String
    public let phoneNumberType: String
    public let label: String
    public init(phoneNumber: String, phoneNumberType: String, label: String) {
        self.phoneNumber = phoneNumber
        self.phoneNumberType = phoneNumberType
        self.label = label
    }
}

public struct ComposeTextAction: Equatable, Codable, Sendable {
    public let phoneNumber: String
    public let text: String
    public init(phoneNumber: String, text: String) {
        self.phoneNumber = phoneNumber
        self.text = text
    }
}

public struct ShowLocationAction: Equatable, Codable, Sendable {
public enum Method: Equatable, Codable, Sendable {
    case coordinates(CLLocationCoordinate2D)
    case query(String)
}

    public let fallbackURL: URL?
    public let label: String?
    public let method: RCSService.Business.ShowLocationAction.Method
    public init(fallbackURL: URL?, label: String?, method: RCSService.Business.ShowLocationAction.Method) {
        self.fallbackURL = fallbackURL
        self.label = label
        self.method = method
    }
}

public struct VerificationDetails: Equatable, Codable, Sendable {
    public let isVerified: Bool
    public let verifiedBy: String?
    public let expirationDate: Date?
    public init(isVerified: Bool, verifiedBy: String?, expirationDate: Date?) {
        self.isVerified = isVerified
        self.verifiedBy = verifiedBy
        self.expirationDate = expirationDate
    }
}

public struct CommunicationAddress: Equatable, Codable, Sendable {
    public let uriEntries: [RCSService.Business.URIEntry]
    public let telephoneDetails: RCSService.Business.TelephoneDetails
    public init(uriEntries: [RCSService.Business.URIEntry], telephoneDetails: RCSService.Business.TelephoneDetails) {
        self.uriEntries = uriEntries
        self.telephoneDetails = telephoneDetails
    }
}

public struct DialPhoneNumberAction: Equatable, Codable, Sendable {
    public let phoneNumber: String
    public let fallbackURL: URL?
    public init(phoneNumber: String, fallbackURL: URL?) {
        self.phoneNumber = phoneNumber
        self.fallbackURL = fallbackURL
    }
}

public struct ComposeRecordingAction: Equatable, Codable, Sendable {
public enum MediaType: Hashable, Codable, Sendable {
    case audio
    case video
}

    public let phoneNumber: String
    public let mediaType: RCSService.Business.ComposeRecordingAction.MediaType
    public init(phoneNumber: String, mediaType: RCSService.Business.ComposeRecordingAction.MediaType) {
        self.phoneNumber = phoneNumber
        self.mediaType = mediaType
    }
}

public struct CreateCalendarEventAction: Equatable, Codable, Sendable {
    public let description: String?
    public let fallbackURL: URL?
    public let title: String
    public let endTime: Date
    public let startTime: Date
    public init(description: String?, fallbackURL: URL?, title: String, endTime: Date, startTime: Date) {
        self.description = description
        self.fallbackURL = fallbackURL
        self.title = title
        self.endTime = endTime
        self.startTime = startTime
    }
}

public struct Card: Equatable, Codable, Sendable {
public enum Orientation: Hashable, Codable, Sendable {
    case horizontal
    case vertical
}

public enum ImageAlignment: Hashable, Codable, Sendable {
    case left
    case right
}

public struct Media: Equatable, Codable, Sendable {
public enum Height: Hashable, Codable, Sendable {
    case tall
    case short
    case medium
}

    public let contentType: UTType?
    public let description: String?
    public let thumbnailURL: URL?
    public let displayHeight: RCSService.Business.Card.Media.Height
    public let thumbnailFileSize: Measurement<UnitInformationStorage>?
    public let thumbnailContentType: UTType?
    public let url: URL
    public let fileSize: Measurement<UnitInformationStorage>
    public init(contentType: UTType?, description: String?, thumbnailURL: URL?, displayHeight: RCSService.Business.Card.Media.Height, thumbnailFileSize: Measurement<UnitInformationStorage>?, thumbnailContentType: UTType?, url: URL, fileSize: Measurement<UnitInformationStorage>) {
        self.contentType = contentType
        self.description = description
        self.thumbnailURL = thumbnailURL
        self.displayHeight = displayHeight
        self.thumbnailFileSize = thumbnailFileSize
        self.thumbnailContentType = thumbnailContentType
        self.url = url
        self.fileSize = fileSize
    }
}

public enum Width: Hashable, Codable, Sendable {
    case small
    case medium
}

public struct Content: Equatable, Codable, Sendable {
    public let description: String?
    public let suggestions: [RCSService.Business.Suggestion]
    public let media: RCSService.Business.Card.Media?
    public let title: String?
    public init(description: String?, suggestions: [RCSService.Business.Suggestion], media: RCSService.Business.Card.Media?, title: String?) {
        self.description = description
        self.suggestions = suggestions
        self.media = media
        self.title = title
    }
}

public struct FontStyle: OptionSet, Hashable, Codable, Sendable {
    public typealias RawValue = Int
    public typealias Element = FontStyle
    public typealias ArrayLiteralElement = FontStyle
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let bold = FontStyle(rawValue: 1 << 0)
    public static let italics = FontStyle(rawValue: 1 << 1)
    public static let underline = FontStyle(rawValue: 1 << 2)
}

    public let orientation: RCSService.Business.Card.Orientation
    public let styleSheetURL: URL?
    public let imageAlignment: RCSService.Business.Card.ImageAlignment?
    public let titleFontStyle: RCSService.Business.Card.FontStyle
    public let descriptionFontStyle: RCSService.Business.Card.FontStyle
    public let content: RCSService.Business.Card.Content
    public init(orientation: RCSService.Business.Card.Orientation, styleSheetURL: URL?, imageAlignment: RCSService.Business.Card.ImageAlignment?, titleFontStyle: RCSService.Business.Card.FontStyle, descriptionFontStyle: RCSService.Business.Card.FontStyle, content: RCSService.Business.Card.Content) {
        self.orientation = orientation
        self.styleSheetURL = styleSheetURL
        self.imageAlignment = imageAlignment
        self.titleFontStyle = titleFontStyle
        self.descriptionFontStyle = descriptionFontStyle
        self.content = content
    }
}

public struct Menu: Equatable, Codable, Sendable {
public enum Content: Equatable, Codable, Sendable {
    case suggestion(RCSService.Business.Suggestion)
    indirect case submenu(RCSService.Business.Menu)
}

    public let title: String?
    public let contents: [RCSService.Business.Menu.Content]
    public init(title: String?, contents: [RCSService.Business.Menu.Content]) {
        self.title = title
        self.contents = contents
    }
}

public struct Media: Equatable, Codable, Sendable {
    public let sha256Digest: String?
    public let url: URL
    public init(sha256Digest: String?, url: URL) {
        self.sha256Digest = sha256Digest
        self.url = url
    }
}

public struct URIEntry: Equatable, Codable, Sendable {
public enum Label: Hashable, Codable, Sendable {
    case sms
    case serviceID
}

public enum URIType: Hashable, Codable, Sendable {
    case sip
    case other
}

    public let uri: URL
    public let type: RCSService.Business.URIEntry.URIType
    public let label: RCSService.Business.URIEntry.Label
    public init(uri: URL, type: RCSService.Business.URIEntry.URIType, label: RCSService.Business.URIEntry.Label) {
        self.uri = uri
        self.type = type
        self.label = label
    }
}

    public let websiteURL: URL?
    public let description: String?
    public let emailAddress: String?
    public let mediaEntries: [RCSService.Business.MediaEntry]
    public let providerName: String?
    public let categoryNames: [String]
    public let addressEntries: [RCSService.Business.AddressEntry]
    public let persistentMenu: RCSService.Business.Menu?
    public let organizationNames: [RCSService.Business.OrganizationName]
    public let backgroundImageURL: URL?
    public let verificationDetails: RCSService.Business.VerificationDetails?
    public let communicationAddress: RCSService.Business.CommunicationAddress?
    public let styleSheetTemplateURL: URL?
    public let termsAndConditionsURL: URL?
    public let version: String?
    public init(websiteURL: URL?, description: String?, emailAddress: String?, mediaEntries: [RCSService.Business.MediaEntry], providerName: String?, categoryNames: [String], addressEntries: [RCSService.Business.AddressEntry], persistentMenu: RCSService.Business.Menu?, organizationNames: [RCSService.Business.OrganizationName], backgroundImageURL: URL?, verificationDetails: RCSService.Business.VerificationDetails?, communicationAddress: RCSService.Business.CommunicationAddress?, styleSheetTemplateURL: URL?, termsAndConditionsURL: URL?, version: String?) {
        self.websiteURL = websiteURL
        self.description = description
        self.emailAddress = emailAddress
        self.mediaEntries = mediaEntries
        self.providerName = providerName
        self.categoryNames = categoryNames
        self.addressEntries = addressEntries
        self.persistentMenu = persistentMenu
        self.organizationNames = organizationNames
        self.backgroundImageURL = backgroundImageURL
        self.verificationDetails = verificationDetails
        self.communicationAddress = communicationAddress
        self.styleSheetTemplateURL = styleSheetTemplateURL
        self.termsAndConditionsURL = termsAndConditionsURL
        self.version = version
    }
    public var themeColor: CGColor? { nil }
}

    public func reportSpam(_ request: RCSService.ReportSpamRequest) async throws {
        throw Error.serviceUnavailable
    }
    public func sendMessage(_ content: RCSMessage.DispositionNotification, to destination: RCSHandle.URI, using cellularServiceID: CellularServiceID, messageID: RCSMessageID, group: RCSHandle.Group? = nil) async throws {
        throw Error.serviceUnavailable
    }
    public func sendMessage(_ content: RCSMessage.FileTransfer, to destination: RCSHandle, using cellularServiceID: CellularServiceID, messageID: RCSMessageID) async throws {
        throw Error.serviceUnavailable
    }
    public func sendMessage(_ content: RCSMessage.GeolocationPush, to destination: RCSHandle, using cellularServiceID: CellularServiceID, messageID: RCSMessageID) async throws {
        throw Error.serviceUnavailable
    }
    public func sendMessage(_ content: RCSMessage.ComposingIndicator, to destination: RCSHandle, using cellularServiceID: CellularServiceID, messageID: RCSMessageID) async throws {
        throw Error.serviceUnavailable
    }
    public func sendMessage(_ content: RCSMessage.Text, to destination: RCSHandle, using cellularServiceID: CellularServiceID, messageID: RCSMessageID) async throws {
        throw Error.serviceUnavailable
    }
    public func configuration(for cellularServiceID: CellularServiceID) throws -> RCSService.Configuration {
        throw Error.serviceUnavailable
    }
    public func revokeMessage(_ request: RCSService.RevokeMessageRequest) async throws -> Bool {
        throw Error.serviceUnavailable
    }
    public func leaveGroupChat(_ request: RCSService.LeaveGroupChatRequest) async throws {
        throw Error.serviceUnavailable
    }
    public func createGroupChat(_ request: RCSService.CreateGroupChatRequest) async throws -> RCSService.CreateGroupChatRequest.Result {
        throw Error.serviceUnavailable
    }
    public var groupChatEvents: TelephonyMessagingEmptyAsyncSequence<RCSService.GroupChatEvent> {
        get throws {
            throw Error.serviceUnavailable
        }
    }
    public func remoteCapabilities(for request: RCSService.RemoteCapabilitiesRequest) async throws -> RCSService.RemoteCapabilities? {
        throw Error.serviceUnavailable
    }
    public func businessInformation(for request: RCSService.BusinessInformationRequest) async throws -> RCSService.Business? {
        throw Error.serviceUnavailable
    }
    public var remoteHandleUpdates: TelephonyMessagingEmptyAsyncSequence<RCSService.RemoteHandleUpdate> {
        get throws {
            throw Error.serviceUnavailable
        }
    }
    public func sendDeviceSpecifics(to destination: RCSHandle.URI, using cellularServiceID: CellularServiceID, messageID: RCSMessageID) async throws {
        throw Error.serviceUnavailable
    }
    public func changeGroupChatSubject(_ request: RCSService.ChangeGroupChatSubjectRequest) async throws {
        throw Error.serviceUnavailable
    }
    public func sendSuggestionResponse(_ response: RCSService.SuggestionResponse) async throws {
        throw Error.serviceUnavailable
    }
    public var viabilityNotifications: TelephonyMessagingEmptyAsyncSequence<RCSService.ViabilityNotification> {
        get throws {
            throw Error.serviceUnavailable
        }
    }
    public func addGroupChatParticipants(_ request: RCSService.AddGroupChatParticipantsRequest) async throws -> RCSService.AddGroupChatParticipantsRequest.Result {
        throw Error.serviceUnavailable
    }
    public func removeGroupChatParticipants(_ request: RCSService.RemoveGroupChatParticipantsRequest) async throws -> RCSService.RemoveGroupChatParticipantsRequest.Result {
        throw Error.serviceUnavailable
    }
    public var incomingMessageNotifications: TelephonyMessagingEmptyAsyncSequence<RCSService.IncomingMessageNotification> {
        get throws {
            throw Error.serviceUnavailable
        }
    }
    public func upload(_ uploadRequest: RCSService.FileUploadRequest) async throws -> RCSService.FileUploadRequest.Metadata {
        throw Error.serviceUnavailable
    }
    public func download(_ downloadRequest: RCSService.FileDownloadRequest) async throws -> RCSService.FileDownloadRequest.Metadata {
        throw Error.serviceUnavailable
    }
    public func isViable(for cellularServiceID: CellularServiceID) -> Bool {
        false
    }
    init() {}
}
