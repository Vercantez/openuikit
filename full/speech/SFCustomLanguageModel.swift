import Foundation

public protocol DataInsertable {
    func insert(data: SFCustomLanguageModelData)
}

public protocol TemplateInsertable {
    func insert(generator: SFCustomLanguageModelData.TemplatePhraseCountGenerator)
}

private struct DataInsertableGroup: DataInsertable {
    var items: [any DataInsertable]
    func insert(data: SFCustomLanguageModelData) {
        for item in items {
            item.insert(data: data)
        }
    }
}

private struct TemplateInsertableGroup: TemplateInsertable {
    var items: [any TemplateInsertable]
    func insert(generator: SFCustomLanguageModelData.TemplatePhraseCountGenerator) {
        for item in items {
            item.insert(generator: generator)
        }
    }
}

public final class SFCustomLanguageModelData: Hashable, Codable, @unchecked Sendable {
    @resultBuilder
    public struct DataInsertableBuilder {
        public static func buildBlock(_ components: any DataInsertable...) -> any DataInsertable {
            DataInsertableGroup(items: components)
        }

        public static func buildArray(_ components: [any DataInsertable]) -> any DataInsertable {
            DataInsertableGroup(items: components)
        }

        public static func buildEither(first: any DataInsertable) -> any DataInsertable {
            first
        }

        public static func buildEither(second: any DataInsertable) -> any DataInsertable {
            second
        }

        public static func buildOptional(_ component: (any DataInsertable)?) -> any DataInsertable {
            component ?? DataInsertableGroup(items: [])
        }
    }

    @resultBuilder
    public struct TemplateInsertableBuilder {
        public static func buildBlock(_ components: any TemplateInsertable...) -> any TemplateInsertable {
            TemplateInsertableGroup(items: components)
        }

        public static func buildArray(_ components: [any TemplateInsertable]) -> any TemplateInsertable {
            TemplateInsertableGroup(items: components)
        }

        public static func buildEither(first: any TemplateInsertable) -> any TemplateInsertable {
            first
        }

        public static func buildEither(second: any TemplateInsertable) -> any TemplateInsertable {
            second
        }

        public static func buildOptional(_ component: (any TemplateInsertable)?) -> any TemplateInsertable {
            component ?? TemplateInsertableGroup(items: [])
        }
    }

    public struct PhraseCount: Hashable, Codable, Sendable, DataInsertable, CustomStringConvertible {
        public let phrase: String
        public let count: Int
        public var description: String { "\(phrase):\(count)" }

        public init(phrase: String, count: Int) {
            self.phrase = phrase
            self.count = count
        }

        public func insert(data: SFCustomLanguageModelData) {
            data.insert(phraseCount: self)
        }
    }

    public struct CustomPronunciation: Hashable, Codable, Sendable, DataInsertable, CustomStringConvertible {
        public let grapheme: String
        public let phonemes: [String]
        public var description: String { "\(grapheme)/\(phonemes.joined(separator: " "))" }

        public init(grapheme: String, phonemes: [String]) {
            self.grapheme = grapheme
            self.phonemes = phonemes
        }

        public func insert(data: SFCustomLanguageModelData) {
            data.insert(term: self)
        }
    }

    public struct CompoundTemplate: TemplateInsertable {
        public let components: [any TemplateInsertable]

        public init(_ components: [any TemplateInsertable]) {
            self.components = components
        }

        public func insert(generator: TemplatePhraseCountGenerator) {
            for component in components {
                component.insert(generator: generator)
            }
        }
    }

    public struct PhraseCountsFromTemplates: DataInsertable {
        public let classes: [String: [String]]
        public let template: any TemplateInsertable

        public init(
            classes: [String: [String]],
            @TemplateInsertableBuilder builder: () -> any TemplateInsertable
        ) {
            self.classes = classes
            self.template = builder()
        }

        public func insert(data: SFCustomLanguageModelData) {
            let generator = TemplatePhraseCountGenerator()
            for (name, values) in classes {
                generator.define(className: name, values: values)
            }
            template.insert(generator: generator)
            data.insert(phraseCountGenerator: generator)
        }
    }

    public class PhraseCountGenerator: Hashable, Codable, DataInsertable, AsyncSequence, @unchecked Sendable {
        public typealias Element = PhraseCount
        public typealias AsyncIterator = Iterator

        public class Iterator: AsyncIteratorProtocol, @unchecked Sendable {
            public typealias Element = PhraseCount
            private var remaining: [PhraseCount]

            init(remaining: [PhraseCount]) {
                self.remaining = remaining
            }

            public func next() async throws -> PhraseCount? {
                guard remaining.isEmpty == false else { return nil }
                return remaining.removeFirst()
            }
        }

        var phrases: [PhraseCount] = []

        public init() {}

        public required init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            phrases = try container.decode([PhraseCount].self)
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(phrases)
        }

        public func makeAsyncIterator() -> Iterator {
            Iterator(remaining: phrases)
        }

        public func insert(data: SFCustomLanguageModelData) {
            data.insert(phraseCountGenerator: self)
        }

        public static func == (lhs: PhraseCountGenerator, rhs: PhraseCountGenerator) -> Bool {
            lhs.phrases == rhs.phrases
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(phrases)
        }
    }

    public class TemplatePhraseCountGenerator: PhraseCountGenerator, @unchecked Sendable {
        public struct Template: Hashable, Codable, Sendable, TemplateInsertable {
            public let body: String
            public let count: Int

            public init(_ body: String, count: Int) {
                self.body = body
                self.count = count
            }

            public func insert(generator: TemplatePhraseCountGenerator) {
                generator.insert(template: body, count: count)
            }
        }

        public class Iterator: PhraseCountGenerator.Iterator, @unchecked Sendable {
            public init(
                templates: [Template],
                templateClasses: [String: [String]]
            ) {
                _ = templateClasses
                super.init(remaining: templates.map { PhraseCount(phrase: $0.body, count: $0.count) })
            }

            public override func next() async throws -> PhraseCount? {
                try await super.next()
            }
        }

        private var templates: [Template] = []
        private var templateClasses: [String: [String]] = [:]

        public override init() {
            super.init()
        }

        public required init(from decoder: any Decoder) throws {
            try super.init(from: decoder)
        }

        public override func makeAsyncIterator() -> PhraseCountGenerator.Iterator {
            Iterator(templates: templates, templateClasses: templateClasses)
        }

        public func define(className: String, values: [String]) {
            templateClasses[className] = values
        }

        public func insert(template: String, count: Int) {
            templates.append(Template(template, count: count))
            phrases.append(PhraseCount(phrase: template, count: count))
        }

        public override func hash(into hasher: inout Hasher) {
            super.hash(into: &hasher)
            hasher.combine(templates)
            hasher.combine(templateClasses)
        }

        public static func == (
            lhs: TemplatePhraseCountGenerator,
            rhs: TemplatePhraseCountGenerator
        ) -> Bool {
            lhs.phrases == rhs.phrases && lhs.templates == rhs.templates
                && lhs.templateClasses == rhs.templateClasses
        }
    }

    public let locale: Locale
    public let identifier: String
    public let version: String
    private let lock = NSLock()
    private var phraseCounts: [PhraseCount] = []
    private var pronunciations: [CustomPronunciation] = []
    private var generators: [PhraseCountGenerator] = []

    public init(locale: Locale, identifier: String, version: String) {
        self.locale = locale
        self.identifier = identifier
        self.version = version
    }

    public convenience init(
        locale: Locale,
        identifier: String,
        version: String,
        @DataInsertableBuilder builder: () -> any DataInsertable
    ) {
        self.init(locale: locale, identifier: identifier, version: version)
        builder().insert(data: self)
    }

    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        locale = try container.decode(Locale.self, forKey: .locale)
        identifier = try container.decode(String.self, forKey: .identifier)
        version = try container.decode(String.self, forKey: .version)
        phraseCounts = try container.decode([PhraseCount].self, forKey: .phraseCounts)
        pronunciations = try container.decode([CustomPronunciation].self, forKey: .pronunciations)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(locale, forKey: .locale)
        try container.encode(identifier, forKey: .identifier)
        try container.encode(version, forKey: .version)
        try container.encode(snapshotPhraseCounts(), forKey: .phraseCounts)
        try container.encode(snapshotPronunciations(), forKey: .pronunciations)
    }

    private enum CodingKeys: String, CodingKey {
        case locale, identifier, version, phraseCounts, pronunciations
    }

    public static func supportedPhonemes(locale: Locale) -> [String] {
        _ = locale
        return []
    }

    public func insert(phraseCount: PhraseCount) {
        lock.lock()
        phraseCounts.append(phraseCount)
        lock.unlock()
    }

    public func insert(term: CustomPronunciation) {
        lock.lock()
        pronunciations.append(term)
        lock.unlock()
    }

    public func insert(phraseCountGenerator: PhraseCountGenerator) {
        lock.lock()
        generators.append(phraseCountGenerator)
        lock.unlock()
    }

    public func export(to path: URL) async throws {
        _ = path
        throw speechFailClosedError(.internalServiceError)
    }

    public static func == (lhs: SFCustomLanguageModelData, rhs: SFCustomLanguageModelData) -> Bool {
        lhs.identifier == rhs.identifier
            && lhs.version == rhs.version
            && lhs.locale == rhs.locale
            && lhs.snapshotPhraseCounts() == rhs.snapshotPhraseCounts()
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
        hasher.combine(version)
        hasher.combine(locale)
        hasher.combine(snapshotPhraseCounts())
    }

    @_spi(OpenUIKitHost)
    public func snapshotPhraseCounts() -> [PhraseCount] {
        lock.lock()
        defer { lock.unlock() }
        return phraseCounts
    }

    @_spi(OpenUIKitHost)
    public func snapshotPronunciations() -> [CustomPronunciation] {
        lock.lock()
        defer { lock.unlock() }
        return pronunciations
    }
}
