import Foundation

public enum PKAddIdentityDocumentType: Int, Hashable, Sendable {
    case idCard = 0
    case mDL = 1
    case photoID = 2
}

public enum PKAddPassButtonStyle: Int, Hashable, Sendable {
    case black = 0
    case blackOutline = 1
}

public enum PKAddPaymentPassError: Int, Hashable, Sendable {
    case unsupported = 0
    case userCancelled = 1
    case systemCancelled = 2
}

public enum PKAddPaymentPassStyle: Int, Hashable, Sendable {
    case payment = 0
    case access = 1
}

public enum PKAddShareablePassConfigurationPrimaryAction: Int, Hashable, Sendable {
    case add = 0
    case share = 1
}

public enum PKApplePayLaterAvailability: Int, Hashable, Sendable {
    case available = 0
    case unavailableItemIneligible = 1
    case unavailableRecurringTransaction = 2
}

public enum PKAutomaticPassPresentationSuppressionResult: UInt, Hashable, Sendable {
    case notSupported = 0
    case alreadyPresenting = 1
    case denied = 2
    case cancelled = 3
    case success = 4
}

public enum PKBarcodeEventConfigurationDataType: Int, Hashable, Sendable {
    case unknown = 0
    case signingKeyMaterial = 1
    case signingCertificate = 2
}

public enum PKIssuerProvisioningExtensionAuthorizationResult: Int, Hashable, Sendable {
    case canceled = 0
    case authorized = 1
}

public enum PKPassLibraryAddPassesStatus: Int, Hashable, Sendable {
    case didAddPasses = 0
    case shouldReviewPasses = 1
    case didCancelAddPasses = 2
}

public enum PKPassType: UInt, Hashable, Sendable {
    case barcode = 0
    case secureElement = 1
    case any = 0xFFFF_FFFF_FFFF_FFFF
}

public enum PKPayLaterAction: Int, Hashable, Sendable {
    case learnMore = 0
    case calculator = 1
}

public enum PKPayLaterDisplayStyle: Int, Hashable, Sendable {
    case standard = 0
    case badge = 1
    case checkout = 2
    case price = 3
}

/// Apple Pay Later namespace. Eligibility is fail-closed on this host.
@frozen public enum PKPayLater {
    public static func validate(amount: Decimal, currency: Locale.Currency) async -> Bool {
        _ = (amount, currency)
        return false
    }
}

public enum PKPaymentMethodType: UInt, Hashable, Sendable {
    case unknown = 0
    case debit = 1
    case credit = 2
    case prepaid = 3
    case store = 4
    case eMoney = 5
}

public enum PKPaymentPassActivationState: UInt, Hashable, Sendable {
    case activated = 0
    case requiresActivation = 1
    case activating = 2
    case suspended = 3
    case deactivated = 4
}

public enum PKShareSecureElementPassResult: Int, Hashable, Sendable {
    case canceled = 0
    case shared = 1
    case failed = 2
}

public enum PKShippingContactEditingMode: UInt, Hashable, Sendable {
    case enabled = 1
    case storePickup = 2
}

public enum PKShippingType: UInt, Hashable, Sendable {
    case shipping = 0
    case delivery = 1
    case storePickup = 2
    case servicePickup = 3
}

public enum PKVehicleConnectionErrorCode: Int, Hashable, Sendable {
    case unknown = 0
    case sessionUnableToStart = 1
    case sessionNotActive = 2
}

public enum PKVehicleConnectionSessionConnectionState: Int, Hashable, Sendable {
    case disconnected = 0
    case connected = 1
    case connecting = 2
    case failedToConnect = 3
}

public struct PKAddressField: OptionSet, Hashable, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let postalAddress = PKAddressField(rawValue: 1 << 0)
    public static let phone = PKAddressField(rawValue: 1 << 1)
    public static let email = PKAddressField(rawValue: 1 << 2)
    public static let name = PKAddressField(rawValue: 1 << 3)
    public static let all: PKAddressField = [.postalAddress, .phone, .email, .name]
}

public struct PKRadioTechnology: OptionSet, Hashable, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let NFC = PKRadioTechnology(rawValue: 1 << 0)
    public static let bluetooth = PKRadioTechnology(rawValue: 1 << 1)
}

public struct PKEncryptionScheme: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let ECC_V2 = PKEncryptionScheme(rawValue: "ECC_V2")
    public static let RSA_V2 = PKEncryptionScheme(rawValue: "RSA_V2")
}

public struct PKPaymentErrorKey: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let contactFieldUserInfoKey = PKPaymentErrorKey(rawValue: "PKPaymentErrorContactFieldUserInfoKey")
    public static let postalAddressUserInfoKey = PKPaymentErrorKey(rawValue: "PKPaymentErrorPostalAddressUserInfoKey")
}

public struct PKDisbursementErrorKey: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let contactFieldUserInfoKey = PKDisbursementErrorKey(rawValue: "PKDisbursementErrorContactFieldUserInfoKey")
}

public struct PKPassLibraryNotificationKey: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let addedPassesUserInfoKey = PKPassLibraryNotificationKey(rawValue: "PKPassLibraryAddedPassesUserInfoKey")
    public static let passTypeIdentifierUserInfoKey = PKPassLibraryNotificationKey(rawValue: "PKPassLibraryPassTypeIdentifierUserInfoKey")
    public static let recoveredPassesUserInfoKey = PKPassLibraryNotificationKey(rawValue: "PKPassLibraryRecoveredPassesUserInfoKey")
    public static let removedPassInfosUserInfoKey = PKPassLibraryNotificationKey(rawValue: "PKPassLibraryRemovedPassInfosUserInfoKey")
    public static let replacementPassesUserInfoKey = PKPassLibraryNotificationKey(rawValue: "PKPassLibraryReplacementPassesUserInfoKey")
    public static let serialNumberUserInfoKey = PKPassLibraryNotificationKey(rawValue: "PKPassLibrarySerialNumberUserInfoKey")
}

public struct PKPassLibraryNotificationName: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ rawValue: String) { self.rawValue = rawValue }
    public static let PKPassLibraryDidChange = PKPassLibraryNotificationName(rawValue: "PKPassLibraryDidChangeNotification")
    public static let PKPassLibraryRemotePaymentPassesDidChange = PKPassLibraryNotificationName(rawValue: "PKPassLibraryRemotePaymentPassesDidChangeNotification")
}

public typealias PKSuppressionRequestToken = Int
public typealias PKInformationRequestCompletionBlock = (PKBarcodeEventMetadataResponse) -> Void
public typealias PKSignatureRequestCompletionBlock = (PKBarcodeEventSignatureResponse) -> Void

public let PKAddSecureElementPassErrorDomain = "PKAddSecureElementPassErrorDomain"
public let PKDisbursementErrorDomain = "PKDisbursementErrorDomain"
public let PKIdentityErrorDomain = "PKIdentityErrorDomain"
public let PKPassKitErrorDomain = "PKPassKitErrorDomain"
public let PKPaymentErrorDomain = "PKPaymentErrorDomain"
public let PKShareSecureElementPassErrorDomain = "PKShareSecureElementPassErrorDomain"
