@_exported import Foundation

/// Linux starting point for Apple's public `PassKit` module.
///
/// Stored-ZIP `pass.json` parsing, in-process payment-request models, pass
/// identity fields, option sets, and fail-closed Wallet / Apple Pay
/// presentation are real on this isolated host. CMS signature checks, the
/// pass library, Apple Pay authorization UI, identity documents, and
/// Wallet chrome are unavailable: those APIs throw `PKPassKitError`,
/// return `false`/`nil`/empty, or never present chrome. Nothing here is a
/// claim of Apple service, entitlement, or UI parity.

public struct PassKitPortableError: Error, Equatable, Sendable,
    CustomStringConvertible
{
    public enum Code: Int, Sendable {
        case passValidationUnavailable = 1
        case passLibraryUnavailable = 2
        case paymentsUnavailable = 3
    }

    public let code: Code
    public let description: String

    public init(_ code: Code) {
        self.code = code
        switch code {
        case .passValidationUnavailable:
            description = "Pass validation is unavailable on this host"
        case .passLibraryUnavailable:
            description = "Pass library is unavailable on this host"
        case .paymentsUnavailable:
            description = "Apple Pay is unavailable on this host"
        }
    }
}

open class PKObject: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }
}

open class PKPass: PKObject, @unchecked Sendable {
    public let passURL: URL?
    public let serialNumber: String
    public let passTypeIdentifier: String
    public private(set) var authenticationToken: String?
    public var deviceName: String = ""
    /// Fail-closed: `icon.png` in the archive is not decoded (no image pipeline
    /// on this Foundation host). Always an empty `UIImage`.
    public var icon: UIImage = UIImage()
    public private(set) var localizedDescription: String = ""
    public private(set) var localizedName: String = ""
    public private(set) var organizationName: String = ""
    public var passType: PKPassType = .barcode
    public var paymentPass: PKPaymentPass? { self as? PKPaymentPass }
    public private(set) var relevantDate: Date?
    public private(set) var relevantDates: [PKPassRelevantDate] = []
    public var isRemotePass = false
    public var secureElementPass: PKSecureElementPass? { self as? PKSecureElementPass }
    public private(set) var userInfo: [AnyHashable: Any]?
    public private(set) var webServiceURL: URL?
    var fieldValues: [String: Any] = [:]

    public init(data: Data) throws {
        // Stored ZIP + pass.json keys from Apple's Wallet Package Format.
        // `manifest.json` SHA-1s are checked when present. A PKCS#7
        // `signature` is fail-closed (`invalidSignature`); CMS/WWDR is
        // unobserved (oracle-questions.tsv). Deflated archives throw
        // invalidDataError.
        let manifest = try PassKitPassArchive.parse(data)
        serialNumber = manifest.serialNumber
        passTypeIdentifier = manifest.passTypeIdentifier
        passURL = nil
        super.init()
        authenticationToken = manifest.authenticationToken
        localizedDescription = manifest.localizedDescription
        localizedName = manifest.localizedName
        organizationName = manifest.organizationName
        relevantDate = manifest.relevantDate
        relevantDates = manifest.relevantDates
        userInfo = manifest.userInfo
        webServiceURL = manifest.webServiceURL
        fieldValues = manifest.fieldValues
        isRemotePass = false
        deviceName = ""
        passType = .barcode
        icon = UIImage()
    }

    internal init(
        portableSerialNumber: String,
        passTypeIdentifier: String,
        passURL: URL? = nil
    ) {
        serialNumber = portableSerialNumber
        self.passTypeIdentifier = passTypeIdentifier
        self.passURL = passURL
        super.init()
    }

    public func localizedValue(forFieldKey key: String) -> Any? {
        fieldValues[key]
    }

    public override init() {
        serialNumber = ""
        passTypeIdentifier = ""
        passURL = nil
        super.init()
    }
}

public final class PKPassLibrary: NSObject, @unchecked Sendable {
    public enum AuthorizationStatus: Int, Hashable, Sendable {
        case notDetermined = -1
        case denied = 0
        case authorized = 1
        case restricted = 2
    }

    public enum Capability: Int, Hashable, Sendable {
        case backgroundAddPasses = 0
    }

    /// In-process barcode pass store. Not Apple Wallet: `isPassLibraryAvailable()`
    /// stays `false` (no Secure Element / entitlement). `add`/`remove`/`contains`
    /// / `passes(of:)` operate on this host table.
    private static let hostStoreLock = NSLock()
    private static var hostPasses: [String: PKPass] = [:]

    private static func hostKey(for pass: PKPass) -> String? {
        hostKey(passTypeIdentifier: pass.passTypeIdentifier, serialNumber: pass.serialNumber)
    }

    private static func hostKey(passTypeIdentifier: String, serialNumber: String) -> String? {
        guard !passTypeIdentifier.isEmpty, !serialNumber.isEmpty else { return nil }
        return passTypeIdentifier + "\u{1e}" + serialNumber
    }

    @discardableResult
    private static func withHostStore<T>(_ body: (inout [String: PKPass]) -> T) -> T {
        hostStoreLock.lock()
        defer { hostStoreLock.unlock() }
        return body(&hostPasses)
    }

    public var remoteSecureElementPasses: [PKSecureElementPass] { [] }
    public var isSecureElementPassActivationAvailable: Bool { false }

    public override init() {
        super.init()
    }

    /// Apple Wallet / Secure Element is not available on this isolated host.
    public static func isPassLibraryAvailable() -> Bool { false }
    public static func isPaymentPassActivationAvailable() -> Bool { false }
    public static func isSuppressingAutomaticPassPresentation() -> Bool { false }

    public static func requestAutomaticPassPresentationSuppression(
        responseHandler: @escaping (PKAutomaticPassPresentationSuppressionResult) -> Void
    ) -> PKSuppressionRequestToken {
        responseHandler(.notSupported)
        return 0
    }

    public static func endAutomaticPassPresentationSuppression(
        withRequestToken requestToken: PKSuppressionRequestToken
    ) {
        _ = requestToken
    }

    public func containsPass(_ pass: PKPass) -> Bool {
        guard let key = Self.hostKey(for: pass) else { return false }
        return Self.withHostStore { $0[key] != nil }
    }

    public func passes() -> [PKPass] {
        Self.withHostStore { Array($0.values) }
    }

    public func passes(of passType: PKPassType) -> [PKPass] {
        let all = passes()
        if passType == .any {
            return all
        }
        return all.filter { $0.passType == passType }
    }

    public func passes(withReaderIdentifier readerIdentifier: String) -> Set<PKSecureElementPass> {
        _ = readerIdentifier
        return []
    }

    public func pass(
        withPassTypeIdentifier identifier: String,
        serialNumber: String
    ) -> PKPass? {
        guard let key = Self.hostKey(passTypeIdentifier: identifier, serialNumber: serialNumber) else {
            return nil
        }
        return Self.withHostStore { $0[key] }
    }

    private func addPassesToHostStore(_ passes: [PKPass]) -> PKPassLibraryAddPassesStatus {
        var added = 0
        Self.withHostStore { store in
            for pass in passes {
                guard let key = Self.hostKey(for: pass) else { continue }
                store[key] = pass
                added += 1
            }
        }
        // Empty / identity-less payloads match the first-pass cancelled add.
        return added == 0 ? .didCancelAddPasses : .didAddPasses
    }

    public func addPasses(
        _ passes: [PKPass],
        withCompletionHandler completion: ((PKPassLibraryAddPassesStatus) -> Void)? = nil
    ) {
        completion?(addPassesToHostStore(passes))
    }

    public func addPasses(_ passes: [PKPass]) async -> PKPassLibraryAddPassesStatus {
        addPassesToHostStore(passes)
    }

    public func removePass(_ pass: PKPass) {
        guard let key = Self.hostKey(for: pass) else { return }
        Self.withHostStore { store in
            store.removeValue(forKey: key)
        }
    }

    public func replacePass(with pass: PKPass) -> Bool {
        guard let key = Self.hostKey(for: pass) else { return false }
        return Self.withHostStore { store in
            guard store[key] != nil else { return false }
            store[key] = pass
            return true
        }
    }

    public func canAddFelicaPass() -> Bool { false }

    public func canAddPaymentPass(withPrimaryAccountIdentifier primaryAccountIdentifier: String) -> Bool {
        _ = primaryAccountIdentifier
        return false
    }

    public func canAddSecureElementPass(primaryAccountIdentifier: String) -> Bool {
        _ = primaryAccountIdentifier
        return false
    }

    public func isPaymentPassActivationAvailable() -> Bool { false }

    public func openPaymentSetup() {}

    public func present(_ pass: PKPaymentPass) { _ = pass }
    public func present(_ pass: PKSecureElementPass) { _ = pass }

    public func remotePaymentPasses() -> [PKPaymentPass] { [] }

    public func authorizationStatus(for capability: Capability) -> AuthorizationStatus {
        _ = capability
        return .denied
    }

    public func requestAuthorization(for capability: Capability) async -> AuthorizationStatus {
        _ = capability
        return .denied
    }

    public func activate(
        _ paymentPass: PKPaymentPass,
        withActivationCode activationCode: String,
        completion: ((Bool, any Error) -> Void)? = nil
    ) {
        _ = (paymentPass, activationCode)
        completion?(false, PKPassKitError(.notEntitledError))
    }

    public func activate(
        _ paymentPass: PKPaymentPass,
        withActivationData activationData: Data,
        completion: ((Bool, any Error) -> Void)? = nil
    ) {
        _ = (paymentPass, activationData)
        completion?(false, PKPassKitError(.notEntitledError))
    }

    public func activate(
        _ secureElementPass: PKSecureElementPass,
        activationData: Data
    ) async throws -> Bool {
        _ = (secureElementPass, activationData)
        throw PKPassKitError(.notEntitledError)
    }

    public func encryptedServiceProviderData(
        for secureElementPass: PKSecureElementPass
    ) async throws -> [AnyHashable: Any] {
        _ = secureElementPass
        throw PKPassKitError(.notEntitledError)
    }

    public func serviceProviderData(
        for secureElementPass: PKSecureElementPass
    ) async throws -> Data {
        _ = secureElementPass
        throw PKPassKitError(.notEntitledError)
    }

    public func sign(
        _ signData: Data,
        using secureElementPass: PKSecureElementPass
    ) async throws -> (Data, Data) {
        _ = (signData, secureElementPass)
        throw PKPassKitError(.notEntitledError)
    }
}

@MainActor
public protocol PKAddPassesViewControllerDelegate: AnyObject {
    func addPassesViewControllerDidFinish(
        _ controller: PKAddPassesViewController
    )
}

@MainActor
open class PKAddPassesViewController: UIViewController, @unchecked Sendable {
    public weak var delegate: (any PKAddPassesViewControllerDelegate)?
    public let passes: [PKPass]

    public static func canAddPasses() -> Bool { false }

    public init?(pass: PKPass) {
        passes = [pass]
        super.init(nibName: nil, bundle: nil)
        return nil
    }

    public init?(passes: [PKPass]) {
        self.passes = passes
        super.init(nibName: nil, bundle: nil)
        return nil
    }

    public init(issuerData: Data, signature: Data) throws {
        _ = (issuerData, signature)
        passes = []
        super.init(nibName: nil, bundle: nil)
        // Seed lists Foundation only; no UIKit sheet. Issuer provisioning
        // is entitlement-gated and fails closed.
        throw PKPassKitError(.notEntitledError)
    }

    public override init() {
        passes = []
        super.init()
    }
}

public struct PKPaymentNetwork: RawRepresentable, Hashable, Sendable,
    ExpressibleByStringLiteral
{
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { rawValue = value }

    public static let amex = PKPaymentNetwork(rawValue: "AmEx")
    public static let bancomat = PKPaymentNetwork(rawValue: "Bancomat")
    public static let bancontact = PKPaymentNetwork(rawValue: "Bancontact")
    public static let bankAxept = PKPaymentNetwork(rawValue: "BankAxept")
    public static let barcode = PKPaymentNetwork(rawValue: "Barcode")
    public static let carteBancaire = PKPaymentNetwork(rawValue: "CarteBancaire")
    public static let carteBancaires = PKPaymentNetwork(rawValue: "CarteBancaires")
    public static let cartesBancaires = PKPaymentNetwork(rawValue: "CartesBancaires")
    public static let chinaUnionPay = PKPaymentNetwork(rawValue: "ChinaUnionPay")
    public static let dankort = PKPaymentNetwork(rawValue: "Dankort")
    public static let discover = PKPaymentNetwork(rawValue: "Discover")
    public static let eftpos = PKPaymentNetwork(rawValue: "Eftpos")
    public static let electron = PKPaymentNetwork(rawValue: "Electron")
    public static let elo = PKPaymentNetwork(rawValue: "Elo")
    public static let girocard = PKPaymentNetwork(rawValue: "Girocard")
    public static let himyan = PKPaymentNetwork(rawValue: "Himyan")
    public static let idCredit = PKPaymentNetwork(rawValue: "IDCredit")
    public static let interac = PKPaymentNetwork(rawValue: "Interac")
    public static let JCB = PKPaymentNetwork(rawValue: "JCB")
    public static let jaywan = PKPaymentNetwork(rawValue: "Jaywan")
    public static let mada = PKPaymentNetwork(rawValue: "Mada")
    public static let maestro = PKPaymentNetwork(rawValue: "Maestro")
    public static let masterCard = PKPaymentNetwork(rawValue: "MasterCard")
    public static let meeza = PKPaymentNetwork(rawValue: "Meeza")
    public static let mir = PKPaymentNetwork(rawValue: "Mir")
    public static let myDebit = PKPaymentNetwork(rawValue: "MyDebit")
    public static let NAPAS = PKPaymentNetwork(rawValue: "NAPAS")
    public static let nanaco = PKPaymentNetwork(rawValue: "Nanaco")
    public static let pagoBancomat = PKPaymentNetwork(rawValue: "PagoBancomat")
    public static let postFinance = PKPaymentNetwork(rawValue: "PostFinance")
    public static let privateLabel = PKPaymentNetwork(rawValue: "PrivateLabel")
    public static let quicPay = PKPaymentNetwork(rawValue: "QuicPay")
    public static let suica = PKPaymentNetwork(rawValue: "Suica")
    public static let tmoney = PKPaymentNetwork(rawValue: "Tmoney")
    public static let vPay = PKPaymentNetwork(rawValue: "VPay")
    public static let visa = PKPaymentNetwork(rawValue: "Visa")
    public static let waon = PKPaymentNetwork(rawValue: "Waon")
}

public struct PKMerchantCapability: OptionSet, Hashable, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let threeDSecure = PKMerchantCapability(rawValue: 1 << 0)
    public static let emv = PKMerchantCapability(rawValue: 1 << 1)
    public static let credit = PKMerchantCapability(rawValue: 1 << 2)
    public static let debit = PKMerchantCapability(rawValue: 1 << 3)
    public static let instantFundsOut = PKMerchantCapability(rawValue: 1 << 7)
    public static var capability3DS: PKMerchantCapability { .threeDSecure }
    public static var capabilityEMV: PKMerchantCapability { .emv }
    public static var capabilityCredit: PKMerchantCapability { .credit }
    public static var capabilityDebit: PKMerchantCapability { .debit }
}

public enum PKPaymentSummaryItemType: Int, Hashable, Sendable {
    case final = 0
    case pending = 1
}

open class PKPaymentSummaryItem: NSObject, @unchecked Sendable {
    public var label: String
    public var amount: NSDecimalNumber
    public var type: PKPaymentSummaryItemType

    public init(
        label: String,
        amount: NSDecimalNumber,
        type: PKPaymentSummaryItemType = .final
    ) {
        self.label = label
        self.amount = amount
        self.type = type
        super.init()
    }

    public convenience init(label: String, amount: NSDecimalNumber) {
        self.init(label: label, amount: amount, type: .final)
    }

    public convenience init(
        label: String,
        amount: Decimal,
        type: PKPaymentSummaryItemType = .final
    ) {
        self.init(label: label, amount: NSDecimalNumber(decimal: amount), type: type)
    }

    public override init() {
        label = ""
        amount = 0
        type = .final
        super.init()
    }
}

public final class PKRecurringPaymentSummaryItem: PKPaymentSummaryItem, @unchecked Sendable {
    public var intervalUnit: NSCalendar.Unit = .month
    public var intervalCount = 1
    public var startDate: Date?
    public var endDate: Date?
}

open class PKPaymentRequest: NSObject, @unchecked Sendable {
    public struct MerchantCategoryCode: RawRepresentable, Hashable, Sendable, Codable, CustomStringConvertible {
        public typealias RawValue = Int16
        public let rawValue: Int16
        public init(rawValue: Int16) { self.rawValue = rawValue }
        public init?(_ description: String) {
            guard let value = Int16(description) else { return nil }
            rawValue = value
        }
        public var description: String { String(rawValue) }
    }

    public enum ApplePayLaterAvailability: Hashable, Sendable {
        public enum Reason: Hashable, Sendable {
            case itemIneligible
            case recurringTransaction
        }
        case available
        case unavailable(Reason)
    }

    public var merchantIdentifier = ""
    public var countryCode = ""
    public var currencyCode = ""
    public var merchantCapabilities: PKMerchantCapability = []
    public var supportedNetworks: [PKPaymentNetwork] = []
    public var paymentSummaryItems: [PKPaymentSummaryItem] = []
    public var requiredBillingContactFields: Set<PKContactField> = []
    public var requiredShippingContactFields: Set<PKContactField> = []
    public var requiredBillingAddressFields: PKAddressField = []
    public var requiredShippingAddressFields: PKAddressField = []
    public var applicationData: Data?
    public var attributionIdentifier: String?
    public var automaticReloadPaymentRequest: PKAutomaticReloadPaymentRequest?
    public var billingAddress: ABRecord?
    public var billingContact: PKContact?
    public var couponCode: String?
    public var deferredPaymentRequest: PKDeferredPaymentRequest?
    public var multiTokenContexts: [PKPaymentTokenContext] = []
    public var recurringPaymentRequest: PKRecurringPaymentRequest?
    public var shippingAddress: ABRecord?
    public var shippingContact: PKContact?
    public var shippingContactEditingMode: PKShippingContactEditingMode = .enabled
    public var shippingMethods: [PKShippingMethod]?
    public var shippingType: PKShippingType = .shipping
    public var supportedCountries: Set<String>?
    public var supportsCouponCode = false
    public var merchantCategoryCode: MerchantCategoryCode?
    public var applePayLaterAvailability: ApplePayLaterAvailability = .available

    public override init() {
        super.init()
    }

    public static func availableNetworks() -> [PKPaymentNetwork] { [] }

    public static func paymentBillingAddressInvalidError(
        withKey postalAddressKey: String,
        localizedDescription: String?
    ) -> any Error {
        PKPaymentError(
            .billingContactInvalidError,
            userInfo: [
                PKPaymentErrorKey.postalAddressUserInfoKey.rawValue: postalAddressKey,
                NSLocalizedDescriptionKey: localizedDescription ?? "",
            ]
        )
    }

    public static func paymentContactInvalidError(
        withContactField field: PKContactField,
        localizedDescription: String?
    ) -> any Error {
        PKPaymentError(
            .shippingContactInvalidError,
            userInfo: [
                PKPaymentErrorKey.contactFieldUserInfoKey.rawValue: field.rawValue,
                NSLocalizedDescriptionKey: localizedDescription ?? "",
            ]
        )
    }

    public static func paymentShippingAddressInvalidError(
        withKey postalAddressKey: String,
        localizedDescription: String?
    ) -> any Error {
        PKPaymentError(
            .shippingContactInvalidError,
            userInfo: [
                PKPaymentErrorKey.postalAddressUserInfoKey.rawValue: postalAddressKey,
                NSLocalizedDescriptionKey: localizedDescription ?? "",
            ]
        )
    }

    public static func paymentShippingAddressUnserviceableError(
        withLocalizedDescription localizedDescription: String?
    ) -> any Error {
        PKPaymentError(
            .shippingAddressUnserviceableError,
            userInfo: [NSLocalizedDescriptionKey: localizedDescription ?? ""]
        )
    }

    public static func paymentCouponCodeInvalidError(
        localizedDescription: String? = nil
    ) -> any Error {
        PKPaymentError(
            .couponCodeInvalidError,
            userInfo: [NSLocalizedDescriptionKey: localizedDescription ?? ""]
        )
    }

    public static func paymentCouponCodeExpiredError(
        localizedDescription: String? = nil
    ) -> any Error {
        PKPaymentError(
            .couponCodeExpiredError,
            userInfo: [NSLocalizedDescriptionKey: localizedDescription ?? ""]
        )
    }
}

public struct PKContactField: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let postalAddress = PKContactField(rawValue: "postalAddress")
    public static let emailAddress = PKContactField(rawValue: "emailAddress")
    public static let phoneNumber = PKContactField(rawValue: "phoneNumber")
    public static let name = PKContactField(rawValue: "name")
    public static let phoneticName = PKContactField(rawValue: "phoneticName")
}

public final class PKContact: NSObject, @unchecked Sendable {
    public var emailAddress: String?
    public var phoneNumber: CNPhoneNumber?
    public var name: PersonNameComponents?
    public var postalAddress: CNPostalAddress?
    public var supplementarySubLocality: String?
    public override init() {
        super.init()
    }
}

public final class PKPaymentToken: NSObject, @unchecked Sendable {
    public let paymentData: Data
    public let transactionIdentifier: String
    public var paymentInstrumentName: String = ""
    public var paymentMethod: PKPaymentMethod = PKPaymentMethod()
    public var paymentNetwork: String = ""

    public init(paymentData: Data = Data(), transactionIdentifier: String = "") {
        self.paymentData = paymentData
        self.transactionIdentifier = transactionIdentifier
        super.init()
    }
}

public final class PKPayment: NSObject, @unchecked Sendable {
    public let token: PKPaymentToken
    public var billingContact: PKContact?
    public var shippingContact: PKContact?
    public var billingAddress: ABRecord?
    public var shippingAddress: ABRecord?
    public var shippingMethod: PKShippingMethod?

    public init(token: PKPaymentToken = PKPaymentToken()) {
        self.token = token
        super.init()
    }
}

public enum PKPaymentAuthorizationStatus: Int, Sendable {
    case success = 0
    case failure = 1
    case invalidBillingPostalAddress = 2
    case invalidShippingPostalAddress = 3
    case invalidShippingContact = 4
    case pinRequired = 5
    case pinIncorrect = 6
    case pinLockout = 7
}

public final class PKPaymentAuthorizationResult: NSObject, @unchecked Sendable {
    public var status: PKPaymentAuthorizationStatus
    public var errors: [any Error]?
    public var orderDetails: PKPaymentOrderDetails?

    public init(status: PKPaymentAuthorizationStatus, errors: [any Error]?) {
        self.status = status
        self.errors = errors
        super.init()
    }
}

@MainActor
public protocol PKPaymentAuthorizationViewControllerDelegate: AnyObject {
    func paymentAuthorizationViewControllerDidFinish(
        _ controller: PKPaymentAuthorizationViewController
    )
    func paymentAuthorizationViewController(
        _ controller: PKPaymentAuthorizationViewController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    )
}

public extension PKPaymentAuthorizationViewControllerDelegate {
    func paymentAuthorizationViewController(
        _ controller: PKPaymentAuthorizationViewController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        _ = (controller, payment)
        completion(
            PKPaymentAuthorizationResult(
                status: .failure,
                errors: [PassKitPortableError(.paymentsUnavailable)]
            )
        )
    }

    func paymentAuthorizationViewController(
        _ controller: PKPaymentAuthorizationViewController,
        didAuthorizePayment payment: PKPayment,
        completion: @escaping (PKPaymentAuthorizationStatus) -> Void
    ) {
        _ = (controller, payment)
        completion(.failure)
    }

    func paymentAuthorizationViewController(
        _ controller: PKPaymentAuthorizationViewController,
        didAuthorizePayment payment: PKPayment
    ) async -> PKPaymentAuthorizationResult {
        _ = (controller, payment)
        return PKPaymentAuthorizationResult(
            status: .failure,
            errors: [PassKitPortableError(.paymentsUnavailable)]
        )
    }

    func paymentAuthorizationViewController(
        _ controller: PKPaymentAuthorizationViewController,
        didChangeCouponCode couponCode: String,
        handler: @escaping (PKPaymentRequestCouponCodeUpdate) -> Void
    ) {
        _ = (controller, couponCode)
        handler(PKPaymentRequestCouponCodeUpdate(paymentSummaryItems: []))
    }

    func paymentAuthorizationViewController(
        _ controller: PKPaymentAuthorizationViewController,
        didSelect paymentMethod: PKPaymentMethod,
        handler: @escaping (PKPaymentRequestPaymentMethodUpdate) -> Void
    ) {
        _ = (controller, paymentMethod)
        handler(PKPaymentRequestPaymentMethodUpdate(paymentSummaryItems: []))
    }

    func paymentAuthorizationViewController(
        _ controller: PKPaymentAuthorizationViewController,
        didSelectShippingContact contact: PKContact,
        handler: @escaping (PKPaymentRequestShippingContactUpdate) -> Void
    ) {
        _ = (controller, contact)
        handler(
            PKPaymentRequestShippingContactUpdate(
                errors: [PassKitPortableError(.paymentsUnavailable)],
                paymentSummaryItems: [],
                shippingMethods: []
            )
        )
    }

    func paymentAuthorizationViewController(
        _ controller: PKPaymentAuthorizationViewController,
        didSelect shippingMethod: PKShippingMethod,
        handler: @escaping (PKPaymentRequestShippingMethodUpdate) -> Void
    ) {
        _ = (controller, shippingMethod)
        handler(PKPaymentRequestShippingMethodUpdate(paymentSummaryItems: []))
    }

    func paymentAuthorizationViewController(
        _ controller: PKPaymentAuthorizationViewController,
        didChangeCouponCode couponCode: String
    ) async -> PKPaymentRequestCouponCodeUpdate {
        _ = (controller, couponCode)
        return PKPaymentRequestCouponCodeUpdate(paymentSummaryItems: [])
    }

    func paymentAuthorizationViewController(
        _ controller: PKPaymentAuthorizationViewController,
        didRequestMerchantSessionUpdate handler: @escaping (PKPaymentRequestMerchantSessionUpdate) -> Void
    ) {
        _ = controller
        handler(PKPaymentRequestMerchantSessionUpdate(status: .failure, session: nil))
    }

    func paymentAuthorizationViewController(
        _ controller: PKPaymentAuthorizationViewController,
        didSelect paymentMethod: PKPaymentMethod,
        completion: @escaping ([PKPaymentSummaryItem]) -> Void
    ) {
        _ = (controller, paymentMethod)
        completion([])
    }

    func paymentAuthorizationViewController(
        _ controller: PKPaymentAuthorizationViewController,
        didSelect paymentMethod: PKPaymentMethod
    ) async -> PKPaymentRequestPaymentMethodUpdate {
        _ = (controller, paymentMethod)
        return PKPaymentRequestPaymentMethodUpdate(paymentSummaryItems: [])
    }

    func paymentAuthorizationViewController(
        _ controller: PKPaymentAuthorizationViewController,
        didSelectShippingAddress address: ABRecord,
        completion: @escaping (PKPaymentAuthorizationStatus, [PKShippingMethod], [PKPaymentSummaryItem]) -> Void
    ) {
        _ = (controller, address)
        completion(.failure, [], [])
    }

    func paymentAuthorizationViewController(
        _ controller: PKPaymentAuthorizationViewController,
        didSelectShippingContact contact: PKContact,
        completion: @escaping (PKPaymentAuthorizationStatus, [PKShippingMethod], [PKPaymentSummaryItem]) -> Void
    ) {
        _ = (controller, contact)
        completion(.failure, [], [])
    }

    func paymentAuthorizationViewController(
        _ controller: PKPaymentAuthorizationViewController,
        didSelectShippingContact contact: PKContact
    ) async -> PKPaymentRequestShippingContactUpdate {
        _ = (controller, contact)
        return PKPaymentRequestShippingContactUpdate(
            errors: [PassKitPortableError(.paymentsUnavailable)],
            paymentSummaryItems: [],
            shippingMethods: []
        )
    }

    func paymentAuthorizationViewController(
        _ controller: PKPaymentAuthorizationViewController,
        didSelect shippingMethod: PKShippingMethod,
        completion: @escaping (PKPaymentAuthorizationStatus, [PKPaymentSummaryItem]) -> Void
    ) {
        _ = (controller, shippingMethod)
        completion(.failure, [])
    }

    func paymentAuthorizationViewController(
        _ controller: PKPaymentAuthorizationViewController,
        didSelect shippingMethod: PKShippingMethod
    ) async -> PKPaymentRequestShippingMethodUpdate {
        _ = (controller, shippingMethod)
        return PKPaymentRequestShippingMethodUpdate(paymentSummaryItems: [])
    }

    func paymentAuthorizationViewControllerWillAuthorizePayment(
        _ controller: PKPaymentAuthorizationViewController
    ) {
        _ = controller
    }
}

@MainActor
open class PKPaymentAuthorizationViewController: UIViewController, @unchecked Sendable {
    public weak var delegate: (any PKPaymentAuthorizationViewControllerDelegate)?
    public let paymentRequest: PKPaymentRequest

    public nonisolated static func canMakePayments() -> Bool { false }
    public nonisolated static func canMakePayments(
        usingNetworks supportedNetworks: [PKPaymentNetwork]
    ) -> Bool {
        _ = supportedNetworks
        return false
    }
    public nonisolated static func canMakePayments(
        usingNetworks supportedNetworks: [PKPaymentNetwork],
        capabilities: PKMerchantCapability
    ) -> Bool {
        _ = (supportedNetworks, capabilities)
        return false
    }
    public static func supportsDisbursements() -> Bool { false }
    public static func supportsDisbursements(
        using supportedNetworks: [PKPaymentNetwork]
    ) -> Bool {
        _ = supportedNetworks
        return false
    }
    public static func supportsDisbursements(
        using supportedNetworks: [PKPaymentNetwork],
        capabilities: PKMerchantCapability
    ) -> Bool {
        _ = (supportedNetworks, capabilities)
        return false
    }

    public init?(paymentRequest request: PKPaymentRequest) {
        paymentRequest = request
        super.init(nibName: nil, bundle: nil)
        return nil
    }

    public convenience init(disbursementRequest request: PKDisbursementRequest) {
        self.init()
        _ = request
    }

    public override init() {
        paymentRequest = PKPaymentRequest()
        super.init()
    }
}

public protocol PKPaymentAuthorizationControllerDelegate: AnyObject {
    func paymentAuthorizationControllerDidFinish(
        _ controller: PKPaymentAuthorizationController
    )
    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    )
}

public extension PKPaymentAuthorizationControllerDelegate {
    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        _ = (controller, payment)
        completion(
            PKPaymentAuthorizationResult(
                status: .failure,
                errors: [PassKitPortableError(.paymentsUnavailable)]
            )
        )
    }

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        completion: @escaping (PKPaymentAuthorizationStatus) -> Void
    ) {
        _ = (controller, payment)
        completion(.failure)
    }

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment
    ) async -> PKPaymentAuthorizationResult {
        _ = (controller, payment)
        return PKPaymentAuthorizationResult(
            status: .failure,
            errors: [PassKitPortableError(.paymentsUnavailable)]
        )
    }

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didChangeCouponCode couponCode: String
    ) async -> PKPaymentRequestCouponCodeUpdate {
        _ = (controller, couponCode)
        return PKPaymentRequestCouponCodeUpdate(paymentSummaryItems: [])
    }

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didRequestMerchantSessionUpdate handler: @escaping (PKPaymentRequestMerchantSessionUpdate) -> Void
    ) {
        _ = controller
        handler(PKPaymentRequestMerchantSessionUpdate(status: .failure, session: nil))
    }

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didSelectPaymentMethod paymentMethod: PKPaymentMethod,
        completion: @escaping ([PKPaymentSummaryItem]) -> Void
    ) {
        _ = (controller, paymentMethod)
        completion([])
    }

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didSelectPaymentMethod paymentMethod: PKPaymentMethod
    ) async -> PKPaymentRequestPaymentMethodUpdate {
        _ = (controller, paymentMethod)
        return PKPaymentRequestPaymentMethodUpdate(paymentSummaryItems: [])
    }

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didSelectShippingContact contact: PKContact,
        completion: @escaping (PKPaymentAuthorizationStatus, [PKShippingMethod], [PKPaymentSummaryItem]) -> Void
    ) {
        _ = (controller, contact)
        completion(.failure, [], [])
    }

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didSelectShippingContact contact: PKContact
    ) async -> PKPaymentRequestShippingContactUpdate {
        _ = (controller, contact)
        return PKPaymentRequestShippingContactUpdate(
            errors: [PassKitPortableError(.paymentsUnavailable)],
            paymentSummaryItems: [],
            shippingMethods: []
        )
    }

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didSelectShippingMethod shippingMethod: PKShippingMethod,
        completion: @escaping (PKPaymentAuthorizationStatus, [PKPaymentSummaryItem]) -> Void
    ) {
        _ = (controller, shippingMethod)
        completion(.failure, [])
    }

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didSelectShippingMethod shippingMethod: PKShippingMethod
    ) async -> PKPaymentRequestShippingMethodUpdate {
        _ = (controller, shippingMethod)
        return PKPaymentRequestShippingMethodUpdate(paymentSummaryItems: [])
    }

    func paymentAuthorizationControllerWillAuthorizePayment(
        _ controller: PKPaymentAuthorizationController
    ) {
        _ = controller
    }

    func presentationWindow(for controller: PKPaymentAuthorizationController) -> UIWindow? {
        _ = controller
        return nil
    }
}

public final class PKPaymentAuthorizationController {
    public weak var delegate: (any PKPaymentAuthorizationControllerDelegate)?
    public let paymentRequest: PKPaymentRequest
    /// Documented PKPaymentRequest field issues found at `present`. Empty when
    /// the request matches Apple's required-field rules; presentation still
    /// fails closed because this host has no Apple Pay network.
    public private(set) var linuxHostValidationIssues: [PassKitPaymentRequestIssue] = []

    public init(paymentRequest: PKPaymentRequest) {
        self.paymentRequest = paymentRequest
    }

    public convenience init(disbursementRequest request: PKDisbursementRequest) {
        self.init(paymentRequest: PKPaymentRequest())
        _ = request
    }

    public static func canMakePayments() -> Bool { false }
    public static func canMakePayments(
        usingNetworks supportedNetworks: [PKPaymentNetwork],
        capabilities: PKMerchantCapability = []
    ) -> Bool {
        _ = (supportedNetworks, capabilities)
        return false
    }
    public static func supportsDisbursements() -> Bool { false }
    public static func supportsDisbursements(
        using supportedNetworks: [PKPaymentNetwork]
    ) -> Bool {
        _ = supportedNetworks
        return false
    }
    public static func supportsDisbursements(
        using supportedNetworks: [PKPaymentNetwork],
        capabilities: PKMerchantCapability
    ) -> Bool {
        _ = (supportedNetworks, capabilities)
        return false
    }

    public func present(completion: ((Bool) -> Void)? = nil) {
        linuxHostValidationIssues = PassKitPaymentRequestValidation.issues(for: paymentRequest)
        completion?(false)
        // No payment sheet: finish synchronously so callers need no run loop.
        delegate?.paymentAuthorizationControllerDidFinish(self)
    }

    public func dismiss(completion: (() -> Void)? = nil) {
        completion?()
    }
}

public enum PKPaymentButtonType: Int, Sendable {
    case plain = 0
    case buy = 1
    case setUp = 2
    case inStore = 3
    case donate = 4
    case checkout = 5
    case book = 6
    case subscribe = 7
    case reload = 8
    case addMoney = 9
    case topUp = 10
    case order = 11
    case rent = 12
    case support = 13
    case contribute = 14
    case tip = 15
    case `continue` = 16
}

public enum PKPaymentButtonStyle: Int, Sendable {
    case white = 0
    case whiteOutline = 1
    case black = 2
    case automatic = 3
}

@MainActor
open class PKPaymentButton: UIButton, @unchecked Sendable {
    public let paymentButtonType: PKPaymentButtonType
    public let paymentButtonStyle: PKPaymentButtonStyle
    public var cornerRadius: CGFloat = 4

    public init(
        paymentButtonType type: PKPaymentButtonType,
        paymentButtonStyle style: PKPaymentButtonStyle
    ) {
        paymentButtonType = type
        paymentButtonStyle = style
        super.init(frame: .zero)
        isEnabled = false
    }

    public convenience init(
        type: PKPaymentButtonType,
        style: PKPaymentButtonStyle,
        disableCardArt: Bool
    ) {
        self.init(paymentButtonType: type, paymentButtonStyle: style)
        _ = disableCardArt
    }

    public convenience init(
        paymentButtonType type: PKPaymentButtonType,
        paymentButtonStyle style: PKPaymentButtonStyle,
        disableCardArt: Bool
    ) {
        self.init(paymentButtonType: type, paymentButtonStyle: style)
        _ = disableCardArt
    }

    public override init(frame: CGRect) {
        paymentButtonType = .plain
        paymentButtonStyle = .automatic
        super.init(frame: frame)
        isEnabled = false
    }

    public required init?(coder: NSCoder) {
        paymentButtonType = .plain
        paymentButtonStyle = .automatic
        super.init(coder: coder)
        isEnabled = false
    }

    public convenience init() {
        self.init(paymentButtonType: .plain, paymentButtonStyle: .automatic)
    }
}
