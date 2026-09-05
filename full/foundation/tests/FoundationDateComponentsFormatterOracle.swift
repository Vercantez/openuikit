#if DATECOMPONENTSFORMATTER_PORT
import DateComponentsFormatterPort
import Foundation
private typealias TestDateComponentsFormatter = DateComponentsFormatterPort.DateComponentsFormatter
private typealias TestCalendarUnit = DateComponentsFormatterPort.NSCalendar.Unit
#else
import Foundation
private typealias TestDateComponentsFormatter = DateComponentsFormatter
private typealias TestCalendarUnit = NSCalendar.Unit
#endif

private func emit(_ key: String, _ value: Any) {
    print("\(key)\t\(value)")
}

private func calendar(for localeID: String) -> Calendar {
    var value = Calendar(identifier: .gregorian)
    value.locale = Locale(identifier: localeID)
    value.timeZone = TimeZone(identifier: "GMT")!
    return value
}

emit("zero.default", TestDateComponentsFormatter.ZeroFormattingBehavior.default.rawValue)
emit("zero.dropLeading", TestDateComponentsFormatter.ZeroFormattingBehavior.dropLeading.rawValue)
emit("zero.dropMiddle", TestDateComponentsFormatter.ZeroFormattingBehavior.dropMiddle.rawValue)
emit("zero.dropTrailing", TestDateComponentsFormatter.ZeroFormattingBehavior.dropTrailing.rawValue)
emit("zero.dropAll", TestDateComponentsFormatter.ZeroFormattingBehavior.dropAll.rawValue)
emit("zero.pad", TestDateComponentsFormatter.ZeroFormattingBehavior.pad.rawValue)
emit("unit.hour", TestCalendarUnit.hour.rawValue)
emit("unit.minute", TestCalendarUnit.minute.rawValue)
emit("unit.second", TestCalendarUnit.second.rawValue)
emit("unit.day", TestCalendarUnit.day.rawValue)

private var hms = DateComponents()
hms.hour = 1
hms.minute = 2
hms.second = 3

private var zeroed = DateComponents()
zeroed.hour = 0
zeroed.minute = 5
zeroed.second = 0

private var mixed = DateComponents()
mixed.day = 2
mixed.hour = 0
mixed.minute = 3

private let styles: [(String, TestDateComponentsFormatter.UnitsStyle)] = [
    ("positional", .positional),
    ("abbreviated", .abbreviated),
    ("short", .short),
    ("full", .full),
    ("brief", .brief),
]

for (styleName, style) in styles {
    let formatter = TestDateComponentsFormatter()
    formatter.unitsStyle = style
    formatter.allowedUnits = [.hour, .minute, .second]
    formatter.zeroFormattingBehavior = []
    formatter.calendar = calendar(for: "en_US")
    emit("dcf.\(styleName).hms", formatter.string(from: hms) ?? "nil")
    emit("dcf.\(styleName).ti", formatter.string(from: TimeInterval(3723)) ?? "nil")
}

private let zeros: [(String, TestDateComponentsFormatter.ZeroFormattingBehavior)] = [
    ("empty", []),
    ("default", .default),
    ("dropLeading", .dropLeading),
    ("dropMiddle", .dropMiddle),
    ("dropTrailing", .dropTrailing),
    ("dropAll", .dropAll),
    ("pad", .pad),
]
for (name, behavior) in zeros {
    let formatter = TestDateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute, .second]
    formatter.zeroFormattingBehavior = behavior
    formatter.calendar = calendar(for: "en_US")
    formatter.unitsStyle = .positional
    emit("dcf.zero.\(name).pos", formatter.string(from: zeroed) ?? "nil")
    formatter.unitsStyle = .abbreviated
    emit("dcf.zero.\(name).abbr", formatter.string(from: zeroed) ?? "nil")
}

do {
    let formatter = TestDateComponentsFormatter()
    formatter.calendar = calendar(for: "en_US")
    formatter.unitsStyle = .full
    formatter.allowedUnits = [.day, .hour, .minute]
    formatter.zeroFormattingBehavior = .dropAll
    emit("dcf.dropall", formatter.string(from: mixed) ?? "nil")
    formatter.zeroFormattingBehavior = .pad
    emit("dcf.pad", formatter.string(from: mixed) ?? "nil")
    formatter.zeroFormattingBehavior = .dropLeading
    emit("dcf.dropleading", formatter.string(from: mixed) ?? "nil")
}

for localeID in ["en_US", "de_DE", "fr_FR", "ja_JP"] {
    let formatter = TestDateComponentsFormatter()
    formatter.calendar = calendar(for: localeID)
    formatter.unitsStyle = .full
    formatter.allowedUnits = [.hour, .minute, .second]
    formatter.zeroFormattingBehavior = []
    emit("dcf.full.\(localeID)", formatter.string(from: TimeInterval(3723)) ?? "nil")
    formatter.unitsStyle = .abbreviated
    emit("dcf.abbr.\(localeID)", formatter.string(from: TimeInterval(3723)) ?? "nil")
}

do {
    let formatter = TestDateComponentsFormatter()
    formatter.calendar = calendar(for: "en_US")
    formatter.unitsStyle = .positional
    formatter.allowedUnits = [.hour, .minute, .second]
    let start = Date(timeIntervalSince1970: 1_709_227_509)
    let end = Date(timeIntervalSince1970: 1_709_227_509 + 3723)
    emit("dcf.range", formatter.string(from: start, to: end) ?? "nil")
}
