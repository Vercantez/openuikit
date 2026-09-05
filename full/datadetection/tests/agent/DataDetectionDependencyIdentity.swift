import DataDetection
import Foundation

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest-Foundation success.

private func assertNotDataDetectionType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("DataDetection."))
}

func dataDetectionDependencyIdentityProbe() {
    let url = URL(string: "https://example.com/identity")!
    assertNotDataDetectionType(url)
    let link = DataDetector.Match.SemanticDetails.Link(url: url)
    precondition(link.url == url)
    assertNotDataDetectionType(link.url)

    let date = Date(timeIntervalSince1970: 1_700_000_000)
    assertNotDataDetectionType(date)
    var options = DataDetector.Options()
    options.documentDate = date
    options.documentTimeZone = TimeZone(identifier: "UTC")
    options.documentRegion = Locale.Region("US")
    options.documentLanguageCode = Locale.LanguageCode("en")
    precondition(options.documentDate == date)
    assertNotDataDetectionType(options.documentDate as Any)

    let amount = Decimal(string: "4.50")!
    assertNotDataDetectionType(amount)
    let money = DataDetector.Match.SemanticDetails.MoneyAmount(
        amount: amount,
        currency: Locale.Currency("USD")
    )
    precondition(money.amount == amount)
    assertNotDataDetectionType(money.amount)
    assertNotDataDetectionType(money.currency)

    let meters = UnitLength.meters
    assertNotDataDetectionType(meters)
    let measurement = DataDetector.Match.SemanticDetails.Measurement(
        value: 3,
        possibleDimensions: [meters]
    )
    let converted = measurement.measurement(in: UnitLength.kilometers)
    assertNotDataDetectionType(converted)
    precondition(abs(converted.value - 0.003) < 0.0000001)
}

#if DATADETECTION_IDENTITY_MAIN
dataDetectionDependencyIdentityProbe()
print("DATADETECTION_DEPENDENCY_IDENTITY_OK")
#endif
