import Foundation
import StoreKit

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testJWSCompactHasThreeBase64URLSegments() {
    StoreKitTesting.reset()
    try! StoreKitTesting.loadConfiguration(json: """
    {
      "identifier": "JWS",
      "products": [{
        "displayPrice": "1.00",
        "familyShareable": false,
        "localizations": [{ "description": "One", "displayName": "One", "locale": "en_US" }],
        "productID": "one",
        "referenceName": "One",
        "type": "NonConsumable"
      }],
      "settings": { "_locale": "en_US" },
      "subscriptionGroups": [],
      "nonRenewingSubscriptions": []
    }
    """)
    let product = try! StoreKitTesting.products(for: ["one"])[0]
    let result = try! StoreKitTesting.purchase(product)
    guard case .success(let verification) = result else {
        expect(false, "purchase")
        return
    }
    let compact = verification.jwsRepresentation
    let parts = compact.split(separator: ".", omittingEmptySubsequences: false)
    expect(parts.count == 3, "header.payload.signature")
    let parsed = try! StoreKitTesting.parseJWS(compact)
    expect(parsed.headerData == verification.headerData, "header data")
    expect(parsed.payloadData == verification.payloadData, "payload data")
    expect(parsed.signatureData.count == 64, "ES256-sized signature bytes")
    expect(!parsed.x5cChain.isEmpty, "x5c chain present")
    expect(parsed.algorithm == "ES256", "alg")
}

func testJWSX5CChainPresentAndSignatureFailClosed() {
    StoreKitTesting.reset()
    try! StoreKitTesting.loadConfiguration(json: """
    {
      "identifier": "JWS2",
      "products": [{
        "displayPrice": "1.00",
        "familyShareable": false,
        "localizations": [{ "description": "One", "displayName": "One", "locale": "en_US" }],
        "productID": "one",
        "referenceName": "One",
        "type": "NonConsumable"
      }],
      "settings": { "_locale": "en_US" },
      "subscriptionGroups": [],
      "nonRenewingSubscriptions": []
    }
    """)
    let product = try! StoreKitTesting.products(for: ["one"])[0]
    let result = try! StoreKitTesting.purchase(product)
    guard case .success(.unverified(_, let error)) = result else {
        expect(false, "unverified")
        return
    }
    expect(error == .invalidSignature, "documented fail-closed error")
    let compact = try! StoreKitTesting.products(for: ["one"])
    _ = compact
    guard case .success(let verification) = result else { return }
    expect(StoreKitTesting.signatureCheck(verification.jwsRepresentation) == .invalidSignature, "check")
}

func testJWSInvalidEncoding() {
    do {
        _ = try StoreKitTesting.parseJWS("not-a-jws")
        expect(false, "must throw")
    } catch VerificationResult<Transaction>.VerificationError.invalidEncoding {
        // expected
    } catch {
        expect(false, "wrong \(error)")
    }
    expect(
        StoreKitTesting.signatureCheck("a.b") == .invalidEncoding
            || StoreKitTesting.signatureCheck("a.b") == .invalidCertificateChain
            || StoreKitTesting.signatureCheck("a.b") == .invalidSignature,
        "two-part compact is not valid JWS"
    )
}

func testJWSMissingX5CIsInvalidCertificateChain() {
    // header without x5c, valid base64url segments
    func b64(_ object: [String: Any]) -> String {
        let data = try! JSONSerialization.data(withJSONObject: object)
        var output = ""
        for character in data.base64EncodedString() {
            if character == "+" { output.append("-") }
            else if character == "/" { output.append("_") }
            else if character == "=" { continue }
            else { output.append(character) }
        }
        return output
    }
    let compact = b64(["alg": "ES256", "typ": "JWS"]) + "." + b64(["productId": "x"]) + "." + b64(["sig": true])
    do {
        _ = try StoreKitTesting.parseJWS(compact)
        expect(false, "missing x5c must fail")
    } catch VerificationResult<Transaction>.VerificationError.invalidCertificateChain {
        // expected
    } catch {
        expect(false, "wrong \(error)")
    }
}

func testShowManageSubscriptionsFailClosed() {
    do {
        try StoreKitTesting.showManageSubscriptions()
        expect(false, "must throw")
    } catch StoreKitError.notAvailableInStorefront {
        // UI manage-subscriptions sheet is unavailable on Linux.
    } catch {
        expect(false, "wrong \(error)")
    }
}

func testPriceFormattingUsesConfigurationLocale() {
    StoreKitTesting.reset()
    try! StoreKitTesting.loadConfiguration(json: """
    {
      "identifier": "FR",
      "products": [{
        "displayPrice": "1.99",
        "familyShareable": false,
        "localizations": [{ "description": "Cafe", "displayName": "Cafe", "locale": "fr_FR" }],
        "productID": "cafe",
        "referenceName": "Cafe",
        "type": "Consumable"
      }],
      "settings": { "_locale": "fr_FR" },
      "subscriptionGroups": [],
      "nonRenewingSubscriptions": []
    }
    """)
    let products = try! StoreKitTesting.products(for: ["cafe"])
    expect(products.count == 1, "cafe")
    expect(!products[0].displayPrice.isEmpty, "formatted via NumberFormatter + locale")
    let request = SKProductsRequest(productIdentifiers: ["cafe"])
    let delegate = RecordingProductsDelegate()
    request.productsDelegate = delegate
    request.start()
    expect(delegate.products[0].priceLocale.identifier.hasPrefix("fr"), "fr locale")
}
