// Bundle.swift -- the third piece of the process layer.
//
// A real app expects `Foo.app` with an Info.plist and resources RELATIVE TO
// THE BUNDLE. OpenUIKit resolves resources from a single search path
// (`OpenUIKitRuntime.resourceRoot`, one String), which is fine for a renderer
// driven by a test harness and is not how an app finds anything.
//
// TWO LAYOUTS, BOTH REAL, and the difference is not cosmetic:
//
//   iOS (flat)      Foo.app/Foo            Foo.app/Info.plist
//                                          Foo.app/<resource>
//   macOS           Foo.app/Contents/MacOS/Foo
//                                          Foo.app/Contents/Info.plist
//                                          Foo.app/Contents/Resources/<resource>
//
// Both are present in ~/uikit/Tools/oracle2 -- SheetProbe.app is flat,
// Oracle2.app has Contents/ -- so this is tested against real bundles rather
// than ones constructed to match the code.
//
// FINDING THE BUNDLE IS PURE STRING WORK, ON PURPOSE. Walk up the executable
// path for a component ending in ".app"; the presence of a "Contents"
// component decides the layout. No directory probing, so it cannot be fooled
// by a missing-file answer and behaves identically wherever it runs.
//
// WHAT REAL UIKIT USES TO GET THE EXECUTABLE PATH IS ABSENT HERE.
// `_NSGetExecutablePath` is not among machorun's libSystem exports (measured;
// the same grep finds getprogname, readlink and getcwd). And `/proc/self/exe`
// is the WRONG ANSWER rather than an unavailable one: the ELF process is the
// LOADER, so that link names machorun, not the guest Mach-O mapped inside it.
// So the path comes from argv[0], resolved against getcwd when relative --
// which is what a launcher passes and what a bundled app would receive as its
// own path. `Bundle.main` reports how it was found so a caller can tell a real
// answer from a fallback.

import CPortableIO
import OpenUIKit

@MainActor
final class Bundle {
    enum Layout: CustomStringConvertible {
        case flat            // Foo.app/…            (iOS)
        case contents        // Foo.app/Contents/…   (macOS)
        var description: String { self == .flat ? "flat (iOS)" : "Contents (macOS)" }
    }

    /// Absolute path of the `.app` directory.
    let bundlePath: String
    let layout: Layout
    /// nil when Info.plist is missing or unreadable; `infoPlistError` says which.
    private(set) var infoDictionary: [String: PlistValue]?
    private(set) var infoPlistError: PlistError?

    /// `Foo.app/Contents/Resources` or `Foo.app`, per layout. Resources are
    /// looked up relative to this and nowhere else -- the point of the exercise.
    var resourcePath: String {
        layout == .contents ? bundlePath + "/Contents/Resources" : bundlePath
    }

    var infoPlistPath: String {
        layout == .contents ? bundlePath + "/Contents/Info.plist" : bundlePath + "/Info.plist"
    }

    init?(path: String) {
        // NOT `path.contains(".app/")`: String.contains has a RegexComponent
        // overload that lives in _StringProcessing, and referencing it makes the
        // guest demand libswift_StringProcessing.dylib at load -- which this
        // build deliberately does not have
        // (-disable-implicit-string-processing-module-import). Splitting on "/"
        // asks the same question with the stdlib alone.
        let components = path.split(separator: "/", omittingEmptySubsequences: false)
        guard path.hasSuffix(".app") || components.contains(where: { $0.hasSuffix(".app") })
        else { return nil }
        // Normalise to the .app directory itself.
        guard let appPath = Bundle.appComponent(of: path) else { return nil }
        bundlePath = appPath
        // A Contents/Info.plist decides the layout; that is the file the choice
        // is actually about, so read for it rather than for the directory.
        let contentsPlist = appPath + "/Contents/Info.plist"
        layout = ResourceIO.readFile(contentsPlist) != nil ? .contents : .flat
        loadInfoPlist()
    }

    private func loadInfoPlist() {
        guard let bytes = ResourceIO.readFile(infoPlistPath) else {
            infoPlistError = .missingFile(infoPlistPath)
            return
        }
        switch Plist.parse(bytes) {
        case .failure(let e): infoPlistError = e
        case .success(let v):
            guard let d = v.dictionaryValue else {
                infoPlistError = .malformed("Info.plist root is not a <dict>")
                return
            }
            infoDictionary = d
        }
    }

    // MARK: Info dictionary

    func object(forInfoDictionaryKey key: String) -> PlistValue? { infoDictionary?[key] }

    /// UIKit's `bundleIdentifier`.
    var bundleIdentifier: String? {
        object(forInfoDictionaryKey: "CFBundleIdentifier")?.stringValue
    }
    var executableName: String? {
        object(forInfoDictionaryKey: "CFBundleExecutable")?.stringValue
    }
    var bundleName: String? {
        object(forInfoDictionaryKey: "CFBundleName")?.stringValue
    }

    /// `Foo.app/Foo` or `Foo.app/Contents/MacOS/Foo`, from CFBundleExecutable.
    var executablePath: String? {
        guard let n = executableName else { return nil }
        return layout == .contents ? bundlePath + "/Contents/MacOS/" + n : bundlePath + "/" + n
    }

    // MARK: Resources

    /// UIKit's `path(forResource:ofType:)`. Returns a path only if the file is
    /// READABLE, which is what UIKit's contract is -- a path to a file that is
    /// not there would be worse than nil.
    func path(forResource name: String, ofType ext: String?) -> String? {
        let file = (ext?.isEmpty == false) ? "\(name).\(ext!)" : name
        let candidate = resourcePath + "/" + file
        return ResourceIO.readFile(candidate) != nil ? candidate : nil
    }

    // MARK: main

    enum MainSource: CustomStringConvertible {
        case argv0(String)
        case notBundled(String)
        var description: String {
            switch self {
            case .argv0(let p): return "argv[0] -> \(p)"
            case .notBundled(let p): return "executable is not inside a .app (\(p))"
            }
        }
    }

    private(set) static var mainSource: MainSource?

    /// UIKit's `Bundle.main`. NIL when the executable is not inside a `.app`,
    /// which is the truth for the scene renderer and is reported rather than
    /// papered over with a search-path fallback -- a Bundle that silently
    /// answers from somewhere else is the failure mode this piece exists to
    /// remove.
    static let main: Bundle? = {
        let argv0 = CommandLine.arguments.first ?? ""
        let abs = absolutePath(argv0)
        if let b = Bundle(path: abs) {
            mainSource = .argv0(abs)
            return b
        }
        mainSource = .notBundled(abs)
        return nil
    }()

    // MARK: Path helpers (string-only)

    /// The `…/Foo.app` prefix of a path, or nil.
    static func appComponent(of path: String) -> String? {
        var parts = path.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        while let last = parts.last {
            if last.hasSuffix(".app") { return parts.joined(separator: "/") }
            parts.removeLast()
            if parts.isEmpty { return nil }
        }
        return nil
    }

    static func absolutePath(_ p: String) -> String {
        if p.hasPrefix("/") { return p }
        var buf = [CChar](repeating: 0, count: 4096)
        let cwd = buf.withUnsafeMutableBufferPointer { b -> String in
            guard let r = getcwd(b.baseAddress, 4096) else { return "" }
            return String(cString: r)
        }
        let stripped = p.hasPrefix("./") ? String(p.dropFirst(2)) : p
        return cwd.isEmpty ? stripped : cwd + "/" + stripped
    }
}

@_silgen_name("getcwd")
private func getcwd(_ buf: UnsafeMutablePointer<CChar>?, _ size: Int) -> UnsafeMutablePointer<CChar>?
