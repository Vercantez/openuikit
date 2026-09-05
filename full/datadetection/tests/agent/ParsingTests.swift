import DataDetection

import Foundation

func testParseEmail() {
    let text = "Contact ada@example.com for details."
    let matches = DataDetector.collectMatches(in: text, types: .emailAddress)
    require(matches.count == 1, "one email")
    guard case .emailAddress(let email) = matches[0].details else {
        require(false, "email details")
        return
    }
    require(email.emailAddress == "ada@example.com", "address")
    require(email.label == nil, "no label")
    require(matches[0].preferredHighlightStyle == .regular, "style")
    require(matches[0].range != nil, "range")
}

func testParseLink() {
    let text = "See https://example.com/docs and www.example.org now."
    let matches = DataDetector.collectMatches(in: text, types: .link)
    require(matches.count == 2, "two links")
    guard case .link(let first) = matches[0].details else {
        require(false, "first link")
        return
    }
    require(first.url.scheme == "https", "https")
    require(matches[0].preferredHighlightStyle == .url, "url style")
    guard case .link(let second) = matches[1].details else {
        require(false, "second link")
        return
    }
    require(second.url.host == "www.example.org" || second.url.host == "example.org", "www host")
}

func testParsePhone() {
    let text = "Call (415) 555-2671 today."
    let matches = DataDetector.collectMatches(in: text, types: .phoneNumber)
    require(matches.count == 1, "one phone")
    guard case .phoneNumber(let phone) = matches[0].details else {
        require(false, "phone details")
        return
    }
    require(phone.phoneNumber.contains("415"), "digits present")
    require(phone.label == nil, "label fail-closed")
}

func testParseMoney() {
    let dollar = DataDetector.collectMatches(in: "Total $12.34 please", types: .moneyAmount)
    require(dollar.count == 1, "dollar")
    guard case .moneyAmount(let usd) = dollar[0].details else {
        require(false, "usd")
        return
    }
    require(usd.amount == Decimal(string: "12.34"), "amount")
    require(usd.currency.identifier == "USD", "USD")

    let coded = DataDetector.collectMatches(in: "Price EUR 99", types: .moneyAmount)
    require(coded.count == 1, "EUR")
    guard case .moneyAmount(let eur) = coded[0].details else {
        require(false, "eur")
        return
    }
    require(eur.currency.identifier == "EUR", "EUR code")
}

func testParseMeasurement() {
    let text = "The runway is 10 km long."
    let matches = DataDetector.collectMatches(in: text, types: .measurement)
    require(matches.count == 1, "one measurement")
    guard case .measurement(let payload) = matches[0].details else {
        require(false, "measurement")
        return
    }
    require(payload.value == 10, "value")
    let meters = payload.measurement(in: UnitLength.meters)
    require(abs(meters.value - 10_000) < 0.001, "convert")
}

func testParseFlight() {
    let text = "Board UA123 at gate 4."
    let matches = DataDetector.collectMatches(in: text, types: .flightNumber)
    require(matches.count == 1, "one flight")
    guard case .flightNumber(let flight) = matches[0].details else {
        require(false, "flight")
        return
    }
    require(flight.airlineCode == "UA", "UA")
    require(flight.flightNumber == 123, "123")
}

func testParseISOCalendar() {
    var options = DataDetector.Options()
    options.documentTimeZone = TimeZone(secondsFromGMT: 0)
    let day = DataDetector.collectMatches(
        in: "Due 2026-09-05 at the office",
        types: .calendarEvent,
        options: options
    )
    require(day.count == 1, "day")
    guard case .calendarEvent(let event) = day[0].details else {
        require(false, "calendar")
        return
    }
    require(event.allDay, "date-only is all-day")
    require(event.startDate != nil, "start")
    require(event.endDate == nil, "end fail-closed")
}

func testParseUSPostal() {
    let text = "Ship to 1 Infinite Loop, Cupertino, CA 95014 please."
    let matches = DataDetector.collectMatches(in: text, types: .postalAddress)
    require(matches.count == 1, "one address")
    guard case .postalAddress(let address) = matches[0].details else {
        require(false, "postal")
        return
    }
    require(address.street == "1 Infinite Loop", "street")
    require(address.city == "Cupertino", "city")
    require(address.state == "CA", "state")
    require(address.postalCode == "95014", "zip")
    require(address.regionCode?.identifier == "US", "US region")
    require(address.label == nil, "label")
}

func testParseUPSTracking() {
    let text = "Track 1Z999AA10123456784 with UPS."
    let matches = DataDetector.collectMatches(in: text, types: .shipmentTrackingNumber)
    require(matches.count == 1, "one tracking")
    guard case .shipmentTrackingNumber(let tracking) = matches[0].details else {
        require(false, "tracking")
        return
    }
    require(tracking.carrier == "UPS", "UPS")
    require(tracking.trackingNumber == "1Z999AA10123456784", "number")
    require(tracking.trackingURL == nil, "no invented Apple tracker URL")
}

func testParseUPIPayment() {
    let text = "Pay upi://pay?pa=merchant@upi now."
    let matches = DataDetector.collectMatches(in: text, types: .paymentIdentifier)
    require(matches.count == 1, "one UPI")
    guard case .paymentIdentifier(let payment) = matches[0].details else {
        require(false, "payment")
        return
    }
    require(payment.identifier.hasPrefix("upi://"), "upi uri")
    require(payment.type == .unifiedPaymentsInterface, "UPI system")
}

func testParseRespectsMatchTypeFilter() {
    let text = "ada@example.com https://example.com $5"
    let emails = DataDetector.collectMatches(in: text, types: .emailAddress)
    require(emails.count == 1, "email filter")
    require(
        DataDetector.collectMatches(in: text, types: .flightNumber).isEmpty,
        "flight filter empty"
    )
    let none = DataDetector.collectMatches(in: text, types: [])
    require(none.isEmpty, "empty types")
}

func testParseEmptyAndNoMatch() {
    require(DataDetector.collectMatches(in: "", types: .all).isEmpty, "empty text")
    require(
        DataDetector.collectMatches(in: "no structured tokens here", types: .all).isEmpty,
        "no match"
    )
}

func testDataDetectorMatchesOpaqueSequence() {
    let text = "Write to ada@example.com"
    let sequence = text.dataDetectorMatches(.emailAddress)
    _ = String(describing: type(of: sequence))
    let defaults = text.dataDetectorMatches()
    _ = String(describing: type(of: defaults))
    let collected = DataDetector.collectMatches(in: text, types: .emailAddress)
    require(collected.count == 1, "collect agrees")
}

func testDataDetectorNamespaceExists() {
    let _: DataDetector.MatchType = .all
    let _: DataDetector.Options = DataDetector.Options()
    require(!DataDetector.MatchType.link.isEmpty, "namespace")
}
