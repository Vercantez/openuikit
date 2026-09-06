@_exported import Foundation
public struct MMSContent: Equatable, Codable, Sendable {
    public var recipients: [MMSHandle]
    public var from: MMSHandle?
    public var parts: [MMSPartContent]
    public var headers: [String : String]
    public var subject: String?
    public init(parts: [MMSPartContent], recipients: [MMSHandle], subject: String? = nil) {
        self.parts = parts
        self.recipients = recipients
        self.subject = subject
        self.from = nil
        self.headers = [:]
    }
    public init() {
        self.parts = []
        self.recipients = []
        self.subject = nil
        self.from = nil
        self.headers = [:]
    }
}

public struct MMSMessage: Equatable, Codable, CustomStringConvertible, Sendable {
    public var cellularServiceID: CellularServiceID
    public var content: MMSContent
    public var messageID: MMSMessageID
    public init(cellularServiceID: CellularServiceID, messageID: MMSMessageID, content: MMSContent) {
        self.cellularServiceID = cellularServiceID
        self.messageID = messageID
        self.content = content
    }
    public var totalSize: Measurement<UnitInformationStorage> {
        let bytes = content.parts.reduce(0) { $0 + $1.data.count }
        return Measurement(value: Double(bytes), unit: UnitInformationStorage.bytes)
    }
    public var description: String { messageID.description }
}

public final class MMSService {
public struct Configuration: Codable, Sendable {
    public var maximumImageSize: Measurement<UnitInformationStorage>?
    public var maximumRecipients: Int?
    public var maximumMessageSize: Measurement<UnitInformationStorage>?
    public var maximumSubjectSize: Measurement<UnitInformationStorage>?
    public var smsSizeToBeSentAsMMSInstead: Measurement<UnitInformationStorage>?
    public init(maximumImageSize: Measurement<UnitInformationStorage>?, maximumRecipients: Int?, maximumMessageSize: Measurement<UnitInformationStorage>?, maximumSubjectSize: Measurement<UnitInformationStorage>?, smsSizeToBeSentAsMMSInstead: Measurement<UnitInformationStorage>?) {
        self.maximumImageSize = maximumImageSize
        self.maximumRecipients = maximumRecipients
        self.maximumMessageSize = maximumMessageSize
        self.maximumSubjectSize = maximumSubjectSize
        self.smsSizeToBeSentAsMMSInstead = smsSizeToBeSentAsMMSInstead
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

public struct IncomingMessageNotification: Equatable, Sendable {
    public let cellularServiceID: CellularServiceID
    public let message: MMSMessage
    public let messageID: MMSMessageID
    public init(cellularServiceID: CellularServiceID, message: MMSMessage, messageID: MMSMessageID) {
        self.cellularServiceID = cellularServiceID
        self.message = message
        self.messageID = messageID
    }
}

public enum Error: Hashable, Codable, Swift.Error, LocalizedError, Sendable {
    case internalError
    case mmsNotReady
    case notSupported
    case invalidRecipient
    case invalidMessageParts
    case maximumSizeExceeded
    case mmsNotConfiguredForCarrier
    case unknown
    public var errorDescription: String? {
        "Linux has no telephony messaging daemon (\(String(describing: self)))."
    }
    public var failureReason: String? { errorDescription }
    public var recoverySuggestion: String? {
        "Use a Darwin device with carrier messaging entitlements."
    }
    public var helpAnchor: String? { nil }
}

    public func reportSpam(_ message: MMSMessage) async throws {
        throw Error.mmsNotConfiguredForCarrier
    }
    public func sendMessage(_ message: MMSMessage) async throws {
        throw Error.mmsNotConfiguredForCarrier
    }
    public func configuration(for cellularServiceID: CellularServiceID) async throws -> MMSService.Configuration {
        throw Error.mmsNotConfiguredForCarrier
    }
    public func receiveMessage(using cellularServiceID: CellularServiceID, messageID: MMSMessageID) async throws -> MMSMessage {
        throw Error.mmsNotConfiguredForCarrier
    }
    public var viabilityNotifications: TelephonyMessagingEmptyAsyncSequence<MMSService.ViabilityNotification> {
        get throws {
            throw Error.mmsNotConfiguredForCarrier
        }
    }
    public var incomingMessageNotifications: TelephonyMessagingEmptyAsyncSequence<MMSService.IncomingMessageNotification> {
        get throws {
            throw Error.mmsNotConfiguredForCarrier
        }
    }
    public func isViable(for cellularServiceID: CellularServiceID) -> Bool {
        false
    }
    init() {}
}

public struct MMSMessageID: RawRepresentable, Hashable, Codable, CustomStringConvertible, Sendable {
    public typealias RawValue = UInt32
    public let rawValue: UInt32
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
    public var description: String { String(rawValue) }
}

public struct MMSPartContent: Equatable, Codable, Sendable {
public struct MMSCustomHeader: Equatable, Codable, Sendable {
    public let key: String
    public let value: String
    public init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}

public enum MMSDispositionType: Hashable, Codable, Sendable {
    case attachment
    case inline
}

    public var contentType: UTType?
    public var disposition: MMSPartContent.MMSDispositionType
    public var customHeaders: [MMSPartContent.MMSCustomHeader]
    public var data: Data
    public var filename: String
    public var contentID: String
    public init(data: Data, contentType: UTType?, contentID: String, disposition: MMSPartContent.MMSDispositionType, fileName: String) {
        self.data = data
        self.contentType = contentType
        self.contentID = contentID
        self.disposition = disposition
        self.filename = fileName
        self.customHeaders = []
    }
    public mutating func addCustomHeader(_ header: MMSPartContent.MMSCustomHeader) {
        customHeaders.append(header)
    }
}

public struct MMSHandle: Equatable, Codable, Sendable {
    public var phoneNumber: String
    public init(phoneNumber: String) {
        self.phoneNumber = phoneNumber
    }
}
