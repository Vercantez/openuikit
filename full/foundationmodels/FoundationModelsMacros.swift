import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Implements the same source contract as Apple's `@Generable` macro for
/// stored struct properties.  It intentionally rejects declarations it cannot
/// model instead of silently fabricating a schema.
public struct GenerableMacro: MemberMacro, ExtensionMacro {
    private struct Property {
        let name: String
        let type: String
        let description: String?
        let guides: [String]
    }

    public static func expansion<Declaration, Context>(
        of node: AttributeSyntax,
        providingMembersOf declaration: Declaration,
        conformingTo protocols: [TypeSyntax],
        in context: Context
    ) throws -> [DeclSyntax]
    where Declaration: DeclGroupSyntax, Context: MacroExpansionContext {
        let properties = try storedProperties(of: declaration)
        let description = argument(named: "description", in: node)

        let schemaProperties = properties.map { property in
            let descriptionArgument = property.description.map {
                ", description: \($0)"
            } ?? ""
            let guideArgument = property.guides.isEmpty
                ? ""
                : ", guides: [\(property.guides.joined(separator: ", "))]"
            return "FoundationModels.GenerationSchema.Property(name: \"\(property.name)\"\(descriptionArgument), type: \(property.type).self\(guideArgument))"
        }.joined(separator: ",\n")

        let schemaDescription = description.map { ", description: \($0)" } ?? ""
        let appendProperties = properties.map { property in
            "addProperty(name: \"\(property.name)\", value: self.\(property.name))"
        }.joined(separator: "\n")
        let partialProperties = properties.map { property in
            "var \(property.name): \(property.type).PartiallyGenerated?"
        }.joined(separator: "\n")
        let partialAssignments = properties.map { property in
            "self.\(property.name) = try content.value(forProperty: \"\(property.name)\")"
        }.joined(separator: "\n")

        return [
            DeclSyntax(stringLiteral: """
            nonisolated static var generationSchema: FoundationModels.GenerationSchema {
                FoundationModels.GenerationSchema(
                    type: Self.self\(schemaDescription),
                    properties: [
                        \(schemaProperties)
                    ]
                )
            }
            """),
            DeclSyntax(stringLiteral: """
            nonisolated var generatedContent: FoundationModels.GeneratedContent {
                var properties = [(String, any FoundationModels.ConvertibleToGeneratedContent)]()
                \(appendProperties)
                return FoundationModels.GeneratedContent(
                    properties: properties,
                    uniquingKeysWith: { _, second in second }
                )
                func addProperty(name: String, value: some FoundationModels.Generable) {
                    properties.append((name, value))
                }
                func addProperty(name: String, value: (some FoundationModels.Generable)?) {
                    if let value { properties.append((name, value)) }
                }
            }
            """),
            DeclSyntax(stringLiteral: """
            nonisolated struct PartiallyGenerated: Identifiable, FoundationModels.ConvertibleFromGeneratedContent {
                var id: FoundationModels.GenerationID
                \(partialProperties)
                nonisolated init(_ content: FoundationModels.GeneratedContent) throws {
                    self.id = content.id ?? FoundationModels.GenerationID()
                    \(partialAssignments)
                }
            }
            """),
        ]
    }

    public static func expansion<Declaration, Context, ExtendedType>(
        of node: AttributeSyntax,
        attachedTo declaration: Declaration,
        providingExtensionsOf type: ExtendedType,
        conformingTo protocols: [TypeSyntax],
        in context: Context
    ) throws -> [ExtensionDeclSyntax]
    where
        Declaration: DeclGroupSyntax,
        Context: MacroExpansionContext,
        ExtendedType: TypeSyntaxProtocol
    {
        let properties = try storedProperties(of: declaration)
        let assignments = properties.map { property in
            "self.\(property.name) = try content.value(forProperty: \"\(property.name)\")"
        }.joined(separator: "\n")
        return [try ExtensionDeclSyntax("""
            extension \(type.trimmed): FoundationModels.Generable {
                nonisolated init(_ content: FoundationModels.GeneratedContent) throws {
                    \(raw: assignments)
                }
            }
            """)]
    }

    private static func storedProperties<Declaration: DeclGroupSyntax>(
        of declaration: Declaration
    ) throws -> [Property] {
        var result: [Property] = []
        for item in declaration.memberBlock.members {
            guard let variable = item.decl.as(VariableDeclSyntax.self) else { continue }
            guard variable.modifiers.allSatisfy({ $0.name.text != "static" }) else {
                continue
            }
            for binding in variable.bindings {
                guard binding.accessorBlock == nil,
                      let identifier = binding.pattern.as(IdentifierPatternSyntax.self),
                      let annotation = binding.typeAnnotation
                else { continue }
                let guide = guideArguments(from: variable)
                result.append(Property(
                    name: identifier.identifier.text,
                    type: annotation.type.trimmedDescription,
                    description: guide.description,
                    guides: guide.guides
                ))
            }
        }
        if result.isEmpty {
            throw MacroError.message("@Generable requires at least one typed stored property")
        }
        return result
    }

    private static func guideArguments(
        from variable: VariableDeclSyntax
    ) -> (description: String?, guides: [String]) {
        for element in variable.attributes {
            guard let attribute = element.as(AttributeSyntax.self),
                  attribute.attributeName.trimmedDescription == "Guide"
            else { continue }
            let arguments = rawArguments(of: attribute)
            var description: String?
            var guides: [String] = []
            for argument in splitTopLevel(arguments) {
                let trimmed = trimWhitespace(argument)
                if trimmed.hasPrefix("description:") {
                    description = trimWhitespace(
                        String(trimmed.dropFirst("description:".count))
                    )
                } else if !trimmed.isEmpty {
                    guides.append(trimmed)
                }
            }
            return (description, guides)
        }
        return (nil, [])
    }

    private static func argument(named label: String, in node: AttributeSyntax) -> String? {
        for argument in splitTopLevel(rawArguments(of: node)) {
            let trimmed = trimWhitespace(argument)
            let prefix = "\(label):"
            if trimmed.hasPrefix(prefix) {
                let value = trimWhitespace(String(trimmed.dropFirst(prefix.count)))
                return value == "nil" ? nil : value
            }
        }
        return nil
    }

    private static func rawArguments(of attribute: AttributeSyntax) -> String {
        let text = attribute.trimmedDescription
        guard let open = text.firstIndex(of: "("),
              let close = text.lastIndex(of: ")"), open < close
        else { return "" }
        return String(text[text.index(after: open)..<close])
    }

    private static func trimWhitespace(_ text: String) -> String {
        func isWhitespace(_ character: Character) -> Bool {
            character == " " || character == "\t" || character == "\n" || character == "\r"
        }
        let leading = text.drop(while: isWhitespace)
        return String(leading.reversed().drop(while: isWhitespace).reversed())
    }

    private static func splitTopLevel(_ text: String) -> [String] {
        var result: [String] = []
        var current = ""
        var depth = 0
        var inString = false
        var escaped = false
        for character in text {
            if inString {
                current.append(character)
                if escaped {
                    escaped = false
                } else if character == "\\" {
                    escaped = true
                } else if character == "\"" {
                    inString = false
                }
                continue
            }
            switch character {
            case "\"":
                inString = true
                current.append(character)
            case "(", "[", "{", "<":
                depth += 1
                current.append(character)
            case ")", "]", "}", ">":
                depth -= 1
                current.append(character)
            case "," where depth == 0:
                result.append(current)
                current = ""
            default:
                current.append(character)
            }
        }
        result.append(current)
        return result
    }

    private enum MacroError: Error, CustomStringConvertible {
        case message(String)
        var description: String {
            switch self { case .message(let message): return message }
        }
    }
}

public struct GuideMacro: PeerMacro {
    public static func expansion<Context: MacroExpansionContext>(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: Context
    ) throws -> [DeclSyntax] {
        []
    }
}
