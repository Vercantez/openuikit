// PassKit's Apple Pay surface against the iOS 26.1 transcript of
// Tools/oracle2/applepayprobe (docs/agent_reports/ios-oss-launch3-applepay-
// oracle-ios26.1.json). Keys quoted above each test. The two fail-closed
// divergences (canMakePayments false, no authorization controller) are
// asserted as such: a test here fails if the port ever claims it can pay.
import XCTest
import Foundation
import OpenUIKit
import PassKit

#if !os(Linux)
@MainActor
#endif
final class ApplePayFailClosedTests: XCTestCase {
    // network.* / capability.* / *.raws
    func testRawValues() {
        XCTAssertEqual([PKPaymentNetwork.amex, .discover, .JCB, .masterCard, .chinaUnionPay, .visa, .maestro, .interac]
                        .map(\.rawValue),
                       ["AmEx", "Discover", "JCB", "MasterCard", "ChinaUnionPay", "Visa", "Maestro", "Interac"])
        XCTAssertEqual([PKMerchantCapability.capability3DS, .capabilityEMV, .capabilityCredit, .capabilityDebit]
                        .map(\.rawValue), [1, 2, 4, 8])
        XCTAssertEqual([PKShippingType.shipping, .delivery, .storePickup, .servicePickup].map(\.rawValue), [0, 1, 2, 3])
        XCTAssertEqual([PKPaymentSummaryItemType.final, .pending].map(\.rawValue), [0, 1])
        XCTAssertEqual([PKPaymentAuthorizationStatus.success, .failure].map(\.rawValue), [0, 1])
        XCTAssertEqual([PKPaymentButtonType.plain, .buy, .setUp, .inStore, .donate].map(\.rawValue), [0, 1, 2, 3, 4])
        XCTAssertEqual([PKPaymentButtonStyle.white, .whiteOutline, .black, .automatic].map(\.rawValue), [0, 1, 2, 3])
    }

    // request.* defaults; item.*; request.set.*
    func testRequestModel() {
        let r = PKPaymentRequest()
        XCTAssertEqual(r.merchantIdentifier, "")
        XCTAssertEqual(r.countryCode, "")
        XCTAssertEqual(r.currencyCode, "")
        XCTAssertTrue(r.supportedNetworks.isEmpty)
        XCTAssertEqual(r.merchantCapabilities.rawValue, 0)
        XCTAssertEqual(r.shippingType, .shipping)
        XCTAssertTrue(r.paymentSummaryItems.isEmpty)
        XCTAssertTrue(r.requiredShippingContactFields.isEmpty)
        r.merchantCapabilities = .capability3DS
        r.supportedNetworks = [.visa, .masterCard, .amex]
        XCTAssertEqual(r.merchantCapabilities.rawValue, 1)
        XCTAssertEqual(r.supportedNetworks.map(\.rawValue), ["Visa", "MasterCard", "AmEx"])
        let item = PKPaymentSummaryItem(label: "Reward", amount: NSDecimalNumber(value: 25.5), type: .final)
        XCTAssertEqual(item.label, "Reward")
        XCTAssertEqual(item.amount, NSDecimalNumber(value: 25.5))
        XCTAssertEqual(PKPaymentSummaryItem(label: "K", amount: NSDecimalNumber(string: "30.00")).type, .final)
        XCTAssertEqual(PKPaymentSummaryItem(label: "K", amount: NSDecimalNumber(string: "30.00")).amount,
                       NSDecimalNumber(value: 30))
    }

    // canMakePayments* (simulator: true) and vc.completeRequest.isNil
    // (simulator: false) — the port fails closed on both.
    func testNoPaymentIsEverPossible() {
        XCTAssertFalse(PKPaymentAuthorizationViewController.canMakePayments())
        XCTAssertFalse(PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: [.visa, .masterCard, .amex]))
        XCTAssertFalse(PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: [.visa],
                                                                            capabilities: .capability3DS))
        XCTAssertTrue(PKPaymentRequest.availableNetworks().isEmpty)
        let r = PKPaymentRequest()
        XCTAssertNil(PKPaymentAuthorizationViewController(paymentRequest: r))
        r.merchantIdentifier = "merchant.com.kickstarter"
        r.supportedNetworks = [.visa]
        r.merchantCapabilities = .capability3DS
        r.countryCode = "US"
        r.currencyCode = "USD"
        r.paymentSummaryItems = [PKPaymentSummaryItem(label: "Kickstarter", amount: 1)]
        XCTAssertNil(PKPaymentAuthorizationViewController(paymentRequest: r))
    }

    // payment.* / result.*
    func testBarePaymentAndResult() {
        let p = PKPayment()
        XCTAssertEqual(p.token.transactionIdentifier, "")
        XCTAssertEqual(p.token.paymentData.count, 0)
        XCTAssertNil(p.token.paymentMethod.displayName)
        XCTAssertNil(p.token.paymentMethod.network)
        XCTAssertEqual(p.token.paymentMethod.type, .unknown)
        let r = PKPaymentAuthorizationResult(status: .failure, errors: [])
        XCTAssertEqual(r.status, .failure)
        XCTAssertEqual(PKPaymentAuthorizationResult(status: .success, errors: nil).errors.count, 0)
    }

    // button.chain / default.frame / *.intrinsic / cornerRadius / title
    func testButtonGeometry() {
        let b = PKPaymentButton()
        XCTAssertTrue((b as AnyObject) is UIButton)
        XCTAssertEqual(b.frame, CGRect(x: 0, y: 0, width: 140, height: 30))
        XCTAssertEqual(b.intrinsicContentSize, CGSize(width: 100, height: 30))
        XCTAssertEqual(b.cornerRadius, 4)
        XCTAssertTrue(b.isEnabled)
        let plain = PKPaymentButton(paymentButtonType: .plain, paymentButtonStyle: .automatic)
        XCTAssertEqual(plain.intrinsicContentSize, CGSize(width: 100, height: 30))
        let buy = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .black)
        XCTAssertEqual(buy.intrinsicContentSize, CGSize(width: 140, height: 30))
        XCTAssertNil(buy.title(for: .normal))
        XCTAssertNil(buy.backgroundColor)
    }
}
