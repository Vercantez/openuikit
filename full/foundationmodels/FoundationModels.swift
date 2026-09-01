//===----------------------------------------------------------------------===//
// Portable FoundationModels
//
// Apple Intelligence model assets and their private inference runtime are not
// present on Linux.  This framework therefore implements the public data and
// compiler model faithfully (Generable, GeneratedContent, guides, schemas,
// prompts, options, responses, and asynchronous streams) while making the
// service boundary explicit: SystemLanguageModel is unavailable and every
// inference request fails with GenerationError.assetsUnavailable.  Callers can
// use their ordinary Apple fallback paths without receiving fabricated text.
//===----------------------------------------------------------------------===//

@_exported import Foundation

// MARK: - Compiler-facing macros

#if hasFeature(Macros)
@attached(extension, conformances: FoundationModels.Generable,
          names: named(init(_:)), named(generatedContent))
@attached(member, names: arbitrary)
public macro Generable(description: String? = nil) =
    #externalMacro(module: "FoundationModelsMacros", type: "GenerableMacro")

@attached(peer)
public macro Guide<T>(
    description: String? = nil,
    _ guides: FoundationModels.GenerationGuide<T>...
) = #externalMacro(module: "FoundationModelsMacros", type: "GuideMacro")
where T: FoundationModels.Generable

@attached(peer)
public macro Guide(description: String) =
    #externalMacro(module: "FoundationModelsMacros", type: "GuideMacro")
#endif

// MARK: - Generated values

public protocol ConvertibleFromGeneratedContent {
    init(_ content: GeneratedContent) throws
}

public protocol InstructionsRepresentable {
    var instructionsRepresentation: Instructions { get }
}

public protocol PromptRepresentable {
    var promptRepresentation: Prompt { get }
}

public protocol ConvertibleToGeneratedContent:
    InstructionsRepresentable, PromptRepresentable
{
    var generatedContent: GeneratedContent { get }
}

public protocol Generable:
    ConvertibleFromGeneratedContent, ConvertibleToGeneratedContent
{
    associatedtype PartiallyGenerated: ConvertibleFromGeneratedContent = Self
    static var generationSchema: GenerationSchema { get }
}

public extension Generable where PartiallyGenerated == Self {
    func asPartiallyGenerated() -> Self { self }
}

public extension ConvertibleToGeneratedContent {
    var instructionsRepresentation: Instructions {
        Instructions(generatedContent.jsonString)
    }

    var promptRepresentation: Prompt {
        Prompt(generatedContent.jsonString)
    }
}

public enum GeneratedContentError: Error, Equatable, Sendable,
    CustomStringConvertible
{
    case typeMismatch(expected: String, actual: String)
    case missingProperty(String)

    public var description: String {
        switch self {
        case .typeMismatch(let expected, let actual):
            return "generated content type mismatch: expected \(expected), got \(actual)"
        case .missingProperty(let property):
            return "generated content property is missing: \(property)"
        }
    }
}

public struct GenerationID: Sendable, Hashable, CustomStringConvertible {
    public let rawValue: String

    public init() {
        rawValue = UUID().uuidString
    }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public var description: String { rawValue }
}

public struct GeneratedContent: Sendable, Equatable, Generable,
    CustomDebugStringConvertible
{
    public indirect enum Kind: Sendable, Equatable {
        case null
        case bool(Bool)
        case number(Double)
        case string(String)
        case array([GeneratedContent])
        case structure(properties: [String: GeneratedContent], orderedKeys: [String])
    }

    public var id: GenerationID?
    public let kind: Kind

    public init(kind: Kind, id: GenerationID? = nil) {
        self.kind = kind
        self.id = id
    }

    public init(_ content: GeneratedContent) throws {
        self = content
    }

    public init(_ value: some ConvertibleToGeneratedContent) {
        self = value.generatedContent
    }

    public init(
        _ value: some ConvertibleToGeneratedContent,
        id: GenerationID
    ) {
        self = value.generatedContent
        self.id = id
    }

    public init(
        properties: KeyValuePairs<String, any ConvertibleToGeneratedContent>,
        id: GenerationID? = nil
    ) {
        var result: [String: GeneratedContent] = [:]
        var order: [String] = []
        for (key, value) in properties {
            if result[key] == nil { order.append(key) }
            result[key] = value.generatedContent
        }
        self.init(kind: .structure(properties: result, orderedKeys: order), id: id)
    }

    public init<S, Combined>(
        properties: S,
        id: GenerationID? = nil,
        uniquingKeysWith combine: (GeneratedContent, GeneratedContent) throws -> Combined
    ) rethrows
    where
        S: Sequence,
        S.Element == (String, any ConvertibleToGeneratedContent),
        Combined: ConvertibleToGeneratedContent
    {
        var result: [String: GeneratedContent] = [:]
        var order: [String] = []
        for (key, value) in properties {
            let incoming = value.generatedContent
            if let existing = result[key] {
                result[key] = try combine(existing, incoming).generatedContent
            } else {
                order.append(key)
                result[key] = incoming
            }
        }
        self.init(kind: .structure(properties: result, orderedKeys: order), id: id)
    }

    public init<S>(elements: S, id: GenerationID? = nil)
    where S: Sequence, S.Element == any ConvertibleToGeneratedContent {
        self.init(
            kind: .array(elements.map(\.generatedContent)),
            id: id
        )
    }

    public var generatedContent: GeneratedContent { self }

    public static var generationSchema: GenerationSchema {
        GenerationSchema(type: Self.self, description: "Generated content", properties: [])
    }

    public func value<Value>(
        _ type: Value.Type = Value.self
    ) throws -> Value where Value: ConvertibleFromGeneratedContent {
        try Value(self)
    }

    public func value<Value>(
        _ type: Value.Type = Value.self,
        forProperty property: String
    ) throws -> Value where Value: ConvertibleFromGeneratedContent {
        guard case .structure(let properties, _) = kind else {
            throw GeneratedContentError.typeMismatch(
                expected: "structure", actual: kindName
            )
        }
        guard let content = properties[property] else {
            throw GeneratedContentError.missingProperty(property)
        }
        return try Value(content)
    }

    public func value<Value>(
        _ type: Value?.Type = Value?.self,
        forProperty property: String
    ) throws -> Value? where Value: ConvertibleFromGeneratedContent {
        guard case .structure(let properties, _) = kind else {
            throw GeneratedContentError.typeMismatch(
                expected: "structure", actual: kindName
            )
        }
        guard let content = properties[property] else { return nil }
        if case .null = content.kind { return nil }
        return try Value(content)
    }

    public var isComplete: Bool { true }
    public var jsonString: String { encodeJSON() }
    public var debugDescription: String { jsonString }

    fileprivate var kindName: String {
        switch kind {
        case .null: return "null"
        case .bool: return "bool"
        case .number: return "number"
        case .string: return "string"
        case .array: return "array"
        case .structure: return "structure"
        }
    }

    private func encodeJSON() -> String {
        switch kind {
        case .null:
            return "null"
        case .bool(let value):
            return value ? "true" : "false"
        case .number(let value):
            if value.isFinite {
                if value.rounded(.towardZero) == value {
                    return String(Int64(value))
                }
                return String(value)
            }
            return "null"
        case .string(let value):
            return "\"\(Self.escapeJSON(value))\""
        case .array(let values):
            return "[\(values.map { $0.encodeJSON() }.joined(separator: ", "))]"
        case .structure(let properties, let orderedKeys):
            var seen: Set<String> = []
            var keys: [String] = []
            for key in orderedKeys where properties[key] != nil && seen.insert(key).inserted {
                keys.append(key)
            }
            for key in properties.keys.sorted() where seen.insert(key).inserted {
                keys.append(key)
            }
            let body = keys.map { key in
                "\"\(Self.escapeJSON(key))\": \(properties[key]!.encodeJSON())"
            }.joined(separator: ", ")
            return "{\(body)}"
        }
    }

    private static func escapeJSON(_ value: String) -> String {
        var result = ""
        result.reserveCapacity(value.utf8.count)
        for scalar in value.unicodeScalars {
            switch scalar.value {
            case 0x22: result += "\\\""
            case 0x5c: result += "\\\\"
            case 0x08: result += "\\b"
            case 0x0c: result += "\\f"
            case 0x0a: result += "\\n"
            case 0x0d: result += "\\r"
            case 0x09: result += "\\t"
            case 0x00...0x1f:
                let hex = String(scalar.value, radix: 16, uppercase: false)
                result += "\\u" + String(repeating: "0", count: 4 - hex.count) + hex
            default:
                result.unicodeScalars.append(scalar)
            }
        }
        return result
    }
}

extension Bool: Generable {
    public static var generationSchema: GenerationSchema {
        GenerationSchema(type: Self.self, properties: [])
    }

    public init(_ content: GeneratedContent) throws {
        guard case .bool(let value) = content.kind else {
            throw GeneratedContentError.typeMismatch(
                expected: "bool", actual: content.kindName
            )
        }
        self = value
    }

    public var generatedContent: GeneratedContent { .init(kind: .bool(self)) }
}

extension String: Generable {
    public static var generationSchema: GenerationSchema {
        GenerationSchema(type: Self.self, properties: [])
    }

    public init(_ content: GeneratedContent) throws {
        guard case .string(let value) = content.kind else {
            throw GeneratedContentError.typeMismatch(
                expected: "string", actual: content.kindName
            )
        }
        self = value
    }

    public var generatedContent: GeneratedContent { .init(kind: .string(self)) }
}

extension Int: Generable {
    public static var generationSchema: GenerationSchema {
        GenerationSchema(type: Self.self, properties: [])
    }

    public init(_ content: GeneratedContent) throws {
        guard case .number(let value) = content.kind,
              value.isFinite,
              value.rounded(.towardZero) == value,
              value >= Double(Int.min), value <= Double(Int.max)
        else {
            throw GeneratedContentError.typeMismatch(
                expected: "integer", actual: content.kindName
            )
        }
        self = Int(value)
    }

    public var generatedContent: GeneratedContent {
        .init(kind: .number(Double(self)))
    }
}

extension Float: Generable {
    public static var generationSchema: GenerationSchema {
        GenerationSchema(type: Self.self, properties: [])
    }

    public init(_ content: GeneratedContent) throws {
        guard case .number(let value) = content.kind else {
            throw GeneratedContentError.typeMismatch(
                expected: "number", actual: content.kindName
            )
        }
        self = Float(value)
    }

    public var generatedContent: GeneratedContent {
        .init(kind: .number(Double(self)))
    }
}

extension Double: Generable {
    public static var generationSchema: GenerationSchema {
        GenerationSchema(type: Self.self, properties: [])
    }

    public init(_ content: GeneratedContent) throws {
        guard case .number(let value) = content.kind else {
            throw GeneratedContentError.typeMismatch(
                expected: "number", actual: content.kindName
            )
        }
        self = value
    }

    public var generatedContent: GeneratedContent { .init(kind: .number(self)) }
}

extension Never: Generable {
    public static var generationSchema: GenerationSchema {
        GenerationSchema(type: Self.self, properties: [])
    }

    public init(_ content: GeneratedContent) throws {
        _ = content
        fatalError("Never cannot be decoded from generated content")
    }

    public var generatedContent: GeneratedContent {
        switch self {}
    }
}

extension Array: ConvertibleToGeneratedContent, InstructionsRepresentable,
    PromptRepresentable
where Element: ConvertibleToGeneratedContent {
    public var generatedContent: GeneratedContent {
        .init(kind: .array(map(\.generatedContent)))
    }
}

extension Array: ConvertibleFromGeneratedContent
where Element: ConvertibleFromGeneratedContent {
    public init(_ content: GeneratedContent) throws {
        guard case .array(let elements) = content.kind else {
            throw GeneratedContentError.typeMismatch(
                expected: "array", actual: content.kindName
            )
        }
        self = try elements.map(Element.init)
    }
}

extension Array: Generable where Element: Generable {
    public typealias PartiallyGenerated = [Element.PartiallyGenerated]

    public static var generationSchema: GenerationSchema {
        GenerationSchema(type: Self.self, properties: [])
    }
}

extension Optional: ConvertibleToGeneratedContent, InstructionsRepresentable,
    PromptRepresentable
where Wrapped: ConvertibleToGeneratedContent {
    public var generatedContent: GeneratedContent {
        switch self {
        case .some(let value): return value.generatedContent
        case .none: return .init(kind: .null)
        }
    }
}

// MARK: - Guides and schemas

public struct GenerationGuide<Value>: Sendable {
    public enum Constraint: Sendable, Equatable {
        case constant(String)
        case anyOf([String])
        case minimum(Double)
        case maximum(Double)
        case range(Double, Double)
        case minimumCount(Int)
        case maximumCount(Int)
        case count(Int, Int)
        case element
    }

    public let constraint: Constraint

    fileprivate init(_ constraint: Constraint) {
        self.constraint = constraint
    }
}

public extension GenerationGuide where Value == String {
    static func constant(_ value: String) -> Self { .init(.constant(value)) }
    static func anyOf(_ values: [String]) -> Self { .init(.anyOf(values)) }
}

public extension GenerationGuide where Value == Int {
    static func minimum(_ value: Int) -> Self { .init(.minimum(Double(value))) }
    static func maximum(_ value: Int) -> Self { .init(.maximum(Double(value))) }
    static func range(_ range: ClosedRange<Int>) -> Self {
        .init(.range(Double(range.lowerBound), Double(range.upperBound)))
    }
}

public extension GenerationGuide where Value == Float {
    static func minimum(_ value: Float) -> Self { .init(.minimum(Double(value))) }
    static func maximum(_ value: Float) -> Self { .init(.maximum(Double(value))) }
    static func range(_ range: ClosedRange<Float>) -> Self {
        .init(.range(Double(range.lowerBound), Double(range.upperBound)))
    }
}

public extension GenerationGuide where Value == Double {
    static func minimum(_ value: Double) -> Self { .init(.minimum(value)) }
    static func maximum(_ value: Double) -> Self { .init(.maximum(value)) }
    static func range(_ range: ClosedRange<Double>) -> Self {
        .init(.range(range.lowerBound, range.upperBound))
    }
}

public extension GenerationGuide {
    static func minimumCount<Element>(
        _ count: Int
    ) -> GenerationGuide<[Element]> where Value == [Element] {
        .init(.minimumCount(count))
    }

    static func maximumCount<Element>(
        _ count: Int
    ) -> GenerationGuide<[Element]> where Value == [Element] {
        .init(.maximumCount(count))
    }

    static func count<Element>(
        _ range: ClosedRange<Int>
    ) -> GenerationGuide<[Element]> where Value == [Element] {
        .init(.count(range.lowerBound, range.upperBound))
    }

    static func count<Element>(
        _ count: Int
    ) -> GenerationGuide<[Element]> where Value == [Element] {
        .init(.count(count, count))
    }

    static func element<Element>(
        _ guide: GenerationGuide<Element>
    ) -> GenerationGuide<[Element]> where Value == [Element] {
        _ = guide
        return .init(.element)
    }
}

// Swift has no property-type context while initially resolving attached macro
// arguments.  Apple publishes these `[Never]` fallbacks for the same reason:
// they make `.count(...)` syntactically resolvable, then the Generable macro
// re-emits the expression inside a schema property whose type supplies the
// concrete array element.
extension GenerationGuide where Value == [Never] {
    @_disfavoredOverload
    public static func minimumCount(_ count: Int) -> Self {
        _ = count
        return .init(.minimumCount(count))
    }

    @_disfavoredOverload
    public static func maximumCount(_ count: Int) -> Self {
        _ = count
        return .init(.maximumCount(count))
    }

    @_disfavoredOverload
    public static func count(_ range: ClosedRange<Int>) -> Self {
        .init(.count(range.lowerBound, range.upperBound))
    }

    @_disfavoredOverload
    public static func count(_ count: Int) -> Self {
        .init(.count(count, count))
    }
}

public struct GenerationSchema: Sendable, CustomDebugStringConvertible {
    public struct Property: Sendable {
        public let name: String
        public let description: String?
        public let typeName: String
        public let guideDescriptions: [String]

        public init<Value>(
            name: String,
            description: String? = nil,
            type: Value.Type,
            guides: [GenerationGuide<Value>] = []
        ) where Value: Generable {
            self.name = name
            self.description = description
            self.typeName = String(reflecting: type)
            self.guideDescriptions = guides.map { String(describing: $0.constraint) }
        }

        public init<Value>(
            name: String,
            description: String? = nil,
            type: Value?.Type,
            guides: [GenerationGuide<Value>] = []
        ) where Value: Generable {
            self.name = name
            self.description = description
            self.typeName = String(reflecting: type)
            self.guideDescriptions = guides.map { String(describing: $0.constraint) }
        }
    }

    public let typeName: String
    public let description: String?
    public let properties: [Property]

    public init(
        type: any Generable.Type,
        description: String? = nil,
        properties: [Property]
    ) {
        self.typeName = String(reflecting: type)
        self.description = description
        self.properties = properties
    }

    public var debugDescription: String {
        let names = properties.map(\.name).joined(separator: ",")
        return "GenerationSchema(type: \(typeName), properties: [\(names)])"
    }
}

// MARK: - Prompt construction

public struct Instructions: Sendable, Hashable, ExpressibleByStringLiteral,
    ExpressibleByStringInterpolation
{
    public let content: String

    public init(_ content: String) { self.content = content }
    public init(stringLiteral value: String) { self.init(value) }
    public init(stringInterpolation: String.StringInterpolation) {
        self.init(String(stringInterpolation: stringInterpolation))
    }
}

public struct Prompt: Sendable, Hashable, ExpressibleByStringLiteral,
    ExpressibleByStringInterpolation
{
    public let content: String

    public init(_ content: String) { self.content = content }
    public init(stringLiteral value: String) { self.init(value) }
    public init(stringInterpolation: String.StringInterpolation) {
        self.init(String(stringInterpolation: stringInterpolation))
    }
}

extension String: InstructionsRepresentable, PromptRepresentable {
    public var instructionsRepresentation: Instructions { Instructions(self) }
    public var promptRepresentation: Prompt { Prompt(self) }
}

@resultBuilder
public enum InstructionsBuilder {
    public static func buildExpression(_ expression: String) -> Instructions {
        Instructions(expression)
    }

    public static func buildExpression<R>(
        _ expression: R
    ) -> Instructions where R: InstructionsRepresentable {
        expression.instructionsRepresentation
    }

    public static func buildBlock(_ components: Instructions...) -> Instructions {
        Instructions(components.map(\.content).joined(separator: "\n"))
    }
}

@resultBuilder
public enum PromptBuilder {
    public static func buildExpression(_ expression: String) -> Prompt {
        Prompt(expression)
    }

    public static func buildExpression<R>(
        _ expression: R
    ) -> Prompt where R: PromptRepresentable {
        expression.promptRepresentation
    }

    public static func buildBlock(_ components: Prompt...) -> Prompt {
        Prompt(components.map(\.content).joined(separator: "\n"))
    }
}

// MARK: - Model service boundary

public struct GenerationOptions: Sendable, Equatable {
    public struct SamplingMode: Sendable, Equatable {
        fileprivate enum Storage: Sendable, Equatable {
            case greedy
            case topK(Int, UInt64?)
            case probabilityThreshold(Double, UInt64?)
        }

        fileprivate let storage: Storage
        public static var greedy: Self { .init(storage: .greedy) }

        public static func random(top k: Int, seed: UInt64? = nil) -> Self {
            .init(storage: .topK(k, seed))
        }

        public static func random(
            probabilityThreshold: Double,
            seed: UInt64? = nil
        ) -> Self {
            .init(storage: .probabilityThreshold(probabilityThreshold, seed))
        }
    }

    public var sampling: SamplingMode?
    public var temperature: Double?
    public var maximumResponseTokens: Int?

    public init(
        sampling: SamplingMode? = nil,
        temperature: Double? = nil,
        maximumResponseTokens: Int? = nil
    ) {
        self.sampling = sampling
        self.temperature = temperature
        self.maximumResponseTokens = maximumResponseTokens
    }
}

public final class SystemLanguageModel: @unchecked Sendable {
    public struct UseCase: Sendable, Equatable {
        fileprivate let rawValue: UInt8
        public static let general = Self(rawValue: 0)
        public static let contentTagging = Self(rawValue: 1)
    }

    public struct Guardrails: Sendable, Equatable {
        fileprivate let rawValue: UInt8
        public static let `default` = Self(rawValue: 0)
        public static let permissiveContentTransformations = Self(rawValue: 1)
    }

    public enum Availability: Sendable, Equatable {
        public enum UnavailableReason: Sendable, Hashable {
            case deviceNotEligible
            case appleIntelligenceNotEnabled
            case modelNotReady
        }

        case available
        case unavailable(UnavailableReason)
    }

    public static let `default` = SystemLanguageModel()

    public let useCase: UseCase
    public let guardrails: Guardrails

    public init(
        useCase: UseCase = .general,
        guardrails: Guardrails = .default
    ) {
        self.useCase = useCase
        self.guardrails = guardrails
    }

    public var availability: Availability { .unavailable(.deviceNotEligible) }
    public var isAvailable: Bool { false }
    public var supportedLanguages: Set<Locale.Language> { [] }
    public func supportsLocale(_ locale: Locale = .current) -> Bool {
        _ = locale
        return false
    }
}

public final class LanguageModelSession: @unchecked Sendable {
    public struct Response<Content> where Content: Generable {
        public let content: Content
        public let rawContent: GeneratedContent

        public init(content: Content, rawContent: GeneratedContent) {
            self.content = content
            self.rawContent = rawContent
        }
    }

    public enum GenerationError: Error, LocalizedError, Sendable {
        public struct Context: Sendable {
            public let debugDescription: String
            public init(debugDescription: String) {
                self.debugDescription = debugDescription
            }
        }

        case exceededContextWindowSize(Context)
        case assetsUnavailable(Context)
        case guardrailViolation(Context)
        case unsupportedGuide(Context)
        case unsupportedLanguageOrLocale(Context)
        case decodingFailure(Context)
        case rateLimited(Context)
        case concurrentRequests(Context)

        public var errorDescription: String? {
            switch self {
            case .assetsUnavailable:
                return "Foundation Models assets are unavailable on this platform."
            case .exceededContextWindowSize:
                return "The model context window was exceeded."
            case .guardrailViolation:
                return "The request violated model guardrails."
            case .unsupportedGuide:
                return "The generation guide is unsupported."
            case .unsupportedLanguageOrLocale:
                return "The language or locale is unsupported."
            case .decodingFailure:
                return "The generated response could not be decoded."
            case .rateLimited:
                return "The model request was rate limited."
            case .concurrentRequests:
                return "Concurrent requests are unsupported by this session."
            }
        }

        public var failureReason: String? {
            switch self {
            case .assetsUnavailable(let context),
                 .exceededContextWindowSize(let context),
                 .guardrailViolation(let context),
                 .unsupportedGuide(let context),
                 .unsupportedLanguageOrLocale(let context),
                 .decodingFailure(let context),
                 .rateLimited(let context),
                 .concurrentRequests(let context):
                return context.debugDescription
            }
        }

        public var recoverySuggestion: String? {
            "Use the application's non-generative fallback path."
        }
    }

    public struct ResponseStream<Content>: AsyncSequence
    where Content: Generable {
        public struct Snapshot {
            public var content: Content.PartiallyGenerated
            public var rawContent: GeneratedContent

            public init(
                content: Content.PartiallyGenerated,
                rawContent: GeneratedContent
            ) {
                self.content = content
                self.rawContent = rawContent
            }
        }

        public struct AsyncIterator: AsyncIteratorProtocol {
            fileprivate var exhausted = false

            public mutating func next() async throws -> Snapshot? {
                guard !exhausted else { return nil }
                exhausted = true
                throw LanguageModelSession.unavailableError
            }
        }

        public init() {}
        public func makeAsyncIterator() -> AsyncIterator { AsyncIterator() }

        public func collect() async throws -> Response<Content> {
            throw LanguageModelSession.unavailableError
        }
    }

    private static var unavailableError: GenerationError {
        .assetsUnavailable(.init(
            debugDescription:
                "No Apple Intelligence model service or compatible local model host is installed."
        ))
    }

    public let model: SystemLanguageModel
    public let instructions: Instructions?

    public init(
        model: SystemLanguageModel = .default,
        instructions: String? = nil
    ) {
        self.model = model
        self.instructions = instructions.map { Instructions($0) }
    }

    public init(
        model: SystemLanguageModel = .default,
        @InstructionsBuilder instructions: () -> Instructions
    ) {
        self.model = model
        self.instructions = instructions()
    }

    public var isResponding: Bool { false }

    public func prewarm(promptPrefix: Prompt? = nil) {
        _ = promptPrefix
    }

    @discardableResult
    public func respond(
        to prompt: String,
        options: GenerationOptions = .init()
    ) async throws -> Response<String> {
        _ = prompt
        _ = options
        throw Self.unavailableError
    }

    @discardableResult
    public func respond<Content>(
        to prompt: String,
        generating type: Content.Type = Content.self,
        includeSchemaInPrompt: Bool = true,
        options: GenerationOptions = .init()
    ) async throws -> Response<Content> where Content: Generable {
        _ = prompt
        _ = type
        _ = includeSchemaInPrompt
        _ = options
        throw Self.unavailableError
    }

    public func streamResponse(
        to prompt: String,
        options: GenerationOptions = .init()
    ) -> ResponseStream<String> {
        _ = prompt
        _ = options
        return ResponseStream()
    }

    public func streamResponse<Content>(
        to prompt: String,
        generating type: Content.Type = Content.self,
        includeSchemaInPrompt: Bool = true,
        options: GenerationOptions = .init()
    ) -> ResponseStream<Content> where Content: Generable {
        _ = prompt
        _ = type
        _ = includeSchemaInPrompt
        _ = options
        return ResponseStream()
    }
}
