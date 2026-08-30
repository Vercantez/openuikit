import Foundation

let serviceDate = Date(timeIntervalSince1970: 1_709_227_509.125)

func emitDateFormatterRows() {
    let patterns = [
        "dd MMM",
        "EEE, dd MMMM",
        "yyyy-MM-dd HH:mm:ss",
        "h:mm a",
        "yyyy-MM-dd'T'HH:mm:ss.SSSXXX",
        "hh 'o''clock' a",
    ]
    for localeID in ["en_US_POSIX", "en_GB", "fr_FR"] {
        for zoneID in ["GMT", "America/Chicago"] {
            for pattern in patterns {
                let formatter = Foundation.DateFormatter()
                formatter.locale = Locale(identifier: localeID)
                formatter.timeZone = TimeZone(identifier: zoneID)!
                formatter.dateFormat = pattern
                print("pattern|\(localeID)|\(zoneID)|\(pattern)|\(formatter.string(from: serviceDate))")
            }
        }
    }

    for localeID in ["en_US_POSIX", "en_GB", "fr_FR"] {
        for dateStyle in [Foundation.DateFormatter.Style.none, .short, .medium, .long, .full] {
            for timeStyle in [Foundation.DateFormatter.Style.none, .short, .medium, .long] {
                if dateStyle == .none && timeStyle == .none { continue }
                let formatter = Foundation.DateFormatter()
                formatter.locale = Locale(identifier: localeID)
                formatter.timeZone = TimeZone(identifier: "GMT")!
                formatter.dateStyle = dateStyle
                formatter.timeStyle = timeStyle
                print("style|\(localeID)|\(dateStyle.rawValue)|\(timeStyle.rawValue)|\(formatter.string(from: serviceDate))")
            }
        }
    }
}

emitDateFormatterRows()
