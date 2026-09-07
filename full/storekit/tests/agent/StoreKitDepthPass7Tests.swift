import Foundation
import StoreKit

private func expectDepth7(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

private func base64URLDepth7(_ data: Data) -> String {
    data.base64EncodedString()
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: "=", with: "")
}

private func compactJWSDepth7(
    algorithm: String = "ES256",
    certificates: [String] = [Data("certificate".utf8).base64EncodedString()],
    signature: Data = Data(repeating: 0x5a, count: 64)
) -> String {
    let header = try! JSONSerialization.data(withJSONObject: [
        "alg": algorithm,
        "typ": "JWS",
        "x5c": certificates,
    ])
    let payload = try! JSONSerialization.data(withJSONObject: [
        "transactionId": "42",
        "productId": "depth.product",
    ])
    return [header, payload, signature].map(base64URLDepth7).joined(separator: ".")
}

func testPublicCompactJWSParsing() {
    let compact = compactJWSDepth7()
    let parsed = try! StoreKitJWS(compactSerialization: compact)
    expectDepth7(parsed.compactSerialization == compact, "compact representation")
    expectDepth7(parsed.algorithm == "ES256", "protected algorithm")
    expectDepth7(parsed.payloadJSON?["productId"] as? String == "depth.product", "payload JSON")
    expectDepth7(parsed.signatureData.count == 64, "raw ES256 signature")
    expectDepth7(parsed.x5cChain == [Data("certificate".utf8)], "certificate chain")
}

func testPublicCompactJWSTrustFailsClosed() {
    let parsed = try! StoreKitJWS(compactSerialization: compactJWSDepth7())
    expectDepth7(parsed.signatureVerificationError == .invalidSignature, "no Apple trust roots on Linux")
}

func testPublicCompactJWSRejectsMalformedSecurityFields() {
    for compact in [
        compactJWSDepth7(algorithm: "none"),
        compactJWSDepth7(certificates: []),
        compactJWSDepth7(certificates: ["%%%"]),
        compactJWSDepth7(signature: Data(repeating: 0, count: 63)),
    ] {
        do {
            _ = try StoreKitJWS(compactSerialization: compact)
            preconditionFailure("malformed JWS accepted")
        } catch {
            expectDepth7(error is VerificationResult<Transaction>.VerificationError, "documented verification error")
        }
    }
}

func testAdvancedCommerceStructuralInequality() {
    let period = Product.SubscriptionPeriod(value: 1, unit: .month)
    let firstDetails = Transaction.AdvancedCommerceInfo.Item.Details(
        sku: "one", description: "first", displayName: "One", price: 1
    )
    let secondDetails = Transaction.AdvancedCommerceInfo.Item.Details(
        sku: "two", description: "second", displayName: "Two", price: 2
    )
    expectDepth7(firstDetails != secondDetails, "details inequality")

    let firstItem = Transaction.AdvancedCommerceInfo.Item(details: firstDetails)
    let secondItem = Transaction.AdvancedCommerceInfo.Item(details: secondDetails)
    expectDepth7(firstItem != secondItem, "item inequality")

    let firstOffer = Transaction.AdvancedCommerceInfo.Offer(
        periodCount: 1, price: 1, period: period, reason: .acquisition
    )
    let secondOffer = Transaction.AdvancedCommerceInfo.Offer(
        periodCount: 2, price: 2, period: period, reason: .retention
    )
    expectDepth7(firstOffer != secondOffer, "offer inequality")

    let firstRefund = Transaction.AdvancedCommerceInfo.Refund(
        date: Date(timeIntervalSince1970: 1), type: .full, amount: 1, reason: .unintended
    )
    let secondRefund = Transaction.AdvancedCommerceInfo.Refund(
        date: Date(timeIntervalSince1970: 2), type: .custom, amount: 2, reason: .other
    )
    expectDepth7(firstRefund != secondRefund, "refund inequality")

    let first = Transaction.AdvancedCommerceInfo(
        description: "first", displayName: "One", estimatedTax: 0,
        taxExclusivePrice: 1, requestReferenceID: "one", items: [firstItem],
        period: period, taxCode: "A", taxRate: 0
    )
    let second = Transaction.AdvancedCommerceInfo(
        description: "second", displayName: "Two", estimatedTax: 1,
        taxExclusivePrice: 2, requestReferenceID: "two", items: [secondItem],
        period: period, taxCode: "B", taxRate: 1
    )
    expectDepth7(first != second, "advanced commerce inequality")
}

func testVerificationResultStructuralInequality() {
    let verified = VerificationResult<Int>.verified(1)
    let unverified = VerificationResult<Int>.unverified(1, .invalidSignature)
    expectDepth7(verified != unverified, "verification case participates in equality")
}
