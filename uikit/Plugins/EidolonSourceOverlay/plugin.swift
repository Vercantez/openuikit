// Build-time source overlays for vendored Eidolon dependencies
// (Sources/EidolonDependencies/overlays/README.md).
//
// The vendored checkout is never edited. For each `<File>.swift.patch` in the
// overlays directory whose target matches, this plugin runs `patch` on the
// pristine vendored file into the plugin work directory; the target excludes
// the original and compiles the patched copy. The identical patch files are
// applied to the real-UIKit golden build of Eidolon (same compile-only
// incompatibility), so both builds compile the same source.
import Foundation
import PackagePlugin

@main
struct EidolonSourceOverlay: BuildToolPlugin {
    /// target name -> (patch file, file inside the target directory)
    static let overlays: [String: [(patch: String, source: String)]] = [
        "RxCocoa": [
            ("RxTableViewReactiveArrayDataSource.swift.patch",
             "iOS/DataSources/RxTableViewReactiveArrayDataSource.swift"),
            ("RxCollectionViewReactiveArrayDataSource.swift.patch",
             "iOS/DataSources/RxCollectionViewReactiveArrayDataSource.swift"),
        ],
    ]

    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        guard let entries = Self.overlays[target.name] else { return [] }
        let overlayDir = context.package.directory
            .appending(subpath: "Sources/EidolonDependencies/overlays")
        return entries.map { entry in
            let patch = overlayDir.appending(subpath: entry.patch)
            let original = target.directory.appending(subpath: entry.source)
            let output = context.pluginWorkDirectory.appending(subpath: original.lastComponent)
            return .buildCommand(
                displayName: "Overlay \(entry.patch)",
                executable: Path("/usr/bin/patch"),
                arguments: ["-s", "-o", output.string, "-i", patch.string, original.string],
                inputFiles: [patch, original],
                outputFiles: [output])
        }
    }
}
