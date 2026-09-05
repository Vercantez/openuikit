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

/// Shared 60 Hz frame clock for both halves of the conformance harness.
///
/// Script times (`t` in script.json) map with `Int((t * 60).rounded())`,
/// so a mid-flight capture at +0.15 s is **frame 9** after the action
/// (TableEditor t1350 / t2350) and +0.2 s is **frame 12** (Modal t600).
/// `Tools/oracle2/confprobe` drives that index from a CADisplayLink;
/// openhost steps `OpenUIKitRuntime.animationTime` by the same integer
/// frames (`Double(frame) / 60`). Wall-clock GCD `asyncAfter` is not
/// used: the same delay landed at remaining 0.162 / 0.179 / 0.238
/// depending on whether the capture was a GCD timer, openhost's loop,
/// or a vsync (scoreboard/open.txt, TableEditor t1350, iPhone SE 2x /
/// iOS 26.1). Accumulating `t += 1/60` also missed t=2.35 by one
/// frame (fire_n=142 vs ideal 141) — integer frames do not.
public enum ConformanceClock {
    public static let hz: Int = 60

    public static func frameIndex(for t: Double) -> Int {
        Int((t * Double(hz)).rounded())
    }

    public static func time(of frame: Int) -> Double {
        Double(frame) / Double(hz)
    }

    /// Frame-file suffix. Light stays `t200` so existing goldens keep their
    /// names; dark appends `.dark` (`t200.dark`), RTL appends `.rtl`
    /// (`t200.rtl`), and landscape appends `.landscape` (`t200.landscape`)
    /// so those timelines do not collide on the scoreboard
    /// (`NavFlow:t200` vs `NavFlow:t200.dark` vs `NavFlow:t200.rtl` vs
    /// `NavFlow:t200.landscape`).
    public static func captureSuffix(for t: Double, style: String = "light",
                                     direction: String = "ltr",
                                     orientation: String = "portrait") -> String {
        var ms = "\(Int((t * 1000).rounded()))"
        while ms.count < 3 { ms = "0" + ms }
        var suffix = "t" + ms
        if style == "dark" { suffix += ".dark" }
        if direction == "rtl" { suffix += ".rtl" }
        if orientation == "landscape" { suffix += ".landscape" }
        return suffix
    }

    /// Style a replay should use. `CONFPROBE_STYLE` / `OPENUIKIT_APP_STYLE`
    /// (set by `conformance_flow.sh --dark`) wins so a light `script.json`
    /// can still drive a dark timeline; otherwise the script's `style`
    /// field; otherwise light. Equality only — no `String.contains`.
    public static func resolvedStyle(script: String, environment: String?) -> String {
        if let environment, environment == "dark" { return "dark" }
        if script == "dark" { return "dark" }
        return "light"
    }

    /// Layout direction a replay should use. `CONFPROBE_DIRECTION` /
    /// `OPENUIKIT_APP_DIRECTION` (set by `conformance_flow.sh --rtl`) wins
    /// so an LTR `script.json` can still drive an RTL timeline; otherwise the
    /// script's `direction` field; otherwise LTR. Equality only.
    public static func resolvedDirection(script: String, environment: String?) -> String {
        if let environment, environment == "rtl" { return "rtl" }
        if script == "rtl" { return "rtl" }
        return "ltr"
    }

    /// Interface orientation a replay should use. `CONFPROBE_ORIENTATION` /
    /// `OPENUIKIT_APP_ORIENTATION` (set by `conformance_flow.sh --landscape`)
    /// wins so a portrait `script.json` can still drive a landscape
    /// timeline; otherwise the script's `orientation` field; otherwise
    /// portrait. Equality only — no `String.contains`.
    public static func resolvedOrientation(script: String, environment: String?) -> String {
        if let environment, environment == "landscape" { return "landscape" }
        if script == "landscape" { return "landscape" }
        return "portrait"
    }
}
