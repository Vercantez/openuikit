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

// The host gate compiles this module without the SwiftSyntax plugin.
// `#externalMacro` therefore exists only off Linux (Apple SDK / Mach-O guest).
#if !os(Linux)
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
public macro Guide<RegexOutput>(
    description: String? = nil,
    _ guides: Regex<RegexOutput>
) = #externalMacro(module: "FoundationModelsMacros", type: "GuideMacro")

@attached(peer)
public macro Guide(description: String) =
    #externalMacro(module: "FoundationModelsMacros", type: "GuideMacro")
#endif
#endif

// MARK: - Generated values

public protocol ConvertibleFromGeneratedContent: SendableMetatype {
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

    public init(json: String) throws {
        let data = Data(json.utf8)
        let object = try JSONSerialization.jsonObject(
            with: data,
            options: [.fragmentsAllowed]
        )
        self = try Self.fromJSONObject(object)
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

    private static func fromJSONObject(_ object: Any) throws -> GeneratedContent {
        switch object {
        case is NSNull:
            return GeneratedContent(kind: .null)
        case let value as Bool:
            return GeneratedContent(kind: .bool(value))
        case let value as String:
            return GeneratedContent(kind: .string(value))
        case let value as [Any]:
            return GeneratedContent(
                kind: .array(try value.map { try fromJSONObject($0) })
            )
        case let value as [String: Any]:
            let keys = value.keys.sorted()
            var properties: [String: GeneratedContent] = [:]
            for key in keys {
                properties[key] = try fromJSONObject(value[key] as Any)
            }
            return GeneratedContent(
                kind: .structure(properties: properties, orderedKeys: keys)
            )
        case let value as NSNumber:
            let type = String(cString: value.objCType)
            if type == "c" || type == "B" {
                return GeneratedContent(kind: .bool(value.boolValue))
            }
            return GeneratedContent(kind: .number(value.doubleValue))
        default:
            throw GeneratedContentError.typeMismatch(
                expected: "json value",
                actual: String(describing: type(of: object))
            )
        }
    }

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

extension Decimal: Generable {
    public static var generationSchema: GenerationSchema {
        GenerationSchema(type: Self.self, properties: [])
    }

    public init(_ content: GeneratedContent) throws {
        guard case .number(let value) = content.kind else {
            throw GeneratedContentError.typeMismatch(
                expected: "number", actual: content.kindName
            )
        }
        self = Decimal(value)
    }

    public var generatedContent: GeneratedContent {
        .init(kind: .number(NSDecimalNumber(decimal: self).doubleValue))
    }
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

extension Optional: ConvertibleFromGeneratedContent
where Wrapped: ConvertibleFromGeneratedContent {
    public init(_ content: GeneratedContent) throws {
        if case .null = content.kind {
            self = nil
            return
        }
        self = try Wrapped(content)
    }
}

extension Optional: Generable where Wrapped: Generable {
    public typealias PartiallyGenerated = Wrapped.PartiallyGenerated?

    public static var generationSchema: GenerationSchema {
        GenerationSchema(type: Self.self, properties: [])
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
        case pattern(String)
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

public extension GenerationGuide where Value == Decimal {
    static func minimum(_ value: Decimal) -> Self {
        .init(.minimum(NSDecimalNumber(decimal: value).doubleValue))
    }
    static func maximum(_ value: Decimal) -> Self {
        .init(.maximum(NSDecimalNumber(decimal: value).doubleValue))
    }
    static func range(_ range: ClosedRange<Decimal>) -> Self {
        .init(
            .range(
                NSDecimalNumber(decimal: range.lowerBound).doubleValue,
                NSDecimalNumber(decimal: range.upperBound).doubleValue
            )
        )
    }
}

public extension GenerationGuide where Value == String {
    static func pattern<Output>(_ regex: Regex<Output>) -> GenerationGuide<String> {
        .init(.pattern(String(describing: regex)))
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

        fileprivate init(
            storedName: String,
            storedDescription: String?,
            storedTypeName: String,
            storedGuides: [String]
        ) {
            self.name = storedName
            self.description = storedDescription
            self.typeName = storedTypeName
            self.guideDescriptions = storedGuides
        }

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

        public init<RegexOutput>(
            name: String,
            description: String? = nil,
            type: String.Type,
            guides: [Regex<RegexOutput>] = []
        ) {
            self.name = name
            self.description = description
            self.typeName = String(reflecting: type)
            self.guideDescriptions = guides.map { String(describing: $0) }
        }

        public init<RegexOutput>(
            name: String,
            description: String? = nil,
            type: String?.Type,
            guides: [Regex<RegexOutput>] = []
        ) {
            self.name = name
            self.description = description
            self.typeName = String(reflecting: type)
            self.guideDescriptions = guides.map { String(describing: $0) }
        }
    }

    public init(
        type: any Generable.Type,
        description: String? = nil,
        properties: [Property]
    ) {
        self.typeName = String(reflecting: type)
        self.description = description
        self.properties = properties
        self.anyOfNames = []
        self.dynamicRootName = nil
    }

    public init(
        type: any Generable.Type,
        description: String? = nil,
        anyOf types: [any Generable.Type]
    ) {
        self.typeName = String(reflecting: type)
        self.description = description
        self.properties = []
        self.anyOfNames = types.map { String(reflecting: $0) }
        self.dynamicRootName = nil
    }

    public init(
        type: any Generable.Type,
        description: String? = nil,
        anyOf choices: [String]
    ) {
        self.typeName = String(reflecting: type)
        self.description = description
        self.properties = []
        self.anyOfNames = choices
        self.dynamicRootName = nil
    }

    public init(
        root: DynamicGenerationSchema,
        dependencies: [DynamicGenerationSchema]
    ) throws {
        _ = dependencies
        guard !root.name.isEmpty else {
            throw SchemaError.emptyTypeChoices(
                schema: root.name,
                context: .init(debugDescription: "dynamic schema root is unnamed")
            )
        }
        self.typeName = root.name
        self.description = root.schemaDescription
        self.properties = []
        self.anyOfNames = root.choices
        self.dynamicRootName = root.name
    }

    public let typeName: String
    public let description: String?
    public let properties: [Property]
    public let anyOfNames: [String]
    public let dynamicRootName: String?

    public var debugDescription: String {
        let names = properties.map(\.name).joined(separator: ",")
        return "GenerationSchema(type: \(typeName), properties: [\(names)])"
    }

    public enum SchemaError: Error, LocalizedError, Sendable {
        public struct Context: Sendable, Equatable {
            public let debugDescription: String
            public init(debugDescription: String) {
                self.debugDescription = debugDescription
            }
        }

        case duplicateType(schema: String?, type: String, context: Context)
        case emptyTypeChoices(schema: String, context: Context)
        case duplicateProperty(schema: String, property: String, context: Context)
        case undefinedReferences(schema: String?, references: [String], context: Context)

        public var errorDescription: String? {
            switch self {
            case .duplicateType(_, let type, _):
                return "Duplicate schema type: \(type)"
            case .emptyTypeChoices(let schema, _):
                return "Schema \(schema) has no type choices."
            case .duplicateProperty(_, let property, _):
                return "Duplicate schema property: \(property)"
            case .undefinedReferences(_, let references, _):
                return "Undefined schema references: \(references.joined(separator: ","))"
            }
        }

        public var recoverySuggestion: String? {
            "Correct the generation schema and retry."
        }

        public var failureReason: String? {
            switch self {
            case .duplicateType(_, _, let context),
                 .undefinedReferences(_, _, let context):
                return context.debugDescription
            case .emptyTypeChoices(_, let context),
                 .duplicateProperty(_, _, let context):
                return context.debugDescription
            }
        }
    }
}

extension GenerationSchema: Codable {
    private enum CodingKeys: String, CodingKey {
        case typeName, description, properties, anyOfNames, dynamicRootName
    }

    private struct CodableProperty: Codable {
        var name: String
        var description: String?
        var typeName: String
        var guideDescriptions: [String]
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        typeName = try container.decode(String.self, forKey: .typeName)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        let decoded = try container.decodeIfPresent([CodableProperty].self, forKey: .properties) ?? []
        properties = decoded.map {
            Property(
                storedName: $0.name,
                storedDescription: $0.description,
                storedTypeName: $0.typeName,
                storedGuides: $0.guideDescriptions
            )
        }
        anyOfNames = try container.decodeIfPresent([String].self, forKey: .anyOfNames) ?? []
        dynamicRootName = try container.decodeIfPresent(String.self, forKey: .dynamicRootName)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(typeName, forKey: .typeName)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(
            properties.map {
                CodableProperty(
                    name: $0.name,
                    description: $0.description,
                    typeName: $0.typeName,
                    guideDescriptions: $0.guideDescriptions
                )
            },
            forKey: .properties
        )
        try container.encode(anyOfNames, forKey: .anyOfNames)
        try container.encodeIfPresent(dynamicRootName, forKey: .dynamicRootName)
    }
}

// MARK: - Prompt construction

public struct Instructions: Sendable, Hashable, ExpressibleByStringLiteral,
    ExpressibleByStringInterpolation, InstructionsRepresentable
{
    public let content: String

    public init(_ content: String) { self.content = content }
    public init(_ content: some InstructionsRepresentable) {
        self.content = content.instructionsRepresentation.content
    }
    public init(@InstructionsBuilder _ content: () throws -> Instructions) rethrows {
        self = try content()
    }
    public init(stringLiteral value: String) { self.init(value) }
    public init(stringInterpolation: String.StringInterpolation) {
        self.init(String(stringInterpolation: stringInterpolation))
    }

    public var instructionsRepresentation: Instructions { self }
}

public struct Prompt: Sendable, Hashable, ExpressibleByStringLiteral,
    ExpressibleByStringInterpolation, PromptRepresentable
{
    public let content: String

    public init(_ content: String) { self.content = content }
    public init(_ content: some PromptRepresentable) {
        self.content = content.promptRepresentation.content
    }
    public init(@PromptBuilder _ content: () throws -> Prompt) rethrows {
        self = try content()
    }
    public init(stringLiteral value: String) { self.init(value) }
    public init(stringInterpolation: String.StringInterpolation) {
        self.init(String(stringInterpolation: stringInterpolation))
    }

    public var promptRepresentation: Prompt { self }
}

extension String: InstructionsRepresentable, PromptRepresentable {
    public var instructionsRepresentation: Instructions { Instructions(self) }
    public var promptRepresentation: Prompt { Prompt(self) }
}

@resultBuilder
public struct InstructionsBuilder {
    public static func buildExpression(_ expression: String) -> Instructions {
        Instructions(expression)
    }

    public static func buildExpression(_ expression: Instructions) -> Instructions {
        expression
    }

    public static func buildExpression<I>(
        _ expression: I
    ) -> I where I: InstructionsRepresentable {
        expression
    }

    public static func buildBlock(_ components: Instructions...) -> Instructions {
        Instructions(components.map(\.content).joined(separator: "\n"))
    }

    public static func buildBlock<each I>(
        _ components: repeat each I
    ) -> Instructions where repeat each I: InstructionsRepresentable {
        var parts: [String] = []
        for component in repeat each components {
            parts.append(component.instructionsRepresentation.content)
        }
        return Instructions(parts.joined(separator: "\n"))
    }

    public static func buildArray(
        _ instructions: [some InstructionsRepresentable]
    ) -> Instructions {
        Instructions(
            instructions.map(\.instructionsRepresentation.content).joined(separator: "\n")
        )
    }

    public static func buildEither(
        first component: some InstructionsRepresentable
    ) -> Instructions {
        component.instructionsRepresentation
    }

    public static func buildEither(
        second component: some InstructionsRepresentable
    ) -> Instructions {
        component.instructionsRepresentation
    }

    public static func buildLimitedAvailability(
        _ instructions: some InstructionsRepresentable
    ) -> Instructions {
        instructions.instructionsRepresentation
    }

    public static func buildOptional(_ instructions: Instructions?) -> Instructions {
        instructions ?? Instructions("")
    }
}

@resultBuilder
public struct PromptBuilder {
    public static func buildExpression(_ expression: String) -> Prompt {
        Prompt(expression)
    }

    public static func buildExpression(_ expression: Prompt) -> Prompt {
        expression
    }

    public static func buildExpression<P>(
        _ expression: P
    ) -> P where P: PromptRepresentable {
        expression
    }

    public static func buildBlock(_ components: Prompt...) -> Prompt {
        Prompt(components.map(\.content).joined(separator: "\n"))
    }

    public static func buildBlock<each P>(
        _ components: repeat each P
    ) -> Prompt where repeat each P: PromptRepresentable {
        var parts: [String] = []
        for component in repeat each components {
            parts.append(component.promptRepresentation.content)
        }
        return Prompt(parts.joined(separator: "\n"))
    }

    public static func buildArray(
        _ prompts: [some PromptRepresentable]
    ) -> Prompt {
        Prompt(prompts.map(\.promptRepresentation.content).joined(separator: "\n"))
    }

    public static func buildEither(
        first component: some PromptRepresentable
    ) -> Prompt {
        component.promptRepresentation
    }

    public static func buildEither(
        second component: some PromptRepresentable
    ) -> Prompt {
        component.promptRepresentation
    }

    public static func buildLimitedAvailability(
        _ prompt: some PromptRepresentable
    ) -> Prompt {
        prompt.promptRepresentation
    }

    public static func buildOptional(_ component: Prompt?) -> Prompt {
        component ?? Prompt("")
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

    @frozen public enum Availability: Sendable, Equatable {
        public enum UnavailableReason: Sendable, Hashable {
            case deviceNotEligible
            case appleIntelligenceNotEnabled
            case modelNotReady
        }

        case available
        case unavailable(UnavailableReason)
    }

    public struct Adapter: Sendable {
        public enum AssetError: Error, LocalizedError, Sendable {
            public struct Context: Sendable, Equatable {
                public let debugDescription: String
                public init(debugDescription: String) {
                    self.debugDescription = debugDescription
                }
            }

            case compatibleAdapterNotFound(Context)
            case invalidAdapterName(Context)
            case invalidAsset(Context)

            public var errorDescription: String? {
                switch self {
                case .compatibleAdapterNotFound:
                    return "No compatible adapter was found."
                case .invalidAdapterName:
                    return "The adapter name is invalid."
                case .invalidAsset:
                    return "The adapter asset is invalid or unavailable."
                }
            }

            public var recoverySuggestion: String? {
                "Install a compatible adapter asset on a supported Apple device."
            }

            public var failureReason: String? {
                switch self {
                case .compatibleAdapterNotFound(let context),
                     .invalidAdapterName(let context),
                     .invalidAsset(let context):
                    return context.debugDescription
                }
            }
        }

        public let name: String
        public let fileURL: URL?
        public var creatorDefinedMetadata: [String: Any] { [:] }

        public init(name: String) throws {
            self.name = name
            self.fileURL = nil
            throw AssetError.invalidAsset(
                .init(debugDescription: "Foundation Models adapters are unavailable on Linux.")
            )
        }

        public init(fileURL: URL) throws {
            self.name = fileURL.lastPathComponent
            self.fileURL = fileURL
            throw AssetError.invalidAsset(
                .init(debugDescription: "Foundation Models adapter files are unavailable on Linux.")
            )
        }

        public static func compatibleAdapterIdentifiers(name: String) -> [String] {
            _ = name
            return []
        }

        public static func removeObsoleteAdapters() throws {
            throw AssetError.invalidAsset(
                .init(debugDescription: "Adapter maintenance requires Apple adapter assets.")
            )
        }

        public func compile() async throws {
            throw AssetError.invalidAsset(
                .init(debugDescription: "Adapter compilation requires Apple adapter assets.")
            )
        }
    }

    public static let `default` = SystemLanguageModel()

    public let useCase: UseCase
    public let guardrails: Guardrails
    public let adapter: Adapter?

    public init(
        useCase: UseCase = .general,
        guardrails: Guardrails = .default
    ) {
        self.useCase = useCase
        self.guardrails = guardrails
        self.adapter = nil
    }

    public init(
        adapter: Adapter,
        guardrails: Guardrails = .default
    ) {
        self.useCase = .general
        self.guardrails = guardrails
        self.adapter = adapter
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
        public let transcriptEntries: ArraySlice<Transcript.Entry>

        public init(
            content: Content,
            rawContent: GeneratedContent,
            transcriptEntries: ArraySlice<Transcript.Entry> = []
        ) {
            self.content = content
            self.rawContent = rawContent
            self.transcriptEntries = transcriptEntries
        }
    }

    public enum GenerationError: Error, LocalizedError, Sendable {
        public struct Context: Sendable {
            public let debugDescription: String
            public init(debugDescription: String) {
                self.debugDescription = debugDescription
            }
        }

        public struct Refusal: Sendable {
            public let transcriptEntries: [Transcript.Entry]

            public init(transcriptEntries: [Transcript.Entry]) {
                self.transcriptEntries = transcriptEntries
            }

            public var explanation: LanguageModelSession.Response<String> {
                get async throws {
                    throw LanguageModelSession.unavailableError
                }
            }

            public var explanationStream: LanguageModelSession.ResponseStream<String> {
                LanguageModelSession.ResponseStream<String>()
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
        case refusal(Refusal, Context)

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
            case .refusal:
                return "The model refused to generate a response."
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
                 .concurrentRequests(let context),
                 .refusal(_, let context):
                return context.debugDescription
            }
        }

        public var recoverySuggestion: String? {
            "Use the application's non-generative fallback path."
        }
    }

    public struct ToolCallError: Error, LocalizedError {
        public var tool: any Tool
        public var underlyingError: any Error

        public init(tool: any Tool, underlyingError: any Error) {
            self.tool = tool
            self.underlyingError = underlyingError
        }

        public var errorDescription: String? {
            "Tool \(tool.name) failed: \(underlyingError.localizedDescription)"
        }

        public var failureReason: String? {
            underlyingError.localizedDescription
        }

        public var recoverySuggestion: String? {
            "Inspect the tool implementation and retry."
        }
    }

    public struct ResponseStream<Content>: AsyncSequence
    where Content: Generable {
        public typealias Element = Snapshot

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
            public typealias Element = Snapshot
            fileprivate var exhausted = false

            public mutating func next() async throws -> Snapshot? {
                try await next(isolation: #isolation)
            }

            public mutating func next(
                isolation actor: isolated (any Actor)? = #isolation
            ) async throws -> Snapshot? {
                _ = actor
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

    fileprivate static var unavailableError: GenerationError {
        .assetsUnavailable(.init(
            debugDescription:
                "No Apple Intelligence model service or compatible local model host is installed."
        ))
    }

    public let model: SystemLanguageModel
    public let instructions: Instructions?
    public let tools: [any Tool]
    public private(set) var transcript: Transcript
    public var isResponding: Bool { false }

    public init(
        model: SystemLanguageModel = .default,
        tools: [any Tool] = [],
        instructions: String? = nil
    ) {
        self.model = model
        self.tools = tools
        self.instructions = instructions.map { Instructions($0) }
        self.transcript = Transcript()
    }

    public init(
        model: SystemLanguageModel = .default,
        tools: [any Tool] = [],
        instructions: Instructions?
    ) {
        self.model = model
        self.tools = tools
        self.instructions = instructions
        self.transcript = Transcript()
    }

    public init(
        model: SystemLanguageModel = .default,
        tools: [any Tool] = [],
        @InstructionsBuilder instructions: () throws -> Instructions
    ) rethrows {
        self.model = model
        self.tools = tools
        self.instructions = try instructions()
        self.transcript = Transcript()
    }

    public init(
        model: SystemLanguageModel = .default,
        tools: [any Tool] = [],
        transcript: Transcript
    ) {
        self.model = model
        self.tools = tools
        self.instructions = nil
        self.transcript = transcript
    }

    public func prewarm(promptPrefix: Prompt? = nil) {
        _ = promptPrefix
    }

    @discardableResult
    public func logFeedbackAttachment(
        sentiment: LanguageModelFeedback.Sentiment? = nil,
        issues: [LanguageModelFeedback.Issue] = [],
        desiredOutput: Transcript.Entry? = nil
    ) -> Data {
        _ = sentiment
        _ = issues
        _ = desiredOutput
        return Data()
    }

    @discardableResult
    public func logFeedbackAttachment(
        sentiment: LanguageModelFeedback.Sentiment? = nil,
        issues: [LanguageModelFeedback.Issue] = [],
        desiredResponseText: String?
    ) -> Data {
        _ = desiredResponseText
        return logFeedbackAttachment(sentiment: sentiment, issues: issues, desiredOutput: nil)
    }

    @discardableResult
    public func logFeedbackAttachment(
        sentiment: LanguageModelFeedback.Sentiment? = nil,
        issues: [LanguageModelFeedback.Issue] = [],
        desiredResponseContent: (any ConvertibleToGeneratedContent)?
    ) -> Data {
        _ = desiredResponseContent
        return logFeedbackAttachment(sentiment: sentiment, issues: issues, desiredOutput: nil)
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
    public func respond(
        to prompt: Prompt,
        options: GenerationOptions = .init()
    ) async throws -> Response<String> {
        try await respond(to: prompt.content, options: options)
    }

    @discardableResult
    public func respond(
        options: GenerationOptions = .init(),
        @PromptBuilder prompt: () throws -> Prompt
    ) async throws -> Response<String> {
        try await respond(to: try prompt(), options: options)
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

    @discardableResult
    public func respond<Content>(
        to prompt: Prompt,
        generating type: Content.Type = Content.self,
        includeSchemaInPrompt: Bool = true,
        options: GenerationOptions = .init()
    ) async throws -> Response<Content> where Content: Generable {
        try await respond(
            to: prompt.content,
            generating: type,
            includeSchemaInPrompt: includeSchemaInPrompt,
            options: options
        )
    }

    @discardableResult
    public func respond<Content>(
        generating type: Content.Type = Content.self,
        includeSchemaInPrompt: Bool = true,
        options: GenerationOptions = .init(),
        @PromptBuilder prompt: () throws -> Prompt
    ) async throws -> Response<Content> where Content: Generable {
        try await respond(
            to: try prompt(),
            generating: type,
            includeSchemaInPrompt: includeSchemaInPrompt,
            options: options
        )
    }

    @discardableResult
    public func respond(
        to prompt: String,
        schema: GenerationSchema,
        includeSchemaInPrompt: Bool = true,
        options: GenerationOptions = .init()
    ) async throws -> Response<GeneratedContent> {
        _ = prompt
        _ = schema
        _ = includeSchemaInPrompt
        _ = options
        throw Self.unavailableError
    }

    @discardableResult
    public func respond(
        to prompt: Prompt,
        schema: GenerationSchema,
        includeSchemaInPrompt: Bool = true,
        options: GenerationOptions = .init()
    ) async throws -> Response<GeneratedContent> {
        try await respond(
            to: prompt.content,
            schema: schema,
            includeSchemaInPrompt: includeSchemaInPrompt,
            options: options
        )
    }

    @discardableResult
    public func respond(
        schema: GenerationSchema,
        includeSchemaInPrompt: Bool = true,
        options: GenerationOptions = .init(),
        @PromptBuilder prompt: () throws -> Prompt
    ) async throws -> Response<GeneratedContent> {
        try await respond(
            to: try prompt(),
            schema: schema,
            includeSchemaInPrompt: includeSchemaInPrompt,
            options: options
        )
    }

    public func streamResponse(
        to prompt: String,
        options: GenerationOptions = .init()
    ) -> ResponseStream<String> {
        _ = prompt
        _ = options
        return ResponseStream()
    }

    public func streamResponse(
        to prompt: Prompt,
        options: GenerationOptions = .init()
    ) -> ResponseStream<String> {
        streamResponse(to: prompt.content, options: options)
    }

    public func streamResponse(
        options: GenerationOptions = .init(),
        @PromptBuilder prompt: () throws -> Prompt
    ) rethrows -> ResponseStream<String> {
        streamResponse(to: try prompt(), options: options)
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

    public func streamResponse<Content>(
        to prompt: Prompt,
        generating type: Content.Type = Content.self,
        includeSchemaInPrompt: Bool = true,
        options: GenerationOptions = .init()
    ) -> ResponseStream<Content> where Content: Generable {
        streamResponse(
            to: prompt.content,
            generating: type,
            includeSchemaInPrompt: includeSchemaInPrompt,
            options: options
        )
    }

    public func streamResponse<Content>(
        generating type: Content.Type = Content.self,
        includeSchemaInPrompt: Bool = true,
        options: GenerationOptions = .init(),
        @PromptBuilder prompt: () throws -> Prompt
    ) rethrows -> ResponseStream<Content> where Content: Generable {
        streamResponse(
            to: try prompt(),
            generating: type,
            includeSchemaInPrompt: includeSchemaInPrompt,
            options: options
        )
    }

    public func streamResponse(
        to prompt: String,
        schema: GenerationSchema,
        includeSchemaInPrompt: Bool = true,
        options: GenerationOptions = .init()
    ) -> ResponseStream<GeneratedContent> {
        _ = prompt
        _ = schema
        _ = includeSchemaInPrompt
        _ = options
        return ResponseStream()
    }

    public func streamResponse(
        to prompt: Prompt,
        schema: GenerationSchema,
        includeSchemaInPrompt: Bool = true,
        options: GenerationOptions = .init()
    ) -> ResponseStream<GeneratedContent> {
        streamResponse(
            to: prompt.content,
            schema: schema,
            includeSchemaInPrompt: includeSchemaInPrompt,
            options: options
        )
    }

    public func streamResponse(
        schema: GenerationSchema,
        includeSchemaInPrompt: Bool = true,
        options: GenerationOptions = .init(),
        @PromptBuilder prompt: () throws -> Prompt
    ) rethrows -> ResponseStream<GeneratedContent> {
        streamResponse(
            to: try prompt(),
            schema: schema,
            includeSchemaInPrompt: includeSchemaInPrompt,
            options: options
        )
    }
}

// MARK: - Tools

public protocol Tool<Arguments, Output>: Sendable {
    associatedtype Arguments: ConvertibleFromGeneratedContent
    associatedtype Output: PromptRepresentable

    var name: String { get }
    var description: String { get }
    var parameters: GenerationSchema { get }
    var includesSchemaInInstructions: Bool { get }
    func call(arguments: Self.Arguments) async throws -> Self.Output
}

extension Tool {
    public var includesSchemaInInstructions: Bool { true }
}

extension Tool where Arguments: Generable {
    public var parameters: GenerationSchema { Arguments.generationSchema }
}

// MARK: - Transcript

public struct Transcript: Sendable, Equatable, RandomAccessCollection, Codable {
    public typealias Element = Entry
    public typealias Index = Int
    public typealias SubSequence = Slice<Transcript>
    public typealias Indices = Range<Index>
    public typealias Iterator = IndexingIterator<Transcript>

    public enum Segment: Sendable, Equatable, CustomStringConvertible {
        public typealias ID = String

        case text(TextSegment)
        case structure(StructuredSegment)

        public var id: String {
            switch self {
            case .text(let segment): return segment.id
            case .structure(let segment): return segment.id
            }
        }

        public var description: String {
            switch self {
            case .text(let segment): return segment.description
            case .structure(let segment): return segment.description
            }
        }
    }

    public struct TextSegment: Sendable, Equatable, CustomStringConvertible {
        public typealias ID = String
        public var id: String
        public var content: String

        public init(id: String = UUID().uuidString, content: String) {
            self.id = id
            self.content = content
        }

        public var description: String { content }
    }

    public struct StructuredSegment: Sendable, Equatable, CustomStringConvertible {
        public typealias ID = String
        public var id: String
        public var source: String
        public var content: GeneratedContent

        public init(
            id: String = UUID().uuidString,
            source: String,
            content: GeneratedContent
        ) {
            self.id = id
            self.source = source
            self.content = content
        }

        public var description: String { content.jsonString }
    }

    public struct ToolDefinition: Sendable, Equatable, CustomStringConvertible {
        public var name: String
        public var description: String
        public var parameters: GenerationSchema

        public init(name: String, description: String, parameters: GenerationSchema) {
            self.name = name
            self.description = description
            self.parameters = parameters
        }

        public init(tool: some Tool) {
            self.name = tool.name
            self.description = tool.description
            self.parameters = tool.parameters
        }
    }

    public struct ResponseFormat: Sendable, Equatable, CustomStringConvertible {
        public var name: String
        public var schema: GenerationSchema

        public init(schema: GenerationSchema) {
            self.name = schema.typeName
            self.schema = schema
        }

        public init<Content>(type: Content.Type) where Content: Generable {
            self.init(schema: Content.generationSchema)
        }

        public var description: String { name }
    }

    public struct Instructions: Sendable, Equatable, CustomStringConvertible {
        public typealias ID = String
        public var id: String
        public var segments: [Segment]
        public var toolDefinitions: [ToolDefinition]

        public init(
            id: String = UUID().uuidString,
            segments: [Segment],
            toolDefinitions: [ToolDefinition]
        ) {
            self.id = id
            self.segments = segments
            self.toolDefinitions = toolDefinitions
        }

        public var description: String {
            segments.map(\.description).joined(separator: " ")
        }
    }

    public struct Prompt: Sendable, Equatable, CustomStringConvertible {
        public typealias ID = String
        public var id: String
        public var segments: [Segment]
        public var options: GenerationOptions
        public var responseFormat: ResponseFormat?

        public init(
            id: String = UUID().uuidString,
            segments: [Segment],
            options: GenerationOptions = GenerationOptions(),
            responseFormat: ResponseFormat? = nil
        ) {
            self.id = id
            self.segments = segments
            self.options = options
            self.responseFormat = responseFormat
        }

        public var description: String {
            segments.map(\.description).joined(separator: " ")
        }
    }

    public struct Response: Sendable, Equatable, CustomStringConvertible {
        public typealias ID = String
        public var id: String
        public var assetIDs: [String]
        public var segments: [Segment]

        public init(
            id: String = UUID().uuidString,
            assetIDs: [String],
            segments: [Segment]
        ) {
            self.id = id
            self.assetIDs = assetIDs
            self.segments = segments
        }

        public var description: String {
            segments.map(\.description).joined(separator: " ")
        }
    }

    public struct ToolCall: Sendable, Equatable, CustomStringConvertible {
        public typealias ID = String
        public var id: String
        public var toolName: String
        public var arguments: GeneratedContent

        public init(id: String, toolName: String, arguments: GeneratedContent) {
            self.id = id
            self.toolName = toolName
            self.arguments = arguments
        }

        public var description: String { "\(toolName)(\(arguments.jsonString))" }
    }

    public struct ToolCalls: Sendable, Equatable, RandomAccessCollection, CustomStringConvertible {
        public typealias ID = String
        public typealias Element = ToolCall
        public typealias Index = Int
        public typealias SubSequence = Slice<ToolCalls>
        public typealias Indices = Range<Int>
        public typealias Iterator = IndexingIterator<ToolCalls>

        public var id: String
        public var calls: [ToolCall]

        public init<S>(
            id: String = UUID().uuidString,
            _ calls: S
        ) where S: Sequence, S.Element == ToolCall {
            self.id = id
            self.calls = Array(calls)
        }

        public var startIndex: Int { calls.startIndex }
        public var endIndex: Int { calls.endIndex }
        public subscript(position: Int) -> ToolCall { calls[position] }
        public var description: String { calls.map(\.description).joined(separator: ",") }
    }

    public struct ToolOutput: Sendable, Equatable, CustomStringConvertible {
        public typealias ID = String
        public var id: String
        public var toolName: String
        public var segments: [Segment]

        public init(id: String, toolName: String, segments: [Segment]) {
            self.id = id
            self.toolName = toolName
            self.segments = segments
        }

        public var description: String {
            segments.map(\.description).joined(separator: " ")
        }
    }

    public enum Entry: Sendable, Equatable, CustomStringConvertible {
        public typealias ID = String

        case instructions(Instructions)
        case prompt(Prompt)
        case response(Response)
        case toolCalls(ToolCalls)
        case toolOutput(ToolOutput)

        public var id: String {
            switch self {
            case .instructions(let value): return value.id
            case .prompt(let value): return value.id
            case .response(let value): return value.id
            case .toolCalls(let value): return value.id
            case .toolOutput(let value): return value.id
            }
        }

        public var description: String {
            switch self {
            case .instructions(let value): return value.description
            case .prompt(let value): return value.description
            case .response(let value): return value.description
            case .toolCalls(let value): return value.description
            case .toolOutput(let value): return value.description
            }
        }
    }

    public var entries: [Entry]

    public init(entries: some Sequence<Entry> = []) {
        self.entries = Array(entries)
    }

    public var startIndex: Int { entries.startIndex }
    public var endIndex: Int { entries.endIndex }
    public subscript(index: Index) -> Entry {
        get { entries[index] }
        set { entries[index] = newValue }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let encoded = try container.decode([CodableEntry].self)
        entries = encoded.map(\.entry)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(entries.map(CodableEntry.init(entry:)))
    }
}

private struct CodableEntry: Codable {
    var kind: String
    var id: String
    var text: String

    init(entry: Transcript.Entry) {
        kind = String(describing: entry)
        id = entry.id
        text = entry.description
    }

    var entry: Transcript.Entry {
        .prompt(
            Transcript.Prompt(
                id: id,
                segments: [.text(.init(id: id, content: text))]
            )
        )
    }
}

// MARK: - Dynamic schemas

public struct DynamicGenerationSchema: Sendable, Equatable {
    public struct Property: Sendable, Equatable {
        public var name: String
        public var schemaDescription: String?
        public var schema: DynamicGenerationSchema
        public var isOptional: Bool

        public init(
            name: String,
            description: String? = nil,
            schema: DynamicGenerationSchema,
            isOptional: Bool = false
        ) {
            self.name = name
            self.schemaDescription = description
            self.schema = schema
            self.isOptional = isOptional
        }
    }

    public var name: String
    public var schemaDescription: String?
    public var properties: [Property]
    public var choices: [String]
    public var nestedChoices: [DynamicGenerationSchema]
    private var boxedItemSchema: [DynamicGenerationSchema]
    public var itemSchema: DynamicGenerationSchema? {
        get { boxedItemSchema.first }
        set { boxedItemSchema = newValue.map { [$0] } ?? [] }
    }
    public var minimumElements: Int?
    public var maximumElements: Int?
    public var referenceName: String?

    public init(name: String, description: String? = nil, properties: [Property]) {
        self.name = name
        self.schemaDescription = description
        self.properties = properties
        self.choices = []
        self.nestedChoices = []
        self.boxedItemSchema = []
        self.minimumElements = nil
        self.maximumElements = nil
        self.referenceName = nil
    }

    public init(name: String, description: String? = nil, anyOf choices: [String]) {
        self.name = name
        self.schemaDescription = description
        self.properties = []
        self.choices = choices
        self.nestedChoices = []
        self.boxedItemSchema = []
        self.minimumElements = nil
        self.maximumElements = nil
        self.referenceName = nil
    }

    public init(name: String, description: String? = nil, anyOf choices: [DynamicGenerationSchema]) {
        self.name = name
        self.schemaDescription = description
        self.properties = []
        self.choices = choices.map(\.name)
        self.nestedChoices = choices
        self.boxedItemSchema = []
        self.minimumElements = nil
        self.maximumElements = nil
        self.referenceName = nil
    }

    public init(
        arrayOf itemSchema: DynamicGenerationSchema,
        minimumElements: Int? = nil,
        maximumElements: Int? = nil
    ) {
        self.name = "Array"
        self.schemaDescription = nil
        self.properties = []
        self.choices = []
        self.nestedChoices = []
        self.boxedItemSchema = [itemSchema]
        self.minimumElements = minimumElements
        self.maximumElements = maximumElements
        self.referenceName = nil
    }

    public init(referenceTo name: String) {
        self.name = name
        self.schemaDescription = nil
        self.properties = []
        self.choices = []
        self.nestedChoices = []
        self.boxedItemSchema = []
        self.minimumElements = nil
        self.maximumElements = nil
        self.referenceName = name
    }

    public init<Value>(
        type: Value.Type,
        guides: [GenerationGuide<Value>] = []
    ) where Value: Generable {
        _ = guides
        self.name = String(reflecting: type)
        self.schemaDescription = nil
        self.properties = []
        self.choices = []
        self.nestedChoices = []
        self.boxedItemSchema = []
        self.minimumElements = nil
        self.maximumElements = nil
        self.referenceName = nil
    }
}

// MARK: - Feedback

public struct LanguageModelFeedback: Sendable {
    public enum Sentiment: String, Sendable, Hashable, CaseIterable {
        case negative
        case neutral
        case positive
    }

    public struct Issue: Sendable {
        public enum Category: String, Sendable, Hashable, CaseIterable {
            case tooVerbose
            case stereotypeOrBias
            case vulgarOrOffensive
            case suggestiveOrSexual
            case didNotFollowInstructions
            case triggeredGuardrailUnexpectedly
            case incorrect
            case unhelpful
        }

        public var category: Category
        public var explanation: String?

        public init(category: Category, explanation: String? = nil) {
            self.category = category
            self.explanation = explanation
        }
    }
}

extension GenerationSchema.Property: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.name == rhs.name
            && lhs.description == rhs.description
            && lhs.typeName == rhs.typeName
            && lhs.guideDescriptions == rhs.guideDescriptions
    }
}

extension GenerationSchema: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.typeName == rhs.typeName
            && lhs.description == rhs.description
            && lhs.properties == rhs.properties
            && lhs.anyOfNames == rhs.anyOfNames
            && lhs.dynamicRootName == rhs.dynamicRootName
    }
}
