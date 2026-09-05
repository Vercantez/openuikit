import DataDetection

import Foundation

func testHighlightStyleCasesHashable() {
    let styles: [DataDetector.Match.HighlightStyle] = [.hidden, .url, .regular]
    require(styles[0] == .hidden, "hidden")
    require(styles[1] == .url, "url")
    require(styles[2] == .regular, "regular")
    require(DataDetector.Match.HighlightStyle.url != .regular, "url != regular")
    require(DataDetector.Match.HighlightStyle.hidden != .url, "hidden != url")
    require(DataDetector.Match.HighlightStyle.regular == .regular, "regular ==")
    require(
        DataDetector.Match.HighlightStyle.url.hashValue == DataDetector.Match.HighlightStyle.url.hashValue,
        "url hashValue stable"
    )
    var hasher = Hasher()
    DataDetector.Match.HighlightStyle.hidden.hash(into: &hasher)
    DataDetector.Match.HighlightStyle.url.hash(into: &hasher)
    DataDetector.Match.HighlightStyle.regular.hash(into: &hasher)
    _ = hasher.finalize()
}

func testPaymentSystemHashable() {
    let system = DataDetector.Match.SemanticDetails.PaymentIdentifier.PaymentSystem.unifiedPaymentsInterface
    require(system == .unifiedPaymentsInterface, "UPI ==")
    require(
        !(system != .unifiedPaymentsInterface),
        "UPI !="
    )
    require(system.hashValue == system.hashValue, "hashValue")
    var hasher = Hasher()
    system.hash(into: &hasher)
    _ = hasher.finalize()
}

func testOptionsDefaultInit() {
    let options = DataDetector.Options()
    require(options.documentDate == nil, "date")
    require(options.documentRegion == nil, "region")
    require(options.documentTimeZone == nil, "timeZone")
    require(options.documentLanguageCode == nil, "language")
}

func testOptionsDocumentFieldsRoundTrip() {
    var options = DataDetector.Options()
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    let zone = TimeZone(identifier: "America/Los_Angeles")
    require(zone != nil, "known zone")
    options.documentDate = date
    options.documentRegion = Locale.Region("US")
    options.documentTimeZone = zone
    options.documentLanguageCode = Locale.LanguageCode("en")
    require(options.documentDate == date, "date round-trip")
    require(options.documentRegion?.identifier == "US", "region")
    require(options.documentTimeZone?.identifier == "America/Los_Angeles", "tz")
    require(options.documentLanguageCode?.identifier == "en", "language")
}
