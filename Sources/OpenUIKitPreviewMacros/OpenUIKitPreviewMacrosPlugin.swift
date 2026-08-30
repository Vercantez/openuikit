import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct OpenUIKitPreviewMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        UIKitPreviewMacro.self,
    ]
}
