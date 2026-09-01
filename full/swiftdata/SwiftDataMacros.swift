import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// The portable persistence runtime stores ordinary Swift reference types.
/// `@Model` therefore only needs to attach the public protocol identity; it
/// deliberately leaves user storage and initializers untouched.
public struct PersistentModelMacro: MemberMacro, ExtensionMacro {
    public static func expansion<Declaration, Context>(
        of node: AttributeSyntax,
        providingMembersOf declaration: Declaration,
        conformingTo protocols: [TypeSyntax],
        in context: Context
    ) throws -> [DeclSyntax]
    where Declaration: DeclGroupSyntax, Context: MacroExpansionContext {
        [
            "private let _swiftDataPersistentIdentifier = SwiftData.PersistentIdentifier()",
            "public var persistentModelID: SwiftData.PersistentIdentifier { _swiftDataPersistentIdentifier }",
            "public var id: SwiftData.PersistentIdentifier { persistentModelID }",
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
        [try ExtensionDeclSyntax("extension \(type.trimmed): SwiftData.PersistentModel {}")]
    }
}
