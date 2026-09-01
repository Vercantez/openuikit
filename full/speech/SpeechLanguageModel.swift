import Foundation

open class SFSpeechLanguageModel: NSObject {
    public final class Configuration: NSObject, NSSecureCoding, NSCopying, @unchecked Sendable {
        public let languageModel: URL
        public let vocabulary: URL?
        public let weight: NSNumber?

        public convenience init(languageModel: URL) {
            self.init(languageModel: languageModel, vocabulary: nil, weight: nil)
        }

        public convenience init(languageModel: URL, vocabulary: URL?) {
            self.init(languageModel: languageModel, vocabulary: vocabulary, weight: nil)
        }

        public init(languageModel: URL, vocabulary: URL?, weight: NSNumber?) {
            self.languageModel = languageModel
            self.vocabulary = vocabulary
            self.weight = weight
            super.init()
        }

        public static var supportsSecureCoding: Bool { true }

        public required init?(coder: NSCoder) {
            guard let languageModel = coder.decodeObject(of: NSURL.self, forKey: "languageModel") as URL? else {
                return nil
            }
            self.languageModel = languageModel
            vocabulary = coder.decodeObject(of: NSURL.self, forKey: "vocabulary") as URL?
            weight = coder.decodeObject(of: NSNumber.self, forKey: "weight")
            super.init()
        }

        public func encode(with coder: NSCoder) {
            coder.encode(languageModel as NSURL, forKey: "languageModel")
            coder.encode(vocabulary as NSURL?, forKey: "vocabulary")
            coder.encode(weight, forKey: "weight")
        }

        public func copy(with zone: NSZone? = nil) -> Any {
            _ = zone
            return Configuration(
                languageModel: languageModel,
                vocabulary: vocabulary,
                weight: weight
            )
        }
    }

    public class func prepareCustomLanguageModel(
        for asset: URL,
        configuration: Configuration
    ) async throws {
        try await prepareCustomLanguageModel(
            for: asset,
            configuration: configuration,
            ignoresCache: false
        )
    }

    public class func prepareCustomLanguageModel(
        for asset: URL,
        configuration: Configuration,
        ignoresCache: Bool
    ) async throws {
        _ = (asset, configuration, ignoresCache)
        throw SpeechPortable.failClosedService()
    }

    public class func prepareCustomLanguageModel(
        for asset: URL,
        clientIdentifier: String,
        configuration: Configuration
    ) async throws {
        try await prepareCustomLanguageModel(
            for: asset,
            clientIdentifier: clientIdentifier,
            configuration: configuration,
            ignoresCache: false
        )
    }

    public class func prepareCustomLanguageModel(
        for asset: URL,
        clientIdentifier: String,
        configuration: Configuration,
        ignoresCache: Bool
    ) async throws {
        _ = clientIdentifier
        try await prepareCustomLanguageModel(
            for: asset,
            configuration: configuration,
            ignoresCache: ignoresCache
        )
    }
}

public protocol DataInsertable {
    func insert(data: SFCustomLanguageModelData)
}

public protocol TemplateInsertable {
    func insert(generator: SFCustomLanguageModelData.TemplatePhraseCountGenerator)
}

private struct _CompositeDataInsertable: DataInsertable {
    let children: [any DataInsertable]
    func insert(data: SFCustomLanguageModelData) {
        for child in children {
            child.insert(data: data)
        }
    }
}

private struct _EmptyDataInsertable: DataInsertable {
    func insert(data: SFCustomLanguageModelData) {
        _ = data
    }
}

private struct _CompositeTemplateInsertable: TemplateInsertable {
    let children: [any TemplateInsertable]
    func insert(generator: SFCustomLanguageModelData.TemplatePhraseCountGenerator) {
        for child in children {
            child.insert(generator: generator)
        }
    }
}

private struct _EmptyTemplateInsertable: TemplateInsertable {
    func insert(generator: SFCustomLanguageModelData.TemplatePhraseCountGenerator) {
        _ = generator
    }
}

public final class SFCustomLanguageModelData: Hashable, @unchecked Sendable {
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
        for phrase in phraseCountGenerator.snapshot() {
            insert(phraseCount: phrase)
        }
    }

    public func export(to path: URL) async throws {
        let snapshot = snapshotDictionary()
        let data = try JSONSerialization.data(
            withJSONObject: snapshot,
            options: [.prettyPrinted, .sortedKeys]
        )
        try data.write(to: path, options: .atomic)
    }

    public static func == (lhs: SFCustomLanguageModelData, rhs: SFCustomLanguageModelData) -> Bool {
        lhs === rhs || (
            lhs.identifier == rhs.identifier
                && lhs.version == rhs.version
                && lhs.locale.identifier == rhs.locale.identifier
        )
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
        hasher.combine(version)
        hasher.combine(locale.identifier)
    }

    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        locale = Locale(identifier: try container.decode(String.self, forKey: .locale))
        identifier = try container.decode(String.self, forKey: .identifier)
        version = try container.decode(String.self, forKey: .version)
        phraseCounts = try container.decodeIfPresent([PhraseCount].self, forKey: .phraseCounts) ?? []
        pronunciations = try container.decodeIfPresent([CustomPronunciation].self, forKey: .pronunciations) ?? []
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(locale.identifier, forKey: .locale)
        try container.encode(identifier, forKey: .identifier)
        try container.encode(version, forKey: .version)
        try container.encode(snapshotPhraseCounts(), forKey: .phraseCounts)
        try container.encode(snapshotPronunciations(), forKey: .pronunciations)
    }

    private enum CodingKeys: String, CodingKey {
        case locale, identifier, version, phraseCounts, pronunciations
    }

    func snapshotPhraseCounts() -> [PhraseCount] {
        lock.lock(); defer { lock.unlock() }
        return phraseCounts
    }

    func snapshotPronunciations() -> [CustomPronunciation] {
        lock.lock(); defer { lock.unlock() }
        return pronunciations
    }

    private func snapshotDictionary() -> [String: Any] {
        [
            "locale": locale.identifier,
            "identifier": identifier,
            "version": version,
            "phraseCounts": snapshotPhraseCounts().map {
                ["phrase": $0.phrase, "count": $0.count]
            },
            "pronunciations": snapshotPronunciations().map {
                ["grapheme": $0.grapheme, "phonemes": $0.phonemes]
            },
        ]
    }

    @resultBuilder
    public struct DataInsertableBuilder {
        public static func buildBlock(_ components: any DataInsertable...) -> any DataInsertable {
            _CompositeDataInsertable(children: components)
        }

        public static func buildArray(_ components: [any DataInsertable]) -> any DataInsertable {
            _CompositeDataInsertable(children: components)
        }

        public static func buildEither(first: any DataInsertable) -> any DataInsertable {
            first
        }

        public static func buildEither(second: any DataInsertable) -> any DataInsertable {
            second
        }

        public static func buildOptional(_ component: (any DataInsertable)?) -> any DataInsertable {
            component ?? _EmptyDataInsertable()
        }
    }

    @resultBuilder
    public struct TemplateInsertableBuilder {
        public static func buildBlock(_ components: any TemplateInsertable...) -> any TemplateInsertable {
            _CompositeTemplateInsertable(children: components)
        }

        public static func buildArray(_ components: [any TemplateInsertable]) -> any TemplateInsertable {
            _CompositeTemplateInsertable(children: components)
        }

        public static func buildEither(first: any TemplateInsertable) -> any TemplateInsertable {
            first
        }

        public static func buildEither(second: any TemplateInsertable) -> any TemplateInsertable {
            second
        }

        public static func buildOptional(_ component: (any TemplateInsertable)?) -> any TemplateInsertable {
            component ?? _EmptyTemplateInsertable()
        }
    }

    public struct PhraseCount: Hashable, Sendable, Codable, CustomStringConvertible, DataInsertable {
        public let phrase: String
        public let count: Int

        public init(phrase: String, count: Int) {
            self.phrase = phrase
            self.count = count
        }

        public var description: String { "\(phrase)×\(count)" }

        public func insert(data: SFCustomLanguageModelData) {
            data.insert(phraseCount: self)
        }
    }

    public struct CustomPronunciation: Hashable, Sendable, Codable, CustomStringConvertible, DataInsertable {
        public let grapheme: String
        public let phonemes: [String]

        public init(grapheme: String, phonemes: [String]) {
            self.grapheme = grapheme
            self.phonemes = phonemes
        }

        public var description: String { "\(grapheme) → \(phonemes.joined(separator: " "))" }

        public func insert(data: SFCustomLanguageModelData) {
            data.insert(term: self)
        }
    }

    public class PhraseCountGenerator: AsyncSequence, Hashable, Codable, DataInsertable, @unchecked Sendable {
        public typealias Element = PhraseCount
        public typealias AsyncIterator = Iterator

        public class Iterator: AsyncIteratorProtocol, @unchecked Sendable {
            public typealias Element = PhraseCount
            private var remaining: [PhraseCount]

            init(phrases: [PhraseCount]) {
                self.remaining = phrases
            }

            public func next() async throws -> PhraseCount? {
                guard !remaining.isEmpty else { return nil }
                return remaining.removeFirst()
            }
        }

        private let lock = NSLock()
        var phrases: [PhraseCount]

        public init() {
            self.phrases = []
        }

        init(phrases: [PhraseCount]) {
            self.phrases = phrases
        }

        public required init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            phrases = try container.decode([PhraseCount].self)
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(snapshot())
        }

        public func makeAsyncIterator() -> Iterator {
            Iterator(phrases: snapshot())
        }

        public func insert(data: SFCustomLanguageModelData) {
            data.insert(phraseCountGenerator: self)
        }

        public static func == (lhs: PhraseCountGenerator, rhs: PhraseCountGenerator) -> Bool {
            lhs === rhs || lhs.snapshot() == rhs.snapshot()
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(snapshot())
        }

        func snapshot() -> [PhraseCount] {
            lock.lock(); defer { lock.unlock() }
            return phrases
        }

        func append(_ phrase: PhraseCount) {
            lock.lock()
            phrases.append(phrase)
            lock.unlock()
        }
    }

    public final class TemplatePhraseCountGenerator: PhraseCountGenerator, @unchecked Sendable {
        public struct Template: Hashable, Sendable, Codable, TemplateInsertable {
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

        public final class Iterator: PhraseCountGenerator.Iterator, @unchecked Sendable {
            public init(
                templates: [Template],
                templateClasses: [String: [String]]
            ) {
                let expanded = TemplatePhraseCountGenerator.expand(
                    templates: templates,
                    templateClasses: templateClasses
                )
                super.init(phrases: expanded)
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

        public override func hash(into hasher: inout Hasher) {
            super.hash(into: &hasher)
            hasher.combine(templates)
            hasher.combine(templateClasses)
        }

        public static func == (
            lhs: TemplatePhraseCountGenerator,
            rhs: TemplatePhraseCountGenerator
        ) -> Bool {
            lhs.snapshot() == rhs.snapshot()
                && lhs.templates == rhs.templates
                && lhs.templateClasses == rhs.templateClasses
        }

        public func define(className: String, values: [String]) {
            templateClasses[className] = values
            rebuildPhrases()
        }

        public func insert(template: String, count: Int) {
            templates.append(Template(template, count: count))
            rebuildPhrases()
        }

        public override func makeAsyncIterator() -> PhraseCountGenerator.Iterator {
            Iterator(templates: templates, templateClasses: templateClasses)
        }

        private func rebuildPhrases() {
            phrases = Self.expand(templates: templates, templateClasses: templateClasses)
        }

        static func expand(
            templates: [Template],
            templateClasses: [String: [String]]
        ) -> [PhraseCount] {
            var result: [PhraseCount] = []
            for template in templates {
                let expansions = expandBody(template.body, classes: templateClasses)
                for phrase in expansions {
                    result.append(PhraseCount(phrase: phrase, count: template.count))
                }
            }
            return result
        }

        static func expandBody(_ body: String, classes: [String: [String]]) -> [String] {
            let pattern = try? NSRegularExpression(pattern: "\\{([A-Za-z0-9_]+)\\}")
            let nsBody = body as NSString
            let range = NSRange(location: 0, length: nsBody.length)
            let matches = pattern?.matches(in: body, range: range) ?? []
            guard !matches.isEmpty else { return [body] }

            var slots: [(NSRange, [String])] = []
            for match in matches {
                let nameRange = match.range(at: 1)
                let name = nsBody.substring(with: nameRange)
                let values = classes[name] ?? []
                slots.append((match.range(at: 0), values))
            }
            if slots.contains(where: { $0.1.isEmpty }) {
                return []
            }

            var expansions = [""]
            var last = 0
            for (slotRange, values) in slots {
                let prefix = nsBody.substring(with: NSRange(location: last, length: slotRange.location - last))
                var next: [String] = []
                next.reserveCapacity(expansions.count * values.count)
                for existing in expansions {
                    for value in values {
                        next.append(existing + prefix + value)
                    }
                }
                expansions = next
                last = slotRange.location + slotRange.length
            }
            let suffix = nsBody.substring(from: last)
            return expansions.map { $0 + suffix }
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
}
