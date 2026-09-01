// Apple-shaped localized string values and resources for the portable
// Foundation facade.  The representation keeps the format key and typed
// arguments separate so a bundle translation can reorder or restyle the
// placeholders before the final string is rendered.

import FoundationEssentials
import OpenUIKit

public extension String {
    struct LocalizationOptions {
        public var replacements: [any CVarArg]?

        public init() {
            replacements = nil
        }
    }

    struct LocalizationValue: Equatable, Codable, Sendable,
        ExpressibleByStringInterpolation
    {
        public enum Placeholder: String, Codable, Hashable, Sendable {
            case int
            case uint
            case float
            case double
            case object

            fileprivate var formatSpecifier: String {
                switch self {
                case .int: "%lld"
                case .uint: "%llu"
                case .float: "%f"
                case .double: "%lf"
                case .object: "%@"
                }
            }

            fileprivate var defaultFormatValue: Any {
                switch self {
                case .int: Int64(0)
                case .uint: UInt64(0)
                case .float, .double: Double(0)
                case .object: ""
                }
            }
        }

        fileprivate enum Argument: Equatable, Codable, Sendable {
            case string(String)
            case signed(Int64)
            case unsigned(UInt64)
            case floating(Double)
            case placeholder(Placeholder)

            var formatValue: Any {
                switch self {
                case .string(let value): value
                case .signed(let value): value
                case .unsigned(let value): value
                case .floating(let value): value
                case .placeholder(let placeholder):
                    placeholder.defaultFormatValue
                }
            }
        }

        fileprivate let formatKey: String
        fileprivate let arguments: [Argument]

        public init(_ value: String) {
            formatKey = value
            arguments = []
        }

        @_semantics("localization_key.init_literal")
        public init(stringLiteral value: String) {
            self.init(value)
        }

        @_semantics("localization_key.init_interpolation")
        public init(stringInterpolation: StringInterpolation) {
            formatKey = stringInterpolation.formatKey
            arguments = stringInterpolation.arguments
        }

        fileprivate var renderedValue: String {
            _foundationGuestFormat(
                formatKey,
                arguments: renderedArguments()
            )
        }

        fileprivate func renderedArguments(
            replacements: [Any] = []
        ) -> [Any] {
            var replacementIndex = 0
            return arguments.map { argument in
                guard case .placeholder(let placeholder) = argument else {
                    return argument.formatValue
                }
                guard replacementIndex < replacements.count else {
                    return placeholder.defaultFormatValue
                }
                defer { replacementIndex += 1 }
                return replacements[replacementIndex]
            }
        }

        public struct StringInterpolation: StringInterpolationProtocol,
            Sendable
        {
            fileprivate var formatKey: String
            fileprivate var arguments: [Argument]

            @_semantics("localization.interpolation_init")
            public init(literalCapacity: Int, interpolationCount: Int) {
                formatKey = ""
                formatKey.reserveCapacity(
                    literalCapacity + interpolationCount * 4
                )
                arguments = []
                arguments.reserveCapacity(interpolationCount)
            }

            @_semantics("localization.interpolation.appendLiteral")
            public mutating func appendLiteral(_ literal: String) {
                formatKey += literal
            }

            @_semantics("localization.interpolation.appendInterpolation_@_specifier")
            public mutating func appendInterpolation(_ string: String) {
                append(format: "%@", argument: .string(string))
            }

            public mutating func appendInterpolation(_ substring: Substring) {
                appendInterpolation(String(substring))
            }

            public mutating func appendInterpolation(
                placeholder: Placeholder
            ) {
                append(
                    format: placeholder.formatSpecifier,
                    argument: .placeholder(placeholder)
                )
            }

            @_semantics("localization.interpolation.appendInterpolation_param_specifier")
            public mutating func appendInterpolation(
                placeholder: Placeholder,
                specifier: String
            ) {
                append(
                    format: specifier,
                    argument: .placeholder(placeholder)
                )
            }

            @_semantics("localization.interpolation.appendInterpolation_@_specifier")
            public mutating func appendInterpolation<T>(_ value: T)
                where T: FixedWidthInteger, T: SignedInteger
            {
                append(
                    format: "%lld",
                    argument: .signed(Int64(clamping: value))
                )
            }

            @_semantics("localization.interpolation.appendInterpolation_param_specifier")
            public mutating func appendInterpolation<T>(
                _ value: T,
                specifier: String
            ) where T: FixedWidthInteger, T: SignedInteger {
                append(
                    format: specifier,
                    argument: .signed(Int64(clamping: value))
                )
            }

            @_semantics("localization.interpolation.appendInterpolation_@_specifier")
            public mutating func appendInterpolation<T>(_ value: T)
                where T: FixedWidthInteger, T: UnsignedInteger
            {
                append(
                    format: "%llu",
                    argument: .unsigned(UInt64(clamping: value))
                )
            }

            @_semantics("localization.interpolation.appendInterpolation_param_specifier")
            public mutating func appendInterpolation<T>(
                _ value: T,
                specifier: String
            ) where T: FixedWidthInteger, T: UnsignedInteger {
                append(
                    format: specifier,
                    argument: .unsigned(UInt64(clamping: value))
                )
            }

            @_semantics("localization.interpolation.appendInterpolation_@_specifier")
            public mutating func appendInterpolation(_ value: Float) {
                append(format: "%f", argument: .floating(Double(value)))
            }

            @_semantics("localization.interpolation.appendInterpolation_param_specifier")
            public mutating func appendInterpolation(
                _ value: Float,
                specifier: String
            ) {
                append(format: specifier, argument: .floating(Double(value)))
            }

            @_semantics("localization.interpolation.appendInterpolation_@_specifier")
            public mutating func appendInterpolation(_ value: Double) {
                append(format: "%lf", argument: .floating(value))
            }

            @_semantics("localization.interpolation.appendInterpolation_param_specifier")
            public mutating func appendInterpolation(
                _ value: Double,
                specifier: String
            ) {
                append(format: specifier, argument: .floating(value))
            }

            @_semantics("localization.interpolation.appendInterpolation_@_specifier")
            public mutating func appendInterpolation<T>(_ value: T)
                where T: CustomLocalizedStringResourceConvertible
            {
                let resource = value.localizedStringResource
                formatKey += resource.defaultValue.formatKey
                arguments += resource.defaultValue.arguments
            }

            @available(
                *,
                deprecated,
                message: "Localized interpolation uses an unlocalized description for this value"
            )
            @_semantics("localization.interpolation.appendInterpolation_@_specifier")
            public mutating func appendInterpolation<T>(_ value: T) {
                append(
                    format: "%@",
                    argument: .string(String(describing: value))
                )
            }

            private mutating func append(
                format: String,
                argument: Argument
            ) {
                formatKey += format
                arguments.append(argument)
            }
        }
    }

    @_semantics("string.init_localized")
    init(
        localized keyAndValue: LocalizationValue,
        table: String? = nil,
        bundle: Bundle? = nil,
        locale: Locale = .current,
        comment: StaticString? = nil
    ) {
        self.init(
            localized: LocalizedStringResource(
                keyAndValue,
                table: table,
                locale: locale,
                bundle: bundle.map {
                    .atURL($0.bundleURL)
                } ?? .main,
                comment: comment
            )
        )
    }

    @_semantics("string.init_localized")
    init(
        localized key: StaticString,
        defaultValue: LocalizationValue,
        table: String? = nil,
        bundle: Bundle? = nil,
        locale: Locale = .current,
        comment: StaticString? = nil
    ) {
        self.init(
            localized: LocalizedStringResource(
                key,
                defaultValue: defaultValue,
                table: table,
                locale: locale,
                bundle: bundle.map {
                    .atURL($0.bundleURL)
                } ?? .main,
                comment: comment
            )
        )
    }

    @_semantics("string.init_localized")
    init(
        localized keyAndValue: LocalizationValue,
        options: LocalizationOptions,
        table: String? = nil,
        bundle: Bundle? = nil,
        locale: Locale = .current,
        comment: StaticString? = nil
    ) {
        self.init(
            localized: LocalizedStringResource(
                keyAndValue,
                table: table,
                locale: locale,
                bundle: bundle.map {
                    .atURL($0.bundleURL)
                } ?? .main,
                comment: comment
            ),
            options: options
        )
    }

    @_semantics("string.init_localized")
    init(
        localized key: StaticString,
        defaultValue: LocalizationValue,
        options: LocalizationOptions,
        table: String? = nil,
        bundle: Bundle? = nil,
        locale: Locale = .current,
        comment: StaticString? = nil
    ) {
        self.init(
            localized: LocalizedStringResource(
                key,
                defaultValue: defaultValue,
                table: table,
                locale: locale,
                bundle: bundle.map {
                    .atURL($0.bundleURL)
                } ?? .main,
                comment: comment
            ),
            options: options
        )
    }

    @_disfavoredOverload
    init(localized resource: LocalizedStringResource) {
        self.init(localized: resource, replacementArguments: nil)
    }

    private init(
        localized resource: LocalizedStringResource,
        replacementArguments: [Any]?
    ) {
        let localizationBundle: Bundle?
        switch resource.bundle {
        case .main:
            localizationBundle = .main
        case .forClass(let subject):
            localizationBundle = Bundle(for: subject)
        case .atURL(let url):
            localizationBundle = Bundle(url: url)
        }
        guard let localizationBundle else {
            self = resource.defaultValue.renderedValue
            return
        }
        let localizedFormat = localizationBundle.localizedString(
            forKey: resource.key,
            value: resource.defaultValue.formatKey,
            table: resource.table
        )
        self = _foundationGuestFormat(
            localizedFormat,
            arguments: resource.defaultValue.renderedArguments(
                replacements: replacementArguments ?? []
            )
        )
    }

    @_disfavoredOverload
    init(
        localized resource: LocalizedStringResource,
        options: LocalizationOptions
    ) {
        self.init(
            localized: resource,
            replacementArguments: options.replacements?.map { $0 as Any }
        )
    }
}

public protocol CustomLocalizedStringResourceConvertible {
    var localizedStringResource: LocalizedStringResource { get }
}

public struct LocalizedStringResource: Equatable, Codable,
    CustomLocalizedStringResourceConvertible, ExpressibleByStringInterpolation,
    @unchecked Sendable
{
    public let key: String
    public let defaultValue: String.LocalizationValue
    public let table: String?
    public var locale: Locale
    private let bundleDescription: BundleDescription

    public var bundle: BundleDescription { bundleDescription }

    public enum BundleDescription: @unchecked Sendable {
        case main
        case forClass(AnyClass)
        case atURL(URL)
    }

    @_semantics("string.init_localized")
    public init(
        _ keyAndValue: String.LocalizationValue,
        table: String? = nil,
        locale: Locale = .current,
        bundle: BundleDescription = .main,
        comment: StaticString? = nil
    ) {
        _ = comment
        key = keyAndValue.formatKey
        defaultValue = keyAndValue
        self.table = table
        self.locale = locale
        bundleDescription = bundle
    }

    @_semantics("string.init_localized")
    public init(
        _ key: StaticString,
        defaultValue: String.LocalizationValue,
        table: String? = nil,
        locale: Locale = .current,
        bundle: BundleDescription = .main,
        comment: StaticString? = nil
    ) {
        _ = comment
        self.key = String(describing: key)
        self.defaultValue = defaultValue
        self.table = table
        self.locale = locale
        bundleDescription = bundle
    }

    @_disfavoredOverload
    @_semantics("string.init_localized")
    public init(
        _ keyAndValue: String.LocalizationValue,
        table: String? = nil,
        locale: Locale = .current,
        bundle: Bundle,
        comment: StaticString? = nil
    ) {
        self.init(
            keyAndValue,
            table: table,
            locale: locale,
            bundle: .atURL(bundle.bundleURL),
            comment: comment
        )
    }

    @_disfavoredOverload
    @_semantics("string.init_localized")
    public init(
        _ key: StaticString,
        defaultValue: String.LocalizationValue,
        table: String? = nil,
        locale: Locale = .current,
        bundle: Bundle,
        comment: StaticString? = nil
    ) {
        self.init(
            key,
            defaultValue: defaultValue,
            table: table,
            locale: locale,
            bundle: .atURL(bundle.bundleURL),
            comment: comment
        )
    }

    @_semantics("localization_key.init_literal")
    public init(stringLiteral value: String) {
        self.init(String.LocalizationValue(value))
    }

    @_semantics("localization_key.init_interpolation")
    public init(
        stringInterpolation: String.LocalizationValue.StringInterpolation
    ) {
        self.init(
            String.LocalizationValue(
                stringInterpolation: stringInterpolation
            )
        )
    }

    public var localizedStringResource: LocalizedStringResource { self }

    public static func == (
        lhs: LocalizedStringResource,
        rhs: LocalizedStringResource
    ) -> Bool {
        lhs.key == rhs.key
            && lhs.defaultValue == rhs.defaultValue
            && lhs.table == rhs.table
            && lhs.locale == rhs.locale
            && _bundleDescriptionsEqual(lhs.bundle, rhs.bundle)
    }

    private enum CodingKeys: String, CodingKey {
        case key
        case defaultValue
        case table
        case locale
        case bundleKind
        case bundlePayload
    }

    private enum BundleKind: String, Codable {
        case main
        case forClass
        case atURL
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(key, forKey: .key)
        try container.encode(defaultValue, forKey: .defaultValue)
        try container.encodeIfPresent(table, forKey: .table)
        try container.encode(locale, forKey: .locale)
        switch bundle {
        case .main:
            try container.encode(BundleKind.main, forKey: .bundleKind)
        case .forClass(let subject):
            try container.encode(BundleKind.forClass, forKey: .bundleKind)
            try container.encode(
                NSStringFromClass(subject),
                forKey: .bundlePayload
            )
        case .atURL(let url):
            try container.encode(BundleKind.atURL, forKey: .bundleKind)
            try container.encode(url, forKey: .bundlePayload)
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        key = try container.decode(String.self, forKey: .key)
        defaultValue = try container.decode(
            String.LocalizationValue.self,
            forKey: .defaultValue
        )
        table = try container.decodeIfPresent(String.self, forKey: .table)
        locale = try container.decode(Locale.self, forKey: .locale)
        switch try container.decode(BundleKind.self, forKey: .bundleKind) {
        case .main:
            bundleDescription = .main
        case .forClass:
            let className = try container.decode(
                String.self,
                forKey: .bundlePayload
            )
            guard let subject = NSClassFromString(className) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .bundlePayload,
                    in: container,
                    debugDescription: "localized resource class is unavailable"
                )
            }
            bundleDescription = .forClass(subject)
        case .atURL:
            bundleDescription = .atURL(
                try container.decode(URL.self, forKey: .bundlePayload)
            )
        }
    }
}

private func _bundleDescriptionsEqual(
    _ lhs: LocalizedStringResource.BundleDescription,
    _ rhs: LocalizedStringResource.BundleDescription
) -> Bool {
    switch (lhs, rhs) {
    case (.main, .main):
        true
    case (.forClass(let lhsClass), .forClass(let rhsClass)):
        ObjectIdentifier(lhsClass) == ObjectIdentifier(rhsClass)
    case (.atURL(let lhsURL), .atURL(let rhsURL)):
        lhsURL == rhsURL
    default:
        false
    }
}
