#if canImport(SwiftUI)
import SwiftUI
#endif
import Foundation

/// `_PassKit_SwiftUI` overlay types. They compile as inert `View` values on
/// the isolated Foundation host. They do not present Wallet or Apple Pay UI.

public struct PayWithApplePayButtonLabel: Hashable, Sendable {
    public let rawValue: String
    private init(_ rawValue: String) { self.rawValue = rawValue }
    public static let contribute = PayWithApplePayButtonLabel("contribute")
    public static let buy = PayWithApplePayButtonLabel("buy")
    public static let tip = PayWithApplePayButtonLabel("tip")
    public static let book = PayWithApplePayButtonLabel("book")
    public static let rent = PayWithApplePayButtonLabel("rent")
    public static let order = PayWithApplePayButtonLabel("order")
    public static let plain = PayWithApplePayButtonLabel("plain")
    public static let setUp = PayWithApplePayButtonLabel("setUp")
    public static let topUp = PayWithApplePayButtonLabel("topUp")
    public static let donate = PayWithApplePayButtonLabel("donate")
    public static let reload = PayWithApplePayButtonLabel("reload")
    public static let inStore = PayWithApplePayButtonLabel("inStore")
    public static let support = PayWithApplePayButtonLabel("support")
    public static let addMoney = PayWithApplePayButtonLabel("addMoney")
    public static let checkout = PayWithApplePayButtonLabel("checkout")
    public static let `continue` = PayWithApplePayButtonLabel("continue")
    public static let subscribe = PayWithApplePayButtonLabel("subscribe")
}

public struct PayWithApplePayButtonStyle: Hashable, Sendable {
    public let rawValue: String
    private init(_ rawValue: String) { self.rawValue = rawValue }
    public static let whiteOutline = PayWithApplePayButtonStyle("whiteOutline")
    public static let black = PayWithApplePayButtonStyle("black")
    public static let white = PayWithApplePayButtonStyle("white")
    public static let automatic = PayWithApplePayButtonStyle("automatic")
}

public enum PayWithApplePayButtonPaymentAuthorizationPhase {
    case didAuthorize(payment: PKPayment, resultHandler: (PKPaymentAuthorizationResult) -> Void)
    case willAuthorize
    case didFinish
}

public struct PayWithApplePayButton<Fallback: View>: View {
    public typealias Body = EmptyView
    public var body: EmptyView { EmptyView() }

    public init(
        _ label: PayWithApplePayButtonLabel = .plain,
        action: @escaping () -> Void
    ) {
        _ = (label, action)
    }

    public init(
        _ label: PayWithApplePayButtonLabel = .plain,
        request: PKPaymentRequest,
        onPaymentAuthorizationChange: @escaping (PayWithApplePayButtonPaymentAuthorizationPhase) -> Void
    ) {
        _ = (label, request, onPaymentAuthorizationChange)
    }

    public init(
        _ label: PayWithApplePayButtonLabel = .plain,
        request: PKPaymentRequest,
        onPaymentAuthorizationChange: @escaping (PayWithApplePayButtonPaymentAuthorizationPhase) -> Void,
        onMerchantSessionRequested: @escaping () -> Void
    ) {
        _ = (label, request, onPaymentAuthorizationChange, onMerchantSessionRequested)
    }

    public init(
        _ label: PayWithApplePayButtonLabel = .plain,
        action: @escaping () -> Void,
        @ViewBuilder fallback: () -> Fallback
    ) {
        _ = (label, action, fallback())
    }

    public init(
        _ label: PayWithApplePayButtonLabel = .plain,
        request: PKPaymentRequest,
        onPaymentAuthorizationChange: @escaping (PayWithApplePayButtonPaymentAuthorizationPhase) -> Void,
        fallback: () -> Fallback
    ) {
        _ = (label, request, onPaymentAuthorizationChange, fallback())
    }

    public init(
        _ label: PayWithApplePayButtonLabel = .plain,
        request: PKPaymentRequest,
        onPaymentAuthorizationChange: @escaping (PayWithApplePayButtonPaymentAuthorizationPhase) -> Void,
        onMerchantSessionRequested: @escaping () -> Void,
        fallback: () -> Fallback
    ) {
        _ = (label, request, onPaymentAuthorizationChange, onMerchantSessionRequested, fallback())
    }
}

public struct AsyncShareablePassConfiguration<Content: View>: View {
    public typealias Body = EmptyView
    public var body: EmptyView { EmptyView() }

    public enum Result {
        case failure(any Error)
        case loading
        case success(PKAddShareablePassConfiguration)
    }

    public init(
        metadata: [PKShareablePassMetadata],
        action: PKAddShareablePassConfigurationPrimaryAction,
        @ViewBuilder content: @escaping (AsyncShareablePassConfiguration<Content>.Result) -> Content
    ) {
        _ = (metadata, action, content)
    }
}

public struct AddPassToWalletButtonStyle: Hashable, Sendable {
    public let rawValue: String
    private init(_ rawValue: String) { self.rawValue = rawValue }
    public static let blackOutline = AddPassToWalletButtonStyle("blackOutline")
    public static let black = AddPassToWalletButtonStyle("black")
}

public struct AddPassToWalletButtonFilter: Hashable, Sendable {
    private let token: String
    private init(_ token: String) { self.token = token }
    public static func paymentNetwork(_ paymentNetwork: PKPaymentNetwork) -> AddPassToWalletButtonFilter {
        AddPassToWalletButtonFilter("network:\(paymentNetwork.rawValue)")
    }
    public static func productIdentifier(_ productIdentifier: String) -> AddPassToWalletButtonFilter {
        AddPassToWalletButtonFilter("product:\(productIdentifier)")
    }
    public static func primaryAccountIdentifier(_ primaryAccountIdentifier: String) -> AddPassToWalletButtonFilter {
        AddPassToWalletButtonFilter("account:\(primaryAccountIdentifier)")
    }
}

public struct AddPassToWalletButtonResponse: Sendable {
    public var certificates: [Data]
    public var nonce: Data
    public var nonceSignature: Data
    public init(certificates: [Data] = [], nonce: Data = Data(), nonceSignature: Data = Data()) {
        self.certificates = certificates
        self.nonce = nonce
        self.nonceSignature = nonceSignature
    }
}

public struct AddPassToWalletButton<Fallback: View>: View {
    public typealias Body = EmptyView
    public var body: EmptyView { EmptyView() }

    public init(action: @escaping () -> Void) { _ = action }

    public init(_ passes: [PKPass], onCompletion: @escaping (Bool) -> Void) {
        _ = (passes, onCompletion)
    }

    public init(
        _ configuration: PKAddSecureElementPassConfiguration,
        onCompletion: @escaping (Result<[PKSecureElementPass], any Error>) -> Void
    ) {
        _ = (configuration, onCompletion)
    }

    public init(
        carKeyPassword: String,
        supportedRadioTechnologies: PKRadioTechnology,
        issuerIdentifier: String,
        onCompletion: @escaping (Result<PKSecureElementPass, any Error>) -> Void
    ) {
        _ = (carKeyPassword, supportedRadioTechnologies, issuerIdentifier, onCompletion)
    }

    public init(
        carKeyPassword: String,
        supportedRadioTechnologies: PKRadioTechnology,
        issuerIdentifier: String,
        onCompletion: @escaping (Result<PKSecureElementPass, any Error>) -> Void,
        fallback: () -> Fallback
    ) {
        _ = (carKeyPassword, supportedRadioTechnologies, issuerIdentifier, onCompletion, fallback())
    }

    public init(
        _ encryptionScheme: PKEncryptionScheme,
        cardholderName: String,
        passStyle: PKAddPaymentPassStyle = .payment,
        primaryAccountSuffix: String? = nil,
        cardDetails: [PKLabeledValue] = [],
        description: String? = nil,
        filters: [AddPassToWalletButtonFilter] = [],
        onRequest: @escaping (AddPassToWalletButtonResponse) async -> PKAddPaymentPassRequest,
        onCompletion: @escaping (Result<[PKSecureElementPass], any Error>) -> Void
    ) {
        _ = (encryptionScheme, cardholderName, passStyle, primaryAccountSuffix, cardDetails, description, filters, onRequest, onCompletion)
    }

    public init(
        _ encryptionScheme: PKEncryptionScheme,
        primaryAccountSuffix: String,
        passStyle: PKAddPaymentPassStyle = .payment,
        cardDetails: [PKLabeledValue] = [],
        description: String? = nil,
        filters: [AddPassToWalletButtonFilter] = [],
        onRequest: @escaping (AddPassToWalletButtonResponse) async -> PKAddPaymentPassRequest,
        onCompletion: @escaping (Result<[PKSecureElementPass], any Error>) -> Void
    ) {
        _ = (encryptionScheme, primaryAccountSuffix, passStyle, cardDetails, description, filters, onRequest, onCompletion)
    }

    public init(
        _ configuration: PKAddPaymentPassRequestConfiguration,
        onRequest: @escaping (AddPassToWalletButtonResponse) async -> PKAddPaymentPassRequest,
        onCompletion: @escaping (Result<[PKSecureElementPass], any Error>) -> Void
    ) {
        _ = (configuration, onRequest, onCompletion)
    }

    public init(
        _ passes: [PKPass],
        onCompletion: @escaping (Bool) -> Void,
        @ViewBuilder fallback: () -> Fallback
    ) {
        _ = (passes, onCompletion, fallback())
    }

    public init(
        _ configuration: PKAddSecureElementPassConfiguration,
        onCompletion: @escaping (Result<[PKSecureElementPass], any Error>) -> Void,
        @ViewBuilder fallback: () -> Fallback
    ) {
        _ = (configuration, onCompletion, fallback())
    }

    public init(
        _ encryptionScheme: PKEncryptionScheme,
        cardholderName: String,
        passStyle: PKAddPaymentPassStyle = .payment,
        primaryAccountSuffix: String? = nil,
        cardDetails: [PKLabeledValue] = [],
        description: String? = nil,
        filters: [AddPassToWalletButtonFilter] = [],
        onRequest: @escaping (AddPassToWalletButtonResponse) async -> PKAddPaymentPassRequest,
        onCompletion: @escaping (Result<[PKSecureElementPass], any Error>) -> Void,
        fallback: () -> Fallback
    ) {
        _ = (encryptionScheme, cardholderName, passStyle, primaryAccountSuffix, cardDetails, description, filters, onRequest, onCompletion, fallback())
    }

    public init(
        _ encryptionScheme: PKEncryptionScheme,
        primaryAccountSuffix: String,
        passStyle: PKAddPaymentPassStyle = .payment,
        cardDetails: [PKLabeledValue] = [],
        description: String? = nil,
        filters: [AddPassToWalletButtonFilter] = [],
        onRequest: @escaping (AddPassToWalletButtonResponse) async -> PKAddPaymentPassRequest,
        onCompletion: @escaping (Result<[PKSecureElementPass], any Error>) -> Void,
        fallback: () -> Fallback
    ) {
        _ = (encryptionScheme, primaryAccountSuffix, passStyle, cardDetails, description, filters, onRequest, onCompletion, fallback())
    }

    public init(
        _ configuration: PKAddPaymentPassRequestConfiguration,
        onRequest: @escaping (AddPassToWalletButtonResponse) async -> PKAddPaymentPassRequest,
        onCompletion: @escaping (Result<[PKSecureElementPass], any Error>) -> Void,
        fallback: () -> Fallback
    ) {
        _ = (configuration, onRequest, onCompletion, fallback())
    }
}

public struct VerifyIdentityWithWalletButtonLabel: Hashable, Sendable {
    public let rawValue: String
    private init(_ rawValue: String) { self.rawValue = rawValue }
    public static let verifyIdentity = VerifyIdentityWithWalletButtonLabel("verifyIdentity")
    public static let verify = VerifyIdentityWithWalletButtonLabel("verify")
    public static let verifyAge = VerifyIdentityWithWalletButtonLabel("verifyAge")
    public static let `continue` = VerifyIdentityWithWalletButtonLabel("continue")
}

public struct VerifyIdentityWithWalletButtonStyle: Hashable, Sendable {
    public let rawValue: String
    private init(_ rawValue: String) { self.rawValue = rawValue }
    public static let black = VerifyIdentityWithWalletButtonStyle("black")
    public static let blackOutline = VerifyIdentityWithWalletButtonStyle("blackOutline")
}

public struct VerifyIdentityWithWalletButton<Fallback: View>: View {
    public typealias Body = EmptyView
    public var body: EmptyView { EmptyView() }

    public init(
        _ label: VerifyIdentityWithWalletButtonLabel = .verifyIdentity,
        request: PKIdentityRequest,
        onCompletion: @escaping (Result<PKIdentityDocument, any Error>) -> Void
    ) {
        _ = (label, request, onCompletion)
    }

    public init(
        _ label: VerifyIdentityWithWalletButtonLabel = .verifyIdentity,
        request: PKIdentityRequest,
        onCompletion: @escaping (Result<PKIdentityDocument, any Error>) -> Void,
        fallback: () -> Fallback
    ) {
        _ = (label, request, onCompletion, fallback())
    }
}

public struct PayLaterViewDisplayStyle: Hashable, Sendable {
    public let rawValue: String
    private init(_ rawValue: String) { self.rawValue = rawValue }
    public static let standard = PayLaterViewDisplayStyle("standard")
    public static let badge = PayLaterViewDisplayStyle("badge")
    public static let checkout = PayLaterViewDisplayStyle("checkout")
    public static let price = PayLaterViewDisplayStyle("price")
}

public struct PayLaterViewAction: Hashable, Sendable {
    public let rawValue: String
    private init(_ rawValue: String) { self.rawValue = rawValue }
    public static let learnMore = PayLaterViewAction("learnMore")
    public static let calculator = PayLaterViewAction("calculator")
}

public struct PayLaterView: View {
    public typealias Body = EmptyView
    public var body: EmptyView { EmptyView() }

    public init(amount: Decimal, displayStyle: PayLaterViewDisplayStyle = .standard) {
        _ = (amount, displayStyle)
    }

    public init(amount: Decimal, action: PayLaterViewAction, displayStyle: PayLaterViewDisplayStyle = .standard) {
        _ = (amount, action, displayStyle)
    }
}
