#if ISO8601DATEFORMATTER_PORT
import ISO8601DateFormatterPort
import Foundation
private typealias TestISO8601DateFormatter = ISO8601DateFormatterPort.ISO8601DateFormatter
#else
import Foundation
private typealias TestISO8601DateFormatter = ISO8601DateFormatter
#endif

private func emit(_ key: String, _ value: Any) {
    print("\(key)\t\(value)")
}

private let sample = Date(timeIntervalSince1970: 1_709_227_509.125)
private let whole = Date(timeIntervalSince1970: 1_709_227_509)

private let gmt = TimeZone(secondsFromGMT: 0)!
private let minusSix = TimeZone(secondsFromGMT: -21_600)!
private let plusOne = TimeZone(secondsFromGMT: 3_600)!

emit("opt.year", TestISO8601DateFormatter.Options.withYear.rawValue)
emit("opt.month", TestISO8601DateFormatter.Options.withMonth.rawValue)
emit("opt.week", TestISO8601DateFormatter.Options.withWeekOfYear.rawValue)
emit("opt.day", TestISO8601DateFormatter.Options.withDay.rawValue)
emit("opt.time", TestISO8601DateFormatter.Options.withTime.rawValue)
emit("opt.zone", TestISO8601DateFormatter.Options.withTimeZone.rawValue)
emit("opt.space", TestISO8601DateFormatter.Options.withSpaceBetweenDateAndTime.rawValue)
emit("opt.dash", TestISO8601DateFormatter.Options.withDashSeparatorInDate.rawValue)
emit("opt.colonTime", TestISO8601DateFormatter.Options.withColonSeparatorInTime.rawValue)
emit("opt.colonZone", TestISO8601DateFormatter.Options.withColonSeparatorInTimeZone.rawValue)
emit("opt.frac", TestISO8601DateFormatter.Options.withFractionalSeconds.rawValue)
emit("opt.fullDate", TestISO8601DateFormatter.Options.withFullDate.rawValue)
emit("opt.fullTime", TestISO8601DateFormatter.Options.withFullTime.rawValue)
emit("opt.internet", TestISO8601DateFormatter.Options.withInternetDateTime.rawValue)

private func format(
    _ name: String,
    _ options: TestISO8601DateFormatter.Options,
    _ zone: TimeZone,
    _ date: Date
) {
    let formatter = TestISO8601DateFormatter()
    formatter.timeZone = zone
    formatter.formatOptions = options
    emit("fmt.\(name)", formatter.string(from: date))
}

format("default", [], gmt, sample)
format("internet", [.withInternetDateTime], gmt, sample)
format("internet.frac", [.withInternetDateTime, .withFractionalSeconds], gmt, sample)
format("internet.whole", [.withInternetDateTime], gmt, whole)
format("fulldate", [.withFullDate], gmt, sample)
format("fulltime", [.withFullTime], gmt, sample)
format("ymd", [.withYear, .withMonth, .withDay, .withDashSeparatorInDate], gmt, sample)
format("ymdtz", [.withYear, .withMonth, .withDay, .withTime, .withTimeZone], gmt, sample)
format("space", [.withFullDate, .withFullTime, .withSpaceBetweenDateAndTime], gmt, sample)
format("minus6", [.withInternetDateTime], minusSix, sample)
format("plus1.frac", [.withInternetDateTime, .withFractionalSeconds], plusOne, sample)
format(
    "week",
    [.withWeekOfYear, .withYear, .withDashSeparatorInDate],
    gmt,
    sample
)
format(
    "week.nodash",
    [.withWeekOfYear, .withYear],
    gmt,
    sample
)

emit(
    "class.internet",
    TestISO8601DateFormatter.string(
        from: sample,
        timeZone: plusOne,
        formatOptions: [.withInternetDateTime]
    )
)

do {
    let formatter = TestISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    emit(
        "parse.frac",
        formatter.date(from: "2024-02-29T17:25:09.125Z")
            .map { String($0.timeIntervalSince1970) } ?? "nil"
    )
    formatter.formatOptions = [.withInternetDateTime]
    emit(
        "parse.z",
        formatter.date(from: "2024-02-29T17:25:09Z")
            .map { String($0.timeIntervalSince1970) } ?? "nil"
    )
    emit(
        "parse.offset",
        formatter.date(from: "2024-02-29T11:25:09-06:00")
            .map { String($0.timeIntervalSince1970) } ?? "nil"
    )
    formatter.formatOptions = [.withFullDate]
    emit(
        "parse.date",
        formatter.date(from: "2024-02-29")
            .map { String($0.timeIntervalSince1970) } ?? "nil"
    )
    emit("parse.bad", formatter.date(from: "not-a-date") == nil)
}
