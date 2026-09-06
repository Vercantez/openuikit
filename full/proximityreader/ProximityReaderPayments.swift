import Foundation

// MARK: - PaymentCardReaderError

public enum PaymentCardReaderError: Error, Sendable {
    case serviceConnectionError
    case networkAuthenticationError
    case emptyReaderToken
    case invalidReaderToken(String?)
    case networkError
    case notAllowed
    case readerBusy
    case unsupported
    case deviceBanned(Date?)
    case tokenExpired
    case prepareFailed(String?)
    case prepareExpired
    case invalidMerchant
    case merchantBlocked
    case accountNotLinked
    case passcodeDisabled
    case readerMemoryFull
    case modelNotSupported
    case accountDeactivated
    case requestInterrupted
    case accountAlreadyLinked
    case accountLinkingFailed
    case osVersionNotSupported
    case accountLinkingCancelled
    case accountLinkingCheckFailed
    case storeAndForwardNotAllowed
    case backgroundRequestNotAllowed
    case storeAndForwardSessionExpired
    case storeAndForwardSessionInvalidated
    case storeAndForwardTokenIssuerChanged
    case accountLinkingRequiresiCloudSignIn
    case unknown(code: Int)
    case notReady

    public var errorName: String {
        switch self {
        case .serviceConnectionError: return "serviceConnectionError"
        case .networkAuthenticationError: return "networkAuthenticationError"
        case .emptyReaderToken: return "emptyReaderToken"
        case .invalidReaderToken: return "invalidReaderToken"
        case .networkError: return "networkError"
        case .notAllowed: return "notAllowed"
        case .readerBusy: return "readerBusy"
        case .unsupported: return "unsupported"
        case .deviceBanned: return "deviceBanned"
        case .tokenExpired: return "tokenExpired"
        case .prepareFailed: return "prepareFailed"
        case .prepareExpired: return "prepareExpired"
        case .invalidMerchant: return "invalidMerchant"
        case .merchantBlocked: return "merchantBlocked"
        case .accountNotLinked: return "accountNotLinked"
        case .passcodeDisabled: return "passcodeDisabled"
        case .readerMemoryFull: return "readerMemoryFull"
        case .modelNotSupported: return "modelNotSupported"
        case .accountDeactivated: return "accountDeactivated"
        case .requestInterrupted: return "requestInterrupted"
        case .accountAlreadyLinked: return "accountAlreadyLinked"
        case .accountLinkingFailed: return "accountLinkingFailed"
        case .osVersionNotSupported: return "osVersionNotSupported"
        case .accountLinkingCancelled: return "accountLinkingCancelled"
        case .accountLinkingCheckFailed: return "accountLinkingCheckFailed"
        case .storeAndForwardNotAllowed: return "storeAndForwardNotAllowed"
        case .backgroundRequestNotAllowed: return "backgroundRequestNotAllowed"
        case .storeAndForwardSessionExpired: return "storeAndForwardSessionExpired"
        case .storeAndForwardSessionInvalidated: return "storeAndForwardSessionInvalidated"
        case .storeAndForwardTokenIssuerChanged: return "storeAndForwardTokenIssuerChanged"
        case .accountLinkingRequiresiCloudSignIn: return "accountLinkingRequiresiCloudSignIn"
        case .unknown: return "unknown"
        case .notReady: return "notReady"
        }
    }

    public var errorDescription: String {
        "PaymentCardReaderError.\(errorName)"
    }

    public var localizedDescription: String { errorDescription }
}

// MARK: - PaymentCardReader

public class PaymentCardReader: @unchecked Sendable {
    public static let isSupported = false

    public final let id: String
    public final let options: Options
    public final let events: AsyncStream<Event>

    public init(options: PaymentCardReader.Options = .init()) {
        self.id = UUID().uuidString
        self.options = options
        let pair = AsyncStream.makeStream(of: Event.self)
        self.events = pair.stream
        pair.continuation.yield(.notReady)
        pair.continuation.finish()
    }

    public var readerIdentifier: String {
        get async throws {
            throw PaymentCardReaderError.unsupported
        }
    }

    public func fetchPaymentCardReaderStore() throws -> PaymentCardReaderStore {
        throw PaymentCardReaderError.unsupported
    }

    public func linkAccount(using token: PaymentCardReader.Token) async throws {
        _ = token
        throw PaymentCardReaderError.unsupported
    }

    public func relinkAccount(using token: PaymentCardReader.Token) async throws {
        _ = token
        throw PaymentCardReaderError.unsupported
    }

    public func isAccountLinked(using token: PaymentCardReader.Token) async throws -> Bool {
        _ = token
        throw PaymentCardReaderError.unsupported
    }

    public func prepareStoreAndForward() async throws -> StoreAndForwardPaymentCardReaderSession {
        throw PaymentCardReaderError.storeAndForwardNotAllowed
    }

    public func prepare(using token: PaymentCardReader.Token) async throws -> PaymentCardReaderSession {
        if token.rawValue.isEmpty {
            throw PaymentCardReaderError.emptyReaderToken
        }
        throw PaymentCardReaderError.unsupported
    }

    public func prepare(
        using token: PaymentCardReader.Token,
        updateHandler: ((PaymentCardReader.UpdateEvent) -> Void)?
    ) async throws -> PaymentCardReaderSession {
        updateHandler?(.notReady)
        return try await prepare(using: token)
    }

    public enum UpdateEvent: Sendable {
        case notReady
        case progress(Int)

        public var name: String {
            switch self {
            case .notReady: return "notReady"
            case .progress: return "progress"
            }
        }
    }

    public enum Event: Sendable {
        case removeCard
        case readyForTap
        case cardDetected
        case readCancelled
        case readCompleted
        case updateProgress(Int)
        case readNotCompleted
        case pinEntryCompleted
        case pinEntryRequested
        case userInterfaceDismissed
        case notReady
        case readRetry

        public var name: String {
            switch self {
            case .removeCard: return "removeCard"
            case .readyForTap: return "readyForTap"
            case .cardDetected: return "cardDetected"
            case .readCancelled: return "readCancelled"
            case .readCompleted: return "readCompleted"
            case .updateProgress: return "updateProgress"
            case .readNotCompleted: return "readNotCompleted"
            case .pinEntryCompleted: return "pinEntryCompleted"
            case .pinEntryRequested: return "pinEntryRequested"
            case .userInterfaceDismissed: return "userInterfaceDismissed"
            case .notReady: return "notReady"
            case .readRetry: return "readRetry"
            }
        }
    }

    public struct Token: RawRepresentable, Hashable, Sendable {
        public typealias RawValue = String
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(rawValue)
        }

        public var hashValue: Int {
            var hasher = Hasher()
            hash(into: &hasher)
            return hasher.finalize()
        }
    }

    public struct Options: Sendable {
        public var vasMerchants: [VASRequest.Merchant]
        public var includeErrorInReadResult: Bool
        public var returnReadResultImmediately: Bool

        public init() {
            self.vasMerchants = []
            self.includeErrorInReadResult = false
            self.returnReadResultImmediately = false
        }

        public init(vasMerchants: [VASRequest.Merchant] = []) {
            self.vasMerchants = vasMerchants
            self.includeErrorInReadResult = false
            self.returnReadResultImmediately = false
        }
    }
}

// MARK: - Store

public struct PaymentCardReaderStore: Sendable {
    public init() {}

    public enum StoreError: Error, Sendable {
        case networkError
        case notAllowed
        case passcodeDisabled
        case storeAndForwardBatchNotFound
        case storeAndForwardResultsNotFound
        case storeAndForwardBatchSizeInvalid
        case storeAndForwardBatchAlreadyExists
        case storeAndForwardDeletionTokenExpired
        case storeAndForwardDeletionTokenInvalid
        case busy
        case unknown(code: Int)

        public var localizedDescription: String {
            switch self {
            case .networkError: return "PaymentCardReaderStore.StoreError.networkError"
            case .notAllowed: return "PaymentCardReaderStore.StoreError.notAllowed"
            case .passcodeDisabled: return "PaymentCardReaderStore.StoreError.passcodeDisabled"
            case .storeAndForwardBatchNotFound: return "PaymentCardReaderStore.StoreError.storeAndForwardBatchNotFound"
            case .storeAndForwardResultsNotFound: return "PaymentCardReaderStore.StoreError.storeAndForwardResultsNotFound"
            case .storeAndForwardBatchSizeInvalid: return "PaymentCardReaderStore.StoreError.storeAndForwardBatchSizeInvalid"
            case .storeAndForwardBatchAlreadyExists: return "PaymentCardReaderStore.StoreError.storeAndForwardBatchAlreadyExists"
            case .storeAndForwardDeletionTokenExpired: return "PaymentCardReaderStore.StoreError.storeAndForwardDeletionTokenExpired"
            case .storeAndForwardDeletionTokenInvalid: return "PaymentCardReaderStore.StoreError.storeAndForwardDeletionTokenInvalid"
            case .busy: return "PaymentCardReaderStore.StoreError.busy"
            case .unknown(let code): return "PaymentCardReaderStore.StoreError.unknown(\(code))"
            }
        }
    }

    public func fetchStoredPaymentCardReadResultBatch(size: Int = 0) async throws -> StoreAndForwardBatch {
        _ = size
        throw StoreError.notAllowed
    }

    public func fetchStoredPaymentCardReadResultCount() async throws -> Int {
        throw StoreError.notAllowed
    }

    public func resolveBatch(batchDeletionToken: StoreAndForwardBatchDeletionToken) async throws -> Int {
        _ = batchDeletionToken
        throw StoreError.notAllowed
    }

    public func resetBatchState() async throws {
        throw StoreError.notAllowed
    }
}

public struct StoreAndForwardBatchDeletionToken: RawRepresentable, Hashable, Sendable {
    public typealias RawValue = String
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }
}

public struct StoreAndForwardBatch: Encodable, Sendable {
    public typealias ID = String
    public let id: String
    public let count: Int
    public let payments: [StoredPaymentCardReadResult]
    public let signature: String
    public let leafCertificate: String
    public let intermediateCertificate: [String]

    public init(
        id: String,
        payments: [StoredPaymentCardReadResult],
        signature: String,
        leafCertificate: String,
        intermediateCertificate: [String]
    ) {
        self.id = id
        self.count = payments.count
        self.payments = payments
        self.signature = signature
        self.leafCertificate = leafCertificate
        self.intermediateCertificate = intermediateCertificate
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(count, forKey: .count)
        try container.encode(payments, forKey: .payments)
        try container.encode(signature, forKey: .signature)
        try container.encode(leafCertificate, forKey: .leafCertificate)
        try container.encode(intermediateCertificate, forKey: .intermediateCertificate)
    }

    private enum CodingKeys: String, CodingKey {
        case id, count, payments, signature, leafCertificate, intermediateCertificate
    }

    public struct StoredPaymentCardReadResult: Encodable, Identifiable, Sendable {
        public typealias ID = String
        public let id: String
        public let generalCardData: String
        public let paymentCardData: String
        public let signature: String

        public init(id: String, generalCardData: String, paymentCardData: String, signature: String) {
            self.id = id
            self.generalCardData = generalCardData
            self.paymentCardData = paymentCardData
            self.signature = signature
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(generalCardData, forKey: .generalCardData)
            try container.encode(paymentCardData, forKey: .paymentCardData)
            try container.encode(signature, forKey: .signature)
        }

        private enum CodingKeys: String, CodingKey {
            case id, generalCardData, paymentCardData, signature
        }
    }
}

public struct StoreAndForwardStatus: Hashable, Sendable {
    public let expiration: Date
    public let readCount: Int

    public init(expiration: Date, readCount: Int) {
        self.expiration = expiration
        self.readCount = readCount
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(expiration)
        hasher.combine(readCount)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }
}

public class StoreAndForwardPaymentCardReaderSession: @unchecked Sendable {
    public init() {}

    public func status() async throws -> StoreAndForwardStatus {
        throw PaymentCardReaderError.storeAndForwardNotAllowed
    }

    public func decline() async throws {
        throw PaymentCardReaderError.storeAndForwardNotAllowed
    }
}

// MARK: - Session

public class PaymentCardReaderSession: @unchecked Sendable {
    public final let id: String
    public final let currentOSVersionDeprecationDate: Date?

    public init() {
        self.id = UUID().uuidString
        self.currentOSVersionDeprecationDate = nil
    }

    public func readPaymentCard(
        _ request: PaymentCardTransactionRequest,
        vasRequest: VASRequest,
        stopOnVASResult: Bool,
        eventHandler: ((PaymentCardReaderSession.Event) -> Void)? = nil
    ) async throws -> (PaymentCardReadResult?, VASReadResult?) {
        _ = request
        _ = vasRequest
        _ = stopOnVASResult
        eventHandler?(.readNotCompleted)
        throw ReadError.readerNotAvailable
    }

    public func readPaymentCard(
        _ request: PaymentCardTransactionRequest,
        vasRequest: VASRequest,
        stopOnVASResult: Bool
    ) async throws -> (PaymentCardReadResult?, VASReadResult?) {
        try await readPaymentCard(request, vasRequest: vasRequest, stopOnVASResult: stopOnVASResult, eventHandler: nil)
    }

    public func readPaymentCard(
        _ request: PaymentCardTransactionRequest,
        eventHandler: ((PaymentCardReaderSession.Event) -> Void)? = nil
    ) async throws -> PaymentCardReadResult {
        _ = request
        eventHandler?(.readNotCompleted)
        throw ReadError.readerNotAvailable
    }

    public func readPaymentCard(
        _ request: PaymentCardVerificationRequest,
        eventHandler: ((PaymentCardReaderSession.Event) -> Void)? = nil
    ) async throws -> PaymentCardReadResult {
        _ = request
        eventHandler?(.readNotCompleted)
        throw ReadError.readerNotAvailable
    }

    public func readPaymentCard(_ request: PaymentCardTransactionRequest) async throws -> PaymentCardReadResult {
        try await readPaymentCard(request, eventHandler: nil)
    }

    public func readPaymentCard(_ request: PaymentCardVerificationRequest) async throws -> PaymentCardReadResult {
        try await readPaymentCard(request, eventHandler: nil)
    }

    public func cancelRead() async throws -> Bool {
        throw ReadError.noReaderSession
    }

    public func capturePIN(
        using token: PaymentCardReaderSession.PINToken,
        cardReaderTransactionID: String
    ) async throws -> PaymentCardReadResult {
        _ = token
        _ = cardReaderTransactionID
        throw ReadError.pinNotAllowed
    }

    public func readVAS(
        _ request: VASRequest,
        eventHandler: ((PaymentCardReaderSession.Event) -> Void)? = nil
    ) async throws -> VASReadResult {
        _ = request
        eventHandler?(.readNotCompleted)
        throw ReadError.vasReadFail
    }

    public func readVAS(_ request: VASRequest) async throws -> VASReadResult {
        try await readVAS(request, eventHandler: nil)
    }

    public enum Event: Hashable, Sendable {
        case removeCard
        case readyForTap
        case cardDetected
        case readCancelled
        case readNotCompleted
        case retry
        case completed

        public var name: String {
            switch self {
            case .removeCard: return "removeCard"
            case .readyForTap: return "readyForTap"
            case .cardDetected: return "cardDetected"
            case .readCancelled: return "readCancelled"
            case .readNotCompleted: return "readNotCompleted"
            case .retry: return "retry"
            case .completed: return "completed"
            }
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(name)
        }

        public var hashValue: Int {
            var hasher = Hasher()
            hash(into: &hasher)
            return hasher.finalize()
        }
    }

    public struct PINToken: RawRepresentable, Hashable, Sendable {
        public typealias RawValue = String
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(rawValue)
        }

        public var hashValue: Int {
            var hasher = Hasher()
            hash(into: &hasher)
            return hasher.finalize()
        }
    }

    public enum ReadError: Error, Sendable {
        case readerServiceError
        case readFromBackgroundError
        case readerServiceConnectionError
        case noReaderSession
        case vasReadFail
        case cardReadFailed
        case readerSessionBusy
        case readerSessionExpired
        case readerSessionAuthenticationError
        case readerSessionNetworkError
        case paymentCardDeclined
        case paymentReadFailed
        case nfcDisabled
        case pinCancelled
        case invalidAmount
        case pinNotAllowed
        case readCancelled
        case pinEntryFailed
        case readNotAllowed
        case pinEntryTimeout
        case pinTokenInvalid
        case cardNotSupported
        case passcodeDisabled
        case readerNotAvailable
        case readerTokenExpired
        case invalidCurrencyCode
        case invalidPreferredAID
        case invalidVASMerchants(String?)
        case readNotAllowedDuringCall
        case readerInitializationFailed
        case invalidVASRequestParameters(String?)
        case storeAndForwardDeclineFailed
        case storeAndForwardResultNotFound
        case unknown(code: Int)

        public var errorName: String {
            switch self {
            case .readerServiceError: return "readerServiceError"
            case .readFromBackgroundError: return "readFromBackgroundError"
            case .readerServiceConnectionError: return "readerServiceConnectionError"
            case .noReaderSession: return "noReaderSession"
            case .vasReadFail: return "vasReadFail"
            case .cardReadFailed: return "cardReadFailed"
            case .readerSessionBusy: return "readerSessionBusy"
            case .readerSessionExpired: return "readerSessionExpired"
            case .readerSessionAuthenticationError: return "readerSessionAuthenticationError"
            case .readerSessionNetworkError: return "readerSessionNetworkError"
            case .paymentCardDeclined: return "paymentCardDeclined"
            case .paymentReadFailed: return "paymentReadFailed"
            case .nfcDisabled: return "nfcDisabled"
            case .pinCancelled: return "pinCancelled"
            case .invalidAmount: return "invalidAmount"
            case .pinNotAllowed: return "pinNotAllowed"
            case .readCancelled: return "readCancelled"
            case .pinEntryFailed: return "pinEntryFailed"
            case .readNotAllowed: return "readNotAllowed"
            case .pinEntryTimeout: return "pinEntryTimeout"
            case .pinTokenInvalid: return "pinTokenInvalid"
            case .cardNotSupported: return "cardNotSupported"
            case .passcodeDisabled: return "passcodeDisabled"
            case .readerNotAvailable: return "readerNotAvailable"
            case .readerTokenExpired: return "readerTokenExpired"
            case .invalidCurrencyCode: return "invalidCurrencyCode"
            case .invalidPreferredAID: return "invalidPreferredAID"
            case .invalidVASMerchants: return "invalidVASMerchants"
            case .readNotAllowedDuringCall: return "readNotAllowedDuringCall"
            case .readerInitializationFailed: return "readerInitializationFailed"
            case .invalidVASRequestParameters: return "invalidVASRequestParameters"
            case .storeAndForwardDeclineFailed: return "storeAndForwardDeclineFailed"
            case .storeAndForwardResultNotFound: return "storeAndForwardResultNotFound"
            case .unknown: return "unknown"
            }
        }

        public var errorDescription: String { "PaymentCardReaderSession.ReadError.\(errorName)" }
        public var localizedDescription: String { errorDescription }
    }
}

// MARK: - VAS

public class VASRequest: @unchecked Sendable {
    public final let vasMerchants: [Merchant]
    public final let localizedVASType: String
    public var userInterfaceLanguage: Locale.Language?

    public init(vasMerchants: [VASRequest.Merchant] = [], localizedVASType: String = "") {
        self.vasMerchants = vasMerchants
        self.localizedVASType = localizedVASType
        self.userInterfaceLanguage = nil
    }

    public struct Merchant: Identifiable, Hashable, Sendable {
        public typealias ID = String
        public let id: String
        public let url: URL?
        public let shouldSendURLOnly: Bool
        public var localizedName: String

        public init(id: String, url: URL? = nil, localizedName: String? = nil) {
            self.id = id
            self.url = url
            self.shouldSendURLOnly = false
            self.localizedName = localizedName ?? ""
        }

        public init(id: String, url: URL? = nil, shouldSendURLOnly: Bool = false, localizedName: String? = nil) {
            self.id = id
            self.url = url
            self.shouldSendURLOnly = shouldSendURLOnly
            self.localizedName = localizedName ?? ""
        }
    }
}

public struct VASReadResult: Identifiable, Sendable {
    public typealias ID = String
    public let id: String
    public let entries: [ReadEntry]

    public init(id: String, entries: [VASReadResult.ReadEntry]) {
        self.id = id
        self.entries = entries
    }

    public struct ReadEntry: Identifiable, Sendable {
        public typealias ID = String
        public let id: String
        public let customerVASData: Data?
        public let status: Status

        public init(id: String, customerVASData: Data?, status: Status) {
            self.id = id
            self.customerVASData = customerVASData
            self.status = status
        }

        /// Sequential raw values follow the pinned API-digester child order
        /// (success = 0 … unsupportedApplicationVersion = 7). Apple's NFC
        /// status-word mapping is unobserved; see oracle-questions.tsv.
        public enum Status: Int, Hashable, Sendable {
            case success = 0
            case vasDataNotFound = 1
            case vasDataNotActivated = 2
            case wrongP1P2 = 3
            case wrongCommandLength = 4
            case userInterventionRequired = 5
            case incorrectData = 6
            case unsupportedApplicationVersion = 7

            public typealias RawValue = Int

            public func hash(into hasher: inout Hasher) {
                hasher.combine(rawValue)
            }

            public var hashValue: Int {
                var hasher = Hasher()
                hash(into: &hasher)
                return hasher.finalize()
            }
        }
    }
}

// MARK: - Read result and transaction requests

public struct PaymentCardReadResult: Identifiable, Sendable {
    public typealias ID = String
    public let id: String
    public let generalCardData: String?
    public let paymentCardData: String?
    public let pinBypassed: Bool
    public let isPINFallback: Bool
    public let cardEffectiveState: CardEffectiveState?
    public let cardExpirationState: CardExpirationState?
    public let applicationTypeIdentifier: String?
    public let outcome: ReadOutcome

    public init(
        id: String,
        generalCardData: String? = nil,
        paymentCardData: String? = nil,
        pinBypassed: Bool = false,
        isPINFallback: Bool = false,
        cardEffectiveState: CardEffectiveState? = nil,
        cardExpirationState: CardExpirationState? = nil,
        applicationTypeIdentifier: String? = nil,
        outcome: ReadOutcome
    ) {
        self.id = id
        self.generalCardData = generalCardData
        self.paymentCardData = paymentCardData
        self.pinBypassed = pinBypassed
        self.isPINFallback = isPINFallback
        self.cardEffectiveState = cardEffectiveState
        self.cardExpirationState = cardExpirationState
        self.applicationTypeIdentifier = applicationTypeIdentifier
        self.outcome = outcome
    }

    public enum CardEffectiveState: Hashable, Sendable {
        case active
        case invalid
        case unknown
        case inactive

        public func hash(into hasher: inout Hasher) {
            hasher.combine(String(describing: self))
        }

        public var hashValue: Int {
            var hasher = Hasher()
            hash(into: &hasher)
            return hasher.finalize()
        }
    }

    public enum CardExpirationState: Hashable, Sendable {
        case notExpired
        case expired
        case invalid
        case unknown

        public func hash(into hasher: inout Hasher) {
            hasher.combine(String(describing: self))
        }

        public var hashValue: Int {
            var hasher = Hasher()
            hash(into: &hasher)
            return hasher.finalize()
        }
    }

    public enum ReadOutcome: Hashable, Sendable {
        case cardDeclined
        case failure
        case success

        public func hash(into hasher: inout Hasher) {
            hasher.combine(String(describing: self))
        }

        public var hashValue: Int {
            var hasher = Hasher()
            hash(into: &hasher)
            return hasher.finalize()
        }
    }
}

public struct PaymentCardTransactionRequest: Sendable {
    public let amount: Decimal
    public let currencyCode: String
    public let type: TransactionType
    public var preferredAIDList: [Data]
    public var useISOCurrencySymbol: Bool
    public var userInterfaceLanguage: Locale.Language?
    public var transactionDescription: TransactionAmountDescription?

    public init(
        amount: Decimal,
        currencyCode: String,
        for type: PaymentCardTransactionRequest.TransactionType = .purchase
    ) {
        self.amount = amount
        self.currencyCode = currencyCode
        self.type = type
        self.preferredAIDList = []
        self.useISOCurrencySymbol = false
        self.userInterfaceLanguage = nil
        self.transactionDescription = nil
    }

    public enum PaymentCycle: Hashable, Sendable {
        case weekly
        case yearly
        case monthly

        public func hash(into hasher: inout Hasher) {
            hasher.combine(String(describing: self))
        }

        public var hashValue: Int {
            var hasher = Hasher()
            hash(into: &hasher)
            return hasher.finalize()
        }
    }

    public enum TransactionType: Hashable, Sendable {
        case refund
        case purchase

        public func hash(into hasher: inout Hasher) {
            hasher.combine(String(describing: self))
        }

        public var hashValue: Int {
            var hasher = Hasher()
            hash(into: &hasher)
            return hasher.finalize()
        }
    }

    public enum TransactionAmountDescription: Sendable {
        case preauthorizationAmount(Decimal)
        case surchargeAmount(Decimal)
        case membership(PaymentCardTransactionRequest.PaymentCycle)
        case installment(PaymentCardTransactionRequest.PaymentCycle, amount: Decimal, payments: Int)
        case preauthorization
        case surchargePercent(Double)
        case preauthorizationRelease
    }
}

public struct PaymentCardVerificationRequest: Sendable {
    public let currencyCode: String
    public let verificationReason: Reason
    public var userInterfaceLanguage: Locale.Language?

    public init(currencyCode: String, for reason: PaymentCardVerificationRequest.Reason = .other) {
        self.currencyCode = currencyCode
        self.verificationReason = reason
        self.userInterfaceLanguage = nil
    }

    public enum Reason: Hashable, Sendable {
        case saveCard
        case other
        case lookUp
        case openTab

        public func hash(into hasher: inout Hasher) {
            hasher.combine(String(describing: self))
        }

        public var hashValue: Int {
            var hasher = Hasher()
            hash(into: &hasher)
            return hasher.finalize()
        }
    }
}
