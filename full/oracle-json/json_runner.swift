// json_runner.swift -- score the PORTED FoundationEssentials JSON stack against
// the golden that real macOS Foundation produced.
//
//     json_runner <corpus.json> <golden.json>
//
// Built twice from identical sources: once natively with Apple's toolchain
// (`build_json_host.sh`, isolates the PORT) and once as an arm64 Mach-O to run
// under machorun (`build_json_runner.sh`, isolates the STACK).  Neither run can
// tell you what the other does, which is why both exist.
//
// ---------------------------------------------------------------------------
// TWO SCOREBOARDS, BECAUSE THE GOLDEN HAS TWO IMPLEMENTATIONS IN IT.
// `EXPECTED.md` is the pre-registration; this file implements it.
//
//   C vs B  -- the port against macOS's JSONDecoder, which is MEASURED to be
//              the same swift-foundation source.  Prediction: ZERO divergences.
//              This is a build/toolchain/stack differential and is reported as
//              one.  It is not evidence that two implementations agree.
//
//   C vs A  -- the port against JSONSerialization, Darwin's closed-source CF
//              parser.  This IS a cross-implementation comparison.  Its
//              expected-divergence set is not a guess and not a list in this
//              file: it is exactly the set of rows where A and B ALREADY
//              disagree in the golden -- a fact established before the port
//              ever ran, and read back out of the golden at run time.
//
// The alarms are the point.  Every one of them is a condition that would prove
// the classifier wrong rather than the port:
//
//   * a row where A == B and C differs from A            (must be 0)
//   * a row where A != B and C MATCHES A                 (must be 0)
//   * any C-vs-B divergence at all                       (must be 0)
//
// #72's URL oracle found its own expected-fail list was wrong -- 16 that was
// really 7 -- only because it carried a "must be 0" line.  Without one, a run
// reports a clean sweep and the classifier stays wrong.
//
// READS WITH read(2) AND DECODES FROM MEMORY.  `fm_unimplemented.c` covers 36
// C symbols machorun's libSystem does not export, 32 of which abort loudly
// naming themselves.  JSONDecoder has no business touching the file surface,
// so a stub firing during this run is a FINDING about the port's dependencies,
// and the runner is built not to be the thing that fires one.

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif
import FoundationEssentials

struct GoldenRow: Decodable {
    let id: String
    let set: String
    let origin: String
    // B -- macOS JSONDecoder
    let dec_ok: Bool
    let dec_canon: String?
    let dec_err: String?
    let dec_err_text: String?
    let enc_ok: Bool?
    let enc_out: String?
    let enc_err: String?
    // A -- macOS JSONSerialization
    let ser_ok: Bool
    let ser_canon: String?
    let ser_err: String?
    let serfrag_ok: Bool
    let serfrag_canon: String?
}

struct GoldenProbe: Decodable {
    let label: String
    let config: String
    let result: String
}

struct Golden: Decodable {
    let generated: String
    let macos: String
    let docs: [GoldenRow]
    let probes: [GoldenProbe]
}

struct Diff {
    let field: String
    let want: String
    let got: String
}

@main
struct JSONRunner {
static func main() {
    let args = CommandLine.arguments
    guard args.count == 3 else {
        errWrite("usage: json_runner <corpus.json> <golden.json>\n"); exit(2)
    }

    // The corpus and the golden are read with the decoder under test.  That is
    // a known weakness (EXPECTED.md names it), and these three checks are its
    // mitigation: a decoder broken enough to mis-read its own inputs must die
    // here rather than score itself.
    let corpus = try! JSONDecoder().decode([CorpusDoc].self, from: Data(slurp(args[1])))
    let golden = try! JSONDecoder().decode(Golden.self, from: Data(slurp(args[2])))
    guard corpus.count == golden.docs.count else {
        errWrite("corpus \(corpus.count) documents, golden \(golden.docs.count) rows -- refusing to score\n")
        exit(2)
    }
    guard !golden.probes.isEmpty else {
        errWrite("golden carries no Codable probes -- refusing to score\n"); exit(2)
    }
    print("== corpus \(corpus.count) documents, golden \(golden.docs.count) rows, \(golden.probes.count) probes")
    print("== golden generated \(golden.generated) on \(golden.macos)")

    // ---- the expected-divergence set, READ OUT OF THE GOLDEN -------------
    // Not a list in this file.  A row is an expected C-vs-A divergence iff the
    // two Apple implementations already disagreed on it, which was measured
    // and committed before json_runner.swift existed.
    func aDiffersFromB(_ g: GoldenRow) -> Bool {
        if g.ser_ok != g.dec_ok { return true }
        if g.ser_ok && g.dec_ok { return g.ser_canon != g.dec_canon }
        return false   // both failed: A's NSError and B's DecodingError are
                       // not comparable by construction, so "both rejected it"
                       // counts as agreement.
    }
    let expectedAB = golden.docs.filter(aDiffersFromB).map(\.id)
    let expectedABSet = Set(expectedAB)
    print("== \(expectedAB.count) rows where the two Apple columns already disagree (the C-vs-A expected set)")

    var scored = 0
    var digested = 0
    // C vs B
    var cbPass = 0
    var cbFail: [(GoldenRow, [Diff])] = []
    // C vs A
    var caAgree = 0
    var caExpectedDiverged: [(GoldenRow, [Diff])] = []
    var caUnexpectedDiverged: [(GoldenRow, [Diff])] = []
    var caUnexpectedlyMatched: [GoldenRow] = []
    // free side-measurement, never scored
    var errTextSame = 0, errTextTotal = 0
    var errTextDiff: [(GoldenRow, String, String)] = []

    func cmp(_ f: String, _ want: String?, _ got: String?, _ into: inout [Diff]) {
        if want != got { into.append(Diff(field: f, want: want ?? "<nil>", got: got ?? "<nil>")) }
    }

    for (i, doc) in corpus.enumerated() {
        let g = golden.docs[i]
        guard g.id == doc.id else {
            errWrite("row \(i): corpus id \(doc.id) vs golden id \(g.id) -- refusing to score\n"); exit(2)
        }
        guard let raw = base64Decode(doc.b64), raw.count == doc.bytes else {
            errWrite("row \(doc.id): corpus document did not decode to its declared \(doc.bytes) bytes -- refusing to score\n")
            exit(2)
        }
        scored += 1
        if (g.dec_canon?.hasPrefix("#") ?? false) { digested += 1 }

        let m = measure(raw)

        // ---- C vs B ------------------------------------------------------
        var d: [Diff] = []
        cmp("dec_ok", String(g.dec_ok), String(m.decOK), &d)
        if g.dec_ok && m.decOK {
            cmp("dec_canon", g.dec_canon, m.decCanon, &d)
            cmp("enc_ok", g.enc_ok.map(String.init), m.encOK.map(String.init), &d)
            if g.enc_ok == true && m.encOK == true {
                cmp("enc_out", g.enc_out, m.encOut, &d)
            } else if g.enc_ok == false && m.encOK == false {
                cmp("enc_err", g.enc_err, m.encErr, &d)
            }
        } else if !g.dec_ok && !m.decOK {
            cmp("dec_err", g.dec_err, m.decErr, &d)
            // TEXT IS RECORDED, NEVER SCORED -- P1 in EXPECTED.md.
            errTextTotal += 1
            if g.dec_err_text == m.decErrText { errTextSame += 1 }
            else { errTextDiff.append((g, g.dec_err_text ?? "<nil>", m.decErrText ?? "<nil>")) }
        }
        if d.isEmpty { cbPass += 1 } else { cbFail.append((g, d)) }

        // ---- C vs A ------------------------------------------------------
        var a: [Diff] = []
        cmp("A_parses", String(g.ser_ok), String(m.decOK), &a)
        if g.ser_ok && m.decOK { cmp("A_canon", g.ser_canon, m.decCanon, &a) }
        let expected = expectedABSet.contains(g.id)
        if a.isEmpty {
            if expected { caUnexpectedlyMatched.append(g) } else { caAgree += 1 }
        } else {
            if expected { caExpectedDiverged.append((g, a)) }
            else { caUnexpectedDiverged.append((g, a)) }
        }
    }

    // ---- Codable probes ---------------------------------------------------
    var probeByLabel = [String: String]()
    for p in golden.probes { probeByLabel[p.label] = p.result }
    var probesScored = 0, probesPass = 0
    var probeFail: [(String, String, String)] = []
    for p in PROBES {
        guard let want = probeByLabel[p.label] else {
            errWrite("probe \(p.label) is not in the golden -- refusing to score\n"); exit(2)
        }
        probesScored += 1
        let got = runProbe(p)
        if got == want { probesPass += 1 } else { probeFail.append((p.label, want, got)) }
    }
    guard probesScored == golden.probes.count else {
        errWrite("scored \(probesScored) probes but the golden has \(golden.probes.count) -- refusing\n"); exit(2)
    }

    // ---- report -----------------------------------------------------------
    // FAILING ROWS ARE PRINTED WITH THEIR DIFFS, NOT COUNTED.  A count cannot
    // show that an expected divergence diverged in the expected WAY, and that
    // is the second thing #72 found.
    if !cbFail.isEmpty {
        print("")
        print("-- C vs B (the port against macOS JSONDecoder, SAME SOURCE): \(cbFail.count) rows differ")
        for (g, ds) in cbFail.prefix(40) {
            print("   FAIL \(g.id)  [\(g.set)]  \(g.origin)")
            for x in ds { print("          \(x.field): want \(clip(x.want)) | got \(clip(x.got))") }
        }
        if cbFail.count > 40 { print("   ... \(cbFail.count - 40) more") }
    }

    // P1 SAYS TEXT IS NOT SCORED.  It does not say text is not interesting:
    // the rate turned out to be 8 of 61 on the first host run, which is the
    // measurement that justifies the rule rather than an assumption behind it.
    // Printed, not counted, so a reader can see WHAT differs.
    if !errTextDiff.isEmpty {
        print("")
        print("-- error TEXT differs on \(errTextDiff.count) of \(errTextTotal) failing rows (NOT scored -- P1):")
        for (g, w, gt) in errTextDiff.prefix(12) {
            print("   TEXT \(g.id)  \(g.origin)")
            print("          macOS: \(clip(w))")
            print("          port : \(clip(gt))")
        }
        if errTextDiff.count > 12 { print("   ... \(errTextDiff.count - 12) more") }
    }

    print("")
    print("-- the \(caExpectedDiverged.count) expected C-vs-A divergences, with their actual shapes:")
    for (g, ds) in caExpectedDiverged.prefix(30) {
        print("   XDIV \(g.id)  [\(g.set)]  \(g.origin)")
        for x in ds { print("          \(x.field): A says \(clip(x.want)) | port says \(clip(x.got))") }
    }
    if caExpectedDiverged.count > 30 { print("   ... \(caExpectedDiverged.count - 30) more") }

    if !caUnexpectedDiverged.isEmpty {
        print("")
        print("!! \(caUnexpectedDiverged.count) rows where JSONSerialization and JSONDecoder AGREED")
        print("!! and the port disagrees with both.  These are the real findings.")
        for (g, ds) in caUnexpectedDiverged.prefix(30) {
            print("   DIV  \(g.id)  [\(g.set)]  \(g.origin)")
            for x in ds { print("          \(x.field): A says \(clip(x.want)) | port says \(clip(x.got))") }
        }
    }
    if !caUnexpectedlyMatched.isEmpty {
        print("")
        print("!! \(caUnexpectedlyMatched.count) rows where the two Apple columns disagree and the port")
        print("!! matched JSONSerialization anyway.  The port compiles the JSONDecoder source,")
        print("!! so this cannot happen without the classifier being wrong.")
        for g in caUnexpectedlyMatched.prefix(20) { print("     \(g.id)  \(g.origin)") }
    }
    if !probeFail.isEmpty {
        print("")
        print("-- \(probeFail.count) Codable probes differ:")
        for (l, w, gt) in probeFail {
            print("   FAIL \(l)")
            print("          want \(clip(w))")
            print("          got  \(clip(gt))")
        }
    }

    let nonExpected = corpus.count - expectedAB.count
    print("")
    print("documents scored             \(scored) of \(corpus.count)   (\(digested) compared by digest)")
    print("")
    print("C vs B  (same source; build+stack differential)")
    print("  identical                  \(cbPass) of \(corpus.count)")
    print("  differing                  \(cbFail.count) of \(corpus.count)   (must be 0)")
    print("  error TEXT also identical  \(errTextSame) of \(errTextTotal) failing rows   (recorded, NOT scored)")
    print("")
    print("C vs A  (JSONSerialization; cross-implementation)")
    print("  agree                      \(caAgree) of \(nonExpected) rows where A and B agree")
    print("  unexpected divergence      \(caUnexpectedDiverged.count) of \(nonExpected)   (must be 0)")
    print("  expected divergence        \(caExpectedDiverged.count) of \(expectedAB.count) confirmed")
    print("  expected rows that matched \(caUnexpectedlyMatched.count) of \(expectedAB.count)   (must be 0)")
    print("")
    print("Codable probes")
    print("  identical to golden        \(probesPass) of \(probesScored)")
    print("  differing                  \(probeFail.count) of \(probesScored)   (must be 0)")

    let ok = scored == corpus.count
        && cbFail.isEmpty
        && caUnexpectedDiverged.isEmpty
        && caUnexpectedlyMatched.isEmpty
        && caExpectedDiverged.count == expectedAB.count
        && probeFail.isEmpty
        && probesScored == golden.probes.count
    print("")
    print(ok ? "VERDICT: all six conditions hold." : "VERDICT: at least one condition failed.")
    exit(ok ? 0 : 1)
}

static func clip(_ s: String) -> String {
    s.count <= 160 ? s : String(s.prefix(160)) + "…(\(s.count))"
}
}
