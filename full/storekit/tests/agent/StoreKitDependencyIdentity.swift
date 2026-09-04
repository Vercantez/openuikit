import Foundation
import StoreKit

/// Future clean EC2 probe. Isolated host compilation does not import UIKit
/// or SwiftUI; this file is not part of tests/acceptance/test_host.sh.
let _: Foundation.Decimal.Type = Decimal.self
let _: Foundation.UUID.Type = UUID.self
let _: Foundation.URL.Type = URL.self
let _: Foundation.Date.Type = Date.self
let _: Foundation.NSError.Type = NSError.self
let _: Foundation.NSObject.Type = NSObject.self
let _: StoreKit.Product.Type = Product.self
let _: StoreKit.Transaction.Type = Transaction.self
let _: StoreKit.SKPaymentQueue.Type = SKPaymentQueue.self
let _: StoreKit.SKError.Type = SKError.self

precondition(SKErrorDomain == "SKErrorDomain")
precondition(SKPaymentQueue.canMakePayments() == false)
precondition(AppStore.canMakePayments == false)
precondition(SKError.Code(rawValue: 2) == .paymentCancelled)

let product = Product(id: "identity.sku")
precondition(product.id == "identity.sku")
let payment = SKPayment(product: SKProduct(productIdentifier: product.id))
precondition(payment.productIdentifier == "identity.sku")

print("STOREKIT_DEPENDENCY_IDENTITY_OK")
