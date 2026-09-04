import Foundation
import PassKit

/// Future clean EC2 probe. Isolated Linux hosts typecheck Foundation
/// values through public PassKit APIs; this file is not compiled by the
/// sealed host gate.
func passKitDependencyIdentityProbe() {
    let request = PKPaymentRequest()
    request.merchantIdentifier = "merchant.example"
    request.countryCode = "US"
    request.currencyCode = "USD"
    request.supportedNetworks = [.visa]
    request.merchantCapabilities = [.threeDSecure]
    precondition(request.merchantIdentifier == "merchant.example")

    let item = PKPaymentSummaryItem(
        label: "Total",
        amount: NSDecimalNumber(decimal: 1),
        type: .final
    )
    precondition(item.label == "Total")

    let contact = PKContact()
    contact.emailAddress = "identity@example.com"
    precondition(contact.emailAddress == "identity@example.com")

    _ = PKPaymentNetwork.visa
    _ = Foundation.Data.self
    _ = Foundation.Decimal.self
    _ = Foundation.URL.self
    _ = Foundation.Date.self
}
