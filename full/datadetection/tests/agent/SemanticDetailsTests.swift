import DataDetection

import Foundation

func testEmailAddressPayload() {
    let payload = DataDetector.Match.SemanticDetails.EmailAddress(
        emailAddress: "ada@example.com",
        label: "work"
    )
    require(payload.emailAddress == "ada@example.com", "email")
    require(payload.label == "work", "label")
    let unlabeled = DataDetector.Match.SemanticDetails.EmailAddress(
        emailAddress: "nobody@example.org",
        label: nil
    )
    require(unlabeled.label == nil, "nil label")
}

func testPhoneNumberPayload() {
    let payload = DataDetector.Match.SemanticDetails.PhoneNumber(
        phoneNumber: "+1 415-555-2671",
        label: "mobile"
    )
    require(payload.phoneNumber == "+1 415-555-2671", "phone")
    require(payload.label == "mobile", "label")
}

func testLinkPayload() {
    let url = URL(string: "https://example.com/path")!
    let payload = DataDetector.Match.SemanticDetails.Link(url: url)
    require(payload.url == url, "url")
    require(payload.url.host == "example.com", "host")
}

func testMoneyAmountPayload() {
    let amount = Decimal(string: "12.34")!
    let payload = DataDetector.Match.SemanticDetails.MoneyAmount(
        amount: amount,
        currency: Locale.Currency("USD")
    )
    require(payload.amount == amount, "amount")
    require(payload.currency.identifier == "USD", "currency")
}

func testMeasurementPayloadAndConversion() {
    let payload = DataDetector.Match.SemanticDetails.Measurement(
        value: 10,
        possibleDimensions: [UnitLength.kilometers]
    )
    require(payload.value == 10, "value")
    require(payload.possibleDimensions.count == 1, "one dimension")
    require(payload.possibleDimensions[0].symbol == UnitLength.kilometers.symbol, "km")
    let meters = payload.measurement(in: UnitLength.meters)
    require(meters.unit == UnitLength.meters, "unit")
    require(abs(meters.value - 10_000) < 0.001, "10 km -> m")
    let same = payload.measurement(in: UnitLength.kilometers)
    require(abs(same.value - 10) < 0.001, "identity conversion")
}

func testFlightNumberPayload() {
    let payload = DataDetector.Match.SemanticDetails.FlightNumber(
        airlineCode: "UA",
        flightNumber: 123
    )
    require(payload.airlineCode == "UA", "airline")
    require(payload.flightNumber == 123, "number")
}

func testCalendarEventPayload() {
    let start = Date(timeIntervalSince1970: 0)
    let end = Date(timeIntervalSince1970: 3600)
    let zone = TimeZone(secondsFromGMT: 0)
    let payload = DataDetector.Match.SemanticDetails.CalendarEvent(
        allDay: false,
        startDate: start,
        startTimeZone: zone,
        endDate: end,
        endTimeZone: zone
    )
    require(payload.allDay == false, "allDay")
    require(payload.startDate == start, "start")
    require(payload.endDate == end, "end")
    require(payload.startTimeZone?.secondsFromGMT() == 0, "start tz")
    require(payload.endTimeZone?.secondsFromGMT() == 0, "end tz")
    let allDay = DataDetector.Match.SemanticDetails.CalendarEvent(
        allDay: true,
        startDate: start,
        startTimeZone: nil,
        endDate: nil,
        endTimeZone: nil
    )
    require(allDay.allDay, "all-day")
    require(allDay.endDate == nil, "open end")
}

func testPostalAddressPayload() {
    let payload = DataDetector.Match.SemanticDetails.PostalAddress(
        fullAddress: "1 Infinite Loop, Cupertino, CA 95014",
        street: "1 Infinite Loop",
        city: "Cupertino",
        state: "CA",
        postalCode: "95014",
        region: "California",
        regionCode: Locale.Region("US"),
        label: "hq"
    )
    require(payload.fullAddress.contains("Cupertino"), "full")
    require(payload.street == "1 Infinite Loop", "street")
    require(payload.city == "Cupertino", "city")
    require(payload.state == "CA", "state")
    require(payload.postalCode == "95014", "zip")
    require(payload.region == "California", "region")
    require(payload.regionCode?.identifier == "US", "regionCode")
    require(payload.label == "hq", "label")
}

func testPaymentIdentifierPayload() {
    let payload = DataDetector.Match.SemanticDetails.PaymentIdentifier(
        identifier: "upi://pay?pa=merchant@upi",
        type: .unifiedPaymentsInterface
    )
    require(payload.identifier.hasPrefix("upi://"), "id")
    require(payload.type == .unifiedPaymentsInterface, "type")
}

func testShipmentTrackingNumberPayload() {
    let url = URL(string: "https://www.ups.com/track?tracknum=1Z999AA10123456784")
    let payload = DataDetector.Match.SemanticDetails.ShipmentTrackingNumber(
        carrier: "UPS",
        trackingNumber: "1Z999AA10123456784",
        trackingURL: url
    )
    require(payload.carrier == "UPS", "carrier")
    require(payload.trackingNumber.hasPrefix("1Z"), "number")
    require(payload.trackingURL == url, "url")
    let failClosed = DataDetector.Match.SemanticDetails.ShipmentTrackingNumber(
        carrier: "UPS",
        trackingNumber: "1Z999AA10123456784",
        trackingURL: nil
    )
    require(failClosed.trackingURL == nil, "nil tracker URL")
}

func testSemanticDetailsEnumCases() {
    let email = DataDetector.Match.SemanticDetails.emailAddress(
        .init(emailAddress: "a@b.c", label: nil)
    )
    let phone = DataDetector.Match.SemanticDetails.phoneNumber(
        .init(phoneNumber: "4155551212", label: nil)
    )
    let link = DataDetector.Match.SemanticDetails.link(
        .init(url: URL(string: "https://example.com")!)
    )
    let money = DataDetector.Match.SemanticDetails.moneyAmount(
        .init(amount: 1, currency: Locale.Currency("EUR"))
    )
    let measurement = DataDetector.Match.SemanticDetails.measurement(
        .init(value: 2, possibleDimensions: [UnitMass.kilograms])
    )
    let flight = DataDetector.Match.SemanticDetails.flightNumber(
        .init(airlineCode: "BA", flightNumber: 204)
    )
    let calendar = DataDetector.Match.SemanticDetails.calendarEvent(
        .init(allDay: true, startDate: nil, startTimeZone: nil, endDate: nil, endTimeZone: nil)
    )
    let postal = DataDetector.Match.SemanticDetails.postalAddress(
        .init(
            fullAddress: "x",
            street: nil,
            city: nil,
            state: nil,
            postalCode: nil,
            region: nil,
            regionCode: nil,
            label: nil
        )
    )
    let payment = DataDetector.Match.SemanticDetails.paymentIdentifier(
        .init(identifier: "upi://pay", type: .unifiedPaymentsInterface)
    )
    let shipment = DataDetector.Match.SemanticDetails.shipmentTrackingNumber(
        .init(carrier: "UPS", trackingNumber: "1Z", trackingURL: nil)
    )

    switch email {
    case .emailAddress(let value): require(value.emailAddress == "a@b.c", "email case")
    default: require(false, "email case")
    }
    switch phone {
    case .phoneNumber(let value): require(value.phoneNumber == "4155551212", "phone case")
    default: require(false, "phone case")
    }
    switch link {
    case .link(let value): require(value.url.host == "example.com", "link case")
    default: require(false, "link case")
    }
    switch money {
    case .moneyAmount(let value): require(value.currency.identifier == "EUR", "money case")
    default: require(false, "money case")
    }
    switch measurement {
    case .measurement(let value): require(value.value == 2, "measurement case")
    default: require(false, "measurement case")
    }
    switch flight {
    case .flightNumber(let value): require(value.airlineCode == "BA", "flight case")
    default: require(false, "flight case")
    }
    switch calendar {
    case .calendarEvent(let value): require(value.allDay, "calendar case")
    default: require(false, "calendar case")
    }
    switch postal {
    case .postalAddress(let value): require(value.fullAddress == "x", "postal case")
    default: require(false, "postal case")
    }
    switch payment {
    case .paymentIdentifier(let value): require(value.type == .unifiedPaymentsInterface, "payment case")
    default: require(false, "payment case")
    }
    switch shipment {
    case .shipmentTrackingNumber(let value): require(value.carrier == "UPS", "shipment case")
    default: require(false, "shipment case")
    }
}

func testMatchPreferredStyleRangeAndDetails() {
    let text = "hello"
    let range = text.startIndex..<text.endIndex
    let match = DataDetector.Match(
        preferredHighlightStyle: .url,
        range: range,
        details: .link(.init(url: URL(string: "https://example.com")!))
    )
    require(match.preferredHighlightStyle == .url, "style")
    require(match.range == range, "range")
    if case .link(let link) = match.details {
        require(link.url.host == "example.com", "details")
    } else {
        require(false, "details")
    }
    let nilRange = DataDetector.Match(
        preferredHighlightStyle: .hidden,
        range: nil,
        details: .phoneNumber(.init(phoneNumber: "0", label: nil))
    )
    require(nilRange.range == nil, "nil range")
    require(nilRange.preferredHighlightStyle == .hidden, "hidden")
}
