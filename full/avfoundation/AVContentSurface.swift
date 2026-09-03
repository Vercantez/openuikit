import Foundation

open class AVContentKey: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var contentKeySpecifier: AVContentKeySpecifier { AVContentKeySpecifier() }
  public var externalContentProtectionStatus: AVExternalContentProtectionStatus { AVExternalContentProtectionStatus(rawValue: 0)! }
  public func revoke() {}
}

public protocol AVContentKeyRecipient {
  func contentKeySession(_ contentKeySession: AVContentKeySession, didProvide contentKey: AVContentKey)
  var mayRequireContentKeysForMediaDataProcessing: Bool { get }
}

open class AVContentKeyRequest: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public struct RetryReason: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.init(rawValue: value) }
    public static let timedOut = RetryReason(rawValue: "timedOut")
    public static let receivedResponseWithExpiredLease = RetryReason(rawValue: "receivedResponseWithExpiredLease")
    public static let receivedObsoleteContentKey = RetryReason(rawValue: "receivedObsoleteContentKey")
  }
  public enum Status: Int, Hashable, Sendable {
    case requestingResponse = 0
    case receivedResponse = 1
    case renewed = 2
    case retried = 3
    case cancelled = 4
    case failed = 5
  }
  public var status: AVContentKeyRequest.Status { AVContentKeyRequest.Status(rawValue: 0)! }
  public var error: (any Error)? { nil }
  public var identifier: (any Sendable)? { nil }
  public var initializationData: Data? { nil }
  public var options: [String : any Sendable] { [:] }
  public var canProvidePersistableContentKey: Bool { false }
  public var contentKeySpecifier: AVContentKeySpecifier { AVContentKeySpecifier() }
  public var contentKey: AVContentKey? { nil }
  public weak var originatingRecipient: (any AVContentKeyRecipient)? { nil }
  public func makeStreamingContentKeyRequestData(forApp appIdentifier: Data, contentIdentifier: Data?, options: [String : Any]? = nil) async throws -> Data { return .init() }
  public func processContentKeyResponse(_ keyResponse: AVContentKeyResponse) {}
  public func processContentKeyResponseError(_ error: any Error) {}
  public func respondByRequestingPersistableContentKeyRequest() {}
  public func respondByRequestingPersistableContentKeyRequestAndReturnError() throws { throw AVFoundationPortableError.mediaServiceUnavailable }
  public var renewsExpiringResponseData: Bool { false }
}

open class AVContentKeyResponse: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  convenience init(fairPlayStreamingKeyResponseData keyResponseData: Data) { self.init() }
  convenience init(clearKeyData keyData: Data, initializationVector: Data?) { self.init() }
  convenience init(authorizationTokenData: Data) { self.init() }
}

open class AVContentKeySession: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  convenience init(keySystem: AVContentKeySystem) { self.init() }
  convenience init(keySystem: AVContentKeySystem, storageDirectoryAt storageURL: URL) { self.init() }
  public func setDelegate(_ delegate: (any AVContentKeySessionDelegate)?, queue delegateQueue: DispatchQueue?) {}
  public weak var delegate: (any AVContentKeySessionDelegate)? { nil }
  public var delegateQueue: DispatchQueue? { nil }
  public var storageURL: URL? { nil }
  public var keySystem: AVContentKeySystem { AVContentKeySystem(rawValue: "") }
  public func expire() {}
  public var contentProtectionSessionIdentifier: Data? { nil }
  public func processContentKeyRequest(withIdentifier identifier: (any Sendable)?, initializationData: Data?, options: [String : any Sendable]? = nil) {}
  public func renewExpiringResponseData(for contentKeyRequest: AVContentKeyRequest) {}
  public func makeSecureTokenForExpirationDate(ofPersistableContentKey persistableContentKeyData: Data) async throws -> Data { return .init() }
  public func invalidatePersistableContentKey(_ persistableContentKeyData: Data, options: [AVContentKeySessionServerPlaybackContextOption : Any]? = nil) async throws -> Data { return .init() }
  public func invalidateAllPersistableContentKeys(forApp appIdentifier: Data, options: [AVContentKeySessionServerPlaybackContextOption : Any]? = nil) async throws -> Data { return .init() }
  public func addContentKeyRecipient(_ recipient: any AVContentKeyRecipient) {}
  public func removeContentKeyRecipient(_ recipient: any AVContentKeyRecipient) {}
  public var contentKeyRecipients: [any AVContentKeyRecipient] { [] }
  public class func pendingExpiredSessionReports(withAppIdentifier appIdentifier: Data, storageDirectoryAt storageURL: URL) -> [Data] { [] }
  public class func removePendingExpiredSessionReports(_ expiredSessionReports: [Data], withAppIdentifier appIdentifier: Data, storageDirectoryAt storageURL: URL) {}
}

public protocol AVContentKeySessionDelegate : AnyObject, Sendable {
  func contentKeySession(_ session: AVContentKeySession, didProvide keyRequest: AVContentKeyRequest)
  func contentKeySession(_ session: AVContentKeySession, didProvideRenewingContentKeyRequest keyRequest: AVContentKeyRequest)
  func contentKeySession(_ session: AVContentKeySession, didProvide keyRequest: AVPersistableContentKeyRequest)
  func contentKeySession(_ session: AVContentKeySession, didUpdatePersistableContentKey persistableContentKey: Data, forContentKeyIdentifier keyIdentifier: Any)
  func contentKeySession(_ session: AVContentKeySession, contentKeyRequest keyRequest: AVContentKeyRequest, didFailWithError err: any Error)
  func contentKeySession(_ session: AVContentKeySession, shouldRetry keyRequest: AVContentKeyRequest, reason retryReason: AVContentKeyRequest.RetryReason) -> Bool
  func contentKeySession(_ session: AVContentKeySession, contentKeyRequestDidSucceed keyRequest: AVContentKeyRequest)
  func contentKeySessionContentProtectionSessionIdentifierDidChange(_ session: AVContentKeySession)
  func contentKeySessionDidGenerateExpiredSessionReport(_ session: AVContentKeySession)
  func contentKeySession(_ session: AVContentKeySession, externalProtectionStatusDidChangeFor contentKey: AVContentKey)
  func contentKeySession(_ session: AVContentKeySession, didProvide keyRequests: [AVContentKeyRequest], forInitializationData initializationData: Data?)
}

public struct AVContentKeySessionServerPlaybackContextOption: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }
  public init(stringLiteral value: String) { self.init(rawValue: value) }
  public static let protocolVersions = AVContentKeySessionServerPlaybackContextOption(rawValue: "protocolVersions")
  public static let serverChallenge = AVContentKeySessionServerPlaybackContextOption(rawValue: "serverChallenge")
}

open class AVContentKeySpecifier: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public init(forKeySystem keySystem: AVContentKeySystem, identifier contentKeyIdentifier: Any, options: [String : Any] = [:]) {}
  public var keySystem: AVContentKeySystem { AVContentKeySystem(rawValue: "") }
  public var options: [String : any Sendable] { [:] }
}

public struct AVContentKeySystem: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }
  public init(stringLiteral value: String) { self.init(rawValue: value) }
  public static let fairPlayStreaming = AVContentKeySystem(rawValue: "fairPlayStreaming")
  public static let clearKey = AVContentKeySystem(rawValue: "clearKey")
  public static let authorizationToken = AVContentKeySystem(rawValue: "authorizationToken")
}
