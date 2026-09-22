// Apple Pay (PassKit payments), fail closed.
//
// The surface Kickstarter (ios-oss 2f2dabb4: Library ApplePayCapabilities,
// PKPaymentRequest+Helpers, Pledge/ApplePayToken view models, Framework
// PledgeViewController, PostCampaignCheckoutViewController, the two CTA
// container views) and its Stripe dependency use. Values and defaults are
// the iOS 26.1 simulator's (Tools/oracle2/applepayprobe; transcript
// docs/agent_reports/ios-oss-launch3-applepay-oracle-ios26.1.json).
//
// OpenUIKit has no Secure Element, no Wallet and no payment sheet, so every
// query that would lead to a payment fails closed. Two deliberate,
// documented divergences from the simulator follow from that:
//
//   * `canMakePayments()` / `canMakePayments(usingNetworks:)` answer FALSE
//     (the simulator answers true — it ships a simulated card);
//   * `PKPaymentAuthorizationViewController(paymentRequest:)` returns NIL
//     for every request (the simulator returns nil only for an incomplete
//     request and a controller for a complete one).
//
// So an app hides its Apple Pay button and never presents a sheet; no
// PKPayment is ever authorised. Everything else (request / summary-item
// models, raw values, the button's geometry) is the measured value.

import Foundation
import OpenUIKit

// MARK: - Networks and capabilities

/// `PKPaymentNetwork` (an extensible string enum in Swift).
public struct PKPaymentNetwork: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ rawValue: String) { self.rawValue = rawValue }

    // iOS 26.1 raw strings (applepayprobe `network.*`).
    public static let amex = PKPaymentNetwork("AmEx")
    public static let discover = PKPaymentNetwork("Discover")
    public static let JCB = PKPaymentNetwork("JCB")
    public static let masterCard = PKPaymentNetwork("MasterCard")
    public static let chinaUnionPay = PKPaymentNetwork("ChinaUnionPay")
    public static let visa = PKPaymentNetwork("Visa")
    public static let maestro = PKPaymentNetwork("Maestro")
    public static let interac = PKPaymentNetwork("Interac")
}

/// `PKMerchantCapability` (iOS 26.1: 3DS 1, EMV 2, credit 4, debit 8).
public struct PKMerchantCapability: OptionSet, Hashable, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let capability3DS = PKMerchantCapability(rawValue: 1 << 0)
    public static let capabilityEMV = PKMerchantCapability(rawValue: 1 << 1)
    public static let capabilityCredit = PKMerchantCapability(rawValue: 1 << 2)
    public static let capabilityDebit = PKMerchantCapability(rawValue: 1 << 3)
    // Swift spells these `threeDSecure` / `emv` / `credit` / `debit` as well.
    public static let threeDSecure = capability3DS
    public static let emv = capabilityEMV
    public static let credit = capabilityCredit
    public static let debit = capabilityDebit
}

/// `PKShippingType` (iOS 26.1 raws 0…3).
public enum PKShippingType: UInt, Sendable {
    case shipping = 0, delivery = 1, storePickup = 2, servicePickup = 3
}

/// `PKPaymentSummaryItemType` (iOS 26.1: final 0, pending 1).
public enum PKPaymentSummaryItemType: UInt, Sendable {
    case final = 0, pending = 1
}

/// `PKPaymentAuthorizationStatus` (iOS 26.1: success 0, failure 1).
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

/// `PKPaymentMethodType` (a bare payment method reads `.unknown`, raw 0).
public enum PKPaymentMethodType: UInt, Sendable {
    case unknown = 0, debit = 1, credit = 2, prepaid = 3, store = 4, eMoney = 5
}

/// `PKContactField`.
public struct PKContactField: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
}

// MARK: - Request model

/// `PKPaymentSummaryItem`. iOS 26.1: `init(label:amount:)` is `.final`.
open class PKPaymentSummaryItem: NSObject {
    open var label: String
    open var amount: NSDecimalNumber
    open var type: PKPaymentSummaryItemType

    public init(label: String, amount: NSDecimalNumber, type: PKPaymentSummaryItemType) {
        self.label = label
        self.amount = amount
        self.type = type
        super.init()
    }

    public convenience init(label: String, amount: NSDecimalNumber) {
        self.init(label: label, amount: amount, type: .final)
    }
}

/// `PKPaymentRequest`. iOS 26.1 defaults: empty strings, no networks,
/// capabilities 0, `.shipping`, no summary items, no required contact fields.
open class PKPaymentRequest: NSObject {
    open var merchantIdentifier: String = ""
    open var countryCode: String = ""
    open var currencyCode: String = ""
    open var supportedNetworks: [PKPaymentNetwork] = []
    open var merchantCapabilities: PKMerchantCapability = []
    open var shippingType: PKShippingType = .shipping
    open var paymentSummaryItems: [PKPaymentSummaryItem] = []
    open var requiredShippingContactFields: Set<PKContactField> = []
    open var requiredBillingContactFields: Set<PKContactField> = []

    public override init() { super.init() }

    /// The networks this device could pay with: none here (the simulator
    /// lists 32; OpenUIKit has no payment networks).
    open class func availableNetworks() -> [PKPaymentNetwork] { [] }
}

// MARK: - Payments (never produced here)

open class PKPaymentMethod: NSObject {
    open var displayName: String? { nil }
    open var network: PKPaymentNetwork? { nil }
    open var type: PKPaymentMethodType { .unknown }
}

open class PKPaymentToken: NSObject {
    open var paymentMethod: PKPaymentMethod { PKPaymentMethod() }
    open var transactionIdentifier: String { "" }
    open var paymentData: Data { Data() }
}

/// `PKPayment`. OpenUIKit never authorises one; a bare instance reads
/// exactly as a bare iOS 26.1 instance does (empty token, no contact).
open class PKPayment: NSObject {
    open var token: PKPaymentToken { PKPaymentToken() }
}

/// `PKPaymentAuthorizationResult`.
open class PKPaymentAuthorizationResult: NSObject {
    open var status: PKPaymentAuthorizationStatus
    /// iOS 26.1: `errors: nil` reads back as an empty array.
    open var errors: [Error]

    public init(status: PKPaymentAuthorizationStatus, errors: [Error]?) {
        self.status = status
        self.errors = errors ?? []
        super.init()
    }
}

// MARK: - Authorization controller

@preconcurrency @MainActor
public protocol PKPaymentAuthorizationViewControllerDelegate: AnyObject {
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController)
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController,
                                            didAuthorizePayment payment: PKPayment,
                                            handler completion: @escaping (PKPaymentAuthorizationResult) -> Void)
}

public extension PKPaymentAuthorizationViewControllerDelegate {
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController,
                                            didAuthorizePayment payment: PKPayment,
                                            handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        completion(PKPaymentAuthorizationResult(status: .failure, errors: nil))
    }
}

@preconcurrency @MainActor
open class PKPaymentAuthorizationViewController: UIViewController {
    open weak var delegate: PKPaymentAuthorizationViewControllerDelegate?

    /// Always nil on OpenUIKit (see the file header): there is no payment
    /// sheet to present.
    public init?(paymentRequest request: PKPaymentRequest) {
        return nil
    }

    public required init?(coder: NSCoder) {
        return nil
    }

    /// False (fail closed; the simulator answers true).
    open class func canMakePayments() -> Bool { false }
    open class func canMakePayments(usingNetworks supportedNetworks: [PKPaymentNetwork]) -> Bool { false }
    open class func canMakePayments(usingNetworks supportedNetworks: [PKPaymentNetwork],
                                    capabilities: PKMerchantCapability) -> Bool { false }
}

// MARK: - Button

/// `PKPaymentButtonType` (iOS 26.1 raws: plain 0, buy 1, setUp 2, inStore 3, donate 4).
public enum PKPaymentButtonType: Int, Sendable {
    case plain = 0, buy = 1, setUp = 2, inStore = 3, donate = 4
    case checkout = 5, book = 6, subscribe = 7, reload = 8, addMoney = 9
    case topUp = 10, order = 11, rent = 12, support = 13, contribute = 14, tip = 15, `continue` = 16
}

/// `PKPaymentButtonStyle` (iOS 26.1 raws: white 0, whiteOutline 1, black 2, automatic 3).
public enum PKPaymentButtonStyle: Int, Sendable {
    case white = 0, whiteOutline = 1, black = 2, automatic = 3
}

/// `PKPaymentButton` — a `UIButton` subclass (iOS 26.1 class chain
/// PKPaymentButton → UIButton → UIControl → UIView). Geometry is measured:
/// `PKPaymentButton()` has frame 140 × 30 and intrinsic size 100 × 30; a
/// `.plain` button's intrinsic size is 100 × 30 and a `.buy` button's
/// 140 × 30; corner radius 4; no title, no background colour, no subviews.
/// The Apple Pay mark is Apple artwork and is not drawn: the button is an
/// empty, correctly sized control. (Apps hide it anyway once
/// `canMakePayments()` is false.)
@preconcurrency @MainActor
open class PKPaymentButton: UIButton {
    public let paymentButtonType: PKPaymentButtonType
    public let paymentButtonStyle: PKPaymentButtonStyle

    /// Corner radius of the button's shape (iOS 26.1 default 4).
    open var cornerRadius: CGFloat = 4 {
        didSet { layer.cornerRadius = cornerRadius }
    }

    public init(paymentButtonType type: PKPaymentButtonType, paymentButtonStyle style: PKPaymentButtonStyle) {
        paymentButtonType = type
        paymentButtonStyle = style
        super.init(frame: .zero)
        layer.cornerRadius = cornerRadius
    }

    /// iOS 26.1: frame (0, 0, 140, 30), intrinsic 100 × 30.
    public convenience init() {
        self.init(paymentButtonType: .plain, paymentButtonStyle: .black)
        frame = CGRect(x: 0, y: 0, width: 140, height: 30)
    }

    public required init?(coder: NSCoder) {
        paymentButtonType = .plain
        paymentButtonStyle = .black
        super.init(coder: coder)
    }

    open override var intrinsicContentSize: CGSize {
        CGSize(width: paymentButtonType == .plain ? 100 : 140, height: 30)
    }
}
