// json_oracle.swift -- MACOS ONLY.  Record what REAL Foundation says about
// every document in the corpus, on THREE columns, and write the golden.
//
//     swiftc -O -D ORACLE_BUILD -o json_oracle \
//         json_canon.swift json_probes.swift json_oracle.swift
//     ./json_oracle corpus.json > golden.json
//
// ---------------------------------------------------------------------------
// THREE COLUMNS, BECAUSE ONE OF THEM IS NOT AN INDEPENDENT IMPLEMENTATION AND
// SAYING SO IS THE POINT.
//
//   A  JSONSerialization  -- Darwin's closed-source CF parser.  NOT part of
//                            swift-foundation and NOT part of the port.  This
//                            is the genuinely independent implementation, and
//                            agreement with it is the strong claim.
//   B  JSONDecoder        -- MEASURED to be swift-foundation's own scanner on
//                            this machine: `JSONDecoder().decode(from: "{")`
//                            reports `The given data was not valid JSON.` with
//                            an underlying NSCocoaError 3840 `Unexpected end
//                            of file`, which is exactly
//                            JSONDecoder.swift:393 + JSONScanner.swift:1308 +
//                            the CustomNSError conformance at
//                            JSONScanner.swift:1381.  So column B is THE SAME
//                            SOURCE the port compiles, built by Apple.
//   C  the port           -- produced by `json_runner`, not by this file.
//
// C-vs-B is therefore a build/toolchain/stack differential, not a
// cross-implementation one, and it must be reported as such.  C-vs-A is the
// cross-implementation comparison.  A URL-oracle-style "802 of 802 agree"
// headline would be a much weaker claim here than it was there, and the README
// says so before it prints any number.
//
// A is recorded TWICE -- with and without `.fragmentsAllowed` -- because the
// real corpus contains ZERO top-level fragments and that is precisely where
// the two Apple implementations are known to differ.
import Foundation

// LOCAL time, on purpose: the golden's `generated` field, the file name it is
// committed under, and the `git log` date have to be the same day, or a later
// reader has to work out which one is UTC.
func iso(_ d: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    return f.string(from: d)
}

// --- canonicalise a JSONSerialization result -------------------------------
//
// NSNUMBER TYPE FOLDING IS THE WHOLE DIFFICULTY.  CF hands back
// `__NSCFNumber`, and the JSON type it came from survives only in `objCType`:
// measured on this machine, `1` -> 'q', `1.0` -> 'd', `-0` -> 'q' (the sign is
// GONE), `1e2` -> 'd', `9223372036854775808` -> 'Q'.  Booleans are
// `__NSCFBoolean`, which is also an NSNumber, so they are separated by
// CFBooleanGetTypeID rather than by objCType -- checking for 'c' would misread
// any small integer CF chose to store narrowly.
func canonAny(_ v: Any) -> String {
    if v is NSNull { return "N" }
    if let n = v as? NSNumber {
        if CFGetTypeID(n as CFTypeRef) == CFBooleanGetTypeID() { return n.boolValue ? "T" : "F" }
        let t = String(cString: n.objCType)
        switch t {
        case "c", "C", "s", "S", "i", "I", "l", "L", "q": return "I\(n.int64Value)"
        case "Q": return "U\(n.uint64Value)"
        default: return "D" + hex16(n.doubleValue.bitPattern)
        }
    }
    if let s = v as? String { return canonString(s) }
    if let a = v as? [Any] { return "[" + a.map(canonAny).joined(separator: ",") + "]" }
    if let d = v as? [String: Any] {
        let keys = d.keys.sorted { Array($0.utf8).lexicographicallyPrecedes(Array($1.utf8)) }
        return "{" + keys.map { canonString($0) + "=" + canonAny(d[$0]!) }.joined(separator: ",") + "}"
    }
    return "?" + String(describing: type(of: v))
}

/// NSError identity, not its message -- same pre-registered rule as
/// `errorKind`: domain and code are the contract, `localizedDescription` is
/// prose.
func nsErrorKind(_ e: Error) -> String {
    let n = e as NSError
    return "\(n.domain)#\(n.code)"
}

struct SerOutcome {
    var ok = false
    var canon: String? = nil
    var err: String? = nil
    var errText: String? = nil
}

func serialize(_ bytes: [UInt8], fragments: Bool) -> SerOutcome {
    var o = SerOutcome()
    let opts: JSONSerialization.ReadingOptions = fragments ? [.fragmentsAllowed] : []
    do {
        let obj = try JSONSerialization.jsonObject(with: Data(bytes), options: opts)
        o.ok = true
        o.canon = digestIfLarge(canonAny(obj))
    } catch {
        o.ok = false
        o.err = nsErrorKind(error)
        o.errText = "\(error)"
    }
    return o
}

// --- main ------------------------------------------------------------------
// Top-level statements are only legal in `main.swift`, and this oracle is one
// of three files in its module, so the entry point is explicit.
@main
struct JSONOracle {
static func main() {
    let args = CommandLine.arguments
    guard args.count == 2 else { errWrite("usage: json_oracle <corpus.json>\n"); exit(2) }

    let corpusBytes = slurp(args[1])
    let docs = try! JSONDecoder().decode([CorpusDoc].self, from: Data(corpusBytes))
    errWrite("== corpus: \(docs.count) documents\n")

    func opt(_ s: String?) -> Any { s ?? NSNull() }
    func opt(_ b: Bool?) -> Any { b ?? NSNull() }

    var rows: [[String: Any]] = []
    for d in docs {
        guard let raw = base64Decode(d.b64) else {
            errWrite("row \(d.id): base64 decode failed -- refusing to write a golden\n"); exit(2)
        }
        guard raw.count == d.bytes else {
            errWrite("row \(d.id): b64 decodes to \(raw.count) bytes, corpus says \(d.bytes) -- refusing\n"); exit(2)
        }

        let m = measure(raw)                       // column B + the round trip
        let s = serialize(raw, fragments: false)   // column A
        let sf = serialize(raw, fragments: true)   // column A, fragments allowed

        rows.append([
            "id": d.id,
            "set": d.set,
            "origin": d.origin,
            "dec_ok": m.decOK,
            "dec_canon": opt(m.decCanon),
            "dec_err": opt(m.decErr),
            "dec_err_text": opt(m.decErrText),
            "enc_ok": opt(m.encOK),
            "enc_out": opt(m.encOut),
            "enc_err": opt(m.encErr),
            "ser_ok": s.ok,
            "ser_canon": opt(s.canon),
            "ser_err": opt(s.err),
            "ser_err_text": opt(s.errText),
            "serfrag_ok": sf.ok,
            // `.fragmentsAllowed` changes the answer for SEVEN of 363
            // documents, so storing a second full copy of the canon for the
            // other 356 was 415 KB of the golden saying "same".  The sentinel
            // is explicit rather than an omission: a reader sees that the
            // column was measured and agreed.
            "serfrag_canon": (sf.canon != nil && sf.canon == s.canon) ? "=ser" : opt(sf.canon),
            "serfrag_err": opt(sf.err),
        ])
    }

    var probeRows: [[String: Any]] = []
    for p in PROBES {
        probeRows.append(["label": p.label, "config": p.config.rawValue, "result": runProbe(p)])
    }

    let top: [String: Any] = [
        "generated": iso(Date()),
        "macos": ProcessInfo.processInfo.operatingSystemVersionString,
        "docs": rows,
        "probes": probeRows,
    ]
    let out = try! JSONSerialization.data(withJSONObject: top, options: [.prettyPrinted, .sortedKeys])
    FileHandle.standardOutput.write(out)

    // A SUMMARY ON STDERR, so the golden run itself is not a silent success.  A
    // tool that runs and prints nothing has failed.
    var decOK = 0, serOK = 0, serFragOK = 0, encOK = 0
    var realN = 0, synN = 0
    for (i, d) in docs.enumerated() {
        if d.set == "real" { realN += 1 } else { synN += 1 }
        let r = rows[i]
        if r["dec_ok"] as! Bool { decOK += 1 }
        if r["ser_ok"] as! Bool { serOK += 1 }
        if r["serfrag_ok"] as! Bool { serFragOK += 1 }
        if (r["enc_ok"] as? Bool) == true { encOK += 1 }
    }
    errWrite("""
    == golden written
       documents                 \(docs.count)   (real \(realN), synthetic \(synN))
       B JSONDecoder parsed      \(decOK) of \(docs.count)
       A JSONSerialization       \(serOK) of \(docs.count)   (+fragmentsAllowed \(serFragOK))
       B round-trip encoded      \(encOK) of \(decOK) decoded
       codable probes            \(probeRows.count)

    """)

}
}
