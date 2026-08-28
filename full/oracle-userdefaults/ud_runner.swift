//===----------------------------------------------------------------------===//
// UserDefaults differential oracle — host route.
//
// Grades the PORT (`PortedUserDefaults.UserDefaults`, from
// ~/foundation-macho/src/overlay/UserDefaults.swift) against REAL
// `Foundation.UserDefaults`, in ONE PROCESS, over the SAME CoreFoundation.
//
// WHY ONE PROCESS AND THE SAME CF. The only variable that must differ is our
// Swift layer. Both sides call the identical `CFPreferences*` entry points in
// the identical `cfprefsd`-backed store, so a mismatch cannot be blamed on a
// different preferences implementation underneath — it is ours. That isolates
// exactly the half this phase is grading. It does NOT exercise corelibs' CF;
// that is a separate measurement and is reported separately.
//
// THREE SCOREBOARDS, and the middle one is the point:
//
//   CONTROL-SELF  real vs real, same rows, two suites. MUST be 100%. If it is
//                 not, the harness is broken and no other number means
//                 anything. This is the instrument check.
//
//   CORELIBS      swift-corelibs-foundation's OWN rules — NSString.integerValue
//                 / .boolValue / .doubleValue, which is literally what
//                 upstream's UserDefaults calls — scored against real
//                 Foundation. This MUST FAIL, and the count of failures is the
//                 pre-registered deviation set. It is what a straight port
//                 would have scored.
//
//   PORT          our implementation against real Foundation. MUST be 100% on
//                 every row CORELIBS fails, or the corrections do not work.
//
// A run where CONTROL-SELF is not perfect, or where CORELIBS passes, is a
// broken measurement and says so rather than printing a scoreboard.
//
// Usage:
//   ud_runner score           write + read + score in one process (default)
//   ud_runner persist-write   write a known set, then exit
//   ud_runner persist-read    re-read it in a FRESH process and score
//   ud_runner clean           remove every suite this runner uses
//===----------------------------------------------------------------------===//

import Foundation
import PortedUserDefaults

typealias PortedDefaults = PortedUserDefaults.UserDefaults
typealias RealDefaults = Foundation.UserDefaults

// MARK: - Suites. Distinct per side so writes never collide.

let SUITE_REAL = "com.example.udoracle.real"
let SUITE_PORT = "com.example.udoracle.port"
let SUITE_SELF = "com.example.udoracle.self"   // CONTROL-SELF's second suite
let SUITE_XREAD = "com.example.udoracle.xread" // ported writes, real reads
let SUITE_PERSIST = "com.example.udoracle.persist"
let ALL_SUITES = [SUITE_REAL, SUITE_PORT, SUITE_SELF, SUITE_XREAD, SUITE_PERSIST]

// MARK: - Canonical rendering
//
// ONE renderer for both sides, into a type-tagged string. Comparing canonical
// strings rather than `Any` is what makes "did we get the same answer" a
// decidable question.
//
// THE ORDER HERE IS LOAD-BEARING, AND AN EARLIER VERSION GOT IT WRONG IN A WAY
// WORTH KEEPING ON THE RECORD. It tested `v is Bool` first, which is correct
// for a Swift value and WRONG for a bridged one: an `NSNumber` holding 1
// satisfies `is Bool`, while one holding 2 does not. So real Foundation's
// `[1, 2, 3]` rendered as `[Bool(true), Int(2), Int(3)]` — folding `1` into
// `true` for the first element only — and the port was marked FAILING on four
// rows where it was right and the instrument was wrong. Exactly the NSNumber
// folding hazard the port's own comments call out, landing in the thing
// measuring it.
//
// `CFGetTypeID` is authoritative and bridging is not, so ask it FIRST. This
// also works for Swift-native values: `true as NSObject` is `__NSCFBoolean`
// and `1 as NSObject` is `__NSCFNumber`, so one path serves both sides and
// there is no asymmetry left to get wrong.
//
// A single shared renderer can, however, fail SYMMETRICALLY — map everything
// to one tag and every comparison passes. `renderDiscriminates()` below is the
// check for that, and it runs before any scoreboard.

func render(_ v: Any?) -> String {
    guard let v = v else { return "nil" }
    if let o = v as? NSObject {
        let id = CFGetTypeID(o as CFTypeRef)
        if id == CFBooleanGetTypeID() {
            return "Bool(\(CFBooleanGetValue((o as! CFBoolean))))"
        }
        if id == CFNumberGetTypeID(), let n = v as? NSNumber {
            switch CFNumberGetType((n as CFNumber)) {
            case .float32Type, .float64Type, .floatType, .doubleType, .cgFloatType:
                return "Double(\(canonDouble(n.doubleValue)))"
            default:
                return "Int(\(n.intValue))"
            }
        }
    }
    // Swift-native values that did not bridge to an NSObject.
    if let b = v as? Bool { return "Bool(\(b))" }
    if let i = v as? Int { return "Int(\(i))" }
    if let d = v as? Double { return "Double(\(canonDouble(d)))" }
    switch v {
    case let s as String: return "String(\(s))"
    case let d as Data:   return "Data(\(d.map { String(format: "%02x", $0) }.joined()))"
    case let d as Date:   return "Date(\(canonDouble(d.timeIntervalSince1970)))"
    case let a as [Any]:
        return "[" + a.map { render($0) }.joined(separator: ",") + "]"
    case let d as [String: Any]:
        return "{" + d.keys.sorted().map { "\($0)=\(render(d[$0]!))" }.joined(separator: ",") + "}"
    default:
        return "OTHER(\(type(of: v)))"
    }
}

func renderReal(_ v: Any?) -> String { render(v) }
func renderPorted(_ v: Any?) -> String { render(v) }

func canonDouble(_ d: Double) -> String { String(format: "%0.17g", d) }

/// INSTRUMENT CHECK. A renderer that folds distinct values together makes every
/// comparison pass, and no scoreboard built on it detects anything. These pairs
/// must all render differently; the `true` vs `1` pair is the one that actually
/// broke, and `1` vs `1.0` is the one that would break next.
func renderDiscriminates() -> [String] {
    var problems: [String] = []
    func distinct(_ a: Any, _ b: Any, _ label: String) {
        if render(a) == render(b) {
            problems.append("\(label): both render as \(render(a))")
        }
    }
    distinct(true, 1, "Bool(true) vs Int(1)")
    distinct(false, 0, "Bool(false) vs Int(0)")
    distinct(1, 1.0, "Int(1) vs Double(1.0)")
    distinct(1, "1", "Int(1) vs String(1)")
    distinct(true, "true", "Bool(true) vs String(true)")
    distinct([1], ["1"], "[Int] vs [String]")
    distinct([1, 2, 3] as [Any], [true, 2, 3] as [Any], "[1,2,3] vs [true,2,3]")
    distinct(Data([0]), Data([1]), "Data(00) vs Data(01)")
    distinct(Date(timeIntervalSince1970: 0), Date(timeIntervalSince1970: 1), "two Dates")
    distinct(["a": 1] as [String: Any], ["a": true] as [String: Any], "{a:1} vs {a:true}")
    // and the nested case that actually failed, through an NSArray round-trip
    let bridged = ([1, 2, 3] as [Any]) as NSArray as Any
    if render(bridged) != render([1, 2, 3] as [Any]) {
        problems.append("bridged NSArray [1,2,3] renders as \(render(bridged)), "
                      + "native renders as \(render([1, 2, 3] as [Any]))")
    }
    return problems
}

// MARK: - Scoreboard

struct Board {
    let name: String
    var pass = 0, fail = 0
    var failures: [(row: String, expected: String, got: String)] = []
    /// EVERY row, passing or failing, with the answer REAL Foundation gave.
    /// This is what `ud_runner golden` emits, and it is the only reason the
    /// GUEST route can be graded at all: the guest runs on Linux under
    /// machorun with no real Foundation to ask, so its expectations have to
    /// come from here. Recording it inside `check` rather than rebuilding the
    /// table separately is deliberate -- a second construction of the same
    /// expectations would be a SECOND AUTHORITY, and a transcription slip in
    /// it would surface as a port failure, or worse, mask a real one.
    var all: [(row: String, expected: String)] = []
    mutating func check(_ row: String, expected: String, got: String) {
        all.append((row, expected))
        if expected == got { pass += 1 }
        else { fail += 1; failures.append((row, expected, got)) }
    }
    var scored: Int { pass + fail }
    func report(showAll: Bool = false) {
        print("\n\(name): scored \(scored) · pass \(pass) · fail \(fail)")
        if !failures.isEmpty {
            let show = showAll ? failures : Array(failures.prefix(25))
            for f in show {
                print("    \(f.row.padding(toLength: 42, withPad: " ", startingAt: 0))"
                    + "expected \(f.expected)   got \(f.got)")
            }
            if !showAll && failures.count > show.count {
                print("    … \(failures.count - show.count) more")
            }
        }
    }
}

// MARK: - corelibs' OWN rules, transcribed from its source
//
// swift-corelibs-foundation Sources/Foundation/UserDefaults.swift:193-279 does
// exactly this: for a String value it calls NSString(string:).integerValue,
// .boolValue, .doubleValue. Reproduced here so the CORELIBS scoreboard is
// upstream's real behaviour, not a caricature of it.

func corelibsInteger(_ v: Any?) -> Int {
    guard let v = v else { return 0 }
    if let b = v as? Bool { return NSNumber(value: b).intValue }
    if let i = v as? Int { return i }
    if let f = v as? Float { return NSNumber(value: f).intValue }
    if let d = v as? Double { return NSNumber(value: d).intValue }
    if let s = v as? String { return NSString(string: s).integerValue }
    return 0
}
func corelibsBool(_ v: Any?) -> Bool {
    guard let v = v else { return false }
    if let b = v as? Bool { return b }
    if let i = v as? Int { return i != 0 }
    if let f = v as? Float { return f != 0 }
    if let d = v as? Double { return d != 0 }
    if let s = v as? String { return NSString(string: s).boolValue }
    return false
}
func corelibsDouble(_ v: Any?) -> Double {
    guard let v = v else { return 0 }
    if let b = v as? Bool { return NSNumber(value: b).doubleValue }
    if let d = v as? Double { return d }
    if let i = v as? Int { return NSNumber(value: i).doubleValue }
    if let f = v as? Float { return NSNumber(value: f).doubleValue }
    if let s = v as? String { return NSString(string: s).doubleValue }
    return 0
}

// MARK: - The corpus of stored values
//
// Strings are the 42 rows from darwin-coercion-2026-08-27.txt plus the
// boundary rows from darwin-rules-2026-08-27.txt, because that is where the
// divergence lives. Non-string values cover the plist type set.

let CORPUS_STRINGS = [
    "123", "0123", " 123", "123 ", "12.9", "3.75", "-7", "+7",
    "0", "1", "2", "-1", "0.0", "1.0", "1e3", "0x10",
    "YES", "Yes", "yes", "Y", "y", "TRUE", "True", "true", "T", "t",
    "NO", "no", "N", "n", "FALSE", "false", "F", "f",
    "banana", "", " ", "1banana", "banana1",
    "9223372036854775807", "9223372036854775808", "-0",
    // boundary rows from RULES
    "2147483647", "2147483648", "3000000000", "-2147483648", "-2147483649",
    "-3000000000", "\t123", "123\t", "  -7", "- 7", "--7", "+ 7", "007",
    "2147483647x", "+", "-", "+0", "1_000",
    " 1", "1 ", "01", "+1", "yEs", "YeS", "tRuE", "truex", "yess", "yes ",
    " yes", "00", " 0", "true1",
    "1E3", "0X10", ".5", "5.", "1e", "inf", "INF", "nan", "-inf", "1e400",
    "0.1", "1,5", "3.14159265358979",
]

/// Keys harvested from the pinned 20-app corpus (userdefaults-census JSON),
/// so the oracle's key space is the apps' own and not invented.
let CORPUS_KEYS = [
    "linkBrowserMode", "favoriteUrl", "safariReaderMode", "ShowThumbnails",
    "Shortcuts", "DimReadPosts", "SwipeToCollapseThreads",
    "ShowNextCommentButton", "LastFeedCategory", "TG_preferredVideoPreset_v0",
    "hn_username", "extra_debug", "LastActiveTimestamp", "openInBrowser",
    "periodicUpdateInterval", "RememberFeedCategory", "textSize",
    "compactFeedDesign", "isOnboardingCompleted", "currentAppVariant",
    "fxa.cwts.declinedSyncEngines", "prefKeySystemThemeSwitchOnOff",
    "com.apple.configuration.managed", "restoreLastURL", "NOTIFICATION_DATA",
    "screenAwakeMode",
]

enum V {
    case s(String), i(Int), d(Double), f(Float), b(Bool)
    case data(Data), date(Date), arr([Any]), dict([String: Any])
    var label: String {
        switch self {
        case .s(let x):  return "String(\(x))"
        case .i(let x):  return "Int(\(x))"
        case .d(let x):  return "Double(\(x))"
        case .f(let x):  return "Float(\(x))"
        case .b(let x):  return "Bool(\(x))"
        case .data:      return "Data"
        case .date:      return "Date"
        case .arr:       return "Array"
        case .dict:      return "Dict"
        }
    }
}

let CORPUS_VALUES: [(String, V)] = [
    ("v_string", .s("hello")),
    ("v_empty", .s("")),
    ("v_int", .i(42)), ("v_int_zero", .i(0)), ("v_int_one", .i(1)),
    ("v_int_neg", .i(-1)), ("v_int_max", .i(Int.max)), ("v_int_min", .i(Int.min)),
    ("v_int_big", .i(1 << 40)),
    ("v_double", .d(3.5)), ("v_double_whole", .d(1.0)), ("v_double_frac", .d(0.1)),
    ("v_double_neg", .d(-2.9)), ("v_double_pi", .d(Double.pi)),
    ("v_float", .f(1.5)),
    ("v_bool_true", .b(true)), ("v_bool_false", .b(false)),
    ("v_data", .data(Data([0xde, 0xad, 0xbe, 0xef]))),
    ("v_data_empty", .data(Data())),
    ("v_date", .date(Date(timeIntervalSince1970: 1000))),
    ("v_arr_int", .arr([1, 2, 3])),
    ("v_arr_str", .arr(["a", "b"])),
    ("v_arr_mixed", .arr(["a", 1, "b"])),
    ("v_arr_empty", .arr([])),
    ("v_dict", .dict(["x": 1, "y": "two"])),
    ("v_dict_nested", .dict(["nested": ["deep": [1, 2]]])),
]

func writeReal(_ d: RealDefaults, _ k: String, _ v: V) {
    switch v {
    case .s(let x): d.set(x, forKey: k)
    case .i(let x): d.set(x, forKey: k)
    case .d(let x): d.set(x, forKey: k)
    case .f(let x): d.set(x, forKey: k)
    case .b(let x): d.set(x, forKey: k)
    case .data(let x): d.set(x, forKey: k)
    case .date(let x): d.set(x, forKey: k)
    case .arr(let x): d.set(x, forKey: k)
    case .dict(let x): d.set(x, forKey: k)
    }
}
func writePorted(_ d: PortedDefaults, _ k: String, _ v: V) {
    switch v {
    case .s(let x): d.set(x, forKey: k)
    case .i(let x): d.set(x, forKey: k)
    case .d(let x): d.set(x, forKey: k)
    case .f(let x): d.set(x, forKey: k)
    case .b(let x): d.set(x, forKey: k)
    case .data(let x): d.set(x, forKey: k)
    case .date(let x): d.set(x, forKey: k)
    case .arr(let x): d.set(x, forKey: k)
    case .dict(let x): d.set(x, forKey: k)
    }
}

// MARK: - Cleanup

func clean() {
    for s in ALL_SUITES {
        RealDefaults(suiteName: s)?.removePersistentDomain(forName: s)
        let home = FileManager.default.homeDirectoryForCurrentUser
        try? FileManager.default.removeItem(
            at: home.appendingPathComponent("Library/Preferences/\(s).plist"))
    }
}

// MARK: - Modes

let mode = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "score"

if mode == "clean" {
    clean(); print("cleaned \(ALL_SUITES.count) suites"); exit(0)
}

if mode == "persist-write" {
    clean()
    let p = PortedDefaults(suiteName: SUITE_PERSIST)!
    for (k, v) in CORPUS_VALUES { writePorted(p, k, v) }
    for (i, s) in CORPUS_STRINGS.enumerated() { p.set(s, forKey: "s\(i)") }
    _ = p.synchronize()
    print("persist-write: wrote \(CORPUS_VALUES.count + CORPUS_STRINGS.count) "
        + "keys through the PORT into \(SUITE_PERSIST), synchronised, exiting.")
    exit(0)
}

if mode == "persist-read" {
    // A FRESH PROCESS. This is the only honest persistence test: nothing this
    // process wrote is in memory, so every value has to have come back from
    // the store.
    var b = Board(name: "PERSIST (fresh process; port wrote, both read)")
    let p = PortedDefaults(suiteName: SUITE_PERSIST)!
    let r = RealDefaults(suiteName: SUITE_PERSIST)!
    for (k, v) in CORPUS_VALUES {
        b.check("persist \(k) [\(v.label)]",
                expected: renderReal(r.object(forKey: k)),
                got: renderPorted(p.object(forKey: k)))
    }
    for (i, s) in CORPUS_STRINGS.enumerated() {
        b.check("persist s\(i) [\(s)]",
                expected: renderReal(r.object(forKey: "s\(i)")),
                got: renderPorted(p.object(forKey: "s\(i)")))
    }
    b.report()
    // TOOTH: if nothing survived, every row would be nil==nil and PASS. Assert
    // that a known value is actually THERE, so an empty store cannot score 100%.
    let sentinel = p.object(forKey: "v_string")
    print("\n  TOOTH — a value must actually be present, or an empty store scores 100%:")
    print("    v_string after restart = \(renderPorted(sentinel))")
    if sentinel == nil {
        print("    *** NOTHING PERSISTED. The scoreboard above is vacuous. ***")
        exit(1)
    }
    exit(b.fail == 0 ? 0 : 1)
}

// MARK: - score

clean()

print("=== UserDefaults differential oracle — HOST ROUTE ===")
print("port:  PortedUserDefaults.UserDefaults  (foundation-macho/src/overlay/UserDefaults.swift)")
print("real:  Foundation.UserDefaults          (macOS \(ProcessInfo.processInfo.operatingSystemVersionString))")
print("both drive the SAME system CFPreferences; only the Swift layer differs.\n")

// INSTRUMENT CHECK, before anything is scored. A renderer that cannot tell two
// values apart makes every board perfect and detects nothing.
let renderProblems = renderDiscriminates()
if renderProblems.isEmpty {
    print("instrument: the renderer discriminates all 11 control pairs "
        + "(incl. Bool(true) vs Int(1), which it once folded).")
} else {
    print("*** INSTRUMENT BROKEN — the renderer folds distinct values: ***")
    for p in renderProblems { print("      \(p)") }
    print("*** No scoreboard below would mean anything. Aborting. ***")
    exit(4)
}

let real = RealDefaults(suiteName: SUITE_REAL)!
let port = PortedDefaults(suiteName: SUITE_PORT)!
let selfB = RealDefaults(suiteName: SUITE_SELF)!

// Seed all three identically.
for (k, v) in CORPUS_VALUES {
    writeReal(real, k, v); writePorted(port, k, v); writeReal(selfB, k, v)
}
for (i, s) in CORPUS_STRINGS.enumerated() {
    real.set(s, forKey: "s\(i)"); port.set(s, forKey: "s\(i)"); selfB.set(s, forKey: "s\(i)")
}
_ = real.synchronize(); _ = port.synchronize(); _ = selfB.synchronize()

var control = Board(name: "CONTROL-SELF  (real vs real — instrument check, must be 100%)")
var corelibs = Board(name: "CORELIBS      (upstream's own rules vs real — MUST FAIL)")
var portB = Board(name: "PORT          (ours vs real)")

// ---- 1. round-trip of every stored type
for (k, v) in CORPUS_VALUES {
    let exp = renderReal(real.object(forKey: k))
    control.check("roundtrip \(k) [\(v.label)]", expected: exp,
                  got: renderReal(selfB.object(forKey: k)))
    portB.check("roundtrip \(k) [\(v.label)]", expected: exp,
                got: renderPorted(port.object(forKey: k)))
}

// ---- 2. the coercion grid over every stored string
for (i, s) in CORPUS_STRINGS.enumerated() {
    let k = "s\(i)"
    let disp = s.replacingOccurrences(of: "\n", with: "\\n")
                .replacingOccurrences(of: "\t", with: "\\t")

    let eI = String(real.integer(forKey: k))
    let eD = canonDouble(real.double(forKey: k))
    let eB = String(real.bool(forKey: k))
    let eS = real.string(forKey: k) ?? "nil"

    control.check("integer(\"\(disp)\")", expected: eI, got: String(selfB.integer(forKey: k)))
    control.check("double(\"\(disp)\")", expected: eD, got: canonDouble(selfB.double(forKey: k)))
    control.check("bool(\"\(disp)\")", expected: eB, got: String(selfB.bool(forKey: k)))
    control.check("string(\"\(disp)\")", expected: eS, got: selfB.string(forKey: k) ?? "nil")

    portB.check("integer(\"\(disp)\")", expected: eI, got: String(port.integer(forKey: k)))
    portB.check("double(\"\(disp)\")", expected: eD, got: canonDouble(port.double(forKey: k)))
    portB.check("bool(\"\(disp)\")", expected: eB, got: String(port.bool(forKey: k)))
    portB.check("string(\"\(disp)\")", expected: eS, got: port.string(forKey: k) ?? "nil")

    corelibs.check("integer(\"\(disp)\")", expected: eI, got: String(corelibsInteger(s)))
    corelibs.check("double(\"\(disp)\")", expected: eD, got: canonDouble(corelibsDouble(s)))
    corelibs.check("bool(\"\(disp)\")", expected: eB, got: String(corelibsBool(s)))
}

// ---- 3. coercion over every stored NON-string type
for (k, v) in CORPUS_VALUES {
    let eI = String(real.integer(forKey: k))
    let eD = canonDouble(real.double(forKey: k))
    let eB = String(real.bool(forKey: k))
    let eS = real.string(forKey: k) ?? "nil"
    let eA = real.array(forKey: k) != nil
    let eDi = real.dictionary(forKey: k) != nil
    let eDa = real.data(forKey: k) != nil
    let eSA = real.stringArray(forKey: k).map { $0.joined(separator: "|") } ?? "nil"
    let eF = String(real.float(forKey: k))

    control.check("integer \(k)", expected: eI, got: String(selfB.integer(forKey: k)))
    control.check("bool \(k)", expected: eB, got: String(selfB.bool(forKey: k)))
    control.check("string \(k)", expected: eS, got: selfB.string(forKey: k) ?? "nil")

    portB.check("integer \(k) [\(v.label)]", expected: eI, got: String(port.integer(forKey: k)))
    portB.check("double \(k) [\(v.label)]", expected: eD, got: canonDouble(port.double(forKey: k)))
    portB.check("float \(k) [\(v.label)]", expected: eF, got: String(port.float(forKey: k)))
    portB.check("bool \(k) [\(v.label)]", expected: eB, got: String(port.bool(forKey: k)))
    portB.check("string \(k) [\(v.label)]", expected: eS, got: port.string(forKey: k) ?? "nil")
    portB.check("array? \(k)", expected: String(eA), got: String(port.array(forKey: k) != nil))
    portB.check("dict? \(k)", expected: String(eDi), got: String(port.dictionary(forKey: k) != nil))
    portB.check("data? \(k)", expected: String(eDa), got: String(port.data(forKey: k) != nil))
    portB.check("stringArray \(k)", expected: eSA,
                got: port.stringArray(forKey: k).map { $0.joined(separator: "|") } ?? "nil")

    // corelibs' getters see the same Swift value; only the string path differs,
    // so non-string rows are where corelibs is EXPECTED to agree. Scoring them
    // keeps the CORELIBS board from being a rigged subset.
    let sv = port.object(forKey: k)
    corelibs.check("integer \(k)", expected: eI, got: String(corelibsInteger(sv)))
    corelibs.check("bool \(k)", expected: eB, got: String(corelibsBool(sv)))
}

// ---- 4. absent keys — absence is an answer
for g in ["object", "string", "integer", "double", "float", "bool", "array",
          "data", "stringArray", "dictionary"] {
    let k = "definitely_absent_key"
    func realAns() -> String {
        switch g {
        case "object": return renderReal(real.object(forKey: k))
        case "string": return real.string(forKey: k) ?? "nil"
        case "integer": return String(real.integer(forKey: k))
        case "double": return canonDouble(real.double(forKey: k))
        case "float": return String(real.float(forKey: k))
        case "bool": return String(real.bool(forKey: k))
        case "array": return real.array(forKey: k) == nil ? "nil" : "some"
        case "data": return real.data(forKey: k) == nil ? "nil" : "some"
        case "stringArray": return real.stringArray(forKey: k) == nil ? "nil" : "some"
        default: return real.dictionary(forKey: k) == nil ? "nil" : "some"
        }
    }
    func portAns() -> String {
        switch g {
        case "object": return renderPorted(port.object(forKey: k))
        case "string": return port.string(forKey: k) ?? "nil"
        case "integer": return String(port.integer(forKey: k))
        case "double": return canonDouble(port.double(forKey: k))
        case "float": return String(port.float(forKey: k))
        case "bool": return String(port.bool(forKey: k))
        case "array": return port.array(forKey: k) == nil ? "nil" : "some"
        case "data": return port.data(forKey: k) == nil ? "nil" : "some"
        case "stringArray": return port.stringArray(forKey: k) == nil ? "nil" : "some"
        default: return port.dictionary(forKey: k) == nil ? "nil" : "some"
        }
    }
    portB.check("absent \(g)(forKey:)", expected: realAns(), got: portAns())
    control.check("absent \(g)(forKey:)", expected: realAns(), got: realAns())
}

// ---- 5. register(defaults:) layering and removeObject fallback
real.register(defaults: ["reg_only": "from-register", "v_string": "reg-LOSES", "reg_int": 7])
port.register(defaults: ["reg_only": "from-register", "v_string": "reg-LOSES", "reg_int": 7])
portB.check("register: unset key reads the registered value",
            expected: renderReal(real.object(forKey: "reg_only")),
            got: renderPorted(port.object(forKey: "reg_only")))
portB.check("register: a SET key beats the registered one",
            expected: renderReal(real.object(forKey: "v_string")),
            got: renderPorted(port.object(forKey: "v_string")))
portB.check("register: typed getter sees it",
            expected: String(real.integer(forKey: "reg_int")),
            got: String(port.integer(forKey: "reg_int")))
real.set("set-value", forKey: "reg_only"); port.set("set-value", forKey: "reg_only")
portB.check("register: after set",
            expected: renderReal(real.object(forKey: "reg_only")),
            got: renderPorted(port.object(forKey: "reg_only")))
real.removeObject(forKey: "reg_only"); port.removeObject(forKey: "reg_only")
portB.check("register: removeObject FALLS BACK to registered",
            expected: renderReal(real.object(forKey: "reg_only")),
            got: renderPorted(port.object(forKey: "reg_only")))
portB.check("register: NOT in persistentDomain",
            expected: String(real.persistentDomain(forName: SUITE_REAL)?["reg_only"] == nil),
            got: String(port.persistentDomain(forName: SUITE_PORT)?["reg_only"] == nil))

// ---- 6. set(nil) is removeObject
real.set("x", forKey: "nilme"); port.set("x", forKey: "nilme")
real.set(nil, forKey: "nilme"); port.set(nil, forKey: "nilme")
portB.check("set(nil) removes",
            expected: renderReal(real.object(forKey: "nilme")),
            got: renderPorted(port.object(forKey: "nilme")))

// ---- 7. suite isolation
let realOther = RealDefaults(suiteName: SUITE_XREAD)!
let portOther = PortedDefaults(suiteName: SUITE_XREAD)!
realOther.set("other", forKey: "iso")
portB.check("suite isolation: other suite's key is not in this one",
            expected: renderReal(real.object(forKey: "iso")),
            got: renderPorted(port.object(forKey: "iso")))
portB.check("suite isolation: same suite, both sides see it",
            expected: renderReal(realOther.object(forKey: "iso")),
            got: renderPorted(portOther.object(forKey: "iso")))

// ---- 8. CROSS-READ: the port WRITES, real Foundation READS.
//
// The strongest test of the setters: it is not enough that we can read back
// what we wrote — the bytes we put in the store have to be the bytes Darwin
// would have put there, or another reader sees something else.
var cross = Board(name: "CROSS-READ    (port writes → real Foundation reads)")
let xr = RealDefaults(suiteName: SUITE_XREAD)!
let xp = PortedDefaults(suiteName: SUITE_XREAD)!
for (k, v) in CORPUS_VALUES {
    writePorted(xp, k, v)
}
_ = xp.synchronize()
let xrefSuite = "com.example.udoracle.xref"
let xref = RealDefaults(suiteName: xrefSuite)!
for (k, v) in CORPUS_VALUES { writeReal(xref, k, v) }
_ = xref.synchronize()
for (k, v) in CORPUS_VALUES {
    cross.check("cross \(k) [\(v.label)]",
                expected: renderReal(xref.object(forKey: k)),
                got: renderReal(xr.object(forKey: k)))
}

// ---- 9. the on-disk FILENAME, not just the contents
print("\n=== STORAGE — the filename is part of the behaviour ===")
let home = FileManager.default.homeDirectoryForCurrentUser
for s in [SUITE_REAL, SUITE_PORT] {
    let p = home.appendingPathComponent("Library/Preferences/\(s).plist")
    let exists = FileManager.default.fileExists(atPath: p.path)
    var fmt = "—"
    if let d = try? Data(contentsOf: p) {
        fmt = d.prefix(6).elementsEqual("bplist".utf8) ? "bplist00 (\(d.count)B)"
                                                       : "NOT binary (\(d.count)B)"
    }
    print("  \(s.padding(toLength: 34, withPad: " ", startingAt: 0))exists=\(exists)  \(fmt)")
}
print("  NOTE: on Darwin these writes go through cfprefsd, so the file is not")
print("        authoritative in real time and its size lags the domain. Our")
print("        target has no daemon; there the file IS authoritative. That is a")
print("        recorded behavioural difference, not a bug in either.")

// ---- report
control.report()
corelibs.report()
portB.report(showAll: true)
cross.report(showAll: true)

print("\n=== TEETH ===")
var ok = true
if control.fail != 0 {
    print("  ✗ CONTROL-SELF failed \(control.fail) rows. The HARNESS is broken;")
    print("    no other scoreboard in this run means anything.")
    ok = false
} else {
    print("  ✓ CONTROL-SELF is perfect (\(control.pass) rows) — the harness can")
    print("    tell same from same.")
}
if corelibs.fail == 0 {
    print("  ✗ CORELIBS passed everything. Either the transcription of upstream's")
    print("    rules is wrong, or this run is not exercising the string path —")
    print("    a scoreboard that cannot fail has not been shown to detect.")
    ok = false
} else {
    print("  ✓ CORELIBS fails \(corelibs.fail) of \(corelibs.scored) rows — the")
    print("    oracle detects the divergence a straight port would have shipped.")
}
if portB.fail == 0 {
    print("  ✓ PORT is perfect on \(portB.pass) rows, including every row CORELIBS fails.")
}
print("\nSCOREBOARD  control \(control.pass)/\(control.scored) · "
    + "corelibs \(corelibs.pass)/\(corelibs.scored) · "
    + "port \(portB.pass)/\(portB.scored) · cross \(cross.pass)/\(cross.scored)")

// ---- golden emit, for the GUEST route (#87 step 4)
//
// The guest runs on Linux under machorun. There is no real Foundation there to
// diff against, so its expectations must be CARRIED from here. This emits the
// PORT board's rows -- row identity and the answer real Foundation gave -- so
// the guest column and the host column are graded against literally the same
// values produced by the same live oracle in the same run.
//
// It is emitted only after the run has been shown sound: a golden captured
// from a run whose CONTROL-SELF was broken would propagate the breakage to a
// second scoreboard, where nothing could see it.
if mode == "golden" {
    guard ok && portB.fail == 0 else {
        FileHandle.standardError.write(Data(
            "REFUSING to emit a golden from a run that is not sound (control fail \(control.fail), port fail \(portB.fail)).\n".utf8))
        exit(2)
    }
    var out = ""
    out += "# UserDefaults DARWIN GOLDEN -- expectations for the guest route (#87 step 4).\n"
    out += "# Every line is a row the HOST PORT board scored, and the answer REAL\n"
    out += "# Foundation gave for it in the run that produced:\n"
    out += "#   control \(control.pass)/\(control.scored) · corelibs \(corelibs.pass)/\(corelibs.scored)"
    out += " · port \(portB.pass)/\(portB.scored) · cross \(cross.pass)/\(cross.scored)\n"
    out += "# Host: macOS \(ProcessInfo.processInfo.operatingSystemVersionString)\n"
    out += "# Regenerate: full/oracle-userdefaults/build_ud_host.sh OUT && OUT/ud_runner golden\n"
    out += "# Format: <row>\\t<expected>, ONE TAB, both fields C-escaped.\n"
    out += "# Rows are NOT sorted -- order is the order they were scored, which is\n"
    out += "# the order the guest replays them in.\n"
    out += "#\n"
    out += "# WHY BOTH FIELDS ARE ESCAPED. Two rows in this corpus -- string(\"\\t123\")\n"
    out += "# and string(\"123\\t\") -- have a LITERAL TAB in the expected value, because\n"
    out += "# the stored string does. Written raw into a tab-separated file they make\n"
    out += "# three fields, and a naive parser silently takes the wrong one as the\n"
    out += "# expectation. Escaping \\\\, \\t, \\n and \\r makes the format total.\n"
    out += "#\n"
    out += "# NOTE ON SCOPE: these are the SUITE-scoped rows. Anything whose answer\n"
    out += "# depends on this machine's NSGlobalDomain is deliberately not here --\n"
    out += "# see the README's \"Reading these numbers safely\".\n"
    func esc(_ s: String) -> String {
        var r = ""
        for c in s.unicodeScalars {
            switch c {
            case "\\": r += "\\\\"
            case "\t": r += "\\t"
            case "\n": r += "\\n"
            case "\r": r += "\\r"
            default: r.unicodeScalars.append(c)
            }
        }
        return r
    }
    func unesc(_ s: String) -> String {
        var r = ""; var it = s.makeIterator();
        while let c = it.next() {
            if c != "\\" { r.append(c); continue }
            guard let n = it.next() else { r.append(c); break }
            switch n {
            case "\\": r.append("\\")
            case "t": r.append("\t")
            case "n": r.append("\n")
            case "r": r.append("\r")
            default: r.append("\\"); r.append(n)
            }
        }
        return r
    }
    for (row, expected) in portB.all {
        out += "\(esc(row))\t\(esc(expected))\n"
    }

    // TOOTH ON THE FORMAT ITSELF. Re-parse what is about to be written and
    // require it to reproduce the in-memory table exactly. Without this, a
    // value containing the separator degrades SILENTLY -- the guest would grade
    // two rows against a truncated expectation and report the difference as a
    // port defect. Demonstrated necessary: those two rows exist in this corpus.
    var reparsed: [(String, String)] = []
    for line in out.split(separator: "\n", omittingEmptySubsequences: false) {
        if line.hasPrefix("#") || line.isEmpty { continue }
        let parts = line.split(separator: "\t", omittingEmptySubsequences: false)
        guard parts.count == 2 else {
            FileHandle.standardError.write(Data(
                "golden: line does not have exactly 2 fields: \(line)\n".utf8))
            exit(4)
        }
        reparsed.append((unesc(String(parts[0])), unesc(String(parts[1]))))
    }
    guard reparsed.count == portB.all.count else {
        FileHandle.standardError.write(Data(
            "golden: re-parse produced \(reparsed.count) rows, table has \(portB.all.count)\n".utf8))
        exit(4)
    }
    for (i, r) in reparsed.enumerated() where r.0 != portB.all[i].row || r.1 != portB.all[i].expected {
        FileHandle.standardError.write(Data(
            "golden: row \(i) does not round-trip: wrote \(portB.all[i]) read \(r)\n".utf8))
        exit(4)
    }
    print("golden: all \(reparsed.count) rows round-trip through the escaped format")
    // To a FILE, named on the command line -- never to stdout. The board
    // reports above have already gone to stdout, and they should: a golden is
    // only trustworthy alongside the evidence that the run producing it was
    // sound. Mixing the two streams would make the golden unparseable and the
    // evidence invisible at the same time.
    let dest = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "darwin-golden.txt"
    do {
        try out.write(toFile: dest, atomically: true, encoding: .utf8)
    } catch {
        FileHandle.standardError.write(Data("golden: cannot write \(dest): \(error)\n".utf8))
        exit(3)
    }
    print("\ngolden: \(portB.all.count) rows -> \(dest)")
    RealDefaults(suiteName: xrefSuite)?.removePersistentDomain(forName: xrefSuite)
    exit(0)
}

RealDefaults(suiteName: xrefSuite)?.removePersistentDomain(forName: xrefSuite)
exit((ok && portB.fail == 0 && cross.fail == 0) ? 0 : 1)
