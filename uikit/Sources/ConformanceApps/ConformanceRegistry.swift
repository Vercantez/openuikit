// The ONE conformance-app table (docs/HILLCLIMB.md).
//
// Every app used to be listed by hand in five places (AppMode.swift,
// ConformanceMode.swift, openhost usage, Package.swift's exclude list, the
// confprobe glue). Adding an app collided on all five. Now:
//
//   * each app appends ONE line from its own *App.swift
//     (`extension ConformanceApps { static let _register<Name> = register(...) }`);
//   * `scripts/gen_conformance_registry.sh` scans Sources/ConformanceApps and
//     writes Registry.swift, which materialises those lines into `registry`;
//   * Package.swift scans the same directory for script.json excludes;
//   * openhost and Tools/oracle2/confprobe both read `ConformanceApps.registry`.
//
// Registry.swift is checked in. ConformanceRegistryTests asserts that
// regenerating it changes nothing.
import UIKit

public enum ConformanceApps {
    public struct Entry {
        public let windowSize: CGSize
        public let makeRoot: @MainActor () -> UIViewController
        public let perform: @MainActor (String) -> Void
        public let scriptPath: String
    }

    @MainActor
    static var _storage: [String: Entry] = [:]

    /// Insert one app. Called from the app's own file (one line) and
    /// materialised by the generated `loadRegistry()`.
    @MainActor
    @discardableResult
    public static func register(
        _ name: String,
        windowSize: CGSize,
        makeRoot: @escaping @MainActor () -> UIViewController,
        perform: @escaping @MainActor (String) -> Void,
        scriptPath: String
    ) -> Void {
        _storage[name] = Entry(windowSize: windowSize, makeRoot: makeRoot,
                               perform: perform, scriptPath: scriptPath)
    }

    /// name → windowSize / makeRoot / perform / script path. Same table
    /// openhost boots and confprobe compiles against real UIKit.
    @MainActor
    public static var registry: [String: Entry] {
        loadRegistry()
        return _storage
    }

    /// Help text for `openhost --help`, one line per scanned app. Built from
    /// `names` so it does not need the main actor (makeRoot/perform do).
    public static var usageLines: String {
        var lines: [String] = []
        for name in names {
            var padCount = 10 - name.count
            if padCount < 1 { padCount = 1 }
            var pad = ""
            var i = 0
            while i < padCount {
                pad += " "
                i += 1
            }
            lines.append("  \(name)\(pad)a CONFORMANCE app (Sources/ConformanceApps/\(name))")
        }
        var out = ""
        for (i, line) in lines.enumerated() {
            if i > 0 { out += "\n" }
            out += line
        }
        return out
    }

    /// True when `name` is a scanned conformance app. A linear scan rather
    /// than `String.contains`, which the guest load list cannot link
    /// (docs/AGENT_BRIEF_ORACLE.md, measured at 54be0035).
    public static func isRegistered(_ name: String) -> Bool {
        for n in names {
            if n == name { return true }
        }
        return false
    }
}
