@_exported import Foundation
public struct RCSMessage: Equatable, Codable, Identifiable, Sendable {
    public typealias ID = RCSMessageID
public enum Disposition: Hashable, Codable, Sendable {
    case deliveryFailed
    case interworkingFailed
    case interworkingDelivered
    case delivered
    case displayed
}

public struct FileTransfer: Equatable, Codable, Sendable {
    public var fileMetadata: RCSFileTransferMetadata
    public var thumbnailMetadata: RCSFileTransferMetadata?
    public init(fileMetadata: RCSFileTransferMetadata, thumbnailMetadata: RCSFileTransferMetadata? = nil) {
        self.fileMetadata = fileMetadata
        self.thumbnailMetadata = thumbnailMetadata
    }
}

public struct GeolocationPush: Equatable, Codable, Sendable {
    public var description: String?
    public var latitude: Double
    public var longitude: Double
    public init(latitude: Double, longitude: Double, description: String? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.description = description
    }
}

public struct ComposingIndicator: Equatable, Codable, Sendable {
public enum State: Hashable, Codable, Sendable {
    case idle
    case active
}

    public var lastActive: Date?
    public var contentType: UTType?
    public var refreshInterval: Duration?
    public var state: RCSMessage.ComposingIndicator.State
    public init(state: RCSMessage.ComposingIndicator.State, lastActive: Date? = nil, contentType: UTType? = nil, refreshInterval: Duration? = nil) {
        self.state = state
        self.lastActive = lastActive
        self.contentType = contentType
        self.refreshInterval = refreshInterval
    }
}

public struct DispositionNotification: Equatable, Codable, Sendable {
    public let disposition: RCSMessage.Disposition
    public let disposedMessageID: RCSMessageID
    public init(disposition: RCSMessage.Disposition, disposedMessageID: RCSMessageID) {
        self.disposition = disposition
        self.disposedMessageID = disposedMessageID
    }
}

public struct Text: Equatable, Codable, ExpressibleByStringLiteral, Sendable {
    public typealias StringLiteralType = String
    public typealias UnicodeScalarLiteralType = String
    public typealias ExtendedGraphemeClusterLiteralType = String
    public var body: String
    public init(body: String) {
        self.body = body
    }

    public init(stringLiteral value: String) {
        self.body = value
    }
}

public enum Content: Equatable, Codable, Sendable {
    case businessCard(RCSService.Business.Card)
    case fileTransfer(RCSMessage.FileTransfer)
    case geolocationPush(RCSMessage.GeolocationPush)
    case composingIndicator(RCSMessage.ComposingIndicator)
    case businessCardCarousel(RCSService.Business.CardCarousel)
    case dispositionNotification(RCSMessage.DispositionNotification)
    case text(RCSMessage.Text)
}

    public let cellularServiceID: CellularServiceID
    public let id: RCSMessageID
    public let handle: RCSHandle
    public let content: RCSMessage.Content
    public init(cellularServiceID: CellularServiceID, id: RCSMessageID, handle: RCSHandle, content: RCSMessage.Content) {
        self.cellularServiceID = cellularServiceID
        self.id = id
        self.handle = handle
        self.content = content
    }
}

public struct RCSMessageID: RawRepresentable, Hashable, Codable, CustomStringConvertible, Sendable {
    public typealias RawValue = String
    public let rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    public var description: String { rawValue }
}

public struct RCSGroupContext: Equatable, Codable, Sendable {
    public let handle: RCSHandle.Group
    public init(handle: RCSHandle.Group) {
        self.handle = handle
    }
}

public struct RCSFileTransferMetadata: Equatable, Codable, Sendable {
public enum Disposition: Hashable, Codable, Sendable {
    case attachment
    case render
}

    public let contentType: UTType?
    public var disposition: RCSFileTransferMetadata.Disposition?
    public let expirationDate: Date
    public var playbackLength: Duration?
    public let url: URL
    public let fileName: String?
    public let fileSize: Int
    public init(contentType: UTType?, disposition: RCSFileTransferMetadata.Disposition?, expirationDate: Date, playbackLength: Duration?, url: URL, fileName: String?, fileSize: Int) {
        self.contentType = contentType
        self.disposition = disposition
        self.expirationDate = expirationDate
        self.playbackLength = playbackLength
        self.url = url
        self.fileName = fileName
        self.fileSize = fileSize
    }
}

public enum RCSHandle: Hashable, Codable, CustomStringConvertible, Sendable {
public struct URI: RawRepresentable, Hashable, Codable, ExpressibleByStringLiteral, Sendable {
    public typealias StringLiteralType = String
    public typealias UnicodeScalarLiteralType = String
    public typealias ExtendedGraphemeClusterLiteralType = String
    public typealias RawValue = String
    public let rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }
}

public struct Group: Hashable, Codable, Sendable {
    public let conversationID: String
    public let focus: String
    public init(conversationID: String, focus: String) {
        self.conversationID = conversationID
        self.focus = focus
    }
}

    case uri(RCSHandle.URI)
    case group(RCSHandle.Group)
    public var description: String {
        switch self {
        case .uri(let uri): return uri.rawValue
        case .group(let group): return group.conversationID
        }
    }
    public static func phoneNumber(_ phoneNumber: String) -> RCSHandle? {
        let trimmed = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        return .uri(URI(rawValue: trimmed))
    }
}
