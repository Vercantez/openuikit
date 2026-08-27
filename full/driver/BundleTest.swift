// BundleTest.swift -- Bundle and the plist reader, against REAL .app bundles.
//
// The fixtures are ~/uikit/Tools/oracle2's own probe apps, which exist for a
// different purpose entirely and were not shaped to fit this code. Both layouts
// are represented -- SheetProbe.app is flat (iOS), Oracle2.app has Contents/
// (macOS) -- so the layout branch is exercised by real data on both sides
// rather than by one real case and one invented one.

import CPortableIO
import OpenUIKit

private let oracleDir = "/uikit/Tools/oracle2"

@MainActor
func bundleSelfTest() -> Bool {
    var ok = true

    // ---- where does the executable path come from under machorun? ---------
    // Reported rather than asserted: this is the piece with no faithful API
    // available (_NSGetExecutablePath is not exported), so the answer belongs
    // in the output where it can be checked.
    // `Bundle.main` FIRST: mainSource is populated inside that lazy static, so
    // reading it beforehand reports "not resolved" for a question nobody has
    // asked yet. (It did, on the first run -- a diagnostic that described the
    // test's own ordering rather than the system.)
    let main = Bundle.main
    print("  main       : \(Bundle.mainSource.map(String.init(describing:)) ?? "not resolved")")
    if let m = main {
        // Running from inside a .app: report what it found, and check that a
        // resource actually resolves through the bundle.
        let id = m.bundleIdentifier ?? "nil"
        let res = m.path(forResource: "hello", ofType: "txt")
        let bundledOK = m.bundleIdentifier != nil && res != nil
        print("  bundled    : id=\(id)  layout=\(m.layout)  resource=\(res != nil ? "found" : "NOT FOUND")  "
            + (bundledOK ? "PASS" : "FAIL"))
        print("  bundled    : resourcePath=\(m.resourcePath)")
        if !bundledOK { ok = false }
    } else {
        // render_full run directly is NOT inside a .app, so nil is the RIGHT
        // answer. A Bundle that answered anyway would be the bug this piece
        // exists to prevent.
        print("  main       : nil -- correct, this executable is not inside a .app")
    }

    // ---- flat (iOS) layout, real fixture ----------------------------------
    guard let flat = Bundle(path: oracleDir + "/SheetProbe.app") else {
        print("  flat       : could not open SheetProbe.app  FAIL")
        return false
    }
    let flatOK = flat.layout == .flat
        && flat.bundleIdentifier == "com.openuikit.sheetprobe"
        && flat.executableName == "sheetprobe"
        && flat.bundleName == "SheetProbe"
    print("  flat       : layout=\(flat.layout)  id=\(flat.bundleIdentifier ?? "nil")"
        + "  exec=\(flat.executableName ?? "nil")  " + (flatOK ? "PASS" : "FAIL"))
    if !flatOK { ok = false }

    // Nested values: the fixture has <array><string>…</string></array> and
    // <array><integer>1</integer></array>, which is where a parser that only
    // handles flat dicts falls over.
    let platforms = flat.object(forInfoDictionaryKey: "CFBundleSupportedPlatforms")?
        .arrayValue?.compactMap { $0.stringValue } ?? []
    let family = flat.object(forInfoDictionaryKey: "UIDeviceFamily")?
        .arrayValue?.compactMap { $0.intValue } ?? []
    // <dict/> self-closing, which is a separate branch from <dict></dict>.
    let launchScreen = flat.object(forInfoDictionaryKey: "UILaunchScreen")?.dictionaryValue
    let nestedOK = platforms == ["iPhoneSimulator"] && family == [1] && launchScreen?.isEmpty == true
    print("  nested     : platforms=\(platforms)  UIDeviceFamily=\(family)"
        + "  UILaunchScreen=\(launchScreen.map { "<dict/> \($0.count) keys" } ?? "nil")  "
        + (nestedOK ? "PASS" : "FAIL"))
    if !nestedOK { ok = false }

    // The executable named by CFBundleExecutable must actually be there --
    // that is the whole point of a bundle being self-describing.
    let execPath = flat.executablePath
    let execThere = execPath.map { ResourceIO.readFile($0) != nil } ?? false
    print("  exec path  : \(execPath ?? "nil") -> \(execThere ? "present" : "MISSING")  "
        + (execThere ? "PASS" : "FAIL"))
    if !execThere { ok = false }

    // ---- Contents (macOS) layout, real fixture ----------------------------
    guard let contents = Bundle(path: oracleDir + "/Oracle2.app") else {
        print("  contents   : could not open Oracle2.app  FAIL")
        return false
    }
    let contentsOK = contents.layout == .contents
        && contents.infoDictionary != nil
        && contents.infoPlistPath.hasSuffix("/Contents/Info.plist")
    print("  contents   : layout=\(contents.layout)  keys=\(contents.infoDictionary?.count ?? 0)"
        + "  plist=\(contents.infoPlistPath.hasSuffix("/Contents/Info.plist") ? "Contents/Info.plist" : "WRONG")  "
        + (contentsOK ? "PASS" : "FAIL"))
    if !contentsOK { ok = false }

    // The two layouts must resolve resources to DIFFERENT places; if they did
    // not, the layout branch would be decorative.
    let differ = flat.resourcePath != contents.resourcePath
        && contents.resourcePath.hasSuffix("/Contents/Resources")
        && flat.resourcePath.hasSuffix(".app")
    print("  resources  : flat=\(flat.resourcePath.suffix(24))  contents=\(contents.resourcePath.suffix(24))  "
        + (differ ? "PASS" : "FAIL"))
    if !differ { ok = false }

    // ---- path(forResource:) is readability, not string-building -----------
    let missing = flat.path(forResource: "NoSuchResource", ofType: "png")
    let found = flat.path(forResource: "Info", ofType: "plist")
    let lookupOK = missing == nil && found != nil
    print("  lookup     : absent->\(missing == nil ? "nil" : "NON-NIL")"
        + "  present->\(found != nil ? "path" : "NIL")  " + (lookupOK ? "PASS" : "FAIL"))
    if !lookupOK { ok = false }

    ok = absentKeyBehaviour(flat: flat) && ok
    ok = plistTeeth() && ok
    return ok
}

/// WHAT A REAL APP HITS FIRST IS AN ABSENT KEY, NOT A MALFORMED FILE.
///
/// Three situations a careless implementation collapses into one bare nil, and
/// which must stay distinguishable to a caller:
///   1. the plist parsed, the key is simply not in it  -> nil, and NO error
///   2. there is no Info.plist at all                  -> nil, error NAMES the path
///   3. the plist is present and unparseable           -> nil, error names the reason
///
/// Collapsing 2 into 1 is what makes a MISCONFIGURED app look like a merely
/// incomplete one -- an absence that reads as a legitimate answer, which is the
/// shape this project keeps finding.
@MainActor
func absentKeyBehaviour(flat: Bundle) -> Bool {
    var ok = true
    let fixtures = cpio_getenv("BUNDLE_FIXTURE_DIR").map { String(cString: $0) } ?? "/w/build/full"

    // ---- 1. key absent from a perfectly good plist ------------------------
    let absent = flat.object(forInfoDictionaryKey: "NoSuchKeyWhatsoever")
    let present = flat.object(forInfoDictionaryKey: "CFBundleIdentifier")
    let case1 = absent == nil && present != nil
        && flat.infoDictionary != nil && flat.infoPlistError == nil
    print("  absent key : missing->\(absent == nil ? "nil" : "NON-NIL")"
        + "  present->\(present != nil ? "value" : "NIL")"
        + "  error=\(flat.infoPlistError == nil ? "none (correct)" : "SET")  "
        + (case1 ? "PASS" : "FAIL"))
    if !case1 { ok = false }

    // Typed accessors over absent keys must be nil, not "" -- and executablePath
    // must decline to build a path from a name that is not there.
    if let noKeys = Bundle(path: fixtures + "/NoKeys.app") {
        let case1b = noKeys.infoDictionary != nil && noKeys.infoPlistError == nil
            && noKeys.bundleIdentifier == nil && noKeys.executableName == nil
            && noKeys.executablePath == nil
        print("  absent key : valid plist with no CFBundle* keys -> id=\(noKeys.bundleIdentifier ?? "nil")"
            + " exec=\(noKeys.executableName ?? "nil") execPath=\(noKeys.executablePath ?? "nil")  "
            + (case1b ? "PASS" : "FAIL"))
        if !case1b { ok = false }
    } else {
        print("  absent key : NoKeys.app fixture missing under \(fixtures)  FAIL")
        ok = false
    }

    // ---- 2. no Info.plist at all ------------------------------------------
    // A directory named Foo.app IS a bundle whose plist is missing, which is a
    // different thing from "not a bundle" -- so it must still open.
    guard let empty = Bundle(path: fixtures + "/Empty.app") else {
        print("  no plist   : Empty.app fixture missing under \(fixtures)  FAIL")
        return false
    }
    let case2 = empty.infoDictionary == nil && empty.infoPlistError != nil
        && empty.object(forInfoDictionaryKey: "CFBundleIdentifier") == nil
        && empty.bundleIdentifier == nil
    print("  no plist   : bundle opens=yes  infoDictionary=nil"
        + "  error=\(empty.infoPlistError.map { "\($0)" } ?? "NONE -- silent")  "
        + (case2 ? "PASS" : "FAIL"))
    if !case2 { ok = false }

    // ---- the distinction itself -------------------------------------------
    // If absent-key and absent-file both produced a bare nil with no error they
    // would be indistinguishable to a caller, and everything above would be
    // checking nothing.
    let distinguishable = flat.infoPlistError == nil && empty.infoPlistError != nil
    print("  distinct   : absent-key vs absent-file are distinguishable  "
        + (distinguishable ? "PASS" : "FAIL -- both look identical to a caller"))
    if !distinguishable { ok = false }

    return ok
}

/// The parser must FAIL on the things it cannot do, and say which.
/// A reader that returns an empty dictionary for a binary plist would make
/// every key lookup silently nil -- an app would look misconfigured rather
/// than unsupported.
@MainActor
func plistTeeth() -> Bool {
    var ok = true

    // Binary plists are the named gap. Detected by magic and reported as such.
    let bplist: [UInt8] = Array("bplist00".utf8) + [0x00, 0x01, 0x02]
    var binaryNamed = false
    if case .failure(let e) = Plist.parse(bplist), case .binaryFormat = e { binaryNamed = true }
    print("  teeth      : binary plist -> \(binaryNamed ? "named as unsupported  PASS" : "NOT DETECTED  FAIL")")
    if !binaryNamed { ok = false }

    // Malformed XML must not parse to an empty dictionary.
    let junk: [UInt8] = Array("<plist version=\"1.0\"><dict><key>a</key></dict></plist>".utf8)
    var malformedNamed = false
    if case .failure = Plist.parse(junk) { malformedNamed = true }
    print("  teeth      : <key> with no value -> \(malformedNamed ? "rejected  PASS" : "ACCEPTED  FAIL")")
    if !malformedNamed { ok = false }

    // And the positive control: the parser must accept what it claims to.
    // Without this, "rejects everything" would score full marks above.
    let good: [UInt8] = Array("""
        <?xml version="1.0"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/x.dtd">
        <plist version="1.0"><dict>
          <!-- a comment, which the oracle2 fixtures really do contain -->
          <key>s</key><string>hi &amp; bye</string>
          <key>n</key><integer>-7</integer>
          <key>b</key><true/>
          <key>a</key><array><string>x</string><integer>2</integer></array>
        </dict></plist>
        """.utf8)
    var positive = false
    if case .success(let v) = Plist.parse(good), let d = v.dictionaryValue {
        positive = d["s"]?.stringValue == "hi & bye"
            && d["n"]?.intValue == -7
            && d["b"]?.boolValue == true
            && d["a"]?.arrayValue?.count == 2
    }
    print("  teeth      : well-formed (entities, comment, DOCTYPE, nesting) -> "
        + (positive ? "parsed correctly  PASS" : "FAILED  FAIL"))
    if !positive { ok = false }

    return ok
}
