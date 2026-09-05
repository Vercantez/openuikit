import XCTest
import Foundation
#if os(Linux)
import StoreKit
#else
import OpenUIKitStoreKit
#endif
import OpenUIKit

final class StoreKitTests: XCTestCase {
    func testProductsForReturnsEmptyArray() async throws {
        let products = try await Product.products(for: ["com.example.pro"])
        XCTAssertTrue(products.isEmpty)
    }

    func testPurchaseThrows() async {
        let product = Product(id: "com.example.pro", displayName: "Pro")
        do {
            _ = try await product.purchase()
            XCTFail("purchase must throw")
        } catch let error as StoreKitError {
            if case .unknown = error {
                // fail-closed
            } else {
                XCTFail("expected StoreKitError.unknown")
            }
        } catch {
            XCTFail("unexpected \(error)")
        }
    }

    func testAppStoreSyncThrows() async {
        do {
            try await AppStore.sync()
            XCTFail("sync must throw")
        } catch is StoreKitError {
            // fail-closed
        } catch {
            XCTFail("unexpected \(error)")
        }
    }

    func testTransactionUpdatesIsEmpty() async {
        var count = 0
        for await _ in Transaction.updates {
            count += 1
        }
        XCTAssertEqual(count, 0)
        let latest = await Transaction.latest(for: "sku")
        XCTAssertNil(latest)
    }

    func testPaymentQueueCannotPay() {
        XCTAssertFalse(SKPaymentQueue.canMakePayments())
        XCTAssertFalse(AppStore.canMakePayments)
    }

    func testProductsRequestDeliversEmptyCatalog() {
        let observer = ProductsSink()
        let request = SKProductsRequest(productIdentifiers: ["a", "b"])
        request.delegate = observer
        request.start()
        XCTAssertEqual(observer.products.count, 0)
        XCTAssertEqual(Set(observer.invalid), ["a", "b"])
        XCTAssertTrue(observer.finished)
    }

    func testReviewRequestDoesNotThrow() {
        SKStoreReviewController.requestReview()
#if !os(Linux)
        let scene = UIWindowScene()
        SKStoreReviewController.requestReview(in: scene)
        AppStore.requestReview(in: scene)
#endif
    }
}

private final class ProductsSink: NSObject, SKProductsRequestDelegate {
    var products: [SKProduct] = []
    var invalid: [String] = []
    var finished = false

    func productsRequest(
        _ request: SKProductsRequest,
        didReceive response: SKProductsResponse
    ) {
        products = response.products
        invalid = response.invalidProductIdentifiers
    }

    func requestDidFinish(_ request: SKRequest) {
        finished = true
    }
}
