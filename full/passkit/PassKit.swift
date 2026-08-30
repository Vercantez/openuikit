import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(OpenUIKit)
import OpenUIKit
#else
#error("PassKit requires UIKit or OpenUIKit")
#endif

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

public final class PKPass {
    public let passURL: URL?
    public let serialNumber: String
    public let passTypeIdentifier: String

    public init(data: Data) throws {
        // A pkpass is a signed archive. Accepting arbitrary bytes without
        // signature/archive validation would create a counterfeit pass.
        throw PassKitPortableError(.passValidationUnavailable)
    }

    internal init(
        portableSerialNumber: String,
        passTypeIdentifier: String,
        passURL: URL? = nil
    ) {
        serialNumber = portableSerialNumber
        self.passTypeIdentifier = passTypeIdentifier
        self.passURL = passURL
    }
}

public final class PKPassLibrary {
    public init() {}
    public func containsPass(_ pass: PKPass) -> Bool { false }
    public func passes() -> [PKPass] { [] }
    public func pass(
        withPassTypeIdentifier identifier: String,
        serialNumber: String
    ) -> PKPass? { nil }
    public func addPasses(
        _ passes: [PKPass],
        withCompletionHandler completion: ((Bool) -> Void)? = nil
    ) {
        completion?(false)
    }
}

@MainActor
public protocol PKAddPassesViewControllerDelegate: AnyObject {
    func addPassesViewControllerDidFinish(
        _ controller: PKAddPassesViewController
    )
}

@MainActor
open class PKAddPassesViewController: UIViewController {
    public weak var delegate: PKAddPassesViewControllerDelegate?
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
    public init(stringLiteral value: String) { rawValue = value }

    public static let amex = PKPaymentNetwork(rawValue: "AmEx")
    public static let masterCard = PKPaymentNetwork(rawValue: "MasterCard")
    public static let visa = PKPaymentNetwork(rawValue: "Visa")
    public static let discover = PKPaymentNetwork(rawValue: "Discover")
    public static let maestro = PKPaymentNetwork(rawValue: "Maestro")
    public static let chinaUnionPay = PKPaymentNetwork(rawValue: "ChinaUnionPay")
    public static let JCB = PKPaymentNetwork(rawValue: "JCB")
    public static let mada = PKPaymentNetwork(rawValue: "Mada")
}

public struct PKMerchantCapability: OptionSet, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let threeDSecure = PKMerchantCapability(rawValue: 1 << 0)
    public static let emv = PKMerchantCapability(rawValue: 1 << 1)
    public static let credit = PKMerchantCapability(rawValue: 1 << 2)
    public static let debit = PKMerchantCapability(rawValue: 1 << 3)
}

public enum PKPaymentSummaryItemType: Int, Sendable {
    case final = 0
    case pending = 1
}

open class PKPaymentSummaryItem {
    public var label: String
    public var amount: Decimal
    public var type: PKPaymentSummaryItemType

    public init(
        label: String,
        amount: Decimal,
        type: PKPaymentSummaryItemType = .final
    ) {
        self.label = label
        self.amount = amount
        self.type = type
    }
}

public final class PKRecurringPaymentSummaryItem: PKPaymentSummaryItem {
    public enum IntervalUnit: Int, Sendable {
        case day, week, month, year
    }

    public var intervalUnit: IntervalUnit = .month
    public var intervalCount = 1
    public var startDate: Date?
    public var endDate: Date?
}

public final class PKPaymentRequest {
    public var merchantIdentifier = ""
    public var countryCode = ""
    public var currencyCode = ""
    public var merchantCapabilities: PKMerchantCapability = []
    public var supportedNetworks: [PKPaymentNetwork] = []
    public var paymentSummaryItems: [PKPaymentSummaryItem] = []
    public var requiredBillingContactFields: Set<PKContactField> = []
    public var requiredShippingContactFields: Set<PKContactField> = []

    public init() {}

    public static func availableNetworks() -> [PKPaymentNetwork] { [] }
}

public struct PKContactField: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let postalAddress = PKContactField(rawValue: "postalAddress")
    public static let emailAddress = PKContactField(rawValue: "emailAddress")
    public static let phoneNumber = PKContactField(rawValue: "phoneNumber")
    public static let name = PKContactField(rawValue: "name")
}

public final class PKContact {
    public var emailAddress: String?
    public var phoneNumber: String?
    public init() {}
}

public final class PKPaymentToken {
    public let paymentData: Data
    public let transactionIdentifier: String
    public init(paymentData: Data = Data(), transactionIdentifier: String = "") {
        self.paymentData = paymentData
        self.transactionIdentifier = transactionIdentifier
    }
}

public final class PKPayment {
    public let token: PKPaymentToken
    public var billingContact: PKContact?
    public var shippingContact: PKContact?

    public init(token: PKPaymentToken = PKPaymentToken()) {
        self.token = token
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

public final class PKPaymentAuthorizationResult {
    public let status: PKPaymentAuthorizationStatus
    public let errors: [Error]?

    public init(status: PKPaymentAuthorizationStatus, errors: [Error]?) {
        self.status = status
        self.errors = errors
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
        completion(
            PKPaymentAuthorizationResult(
                status: .failure,
                errors: [PassKitPortableError(.paymentsUnavailable)]
            )
        )
    }
}

@MainActor
open class PKPaymentAuthorizationViewController: UIViewController {
    public weak var delegate: PKPaymentAuthorizationViewControllerDelegate?
    public let paymentRequest: PKPaymentRequest

    public static func canMakePayments() -> Bool { false }
    public static func canMakePayments(
        usingNetworks supportedNetworks: [PKPaymentNetwork]
    ) -> Bool { false }
    public static func canMakePayments(
        usingNetworks supportedNetworks: [PKPaymentNetwork],
        capabilities: PKMerchantCapability
    ) -> Bool { false }

    public init?(paymentRequest request: PKPaymentRequest) {
        paymentRequest = request
        super.init(nibName: nil, bundle: nil)
        return nil
    }

    public override init() {
        paymentRequest = PKPaymentRequest()
        super.init()
    }
}

@MainActor
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

@MainActor
public final class PKPaymentAuthorizationController {
    public weak var delegate: PKPaymentAuthorizationControllerDelegate?
    public let paymentRequest: PKPaymentRequest

    public init(paymentRequest: PKPaymentRequest) {
        self.paymentRequest = paymentRequest
    }

    public static func canMakePayments() -> Bool { false }
    public static func canMakePayments(
        usingNetworks supportedNetworks: [PKPaymentNetwork],
        capabilities: PKMerchantCapability = []
    ) -> Bool { false }

    public func present(completion: ((Bool) -> Void)? = nil) {
        completion?(false)
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
}

public enum PKPaymentButtonStyle: Int, Sendable {
    case white = 0
    case whiteOutline = 1
    case black = 2
    case automatic = 3
}

@MainActor
open class PKPaymentButton: UIButton {
    public let paymentButtonType: PKPaymentButtonType
    public let paymentButtonStyle: PKPaymentButtonStyle

    public init(
        paymentButtonType type: PKPaymentButtonType,
        paymentButtonStyle style: PKPaymentButtonStyle
    ) {
        paymentButtonType = type
        paymentButtonStyle = style
        super.init(frame: .zero)
        isEnabled = false
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
