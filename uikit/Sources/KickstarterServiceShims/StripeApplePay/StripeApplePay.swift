// Fail-closed stand-in for StripeApplePay from stripe-ios-spm 23.32.0
// (653fc8cf). Surface = what ios-oss touches:
//   STPApplePayContext(paymentRequest:delegate:) + presentApplePay()
//     (PostCampaignCheckoutViewController.swift:394-401) — spelled
//     `StripeApplePay.STPApplePayContext` in the delegate methods
//   STPApplePayContextDelegate's two methods (PostCampaignCheckout:484-520)
//   StripeApplePay.STPIntentClientSecretCompletionBlock
//   STPAPIClient.createToken(with: PKPayment, completion:)
//     (PledgeViewController.swift:566)
//
// Behaviour: Apple Pay through Stripe is unavailable. The context's failable
// initializer always returns nil — the app's own `guard ... else {
// checkoutTerminated() }` path (PostCampaignCheckout:394-397). Token creation
// completes once, on the main queue, with a nil token and an error. PassKit
// is OpenUIKit's (Sources/PassKit, fail-closed Apple Pay measured on iOS
// 26.1); the `canImport` guard keeps the file building where it is absent.
import Foundation
@_exported import StripePayments
#if canImport(PassKit)
import PassKit
#endif

public typealias STPIntentClientSecretCompletionBlock = (String?, Error?) -> Void

#if canImport(PassKit)
public protocol STPApplePayContextDelegate: AnyObject {
    func applePayContext(
        _ context: STPApplePayContext,
        didCreatePaymentMethod paymentMethod: STPPaymentMethod,
        paymentInformation: PKPayment,
        completion: @escaping STPIntentClientSecretCompletionBlock
    )

    func applePayContext(
        _ context: STPApplePayContext,
        didCompleteWith status: STPPaymentStatus,
        error: Error?
    )
}

public final class STPApplePayContext {
    /// Always nil: Apple Pay via Stripe cannot be presented on OpenUIKit.
    public init?(paymentRequest: PKPaymentRequest, delegate: STPApplePayContextDelegate?) {
        return nil
    }

    public func presentApplePay(completion: (() -> Void)? = nil) {}
}

extension STPAPIClient {
    public func createToken(with payment: PKPayment, completion: @escaping (STPToken?, Error?) -> Void) {
        let error = NSError(domain: STPPaymentHandler.shimErrorDomain, code: 1, userInfo: [
            NSLocalizedDescriptionKey: "Stripe is not available on OpenUIKit (fail-closed shim)",
        ])
        DispatchQueue.main.async { completion(nil, error) }
    }
}
#endif
