import Foundation

extension AttributeScopes {
    public struct AccessibilityAttributes: AttributeScope {
        public typealias DecodingConfiguration = AttributeScopeCodableConfiguration
        public typealias EncodingConfiguration = AttributeScopeCodableConfiguration

        private init() {}

        public var accessibilityTextCustom: TextCustomAttribute {
            accessibilityKeyMarker()
        }
        public var accessibilityHeadingLevel: HeadingLevelAttribute {
            accessibilityKeyMarker()
        }
        public var accessibilityTextualContext: TextualContextAttribute {
            accessibilityKeyMarker()
        }
        public var accessibilitySpeechAdjustedPitch: AdjustedPitchAttribute {
            accessibilityKeyMarker()
        }
        public var accessibilitySpeechPhoneticNotation: IPANotationAttribute {
            accessibilityKeyMarker()
        }
        public var accessibilitySpeechAnnouncementsQueued: QueueAnnouncementAttribute {
            accessibilityKeyMarker()
        }
        public var accessibilitySpeechIncludesPunctuation: IncludesPunctuationAttribute {
            accessibilityKeyMarker()
        }
        public var accessibilitySpeechSpellsOutCharacters: SpellOutAttribute {
            accessibilityKeyMarker()
        }
        public var accessibilitySpeechAnnouncementPriority: AnnouncementPriorityAttribute {
            accessibilityKeyMarker()
        }

        public static var attributeKeys: some Sequence<any AttributedStringKey.Type> {
            [
                TextCustomAttribute.self,
                IPANotationAttribute.self,
                HeadingLevelAttribute.self,
                AdjustedPitchAttribute.self,
                TextualContextAttribute.self,
                QueueAnnouncementAttribute.self,
                IncludesPunctuationAttribute.self,
                AnnouncementPriorityAttribute.self,
                SpellOutAttribute.self,
            ]
        }

        @frozen public enum TextCustomAttribute: CodableAttributedStringKey, MarkdownDecodableAttributedStringKey {
            public typealias Value = [String]
            public static var name: String { "UIAccessibilityTextAttributeCustom" }
            public static let markdownName = "accessibilityTextCustom"
            public var description: String { Self.name }
        }

        @frozen public enum IPANotationAttribute: CodableAttributedStringKey, MarkdownDecodableAttributedStringKey {
            public typealias Value = String
            public static var name: String { "UIAccessibilitySpeechAttributeIPANotation" }
            public static let markdownName = "accessibilitySpeechPhoneticNotation"
            public var description: String { Self.name }
        }

        @frozen public enum HeadingLevelAttribute: CodableAttributedStringKey, MarkdownDecodableAttributedStringKey
        {
            public enum HeadingLevel: Int, Codable, Equatable, Hashable, Sendable {
                case unspecified = 0
                case h1 = 1
                case h2 = 2
                case h3 = 3
                case h4 = 4
                case h5 = 5
                case h6 = 6
            }

            public typealias Value = HeadingLevel
            public typealias ObjectiveCValue = NSNumber
            public static var name: String { "UIAccessibilityTextAttributeHeadingLevel" }
            public static let markdownName = "accessibilityHeadingLevel"
            public var description: String { Self.name }

            public static func objectiveCValue(for value: HeadingLevel) throws -> NSNumber {
                NSNumber(value: value.rawValue)
            }

            public static func value(for object: NSNumber) throws -> HeadingLevel {
                HeadingLevel(rawValue: object.intValue) ?? .unspecified
            }
        }

        @frozen public enum AdjustedPitchAttribute: CodableAttributedStringKey, MarkdownDecodableAttributedStringKey
        {
            public typealias Value = Double
            public typealias ObjectiveCValue = NSNumber
            public static var name: String { "UIAccessibilitySpeechAttributePitch" }
            public static let markdownName = "accessibilitySpeechAdjustedPitch"
            public var description: String { Self.name }

            public static func objectiveCValue(for value: Double) throws -> NSNumber {
                NSNumber(value: value)
            }

            public static func value(for object: NSNumber) throws -> Double {
                object.doubleValue
            }
        }

        @frozen public enum TextualContextAttribute: CodableAttributedStringKey, MarkdownDecodableAttributedStringKey
        {
            public enum TextualContext: String, Codable, Equatable, Hashable, Sendable {
                case sourceCode
                case spreadsheet
                case fileSystem
                case messaging
                case wordProcessing
                case narrative
                case console
                case plain
            }

            public typealias Value = TextualContext
            public typealias ObjectiveCValue = NSString
            public static var name: String { "UIAccessibilityTextAttributeContext" }
            public static let markdownName = "accessibilityTextualContext"
            public var description: String { Self.name }

            public static func objectiveCValue(for value: TextualContext) throws -> NSString {
                value.rawValue as NSString
            }

            public static func value(for object: NSString) throws -> TextualContext {
                TextualContext(rawValue: object as String) ?? .plain
            }
        }

        @frozen public enum QueueAnnouncementAttribute: CodableAttributedStringKey, MarkdownDecodableAttributedStringKey {
            public typealias Value = Bool
            public static var name: String { "UIAccessibilitySpeechAttributeQueueAnnouncement" }
            public static let markdownName = "accessibilitySpeechAnnouncementsQueued"
            public var description: String { Self.name }
        }

        @frozen public enum IncludesPunctuationAttribute: CodableAttributedStringKey, MarkdownDecodableAttributedStringKey {
            public typealias Value = Bool
            public static var name: String { "UIAccessibilitySpeechAttributePunctuation" }
            public static let markdownName = "accessibilitySpeechIncludesPunctuation"
            public var description: String { Self.name }
        }

        @frozen public enum AnnouncementPriorityAttribute: CodableAttributedStringKey, MarkdownDecodableAttributedStringKey
        {
            public enum AnnouncementPriority: String, Codable, Equatable, Hashable, Sendable {
                case low
                case high
                case `default`
            }

            public typealias Value = AnnouncementPriority
            public typealias ObjectiveCValue = NSString
            public static var name: String { "UIAccessibilitySpeechAttributeAnnouncementPriority" }
            public static let markdownName = "accessibilitySpeechAnnouncementPriority"
            public var description: String { Self.name }

            public static func objectiveCValue(for value: AnnouncementPriority) throws -> NSString {
                value.rawValue as NSString
            }

            public static func value(for object: NSString) throws -> AnnouncementPriority {
                AnnouncementPriority(rawValue: object as String) ?? .default
            }
        }

        @frozen public enum SpellOutAttribute: CodableAttributedStringKey, MarkdownDecodableAttributedStringKey {
            public typealias Value = Bool
            public static var name: String { "UIAccessibilitySpeechAttributeSpellOut" }
            public static let markdownName = "accessibilitySpeechSpellsOutCharacters"
            public var description: String { Self.name }
        }
    }

    public var accessibility: AttributeScopes.AccessibilityAttributes.Type {
        AttributeScopes.AccessibilityAttributes.self
    }
}

extension AttributeDynamicLookup {
    public subscript<T>(dynamicMember keyPath: KeyPath<AttributeScopes.AccessibilityAttributes, T>) -> T
    where T: AttributedStringKey {
        self[T.self]
    }
}

private func accessibilityKeyMarker<T>() -> T {
    fatalError("AttributeScope key-path marker")
}
