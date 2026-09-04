import Foundation
import Dispatch

open class ASCredentialServiceIdentifier: NSObject, NSCopying, NSSecureCoding {
    public enum IdentifierType: Int, Hashable, Sendable {
        case domain = 0
        case URL = 1
    }

    public let identifier: String
    public let type: IdentifierType

    public init(identifier: String, type: IdentifierType) {
        self.identifier = identifier
        self.type = type
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard let identifier = coder.decodeObject(of: NSString.self, forKey: "identifier") as String? else {
            return nil
        }
        self.identifier = identifier
        self.type = IdentifierType(rawValue: Int(coder.decodeInt64(forKey: "type"))) ?? .domain
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(identifier as NSString, forKey: "identifier")
        coder.encode(Int64(type.rawValue), forKey: "type")
    }

    public static var supportsSecureCoding: Bool { true }

    public func copy(with zone: NSZone? = nil) -> Any {
        ASCredentialServiceIdentifier(identifier: identifier, type: type)
    }
}

open class ASPasswordCredential: NSObject, ASAuthorizationCredential {
    public let user: String
    public let password: String

    public init(user: String, password: String) {
        self.user = user
        self.password = password
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard let user = coder.decodeObject(of: NSString.self, forKey: "user") as String?,
              let password = coder.decodeObject(of: NSString.self, forKey: "password") as String?
        else { return nil }
        self.user = user
        self.password = password
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(user as NSString, forKey: "user")
        coder.encode(password as NSString, forKey: "password")
    }

    public static var supportsSecureCoding: Bool { true }
    public func copy(with zone: NSZone? = nil) -> Any {
        ASPasswordCredential(user: user, password: password)
    }
}

open class ASPasswordCredentialIdentity: NSObject, ASCredentialIdentity, NSCopying, NSSecureCoding {
    public let serviceIdentifier: ASCredentialServiceIdentifier
    public let user: String
    public let recordIdentifier: String?
    public var rank: Int = 0

    public init(serviceIdentifier: ASCredentialServiceIdentifier, user: String, recordIdentifier: String?) {
        self.serviceIdentifier = serviceIdentifier
        self.user = user
        self.recordIdentifier = recordIdentifier
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
    public static var supportsSecureCoding: Bool { true }
    public func copy(with zone: NSZone? = nil) -> Any { self }
}

open class ASPasswordCredentialRequest: NSObject, ASCredentialRequest {
    public let passwordCredentialIdentity: ASPasswordCredentialIdentity
    public var credentialIdentity: any ASCredentialIdentity { passwordCredentialIdentity }
    public var type: ASCredentialRequestType { .password }

    public init(credentialIdentity: ASPasswordCredentialIdentity) {
        self.passwordCredentialIdentity = credentialIdentity
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
    public static var supportsSecureCoding: Bool { true }
    public func copy(with zone: NSZone? = nil) -> Any { self }
}

open class ASOneTimeCodeCredential: NSObject, ASAuthorizationCredential {
    public let code: String

    public init(code: String) {
        self.code = code
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
    public static var supportsSecureCoding: Bool { true }
    public func copy(with zone: NSZone? = nil) -> Any { self }
}

open class ASOneTimeCodeCredentialIdentity: NSObject, ASCredentialIdentity, NSCopying, NSSecureCoding {
    public let serviceIdentifier: ASCredentialServiceIdentifier
    public let label: String
    public let recordIdentifier: String?
    public var rank: Int = 0
    public var user: String { label }

    public init(serviceIdentifier: ASCredentialServiceIdentifier, label: String, recordIdentifier: String?) {
        self.serviceIdentifier = serviceIdentifier
        self.label = label
        self.recordIdentifier = recordIdentifier
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
    public static var supportsSecureCoding: Bool { true }
    public func copy(with zone: NSZone? = nil) -> Any { self }
}

open class ASOneTimeCodeCredentialRequest: NSObject, ASCredentialRequest {
    public let oneTimeCodeCredentialIdentity: ASOneTimeCodeCredentialIdentity
    public var credentialIdentity: any ASCredentialIdentity { oneTimeCodeCredentialIdentity }
    public var type: ASCredentialRequestType { .oneTimeCode }

    public init(credentialIdentity: ASOneTimeCodeCredentialIdentity) {
        self.oneTimeCodeCredentialIdentity = credentialIdentity
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
    public static var supportsSecureCoding: Bool { true }
    public func copy(with zone: NSZone? = nil) -> Any { self }
}

open class ASPasskeyCredentialIdentity: NSObject, ASCredentialIdentity, NSCopying, NSSecureCoding {
    public let relyingPartyIdentifier: String
    public let userName: String
    public let credentialID: Data
    public let userHandle: Data
    public let recordIdentifier: String?
    public var rank: Int = 0
    public var user: String { userName }
    public var serviceIdentifier: ASCredentialServiceIdentifier {
        ASCredentialServiceIdentifier(identifier: relyingPartyIdentifier, type: .domain)
    }

    public convenience init(
        relyingPartyIdentifier: String,
        userName: String,
        credentialID: Data,
        userHandle: Data,
        recordIdentifier: String?
    ) {
        self.init(
            relyingPartyIdentifier: relyingPartyIdentifier,
            userName: userName,
            credentialID: credentialID,
            userHandle: userHandle,
            recordIdentifier: recordIdentifier,
            rank: 0
        )
    }

    public init(
        relyingPartyIdentifier: String,
        userName: String,
        credentialID: Data,
        userHandle: Data,
        recordIdentifier: String?,
        rank: Int
    ) {
        self.relyingPartyIdentifier = relyingPartyIdentifier
        self.userName = userName
        self.credentialID = credentialID
        self.userHandle = userHandle
        self.recordIdentifier = recordIdentifier
        self.rank = rank
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
    public static var supportsSecureCoding: Bool { true }
    public func copy(with zone: NSZone? = nil) -> Any { self }
}

public struct ASPasskeyAssertionCredentialExtensionInput: Hashable, Sendable {
    public var largeBlob: ASAuthorizationPublicKeyCredentialLargeBlobAssertionInput?
    public var prf: ASAuthorizationPublicKeyCredentialPRFAssertionInput?

    public init(
        largeBlob: ASAuthorizationPublicKeyCredentialLargeBlobAssertionInput? = nil,
        prf: ASAuthorizationPublicKeyCredentialPRFAssertionInput? = nil
    ) {
        self.largeBlob = largeBlob
        self.prf = prf
    }
}

public struct ASPasskeyAssertionCredentialExtensionOutput: Hashable, Sendable {
    public var largeBlob: ASAuthorizationPublicKeyCredentialLargeBlobAssertionOutput?
    public var prf: ASAuthorizationPublicKeyCredentialPRFAssertionOutput?

    public init(
        largeBlob: ASAuthorizationPublicKeyCredentialLargeBlobAssertionOutput? = nil,
        prf: ASAuthorizationPublicKeyCredentialPRFAssertionOutput? = nil
    ) {
        self.largeBlob = largeBlob
        self.prf = prf
    }
}

public struct ASPasskeyRegistrationCredentialExtensionInput: Hashable, Sendable {
    public var largeBlob: ASAuthorizationPublicKeyCredentialLargeBlobRegistrationInput?
    public var prf: ASAuthorizationPublicKeyCredentialPRFRegistrationInput?

    public init(
        largeBlob: ASAuthorizationPublicKeyCredentialLargeBlobRegistrationInput? = nil,
        prf: ASAuthorizationPublicKeyCredentialPRFRegistrationInput? = nil
    ) {
        self.largeBlob = largeBlob
        self.prf = prf
    }
}

public struct ASPasskeyRegistrationCredentialExtensionOutput: Hashable, Sendable {
    public var largeBlob: ASAuthorizationPublicKeyCredentialLargeBlobRegistrationOutput?
    public var prf: ASAuthorizationPublicKeyCredentialPRFRegistrationOutput?

    public init(
        largeBlob: ASAuthorizationPublicKeyCredentialLargeBlobRegistrationOutput? = nil,
        prf: ASAuthorizationPublicKeyCredentialPRFRegistrationOutput? = nil
    ) {
        self.largeBlob = largeBlob
        self.prf = prf
    }
}

public enum ASPasskeyCredentialExtensionInput: Hashable, Sendable {
    case none
    case assertion(ASPasskeyAssertionCredentialExtensionInput)
    case registration(ASPasskeyRegistrationCredentialExtensionInput)
}

open class ASPasskeyAssertionCredential: NSObject, ASAuthorizationCredential {
    public let userHandle: Data
    public let relyingParty: String
    public let signature: Data
    public let clientDataHash: Data
    public let authenticatorData: Data
    public let credentialID: Data
    public var extensionOutput: ASPasskeyAssertionCredentialExtensionOutput?

    public init(
        userHandle: Data,
        relyingParty: String,
        signature: Data,
        clientDataHash: Data,
        authenticatorData: Data,
        credentialID: Data
    ) {
        self.userHandle = userHandle
        self.relyingParty = relyingParty
        self.signature = signature
        self.clientDataHash = clientDataHash
        self.authenticatorData = authenticatorData
        self.credentialID = credentialID
        super.init()
    }

    public convenience init(
        userHandle: Data,
        relyingParty: String,
        signature: Data,
        clientDataHash: Data,
        authenticatorData: Data,
        credentialID: Data,
        extensionOutput: ASPasskeyAssertionCredentialExtensionOutput?
    ) {
        self.init(
            userHandle: userHandle,
            relyingParty: relyingParty,
            signature: signature,
            clientDataHash: clientDataHash,
            authenticatorData: authenticatorData,
            credentialID: credentialID
        )
        self.extensionOutput = extensionOutput
    }

    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
    public static var supportsSecureCoding: Bool { true }
    public func copy(with zone: NSZone? = nil) -> Any { self }
}

open class ASPasskeyRegistrationCredential: NSObject, ASAuthorizationCredential {
    public let relyingParty: String
    public let clientDataHash: Data
    public let credentialID: Data
    public let attestationObject: Data
    public var extensionOutput: ASPasskeyRegistrationCredentialExtensionOutput?

    public init(
        relyingParty: String,
        clientDataHash: Data,
        credentialID: Data,
        attestationObject: Data
    ) {
        self.relyingParty = relyingParty
        self.clientDataHash = clientDataHash
        self.credentialID = credentialID
        self.attestationObject = attestationObject
        super.init()
    }

    public convenience init(
        relyingParty: String,
        clientDataHash: Data,
        credentialID: Data,
        attestationObject: Data,
        extensionOutput: ASPasskeyRegistrationCredentialExtensionOutput?
    ) {
        self.init(
            relyingParty: relyingParty,
            clientDataHash: clientDataHash,
            credentialID: credentialID,
            attestationObject: attestationObject
        )
        self.extensionOutput = extensionOutput
    }

    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
    public static var supportsSecureCoding: Bool { true }
    public func copy(with zone: NSZone? = nil) -> Any { self }
}

open class ASPasskeyCredentialRequest: NSObject, ASCredentialRequest {
    public let passkeyCredentialIdentity: ASPasskeyCredentialIdentity
    public let clientDataHash: Data
    public var userVerificationPreference: ASAuthorizationPublicKeyCredentialUserVerificationPreference
    public let supportedAlgorithms: [ASCOSEAlgorithmIdentifier]
    public var excludedCredentials: [ASAuthorizationPlatformPublicKeyCredentialDescriptor]?
    public var extensionInput: ASPasskeyCredentialExtensionInput = ASPasskeyCredentialExtensionInput.none
    public var credentialIdentity: any ASCredentialIdentity { passkeyCredentialIdentity }
    public var type: ASCredentialRequestType { .passkeyAssertion }

    public convenience init(
        credentialIdentity: ASPasskeyCredentialIdentity,
        clientDataHash: Data,
        userVerificationPreference: ASAuthorizationPublicKeyCredentialUserVerificationPreference,
        supportedAlgorithms: [ASCOSEAlgorithmIdentifier]
    ) {
        self.init(
            credentialIdentity: credentialIdentity,
            clientDataHash: clientDataHash,
            userVerificationPreference: userVerificationPreference,
            supportedAlgorithms: supportedAlgorithms,
            extensionInput: ASPasskeyCredentialExtensionInput.none
        )
    }

    public convenience init(
        credentialIdentity: ASPasskeyCredentialIdentity,
        clientDataHash: Data,
        userVerificationPreference: ASAuthorizationPublicKeyCredentialUserVerificationPreference,
        supportedAlgorithms: [NSNumber]
    ) {
        self.init(
            credentialIdentity: credentialIdentity,
            clientDataHash: clientDataHash,
            userVerificationPreference: userVerificationPreference,
            supportedAlgorithms: supportedAlgorithms.map { ASCOSEAlgorithmIdentifier($0.intValue) }
        )
    }

    public convenience init(
        credentialIdentity: ASPasskeyCredentialIdentity,
        clientDataHash: Data,
        userVerificationPreference: ASAuthorizationPublicKeyCredentialUserVerificationPreference,
        supportedAlgorithms: [ASCOSEAlgorithmIdentifier],
        extensionInput: ASPasskeyAssertionCredentialExtensionInput?
    ) {
        var boxed: ASPasskeyCredentialExtensionInput = ASPasskeyCredentialExtensionInput.none
        if let extensionInput {
            boxed = .assertion(extensionInput)
        }
        self.init(
            credentialIdentity: credentialIdentity,
            clientDataHash: clientDataHash,
            userVerificationPreference: userVerificationPreference,
            supportedAlgorithms: supportedAlgorithms,
            extensionInput: boxed
        )
    }

    public convenience init(
        credentialIdentity: ASPasskeyCredentialIdentity,
        clientDataHash: Data,
        userVerificationPreference: ASAuthorizationPublicKeyCredentialUserVerificationPreference,
        supportedAlgorithms: [ASCOSEAlgorithmIdentifier],
        extensionInput: ASPasskeyRegistrationCredentialExtensionInput?
    ) {
        var boxed: ASPasskeyCredentialExtensionInput = ASPasskeyCredentialExtensionInput.none
        if let extensionInput {
            boxed = .registration(extensionInput)
        }
        self.init(
            credentialIdentity: credentialIdentity,
            clientDataHash: clientDataHash,
            userVerificationPreference: userVerificationPreference,
            supportedAlgorithms: supportedAlgorithms,
            extensionInput: boxed
        )
    }

    public init(
        credentialIdentity: ASPasskeyCredentialIdentity,
        clientDataHash: Data,
        userVerificationPreference: ASAuthorizationPublicKeyCredentialUserVerificationPreference,
        supportedAlgorithms: [ASCOSEAlgorithmIdentifier],
        extensionInput: ASPasskeyCredentialExtensionInput
    ) {
        self.passkeyCredentialIdentity = credentialIdentity
        self.clientDataHash = clientDataHash
        self.userVerificationPreference = userVerificationPreference
        self.supportedAlgorithms = supportedAlgorithms
        self.extensionInput = extensionInput
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
    public static var supportsSecureCoding: Bool { true }
    public func copy(with zone: NSZone? = nil) -> Any { self }
}

open class ASPasskeyCredentialRequestParameters: NSObject, NSCopying, NSSecureCoding {
    public var relyingPartyIdentifier: String = ""
    public var clientDataHash: Data = Data()
    public var userVerificationPreference: ASAuthorizationPublicKeyCredentialUserVerificationPreference = .preferred
    public var allowedCredentials: [Data] = []
    public var extensionInput: ASPasskeyAssertionCredentialExtensionInput?

    public override init() { super.init() }
    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
    public static var supportsSecureCoding: Bool { true }
    public func copy(with zone: NSZone? = nil) -> Any { self }
}

open class ASCredentialIdentityStoreState: NSObject {
    public let isEnabled: Bool
    public let supportsIncrementalUpdates: Bool

    @_spi(OpenUIKitHost)
    public init(isEnabled: Bool, supportsIncrementalUpdates: Bool) {
        self.isEnabled = isEnabled
        self.supportsIncrementalUpdates = supportsIncrementalUpdates
        super.init()
    }
}

open class ASCredentialIdentityStore: NSObject {
    public struct IdentityTypes: OptionSet, Hashable, Sendable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        public static let password = IdentityTypes(rawValue: 1 << 0)
        public static let passkey = IdentityTypes(rawValue: 1 << 1)
        public static let oneTimeCode = IdentityTypes(rawValue: 1 << 2)
    }

    public static let shared = ASCredentialIdentityStore()

    public func getState(_ completion: @escaping (ASCredentialIdentityStoreState) -> Void) {
        let state = ASCredentialIdentityStoreState(isEnabled: false, supportsIncrementalUpdates: false)
        AuthenticationServicesHostCallback.queue.async {
            completion(state)
        }
    }

    public func removeAllCredentialIdentities(_ completion: ((Bool, (any Error)?) -> Void)? = nil) {
        let error = ASCredentialIdentityStoreError(.storeDisabled)
        AuthenticationServicesHostCallback.queue.async {
            completion?(false, error)
        }
    }

    public func removeCredentialIdentities(_ credentialIdentities: [ASPasswordCredentialIdentity]) async throws {
        _ = credentialIdentities
        throw ASCredentialIdentityStoreError(.storeDisabled)
    }

    public func removeCredentialIdentities(_ credentialIdentities: [any ASCredentialIdentity]) async throws {
        _ = credentialIdentities
        throw ASCredentialIdentityStoreError(.storeDisabled)
    }

    public func replaceCredentialIdentities(with newCredentialIdentities: [ASPasswordCredentialIdentity]) async throws {
        _ = newCredentialIdentities
        throw ASCredentialIdentityStoreError(.storeDisabled)
    }

    public func replaceCredentialIdentities(_ newCredentialIdentities: [any ASCredentialIdentity]) async throws {
        _ = newCredentialIdentities
        throw ASCredentialIdentityStoreError(.storeDisabled)
    }

    public func saveCredentialIdentities(_ credentialIdentities: [ASPasswordCredentialIdentity]) async throws {
        _ = credentialIdentities
        throw ASCredentialIdentityStoreError(.storeDisabled)
    }

    public func saveCredentialIdentities(_ credentialIdentities: [any ASCredentialIdentity]) async throws {
        _ = credentialIdentities
        throw ASCredentialIdentityStoreError(.storeDisabled)
    }

    public func credentialIdentities(
        forService serviceIdentifier: ASCredentialServiceIdentifier? = nil,
        credentialIdentityTypes: IdentityTypes = []
    ) async -> [any ASCredentialIdentity] {
        _ = serviceIdentifier
        _ = credentialIdentityTypes
        return []
    }
}

public final class ASCredentialUpdater: NSObject, @unchecked Sendable {
    public override init() { super.init() }

    public func reportUnusedPasswordCredential(domain: String, userName: String) async throws {
        _ = domain
        _ = userName
        throw ASAuthorizationError(.failed)
    }

    public func reportPublicKeyCredentialUpdate(relyingPartyIdentifier: String, userHandle: Data, newName: String) async throws {
        _ = relyingPartyIdentifier
        _ = userHandle
        _ = newName
        throw ASAuthorizationError(.failed)
    }

    public func reportUnknownPublicKeyCredential(relyingPartyIdentifier: String, credentialID: Data) async throws {
        _ = relyingPartyIdentifier
        _ = credentialID
        throw ASAuthorizationError(.failed)
    }

    public func reportAllAcceptedPublicKeyCredentials(
        relyingPartyIdentifier: String,
        userHandle: Data,
        acceptedCredentialIDs: [Data]
    ) async throws {
        _ = relyingPartyIdentifier
        _ = userHandle
        _ = acceptedCredentialIDs
        throw ASAuthorizationError(.failed)
    }
}

open class ASSettingsHelper: NSObject {
    public class func openCredentialProviderAppSettings(completionHandler: (((any Error)?) -> Void)? = nil) {
        AuthenticationServicesHostCallback.queue.async {
            completionHandler?(ASAuthorizationError(.notInteractive))
        }
    }

    public class func openVerificationCodeAppSettings(completionHandler: (((any Error)?) -> Void)? = nil) {
        AuthenticationServicesHostCallback.queue.async {
            completionHandler?(ASAuthorizationError(.notInteractive))
        }
    }

    public class func requestToTurnOnCredentialProviderExtension(completionHandler: @escaping (Bool) -> Void) {
        AuthenticationServicesHostCallback.queue.async {
            completionHandler(false)
        }
    }
}

open class ASAccountAuthenticationModificationRequest: NSObject {}

open class ASAccountAuthenticationModificationReplacePasswordWithSignInWithAppleRequest: ASAccountAuthenticationModificationRequest {
    public let user: String
    public let serviceIdentifier: ASCredentialServiceIdentifier
    public let userInfo: [AnyHashable: Any]?

    public init(user: String, serviceIdentifier: ASCredentialServiceIdentifier, userInfo: [AnyHashable: Any]? = nil) {
        self.user = user
        self.serviceIdentifier = serviceIdentifier
        self.userInfo = userInfo
        super.init()
    }
}

open class ASAccountAuthenticationModificationUpgradePasswordToStrongPasswordRequest: ASAccountAuthenticationModificationRequest {
    public let user: String
    public let serviceIdentifier: ASCredentialServiceIdentifier
    public let userInfo: [AnyHashable: Any]?

    public init(user: String, serviceIdentifier: ASCredentialServiceIdentifier, userInfo: [AnyHashable: Any]? = nil) {
        self.user = user
        self.serviceIdentifier = serviceIdentifier
        self.userInfo = userInfo
        super.init()
    }
}

public protocol ASAccountAuthenticationModificationControllerDelegate: AnyObject {
    func accountAuthenticationModificationController(
        _ controller: ASAccountAuthenticationModificationController,
        didFail request: ASAccountAuthenticationModificationRequest,
        error: any Error
    )
    func accountAuthenticationModificationController(
        _ controller: ASAccountAuthenticationModificationController,
        didSuccessfullyComplete request: ASAccountAuthenticationModificationRequest,
        userInfo: [AnyHashable: Any]?
    )
}

extension ASAccountAuthenticationModificationControllerDelegate {
    public func accountAuthenticationModificationController(
        _ controller: ASAccountAuthenticationModificationController,
        didFail request: ASAccountAuthenticationModificationRequest,
        error: any Error
    ) {}
    public func accountAuthenticationModificationController(
        _ controller: ASAccountAuthenticationModificationController,
        didSuccessfullyComplete request: ASAccountAuthenticationModificationRequest,
        userInfo: [AnyHashable: Any]?
    ) {}
}

open class ASAccountAuthenticationModificationController: NSObject {
    public weak var delegate: (any ASAccountAuthenticationModificationControllerDelegate)?

    public func perform(_ request: ASAccountAuthenticationModificationRequest) {
        _ = request
    }
}

open class ASAccountAuthenticationModificationExtensionContext: NSObject {
    public func cancelRequest(withError error: any Error) {
        _ = error
    }

    public func completeChangePasswordRequest(updatedCredential: ASPasswordCredential, userInfo: [AnyHashable: Any]? = nil) {
        _ = updatedCredential
        _ = userInfo
    }

    public func completeUpgradeToSignInWithApple(userInfo: [AnyHashable: Any]? = nil) {
        _ = userInfo
    }

    public func getSignInWithAppleUpgradeAuthorization(
        state: String?,
        nonce: String?,
        completionHandler: @escaping (ASAuthorizationAppleIDCredential?, (any Error)?) -> Void
    ) {
        _ = state
        _ = nonce
        AuthenticationServicesHostCallback.queue.async {
            completionHandler(nil, ASAuthorizationError(.notInteractive))
        }
    }
}

open class ASCredentialProviderExtensionContext: NSObject {
    public func cancelRequest(withError error: any Error) {
        _ = error
    }

    public func completeAssertionRequest(using credential: ASPasskeyAssertionCredential) async -> Bool {
        _ = credential
        return false
    }

    public func completeExtensionConfigurationRequest() {}

    public func completeOneTimeCodeRequest(using credential: ASOneTimeCodeCredential) async -> Bool {
        _ = credential
        return false
    }

    public func completeRegistrationRequest(using credential: ASPasskeyRegistrationCredential) async -> Bool {
        _ = credential
        return false
    }

    public func completeRequest(withSelectedCredential credential: ASPasswordCredential, completionHandler: ((Bool) -> Void)? = nil) {
        _ = credential
        AuthenticationServicesHostCallback.queue.async {
            completionHandler?(false)
        }
    }

    public func completeRequest(withTextToInsert text: String) async -> Bool {
        _ = text
        return false
    }
}

open class ASAuthorizationProviderExtensionAuthorizationResult: NSObject {
    public var httpAuthorizationHeaders: [String: String]?
    public var httpBody: Data?

    public init(httpAuthorizationHeaders: [String: String]) {
        self.httpAuthorizationHeaders = httpAuthorizationHeaders
        super.init()
    }

    public init(HTTPAuthorizationHeaders httpAuthorizationHeaders: [String: String]) {
        self.httpAuthorizationHeaders = httpAuthorizationHeaders
        super.init()
    }
}

open class ASAuthorizationProviderExtensionAuthorizationRequest: NSObject {
    public var authorizationOptions: [AnyHashable: Any] = [:]
    public var callerBundleIdentifier = ""
    public var isCallerManaged = false
    public var callerTeamIdentifier = ""
    public var extensionData: [AnyHashable: Any] = [:]
    public var httpBody = Data()
    public var httpHeaders: [String: String] = [:]
    public var localizedCallerDisplayName = ""
    public var realm = ""
    public var requestedOperation = ASAuthorizationProviderAuthorizationOperation.directRequest
    public var url = URL(fileURLWithPath: "/")
    public var isUserInterfaceEnabled = false

    public func cancel() {}
    public func complete() {}
    public func complete(authorizationResult: ASAuthorizationProviderExtensionAuthorizationResult) {
        _ = authorizationResult
    }
    public func complete(error: any Error) { _ = error }
    public func complete(httpAuthorizationHeaders: [String: String]) {
        _ = httpAuthorizationHeaders
    }
    public func doNotHandle() {}

    public func presentAuthorizationViewController(
        completion: @escaping (Bool, (any Error)?) -> Void
    ) {
        AuthenticationServicesHostCallback.queue.async {
            completion(false, ASAuthorizationError(.notInteractive))
        }
    }
}

@MainActor
public protocol ASAuthorizationProviderExtensionAuthorizationRequestHandler: NSObjectProtocol {
    func beginAuthorization(with request: ASAuthorizationProviderExtensionAuthorizationRequest)
    func cancelAuthorization(with request: ASAuthorizationProviderExtensionAuthorizationRequest)
}

extension ASAuthorizationProviderExtensionAuthorizationRequestHandler {
    public func cancelAuthorization(with request: ASAuthorizationProviderExtensionAuthorizationRequest) {
        _ = request
    }
}
