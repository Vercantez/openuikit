import Dispatch
import Foundation
import StoreKit

private enum StoreKitTestFailure: Error {
    case message(String)
}

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

private func waitFor(_ work: @escaping () async -> Void) {
    let semaphore = DispatchSemaphore(value: 0)
    Task {
        await work()
        semaphore.signal()
    }
    expect(semaphore.wait(timeout: .now() + .seconds(5)) == .success, "async test timed out")
}

func testPaymentQueueCannotPay() {
    expect(SKPaymentQueue.canMakePayments() == false, "Linux never reports payment entitlement")
    expect(AppStore.canMakePayments == false, "AppStore.canMakePayments is fail-closed")
}

func testProductsUnavailable() {
    waitFor {
        do {
            _ = try await Product.products(for: ["com.example.pro"])
            expect(false, "products(for:) must throw")
        } catch let error as StoreKitPortableError {
            expect(error.code == .productUnavailable, "expected productUnavailable")
        } catch {
            expect(false, "unexpected error \(error)")
        }
    }
}

func testReviewRequestCount() {
    let before = SKStoreReviewController.portableRequestCount
    SKStoreReviewController.requestReview()
    expect(
        SKStoreReviewController.portableRequestCount == before + 1,
        "requestReview increments portableRequestCount without presenting UI"
    )
}

final class RecordingRequestDelegate: NSObject, SKRequestDelegate {
    var failed = 0
    func request(_ request: SKRequest, didFailWithError error: Error) {
        failed += 1
        expect(error is StoreKitPortableError, "SKRequest fails closed")
    }
}

func testRequestFailsClosed() {
    let delegate = RecordingRequestDelegate()
    let request = SKRequest()
    request.delegate = delegate
    request.start()
    expect(delegate.failed == 1, "start() delivers one fail-closed error")
    request.cancel()
    expect(request.isCancelled, "cancel() records cancellation")
}

func testAdNetworkPostbackFails() {
    var seen = 0
    SKAdNetwork.updatePostbackConversionValue(3) { error in
        seen += 1
        expect(error is StoreKitPortableError, "postback completion is fail-closed")
    }
    expect(seen == 1, "completion runs once")
    let coarse = SKAdNetwork.CoarseConversionValue.low
    expect(coarse.rawValue == "low", "coarse conversion raw value")
}

func testSKErrorCodes() {
    for raw in 0...20 {
        expect(SKError.Code(rawValue: raw)?.rawValue == raw, "SKError.Code raw \(raw)")
    }
    expect(SKError.Code(rawValue: 21) == nil, "raw 21 is not a case")
    let error = SKError(.paymentCancelled)
    expect(error.code == .paymentCancelled, "code")
    expect(error.errorCode == 2, "errorCode")
}

func testStoreKitErrorCases() {
    let cancelled = StoreKitError.userCancelled
    let unknown = StoreKitError.unknown
    expect(cancelled.errorDescription != nil, "errorDescription exists")
    switch unknown {
    case .unknown:
        break
    default:
        expect(false, "unknown case")
    }
}

func testPurchaseOptionFactories() {
    let a = Product.PurchaseOption.quantity(1)
    let b = Product.PurchaseOption.quantity(2)
    let c = Product.PurchaseOption.appAccountToken(UUID())
    expect(a != b, "distinct quantities")
    expect(a != c, "quantity != token")
    expect(a == Product.PurchaseOption.quantity(1), "equal quantities")
}

func testStorefrontCurrentNil() {
    waitFor {
        let current = await Storefront.current
        expect(current == nil, "no App Store storefront on Linux")
    }
}

final class RecordingTransactionObserver: NSObject, SKPaymentTransactionObserver {
    var states: [SKPaymentTransactionState] = []
    func paymentQueue(
        _ queue: SKPaymentQueue,
        updatedTransactions transactions: [SKPaymentTransaction]
    ) {
        states.append(contentsOf: transactions.map(\.transactionState))
    }
}

func testPaymentQueueAddFails() {
    let observer = RecordingTransactionObserver()
    let queue = SKPaymentQueue.default()
    queue.add(observer)
    let product = SKProduct(productIdentifier: "com.example.pro")
    queue.add(SKPayment(product: product))
    expect(observer.states == [.failed], "add(payment) notifies a failed transaction")
    queue.remove(observer)
}

func testVerificationResultPayload() {
    let product = Product(id: "sku")
    _ = product
    let transaction = Transaction(
        id: 1,
        productID: "sku",
        purchaseDate: Date(timeIntervalSince1970: 0)
    )
    let verified = VerificationResult.verified(transaction)
    expect(verified.unsafePayloadValue.id == 1, "unsafe payload")
    do {
        let value = try verified.payloadValue
        expect(value.productID == "sku", "payloadValue")
    } catch {
        expect(false, "verified must not throw")
    }
}

func testSubscriptionPeriodUnits() {
    expect(Product.SubscriptionPeriod.Unit.day < .week, "day < week")
    expect(Product.SubscriptionPeriod.Unit.week < .month, "week < month")
    expect(Product.SubscriptionPeriod.Unit.month < .year, "month < year")
    let monthly = Product.SubscriptionPeriod.monthly
    expect(monthly.value == 1 && monthly.unit == .month, "monthly factory")
}

func testAppStoreSyncFails() {
    waitFor {
        do {
            try await AppStore.sync()
            expect(false, "sync must throw")
        } catch let error as StoreKitPortableError {
            expect(error.code == .serviceUnavailable, "sync is serviceUnavailable")
        } catch {
            expect(false, "unexpected \(error)")
        }
    }
}

func testTransactionLatestNil() {
    waitFor {
        let latest = await Transaction.latest(for: "sku")
        expect(latest == nil, "no receipt daemon")
        let entitlement = await Transaction.currentEntitlement(for: "sku")
        expect(entitlement == nil, "no entitlements")
    }
}

func testSKErrorDomain() {
    expect(SKErrorDomain == "SKErrorDomain", "domain constant")
    expect(SKError.errorDomain == SKErrorDomain, "SKError.errorDomain")
}
