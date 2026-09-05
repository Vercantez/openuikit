#if NUMBERFORMATTER_PORT
import NumberFormatterPort
import Foundation
private typealias TestNumberFormatter = NumberFormatterPort.NumberFormatter
#else
import Foundation
private typealias TestNumberFormatter = NumberFormatter
#endif

private func emit(_ key: String, _ value: Any) {
    print("\(key)\t\(value)")
}

private let locales = ["en_US_POSIX", "en_US", "en_GB", "de_DE", "fr_FR", "ja_JP"]
private let styles: [(String, TestNumberFormatter.Style)] = [
    ("decimal", .decimal),
    ("percent", .percent),
    ("currency", .currency),
    ("ordinal", .ordinal),
]
private let numbers: [NSNumber] = [
    0, 1, -2, 1.25, 1234.5, 1_234_567,
]

for localeID in locales {
    for (styleName, style) in styles {
        let formatter = TestNumberFormatter()
        formatter.locale = Locale(identifier: localeID)
        formatter.numberStyle = style
        for number in numbers {
            emit(
                "num.\(localeID).\(styleName).\(number.stringValue)",
                formatter.string(from: number) ?? "nil"
            )
        }
    }
}

do {
    let formatter = TestNumberFormatter()
    formatter.locale = Locale(identifier: "en_US")
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 4
    emit("frac.1", formatter.string(from: 1) ?? "nil")
    emit("frac.1.2", formatter.string(from: 1.2) ?? "nil")
    emit("frac.1.23456", formatter.string(from: 1.23456) ?? "nil")
    formatter.usesGroupingSeparator = false
    emit("frac.nogroup", formatter.string(from: 12345) ?? "nil")
    formatter.usesGroupingSeparator = true
    emit("frac.group", formatter.string(from: 1_234_567) ?? "nil")
}

private let modes: [(String, TestNumberFormatter.RoundingMode)] = [
    ("ceiling", .ceiling),
    ("floor", .floor),
    ("down", .down),
    ("up", .up),
    ("halfEven", .halfEven),
    ("halfDown", .halfDown),
    ("halfUp", .halfUp),
]
for (name, mode) in modes {
    let formatter = TestNumberFormatter()
    formatter.locale = Locale(identifier: "en_US")
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 1
    formatter.maximumFractionDigits = 1
    formatter.roundingMode = mode
    emit("round.\(name).1.25", formatter.string(from: 1.25) ?? "nil")
    emit("round.\(name).1.15", formatter.string(from: 1.15) ?? "nil")
    emit("round.\(name).-1.25", formatter.string(from: -1.25) ?? "nil")
}

do {
    let formatter = TestNumberFormatter()
    formatter.locale = Locale(identifier: "en_US")
    formatter.numberStyle = .decimal
    emit("parse.en", formatter.number(from: "1,234.5")?.stringValue ?? "nil")
    formatter.locale = Locale(identifier: "de_DE")
    emit("parse.de", formatter.number(from: "1.234,5")?.stringValue ?? "nil")
    formatter.locale = Locale(identifier: "en_US")
    formatter.numberStyle = .percent
    emit("parse.pct", formatter.number(from: "50%")?.stringValue ?? "nil")
}

emit("style.decimal", TestNumberFormatter.Style.decimal.rawValue)
emit("style.currency", TestNumberFormatter.Style.currency.rawValue)
emit("style.percent", TestNumberFormatter.Style.percent.rawValue)
emit("style.ordinal", TestNumberFormatter.Style.ordinal.rawValue)
emit("round.halfEven.raw", TestNumberFormatter.RoundingMode.halfEven.rawValue)
