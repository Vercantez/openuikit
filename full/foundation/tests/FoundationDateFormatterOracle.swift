#if DATEFORMATTER_PORT
import DateFormatterPort
import Foundation
private typealias TestDateFormatter = DateFormatterPort.DateFormatter
#else
import Foundation
private typealias TestDateFormatter = DateFormatter
#endif

private func emit(_ key: String, _ value: Any) {
    print("\(key)\t\(value)")
}

private let sample = Date(timeIntervalSince1970: 1_709_227_509.125)

private let patterns = [
    "dd MMM",
    "EEE, dd MMMM",
    "yyyy-MM-dd HH:mm:ss",
    "h:mm a",
    "yyyy-MM-dd'T'HH:mm:ss.SSSXXX",
    "hh 'o''clock' a",
    "G yyyy MMMM d EEEE",
    "D",
    "HH:mm:ssZ",
    "yyyy-MM-dd HH:mm:ss z",
    "yyyy-MM-dd HH:mm:ss zzzz",
]

private let locales = ["en_US_POSIX", "en_US", "en_GB", "de_DE"]
private let nameLocales = ["fr_FR", "ja_JP"]

for localeID in locales {
    for zoneID in ["GMT", "America/Chicago"] {
        for pattern in patterns {
            let formatter = TestDateFormatter()
            formatter.locale = Locale(identifier: localeID)
            formatter.timeZone = TimeZone(identifier: zoneID)!
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.dateFormat = pattern
            emit(
                "pattern.\(localeID).\(zoneID).\(pattern)",
                formatter.string(from: sample)
            )
        }
    }
}

for localeID in nameLocales {
    for pattern in patterns {
        let formatter = TestDateFormatter()
        formatter.locale = Locale(identifier: localeID)
        formatter.timeZone = TimeZone(identifier: "GMT")!
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = pattern
        emit(
            "pattern.\(localeID).GMT.\(pattern)",
            formatter.string(from: sample)
        )
    }
}

private let styles: [TestDateFormatter.Style] = [.none, .short, .medium, .long, .full]
for localeID in locales + nameLocales {
    for dateStyle in styles {
        for timeStyle in styles {
            if dateStyle == .none && timeStyle == .none { continue }
            let formatter = TestDateFormatter()
            formatter.locale = Locale(identifier: localeID)
            formatter.timeZone = TimeZone(identifier: "GMT")!
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.dateStyle = dateStyle
            formatter.timeStyle = timeStyle
            emit(
                "style.\(localeID).\(dateStyle.rawValue).\(timeStyle.rawValue)",
                formatter.string(from: sample)
            )
        }
    }
}

do {
    let formatter = TestDateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(identifier: "GMT")!
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let parsed = formatter.date(from: "2024-02-29 17:25:09")
    emit("parse.posix", parsed.map { String($0.timeIntervalSince1970) } ?? "nil")
    emit(
        "parse.roundtrip",
        parsed.map { formatter.string(from: $0) } ?? "nil"
    )
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXX"
    let iso = formatter.date(from: "2024-02-29T17:25:09.125Z")
    emit("parse.iso", iso.map { String($0.timeIntervalSince1970) } ?? "nil")
    formatter.dateFormat = "M/d/yy"
    let short = formatter.date(from: "2/29/24")
    emit("parse.short", short.map { String($0.timeIntervalSince1970) } ?? "nil")
    formatter.dateFormat = "hh 'o''clock' a"
    let quoted = formatter.date(from: "05 o'clock PM")
    emit("parse.quoted", quoted.map { formatter.string(from: $0) } ?? "nil")
}

do {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "de_DE")
    calendar.timeZone = TimeZone(identifier: "GMT")!
    let formatter = TestDateFormatter()
    formatter.locale = Locale(identifier: "de_DE")
    formatter.calendar = calendar
    formatter.timeZone = TimeZone(identifier: "GMT")!
    formatter.dateFormat = "EEEE, d. MMMM y"
    emit("calendar.de", formatter.string(from: sample))
}
