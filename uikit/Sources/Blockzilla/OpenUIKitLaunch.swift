// Harness, not Focus source. Same module as AppDelegate so it can
// construct the internal type and run UIApplicationMain. RealAppProbe
// imports Blockzilla and calls FocusBrowserLaunch.makeRoot().

import UIKit
import Onboarding
import Darwin

func installFocusMainBundleResources() {
    let fm = FileManager.default
    let cwd = fm.currentDirectoryPath
    let source = cwd + "/fixtures/realapp/focus-bundle"
    guard fm.fileExists(atPath: source + "/SearchEngines.plist") else { return }
    // argv[0] is the executable; Apple's CLI Bundle.main searches that
    // directory. Do not query Bundle.main first: Foundation snapshots
    // the resource inventory on first access. MEASURED try3: reading
    // resourceURL then copying left path(forResource:ofType: "json")
    // nil for disconnect-advertising.json.
    let exe = URL(fileURLWithPath: CommandLine.arguments[0]).standardizedFileURL
    var dests = [exe.deletingLastPathComponent().path]
    for extra in [
        cwd + "/.build/debug",
        cwd + "/.build/arm64-apple-macosx/debug",
        cwd + "/.build/release",
        cwd + "/.build/arm64-apple-macosx/release",
    ] where !dests.contains(extra) {
        dests.append(extra)
    }
    guard let items = try? fm.contentsOfDirectory(atPath: source) else { return }
    for destDir in dests {
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: destDir, isDirectory: &isDir), isDir.boolValue else { continue }
        for name in items {
            if name.hasPrefix(".") { continue }
            let from = source + "/" + name
            let to = destDir + "/" + name
            try? fm.removeItem(atPath: to)
            try? fm.copyItem(atPath: from, toPath: to)
        }
    }
}

@MainActor
public enum FocusBrowserLaunch {
    /// Seed returning-user onboarding state so AppDelegate's
    /// `send(.applicationDidLaunch)` does not present the first-run
    /// overlay. ToolTipRoute is Codable; the set is what
    /// OnboardingEventsHandlerV1/V2 persist under ShownTips.
    public static func prepareReturningUserDefaults() {
        let shown: Set<ToolTipRoute> = [
            .onboarding(.v1),
            .onboarding(.v2),
            .searchBar,
            .menu,
        ]
        if let data = try? JSONEncoder().encode(shown) {
            UserDefaults.standard.set(data, forKey: OnboardingConstants.shownTips)
        }
        UserDefaults.standard.set(true, forKey: OnboardingConstants.onboardingDidAppear)
        UserDefaults.standard.set(true, forKey: OnboardingConstants.showOldOnboarding)
    }

    /// WebCacheUtils.reset() (AppDelegate.swift:158) enumerates
    /// NSSearchPath .cachesDirectory and deletes every child except a
    /// whitelist. On a real iOS app that directory is the sandbox; on a
    /// SwiftPM CLI it is ~/Library/Caches. MEASURED try7: NSLog
    /// `Unable to delete file at …/Library/Caches/dotslash`. Redirect
    /// HOME to a throwaway directory before UIApplicationMain.
    private static func sandboxProcessHome() {
        let home = NSTemporaryDirectory() + "focus-launch-home"
        let fm = FileManager.default
        try? fm.createDirectory(
            atPath: home + "/Library/Caches",
            withIntermediateDirectories: true
        )
        try? fm.createDirectory(
            atPath: home + "/Library/Cookies",
            withIntermediateDirectories: true
        )
        try? fm.createDirectory(
            atPath: home + "/Library/Application Support",
            withIntermediateDirectories: true
        )
        home.withCString { ptr in
            if let copy = strdup(ptr) {
                _ = setenv("HOME", copy, 1)
                _ = setenv("CFFIXED_USER_HOME", copy, 1)
            }
        }
    }

    public static func installBundleResources() {
        installFocusMainBundleResources()
    }

    public static func makeRoot() -> UIViewController {
        prepareReturningUserDefaults()
        sandboxProcessHome()
        installBundleResources()
        let delegate = AppDelegate()
        _ = UIApplicationMain(delegate: delegate)
        guard let root = delegate.window?.rootViewController else {
            return UIViewController()
        }
        return root
    }
}
