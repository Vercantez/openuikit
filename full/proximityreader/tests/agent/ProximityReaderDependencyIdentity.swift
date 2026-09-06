import Foundation
import ProximityReader

/// Future clean EC2 probe. Isolated Linux hosts typecheck Foundation
/// values through public ProximityReader APIs; this file is not compiled by
/// the sealed host gate.
func proximityReaderDependencyIdentityProbe() {
    let amount = Decimal(string: "4.00")!
    let request = PaymentCardTransactionRequest(amount: amount, currencyCode: "USD")
    precondition(request.amount == amount)
    precondition(request.currencyCode == "USD")

    let data = Data([0xA0, 0x00, 0x00, 0x00, 0x03])
    var withAID = request
    withAID.preferredAIDList = [data]
    precondition(withAID.preferredAIDList == [data])

    let url = URL(string: "https://example.test/vas")!
    let merchant = VASRequest.Merchant(id: "merchant.example", url: url, localizedName: "Example")
    precondition(merchant.url == url)

    let token = PaymentCardReader.Token(rawValue: "foundation-token")
    precondition(token.rawValue == "foundation-token")

    _ = Foundation.UUID.self
    _ = Foundation.Date.self
    _ = Foundation.Locale.Region("US")
}
