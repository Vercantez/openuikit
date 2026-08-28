// ResolutionProbe -- ask REAL UIKit which variant it loads, and report which
// candidate that was.
//
// Runs as an installed .app in the iOS simulator (Tools/oracle2 precedent),
// because that is the only vehicle that can express the SCALE axis: measured,
// `displayScale` in a UITraitCollection does not drive catalog scale selection
// on Mac Catalyst or in a `simctl spawn`ed process — UIKit takes the scale from
// the screen, and neither of those has one. See EXPECTED_RESOLUTION.md.
//
// The probe is deliberately DUMB. It does not know the resolution algorithm and
// does not compare anything: it reports, per (asset, idiom, appearance), which
// candidate payload UIKit's returned image is byte-identical to. The algorithm
// under test lives in `xcassets_tool.py resolve`, and the comparison lives in
// `score_resolution.py` on the host — so the thing being measured is never in
// the same process as the measurement.
//
// Output: <Documents>/resolution_<scale>x_<idiomname>.json

import UIKit
import CryptoKit

let docs = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]

func fail(_ m: String) -> Never {
    FileHandle.standardError.write(Data(("PROBE FAILED: " + m + "\n").utf8))
    try? Data(("PROBE FAILED: " + m).utf8).write(to: URL(fileURLWithPath: docs + "/PROBE_FAILED"))
    exit(2)
}

// ---------------------------------------------------------------------------
// ONE decode pipeline, used for the returned image and for every candidate.
// Any difference between the two sides would otherwise be a difference between
// two pipelines rather than a difference between two choices.
// ---------------------------------------------------------------------------
/// Decode to raw sRGB premultiplied bytes at the image's own pixel size.
/// Returned alongside the dimensions because dimensions are themselves a
/// strong signal: for the scale axis, 24x24 vs 48x48 IS the answer.
func bitmapBytes(_ cg: CGImage) -> (w: Int, h: Int, bytes: [UInt8])? {
    let w = cg.width, h = cg.height
    var buf = [UInt8](repeating: 0, count: w * h * 4)
    guard let cs = CGColorSpace(name: CGColorSpace.sRGB),
          let ctx = CGContext(data: &buf, width: w, height: h, bitsPerComponent: 8,
                              bytesPerRow: w * 4, space: cs,
                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    else { return nil }
    ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
    return (w, h, buf)
}

/// Mean absolute difference per byte, 0...255.  Only defined for equal
/// dimensions; different dimensions are reported as a dimension mismatch
/// rather than as a large distance, so the two signals stay separable.
func mad(_ a: (w: Int, h: Int, bytes: [UInt8]), _ b: (w: Int, h: Int, bytes: [UInt8])) -> Double? {
    guard a.w == b.w, a.h == b.h, a.bytes.count == b.bytes.count else { return nil }
    var sum = 0
    for i in 0..<a.bytes.count { sum += abs(Int(a.bytes[i]) - Int(b.bytes[i])) }
    return Double(sum) / Double(a.bytes.count)
}

func bitmapHash(_ cg: CGImage) -> String {
    let w = cg.width, h = cg.height
    var buf = [UInt8](repeating: 0, count: w * h * 4)
    guard let cs = CGColorSpace(name: CGColorSpace.sRGB),
          let ctx = CGContext(data: &buf, width: w, height: h, bitsPerComponent: 8,
                              bytesPerRow: w * 4, space: cs,
                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    else { return "CTXFAIL" }
    ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
    let d = SHA256.hash(data: Data(buf)).compactMap { String(format: "%02x", $0) }.joined()
    return "\(w)x\(h):" + String(d.prefix(24))
}

func fileHash(_ path: String) -> String? {
    guard let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
          let cg = CGImageSourceCreateImageAtIndex(src, 0, nil) else { return nil }
    return bitmapHash(cg)
}

func fileBytes(_ path: String) -> (w: Int, h: Int, bytes: [UInt8])? {
    guard let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
          let cg = CGImageSourceCreateImageAtIndex(src, 0, nil) else { return nil }
    return bitmapBytes(cg)
}

func traits(_ idiom: UIUserInterfaceIdiom, _ style: UIUserInterfaceStyle) -> UITraitCollection {
    // NOTE: displayScale is deliberately NOT set. It does not work (measured,
    // five routes), and setting it would suggest to a reader that the scale
    // axis is coming from here rather than from the device.
    UITraitCollection { m in
        m.userInterfaceIdiom = idiom
        m.userInterfaceStyle = style
    }
}

struct Row: Decodable {
    struct Candidate: Decodable {
        let sha256: String?
        let file: String?
        let filename: String?
        let idiom: String
        let appearance: String
        let scale: Int?
        let native: [Double]?
        let color_space: String?
    }
    let asset: String
    let kind: String
    let shapes: [String]
    let candidates: [Candidate]
}

let bundleDir = Bundle.main.bundlePath
guard let gridData = FileManager.default.contents(atPath: bundleDir + "/grid.json"),
      let grid = try? JSONDecoder().decode([String: [Row]].self, from: gridData),
      let rows = grid["rows"], !rows.isEmpty
else { fail("no grid.json, or it holds no rows") }

let screenScale = UIScreen.main.scale
let deviceIdiom = UIDevice.current.userInterfaceIdiom

// ---------------------------------------------------------------------------
// INSTRUMENT CHECK 1, before anything is resolved: within each asset, every
// candidate must hash differently. Two identical candidates make every
// comparison on that asset pass no matter what UIKit does. #78's
// renderDiscriminates, applied to pixels.
// ---------------------------------------------------------------------------
var candHash: [String: [String: String]] = [:]   // asset -> sha256 -> hash
var candBytes: [String: [String: (w: Int, h: Int, bytes: [UInt8])]] = [:]
var undecidable: [String: String] = [:]
/// Pairwise separation between same-size candidates of one asset, reported so
/// the HOST can set a threshold against measured data instead of a guess.
var candSeparation: [String: [[String: Any]]] = [:]
for r in rows where r.kind != "colour" {
    var byHash: [String: String] = [:]
    var m: [String: String] = [:]
    var b: [String: (w: Int, h: Int, bytes: [UInt8])] = [:]
    for c in r.candidates {
        guard let sha = c.sha256, let f = c.file else { continue }
        guard let h = fileHash(bundleDir + "/Candidates/" + f),
              let bb = fileBytes(bundleDir + "/Candidates/" + f) else {
            undecidable[r.asset] = "candidate \(c.filename ?? f) did not decode"
            continue
        }
        m[sha] = h
        b[sha] = bb
        if let other = byHash[h], other != sha {
            undecidable[r.asset] =
                "two candidates decode identically (\(c.filename ?? sha) and the one at \(other))"
        }
        byHash[h] = sha
    }
    candHash[r.asset] = m
    candBytes[r.asset] = b
    // Same-size pairs are the ones a distance has to separate.  Different-size
    // pairs are separated by their dimensions and need no threshold at all.
    var seps: [[String: Any]] = []
    let keys = Array(b.keys).sorted()
    for i in 0..<keys.count {
        for j in (i+1)..<keys.count {
            if let d = mad(b[keys[i]]!, b[keys[j]]!) {
                seps.append(["a": keys[i], "b": keys[j], "mad": d])
            }
        }
    }
    candSeparation[r.asset] = seps
}

// ---------------------------------------------------------------------------
var out: [[String: Any]] = []

for r in rows {
    let askIdioms: [(UIUserInterfaceIdiom, String)] =
        r.shapes.contains("idiom-specific")
        ? [(.phone, "iphone"), (.pad, "ipad"), (.unspecified, "unspecified")]
        : [(deviceIdiom, deviceIdiom == .pad ? "ipad" : "iphone")]
    let askStyles: [(UIUserInterfaceStyle, String)] = [(.light, "light"), (.dark, "dark")]

    for (idiom, iname) in askIdioms {
        for (style, sname) in askStyles {
            var rec: [String: Any] = [
                "asset": r.asset, "kind": r.kind,
                "ask_idiom": iname, "ask_appearance": sname,
                "device_scale": Double(screenScale),
                "device_idiom": deviceIdiom == .pad ? "ipad" : "iphone",
            ]
            let tc = traits(idiom, style)

            if r.kind == "colour" {
                if let col = UIColor(named: r.asset, in: .main, compatibleWith: tc) {
                    let resolved = col.resolvedColor(with: tc)
                    var cr: CGFloat = 0, cg: CGFloat = 0, cb: CGFloat = 0, ca: CGFloat = 0
                    if resolved.getRed(&cr, green: &cg, blue: &cb, alpha: &ca) {
                        rec["components"] = [Double(cr), Double(cg), Double(cb), Double(ca)]
                    }
                    let space = resolved.cgColor.colorSpace?.name as String? ?? "unknown"
                    rec["color_space"] = space
                } else {
                    rec["error"] = "UIColor(named:) returned nil"
                }
                out.append(rec); continue
            }

            guard let img = UIImage(named: r.asset, in: .main, compatibleWith: tc),
                  let cg = img.cgImage else {
                rec["error"] = "UIImage(named:) returned nil or has no CGImage"
                out.append(rec); continue
            }
            let h = bitmapHash(cg)
            rec["image_scale"] = Double(img.scale)
            rec["hash"] = h
            // EXACT match first, because when it holds it needs no threshold.
            if let m = candHash[r.asset], let sha = m.first(where: { $0.value == h })?.key {
                rec["matched_sha256"] = sha
                rec["match_kind"] = "exact"
            } else {
                rec["matched_sha256"] = NSNull()
            }
            // DISTANCE TO EVERY CANDIDATE, always, exact match or not.  actool
            // re-encodes: measured, UIKit hands back an image with the right
            // DIMENSIONS whose bytes differ slightly from the source file, so
            // exact equality identifies only a minority of real assets.  The
            // probe therefore reports the whole distance vector and lets the
            // host choose the nearest and check the margin -- the decision
            // stays where it can be audited, and the threshold is set against
            // measured separations rather than guessed here.
            if let bytes = bitmapBytes(cg), let cands = candBytes[r.asset] {
                var dists: [[String: Any]] = []
                for (sha, cb) in cands {
                    if let d = mad(bytes, cb) {
                        dists.append(["sha256": sha, "mad": d, "dims_match": true])
                    } else {
                        dists.append(["sha256": sha, "mad": NSNull(), "dims_match": false,
                                      "cand_w": cb.w, "cand_h": cb.h])
                    }
                }
                rec["distances"] = dists
                rec["width"] = bytes.w
                rec["height"] = bytes.h
            }
            out.append(rec)
        }
    }
}

let payload: [String: Any] = [
    "device_scale": Double(screenScale),
    "device_idiom": deviceIdiom == .pad ? "ipad" : "iphone",
    "rows_in_grid": rows.count,
    "undecidable": undecidable,
    "candidate_separation": candSeparation,
    "results": out,
]
let name = String(format: "resolution_%.0fx_%@.json", Double(screenScale),
                  deviceIdiom == .pad ? "ipad" : "iphone")
guard let data = try? JSONSerialization.data(withJSONObject: payload,
                                             options: [.prettyPrinted, .sortedKeys])
else { fail("could not serialise results") }
try? data.write(to: URL(fileURLWithPath: docs + "/" + name))
print("wrote \(name): \(out.count) results, \(undecidable.count) undecidable assets, "
      + "scale \(screenScale), idiom \(deviceIdiom.rawValue)")
exit(0)
