# Localized string resources in the guest Foundation facade

`LocalizedStringResource.swift` restores the Apple Foundation identities used
by WidgetKit, AppIntents, SwiftUI, and application code without rewriting an
application source file. It publishes `String.LocalizationValue`,
`String.LocalizationOptions`, `LocalizedStringResource`,
`CustomLocalizedStringResourceConvertible`, and the corresponding
`String(localized:)` initializers from the project-owned `Foundation` dylib.

The representation keeps a localization key, default format value, and typed
arguments separate. String, signed and unsigned integer, Float, Double,
explicit placeholder, custom-resource, and fallback description interpolation
produce Apple-shaped format keys. `LocalizationOptions.replacements` fills
only explicit placeholder slots; ordinary interpolated values remain intact.
Bundle descriptions support the main bundle, a class bundle, and an explicit
URL. The complete value is Equatable, Codable, and Sendable.

Rendering first resolves the bundle table through the existing filesystem
localization implementation, then applies the typed arguments. Floating-point
`%f`, `%e`, and `%g` conversions use Darwin `vsnprintf`, including the C default
precision, explicit precision, alternate form, and exponent behavior. This
also closes the former floating-point approximation in the shared
`String(format:)` implementation.

## Evidence

`tests/FoundationLocalizedStringResourceOracle.swift` runs unchanged against
Apple Foundation and against a fresh literal portable module named
`Foundation`. Its 17 output rows compare byte-for-byte and cover literal,
signed, unsigned, Float, Double, String, explicit-key/default, replacement
placeholder, explicit specifier, and Codable round-trip behavior. The portable
binary is rejected if it loads Apple Foundation or CoreFoundation.

The ARM64 Mach-O core-package probe repeats literal, integer and Double
interpolation, placeholder replacement, and Codable behavior after cold launch
under the Linux loader. Publication requires this runtime marker component:

```text
localization=literal,interpolation,placeholders,codable
```

The exact untouched IceCubes WidgetKit consumer remains an independent compile
gate. Its `static let title: LocalizedStringResource = "Account configuration"`
is application source, not a copied or rewritten fixture declaration.

## Deliberate remaining boundaries

The resource locale is preserved and round-tripped, but this tranche still
uses the bundle's preferred-localization chain rather than selecting an
`.lproj` from `resource.locale`. FormatStyle, AttributedString, NSObject, and
custom-resource list interpolation overloads remain future compatibility
surface. Unsupported behavior is not reported by the runtime marker above.
