import Foundation
import FoundationInternationalization

let posix = Locale(identifier: "en_US_POSIX")
precondition(posix.identifier == "en_US_POSIX", "POSIX locale lost its identity")

let french = Locale(identifier: "fr_FR")
precondition(french.identifier == "fr_FR", "French locale lost its identity")

let number = 12_345.67.formatted(
    .number.precision(.fractionLength(2)).locale(french)
)
precondition(number == "12 345,67", "French number formatting was \(number)")

let relative = Date.now.addingTimeInterval(86_400).formatted(
    .relative(presentation: .numeric).locale(french)
)
precondition(relative == "dans 1 jour", "French relative date was \(relative)")

let internationalURL = URL(string: "https://bücher.example/")
precondition(
    internationalURL?.absoluteString == "https://xn--bcher-kva.example/",
    "IDNA URL conversion was \(internationalURL?.absoluteString ?? "nil")"
)

print(
    "FOUNDATION_INTERNATIONALIZATION_MACHO_OK " +
    "locale=fr_FR number=12 345,67 relative=dans-1-jour idna=xn--bcher-kva"
)
