// This file adapts the registry/source-location skeleton from OpenSwiftUI's
// MIT-licensed PreviewMacro.swift at the exact provenance recorded in
// docs/PREVIEW.md and THIRD_PARTY_LICENSES/OpenSwiftUI.txt. It was changed for
// UIKit and SwiftUI values, a bounded optional display-name boundary, and
// Apple's measured single-expression expansion shape.
// OpenSwiftUI portions copyright (c) 2023-2025 Kyle-Ye.

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct UIKitPreviewMacro: DeclarationMacro {
    static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard node.arguments.count <= 1,
              node.additionalTrailingClosures.isEmpty,
              let body = node.trailingClosure else {
            throw MacroExpansionErrorMessage(
                "OpenUIKit #Preview requires an optional display name and exactly one trailing closure"
            )
        }

        guard let sourceLocation = context.location(
            of: node,
            at: .afterLeadingTrivia,
            filePathMode: .fileID
        ) else {
            throw MacroExpansionErrorMessage(
                "OpenUIKit #Preview could not determine its source location"
            )
        }

        let registryName = context.makeUniqueName("PreviewRegistry")
        let registry: DeclSyntax =
            """
            @available(iOS 17.0, macOS 14.0, tvOS 17.0, visionOS 1.0, watchOS 10.0, *)
            struct \(registryName): DeveloperToolsSupport.PreviewRegistry {
                static var fileID: String {
                    \(sourceLocation.file)
                }
                static var line: Int {
                    \(sourceLocation.line)
                }
                static var column: Int {
                    \(sourceLocation.column)
                }

                static func makePreview() throws -> DeveloperToolsSupport.Preview {
                    DeveloperToolsSupport.Preview(body: {
                        @resultBuilder struct __B_Builder<Content> {
                            static func buildBlock(_ content: Content) -> Content {
                                content
                            }
                        }
                        func __b_buildContent<Content>(
                            @__B_Builder<Content> build: () -> Content
                        ) -> Content {
                            build()
                        }
                        return __b_buildContent \(body)
                    })
                }
            }
            """
        return [registry]
    }
}
