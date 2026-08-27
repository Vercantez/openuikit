// url_runner.swift -- score the PORTED FoundationEssentials `URL` against the
// golden that real macOS Foundation produced.
//
//   url_runner <corpus.json> <golden.json>
//
// Prints one line per differing row and a scoreboard with DENOMINATORS.  It
// never prints the word "pass" without "of 809" beside it, and it exits
// non-zero if it scored a number of rows different from the number in the
// corpus -- a runner that scores 12 rows and reports them all correct has
// failed, not succeeded.
//
// READS WITH read(2), NOT Data(contentsOf:).  FileManager and the file-reading
// paths depend on copyfile/removefile/fts/xattr, none of which machorun's
// libSystem exports, so touching them would make the runner fail for reasons
// that have nothing to do with URL.  The oracle must exercise the thing under
// test and as little else as possible.
//
// SEVEN ROWS ARE EXPECTED-FAIL, not sixteen -- see isIDNARow below, which is
// where that was measured.  `_uidnaHook()` is a `dynamic package func` that
// FoundationInternationalization overrides; we do not port that module, so
// IDNA/punycode encoding of non-ASCII hostnames is skipped.  The runner FAILS
// if one of the seven unexpectedly matches, and it PRINTS the diffs of the
// ones that fail, because an expected failure still has to fail in the
// expected way.
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif
import FoundationEssentials

func slurp(_ path: String) -> [UInt8] {
    let fd = open(path, O_RDONLY)
    guard fd >= 0 else {
        FileHandleShim.err("cannot open \(path)\n"); exit(2)
    }
    var out = [UInt8]()
    var buf = [UInt8](repeating: 0, count: 1 << 16)
    while true {
        let n = buf.withUnsafeMutableBytes { read(fd, $0.baseAddress, $0.count) }
        if n <= 0 { break }
        out.append(contentsOf: buf[0..<n])
    }
    close(fd)
    return out
}

enum FileHandleShim {
    static func err(_ s: String) {
        let b = Array(s.utf8)
        b.withUnsafeBufferPointer { p in
            var o = 0
            while o < p.count {
                let n = write(2, p.baseAddress! + o, p.count - o)
                if n <= 0 { break }
                o += n
            }
        }
    }
}

/// One golden row.  Field names and semantics come from url_oracle.swift,
/// which produced the file; `parses == false` rows carry nothing else.
struct Row: Decodable {
    let input: String
    let parses: Bool
    let absoluteString: String?
    let scheme: String?
    let host: String?
    let port: Int?
    let path: String?
    let query: String?
    let fragment: String?
    let user: String?
    let password: String?
    let relativePath: String?
    let isFileURL: Bool?
    let lastPathComponent: String?
    let pathExtension: String?
    let pathComponents: [String]?
    let appendingPathComponent_x: String?
    let deletingLastPathComponent: String?
}

let args = CommandLine.arguments
guard args.count == 3 else {
    FileHandleShim.err("usage: url_runner <corpus.json> <golden.json>\n"); exit(2)
}

let corpusBytes = slurp(args[1])
let goldenBytes = slurp(args[2])
let dec = JSONDecoder()
let corpus = try! dec.decode([String].self, from: Data(corpusBytes))
let golden = try! dec.decode([Row].self, from: Data(goldenBytes))

guard corpus.count == golden.count else {
    FileHandleShim.err("corpus \(corpus.count) rows, golden \(golden.count) rows -- refusing to score\n")
    exit(2)
}
print("== corpus \(corpus.count) rows, golden \(golden.count) rows")

/// A row is expected-fail iff Foundation had to PERFORM an IDNA conversion:
/// the input carries a non-ASCII character AND the golden carries a punycode
/// label.  Both halves are necessary, and getting this wrong is the easiest
/// way to mis-score this corpus.
///
/// MEASURED, not assumed: 16 golden rows contain `xn--`, and only SEVEN of
/// them have a non-ASCII input.  The other NINE were ALREADY punycode when
/// they were written (`https://xn--ls8h.la/path`) -- they need no IDNA hook
/// and MUST pass.  The first version of this file classified on the golden
/// alone, marked all 16 expected-fail, and then reported "9 of 16 IDNA rows
/// MATCHED -- must be 0".  That alarm was the classifier being wrong, not the
/// port; the README's heading "16 rows are EXPECTED-FAIL" carries the same
/// error, though its own body says "7 inputs contain non-ASCII characters and
/// 16 rows carry punycode output".  The right numbers are 7 and 9.
func isIDNARow(_ r: Row) -> Bool {
    guard r.input.unicodeScalars.contains(where: { !$0.isASCII }) else { return false }
    for v in [r.absoluteString, r.host, r.appendingPathComponent_x, r.deletingLastPathComponent] {
        if let v, v.contains("xn--") { return true }
    }
    return false
}

struct Diff { let field: String; let want: String; let got: String }

func cmp(_ field: String, _ want: String?, _ got: String?, _ into: inout [Diff]) {
    if want != got { into.append(Diff(field: field, want: want ?? "<nil>", got: got ?? "<nil>")) }
}

var scored = 0
var passed = 0
var realFailures: [(Row, [Diff])] = []
var idnaExpectedFailed = 0
var idnaUnexpectedlyPassed: [String] = []
/// The expected-fails are printed too, with their diffs.  An expected failure
/// still has to fail IN THE EXPECTED WAY -- if one of these came back with a
/// mangled path rather than an unconverted host, it would be a real defect
/// wearing an expected-fail label.
var idnaShapes: [(Row, [Diff])] = []

for (i, input) in corpus.enumerated() {
    let g = golden[i]
    guard g.input == input else {
        FileHandleShim.err("row \(i): corpus/golden input mismatch -- refusing to score\n"); exit(2)
    }
    scored += 1
    var diffs: [Diff] = []

    guard let u = URL(string: input) else {
        if g.parses { diffs.append(Diff(field: "parses", want: "true", got: "false")) }
        recordOutcome(g, diffs); continue
    }
    if !g.parses {
        diffs.append(Diff(field: "parses", want: "false", got: "true"))
        recordOutcome(g, diffs); continue
    }

    cmp("absoluteString", g.absoluteString, u.absoluteString, &diffs)
    cmp("scheme", g.scheme, u.scheme, &diffs)
    cmp("host", g.host, u.host, &diffs)
    cmp("port", g.port.map(String.init), u.port.map(String.init), &diffs)
    cmp("path", g.path, u.path, &diffs)
    cmp("query", g.query, u.query, &diffs)
    cmp("fragment", g.fragment, u.fragment, &diffs)
    cmp("user", g.user, u.user, &diffs)
    cmp("password", g.password, u.password, &diffs)
    cmp("relativePath", g.relativePath, u.relativePath, &diffs)
    cmp("isFileURL", g.isFileURL.map(String.init), String(u.isFileURL), &diffs)
    cmp("lastPathComponent", g.lastPathComponent, u.lastPathComponent, &diffs)
    cmp("pathExtension", g.pathExtension, u.pathExtension, &diffs)
    cmp("pathComponents", g.pathComponents?.joined(separator: "\u{1}"),
        u.pathComponents.joined(separator: "\u{1}"), &diffs)
    cmp("appendingPathComponent_x", g.appendingPathComponent_x,
        u.appendingPathComponent("x").absoluteString, &diffs)
    cmp("deletingLastPathComponent", g.deletingLastPathComponent,
        u.deletingLastPathComponent().absoluteString, &diffs)

    recordOutcome(g, diffs)
}

func recordOutcome(_ g: Row, _ diffs: [Diff]) {
    let idna = isIDNARow(g)
    if diffs.isEmpty {
        if idna { idnaUnexpectedlyPassed.append(g.input) } else { passed += 1 }
    } else {
        if idna { idnaExpectedFailed += 1; idnaShapes.append((g, diffs)) }
        else { realFailures.append((g, diffs)) }
    }
}

// ---- report ---------------------------------------------------------------
let idnaTotal = golden.filter(isIDNARow).count

for (g, diffs) in realFailures {
    print("FAIL \(g.input)")
    for d in diffs { print("       \(d.field): want \(d.want) | got \(d.got)") }
}
print("")
print("-- the \(idnaShapes.count) expected-fail (IDNA) rows, with their actual shapes:")
for (g, diffs) in idnaShapes {
    print("   XFAIL \(g.input)")
    for d in diffs { print("           \(d.field): want \(d.want) | got \(d.got)") }
}
if !idnaUnexpectedlyPassed.isEmpty {
    print("")
    print("!! \(idnaUnexpectedlyPassed.count) of \(idnaTotal) IDNA rows MATCHED the golden.")
    print("!! They cannot without FoundationInternationalization's _uidnaHook.")
    for s in idnaUnexpectedlyPassed.prefix(10) { print("!!   \(s)") }
}

print("")
print("scored                 \(scored) of \(corpus.count)")
print("pass                   \(passed) of \(corpus.count - idnaTotal) non-IDNA rows")
print("fail                   \(realFailures.count) of \(corpus.count - idnaTotal) non-IDNA rows")
print("expected-fail (IDNA)   \(idnaExpectedFailed) of \(idnaTotal) confirmed failing")
print("IDNA rows that matched \(idnaUnexpectedlyPassed.count) of \(idnaTotal)   (must be 0)")

let ok = scored == corpus.count
    && realFailures.isEmpty
    && idnaUnexpectedlyPassed.isEmpty
    && idnaExpectedFailed == idnaTotal
exit(ok ? 0 : 1)
