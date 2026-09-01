import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct OpenSwiftUIMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        EntryMacro.self,
    ]
}
