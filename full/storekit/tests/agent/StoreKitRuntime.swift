import Foundation
import StoreKit

/// Exercises fail-closed StoreKit behavior for operators and later EC2 runs.
/// The schema-v2 host gate does not compile this file; `StoreKitTests.swift`
/// is the sealed runner input.
enum StoreKitRuntime {
    static func run() {
        precondition(SKPaymentQueue.canMakePayments() == false)
        precondition(AppStore.canMakePayments == false)
        precondition(SKErrorDomain == "SKErrorDomain")
        precondition(SKError.Code.paymentCancelled.rawValue == 2)
        let product = Product(id: "runtime.sku", displayName: "Runtime")
        precondition(product.id == "runtime.sku")
        precondition(product.displayPrice == product.price.description)
        let option = Product.PurchaseOption.quantity(1)
        precondition(option == Product.PurchaseOption.quantity(1))
        SKStoreReviewController.requestReview()
        precondition(SKStoreReviewController.portableRequestCount >= 1)
        let view = ProductView<EmptyView, EmptyView>(id: product.id)
        _ = view.body
        print("STOREKIT_AGENT_RUNTIME_OK")
    }
}
