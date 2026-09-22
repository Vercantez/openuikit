// Fail-closed stand-in for StripePaymentSheet from stripe-ios-spm 23.32.0
// (653fc8cf). Surface = what ios-oss touches:
//   PaymentSheet.Configuration() + .merchantDisplayName,
//     .allowsDelayedPaymentMethods, .defaultBillingDetails.email
//     (PledgePaymentMethodsViewModel:325-329, PaymentMethodSettingsViewModel:
//      138-142)
//   PaymentSheet.FlowController.create(setupIntentClientSecret:configuration:
//     completion:), .paymentOption, .presentPaymentOptions(from:completion:),
//     .confirm(from:completion:) with PaymentSheetResult .completed/.canceled/
//     .failed(error:) (PledgePaymentMethodsViewController:148-215,
//      PaymentMethodSettingsViewController:164-219)
//   the StripePayments surface (STPAPIClient, STPPaymentHandlerActionStatus),
//     re-exported as the real module does
//
// Behaviour: no PaymentSheet can be created. `create` completes once, on the
// main queue, with `.failure` — the app cancels its loading state and shows
// the error banner. `FlowController` has no public initializer, so no
// caller can hold one; its members (for completeness of the type) report no
// payment option and `.failed`.
import Foundation
@_exported import StripeApplePay
@_exported import StripePayments
import UIKit

public enum PaymentSheetResult {
    case completed
    case canceled
    case failed(error: Error)
}

public final class PaymentSheet {
    public struct Address {
        public var city: String?
        public var country: String?
        public var line1: String?
        public var line2: String?
        public var postalCode: String?
        public var state: String?
        public init() {}
    }

    public struct BillingDetails {
        public var address = Address()
        public var email: String?
        public var name: String?
        public var phone: String?
        public init() {}
    }

    public struct Configuration {
        public var merchantDisplayName: String = ""
        public var allowsDelayedPaymentMethods = false
        public var defaultBillingDetails = BillingDetails()
        public init() {}
    }

    public final class FlowController {
        public struct PaymentOptionDisplayData {
            public let image: UIImage
            public let label: String
        }

        public let configuration: Configuration

        init(configuration: Configuration) { self.configuration = configuration }

        /// Not SDK API: the domain of the error `create` reports.
        public static let shimErrorDomain = "OpenUIKit.StripePaymentSheetShim"

        public static func create(
            setupIntentClientSecret: String,
            configuration: Configuration,
            completion: @escaping (Result<FlowController, Error>) -> Void
        ) {
            let error = NSError(domain: shimErrorDomain, code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Stripe PaymentSheet is not available on OpenUIKit (fail-closed shim)",
            ])
            DispatchQueue.main.async { completion(.failure(error)) }
        }

        public static func create(
            paymentIntentClientSecret: String,
            configuration: Configuration,
            completion: @escaping (Result<FlowController, Error>) -> Void
        ) {
            create(setupIntentClientSecret: paymentIntentClientSecret, configuration: configuration,
                   completion: completion)
        }

        public var paymentOption: PaymentOptionDisplayData? { nil }

        public func presentPaymentOptions(from presentingViewController: UIViewController,
                                          completion: (() -> Void)? = nil) {
            completion?()
        }

        public func confirm(from presentingViewController: UIViewController,
                            completion: @escaping (PaymentSheetResult) -> Void) {
            let error = NSError(domain: Self.shimErrorDomain, code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Stripe PaymentSheet is not available on OpenUIKit (fail-closed shim)",
            ])
            DispatchQueue.main.async { completion(.failed(error: error)) }
        }
    }
}
