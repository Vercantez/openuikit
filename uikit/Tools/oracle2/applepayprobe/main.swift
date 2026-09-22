// Apple Pay (PassKit payments) surface ios-oss and its Stripe dependency use,
// read on a private iPhone 16 / iOS 26.1 simulator
// (scripts/applepay_probe_sim.sh). One `key=value` line per measurement;
// transcript: docs/agent_reports/ios-oss-launch3-applepay-oracle-ios26.1.json.
//
// What it reads: PKPaymentNetwork raw strings; PKMerchantCapability,
// PKShippingType, PKPaymentSummaryItemType, PKPaymentAuthorizationStatus,
// PKPaymentButtonType/Style raw values; PKPaymentRequest and
// PKPaymentSummaryItem defaults and round-trips; PKPaymentAuthorizationResult;
// a bare PKPayment's token / payment method; the canMakePayments queries and
// PKPaymentAuthorizationViewController(paymentRequest:) for an empty and a
// complete request; PKPaymentButton's class chain, geometry and defaults.
import UIKit
import PassKit

func out(_ key: String, _ value: Any?) {
    if let value { print("\(key)=\(value)") } else { print("\(key)=nil") }
}

func chain(_ cls: AnyClass) -> [String] {
    var names: [String] = []
    var c: AnyClass? = cls
    while let k = c { names.append(NSStringFromClass(k)); c = class_getSuperclass(k) }
    return names
}

@MainActor
func measure() {
    let networks: [(String, PKPaymentNetwork)] = [
        ("amex", .amex), ("discover", .discover), ("JCB", .JCB), ("masterCard", .masterCard),
        ("chinaUnionPay", .chinaUnionPay), ("visa", .visa), ("maestro", .maestro), ("interac", .interac),
    ]
    for (n, v) in networks { out("network.\(n)", v.rawValue) }
    out("network.availableNetworks.count", PKPaymentRequest.availableNetworks().count)

    out("capability.3DS", PKMerchantCapability.capability3DS.rawValue)
    out("capability.EMV", PKMerchantCapability.capabilityEMV.rawValue)
    out("capability.credit", PKMerchantCapability.capabilityCredit.rawValue)
    out("capability.debit", PKMerchantCapability.capabilityDebit.rawValue)
    out("shippingType.raws", [PKShippingType.shipping, .delivery, .storePickup, .servicePickup].map(\.rawValue))
    out("summaryItemType.raws", [PKPaymentSummaryItemType.final, .pending].map(\.rawValue))
    out("authStatus.raws", [PKPaymentAuthorizationStatus.success, .failure].map(\.rawValue))
    out("buttonType.raws", [PKPaymentButtonType.plain, .buy, .setUp, .inStore, .donate].map(\.rawValue))
    out("buttonStyle.raws", [PKPaymentButtonStyle.white, .whiteOutline, .black, .automatic].map(\.rawValue))

    let r = PKPaymentRequest()
    out("request.merchantIdentifier", r.merchantIdentifier)
    out("request.countryCode", r.countryCode)
    out("request.currencyCode", r.currencyCode)
    out("request.supportedNetworks", r.supportedNetworks.map(\.rawValue))
    out("request.merchantCapabilities", r.merchantCapabilities.rawValue)
    out("request.shippingType", r.shippingType.rawValue)
    out("request.paymentSummaryItems.count", r.paymentSummaryItems.count)
    out("request.requiredShippingContactFields.count", r.requiredShippingContactFields.count)
    out("vc.emptyRequest.isNil", PKPaymentAuthorizationViewController(paymentRequest: r) == nil)

    r.merchantIdentifier = "merchant.com.kickstarter"
    r.supportedNetworks = [.visa, .masterCard, .amex]
    r.merchantCapabilities = .capability3DS
    r.countryCode = "US"
    r.currencyCode = "USD"
    r.shippingType = .shipping
    let item = PKPaymentSummaryItem(label: "Reward", amount: NSDecimalNumber(value: 25.5), type: .final)
    let item2 = PKPaymentSummaryItem(label: "Kickstarter", amount: NSDecimalNumber(string: "30.00"))
    r.paymentSummaryItems = [item, item2]
    out("item.label", item.label)
    out("item.amount", item.amount)
    out("item.type", item.type.rawValue)
    out("item2.type.default", item2.type.rawValue)
    out("item2.amount", item2.amount)
    out("request.set.merchantCapabilities", r.merchantCapabilities.rawValue)
    out("request.set.supportedNetworks", r.supportedNetworks.map(\.rawValue))
    out("vc.completeRequest.isNil", PKPaymentAuthorizationViewController(paymentRequest: r) == nil)

    out("canMakePayments", PKPaymentAuthorizationViewController.canMakePayments())
    out("canMakePayments.visaMcAmex",
        PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: [.visa, .masterCard, .amex]))
    out("canMakePayments.empty", PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: []))
    out("canMakePayments.visa.3DS",
        PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: [.visa], capabilities: .capability3DS))

    let result = PKPaymentAuthorizationResult(status: .failure, errors: [])
    out("result.status", result.status.rawValue)
    out("result.errors.count", result.errors.count)
    let result2 = PKPaymentAuthorizationResult(status: .success, errors: nil)
    out("result2.errors.isNil", (result2.errors as [Error]?) == nil)
    out("result2.errors.count", result2.errors.count)

    let p = PKPayment()
    out("payment.token.transactionIdentifier", p.token.transactionIdentifier)
    out("payment.token.paymentData.count", p.token.paymentData.count)
    out("payment.token.paymentMethod.displayName", p.token.paymentMethod.displayName)
    out("payment.token.paymentMethod.network", p.token.paymentMethod.network?.rawValue)
    out("payment.token.paymentMethod.type", p.token.paymentMethod.type.rawValue)
    out("payment.billingContact.isNil", p.billingContact == nil)

    out("button.chain", chain(PKPaymentButton.self))
    let b = PKPaymentButton()
    out("button.default.frame", b.frame)
    out("button.default.intrinsic", b.intrinsicContentSize)
    out("button.default.cornerRadius", b.cornerRadius)
    out("button.default.isEnabled", b.isEnabled)
    out("button.default.subviews", b.subviews.count)
    let b2 = PKPaymentButton(paymentButtonType: .plain, paymentButtonStyle: .automatic)
    out("button.plainAuto.intrinsic", b2.intrinsicContentSize)
    out("button.plainAuto.cornerRadius", b2.cornerRadius)
    b2.frame = CGRect(x: 0, y: 0, width: 300, height: 48)
    b2.layoutIfNeeded()
    out("button.plainAuto.sizeThatFits.300x48", b2.sizeThatFits(CGSize(width: 300, height: 48)))
    let b3 = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .black)
    out("button.buyBlack.intrinsic", b3.intrinsicContentSize)
    out("button.buyBlack.backgroundColor.isNil", b3.backgroundColor == nil)
    out("button.buyBlack.title", b3.title(for: .normal))
}

MainActor.assumeIsolated { measure() }
print("done=1")
