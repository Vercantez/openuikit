import Foundation

/// Objective-C data-detector match root. Apple disables the default
/// constructor; Linux exposes designated inits so tests can build values
/// without a Darwin detector daemon.
public class DDMatch: NSObject {
    public let matchedString: String

    public init(matchedString: String) {
        self.matchedString = matchedString
        super.init()
    }
}

public class DDMatchLink: DDMatch {
    public let url: URL

    public init(matchedString: String, url: URL) {
        self.url = url
        super.init(matchedString: matchedString)
    }
}

public class DDMatchPhoneNumber: DDMatch {
    public let phoneNumber: String
    public let label: String?

    public init(matchedString: String, phoneNumber: String, label: String?) {
        self.phoneNumber = phoneNumber
        self.label = label
        super.init(matchedString: matchedString)
    }
}

public class DDMatchEmailAddress: DDMatch {
    public let emailAddress: String
    public let label: String?

    public init(matchedString: String, emailAddress: String, label: String?) {
        self.emailAddress = emailAddress
        self.label = label
        super.init(matchedString: matchedString)
    }
}

public class DDMatchPostalAddress: DDMatch {
    public let street: String?
    public let city: String?
    public let state: String?
    public let postalCode: String?
    public let country: String?

    public init(
        matchedString: String,
        street: String?,
        city: String?,
        state: String?,
        postalCode: String?,
        country: String?
    ) {
        self.street = street
        self.city = city
        self.state = state
        self.postalCode = postalCode
        self.country = country
        super.init(matchedString: matchedString)
    }
}

public class DDMatchCalendarEvent: DDMatch {
    public let isAllDay: Bool
    public let startDate: Date?
    public let startTimeZone: TimeZone?
    public let endDate: Date?
    public let endTimeZone: TimeZone?

    public init(
        matchedString: String,
        isAllDay: Bool,
        startDate: Date?,
        startTimeZone: TimeZone?,
        endDate: Date?,
        endTimeZone: TimeZone?
    ) {
        self.isAllDay = isAllDay
        self.startDate = startDate
        self.startTimeZone = startTimeZone
        self.endDate = endDate
        self.endTimeZone = endTimeZone
        super.init(matchedString: matchedString)
    }
}

public class DDMatchShipmentTrackingNumber: DDMatch {
    public let carrier: String
    public let trackingNumber: String

    public init(matchedString: String, carrier: String, trackingNumber: String) {
        self.carrier = carrier
        self.trackingNumber = trackingNumber
        super.init(matchedString: matchedString)
    }
}

public class DDMatchFlightNumber: DDMatch {
    public let airline: String
    public let flightNumber: String

    public init(matchedString: String, airline: String, flightNumber: String) {
        self.airline = airline
        self.flightNumber = flightNumber
        super.init(matchedString: matchedString)
    }
}

public class DDMatchMoneyAmount: DDMatch {
    public let amount: Double
    public let currency: String

    public init(matchedString: String, amount: Double, currency: String) {
        self.amount = amount
        self.currency = currency
        super.init(matchedString: matchedString)
    }
}
