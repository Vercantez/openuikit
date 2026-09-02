import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Expands a stored-looking EnvironmentValues declaration into the same
/// key-backed computed-property shape as SwiftUI's production `@Entry` macro.
struct EntryMacro: AccessorMacro, PeerMacro {
    private static func binding(
        from declaration: some DeclSyntaxProtocol
    ) throws -> (TokenSyntax, TypeSyntax, ExprSyntax) {
        guard let variable = declaration.as(VariableDeclSyntax.self),
              variable.bindings.count == 1,
              let binding = variable.bindings.first,
              binding.accessorBlock == nil,
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier,
              let type = binding.typeAnnotation?.type,
              let initializer = binding.initializer?.value else {
            throw MacroExpansionErrorMessage(
                "@Entry requires one explicitly typed property with a default value"
            )
        }
        return (identifier, type, initializer)
    }

    static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        _ = node
        _ = context
        let (identifier, _, _) = try binding(from: declaration)
        return [
            "get { self[__Key_\(identifier).self] }",
            "set { self[__Key_\(identifier).self] = newValue }",
        ]
    }

    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        _ = node
        _ = context
        let (identifier, type, initializer) = try binding(from: declaration)
        return [
            """
            private struct __Key_\(identifier): EnvironmentKey {
                static var defaultValue: \(type) { \(initializer) }
            }
            """
        ]
    }
}
