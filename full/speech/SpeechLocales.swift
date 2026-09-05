import Foundation

/// Locale identifiers from Apple's documented dictation list that
/// `SFSpeechRecognizer.supportedLocales()` is specified to match.
///
/// Citation: [supportedLocales()](https://developer.apple.com/documentation/speech/sfspeechrecognizer/supportedlocales())
/// — "Speech recognition supports the same locales that are supported by the
/// keyboard’s dictation feature. For a list of these locales, see
/// [QuickType Keyboard: Dictation](https://www.apple.com/ios/feature-availability/#quicktype-keyboard-dictation)."
///
/// Identifiers are the conventional BCP-47 tags for those published names
/// (`en-US`, `yue-CN`, `wuu-CN`, `zh-HK`, …). Apple's on-device runtime set
/// can be a subset of this catalog; this host returns the documented list
/// itself, not a fabricated device probe.
enum SpeechDocumentedLocales {
    static let identifiers: [String] = [
        "ar-AE", "ar-SA",
        "ca-ES",
        "cs-CZ",
        "da-DK",
        "de-AT", "de-CH", "de-DE",
        "el-GR",
        "en-AE", "en-AU", "en-CA", "en-GB", "en-ID", "en-IE", "en-IN", "en-JP",
        "en-MY", "en-NZ", "en-PH", "en-SA", "en-SG", "en-US", "en-ZA",
        "es-CL", "es-CO", "es-ES", "es-MX", "es-US",
        "fi-FI",
        "fr-BE", "fr-CA", "fr-CH", "fr-FR",
        "he-IL",
        "hi-IN",
        "hr-HR",
        "hu-HU",
        "id-ID",
        "it-CH", "it-IT",
        "ja-JP",
        "ko-KR",
        "ms-MY",
        "nb-NO",
        "nl-BE", "nl-NL",
        "pl-PL",
        "pt-BR", "pt-PT",
        "ro-RO",
        "ru-RU",
        "sk-SK",
        "sv-SE",
        "th-TH",
        "tr-TR",
        "uk-UA",
        "vi-VN",
        "wuu-CN",
        "yue-CN", "yue-HK",
        "zh-CN", "zh-HK", "zh-TW",
    ]

    static let locales: Set<Locale> = Set(identifiers.map { Locale(identifier: $0) })

    static func canonicalIdentifier(_ locale: Locale) -> String {
        locale.identifier.replacingOccurrences(of: "_", with: "-")
    }

    static func isSupported(_ locale: Locale) -> Bool {
        let needle = canonicalIdentifier(locale)
        return identifiers.contains { $0.caseInsensitiveCompare(needle) == .orderedSame }
    }

    static func matchingSupportedLocale(_ locale: Locale) -> Locale? {
        let needle = canonicalIdentifier(locale)
        if let match = identifiers.first(where: { $0.caseInsensitiveCompare(needle) == .orderedSame }) {
            return Locale(identifier: match)
        }
        return nil
    }

    /// Host default when `Locale.current` is not in the documented catalog.
    /// Keyboard-dictation fallback from
    /// [init(locale:)](https://developer.apple.com/documentation/speech/sfspeechrecognizer/init(locale:))
    /// is unobserved on Linux, so the documented `en-US` tag is used.
    static func hostDefaultLocale() -> Locale {
        matchingSupportedLocale(Locale.current) ?? Locale(identifier: "en-US")
    }
}
