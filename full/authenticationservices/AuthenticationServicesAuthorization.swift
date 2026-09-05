import Foundation
import Dispatch

public struct ASAuthorizationPublicKeyCredentialAttestationKind: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ rawValue: String) { self.rawValue = rawValue }
    public static let none = Self("ASAuthorizationPublicKeyCredentialAttestationKindNone")
    public static let indirect = Self("ASAuthorizationPublicKeyCredentialAttestationKindIndirect")
    public static let direct = Self("ASAuthorizationPublicKeyCredentialAttestationKindDirect")
    public static let enterprise = Self("ASAuthorizationPublicKeyCredentialAttestationKindEnterprise")
}

public struct ASAuthorizationPublicKeyCredentialResidentKeyPreference: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ rawValue: String) { self.rawValue = rawValue }
    public static let discouraged = Self("ASAuthorizationPublicKeyCredentialResidentKeyPreferenceDiscouraged")
    public static let preferred = Self("ASAuthorizationPublicKeyCredentialResidentKeyPreferencePreferred")
    public static let required = Self("ASAuthorizationPublicKeyCredentialResidentKeyPreferenceRequired")
}

public struct ASAuthorizationPublicKeyCredentialUserVerificationPreference: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ rawValue: String) { self.rawValue = rawValue }
    public static let discouraged = Self("ASAuthorizationPublicKeyCredentialUserVerificationPreferenceDiscouraged")
    public static let preferred = Self("ASAuthorizationPublicKeyCredentialUserVerificationPreferencePreferred")
    public static let required = Self("ASAuthorizationPublicKeyCredentialUserVerificationPreferenceRequired")
}

public struct ASAuthorizationProviderAuthorizationOperation: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ rawValue: String) { self.rawValue = rawValue }
    public static let configurationRemoved = Self("ASAuthorizationProviderAuthorizationOperationConfigurationRemoved")
    public static let directRequest = Self("ASAuthorizationProviderAuthorizationOperationDirectRequest")
}

public struct ASCOSEAlgorithmIdentifier: RawRepresentable, Hashable, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public init(_ rawValue: Int) { self.rawValue = rawValue }
    public static let ES256 = Self(-7)
}

public struct ASCOSEEllipticCurveIdentifier: RawRepresentable, Hashable, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public init(_ rawValue: Int) { self.rawValue = rawValue }
    public static let P256 = Self(1)
}

public enum ASAuthorizationPublicKeyCredentialAttachment: Int, Hashable, Sendable {
    case platform = 0
    case crossPlatform = 1
}

public enum ASPublicKeyCredentialClientDataCrossOriginValue: Int, Hashable, Sendable {
    case notSet = 0
    case crossOrigin = 1
    case sameOriginWithAncestors = 2
}

public enum ASUserAgeRange: Int, Hashable, Sendable {
    case unknown = 0
    case child = 1
    case notChild = 2
}

public enum ASUserDetectionStatus: Int, Hashable, Sendable {
    case unsupported = 0
    case unknown = 1
    case likelyReal = 2
}

public enum ASCredentialRequestType: Int, Hashable, Sendable {
    case password = 0
    case passkeyAssertion = 1
    case passkeyRegistration = 2
    case oneTimeCode = 3
}

public protocol ASAuthorizationProvider: NSObjectProtocol {}

public protocol ASAuthorizationCredential: NSObjectProtocol, NSCopying, NSSecureCoding {}

public protocol ASCredentialIdentity: NSObjectProtocol {
    var rank: Int { get set }
    var recordIdentifier: String? { get }
    var serviceIdentifier: ASCredentialServiceIdentifier { get }
    var user: String { get }
}

public protocol ASCredentialRequest: NSObjectProtocol, NSCopying, NSSecureCoding {
    var credentialIdentity: any ASCredentialIdentity { get }
    var type: ASCredentialRequestType { get }
}

public protocol ASPublicKeyCredential: ASAuthorizationCredential {
    var rawClientDataJSON: Data { get }
    var credentialID: Data { get }
}

public protocol ASAuthorizationPublicKeyCredentialDescriptor: NSObjectProtocol, NSCopying, NSSecureCoding {
    var credentialID: Data { get set }
}

public protocol ASAuthorizationPublicKeyCredentialAssertion: ASPublicKeyCredential {
    var rawAuthenticatorData: Data! { get }
    var signature: Data! { get }
    var userID: Data! { get }
}

public protocol ASAuthorizationPublicKeyCredentialRegistration: ASPublicKeyCredential {
    var rawAttestationObject: Data? { get }
}

public protocol ASAuthorizationPublicKeyCredentialAssertionRequest: NSObjectProtocol, NSCopying, NSSecureCoding {
    var allowedCredentials: [any ASAuthorizationPublicKeyCredentialDescriptor] { get set }
    var challenge: Data { get set }
    var relyingPartyIdentifier: String { get set }
    var userVerificationPreference: ASAuthorizationPublicKeyCredentialUserVerificationPreference { get set }
}

public protocol ASAuthorizationPublicKeyCredentialRegistrationRequest: NSObjectProtocol, NSCopying, NSSecureCoding {
    var attestationPreference: ASAuthorizationPublicKeyCredentialAttestationKind { get set }
    var challenge: Data { get set }
    var displayName: String? { get set }
    var name: String { get set }
    var relyingPartyIdentifier: String { get }
    var userID: Data { get set }
    var userVerificationPreference: ASAuthorizationPublicKeyCredentialUserVerificationPreference { get set }
}

open class ASAuthorizationRequest: NSObject, NSCopying, NSSecureCoding {
    public private(set) var provider: any ASAuthorizationProvider

    public init(provider: any ASAuthorizationProvider) {
        self.provider = provider
        super.init()
    }

    public required init?(coder: NSCoder) {
        return nil
    }

    open func encode(with coder: NSCoder) {}

    public static var supportsSecureCoding: Bool { true }

    open func copy(with zone: NSZone? = nil) -> Any {
        self
    }
}

public final class ASAuthorization: NSObject {
    public struct OpenIDOperation: RawRepresentable, Hashable, Sendable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public init(_ rawValue: String) { self.rawValue = rawValue }
        public static let operationImplicit = Self("ASAuthorizationOperationImplicit")
        public static let operationLogin = Self("ASAuthorizationOperationLogin")
        public static let operationRefresh = Self("ASAuthorizationOperationRefresh")
        public static let operationLogout = Self("ASAuthorizationOperationLogout")
    }

    public struct Scope: RawRepresentable, Hashable, Sendable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public init(_ rawValue: String) { self.rawValue = rawValue }
        public static let email = Self("ASAuthorizationScopeEmail")
        public static let fullName = Self("ASAuthorizationScopeFullName")
    }

    public let provider: any ASAuthorizationProvider
    public let credential: any ASAuthorizationCredential

    @_spi(OpenUIKitHost)
    public init(provider: any ASAuthorizationProvider, credential: any ASAuthorizationCredential) {
        self.provider = provider
        self.credential = credential
        super.init()
    }
}

open class ASAuthorizationOpenIDRequest: ASAuthorizationRequest {
    public var nonce: String?
    public var requestedOperation: ASAuthorization.OpenIDOperation = .operationImplicit
    public var requestedScopes: [ASAuthorization.Scope]?
    public var state: String?
}

open class ASAuthorizationAppleIDRequest: ASAuthorizationOpenIDRequest {
    public var user: String?
}

open class ASAuthorizationPasswordRequest: ASAuthorizationRequest {}

open class ASAuthorizationSingleSignOnRequest: ASAuthorizationOpenIDRequest {
    public var authorizationOptions: [String: Any]?
    public var isUserInterfaceEnabled = true
}

public protocol ASAuthorizationControllerDelegate: AnyObject {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    )
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    )
}

extension ASAuthorizationControllerDelegate {
    public func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {}
    public func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {}
}

open class ASAuthorizationController: NSObject {
    public struct RequestOptions: OptionSet, Hashable, Sendable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        public static let preferImmediatelyAvailableCredentials = RequestOptions(rawValue: 1 << 0)
    }

    public let authorizationRequests: [ASAuthorizationRequest]
    public weak var delegate: (any ASAuthorizationControllerDelegate)?
    /// Darwin is `UIWindow`-backed. Linux stores the provider; `performRequests`
    /// never presents UI.
    public weak var presentationContextProvider:
        (any ASAuthorizationControllerPresentationContextProviding)?

    /// Documented Linux test hook. When set, `performRequests` delivers this
    /// authorization to the delegate instead of failing closed.
    @_spi(OpenUIKitHost)
    public var _testAuthorization: ASAuthorization?

    public init(authorizationRequests: [ASAuthorizationRequest]) {
        self.authorizationRequests = authorizationRequests
        super.init()
    }

    public func cancel() {}

    public func performRequests() {
        performRequests(options: [])
    }

    public func performRequests(options: RequestOptions = []) {
        _ = options
        if let authorization = _testAuthorization {
            AuthenticationServicesHostCallback.queue.async { [weak self] in
                guard let self else { return }
                self.delegate?.authorizationController(
                    controller: self,
                    didCompleteWithAuthorization: authorization
                )
            }
            return
        }
        // Linux has no Apple ID / passkey authenticator. Empty request lists
        // complete with `.unknown`; any real request completes with
        // `.notHandled` unless `_testAuthorization` supplies credentials.
        // Apple's `ASAuthorizationError.Code`: unknown = 1000, notHandled = 1003
        // (macios / iPhoneOS 26.1). Presentation-context absence is not
        // separately coded here: Darwin's queue/code for a missing provider
        // remains an oracle question.
        let code: ASAuthorizationError.Code =
            authorizationRequests.isEmpty ? .unknown : .notHandled
        let error = ASAuthorizationError(code)
        AuthenticationServicesHostCallback.queue.async { [weak self] in
            guard let self else { return }
            self.delegate?.authorizationController(
                controller: self,
                didCompleteWithError: error
            )
        }
    }

    public func performAutoFillAssistedRequests() {
        performRequests(options: [])
    }
}

public protocol ASAuthorizationControllerPresentationContextProviding: NSObjectProtocol {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor
}

open class ASAuthorizationAppleIDProvider: NSObject, ASAuthorizationProvider {
    public enum CredentialState: Int, Hashable, Sendable {
        case revoked = 0
        case authorized = 1
        case notFound = 2
        case transferred = 3
    }

    public static let credentialRevokedNotification = ASAuthorizationAppleIDProviderCredentialRevokedNotification

    public func createRequest() -> ASAuthorizationAppleIDRequest {
        ASAuthorizationAppleIDRequest(provider: self)
    }

    /// Completion-handler form of the ObjC selector
    /// `getCredentialStateForUserID:completion:`. Linux always reports
    /// `.notFound` (no Apple ID daemon).
    public func getCredentialState(
        forUserID userID: String,
        completion: @escaping (CredentialState, (any Error)?) -> Void
    ) {
        _ = userID
        AuthenticationServicesHostCallback.queue.async {
            completion(.notFound, nil)
        }
    }

    public func credentialState(forUserID userID: String) async throws -> CredentialState {
        _ = userID
        return .notFound
    }
}

open class ASAuthorizationPasswordProvider: NSObject, ASAuthorizationProvider {
    public func createRequest() -> ASAuthorizationPasswordRequest {
        ASAuthorizationPasswordRequest(provider: self)
    }
}

open class ASAuthorizationSingleSignOnProvider: NSObject, ASAuthorizationProvider {
    public let url: URL
    public var canPerformAuthorization: Bool { false }

    public init(identityProvider url: URL) {
        self.url = url
        super.init()
    }

    public func createRequest() -> ASAuthorizationSingleSignOnRequest {
        ASAuthorizationSingleSignOnRequest(provider: self)
    }
}

open class ASAuthorizationAppleIDButton: NSObject {
    public enum Style: Int, Hashable, Sendable {
        case white = 0
        case whiteOutline = 1
        case black = 2
    }

    public enum ButtonType: Int, Hashable, Sendable {
        case signIn = 0
        case `continue` = 1
        case signUp = 2
        public static var `default`: ButtonType { .signIn }
    }

    /// Darwin is a `UIControl`. Isolated Linux stores type/style/cornerRadius
    /// only; there is no UIKit drawing path (`draw(_:)`, intrinsic size, or
    /// control events). Default `cornerRadius` is 0 until an Apple layout
    /// sample records the control's intrinsic radius.
    public var cornerRadius: CGFloat = 0

    public init(authorizationButtonType type: ButtonType, authorizationButtonStyle style: Style) {
        self.storedType = type
        self.storedStyle = style
        super.init()
    }

    public convenience init(type: ButtonType, style: Style) {
        self.init(authorizationButtonType: type, authorizationButtonStyle: style)
    }

    private let storedType: ButtonType
    private let storedStyle: Style
}

open class ASAuthorizationAppleIDCredential: NSObject, ASAuthorizationCredential {
    public private(set) var user: String = ""
    public private(set) var state: String?
    public private(set) var authorizedScopes: [ASAuthorization.Scope] = []
    public private(set) var authorizationCode: Data?
    public private(set) var identityToken: Data?
    public private(set) var email: String?
    public private(set) var fullName: PersonNameComponents?
    public private(set) var realUserStatus: ASUserDetectionStatus = .unsupported
    public private(set) var userAgeRange: ASUserAgeRange = .unknown

    public override init() { super.init() }

    /// Host/test construction. Darwin produces this type from Sign in with
    /// Apple; Linux never invents tokens unless a test hook supplies them.
    @_spi(OpenUIKitHost)
    public init(
        user: String,
        email: String? = nil,
        fullName: PersonNameComponents? = nil,
        identityToken: Data? = nil,
        authorizationCode: Data? = nil,
        state: String? = nil,
        authorizedScopes: [ASAuthorization.Scope] = [],
        realUserStatus: ASUserDetectionStatus = .unsupported,
        userAgeRange: ASUserAgeRange = .unknown
    ) {
        self.user = user
        self.email = email
        self.fullName = fullName
        self.identityToken = identityToken
        self.authorizationCode = authorizationCode
        self.state = state
        self.authorizedScopes = authorizedScopes
        self.realUserStatus = realUserStatus
        self.userAgeRange = userAgeRange
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
    public static var supportsSecureCoding: Bool { true }
    public func copy(with zone: NSZone? = nil) -> Any {
        ASAuthorizationAppleIDCredential(
            user: user,
            email: email,
            fullName: fullName,
            identityToken: identityToken,
            authorizationCode: authorizationCode,
            state: state,
            authorizedScopes: authorizedScopes,
            realUserStatus: realUserStatus,
            userAgeRange: userAgeRange
        )
    }
}

open class ASAuthorizationSingleSignOnCredential: NSObject, ASAuthorizationCredential {
    public private(set) var state: String?
    public private(set) var accessToken: Data?
    public private(set) var identityToken: Data?
    public private(set) var authorizedScopes: [ASAuthorization.Scope] = []

    public override init() { super.init() }

    @_spi(OpenUIKitHost)
    public init(
        state: String? = nil,
        accessToken: Data? = nil,
        identityToken: Data? = nil,
        authorizedScopes: [ASAuthorization.Scope] = []
    ) {
        self.state = state
        self.accessToken = accessToken
        self.identityToken = identityToken
        self.authorizedScopes = authorizedScopes
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
    public static var supportsSecureCoding: Bool { true }
    public func copy(with zone: NSZone? = nil) -> Any {
        ASAuthorizationSingleSignOnCredential(
            state: state,
            accessToken: accessToken,
            identityToken: identityToken,
            authorizedScopes: authorizedScopes
        )
    }
}

public struct ASPublicKeyCredentialClientData: Hashable, Sendable {
    public enum CrossOriginValue: Hashable, Sendable {
        case crossOrigin
        case sameOriginWithAncestors
    }

    public var challenge: Data
    public var origin: String
    public var topOrigin: String?
    public var crossOrigin: CrossOriginValue?

    public init(
        challenge: Data,
        origin: String,
        topOrigin: String? = nil,
        crossOrigin: CrossOriginValue? = nil
    ) {
        self.challenge = challenge
        self.origin = origin
        self.topOrigin = topOrigin
        self.crossOrigin = crossOrigin
    }
}

open class ASAuthorizationPlatformPublicKeyCredentialProvider: NSObject, ASAuthorizationProvider {
    public let relyingPartyIdentifier: String

    public init(relyingPartyIdentifier: String) {
        self.relyingPartyIdentifier = relyingPartyIdentifier
        super.init()
    }

    public func createCredentialAssertionRequest(challenge: Data) -> ASAuthorizationPlatformPublicKeyCredentialAssertionRequest {
        ASAuthorizationPlatformPublicKeyCredentialAssertionRequest(provider: self, relyingPartyIdentifier: relyingPartyIdentifier, challenge: challenge)
    }

    public func createCredentialRegistrationRequest(challenge: Data, name: String, userID: Data) -> ASAuthorizationPlatformPublicKeyCredentialRegistrationRequest {
        ASAuthorizationPlatformPublicKeyCredentialRegistrationRequest(provider: self, relyingPartyIdentifier: relyingPartyIdentifier, challenge: challenge, name: name, userID: userID)
    }

    public func createCredentialRegistrationRequest(
        challenge: Data,
        name: String,
        userID: Data,
        requestStyle: ASAuthorizationPlatformPublicKeyCredentialRegistrationRequest.RequestStyle
    ) -> ASAuthorizationPlatformPublicKeyCredentialRegistrationRequest {
        let request = createCredentialRegistrationRequest(challenge: challenge, name: name, userID: userID)
        request.requestStyle = requestStyle
        return request
    }

    public func createCredentialAssertionRequest(clientData: ASPublicKeyCredentialClientData) -> ASAuthorizationPlatformPublicKeyCredentialAssertionRequest {
        createCredentialAssertionRequest(challenge: clientData.challenge)
    }

    public func createCredentialRegistrationRequest(clientData: ASPublicKeyCredentialClientData, name: String, userID: Data) -> ASAuthorizationPlatformPublicKeyCredentialRegistrationRequest {
        createCredentialRegistrationRequest(challenge: clientData.challenge, name: name, userID: userID)
    }

    public func createCredentialRegistrationRequest(
        clientData: ASPublicKeyCredentialClientData,
        name: String,
        userID: Data,
        requestStyle: ASAuthorizationPlatformPublicKeyCredentialRegistrationRequest.RequestStyle
    ) -> ASAuthorizationPlatformPublicKeyCredentialRegistrationRequest {
        let request = createCredentialRegistrationRequest(clientData: clientData, name: name, userID: userID)
        request.requestStyle = requestStyle
        return request
    }
}

open class ASAuthorizationSecurityKeyPublicKeyCredentialProvider: NSObject, ASAuthorizationProvider {
    public let relyingPartyIdentifier: String

    public init(relyingPartyIdentifier: String) {
        self.relyingPartyIdentifier = relyingPartyIdentifier
        super.init()
    }

    public func createCredentialAssertionRequest(challenge: Data) -> ASAuthorizationSecurityKeyPublicKeyCredentialAssertionRequest {
        ASAuthorizationSecurityKeyPublicKeyCredentialAssertionRequest(provider: self, relyingPartyIdentifier: relyingPartyIdentifier, challenge: challenge)
    }

    public func createCredentialRegistrationRequest(challenge: Data, displayName: String, name: String, userID: Data) -> ASAuthorizationSecurityKeyPublicKeyCredentialRegistrationRequest {
        ASAuthorizationSecurityKeyPublicKeyCredentialRegistrationRequest(
            provider: self,
            relyingPartyIdentifier: relyingPartyIdentifier,
            challenge: challenge,
            displayName: displayName,
            name: name,
            userID: userID
        )
    }
}

open class ASAuthorizationPlatformPublicKeyCredentialRegistrationRequest: ASAuthorizationRequest, ASAuthorizationPublicKeyCredentialRegistrationRequest {
    public enum RequestStyle: Int, Hashable, Sendable {
        case standard = 0
        case conditional = 1
    }

    public var requestStyle: RequestStyle = .standard
    public var attestationPreference: ASAuthorizationPublicKeyCredentialAttestationKind = .none
    public var challenge: Data
    public var displayName: String?
    public var name: String
    public let relyingPartyIdentifier: String
    public var userID: Data
    public var userVerificationPreference: ASAuthorizationPublicKeyCredentialUserVerificationPreference = .preferred
    public var prf: ASAuthorizationPublicKeyCredentialPRFRegistrationInput?
    public var largeBlob: ASAuthorizationPublicKeyCredentialLargeBlobRegistrationInput?

    public init(
        provider: any ASAuthorizationProvider,
        relyingPartyIdentifier: String,
        challenge: Data,
        name: String,
        userID: Data
    ) {
        self.relyingPartyIdentifier = relyingPartyIdentifier
        self.challenge = challenge
        self.name = name
        self.userID = userID
        super.init(provider: provider)
    }

    public required init?(coder: NSCoder) { return nil }
}

open class ASAuthorizationPlatformPublicKeyCredentialAssertionRequest: ASAuthorizationRequest, ASAuthorizationPublicKeyCredentialAssertionRequest {
    public var allowedCredentials: [any ASAuthorizationPublicKeyCredentialDescriptor] = []
    public var challenge: Data
    public var relyingPartyIdentifier: String
    public var userVerificationPreference: ASAuthorizationPublicKeyCredentialUserVerificationPreference = .preferred
    public var prf: ASAuthorizationPublicKeyCredentialPRFAssertionInput?
    public var largeBlob: ASAuthorizationPublicKeyCredentialLargeBlobAssertionInput?
    public var platformAllowedCredentials: [ASAuthorizationPlatformPublicKeyCredentialDescriptor] {
        get { allowedCredentials.compactMap { $0 as? ASAuthorizationPlatformPublicKeyCredentialDescriptor } }
        set { allowedCredentials = newValue }
    }

    public init(
        provider: any ASAuthorizationProvider,
        relyingPartyIdentifier: String,
        challenge: Data
    ) {
        self.relyingPartyIdentifier = relyingPartyIdentifier
        self.challenge = challenge
        super.init(provider: provider)
    }

    public required init?(coder: NSCoder) { return nil }
}

open class ASAuthorizationSecurityKeyPublicKeyCredentialRegistrationRequest: ASAuthorizationRequest, ASAuthorizationPublicKeyCredentialRegistrationRequest {
    public var attestationPreference: ASAuthorizationPublicKeyCredentialAttestationKind = .none
    public var challenge: Data
    public var displayName: String?
    public var name: String
    public let relyingPartyIdentifier: String
    public var userID: Data
    public var userVerificationPreference: ASAuthorizationPublicKeyCredentialUserVerificationPreference = .preferred
    public var credentialParameters: [ASAuthorizationPublicKeyCredentialParameters] = []
    public var excludedCredentials: [ASAuthorizationSecurityKeyPublicKeyCredentialDescriptor] = []
    public var residentKeyPreference: ASAuthorizationPublicKeyCredentialResidentKeyPreference = .preferred

    public init(
        provider: any ASAuthorizationProvider,
        relyingPartyIdentifier: String,
        challenge: Data,
        displayName: String,
        name: String,
        userID: Data
    ) {
        self.relyingPartyIdentifier = relyingPartyIdentifier
        self.challenge = challenge
        self.displayName = displayName
        self.name = name
        self.userID = userID
        super.init(provider: provider)
    }

    public required init?(coder: NSCoder) { return nil }
}

open class ASAuthorizationSecurityKeyPublicKeyCredentialAssertionRequest: ASAuthorizationRequest, ASAuthorizationPublicKeyCredentialAssertionRequest {
    public var allowedCredentials: [any ASAuthorizationPublicKeyCredentialDescriptor] = []
    public var challenge: Data
    public var relyingPartyIdentifier: String
    public var userVerificationPreference: ASAuthorizationPublicKeyCredentialUserVerificationPreference = .preferred
    public var appID: String?
    public var clientData: ASPublicKeyCredentialClientData?
    public var securityKeyAllowedCredentials: [ASAuthorizationSecurityKeyPublicKeyCredentialDescriptor] {
        get { allowedCredentials.compactMap { $0 as? ASAuthorizationSecurityKeyPublicKeyCredentialDescriptor } }
        set { allowedCredentials = newValue }
    }

    public init(
        provider: any ASAuthorizationProvider,
        relyingPartyIdentifier: String,
        challenge: Data
    ) {
        self.relyingPartyIdentifier = relyingPartyIdentifier
        self.challenge = challenge
        super.init(provider: provider)
    }

    public required init?(coder: NSCoder) { return nil }
}

open class ASAuthorizationPublicKeyCredentialParameters: NSObject, NSCopying, NSSecureCoding {
    public let algorithm: ASCOSEAlgorithmIdentifier

    public init(algorithm: ASCOSEAlgorithmIdentifier) {
        self.algorithm = algorithm
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
    public static var supportsSecureCoding: Bool { true }
    public func copy(with zone: NSZone? = nil) -> Any { self }
}

open class ASAuthorizationPlatformPublicKeyCredentialDescriptor: NSObject, ASAuthorizationPublicKeyCredentialDescriptor {
    public var credentialID: Data

    public init(credentialID: Data) {
        self.credentialID = credentialID
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
    public static var supportsSecureCoding: Bool { true }
    public func copy(with zone: NSZone? = nil) -> Any { self }
}

open class ASAuthorizationSecurityKeyPublicKeyCredentialDescriptor: NSObject, ASAuthorizationPublicKeyCredentialDescriptor {
    public struct Transport: RawRepresentable, Hashable, Sendable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public init(_ rawValue: String) { self.rawValue = rawValue }
        public static let bluetooth = Self("ASAuthorizationSecurityKeyPublicKeyCredentialDescriptorTransportBluetooth")
        public static let nfc = Self("ASAuthorizationSecurityKeyPublicKeyCredentialDescriptorTransportNFC")
        public static let usb = Self("ASAuthorizationSecurityKeyPublicKeyCredentialDescriptorTransportUSB")
        public static var allSupported: [Transport] { [.usb, .nfc, .bluetooth] }
    }

    public var credentialID: Data
    public var transports: [Transport]

    public init(credentialID: Data, transports allowedTransports: [Transport]) {
        self.credentialID = credentialID
        self.transports = allowedTransports
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
    public static var supportsSecureCoding: Bool { true }
    public func copy(with zone: NSZone? = nil) -> Any { self }
}

open class ASAuthorizationPlatformPublicKeyCredentialAssertion: NSObject, ASAuthorizationPublicKeyCredentialAssertion {
    public var rawClientDataJSON: Data = Data()
    public var credentialID: Data = Data()
    public var rawAuthenticatorData: Data! = Data()
    public var signature: Data! = Data()
    public var userID: Data! = Data()
    public var attachment: ASAuthorizationPublicKeyCredentialAttachment = .platform
    public var prf: ASAuthorizationPublicKeyCredentialPRFAssertionOutput?
    public var largeBlob: ASAuthorizationPublicKeyCredentialLargeBlobAssertionOutput?

    public override init() { super.init() }
    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
    public static var supportsSecureCoding: Bool { true }
    public func copy(with zone: NSZone? = nil) -> Any { self }
}

open class ASAuthorizationPlatformPublicKeyCredentialRegistration: NSObject, ASAuthorizationPublicKeyCredentialRegistration {
    public var rawClientDataJSON: Data = Data()
    public var credentialID: Data = Data()
    public var rawAttestationObject: Data?
    public var attachment: ASAuthorizationPublicKeyCredentialAttachment = .platform
    public var prf: ASAuthorizationPublicKeyCredentialPRFRegistrationOutput?
    public var largeBlob: ASAuthorizationPublicKeyCredentialLargeBlobRegistrationOutput?

    public override init() { super.init() }
    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
    public static var supportsSecureCoding: Bool { true }
    public func copy(with zone: NSZone? = nil) -> Any { self }
}

open class ASAuthorizationSecurityKeyPublicKeyCredentialAssertion: NSObject, ASAuthorizationPublicKeyCredentialAssertion {
    public var rawClientDataJSON: Data = Data()
    public var credentialID: Data = Data()
    public var rawAuthenticatorData: Data! = Data()
    public var signature: Data! = Data()
    public var userID: Data! = Data()
    public var appID: Bool = false

    public override init() { super.init() }
    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
    public static var supportsSecureCoding: Bool { true }
    public func copy(with zone: NSZone? = nil) -> Any { self }
}

open class ASAuthorizationSecurityKeyPublicKeyCredentialRegistration: NSObject, ASAuthorizationPublicKeyCredentialRegistration {
    public var rawClientDataJSON: Data = Data()
    public var credentialID: Data = Data()
    public var rawAttestationObject: Data?
    public var transports: [ASAuthorizationSecurityKeyPublicKeyCredentialDescriptor.Transport] = []

    public override init() { super.init() }
    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
    public static var supportsSecureCoding: Bool { true }
    public func copy(with zone: NSZone? = nil) -> Any { self }
}

public struct ASAuthorizationPublicKeyCredentialPRFAssertionInput: Hashable, Sendable {
    public struct InputValues: Hashable, Sendable {
        public var saltInput1: Data
        public var saltInput2: Data?

        public init(saltInput1: Data, saltInput2: Data? = nil) {
            self.saltInput1 = saltInput1
            self.saltInput2 = saltInput2
        }

        public static func saltInput1(_ saltInput1: Data, saltInput2: Data? = nil) -> InputValues {
            InputValues(saltInput1: saltInput1, saltInput2: saltInput2)
        }
    }

    public let inputValues: InputValues?
    public let perCredentialInputValues: [Data: InputValues]?

    public static func inputValues(
        _ inputValues: InputValues,
        perCredentialInputValues: [Data: InputValues]? = nil
    ) -> ASAuthorizationPublicKeyCredentialPRFAssertionInput {
        ASAuthorizationPublicKeyCredentialPRFAssertionInput(
            inputValues: inputValues,
            perCredentialInputValues: perCredentialInputValues
        )
    }

    public static func perCredentialInputValues(
        _ perCredentialInputValues: [Data: InputValues]
    ) -> ASAuthorizationPublicKeyCredentialPRFAssertionInput {
        ASAuthorizationPublicKeyCredentialPRFAssertionInput(
            inputValues: nil,
            perCredentialInputValues: perCredentialInputValues
        )
    }

    private init(inputValues: InputValues?, perCredentialInputValues: [Data: InputValues]?) {
        self.inputValues = inputValues
        self.perCredentialInputValues = perCredentialInputValues
    }
}

public struct ASAuthorizationPublicKeyCredentialPRFRegistrationInput: Hashable, Sendable {
    public typealias InputValues = ASAuthorizationPublicKeyCredentialPRFAssertionInput.InputValues
    public let inputValues: InputValues?
    public let shouldCheckForSupport: Bool

    public static var checkForSupport: ASAuthorizationPublicKeyCredentialPRFRegistrationInput {
        ASAuthorizationPublicKeyCredentialPRFRegistrationInput(inputValues: nil, shouldCheckForSupport: true)
    }

    public static func inputValues(_ inputValues: InputValues) -> ASAuthorizationPublicKeyCredentialPRFRegistrationInput {
        ASAuthorizationPublicKeyCredentialPRFRegistrationInput(inputValues: inputValues, shouldCheckForSupport: false)
    }

    private init(inputValues: InputValues?, shouldCheckForSupport: Bool) {
        self.inputValues = inputValues
        self.shouldCheckForSupport = shouldCheckForSupport
    }
}

public struct ASAuthorizationPublicKeyCredentialPRFRegistrationOutput: Hashable, Sendable {
    public let isSupported: Bool
    public static var unsupported: Self { Self(isSupported: false) }
    public static var supported: Self { Self(isSupported: true) }
}

public struct ASAuthorizationPublicKeyCredentialPRFAssertionOutput: Hashable, Sendable {
    public init() {}
}

public struct ASAuthorizationPublicKeyCredentialLargeBlobRegistrationInput: Hashable, Sendable {
    public enum SupportRequirement: Hashable, Sendable {
        case required
        case preferred
    }

    public var supportRequirement: SupportRequirement
    public static var supportRequired: Self { Self(supportRequirement: .required) }
    public static var supportPreferred: Self { Self(supportRequirement: .preferred) }
}

public struct ASAuthorizationPublicKeyCredentialLargeBlobRegistrationOutput: Hashable, Sendable {
    public var isSupported: Bool
    public static var unsupported: Self { Self(isSupported: false) }
    public static var supported: Self { Self(isSupported: true) }
}

public struct ASAuthorizationPublicKeyCredentialLargeBlobAssertionInput: Hashable, Sendable {
    public enum Operation: Hashable, Sendable {
        case read
        case write(Data)
    }

    public var operation: Operation
    public static var read: Self { Self(operation: .read) }
    public static func write(_ data: Data) -> Self { Self(operation: .write(data)) }
}

public struct ASAuthorizationPublicKeyCredentialLargeBlobAssertionOutput: Hashable, Sendable {
    public enum OperationResult: Hashable, Sendable {
        case read(data: Data?)
        case write(success: Bool)
    }

    public var result: OperationResult
    public static func read(data: Data?) -> Self { Self(result: .read(data: data)) }
    public static func write(success: Bool) -> Self { Self(result: .write(success: success)) }
}

public struct ASAuthorizationWebBrowserPlatformPublicKeyCredential: Hashable, Sendable {
    public var name: String
    public var relyingParty: String
    public var credentialID: Data
    public var userHandle: Data
    public var providerName: String?
    public var userName: String?
    public var customTitle: String = ""

    public init(name: String, relyingParty: String, credentialID: Data, userHandle: Data) {
        self.name = name
        self.relyingParty = relyingParty
        self.credentialID = credentialID
        self.userHandle = userHandle
    }
}

open class ASAuthorizationWebBrowserPublicKeyCredentialManager: NSObject {
    public enum AuthorizationState: Int, Hashable, Sendable {
        case authorized = 0
        case denied = 1
        case notDetermined = 2
    }

    public static var isDeviceConfiguredForPasskeys: Bool { false }

    public func authorizationState() async -> AuthorizationState { .denied }

    public func platformCredentials(forRelyingParty relyingParty: String) async -> [ASAuthorizationWebBrowserPlatformPublicKeyCredential] {
        _ = relyingParty
        return []
    }

    public func requestAuthorization() async -> AuthorizationState { .denied }

    public var authorizationStateForPlatformCredentials: AuthorizationState { .denied }

    public func requestAuthorizationForPublicKeyCredentials(
        _ completionHandler: @escaping (AuthorizationState) -> Void
    ) {
        AuthenticationServicesHostCallback.queue.async {
            completionHandler(.denied)
        }
    }
}

open class ASAuthorizationAccountCreationProvider: NSObject, ASAuthorizationProvider {
    public func createCredentialRegistrationRequest() -> ASAuthorizationAccountCreationPlatformPublicKeyCredentialRequest {
        ASAuthorizationAccountCreationPlatformPublicKeyCredentialRequest(provider: self)
    }

    public func createPlatformPublicKeyCredentialRegistrationRequest(
        acceptedContactIdentifiers: [ASContactIdentifierRequest],
        shouldRequestName: Bool,
        relyingPartyIdentifier: String,
        challenge: Data,
        userID: Data
    ) -> ASAuthorizationAccountCreationPlatformPublicKeyCredentialRequest {
        let request = ASAuthorizationAccountCreationPlatformPublicKeyCredentialRequest(provider: self)
        request.acceptedContactIdentifiers = acceptedContactIdentifiers
        request.shouldRequestName = shouldRequestName
        request.relyingPartyIdentifier = relyingPartyIdentifier
        request.challenge = challenge
        request.userID = userID
        return request
    }
}

open class ASAuthorizationAccountCreationPlatformPublicKeyCredentialRequest: ASAuthorizationRequest {
    public var contactIdentifiers: [ASContactIdentifierRequest] = []
    public var acceptedContactIdentifiers: [ASContactIdentifierRequest] = []
    public var shouldRequestName = false
    public var relyingPartyIdentifier = ""
    public var challenge = Data()
    public var userID = Data()

    public override init(provider: any ASAuthorizationProvider) {
        super.init(provider: provider)
    }
    public required init?(coder: NSCoder) { return nil }
}

open class ASAuthorizationAccountCreationPlatformPublicKeyCredential: NSObject, NSCopying, NSSecureCoding {
    public var contactIdentifier: ASContactIdentifier = .email(ASEmailIdentifier(value: ""))
    public var credentialRegistration = ASAuthorizationPlatformPublicKeyCredentialRegistration()
    public var name: PersonNameComponents?

    public override init() { super.init() }
    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}
    public static var supportsSecureCoding: Bool { true }
    public func copy(with zone: NSZone? = nil) -> Any { self }
}

public enum ASAuthorizationResult {
    case passkeyAssertion(ASAuthorizationPlatformPublicKeyCredentialAssertion)
    case passkeyRegistration(ASAuthorizationPlatformPublicKeyCredentialRegistration)
    case securityKeyAssertion(ASAuthorizationSecurityKeyPublicKeyCredentialAssertion)
    case passkeyAccountCreation(ASAuthorizationAccountCreationPlatformPublicKeyCredential)
    case securityKeyRegistration(ASAuthorizationSecurityKeyPublicKeyCredentialRegistration)
    case appleID(ASAuthorizationAppleIDCredential)
    case password(ASPasswordCredential)
}
