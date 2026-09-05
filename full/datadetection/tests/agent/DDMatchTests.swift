import DataDetection

import Foundation

func testDDMatchMatchedString() {
    let match = DDMatch(matchedString: "sample")
    require(match.matchedString == "sample", "matchedString")
    require(type(of: match) == DDMatch.self, "DDMatch type")
}

func testDDMatchLink() {
    let url = URL(string: "https://developer.apple.com")!
    let match = DDMatchLink(matchedString: "developer.apple.com", url: url)
    require(match.matchedString == "developer.apple.com", "matched")
    require(match.url == url, "url")
}

func testDDMatchEmailAddress() {
    let match = DDMatchEmailAddress(
        matchedString: "ada@example.com",
        emailAddress: "ada@example.com",
        label: "work"
    )
    require(match.emailAddress == "ada@example.com", "email")
    require(match.label == "work", "label")
    require(match.matchedString == "ada@example.com", "matched")
}

func testDDMatchPhoneNumber() {
    let match = DDMatchPhoneNumber(
        matchedString: "(415) 555-2671",
        phoneNumber: "4155552671",
        label: nil
    )
    require(match.phoneNumber == "4155552671", "phone")
    require(match.label == nil, "nil label")
}

func testDDMatchPostalAddress() {
    let match = DDMatchPostalAddress(
        matchedString: "1 Infinite Loop, Cupertino, CA 95014",
        street: "1 Infinite Loop",
        city: "Cupertino",
        state: "CA",
        postalCode: "95014",
        country: "United States"
    )
    require(match.street == "1 Infinite Loop", "street")
    require(match.city == "Cupertino", "city")
    require(match.state == "CA", "state")
    require(match.postalCode == "95014", "zip")
    require(match.country == "United States", "country")
}

func testDDMatchCalendarEvent() {
    let start = Date(timeIntervalSince1970: 1000)
    let zone = TimeZone(identifier: "UTC")
    let match = DDMatchCalendarEvent(
        matchedString: "2026-09-05",
        isAllDay: true,
        startDate: start,
        startTimeZone: zone,
        endDate: nil,
        endTimeZone: nil
    )
    require(match.isAllDay, "all day")
    require(match.startDate == start, "start")
    require(match.startTimeZone?.identifier == "UTC" || match.startTimeZone?.identifier == "GMT", "tz")
    require(match.endDate == nil, "end")
    require(match.endTimeZone == nil, "end tz")
}

func testDDMatchFlightNumber() {
    let match = DDMatchFlightNumber(
        matchedString: "UA123",
        airline: "United",
        flightNumber: "123"
    )
    require(match.airline == "United", "airline")
    require(match.flightNumber == "123", "number is String on DDMatch")
}

func testDDMatchMoneyAmount() {
    let match = DDMatchMoneyAmount(
        matchedString: "$12.50",
        amount: 12.50,
        currency: "USD"
    )
    require(abs(match.amount - 12.50) < 0.0001, "amount")
    require(match.currency == "USD", "currency")
}

func testDDMatchShipmentTrackingNumber() {
    let match = DDMatchShipmentTrackingNumber(
        matchedString: "1Z999AA10123456784",
        carrier: "UPS",
        trackingNumber: "1Z999AA10123456784"
    )
    require(match.carrier == "UPS", "carrier")
    require(match.trackingNumber == "1Z999AA10123456784", "number")
}
