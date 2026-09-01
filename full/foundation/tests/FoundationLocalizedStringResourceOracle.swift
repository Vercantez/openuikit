import Foundation

private func emit(_ name: String, _ value: String) {
    print("\(name)=\(value)")
}

let literal: LocalizedStringResource = "portable.literal"
emit("literal.key", literal.key)
emit("literal.value", String(localized: literal))

let signed = 42
let signedResource: LocalizedStringResource = "Items \(signed)"
emit("signed.key", signedResource.key)
emit("signed.value", String(localized: signedResource))

let unsigned: UInt = 7
let unsignedResource: LocalizedStringResource = "Unsigned \(unsigned)"
emit("unsigned.key", unsignedResource.key)
emit("unsigned.value", String(localized: unsignedResource))

let floating: Float = 1.5
let double = 2.25
let floatingResource: LocalizedStringResource =
    "Floating \(floating) double \(double)"
emit("floating.key", floatingResource.key)
emit("floating.value", String(localized: floatingResource))

let name = "Ada"
let stringResource: LocalizedStringResource = "Hello \(name)"
emit("string.key", stringResource.key)
emit("string.value", String(localized: stringResource))

let explicit = LocalizedStringResource(
    "portable.explicit",
    defaultValue: "Fallback \(signed)",
    table: "Portable",
    locale: Locale(identifier: "en_US_POSIX")
)
emit("explicit.key", explicit.key)
emit("explicit.value", String(localized: explicit))

var options = String.LocalizationOptions()
options.replacements = [9]
let optionValue: String.LocalizationValue = "Replacement \(signed)"
emit(
    "options.value",
    String(
        localized: optionValue,
        options: options,
        locale: Locale(identifier: "en_US_POSIX")
    )
)

let placeholderValue: String.LocalizationValue =
    "Placeholder \(placeholder: .int)"
emit(
    "placeholder.value",
    String(
        localized: placeholderValue,
        options: options,
        locale: Locale(identifier: "en_US_POSIX")
    )
)

let padded: LocalizedStringResource = "Padded \(7, specifier: "%03lld")"
emit("specifier.key", padded.key)
emit("specifier.value", String(localized: padded))

let encoded = try JSONEncoder().encode(floatingResource)
let decoded = try JSONDecoder().decode(
    LocalizedStringResource.self,
    from: encoded
)
emit("codable", decoded == floatingResource ? "roundtrip" : "mismatch")

print(
    "FOUNDATION_LOCALIZED_STRING_RESOURCE_OK "
        + "literal=1 interpolation=5 explicit=1 options=2 codable=1"
)
