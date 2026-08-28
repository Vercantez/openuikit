//===----------------------------------------------------------------------===//
// #87 STEP 4 — the GUEST UserDefaults scoreboard.
//
// Scores the port running as the Foundation overlay over OUR CoreFoundation,
// on Linux under machorun, against the answers REAL Foundation gave on macOS.
//
// WHERE THE EXPECTATIONS COME FROM, AND WHY IT MATTERS. There is no real
// Foundation here to diff against, so the expectations are CARRIED: the host
// oracle's `ud_runner golden` emits, for every row it scored, the answer real
// Foundation gave, straight out of the same `Board.check` calls that produced
// its own 627/627. The host column and this column are therefore graded
// against literally the same values from the same live run. The alternative --
// retyping the coercion tables here -- would have created a second authority
// for the same answers, where a slip would surface as a port failure or, worse,
// mask a real one.
//
// THE CORPUS IS DERIVED FROM THE GOLDEN, NOT RESTATED. Every row identity
// encodes what to do: `roundtrip v_int [Int(42)]` says write 42 under v_int,
// `bool("YES")` says the string corpus contains "YES". So this runner does not
// carry its own copy of the corpus either; it reads it out of the golden. If
// that derivation is wrong, the CONSUMPTION CHECK at the end catches it -- every
// golden row must be accounted for exactly once, and every row this runner
// produces must exist in the golden. A corpus that silently drifted would leave
// rows unconsumed, and unconsumed rows are a hard failure rather than a smaller
// denominator.
//
// THREE COLUMNS, and the middle one is what makes the first one mean anything:
//
//   PORT       guest answers vs REAL FOUNDATION's (column D). Must pass.
//   MUST-FAIL  guest answers vs CORELIBS' rules (column C). Must FAIL, and the
//              run aborts if it passes -- a guest matching upstream's NSString
//              conversions has regressed to the behaviour the whole port exists
//              to correct, and a column that cannot fail has not been shown to
//              detect anything.
//   REFUSED    rows this build genuinely cannot attempt, each named, with its
//              golden expectation and the reason. REPORTED, never skipped: a
//              denominator that quietly shrinks to the rows that pass is the
//              oldest false green there is.
//
// WHY REFUSED ROWS ARE NOT ATTEMPTED. `_UDUnimplemented` returns Never — the
// guest CF bridge ABORTS THE PROCESS on an unmarshalled type rather than
// returning nil. That is the right behaviour for the bridge and it means this
// runner must classify statically: attempting `set(Data(...))` would kill the
// run, not score a row.
//===----------------------------------------------------------------------===//

import FoundationEssentials
import PortedUserDefaultsGuest
import UDPlatformMinimal

// MARK: - Output. `print` through FoundationEssentials is fine, but a buffered
// write is discarded by abort(), and this runner can abort on purpose.

func say(_ s: String) {
    var b = Array((s + "\n").utf8)
    b.withUnsafeMutableBufferPointer { p in
        _ = ud_write(1, p.baseAddress, UInt(p.count))
    }
}

func die(_ s: String) -> Never {
    say("")
    say("*** \(s)")
    ud_exit(1)
}

// MARK: - Canonical rendering, matching the host runner's exactly.
//
// The host renders into a type-tagged string so "same answer" is decidable.
// Here the values coming back are Swift-native (the guest bridge returns Bool,
// Int, Double, String from CF type-ID dispatch), so the Swift-native arm of the
// host's renderer is the one that has to agree — including its Bool-before-Int
// ordering, which is the NSNumber folding hazard the port exists to respect.

func canonDouble(_ d: Double) -> String {
    var buf = [CChar](repeating: 0, count: 64)
    buf.withUnsafeMutableBufferPointer { b in
        withVaList([d]) { va in
            _ = ud_vsnprintf(b.baseAddress, 64, "%0.17g", va)
        }
    }
    var out = ""
    for c in buf { if c == 0 { break }; out.append(Character(UnicodeScalar(UInt8(bitPattern: c)))) }
    return out
}

func render(_ v: Any?) -> String {
    guard let v = v else { return "nil" }
    if let b = v as? Bool { return "Bool(\(b))" }
    if let i = v as? Int { return "Int(\(i))" }
    if let d = v as? Double { return "Double(\(canonDouble(d)))" }
    if let s = v as? String { return "String(\(s))" }
    return "OTHER(\(type(of: v)))"
}

// MARK: - The golden

func unesc(_ s: String) -> String {
    var r = ""; var it = s.makeIterator()
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

var darwinRows: [(row: String, answer: String)] = []
var darwinAt: [String: String] = [:]
var corelibsAt: [String: String] = [:]

for line in GOLDEN_TEXT.split(separator: "\n", omittingEmptySubsequences: false) {
    if line.isEmpty || line.hasPrefix("#") { continue }
    let f = line.split(separator: "\t", omittingEmptySubsequences: false)
    guard f.count == 3 else { die("golden line has \(f.count) fields: \(line)") }
    let row = unesc(String(f[1])), ans = unesc(String(f[2]))
    if f[0] == "D" { darwinRows.append((row, ans)); darwinAt[row] = ans }
    else { corelibsAt[row] = ans }
}

guard darwinRows.count == GOLDEN_ROWS_D, corelibsAt.count > 0 else {
    die("golden parsed \(darwinRows.count) D rows, header says \(GOLDEN_ROWS_D)")
}

// MARK: - Derive the corpus FROM the golden.

enum V {
    case s(String), i(Int), d(Double), f(Float), b(Bool)
    case unmarshalled(String)     // Data / Date / Array / Dict
}

/// `roundtrip v_int [Int(42)]` -> ("v_int", .i(42))
func parseRoundtrip(_ row: String) -> (String, V)? {
    guard row.hasPrefix("roundtrip ") else { return nil }
    let rest = String(row.dropFirst("roundtrip ".count))
    guard let br = rest.firstIndex(of: "[") else { return nil }
    let key = String(rest[rest.startIndex..<br]).trimmed()
    var label = String(rest[rest.index(after: br)...])
    if label.hasSuffix("]") { label = String(label.dropLast()) }
    func inner(_ tag: String) -> String? {
        guard label.hasPrefix(tag + "("), label.hasSuffix(")") else { return nil }
        return String(label.dropFirst(tag.count + 1).dropLast())
    }
    if let x = inner("String") { return (key, .s(x)) }
    if let x = inner("Int"), let n = Int(x) { return (key, .i(n)) }
    if let x = inner("Double"), let n = Double(x) { return (key, .d(n)) }
    if let x = inner("Float"), let n = Float(x) { return (key, .f(n)) }
    if let x = inner("Bool") { return (key, .b(x == "true")) }
    return (key, .unmarshalled(label))
}

/// The host builds a row's display form with exactly two substitutions:
/// newline -> \n and tab -> \t. It does NOT escape backslash. So the inverse
/// used here must undo exactly those two and nothing else -- reusing the
/// golden's own `unesc` would additionally eat backslashes and quietly change
/// any corpus string containing one. No such string exists today; matching the
/// transform anyway is what keeps that true tomorrow rather than by luck.
/// FoundationEssentials has no `replacingOccurrences` (that is NSString), so
/// both directions are spelled out here.
func disp(_ s: String) -> String {
    var r = ""
    for c in s {
        if c == "\n" { r += "\\n" } else if c == "\t" { r += "\\t" } else { r.append(c) }
    }
    return r
}

func undisp(_ s: String) -> String {
    var r = ""; var it = s.makeIterator()
    while let c = it.next() {
        if c != "\\" { r.append(c); continue }
        guard let n = it.next() else { r.append(c); break }
        switch n {
        case "n": r.append("\n")
        case "t": r.append("\t")
        default: r.append("\\"); r.append(n)
        }
    }
    return r
}

/// `string("YES")` -> the stored string.
func parseStringRow(_ row: String) -> String? {
    guard row.hasPrefix("string(\""), row.hasSuffix("\")") else { return nil }
    return undisp(String(row.dropFirst("string(\"".count).dropLast(2)))
}

extension String {
    func trimmed() -> String {
        var s = Substring(self)
        while let f = s.first, f == " " { s = s.dropFirst() }
        while let l = s.last, l == " " { s = s.dropLast() }
        return String(s)
    }
}

var corpusValues: [(String, V)] = []
var corpusStrings: [String] = []
var seenKey = Set<String>()
for (row, _) in darwinRows {
    if let (k, v) = parseRoundtrip(row), !seenKey.contains(k) {
        seenKey.insert(k); corpusValues.append((k, v))
    }
    if let s = parseStringRow(row) { corpusStrings.append(s) }
}

say("=== corpus derived from the golden ===")
say("  values  \(corpusValues.count)")
say("  strings \(corpusStrings.count)")

// MARK: - Boards

struct Board {
    let name: String
    var pass = 0, fail = 0
    var failures: [(String, String, String)] = []
    mutating func check(_ row: String, expected: String, got: String) {
        if expected == got { pass += 1 }
        else { fail += 1; failures.append((row, expected, got)) }
    }
    var scored: Int { pass + fail }
}

var portB = Board(name: "PORT")
var mustFail = Board(name: "MUST-FAIL")
var consumed = Set<String>()
var consumedC = Set<String>()
var refused: [(row: String, golden: String, why: String)] = []

/// Score a row against the golden, and against corelibs where corelibs has an
/// opinion. Every scored row is marked consumed.
func score(_ row: String, _ got: String) {
    guard let want = darwinAt[row] else {
        die("row produced by the guest is NOT in the golden: \(row)\n"
          + "    The corpus derived here has drifted from the one the host scored.")
    }
    consumed.insert(row)
    portB.check(row, expected: want, got: got)
    if let c = corelibsAt[row] { consumedC.insert(row); mustFail.check(row, expected: c, got: got) }
}

func refuse(_ row: String, _ why: String) {
    guard let want = darwinAt[row] else { die("refused row not in golden: \(row)") }
    consumed.insert(row)
    refused.append((row, want, why))
}

// MARK: - Mode
//
// THREE MODES, and the split exists for one reason: a single process proves
// nothing about persistence. Everything `score` reads back could have come from
// CF's in-memory preferences cache. On Darwin that ambiguity is tolerable
// because writes go through cfprefsd and the file is not authoritative in real
// time anyway; HERE THERE IS NO DAEMON, so persistence must come from the file
// -- which makes this the route where a format or flush defect actually bites,
// and makes a fresh-process read the only honest test of it.
//
//   score          write and read in ONE process (the #87 step 4 board)
//   persist-write  write, synchronise, exit. NOTHING is scored.
//   persist-read   a FRESH process: read and score, writing nothing.
//
// Mode comes from the environment rather than argv because ud_getenv is
// already declared in the guest's libc surface and needs no argument plumbing
// through machorun.
func envStr(_ name: String) -> String? {
    guard let p = ud_getenv(name) else { return nil }
    var s = ""; var i = 0
    while p[i] != 0 { s.append(Character(UnicodeScalar(UInt8(bitPattern: p[i])))); i += 1 }
    return s
}
let MODE = envStr("UD_MODE") ?? "score"
guard ["score", "persist-write", "persist-read"].contains(MODE) else {
    die("unknown UD_MODE '\(MODE)'")
}

// MARK: - Replay

let SUITE = MODE == "score" ? "com.example.udguest.score"
                            : "com.example.udguest.persist"
let SUITE_OTHER = SUITE + ".other"
guard let d = UserDefaults(suiteName: SUITE) else { die("UserDefaults(suiteName:) returned nil") }
guard let other = UserDefaults(suiteName: SUITE_OTHER) else { die("other suite nil") }

let UNMARSHALLED_WHY =
    "guest CF bridge marshals Bool/String/Int/Double/Float only; "
  + "Data/Date/Array/Dict abort by design (_UDUnimplemented is -> Never)"

// REGISTRATION IS PER-PROCESS BY DESIGN, so its rows cannot be scored after a
// restart -- register(defaults:) populates a volatile domain that is never
// written to the file. Two of the six would even PASS across a restart
// ("a SET key beats the registered one" reads a persisted key; "removeObject
// FALLS BACK to registered" reads nil either way), which is exactly the shape
// this board refuses to count: right answer, no registration involved.
let REGISTER_ROWS = [
    "register: unset key reads the registered value",
    "register: a SET key beats the registered one",
    "register: typed getter sees it",
    "register: after set",
    "register: removeObject FALLS BACK to registered",
]
let REGISTER_WHY =
    "register(defaults:) is a VOLATILE domain, never written to the file; "
  + "after a restart these rows would answer without any registration present"

var writable: [(String, V)] = []
for (k, v) in corpusValues { if case .unmarshalled = v {} else { writable.append((k, v)) } }

func writeCorpus() {
    for (k, v) in writable {
        switch v {
        case .s(let x): d.set(x, forKey: k)
        case .i(let x): d.set(x, forKey: k)
        case .d(let x): d.set(x, forKey: k)
        case .f(let x): d.set(x, forKey: k)
        case .b(let x): d.set(x, forKey: k)
        case .unmarshalled: break
        }
    }
    for (i, s) in corpusStrings.enumerated() { d.set(s, forKey: "s\(i)") }
    // The rows outside the corpus loops that are nonetheless pure stored state.
    d.set("x", forKey: "nilme"); d.set(nil, forKey: "nilme")
    other.set("other", forKey: "iso")
    for (i, uk) in NONASCII_KEYS.enumerated() { d.set("v\(i)-é日🔑", forKey: uk) }
    _ = d.synchronize(); _ = other.synchronize()
}

let NONASCII_KEYS = ["clé_caché", "日本語のキー", "🔑", "ключ"]

if MODE != "persist-read" {
    // Start from a known-empty store, or a previous run's values grade this one.
    for (k, _) in corpusValues { d.removeObject(forKey: k) }
    for i in 0..<corpusStrings.count { d.removeObject(forKey: "s\(i)") }
    for k in ["reg_only", "reg_int", "nilme", "iso", "definitely_absent_key",
              "clé_caché", "日本語のキー", "🔑", "ключ", "c", "日", "к"] {
        d.removeObject(forKey: k); other.removeObject(forKey: k)
    }
    _ = d.synchronize(); _ = other.synchronize()
    writeCorpus()
}

if MODE == "persist-write" {
    // NOTHING IS SCORED HERE. Report only what was written, so the orchestrator
    // and the reader phase have a stated expectation to check against.
    say("")
    say("persist-write: suite \(SUITE)")
    say("  values written   \(writable.count) of \(corpusValues.count) "
      + "(\(corpusValues.count - writable.count) unmarshalled by design)")
    say("  strings written  \(corpusStrings.count)")
    say("  non-ASCII keys   \(NONASCII_KEYS.count)")
    say("  synchronised, exiting without scoring anything.")
    ud_exit(0)
}

// ---- 1. round-trip
for (k, v) in corpusValues {
    let row = darwinRows.first { $0.row.hasPrefix("roundtrip \(k) [") }!.row
    if case .unmarshalled(let label) = v {
        refuse(row, "\(label): \(UNMARSHALLED_WHY)")
    } else {
        score(row, render(d.object(forKey: k)))
    }
}

// ---- 2. the coercion grid over every stored string
for (i, s) in corpusStrings.enumerated() {
    let k = "s\(i)"
    let ds = disp(s)
    score("integer(\"\(ds)\")", String(d.integer(forKey: k)))
    score("double(\"\(ds)\")", canonDouble(d.double(forKey: k)))
    score("bool(\"\(ds)\")", String(d.bool(forKey: k)))
    score("string(\"\(ds)\")", d.string(forKey: k) ?? "nil")
}

// ---- 3. coercion over every stored NON-string type
for (k, v) in corpusValues {
    let label: String
    switch v {
    case .s(let x): label = "String(\(x))"
    case .i(let x): label = "Int(\(x))"
    case .d(let x): label = "Double(\(x))"
    case .f(let x): label = "Float(\(x))"
    case .b(let x): label = "Bool(\(x))"
    case .unmarshalled(let l): label = l
    }
    let rows = ["integer \(k) [\(label)]", "double \(k) [\(label)]",
                "float \(k) [\(label)]", "bool \(k) [\(label)]",
                "string \(k) [\(label)]", "array? \(k)", "dict? \(k)",
                "data? \(k)", "stringArray \(k)"]
    if case .unmarshalled = v {
        for r in rows { refuse(r, "\(label): \(UNMARSHALLED_WHY)") }
        continue
    }
    score(rows[0], String(d.integer(forKey: k)))
    score(rows[1], canonDouble(d.double(forKey: k)))
    score(rows[2], String(d.float(forKey: k)))
    score(rows[3], String(d.bool(forKey: k)))
    score(rows[4], d.string(forKey: k) ?? "nil")
    score(rows[5], String(d.array(forKey: k) != nil))
    score(rows[6], String(d.dictionary(forKey: k) != nil))
    score(rows[7], String(d.data(forKey: k) != nil))
    score(rows[8], d.stringArray(forKey: k).map { $0.joined(separator: "|") } ?? "nil")
}

// ---- 4. absent keys — absence is an answer
let ak = "definitely_absent_key"
score("absent object(forKey:)", render(d.object(forKey: ak)))
score("absent string(forKey:)", d.string(forKey: ak) ?? "nil")
score("absent integer(forKey:)", String(d.integer(forKey: ak)))
score("absent double(forKey:)", canonDouble(d.double(forKey: ak)))
score("absent float(forKey:)", String(d.float(forKey: ak)))
score("absent bool(forKey:)", String(d.bool(forKey: ak)))
score("absent array(forKey:)", d.array(forKey: ak) == nil ? "nil" : "some")
score("absent data(forKey:)", d.data(forKey: ak) == nil ? "nil" : "some")
score("absent stringArray(forKey:)", d.stringArray(forKey: ak) == nil ? "nil" : "some")
score("absent dictionary(forKey:)", d.dictionary(forKey: ak) == nil ? "nil" : "some")

// ---- 5. register(defaults:) layering and removeObject fallback
if MODE == "persist-read" {
    for r in REGISTER_ROWS { refuse(r, REGISTER_WHY) }
} else {
    d.register(defaults: ["reg_only": "from-register", "v_string": "reg-LOSES", "reg_int": 7])
    score("register: unset key reads the registered value", render(d.object(forKey: "reg_only")))
    score("register: a SET key beats the registered one", render(d.object(forKey: "v_string")))
    score("register: typed getter sees it", String(d.integer(forKey: "reg_int")))
    d.set("set-value", forKey: "reg_only")
    score("register: after set", render(d.object(forKey: "reg_only")))
    d.removeObject(forKey: "reg_only")
    score("register: removeObject FALLS BACK to registered", render(d.object(forKey: "reg_only")))
}

// persistentDomain is HOST-ONLY on this build: _udCopyAll returns [:], so the
// answer "reg_only is not in the persistent domain" would be true because the
// domain is EMPTY, not because registration is kept out of it. That is the
// right answer for the wrong reason, which is worse than no answer.
refuse("register: NOT in persistentDomain",
       "persistentDomain reads through _udCopyAll, which returns [:] on the "
     + "guest; this row would PASS VACUOUSLY (empty domain lacks every key)")

// ---- 6. set(nil) is removeObject
// In persist-read the write already happened in the previous process, and
// re-doing it here would turn a persistence test back into a round trip.
if MODE != "persist-read" { d.set("x", forKey: "nilme"); d.set(nil, forKey: "nilme") }
score("set(nil) removes", render(d.object(forKey: "nilme")))

// ---- 7. suite isolation
if MODE != "persist-read" { other.set("other", forKey: "iso"); _ = other.synchronize() }
score("suite isolation: other suite's key is not in this one", render(d.object(forKey: "iso")))
score("suite isolation: same suite, both sides see it", render(other.object(forKey: "iso")))

// ---- 7b. NON-ASCII KEYS.
//
// The string corpus stores non-ASCII VALUES under ASCII keys s0..sN, so it
// never puts a multi-byte string through the KEY path — and here that is a
// different call: the key becomes a CFString that CFPreferences hashes and
// compares, while a value is only stored and handed back. This is the row set
// that measures the guest bridge's CFStringCreateWithBytes(UTF-8,
// isExternalRepresentation: false) rather than assuming it.
//
// These rows are spelled out rather than derived from the golden, because
// unlike `roundtrip`/`string(...)` their names do not encode the corpus. If the
// spelling drifts from the host's, the consumption check reports them as
// unaccounted-for golden rows — which is a hard failure, not a smaller board.
for (i, uk) in NONASCII_KEYS.enumerated() {
    if MODE != "persist-read" { d.set("v\(i)-é日🔑", forKey: uk) }
    score("non-ASCII key round-trip [\(uk)]", render(d.object(forKey: uk)))
    score("non-ASCII key string(forKey:) [\(uk)]", d.string(forKey: uk) ?? "nil")
    score("non-ASCII key looked up by first character [\(uk)]",
          render(d.object(forKey: String(uk.prefix(1)))))
}

// MARK: - Report

func report(_ b: Board, showAll: Bool) {
    say("")
    say("\(b.name): scored \(b.scored) · pass \(b.pass) · fail \(b.fail)")
    let show = showAll ? b.failures : Array(b.failures.prefix(30))
    for f in show {
        var r = f.0
        while r.count < 44 { r += " " }
        say("    \(r)expected \(f.1)   got \(f.2)")
    }
    if b.failures.count > show.count { say("    … \(b.failures.count - show.count) more") }
}

say("")
say("=== UserDefaults differential oracle — GUEST ROUTE (#87 step 4) ===")

// THE ROUTE. The board names the composition it measured, because "the guest
// route" is not an artifact and five things under it move independently. The
// hashes are baked in at build time (Provenance.swift); the root is read from
// the environment at run time, because the same binary can be pointed at a
// different root and would otherwise report a number belonging to a tree it
// never touched.
say("route:")
for (what, which) in ROUTE {
    var w = what
    while w.count < 22 { w += " " }
    say("  \(w)\(which)")
}
var rootStr = "MACHORUN_ROOT unset"
if let p = ud_getenv("MACHORUN_ROOT") {
    var s = ""; var i = 0
    while p[i] != 0 { s.append(Character(UnicodeScalar(UInt8(bitPattern: p[i])))); i += 1 }
    rootStr = s
}
var rl = "guest root"; while rl.count < 22 { rl += " " }
say("  \(rl)\(rootStr)")
var gl = "golden"; while gl.count < 22 { gl += " " }
say("  \(gl)darwin-golden-2026-08-28.txt \(String(GOLDEN_SHA256.prefix(16)))")
say("  golden rows           D \(GOLDEN_ROWS_D) (real Foundation) · C \(GOLDEN_ROWS_C) (corelibs' rules)")

report(portB, showAll: true)
report(mustFail, showAll: false)

say("")
say("REFUSED (not attempted — reported, not skipped): \(refused.count)")
var byWhy: [String: Int] = [:]
for r in refused { byWhy[r.why, default: 0] += 1 }
for (why, n) in byWhy.sorted(by: { $0.value > $1.value }) {
    say("  \(n) rows · \(why)")
}
for r in refused.prefix(12) {
    var row = r.row
    while row.count < 44 { row += " " }
    say("    \(row)golden \(r.golden)")
}
if refused.count > 12 { say("    … \(refused.count - 12) more") }

// MARK: - The denominator must be consumed

say("")
say("=== DENOMINATOR ===")
let unconsumed = darwinRows.filter { !consumed.contains($0.row) }
say("  golden rows        \(darwinRows.count)")
say("  scored             \(portB.scored)")
say("  refused            \(refused.count)")
say("  scored + refused   \(portB.scored + refused.count)")
say("  unaccounted for    \(unconsumed.count)")
for u in unconsumed.prefix(15) { say("      \(u.row)") }
if unconsumed.count > 15 { say("      … \(unconsumed.count - 15) more") }

// THE MUST-FAIL COLUMN HAS ITS OWN DENOMINATOR, and it is not the same one.
// A C row is consulted only when the guest actually scored the row it names, so
// C rows go unused for two very different reasons: the row was REFUSED (fine,
// and already accounted for above), or the row NAME does not match anything the
// guest produced (not fine -- that is drift between the two columns, and it
// shrinks the must-fail board silently while leaving it looking healthy). The
// first version of this board scored 261 of 313 for exactly that reason.
let unusedC = corelibsAt.keys.filter { !consumedC.contains($0) }.sorted()
let unusedBecauseRefused = unusedC.filter { r in refused.contains { $0.row == r } }
let unusedUnexplained = unusedC.filter { r in !refused.contains { $0.row == r } }
say("  corelibs rows      \(corelibsAt.count)")
say("    consulted        \(consumedC.count)")
say("    unused: refused  \(unusedBecauseRefused.count)")
say("    unused: NO MATCH \(unusedUnexplained.count)")
for u in unusedUnexplained.prefix(10) { say("      \(u)") }
if unusedUnexplained.count > 10 { say("      … \(unusedUnexplained.count - 10) more") }

// MARK: - Teeth

say("")
say("=== TEETH ===")
var ok = true

// PRESENCE, BEFORE AGREEMENT. This board compares answers, and an EMPTY store
// agrees with a golden on every row whose expectation happens to be nil or a
// zero-valued getter. So count what is actually THERE first: every value and
// string written must read back non-nil, and a specific distinctive value must
// be exactly right. Without this a persist-read against a deleted file could
// score respectably and mean nothing.
let presentValues = writable.filter { d.object(forKey: $0.0) != nil }.count
let presentStrings = (0..<corpusStrings.count).filter { d.object(forKey: "s\($0)") != nil }.count
let presentKeys = NONASCII_KEYS.filter { d.object(forKey: $0) != nil }.count
let witness = d.string(forKey: "s\(corpusStrings.count - 1)") ?? "nil"
let witnessWant = corpusStrings.last ?? ""
say("  presence: \(presentValues)/\(writable.count) values · "
  + "\(presentStrings)/\(corpusStrings.count) strings · "
  + "\(presentKeys)/\(NONASCII_KEYS.count) non-ASCII keys")
say("  witness:  last corpus string reads \(witness == witnessWant ? "correctly" : "WRONG: \(witness)")")
if presentValues != writable.count || presentStrings != corpusStrings.count
    || presentKeys != NONASCII_KEYS.count || witness != witnessWant {
    say("  ✗ the store does not hold what was written. An agreement-only board")
    say("    scores well against an EMPTY store, so this is checked before the")
    say("    scoreboard is allowed to mean anything.")
    ok = false
} else {
    say("  ✓ every written key is present and the witness value is exact — the")
    say("    board is grading a populated store, not an empty one.")
}
if !unconsumed.isEmpty {
    say("  ✗ \(unconsumed.count) golden rows were neither scored nor refused.")
    say("    A verdict that does not consume its denominator is not a verdict.")
    ok = false
} else {
    say("  ✓ all \(darwinRows.count) golden rows accounted for (\(portB.scored) scored + \(refused.count) refused).")
}
if !unusedUnexplained.isEmpty {
    say("  ✗ \(unusedUnexplained.count) corelibs rows matched no row the guest produced.")
    say("    The two columns of the golden have drifted apart; the must-fail")
    say("    board is smaller than it looks and nothing else would say so.")
    ok = false
} else {
    say("  ✓ every corelibs row is either consulted (\(consumedC.count)) or refused (\(unusedBecauseRefused.count)).")
}
if mustFail.fail == 0 {
    say("  ✗ MUST-FAIL passed all \(mustFail.scored) rows. The guest is answering")
    say("    what corelibs' NSString conversions answer — the behaviour this port")
    say("    exists to correct — or this board is not reaching the string path.")
    say("    Either way the PORT column above cannot be trusted.")
    ok = false
} else {
    say("  ✓ MUST-FAIL fails \(mustFail.fail) of \(mustFail.scored) rows — the guest")
    say("    disagrees with upstream exactly where Darwin does.")
}
if portB.fail == 0 && ok {
    say("  ✓ PORT is perfect on \(portB.pass) rows against real Foundation's answers.")
}

say("")
say("GUEST SCOREBOARD  port \(portB.pass)/\(portB.scored)"
  + " · must-fail \(mustFail.fail)/\(mustFail.scored) failing (required)"
  + " · refused \(refused.count) · denominator \(darwinRows.count)")

ud_exit((ok && portB.fail == 0) ? 0 : 1)
