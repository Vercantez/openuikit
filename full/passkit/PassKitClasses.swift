import Foundation

// Remaining PassKit model, identity, and Wallet types. Apple Pay / Wallet
// presentation, secure-element provisioning, and identity document requests
// stay fail-closed on this isolated Foundation host.

extension PKSecureElementPass {
    public enum PassActivationState: Int, Hashable, Sendable {
        case activated = 0
        case requiresActivation = 1
        case activating = 2
        case suspended = 3
        case deactivated = 4
    }
}


open class PKAddSecureElementPassConfiguration: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public var issuerIdentifier: String? = nil
    public var localizedDescription: String? = nil
}

open class PKAddCarKeyPassConfiguration: PKAddSecureElementPassConfiguration, @unchecked Sendable {
    public override init() { super.init() }
    public var manufacturerIdentifier: String = ""
    public var password: String = ""
    public var provisioningTemplateIdentifier: String? = nil
    public var supportedRadioTechnologies: PKRadioTechnology = []
}

open class PKAddIdentityDocumentConfiguration: PKAddSecureElementPassConfiguration, @unchecked Sendable {
    public override init() { super.init() }
    public static func forMetadata(_ metadata: PKIdentityDocumentMetadata) async throws -> PKAddIdentityDocumentConfiguration {
        _ = metadata
        throw PassKitPortableError(.paymentsUnavailable)
    }
    public var metadata: PKIdentityDocumentMetadata = PKIdentityDocumentMetadata()
}

open class PKAddIdentityDocumentMetadata: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public init(provisioningCredentialIdentifier credentialIdentifier: String, sharingInstanceIdentifier: String, cardTemplateIdentifier templateIdentifier: String, issuingCountryCode: String, documentType: PKAddIdentityDocumentType, preview: PKAddPassMetadataPreview) {
        super.init()
        self.credentialIdentifier = credentialIdentifier
        self.sharingInstanceIdentifier = sharingInstanceIdentifier
        self.cardTemplateIdentifier = templateIdentifier
        self.issuingCountryCode = issuingCountryCode
        self.documentType = documentType
        self.preview = preview
    }
    public var credentialIdentifier: String = ""
    public var sharingInstanceIdentifier: String = ""
    public var cardTemplateIdentifier: String = ""
    public var issuingCountryCode: String = ""
    public var documentType: PKAddIdentityDocumentType = .idCard
    public var preview: PKAddPassMetadataPreview = PKAddPassMetadataPreview()
}

@MainActor open class PKAddPassButton: UIButton, @unchecked Sendable {
    public override init(frame: CGRect) { super.init(frame: frame) }
    public required init?(coder: NSCoder) { super.init(coder: coder) }
    public init(addPassButtonStyle style: PKAddPassButtonStyle) {
        _ = (style)
        super.init(frame: .zero)
    }
    public var addPassButtonStyle: PKAddPassButtonStyle = .black
}

open class PKAddPassMetadataPreview: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public init(passThumbnail: CGImage, localizedDescription description: String) {
        super.init()
        self.passThumbnailImage = passThumbnail
        self.localizedDescription = description
    }
    public var localizedDescription: String? = nil
    public var passThumbnailImage: CGImage? = nil
}

open class PKAddPaymentPassRequest: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public var activationData: Data? = nil
    public var encryptedPassData: Data? = nil
    public var ephemeralPublicKey: Data? = nil
    public var wrappedKey: Data? = nil
}

open class PKAddPaymentPassRequestConfiguration: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public init?(encryptionScheme: PKEncryptionScheme) {
        super.init()
        self.encryptionScheme = encryptionScheme
    }
    public var cardDetails: [PKLabeledValue] = []
    public var cardholderName: String? = nil
    public var encryptionScheme: PKEncryptionScheme = .ECC_V2
    public var localizedDescription: String? = nil
    public var paymentNetwork: PKPaymentNetwork? = nil
    public var primaryAccountIdentifier: String? = nil
    public var primaryAccountSuffix: String? = nil
    public var productIdentifiers: Set<String> = []
    public var requiresFelicaSecureElement: Bool = false
    public var style: PKAddPaymentPassStyle = .payment
}

@MainActor open class PKAddPaymentPassViewController: UIViewController, @unchecked Sendable {
    public override init() { super.init() }
    public static func canAddPaymentPass() -> Bool {
        return false
    }
    public init?(requestConfiguration configuration: PKAddPaymentPassRequestConfiguration, delegate: (any PKAddPaymentPassViewControllerDelegate)?) {
        super.init(nibName: nil, bundle: nil)
        return nil
    }
    public var delegate: (any PKAddPaymentPassViewControllerDelegate)? = nil
}

@MainActor open class PKAddSecureElementPassViewController: UIViewController, @unchecked Sendable {
    public override init() { super.init() }
    public static func canAddSecureElementPass(configuration: PKAddSecureElementPassConfiguration) -> Bool {
        _ = configuration
        return false
    }
    public init?(configuration: PKAddSecureElementPassConfiguration, delegate: (any PKAddSecureElementPassViewControllerDelegate)?) {
        super.init(nibName: nil, bundle: nil)
        return nil
    }
    public var delegate: (any PKAddSecureElementPassViewControllerDelegate)? = nil
}

open class PKAddShareablePassConfiguration: PKAddSecureElementPassConfiguration, @unchecked Sendable {
    public override init() { super.init() }
    public static func forPassMetadata(_ passMetadata: [PKShareablePassMetadata], action: PKAddShareablePassConfigurationPrimaryAction) async throws -> PKAddShareablePassConfiguration {
        _ = (passMetadata, action)
        throw PassKitPortableError(.paymentsUnavailable)
    }
    public static func forPassMetaData(_ passMetadata: [PKShareablePassMetadata], provisioningPolicyIdentifier: String, action: PKAddShareablePassConfigurationPrimaryAction) async throws -> PKAddShareablePassConfiguration {
        _ = (passMetadata, provisioningPolicyIdentifier, action)
        throw PassKitPortableError(.paymentsUnavailable)
    }
    public var credentialsMetadata: [PKShareablePassMetadata] = []
    public var primaryAction: PKAddShareablePassConfigurationPrimaryAction = .add
    public var provisioningPolicyIdentifier: String = ""
}

open class PKAutomaticReloadPaymentRequest: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public init(paymentDescription: String, automaticReloadBilling: PKAutomaticReloadPaymentSummaryItem, managementURL: URL) {
        super.init()
        self.paymentDescription = paymentDescription
        self.automaticReloadBilling = automaticReloadBilling
        self.managementURL = managementURL
    }
    public var automaticReloadBilling: PKAutomaticReloadPaymentSummaryItem = PKAutomaticReloadPaymentSummaryItem()
    public var billingAgreement: String? = nil
    public var managementURL: URL = URL(fileURLWithPath: "/")
    public var paymentDescription: String = ""
    public var tokenNotificationURL: URL? = nil
}

open class PKAutomaticReloadPaymentSummaryItem: PKPaymentSummaryItem, @unchecked Sendable {
    public override init() { super.init() }
    public override init(label: String, amount: NSDecimalNumber, type: PKPaymentSummaryItemType = .final) {
        super.init(label: label, amount: amount, type: type)
    }
    public var thresholdAmount: NSDecimalNumber = 0
}

open class PKBarcodeEventConfigurationRequest: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public var configurationData: Data = Data()
    public var configurationDataType: PKBarcodeEventConfigurationDataType = .unknown
    public var deviceAccountIdentifier: String = ""
}

open class PKBarcodeEventMetadataRequest: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public var deviceAccountIdentifier: String = ""
    public var lastUsedBarcodeIdentifier: String = ""
}

open class PKBarcodeEventMetadataResponse: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public init(paymentInformation: Data) {
        super.init()
        self.paymentInformation = paymentInformation
    }
    public var paymentInformation: Data = Data()
}

open class PKBarcodeEventSignatureRequest: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public var amount: NSNumber = 0
    public var barcodeIdentifier: String = ""
    public var currencyCode: String = ""
    public var deviceAccountIdentifier: String = ""
    public var merchantName: String = ""
    public var partialSignature: Data = Data()
    public var rawMerchantName: String = ""
    public var transactionDate: Date = Date.distantPast
    public var transactionIdentifier: String = ""
    public var transactionStatus: String = ""
}

open class PKBarcodeEventSignatureResponse: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public init(signedData: Data) {
        super.init()
        self.signedData = signedData
    }
    public var signedData: Data = Data()
}

open class PKDateComponentsRange: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public init(start startDateComponents: DateComponents, end endDateComponents: DateComponents) {
        super.init()
        self.startDateComponents = startDateComponents
        self.endDateComponents = endDateComponents
    }
    public init(startDateComponents: DateComponents, endDateComponents: DateComponents) {
        super.init()
        self.startDateComponents = startDateComponents
        self.endDateComponents = endDateComponents
    }
    public var endDateComponents: DateComponents = DateComponents()
    public var startDateComponents: DateComponents = DateComponents()
    public init(coder: NSCoder) {
        _ = (coder)
        super.init()
    }
}

open class PKDeferredPaymentRequest: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public init(paymentDescription: String, deferredBilling: PKDeferredPaymentSummaryItem, managementURL: URL) {
        super.init()
        self.paymentDescription = paymentDescription
        self.deferredBilling = deferredBilling
        self.managementURL = managementURL
    }
    public var billingAgreement: String? = nil
    public var deferredBilling: PKDeferredPaymentSummaryItem = PKDeferredPaymentSummaryItem()
    public var freeCancellationDate: Date? = nil
    public var freeCancellationDateTimeZone: TimeZone? = nil
    public var managementURL: URL = URL(fileURLWithPath: "/")
    public var paymentDescription: String = ""
    public var tokenNotificationURL: URL? = nil
}

open class PKDeferredPaymentSummaryItem: PKPaymentSummaryItem, @unchecked Sendable {
    public override init() { super.init() }
    public override init(label: String, amount: NSDecimalNumber, type: PKPaymentSummaryItemType = .final) {
        super.init(label: label, amount: amount, type: type)
    }
    public var deferredDate: Date = Date.distantPast
}

open class PKDisbursementRequest: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public static func disbursementCardUnsupportedError() -> any Error {
        return PassKitPortableError(.paymentsUnavailable)
    }
    public static func disbursementContactInvalidError(withContactField field: PKContactField, localizedDescription: String?) -> any Error {
        _ = (field, localizedDescription)
        return PassKitPortableError(.paymentsUnavailable)
    }
    public var applicationData: Data? = nil
    public var merchantCapabilities: PKMerchantCapability = []
    public var merchantIdentifier: String = ""
    public var recipientContact: PKContact? = nil
    public var requiredRecipientContactFields: [PKContactField] = []
    public var summaryItems: [PKPaymentSummaryItem] = []
    public var supportedNetworks: [PKPaymentNetwork] = []
    public var supportedRegions: [Locale.Region]? = nil
    public init(merchantIdentifier: String, currency: Locale.Currency, region: Locale.Region, supportedNetworks: [PKPaymentNetwork], merchantCapabilities: PKMerchantCapability, summaryItems: [PKPaymentSummaryItem]) {
        super.init()
        self.merchantIdentifier = merchantIdentifier
        self.currency = currency
        self.region = region
        self.supportedNetworks = supportedNetworks
        self.merchantCapabilities = merchantCapabilities
        self.summaryItems = summaryItems
    }
    public var region: Locale.Region? = nil
    public var currency: Locale.Currency? = nil
}

open class PKDisbursementSummaryItem: PKPaymentSummaryItem, @unchecked Sendable {
    public override init() { super.init() }
}

open class PKIdentityAnyOfDescriptor: NSObject, PKIdentityDocumentDescriptor, @unchecked Sendable {
    public override init() { super.init() }
    public init(descriptors: [any PKIdentityDocumentDescriptor]) {
        _ = (descriptors)
        super.init()
    }
    public var descriptors: [any PKIdentityDocumentDescriptor] = []
}

open class PKIdentityAuthorizationController: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public func cancelRequest() {
    }
    public func canRequestDocument(_ descriptor: any PKIdentityDocumentDescriptor) async -> Bool {
        _ = descriptor
        return false
    }
    public func requestDocument(_ request: PKIdentityRequest) async throws -> PKIdentityDocument {
        _ = request
        throw PassKitPortableError(.paymentsUnavailable)
    }
}

@MainActor open class PKIdentityButton: UIButton, @unchecked Sendable {
    public enum Label: Int, Hashable, Sendable {
        case verifyIdentity = 0
        case verify = 1
        case verifyAge = 2
        case `continue` = 3
    }
    public enum Style: Int, Hashable, Sendable {
        case black = 0
        case blackOutline = 1
    }
    public override init(frame: CGRect) { super.init(frame: frame) }
    public required init?(coder: NSCoder) { super.init(coder: coder) }
    public init(label: PKIdentityButton.Label, style: PKIdentityButton.Style) {
        _ = (label, style)
        super.init(frame: .zero)
    }
    public var cornerRadius: CGFloat = 0
}

open class PKIdentityDocument: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public var encryptedData: Data = Data()
}

open class PKIdentityDocumentMetadata: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public var cardConfigurationIdentifier: String = ""
    public var cardTemplateIdentifier: String = ""
    public var credentialIdentifier: String = ""
    public var documentType: PKAddIdentityDocumentType = .idCard
    public var issuingCountryCode: String = ""
    public var serverEnvironmentIdentifier: String = ""
    public var sharingInstanceIdentifier: String = ""
}

open class PKIdentityDriversLicenseDescriptor: NSObject, PKIdentityDocumentDescriptor, @unchecked Sendable {
    public override init() { super.init() }
}

open class PKIdentityElement: NSObject, @unchecked Sendable {
    public required override init() { super.init() }
    public static func age(atLeast age: Int) -> Self {
        _ = age
        return Self()
    }
    public static var address: PKIdentityElement = PKIdentityElement()
    public static var age: PKIdentityElement = PKIdentityElement()
    public static var dateOfBirth: PKIdentityElement = PKIdentityElement()
    public static var documentDHSComplianceStatus: PKIdentityElement = PKIdentityElement()
    public static var documentExpirationDate: PKIdentityElement = PKIdentityElement()
    public static var documentIssueDate: PKIdentityElement = PKIdentityElement()
    public static var documentNumber: PKIdentityElement = PKIdentityElement()
    public static var drivingPrivileges: PKIdentityElement = PKIdentityElement()
    public static var eyeColor: PKIdentityElement = PKIdentityElement()
    public static var familyName: PKIdentityElement = PKIdentityElement()
    public static var givenName: PKIdentityElement = PKIdentityElement()
    public static var hairColor: PKIdentityElement = PKIdentityElement()
    public static var height: PKIdentityElement = PKIdentityElement()
    public static var issuingAuthority: PKIdentityElement = PKIdentityElement()
    public static var organDonorStatus: PKIdentityElement = PKIdentityElement()
    public static var portrait: PKIdentityElement = PKIdentityElement()
    public static var sex: PKIdentityElement = PKIdentityElement()
    public static var veteranStatus: PKIdentityElement = PKIdentityElement()
    public static var weight: PKIdentityElement = PKIdentityElement()
}

open class PKIdentityIntentToStore: NSObject, @unchecked Sendable {
    public required override init() { super.init() }
    public static func mayStore(days: Int) -> Self {
        _ = days
        return Self()
    }
    public static var mayStore: PKIdentityIntentToStore = PKIdentityIntentToStore()
    public static var willNotStore: PKIdentityIntentToStore = PKIdentityIntentToStore()
}

open class PKIdentityNationalIDCardDescriptor: NSObject, PKIdentityDocumentDescriptor, @unchecked Sendable {
    public override init() { super.init() }
    public var region: Locale.Region? = nil
}

open class PKIdentityPhotoIDDescriptor: NSObject, PKIdentityDocumentDescriptor, @unchecked Sendable {
    public override init() { super.init() }
}

open class PKIdentityRequest: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public var descriptor: (any PKIdentityDocumentDescriptor)? = nil
    public var merchantIdentifier: String? = nil
    public var nonce: Data? = nil
}

open class PKInstantFundsOutFeeSummaryItem: PKPaymentSummaryItem, @unchecked Sendable {
    public override init() { super.init() }
}

open class PKIssuerProvisioningExtensionHandler: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public func generateAddPaymentPassRequestForPassEntryWithIdentifier(_ identifier: String, configuration: PKAddPaymentPassRequestConfiguration, certificateChain certificates: [Data], nonce: Data, nonceSignature: Data) async -> PKAddPaymentPassRequest? {
        _ = (identifier, configuration, certificates, nonce, nonceSignature)
        return nil
    }
    public func passEntries(completion: @escaping ([PKIssuerProvisioningExtensionPassEntry]) -> Void) {
        _ = completion
        completion([])
    }
    public func remotePassEntries(completion: @escaping ([PKIssuerProvisioningExtensionPassEntry]) -> Void) {
        _ = completion
        completion([])
    }
    public func status(completion: @escaping (PKIssuerProvisioningExtensionStatus) -> Void) {
        _ = completion
        completion(PKIssuerProvisioningExtensionStatus())
    }
}

open class PKIssuerProvisioningExtensionPassEntry: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public var art: CGImage = CGImage()
    public var identifier: String = ""
    public var title: String = ""
}

open class PKIssuerProvisioningExtensionPaymentPassEntry: PKIssuerProvisioningExtensionPassEntry, @unchecked Sendable {
    public override init() { super.init() }
    public init(identifier: String, title: String, art: CGImage, addRequestConfiguration configuration: PKAddPaymentPassRequestConfiguration) {
        super.init()
        self.identifier = identifier
        self.title = title
        self.art = art
        self.addRequestConfiguration = configuration
    }
    public var addRequestConfiguration: PKAddPaymentPassRequestConfiguration = PKAddPaymentPassRequestConfiguration()
}

open class PKIssuerProvisioningExtensionStatus: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public var passEntriesAvailable: Bool = false
    public var remotePassEntriesAvailable: Bool = false
    public var requiresAuthentication: Bool = false
}

open class PKJapanIndividualNumberCardMetadata: PKIdentityDocumentMetadata, @unchecked Sendable {
    public override init() { super.init() }
    public init(provisioningCredentialIdentifier credentialIdentifier: String, sharingInstanceIdentifier: String, cardConfigurationIdentifier: String, preview: PKAddPassMetadataPreview) {
        super.init()
        self.credentialIdentifier = credentialIdentifier
        self.sharingInstanceIdentifier = sharingInstanceIdentifier
        self.cardConfigurationIdentifier = cardConfigurationIdentifier
        self.preview = preview
    }
    public init(provisioningCredentialIdentifier credentialIdentifier: String, sharingInstanceIdentifier: String, cardTemplateIdentifier templateIdentifier: String, preview: PKAddPassMetadataPreview) {
        super.init()
        self.credentialIdentifier = credentialIdentifier
        self.sharingInstanceIdentifier = sharingInstanceIdentifier
        self.cardTemplateIdentifier = templateIdentifier
        self.preview = preview
    }
    public var authenticationPassword: String? = nil
    public var preview: PKAddPassMetadataPreview = PKAddPassMetadataPreview()
    public var signingPassword: String? = nil
}

open class PKLabeledValue: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public init(label: String, value: String) {
        super.init()
        self.label = label
        self.value = value
    }
    public var label: String = ""
    public var value: String = ""
}

open class PKPassRelevantDate: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public var date: Date? = nil
    public var interval: DateInterval? = nil
}

@MainActor open class PKPayLaterView: UIView, @unchecked Sendable {
    public override init(frame: CGRect) { super.init(frame: frame) }
    public var action: PKPayLaterAction = .learnMore
    public weak var delegate: (any PKPayLaterViewDelegate)?
    public var displayStyle: PKPayLaterDisplayStyle = .standard
    public init(amount: Decimal, currency: Locale.Currency) {
        super.init(frame: .zero)
        self.amount = amount
        self.currency = currency
    }
    public var amount: Decimal = 0
    public var currency: Locale.Currency? = nil
}

open class PKPaymentInformationEventExtension: NSObject, @unchecked Sendable {
    public override init() { super.init() }
}

open class PKPaymentMerchantSession: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public init(dictionary: [AnyHashable : Any]) {
        _ = dictionary
        super.init()
    }
}

open class PKPaymentMethod: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public var billingAddress: CNContact? = nil
    public var displayName: String? = nil
    public var network: PKPaymentNetwork? = nil
    public var paymentPass: PKPaymentPass? = nil
    public var secureElementPass: PKSecureElementPass? = nil
    public var type: PKPaymentMethodType = .unknown
}

open class PKPaymentOrderDetails: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public init(orderTypeIdentifier: String, orderIdentifier: String, webServiceURL: URL, authenticationToken: String) {
        super.init()
        self.orderTypeIdentifier = orderTypeIdentifier
        self.orderIdentifier = orderIdentifier
        self.webServiceURL = webServiceURL
        self.authenticationToken = authenticationToken
    }
    public var authenticationToken: String = ""
    public var orderIdentifier: String = ""
    public var orderTypeIdentifier: String = ""
    public var webServiceURL: URL = URL(fileURLWithPath: "/")
}

open class PKSecureElementPass: PKPass, @unchecked Sendable {
    public override init() { super.init() }
    public var deviceAccountIdentifier: String = ""
    public var deviceAccountNumberSuffix: String = ""
    public var devicePassIdentifier: String? = nil
    public var pairedTerminalIdentifier: String? = nil
    public var passActivationState: PKSecureElementPass.PassActivationState = .deactivated
    public var primaryAccountIdentifier: String = ""
    public var primaryAccountNumberSuffix: String = ""
}

open class PKPaymentPass: PKSecureElementPass, @unchecked Sendable {
    public override init() { super.init() }
    public var activationState: PKPaymentPassActivationState = .deactivated
}

open class PKPaymentRequestUpdate: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public init(paymentSummaryItems: [PKPaymentSummaryItem]) {
        super.init()
        self.paymentSummaryItems = paymentSummaryItems
    }
    public var automaticReloadPaymentRequest: PKAutomaticReloadPaymentRequest? = nil
    public var deferredPaymentRequest: PKDeferredPaymentRequest? = nil
    public var multiTokenContexts: [PKPaymentTokenContext]? = nil
    public var paymentSummaryItems: [PKPaymentSummaryItem] = []
    public var recurringPaymentRequest: PKRecurringPaymentRequest? = nil
    public var shippingMethods: [PKShippingMethod] = []
    public var status: PKPaymentAuthorizationStatus = .failure
}

open class PKPaymentRequestCouponCodeUpdate: PKPaymentRequestUpdate, @unchecked Sendable {
    public override init() { super.init() }
    public init(errors: [any Error]?, paymentSummaryItems: [PKPaymentSummaryItem], shippingMethods: [PKShippingMethod]) {
        super.init(paymentSummaryItems: paymentSummaryItems)
        self.errors = errors
        self.shippingMethods = shippingMethods
    }
    public convenience override init(paymentSummaryItems: [PKPaymentSummaryItem]) {
        self.init(errors: nil, paymentSummaryItems: paymentSummaryItems, shippingMethods: [])
    }
    public var errors: [any Error]? = nil
}

open class PKPaymentRequestMerchantSessionUpdate: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public init(status: PKPaymentAuthorizationStatus, merchantSession session: PKPaymentMerchantSession?) {
        _ = session
        self.status = status
        self.session = session
        super.init()
    }

    public convenience init(status: PKPaymentAuthorizationStatus, session: PKPaymentMerchantSession?) {
        self.init(status: status, merchantSession: session)
    }
    public var session: PKPaymentMerchantSession? = nil
    public var status: PKPaymentAuthorizationStatus = .failure
}

open class PKPaymentRequestPaymentMethodUpdate: PKPaymentRequestUpdate, @unchecked Sendable {
    public override init() { super.init() }
    public init(errors: [any Error]?, paymentSummaryItems: [PKPaymentSummaryItem]) {
        super.init(paymentSummaryItems: paymentSummaryItems)
        self.errors = errors
    }
    public convenience override init(paymentSummaryItems: [PKPaymentSummaryItem]) {
        self.init(errors: nil, paymentSummaryItems: paymentSummaryItems)
    }
    public var errors: [any Error]? = nil
}

open class PKPaymentRequestShippingContactUpdate: PKPaymentRequestUpdate, @unchecked Sendable {
    public override init() { super.init() }
    public init(errors: [any Error]?, paymentSummaryItems: [PKPaymentSummaryItem], shippingMethods: [PKShippingMethod]) {
        super.init(paymentSummaryItems: paymentSummaryItems)
        self.errors = errors
        self.shippingMethods = shippingMethods
    }
    public var errors: [any Error]? = nil
}

open class PKPaymentRequestShippingMethodUpdate: PKPaymentRequestUpdate, @unchecked Sendable {
    public override init() { super.init() }
    public convenience override init(paymentSummaryItems: [PKPaymentSummaryItem]) {
        self.init()
        self.paymentSummaryItems = paymentSummaryItems
    }
}

open class PKPaymentTokenContext: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public init(merchantIdentifier: String, externalIdentifier: String, merchantName: String, merchantDomain: String?, amount: NSDecimalNumber) {
        super.init()
        self.merchantIdentifier = merchantIdentifier
        self.externalIdentifier = externalIdentifier
        self.merchantName = merchantName
        self.merchantDomain = merchantDomain
        self.amount = amount
    }
    public var amount: NSDecimalNumber = 0
    public var externalIdentifier: String = ""
    public var merchantDomain: String? = nil
    public var merchantIdentifier: String = ""
    public var merchantName: String = ""
}

open class PKRecurringPaymentRequest: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public init(paymentDescription: String, regularBilling: PKRecurringPaymentSummaryItem, managementURL: URL) {
        super.init()
        self.paymentDescription = paymentDescription
        self.regularBilling = regularBilling
        self.managementURL = managementURL
    }
    public var billingAgreement: String? = nil
    public var managementURL: URL = URL(fileURLWithPath: "/")
    public var paymentDescription: String = ""
    public var regularBilling: PKRecurringPaymentSummaryItem = PKRecurringPaymentSummaryItem(label: "", amount: 0)
    public var tokenNotificationURL: URL? = nil
    public var trialBilling: PKRecurringPaymentSummaryItem? = nil
}

@MainActor open class PKShareSecureElementPassViewController: UIViewController, @unchecked Sendable {
    public override init() { super.init() }
    public init(secureElementPass pass: PKSecureElementPass, delegate: (any PKShareSecureElementPassViewControllerDelegate)?) {
        _ = (pass)
        super.init(nibName: nil, bundle: nil)
    }
    public var delegate: (any PKShareSecureElementPassViewControllerDelegate)? = nil
    public var promptToShareURL: Bool = false
}

open class PKShareablePassMetadata: NSObject, @unchecked Sendable {
    open class Preview: NSObject, @unchecked Sendable {
        public var localizedDescription: String = ""
        public var passThumbnail: CGImage = CGImage()
        public var ownerDisplayName: String?
        public var provisioningTemplateIdentifier: String?
        public init(passThumbnail: CGImage, localizedDescription description: String) {
            self.passThumbnail = passThumbnail
            self.localizedDescription = description
            super.init()
        }
        public override init() { super.init() }
    }
    public override init() { super.init() }
    public init(provisioningCredentialIdentifier credentialIdentifier: String, cardConfigurationIdentifier: String, sharingInstanceIdentifier: String, passThumbnailImage: CGImage, ownerDisplayName: String, localizedDescription: String) {
        super.init()
        self.credentialIdentifier = credentialIdentifier
        self.cardConfigurationIdentifier = cardConfigurationIdentifier
        self.sharingInstanceIdentifier = sharingInstanceIdentifier
        self.passThumbnailImage = passThumbnailImage
        self.ownerDisplayName = ownerDisplayName
        self.localizedDescription = localizedDescription
    }
    public init(provisioningCredentialIdentifier credentialIdentifier: String, sharingInstanceIdentifier: String, cardConfigurationIdentifier templateIdentifier: String, preview: PKShareablePassMetadata.Preview) {
        super.init()
        self.credentialIdentifier = credentialIdentifier
        self.sharingInstanceIdentifier = sharingInstanceIdentifier
        self.cardConfigurationIdentifier = templateIdentifier
        self.preview = preview
        self.localizedDescription = preview.localizedDescription
        self.passThumbnailImage = preview.passThumbnail
        self.ownerDisplayName = preview.ownerDisplayName ?? ""
    }
    public init(provisioningCredentialIdentifier credentialIdentifier: String, sharingInstanceIdentifier: String, cardTemplateIdentifier templateIdentifier: String, preview: PKShareablePassMetadata.Preview) {
        super.init()
        self.credentialIdentifier = credentialIdentifier
        self.sharingInstanceIdentifier = sharingInstanceIdentifier
        self.cardTemplateIdentifier = templateIdentifier
        self.templateIdentifier = templateIdentifier
        self.preview = preview
        self.localizedDescription = preview.localizedDescription
        self.passThumbnailImage = preview.passThumbnail
        self.ownerDisplayName = preview.ownerDisplayName ?? ""
    }
    public init(provisioningCredentialIdentifier credentialIdentifier: String, sharingInstanceIdentifier: String, passThumbnailImage: CGImage, ownerDisplayName: String, localizedDescription: String, accountHash: String, templateIdentifier: String, relyingPartyIdentifier: String, requiresUnifiedAccessCapableDevice: Bool) {
        super.init()
        self.credentialIdentifier = credentialIdentifier
        self.sharingInstanceIdentifier = sharingInstanceIdentifier
        self.passThumbnailImage = passThumbnailImage
        self.ownerDisplayName = ownerDisplayName
        self.localizedDescription = localizedDescription
        self.accountHash = accountHash
        self.templateIdentifier = templateIdentifier
        self.relyingPartyIdentifier = relyingPartyIdentifier
        self.requiresUnifiedAccessCapableDevice = requiresUnifiedAccessCapableDevice
    }
    public var accountHash: String = ""
    public var cardConfigurationIdentifier: String = ""
    public var cardTemplateIdentifier: String = ""
    public var credentialIdentifier: String = ""
    public var localizedDescription: String = ""
    public var ownerDisplayName: String = ""
    public var passThumbnailImage: CGImage = CGImage()
    public var preview: PKShareablePassMetadata.Preview = PKShareablePassMetadata.Preview()
    public var relyingPartyIdentifier: String = ""
    public var requiresUnifiedAccessCapableDevice: Bool = false
    public var serverEnvironmentIdentifier: String = ""
    public var sharingInstanceIdentifier: String = ""
    public var templateIdentifier: String = ""
}

open class PKShippingMethod: PKPaymentSummaryItem, @unchecked Sendable {
    public override init() { super.init() }
    public override init(label: String, amount: NSDecimalNumber, type: PKPaymentSummaryItemType = .final) {
        super.init(label: label, amount: amount, type: type)
    }
    public var dateComponentsRange: PKDateComponentsRange? = nil
    public var detail: String? = nil
    public var identifier: String? = nil
}

open class PKStoredValuePassBalance: NSObject, @unchecked Sendable {
    public struct BalanceType: RawRepresentable, Hashable, Sendable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public static let cash = BalanceType(rawValue: "cash")
        public static let loyaltyPoints = BalanceType(rawValue: "loyaltyPoints")
    }
    public override init() { super.init() }
    public var balanceType: PKStoredValuePassBalance.BalanceType = .cash
    public var currencyCode: String? = nil
    public var expiryDate: Date? = nil
    public var amount: Decimal = 0
}

open class PKStoredValuePassProperties: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public var isBlocked: Bool = false
    public init(for pass: PKPass) {
        _ = (pass)
        super.init()
    }
    public init(forPass pass: PKPass) {
        _ = (pass)
        super.init()
    }
    public var balances: [PKStoredValuePassBalance] = []
    public var isBlacklisted: Bool = false
    public var expirationDate: Date? = nil
}

open class PKTransitPassProperties: PKStoredValuePassProperties, @unchecked Sendable {
    public override init() { super.init() }
}

open class PKSuicaPassProperties: PKTransitPassProperties, @unchecked Sendable {
    public override init() { super.init() }
    public init(for pass: PKPass) {
        _ = (pass)
        super.init()
    }
    public var isBalanceAllowedForCommute: Bool = false
    public var isGreenCarTicketUsed: Bool = false
    public var isInShinkansenStation: Bool = false
    public var isLowBalanceGateNotificationEnabled: Bool = false
}

open class PKVehicleConnectionSession: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public static func session(for pass: PKSecureElementPass, delegate: any PKVehicleConnectionDelegate) async throws -> PKVehicleConnectionSession {
        _ = (pass, delegate)
        throw PassKitPortableError(.paymentsUnavailable)
    }
    public func invalidate() {
    }
    public func send(_ message: Data) throws {
        _ = message
        throw PassKitPortableError(.paymentsUnavailable)
    }
    public var connectionStatus: PKVehicleConnectionSessionConnectionState = .disconnected
    public var delegate: (any PKVehicleConnectionDelegate)? = nil
}

public protocol PKAddPaymentPassViewControllerDelegate: AnyObject {
    func addPaymentPassViewController(_ controller: PKAddPaymentPassViewController, didFinishAdding pass: PKPaymentPass?, error: (any Error)?)
    func addPaymentPassViewController(_ controller: PKAddPaymentPassViewController, generateRequestWithCertificateChain certificates: [Data], nonce: Data, nonceSignature: Data) async -> PKAddPaymentPassRequest
}

public extension PKAddPaymentPassViewControllerDelegate {
    func addPaymentPassViewController(_ controller: PKAddPaymentPassViewController, didFinishAdding pass: PKPaymentPass?, error: (any Error)?) {
        _ = (controller, pass, error)
    }
    func addPaymentPassViewController(_ controller: PKAddPaymentPassViewController, generateRequestWithCertificateChain certificates: [Data], nonce: Data, nonceSignature: Data) async -> PKAddPaymentPassRequest {
        _ = (controller, certificates, nonce, nonceSignature)
        return PKAddPaymentPassRequest()
    }
    func addPaymentPassViewController(_ controller: PKAddPaymentPassViewController, generateRequestWithCertificateChain certificates: [Data], nonce: Data, nonceSignature: Data, completionHandler handler: @escaping (PKAddPaymentPassRequest) -> Void) {
        _ = (controller, certificates, nonce, nonceSignature)
        handler(PKAddPaymentPassRequest())
    }
}

public protocol PKAddSecureElementPassViewControllerDelegate: AnyObject {
    func addSecureElementPassViewController(_ controller: PKAddSecureElementPassViewController, didFinishAdding pass: PKSecureElementPass?, error: (any Error)?)
    func addSecureElementPassViewController(_ controller: PKAddSecureElementPassViewController, didFinishAddingSecureElementPasses passes: [PKSecureElementPass]?, error: (any Error)?)
}

public extension PKAddSecureElementPassViewControllerDelegate {
    func addSecureElementPassViewController(_ controller: PKAddSecureElementPassViewController, didFinishAdding pass: PKSecureElementPass?, error: (any Error)?) {
        _ = (controller, pass, error)
    }
    func addSecureElementPassViewController(_ controller: PKAddSecureElementPassViewController, didFinishAddingSecureElementPasses passes: [PKSecureElementPass]?, error: (any Error)?) {
        _ = (controller, passes, error)
    }
}

public protocol PKIdentityDocumentDescriptor: AnyObject {
    func addElements(_ elements: [PKIdentityElement], intentToStore: PKIdentityIntentToStore)
    func intentToStore(element: PKIdentityElement) -> PKIdentityIntentToStore?
    var elements: [PKIdentityElement] { get }
}

public extension PKIdentityDocumentDescriptor {
    func addElements(_ elements: [PKIdentityElement], intentToStore: PKIdentityIntentToStore) {
        _ = (elements, intentToStore)
    }
    func intentToStore(element: PKIdentityElement) -> PKIdentityIntentToStore? {
        _ = element
        return nil
    }
    var elements: [PKIdentityElement] { [] }
}

public protocol PKIssuerProvisioningExtensionAuthorizationProviding: AnyObject {
    var completionHandler: ((PKIssuerProvisioningExtensionAuthorizationResult) -> Void)? { get set }
}

public extension PKIssuerProvisioningExtensionAuthorizationProviding {
}

public protocol PKPayLaterViewDelegate: AnyObject {
    func payLaterViewDidUpdateHeight(_ view: PKPayLaterView)
}

public extension PKPayLaterViewDelegate {
    func payLaterViewDidUpdateHeight(_ view: PKPayLaterView) {
        _ = view
    }
}

public protocol PKPaymentInformationRequestHandling: AnyObject {
    func handle(_ configurationRequest: PKBarcodeEventConfigurationRequest) async
    func handleInformationRequest(_ infoRequest: PKBarcodeEventMetadataRequest) async -> PKBarcodeEventMetadataResponse
    func handle(_ signatureRequest: PKBarcodeEventSignatureRequest) async -> PKBarcodeEventSignatureResponse
}

public extension PKPaymentInformationRequestHandling {
    func handle(_ configurationRequest: PKBarcodeEventConfigurationRequest) async {
        _ = configurationRequest
    }
    func handleInformationRequest(_ infoRequest: PKBarcodeEventMetadataRequest) async -> PKBarcodeEventMetadataResponse {
        _ = infoRequest
        return PKBarcodeEventMetadataResponse()
    }
    func handle(_ signatureRequest: PKBarcodeEventSignatureRequest) async -> PKBarcodeEventSignatureResponse {
        _ = signatureRequest
        return PKBarcodeEventSignatureResponse()
    }
}

public protocol PKShareSecureElementPassViewControllerDelegate: AnyObject {
    func shareSecureElementPassViewController(_ controller: PKShareSecureElementPassViewController, didCreateShare universalShareURL: URL?, activationCode: String?)
    func shareSecureElementPassViewController(_ controller: PKShareSecureElementPassViewController, didFinishWith result: PKShareSecureElementPassResult)
}

public extension PKShareSecureElementPassViewControllerDelegate {
    func shareSecureElementPassViewController(_ controller: PKShareSecureElementPassViewController, didCreateShare universalShareURL: URL?, activationCode: String?) {
        _ = (controller, universalShareURL, activationCode)
    }
    func shareSecureElementPassViewController(_ controller: PKShareSecureElementPassViewController, didFinishWith result: PKShareSecureElementPassResult) {
        _ = (controller, result)
    }
}

public protocol PKVehicleConnectionDelegate: AnyObject {
    func sessionDidChange(_ newState: PKVehicleConnectionSessionConnectionState)
    func sessionDidReceive(_ data: Data)
}

public extension PKVehicleConnectionDelegate {
    func sessionDidChange(_ newState: PKVehicleConnectionSessionConnectionState) {
        _ = newState
    }
    func sessionDidReceive(_ data: Data) {
        _ = data
    }
}
