import Foundation

// MARK: - Token driver / token / session

public protocol TKTokenDelegate: NSObjectProtocol {
    func createSession(_ token: TKToken) throws -> TKTokenSession
    func token(_ token: TKToken, terminateSession session: TKTokenSession)
}

public extension TKTokenDelegate {
    func token(_ token: TKToken, terminateSession session: TKTokenSession) {}
}

public protocol TKTokenDriverDelegate: NSObjectProtocol {
    func tokenDriver(_ driver: TKTokenDriver, terminateToken token: TKToken)
    func tokenDriver(_ driver: TKTokenDriver, tokenFor configuration: TKToken.Configuration) throws -> TKToken
}

public extension TKTokenDriverDelegate {
    func tokenDriver(_ driver: TKTokenDriver, terminateToken token: TKToken) {}
    func tokenDriver(_ driver: TKTokenDriver, tokenFor configuration: TKToken.Configuration) throws -> TKToken {
        throw tkMakeError(.notImplemented, reason: "token driver has no hardware backend")
    }
}

public protocol TKTokenSessionDelegate: NSObjectProtocol {
    func tokenSession(
        _ session: TKTokenSession,
        beginAuthFor operation: TKTokenOperation,
        constraint: Any
    ) throws -> TKTokenAuthOperation
    func tokenSession(
        _ session: TKTokenSession,
        decrypt ciphertext: Data,
        keyObjectID: TKToken.ObjectID,
        algorithm: TKTokenKeyAlgorithm
    ) throws -> Data
    func tokenSession(
        _ session: TKTokenSession,
        performKeyExchange otherPartyPublicKeyData: Data,
        keyObjectID objectID: TKToken.ObjectID,
        algorithm: TKTokenKeyAlgorithm,
        parameters: TKTokenKeyExchangeParameters
    ) throws -> Data
    func tokenSession(
        _ session: TKTokenSession,
        sign dataToSign: Data,
        keyObjectID: TKToken.ObjectID,
        algorithm: TKTokenKeyAlgorithm
    ) throws -> Data
    func tokenSession(
        _ session: TKTokenSession,
        supports operation: TKTokenOperation,
        keyObjectID: TKToken.ObjectID,
        algorithm: TKTokenKeyAlgorithm
    ) -> Bool
}

public extension TKTokenSessionDelegate {
    func tokenSession(
        _ session: TKTokenSession,
        beginAuthFor operation: TKTokenOperation,
        constraint: Any
    ) throws -> TKTokenAuthOperation {
        _ = (session, operation, constraint)
        throw tkMakeError(.authenticationNeeded, reason: "token session has no authenticator")
    }

    func tokenSession(
        _ session: TKTokenSession,
        decrypt ciphertext: Data,
        keyObjectID: TKToken.ObjectID,
        algorithm: TKTokenKeyAlgorithm
    ) throws -> Data {
        _ = (session, ciphertext, keyObjectID, algorithm)
        throw tkMakeError(.notImplemented, reason: "private-key decrypt requires a token")
    }

    func tokenSession(
        _ session: TKTokenSession,
        performKeyExchange otherPartyPublicKeyData: Data,
        keyObjectID objectID: TKToken.ObjectID,
        algorithm: TKTokenKeyAlgorithm,
        parameters: TKTokenKeyExchangeParameters
    ) throws -> Data {
        _ = (session, otherPartyPublicKeyData, objectID, algorithm, parameters)
        throw tkMakeError(.notImplemented, reason: "key exchange requires a token")
    }

    func tokenSession(
        _ session: TKTokenSession,
        sign dataToSign: Data,
        keyObjectID: TKToken.ObjectID,
        algorithm: TKTokenKeyAlgorithm
    ) throws -> Data {
        _ = (session, dataToSign, keyObjectID, algorithm)
        throw tkMakeError(.notImplemented, reason: "private-key sign requires a token")
    }

    func tokenSession(
        _ session: TKTokenSession,
        supports operation: TKTokenOperation,
        keyObjectID: TKToken.ObjectID,
        algorithm: TKTokenKeyAlgorithm
    ) -> Bool {
        _ = (session, operation, keyObjectID, algorithm)
        return false
    }
}

open class TKTokenDriver: NSObject {
    public weak var delegate: (any TKTokenDriverDelegate)?
}

open class TKToken: NSObject {
    public let tokenDriver: TKTokenDriver
    public let configuration: TKToken.Configuration
    public weak var delegate: (any TKTokenDelegate)?
    public let keychainContents: TKTokenKeychainContents?

    public init(tokenDriver: TKTokenDriver, instanceID: TKToken.InstanceID) {
        self.tokenDriver = tokenDriver
        self.configuration = TKToken.Configuration(instanceID: instanceID)
        self.keychainContents = TKTokenKeychainContents()
        super.init()
    }
}

open class TKTokenSession: NSObject {
    public let token: TKToken
    public weak var delegate: (any TKTokenSessionDelegate)?

    public init(token: TKToken) {
        self.token = token
        super.init()
    }
}

// MARK: - Configuration (process-local catalog)

extension TKToken {
    open class Configuration: NSObject {
        public let instanceID: TKToken.InstanceID
        public var configurationData: Data?
        public var keychainItems: [TKTokenKeychainItem] = []

        public init(instanceID: TKToken.InstanceID) {
            self.instanceID = instanceID
            super.init()
        }

        public func certificate(for objectID: TKToken.ObjectID) throws -> TKTokenKeychainCertificate {
            for item in keychainItems {
                if let certificate = item as? TKTokenKeychainCertificate,
                   tkObjectIDsEqual(certificate.objectID, objectID) {
                    return certificate
                }
            }
            throw tkMakeError(.objectNotFound, reason: "no certificate for objectID")
        }

        public func key(for objectID: TKToken.ObjectID) throws -> TKTokenKeychainKey {
            for item in keychainItems {
                if let key = item as? TKTokenKeychainKey,
                   tkObjectIDsEqual(key.objectID, objectID) {
                    return key
                }
            }
            throw tkMakeError(.objectNotFound, reason: "no key for objectID")
        }
    }
}

extension TKTokenDriver {
    open class Configuration: NSObject {
        private static let lock = NSLock()
        private static var registry: [TKTokenDriver.ClassID: TKTokenDriver.Configuration] = [:]

        public static var driverConfigurations: [TKTokenDriver.ClassID: TKTokenDriver.Configuration] {
            lock.lock()
            defer { lock.unlock() }
            return registry
        }

        public let classID: TKTokenDriver.ClassID
        private var tokens: [TKToken.InstanceID: TKToken.Configuration] = [:]
        private let tokenLock = NSLock()

        public init(classID: TKTokenDriver.ClassID) {
            self.classID = classID
            super.init()
            Self.lock.lock()
            Self.registry[classID] = self
            Self.lock.unlock()
        }

        public var tokenConfigurations: [TKToken.InstanceID: TKToken.Configuration] {
            tokenLock.lock()
            defer { tokenLock.unlock() }
            return tokens
        }

        public func addTokenConfiguration(for instanceID: TKToken.InstanceID) -> TKToken.Configuration {
            tokenLock.lock()
            defer { tokenLock.unlock() }
            if let existing = tokens[instanceID] {
                return existing
            }
            let created = TKToken.Configuration(instanceID: instanceID)
            tokens[instanceID] = created
            return created
        }

        public func removeTokenConfiguration(for instanceID: TKToken.InstanceID) {
            tokenLock.lock()
            tokens.removeValue(forKey: instanceID)
            tokenLock.unlock()
        }
    }
}

// MARK: - Keychain items

open class TKTokenKeychainItem: NSObject {
    public let objectID: TKToken.ObjectID
    public var constraints: [NSNumber: Any]?
    public var label: String?

    public init(objectID: TKToken.ObjectID) {
        self.objectID = objectID
        super.init()
    }
}

open class TKTokenKeychainCertificate: TKTokenKeychainItem {
    public private(set) var data: Data

    public init(objectID: TKToken.ObjectID, data: Data = Data()) {
        self.data = data
        super.init(objectID: objectID)
    }
}

open class TKTokenKeychainKey: TKTokenKeychainItem {
    public var applicationTag: Data?
    public var canDecrypt: Bool = false
    public var canPerformKeyExchange: Bool = false
    public var canSign: Bool = false
    public var keySizeInBits: Int = 0
    public var keyType: String = ""
    public var publicKeyData: Data?
    public var publicKeyHash: Data?
    public var isSuitableForLogin: Bool = false

    public override init(objectID: TKToken.ObjectID) {
        super.init(objectID: objectID)
    }
}

open class TKTokenKeychainContents: NSObject {
    private var storage: [TKTokenKeychainItem] = []
    private let lock = NSLock()

    public override init() {
        super.init()
    }

    public var items: [TKTokenKeychainItem] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    public func fill(with items: [TKTokenKeychainItem]) {
        lock.lock()
        storage = items
        lock.unlock()
    }

    public func certificate(forObjectID objectID: TKToken.ObjectID) throws -> TKTokenKeychainCertificate {
        for item in items {
            if let certificate = item as? TKTokenKeychainCertificate,
               tkObjectIDsEqual(certificate.objectID, objectID) {
                return certificate
            }
        }
        throw tkMakeError(.objectNotFound, reason: "no certificate for objectID")
    }

    public func key(forObjectID objectID: TKToken.ObjectID) throws -> TKTokenKeychainKey {
        for item in items {
            if let key = item as? TKTokenKeychainKey,
               tkObjectIDsEqual(key.objectID, objectID) {
                return key
            }
        }
        throw tkMakeError(.objectNotFound, reason: "no key for objectID")
    }
}

open class TKTokenKeyAlgorithm: NSObject {}

open class TKTokenKeyExchangeParameters: NSObject {
    public private(set) var requestedSize: Int = 0
    public private(set) var sharedInfo: Data?

    public override init() {
        super.init()
    }

    public init(requestedSize: Int, sharedInfo: Data? = nil) {
        self.requestedSize = requestedSize
        self.sharedInfo = sharedInfo
        super.init()
    }
}

// MARK: - Auth operations

open class TKTokenAuthOperation: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init()
        _ = coder
    }

    public func encode(with coder: NSCoder) {
        _ = coder
    }

    open func finish() throws {
        // Base class is the "no further authentication needed" operation.
    }
}

open class TKTokenPasswordAuthOperation: TKTokenAuthOperation {
    public var password: String?

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        password = coder.decodeObject(of: NSString.self, forKey: "password") as String?
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(password as NSString?, forKey: "password")
    }

    open override func finish() throws {
        throw tkMakeError(.notImplemented, reason: "password token auth requires the token daemon")
    }
}

open class TKTokenSmartCardPINAuthOperation: TKTokenAuthOperation {
    public var apduTemplate: Data?
    public var pin: String?
    public var pinByteOffset: Int = 0
    public var pinFormat: TKSmartCardPINFormat = TKSmartCardPINFormat()
    public var smartCard: TKSmartCard?

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        pin = coder.decodeObject(of: NSString.self, forKey: "pin") as String?
        pinByteOffset = Int(coder.decodeInt64(forKey: "pinByteOffset"))
        apduTemplate = coder.decodeObject(of: NSData.self, forKey: "apduTemplate") as Data?
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(pin as NSString?, forKey: "pin")
        coder.encode(Int64(pinByteOffset), forKey: "pinByteOffset")
        coder.encode(apduTemplate as NSData?, forKey: "apduTemplate")
    }

    open override func finish() throws {
        throw tkMakeError(.notImplemented, reason: "smart-card PIN auth requires reader hardware")
    }
}

// MARK: - Watcher

open class TKTokenWatcher: NSObject {
    public private(set) var tokenIDs: [String] = []
    private var insertionHandler: ((String) -> Void)?
    private var removalHandlers: [String: (String) -> Void] = [:]

    public override init() {
        super.init()
    }

    public init(insertionHandler: @escaping (String) -> Void) {
        self.insertionHandler = insertionHandler
        super.init()
    }

    public func setInsertionHandler(_ insertionHandler: @escaping (String) -> Void) {
        self.insertionHandler = insertionHandler
    }

    public func addRemovalHandler(_ removalHandler: @escaping (String) -> Void, forTokenID tokenID: String) {
        removalHandlers[tokenID] = removalHandler
    }

    public func tokenInfo(forTokenID tokenID: String) -> TKTokenWatcher.TokenInfo? {
        _ = tokenID
        return nil
    }
}

extension TKTokenWatcher {
    open class TokenInfo: NSObject {
        public let tokenID: String
        public let driverName: String?
        public let slotName: String?

        public init(tokenID: String, driverName: String? = nil, slotName: String? = nil) {
            self.tokenID = tokenID
            self.driverName = driverName
            self.slotName = slotName
            super.init()
        }
    }
}

// MARK: - Smart card token

public protocol TKSmartCardTokenDriverDelegate: TKTokenDriverDelegate {
    func tokenDriver(
        _ driver: TKSmartCardTokenDriver,
        createTokenFor smartCard: TKSmartCard,
        aid AID: Data?
    ) throws -> TKSmartCardToken
}

open class TKSmartCardTokenDriver: TKTokenDriver {}

open class TKSmartCardToken: TKToken {
    public let aid: Data?
    let attachedSmartCard: TKSmartCard

    public init(
        smartCard: TKSmartCard,
        aid AID: Data?,
        instanceID: String,
        tokenDriver: TKSmartCardTokenDriver
    ) {
        self.aid = AID
        self.attachedSmartCard = smartCard
        super.init(tokenDriver: tokenDriver, instanceID: instanceID)
    }

    public init(
        smartCard: TKSmartCard,
        AID: Data?,
        instanceID: String,
        tokenDriver: TKSmartCardTokenDriver
    ) {
        self.aid = AID
        self.attachedSmartCard = smartCard
        super.init(tokenDriver: tokenDriver, instanceID: instanceID)
    }
}

open class TKSmartCardTokenSession: TKTokenSession {
    public var smartCard: TKSmartCard {
        (try? getSmartCard()) ?? TKSmartCard()
    }

    public func getSmartCard() throws -> TKSmartCard {
        guard let token = token as? TKSmartCardToken else {
            throw tkMakeError(.tokenNotFound, reason: "session is not attached to a smart-card token")
        }
        return token.attachedSmartCard
    }
}

open class TKSmartCardTokenRegistrationManager: NSObject {
    public static let `default` = TKSmartCardTokenRegistrationManager()

    public var registeredSmartCardTokens: [String] { [] }

    public func registerSmartCard(tokenID: String, promptMessage: String) throws {
        _ = (tokenID, promptMessage)
        throw tkMakeError(.notImplemented, reason: "smart-card pairing requires ctkd")
    }

    public func unregisterSmartCard(tokenID: String) throws {
        _ = tokenID
        throw tkMakeError(.notImplemented, reason: "smart-card pairing requires ctkd")
    }
}
