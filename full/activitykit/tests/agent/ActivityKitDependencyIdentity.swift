import ActivityKit
import Foundation
import SwiftUI
import WidgetKit

/// EC2 dependency-identity probe for ActivityKit.
///
/// Isolated `test_host.sh` does not compile this file. A future clean EC2 run
/// must:
/// 1. Build guest Foundation, SwiftUI, and WidgetKit modules and dylibs.
/// 2. Build ActivityKit with those `-I`/`-L` paths and `-D OPENUIKIT_GUEST`
///    so `AlertConfiguration` is compiled against
///    `Foundation.LocalizedStringResource`.
/// 3. Emit `ActivityKit.swiftinterface` and/or an ActivityKit symbol graph
///    next to `libActivityKit.dylib`, or pass
///    `ACTIVITYKIT_SWIFTINTERFACE` / `ACTIVITYKIT_SYMBOLGRAPH`.
/// 4. Link this client against `libActivityKit.dylib` (and the guest
///    dependencies), then run with `LD_LIBRARY_PATH` covering those dylibs.
///
/// Expected exact marker:
/// `ACTIVITYKIT_DEPENDENCY_IDENTITY_OK foundation=LocalizedStringResource dylib=libActivityKit.dylib`
enum ActivityKitDependencyIdentity {
    static func main() throws {
        let titleResource: Foundation.LocalizedStringResource = "Title"
        let bodyResource: Foundation.LocalizedStringResource = "Body"
        let alert = AlertConfiguration(
            title: titleResource,
            body: bodyResource,
            sound: .default
        )
        let assignedTitle: Foundation.LocalizedStringResource = alert.title
        let assignedBody: Foundation.LocalizedStringResource = alert.body
        _ = (assignedTitle, assignedBody)

        let titleName = _typeName(type(of: alert.title), qualified: true)
        let bodyName = _typeName(type(of: alert.body), qualified: true)
        if !titleName.contains("Foundation") || !titleName.contains("LocalizedStringResource") {
            fatalError("title is not Foundation.LocalizedStringResource: \(titleName)")
        }
        if !bodyName.contains("Foundation") || !bodyName.contains("LocalizedStringResource") {
            fatalError("body is not Foundation.LocalizedStringResource: \(bodyName)")
        }
        if titleName.contains("ActivityKit") || bodyName.contains("ActivityKit") {
            fatalError("LocalizedStringResource must not be an ActivityKit nominal type")
        }

        let named = AlertConfiguration(
            title: titleResource,
            body: bodyResource,
            sound: .named("chime")
        )
        if alert == named {
            fatalError("default sound must not equal named(chime)")
        }
        if AlertConfiguration.AlertSound.default == .named("default") {
            fatalError("default sound must remain distinct from named(default)")
        }

        let dylibPath = loadedLibraryPath(containing: "libActivityKit.dylib")
        guard let dylibPath else {
            fatalError("libActivityKit.dylib is not loaded in this process")
        }

        inspectEmittedInterface(nearDylib: dylibPath)

        print(
            "ACTIVITYKIT_DEPENDENCY_IDENTITY_OK foundation=LocalizedStringResource dylib=libActivityKit.dylib"
        )
    }
}

private func loadedLibraryPath(containing name: String) -> String? {
    guard let maps = try? String(contentsOfFile: "/proc/self/maps", encoding: .utf8) else {
        return nil
    }
    for line in maps.split(separator: "\n") {
        guard line.contains(name) else { continue }
        if let slash = line.firstIndex(of: "/") {
            return String(line[slash...])
        }
    }
    return nil
}

private func inspectEmittedInterface(nearDylib dylibPath: String) {
    let environment = ProcessInfo.processInfo.environment
    var files: [URL] = []
    if let explicit = environment["ACTIVITYKIT_SWIFTINTERFACE"] {
        files.append(URL(fileURLWithPath: explicit))
    }
    if let explicit = environment["ACTIVITYKIT_SYMBOLGRAPH"] {
        files.append(URL(fileURLWithPath: explicit))
    }

    let directory = URL(fileURLWithPath: dylibPath).deletingLastPathComponent()
    files.append(directory.appendingPathComponent("ActivityKit.swiftinterface"))
    files.append(directory.appendingPathComponent("ActivityKit.symbols.json"))
    if let graphDir = environment["ACTIVITYKIT_SYMBOLGRAPH_DIR"] {
        let dir = URL(fileURLWithPath: graphDir)
        if let contents = try? FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: nil
        ) {
            files.append(
                contentsOf: contents.filter {
                    $0.lastPathComponent.contains("ActivityKit")
                        && ($0.pathExtension == "json" || $0.path.hasSuffix(".symbols.json"))
                }
            )
        }
    }

    var inspected = 0
    for file in files {
        guard FileManager.default.isReadableFile(atPath: file.path) else { continue }
        guard let text = try? String(contentsOf: file, encoding: .utf8) else { continue }
        inspected += 1
        let hasFoundationIdentity =
            text.contains("Foundation.LocalizedStringResource")
            || text.contains("10Foundation23LocalizedStringResource")
        if !hasFoundationIdentity {
            fatalError("\(file.lastPathComponent) does not name Foundation.LocalizedStringResource")
        }
        if text.contains("public struct LocalizedStringResource") {
            fatalError("\(file.lastPathComponent) publishes ActivityKit.LocalizedStringResource")
        }
        let activityKitNominal =
            text.contains("s:11ActivityKit23LocalizedStringResourceV")
            || text.contains("ActivityKit.LocalizedStringResource")
        if activityKitNominal {
            fatalError("\(file.lastPathComponent) uses ActivityKit.LocalizedStringResource")
        }
    }
    if inspected == 0 {
        fatalError(
            "no ActivityKit.swiftinterface or symbol graph found; set ACTIVITYKIT_SWIFTINTERFACE or ACTIVITYKIT_SYMBOLGRAPH"
        )
    }
}

do {
    try ActivityKitDependencyIdentity.main()
} catch {
    fatalError("ActivityKit dependency identity failed: \(error)")
}
