// Fail-closed stand-in for StripePayments (+ the StripeCore pieces it
// re-exports) from stripe-ios-spm 23.32.0 (653fc8cf). Surface = what ios-oss
// touches, unqualified or as `StripePayments.<T>`:
//   STPAPIClient.shared.publishableKey / .configuration.appleMerchantIdentifier
//     (PledgeViewController:277-278, PostCampaignCheckoutViewController:295-296,
//      PPOContainerViewController:67-68, PaymentMethodSettingsViewController:151)
//   STPAPIClient.shared.retrieveSetupIntent(withClientSecret:completion:)
//     (PledgePaymentMethodsViewController:196), `intent?.paymentMethodID`
//   STPPaymentHandler.shared().confirmPayment(_:with:completion:) /
//     .confirmSetupIntent(_:with:completion:) (PPOContainerViewController:
//     268,290; PostCampaignCheckoutViewController:354; PledgeViewController:490)
//   STPPaymentIntentParams(clientSecret:) + .paymentMethodId,
//   STPSetupIntentConfirmParams(clientSecret:)
//   STPPaymentHandlerActionStatus (.succeeded/.canceled/.failed; extended by
//     STPPaymentHandler+StripePaymentHandlerActionStatus.swift)
//   STPAuthenticationContext (3 conformers; PPO also implements
//     authenticationContextWillDismiss)
//   STPError.stripeDomain, STPErrorCode.cardError (PostCampaignCheckout:462)
//   StripePayments.STPPaymentMethod (.stripeId), StripePayments.STPPaymentStatus
//
// Behaviour: no Stripe API is reachable. Keys and merchant identifiers are
// stored (plain properties in the SDK too) and sent nowhere. Every confirm
// completes once, on the main queue, with `.failed`, a nil intent and an
// NSError in `STPPaymentHandler.shimErrorDomain` (deliberately NOT
// `STPError.stripeDomain`, so the app never mistakes it for a real card
// decline). Every retrieve completes with nil and that error. Intents,
// payment methods and tokens have no public initializer: nothing can
// fabricate one.
import Foundation
import UIKit

// MARK: - Errors

public enum STPError {
    public static let stripeDomain = "com.stripe.lib"
}

public enum STPErrorCode: Int {
    case connectionError = 40
    case invalidRequestError = 50
    case authenticationError = 51
    case apiError = 60
    case cardError = 70
    case cancellationError = 80
}

func stripeUnavailableError() -> NSError {
    NSError(domain: STPPaymentHandler.shimErrorDomain, code: 1, userInfo: [
        NSLocalizedDescriptionKey: "Stripe is not available on OpenUIKit (fail-closed shim)",
    ])
}

// MARK: - API client

public final class STPPaymentConfiguration {
    public var appleMerchantIdentifier: String?
    public init() {}
}

public final class STPAPIClient {
    public static let shared = STPAPIClient()

    public var publishableKey: String?
    public var configuration = STPPaymentConfiguration()

    public init(publishableKey: String? = nil) { self.publishableKey = publishableKey }

    public func retrieveSetupIntent(
        withClientSecret secret: String,
        completion: @escaping (STPSetupIntent?, Error?) -> Void
    ) {
        let error = stripeUnavailableError()
        DispatchQueue.main.async { completion(nil, error) }
    }

    public func retrievePaymentIntent(
        withClientSecret secret: String,
        completion: @escaping (STPPaymentIntent?, Error?) -> Void
    ) {
        let error = stripeUnavailableError()
        DispatchQueue.main.async { completion(nil, error) }
    }
}

// MARK: - Model objects (no public initializers)

public final class STPSetupIntent {
    public let stripeID: String
    public let paymentMethodID: String?
    init(stripeID: String, paymentMethodID: String?) {
        self.stripeID = stripeID
        self.paymentMethodID = paymentMethodID
    }
}

public final class STPPaymentIntent {
    public let stripeId: String
    public let paymentMethodId: String?
    init(stripeId: String, paymentMethodId: String?) {
        self.stripeId = stripeId
        self.paymentMethodId = paymentMethodId
    }
}

public final class STPPaymentMethod {
    public let stripeId: String
    init(stripeId: String) { self.stripeId = stripeId }
}

public final class STPToken {
    public let tokenId: String
    init(tokenId: String) { self.tokenId = tokenId }
}

public enum STPPaymentStatus: Int {
    case success
    case error
    case userCancellation
}

// MARK: - Params

public final class STPPaymentIntentParams {
    public let clientSecret: String
    public var paymentMethodId: String?
    public init(clientSecret: String) { self.clientSecret = clientSecret }
}

public final class STPSetupIntentConfirmParams {
    public let clientSecret: String
    public var paymentMethodID: String?
    public init(clientSecret: String) { self.clientSecret = clientSecret }
}

// MARK: - Payment handler

public protocol STPAuthenticationContext: AnyObject {
    func authenticationPresentingViewController() -> UIViewController
    func authenticationContextWillDismiss(_ viewController: UIViewController)
}

extension STPAuthenticationContext {
    public func authenticationContextWillDismiss(_ viewController: UIViewController) {}
}

public enum STPPaymentHandlerActionStatus: Int {
    case succeeded
    case canceled
    case failed
}

public typealias STPPaymentHandlerActionPaymentIntentCompletionBlock =
    (STPPaymentHandlerActionStatus, STPPaymentIntent?, NSError?) -> Void
public typealias STPPaymentHandlerActionSetupIntentCompletionBlock =
    (STPPaymentHandlerActionStatus, STPSetupIntent?, NSError?) -> Void

public final class STPPaymentHandler {
    /// Not SDK API: the domain of the error every confirmation reports.
    public static let shimErrorDomain = "OpenUIKit.StripeShim"

    private static let sharedHandler = STPPaymentHandler()
    private init() {}

    public static func shared() -> STPPaymentHandler { sharedHandler }

    public func confirmPayment(
        _ paymentParams: STPPaymentIntentParams,
        with authenticationContext: STPAuthenticationContext,
        completion: @escaping STPPaymentHandlerActionPaymentIntentCompletionBlock
    ) {
        let error = stripeUnavailableError()
        DispatchQueue.main.async { completion(.failed, nil, error) }
    }

    public func confirmSetupIntent(
        _ setupIntentConfirmParams: STPSetupIntentConfirmParams,
        with authenticationContext: STPAuthenticationContext,
        completion: @escaping STPPaymentHandlerActionSetupIntentCompletionBlock
    ) {
        let error = stripeUnavailableError()
        DispatchQueue.main.async { completion(.failed, nil, error) }
    }
}
