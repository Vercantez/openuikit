@_spi(OpenUIKitHost) import TipKit
import Foundation

func testDonationTimeRangeValues() {
    precondition(Tips.DonationTimeRange.minute != .hour)
    precondition(Tips.DonationTimeRange.hour != .day)
    precondition(Tips.DonationTimeRange.day != .week)
    precondition(Tips.DonationTimeRange.minutes(2) != .minutes(3))
    precondition(Tips.DonationTimeRange.hours(1) == .hour)
    precondition(Tips.DonationTimeRange.days(1) == .day)
    precondition(Tips.DonationTimeRange.weeks(1) == .week)
    let encoded = try! JSONEncoder().encode(Tips.DonationTimeRange.day)
    let decoded = try! JSONDecoder().decode(Tips.DonationTimeRange.self, from: encoded)
    precondition(decoded == .day)
    var hasher = Hasher()
    decoded.hash(into: &hasher)
    _ = decoded.hashValue
}

func testDonationLimitAndDisplayOptions() {
    let limit = Tips.DonationLimit(maximumCount: 2, maximumAge: .minute)
    precondition(limit.maximumCount == 2)
    precondition(limit.maximumAge == .minute)
    let count = Tips.MaxDisplayCount(3)
    let duration = Tips.MaxDisplayDuration(1.5)
    let ignores = Tips.IgnoresDisplayFrequency(true)
    let option: any TipOption = count
    _ = option
    _ = duration
    _ = ignores
}

func testEmptyDonationCodable() {
    let empty = Tips.EmptyDonation()
    let data = try! JSONEncoder().encode(empty)
    _ = try! JSONDecoder().decode(Tips.EmptyDonation.self, from: data)
}
