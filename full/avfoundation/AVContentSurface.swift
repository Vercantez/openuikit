import Foundation

open class AVContentKey: NSObject, @unchecked Sendable {
  private var storedSpecifier = AVContentKeySpecifier()
  private var storedRevoked = false
  public override init() { super.init() }
  public var contentKeySpecifier: AVContentKeySpecifier { storedSpecifier }
  public var externalContentProtectionStatus: AVExternalContentProtectionStatus {
    AVExternalContentProtectionStatus(rawValue: 0)!
  }
  public func revoke() { storedRevoked = true }
  public var portableIsRevoked: Bool { storedRevoked }
}

public protocol AVContentKeyRecipient {
  func contentKeySession(_ contentKeySession: AVContentKeySession, didProvide contentKey: AVContentKey)
  var mayRequireContentKeysForMediaDataProcessing: Bool { get }
}

extension AVContentKeyRecipient {
  public func contentKeySession(_ contentKeySession: AVContentKeySession, didProvide contentKey: AVContentKey) {
    _ = (contentKeySession, contentKey)
  }
  public var mayRequireContentKeysForMediaDataProcessing: Bool { false }
}

open class AVContentKeyRequest: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public struct RetryReason: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.init(rawValue: value) }
    public static let timedOut = RetryReason(rawValue: "AVContentKeyRequestRetryReasonTimedOut")
    public static let receivedResponseWithExpiredLease = RetryReason(
      rawValue: "AVContentKeyRequestRetryReasonReceivedResponseWithExpiredLease"
    )
    public static let receivedObsoleteContentKey = RetryReason(
      rawValue: "AVContentKeyRequestRetryReasonReceivedObsoleteContentKey"
    )
  }
  public enum Status: Int, Hashable, Sendable {
    case requestingResponse = 0
    case receivedResponse = 1
    case renewed = 2
    case retried = 3
    case cancelled = 4
    case failed = 5
  }
  var storedStatus = Status.failed
  var storedError: (any Error)? = AVError(.contentKeyRequestCancelled)
  var storedIdentifier: (any Sendable)?
  var storedInitializationData: Data?
  var storedOptions: [String : any Sendable] = [:]
  var storedSpecifier = AVContentKeySpecifier()
  var storedOriginatingRecipient: (any AVContentKeyRecipient)?
  var storedRenewsExpiringResponseData = false

  public var status: AVContentKeyRequest.Status { storedStatus }
  public var error: (any Error)? { storedError }
  public var identifier: (any Sendable)? { storedIdentifier }
  public var initializationData: Data? { storedInitializationData }
  public var options: [String : any Sendable] { storedOptions }
  public var canProvidePersistableContentKey: Bool { false }
  public var contentKeySpecifier: AVContentKeySpecifier { storedSpecifier }
  public var contentKey: AVContentKey? { nil }
  public var originatingRecipient: (any AVContentKeyRecipient)? { storedOriginatingRecipient }
  public func makeStreamingContentKeyRequestData(
    forApp appIdentifier: Data,
    contentIdentifier: Data?,
    options: [String : Any]? = nil
  ) async throws -> Data {
    _ = (appIdentifier, contentIdentifier, options)
    throw AVError(.contentKeyRequestCancelled)
  }
  public func processContentKeyResponse(_ keyResponse: AVContentKeyResponse) {
    _ = keyResponse
    storedStatus = .failed
    storedError = AVError(.contentKeyRequestCancelled)
  }
  public func processContentKeyResponseError(_ error: any Error) {
    storedStatus = .failed
    storedError = error
  }
  public func respondByRequestingPersistableContentKeyRequest() {}
  public func respondByRequestingPersistableContentKeyRequestAndReturnError() throws {
    throw AVError(.contentKeyRequestCancelled)
  }
  public var renewsExpiringResponseData: Bool { storedRenewsExpiringResponseData }
}

open class AVContentKeyResponse: NSObject, @unchecked Sendable {
  var storedData = Data()
  public override init() { super.init() }
  public convenience init(fairPlayStreamingKeyResponseData keyResponseData: Data) {
    self.init()
    storedData = keyResponseData
  }
  public convenience init(clearKeyData keyData: Data, initializationVector: Data?) {
    self.init()
    storedData = keyData
    _ = initializationVector
  }
  public convenience init(authorizationTokenData: Data) {
    self.init()
    storedData = authorizationTokenData
  }
}

open class AVContentKeySession: NSObject, @unchecked Sendable {
  private var storedKeySystem = AVContentKeySystem.fairPlayStreaming
  private var storedStorageURL: URL?
  private weak var storedDelegate: (any AVContentKeySessionDelegate)?
  private var storedDelegateQueue: DispatchQueue?
  private var storedRecipients: [any AVContentKeyRecipient] = []
  private var storedExpired = false
  public override init() { super.init() }
  public convenience init(keySystem: AVContentKeySystem) {
    self.init()
    storedKeySystem = keySystem
  }
  public convenience init(keySystem: AVContentKeySystem, storageDirectoryAt storageURL: URL) {
    self.init()
    storedKeySystem = keySystem
    storedStorageURL = storageURL
  }
  public func setDelegate(
    _ delegate: (any AVContentKeySessionDelegate)?,
    queue delegateQueue: DispatchQueue?
  ) {
    storedDelegate = delegate
    storedDelegateQueue = delegateQueue
  }
  public var delegate: (any AVContentKeySessionDelegate)? { storedDelegate }
  public var delegateQueue: DispatchQueue? { storedDelegateQueue }
  public var storageURL: URL? { storedStorageURL }
  public var keySystem: AVContentKeySystem { storedKeySystem }
  public func expire() { storedExpired = true }
  public var contentProtectionSessionIdentifier: Data? { nil }
  public func processContentKeyRequest(
    withIdentifier identifier: (any Sendable)?,
    initializationData: Data?,
    options: [String : any Sendable]? = nil
  ) {
    let request = AVContentKeyRequest()
    request.storedIdentifier = identifier
    request.storedInitializationData = initializationData
    request.storedOptions = options ?? [:]
    request.storedStatus = .failed
    request.storedError = AVError(.contentKeyRequestCancelled)
    storedDelegate?.contentKeySession(self, contentKeyRequest: request, didFailWithError: request.storedError!)
  }
  public func renewExpiringResponseData(for contentKeyRequest: AVContentKeyRequest) {
    contentKeyRequest.storedRenewsExpiringResponseData = true
    contentKeyRequest.storedStatus = .failed
    contentKeyRequest.storedError = AVError(.contentKeyRequestCancelled)
  }
  public func makeSecureTokenForExpirationDate(
    ofPersistableContentKey persistableContentKeyData: Data
  ) async throws -> Data {
    _ = persistableContentKeyData
    throw AVError(.contentKeyRequestCancelled)
  }
  public func invalidatePersistableContentKey(
    _ persistableContentKeyData: Data,
    options: [AVContentKeySessionServerPlaybackContextOption : Any]? = nil
  ) async throws -> Data {
    _ = (persistableContentKeyData, options)
    throw AVError(.contentKeyRequestCancelled)
  }
  public func invalidateAllPersistableContentKeys(
    forApp appIdentifier: Data,
    options: [AVContentKeySessionServerPlaybackContextOption : Any]? = nil
  ) async throws -> Data {
    _ = (appIdentifier, options)
    throw AVError(.contentKeyRequestCancelled)
  }
  public func addContentKeyRecipient(_ recipient: any AVContentKeyRecipient) {
    storedRecipients.append(recipient)
  }
  public func removeContentKeyRecipient(_ recipient: any AVContentKeyRecipient) {
    storedRecipients.removeAll { ObjectIdentifier($0 as AnyObject) == ObjectIdentifier(recipient as AnyObject) }
  }
  public var contentKeyRecipients: [any AVContentKeyRecipient] { storedRecipients }
  public class func pendingExpiredSessionReports(
    withAppIdentifier appIdentifier: Data,
    storageDirectoryAt storageURL: URL
  ) -> [Data] {
    _ = (appIdentifier, storageURL)
    return []
  }
  public class func removePendingExpiredSessionReports(
    _ expiredSessionReports: [Data],
    withAppIdentifier appIdentifier: Data,
    storageDirectoryAt storageURL: URL
  ) {
    _ = (expiredSessionReports, appIdentifier, storageURL)
  }
  public var portableIsExpired: Bool { storedExpired }
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

extension AVContentKeySessionDelegate {
  public func contentKeySession(_ session: AVContentKeySession, didProvide keyRequest: AVContentKeyRequest) {
    _ = (session, keyRequest)
  }
  public func contentKeySession(_ session: AVContentKeySession, didProvideRenewingContentKeyRequest keyRequest: AVContentKeyRequest) {
    _ = (session, keyRequest)
  }
  public func contentKeySession(_ session: AVContentKeySession, didProvide keyRequest: AVPersistableContentKeyRequest) {
    _ = (session, keyRequest)
  }
  public func contentKeySession(_ session: AVContentKeySession, didUpdatePersistableContentKey persistableContentKey: Data, forContentKeyIdentifier keyIdentifier: Any) {
    _ = (session, persistableContentKey, keyIdentifier)
  }
  public func contentKeySession(_ session: AVContentKeySession, contentKeyRequest keyRequest: AVContentKeyRequest, didFailWithError err: any Error) {
    _ = (session, keyRequest, err)
  }
  public func contentKeySession(_ session: AVContentKeySession, shouldRetry keyRequest: AVContentKeyRequest, reason retryReason: AVContentKeyRequest.RetryReason) -> Bool {
    _ = (session, keyRequest, retryReason)
    return false
  }
  public func contentKeySession(_ session: AVContentKeySession, contentKeyRequestDidSucceed keyRequest: AVContentKeyRequest) {
    _ = (session, keyRequest)
  }
  public func contentKeySessionContentProtectionSessionIdentifierDidChange(_ session: AVContentKeySession) {
    _ = session
  }
  public func contentKeySessionDidGenerateExpiredSessionReport(_ session: AVContentKeySession) {
    _ = session
  }
  public func contentKeySession(_ session: AVContentKeySession, externalProtectionStatusDidChangeFor contentKey: AVContentKey) {
    _ = (session, contentKey)
  }
  public func contentKeySession(_ session: AVContentKeySession, didProvide keyRequests: [AVContentKeyRequest], forInitializationData initializationData: Data?) {
    _ = (session, keyRequests, initializationData)
  }
}

public struct AVContentKeySessionServerPlaybackContextOption: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }
  public init(stringLiteral value: String) { self.init(rawValue: value) }
  public static let protocolVersions = AVContentKeySessionServerPlaybackContextOption(rawValue: "protocolVersions")
  public static let serverChallenge = AVContentKeySessionServerPlaybackContextOption(rawValue: "serverChallenge")
}

open class AVContentKeySpecifier: NSObject, @unchecked Sendable {
  private var storedKeySystem = AVContentKeySystem.fairPlayStreaming
  private var storedOptions: [String : any Sendable] = [:]
  public override init() { super.init() }
  public convenience init(
    forKeySystem keySystem: AVContentKeySystem,
    identifier contentKeyIdentifier: Any,
    options: [String : Any] = [:]
  ) {
    self.init()
    storedKeySystem = keySystem
    _ = contentKeyIdentifier
    storedOptions = Dictionary(uniqueKeysWithValues: options.map { ($0.key, $0.value as any Sendable) })
  }
  public var keySystem: AVContentKeySystem { storedKeySystem }
  public var options: [String : any Sendable] { storedOptions }
}

public struct AVContentKeySystem: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }
  public init(stringLiteral value: String) { self.init(rawValue: value) }
  public static let fairPlayStreaming = AVContentKeySystem(rawValue: "AVContentKeySystemFairPlayStreaming")
  public static let clearKey = AVContentKeySystem(rawValue: "AVContentKeySystemClearKey")
  public static let authorizationToken = AVContentKeySystem(rawValue: "AVContentKeySystemAuthorizationToken")
}
