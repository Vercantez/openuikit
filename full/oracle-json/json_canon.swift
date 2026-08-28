// json_canon.swift -- ONE definition of "equal", compiled into BOTH the oracle
// and the runner.
//
// The oracle (`json_oracle.swift`, macOS, real Foundation) and the runner
// (`json_runner.swift`, the ported FoundationEssentials) must agree on what a
// decoded document IS before they can disagree about a document.  Sharing the
// source rather than the prose is the point: a canonicalisation described in a
// README and implemented twice is two canonicalisations.
//
// Build selects the module, and nothing else differs:
//     -D ORACLE_BUILD   -> import Foundation          (the golden)
//     (default)         -> import FoundationEssentials (the port)
//
// ---------------------------------------------------------------------------
// WHAT "EQUAL" MEANS.  Every rule here is a decision that could have gone the
// other way, so each one is stated:
//
//   null            N
//   bool            T / F
//   Int64           I<decimal>            e.g. I-42
//   UInt64          U<decimal>            only for values above Int64.max
//   Double          D<16 hex digits>      the RAW BIT PATTERN, not a rendering
//   string          S<scalar count>:<escaped scalars>
//   array           [ e , e , e ]
//   object          { K=V , K=V }         keys sorted by their UTF-8 BYTES
//
// * Doubles compare by `bitPattern`, so `0.0` and `-0.0` are DIFFERENT and no
//   float formatting difference can ever be mistaken for a parse difference.
//   A shortest-round-trip rendering would have hidden -0 and made a
//   formatting change look like a decoding change.
//
// * The scalar type is part of the value.  `1` and `1.0` are NOT equal here,
//   because "which Swift type did this JSON number become" is precisely the
//   thing two JSON implementations most often disagree about, and folding them
//   together would erase the finding.
//
// * Object keys are sorted by UTF-8 bytes, not by `String <`, so the ordering
//   is a byte fact rather than a Unicode-collation fact.
//
// * DUPLICATE KEYS ARE ALREADY GONE by the time we canonicalise -- the decoder
//   collapsed them.  Which value survived is exactly what the canon records,
//   and that is the observable we want.
//
// * KNOWN AND ACCEPTED: Swift `String` equality is canonical equivalence, so
//   two object keys that are canonically equivalent but differently composed
//   (U+00E9 vs U+0065 U+0301) collapse into one entry.  Both sides are Swift
//   and both do this, so it cancels; it is recorded here because it means the
//   canon is a statement about Swift's string model, not about JSON's.

#if ORACLE_BUILD
import Foundation
#else
import FoundationEssentials
#endif

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

// ---------------------------------------------------------------------------
// I/O, deliberately at the level of read(2)/write(2).
//
// `Data(contentsOf:)` and `FileHandle` pull in the file surface, which
// machorun's libSystem does not export (copyfile/removefile/fts/xattr) and
// which `fm_unimplemented.c` covers with 32 loud aborts.  Touching them would
// make the runner die for reasons that have nothing to do with JSON -- and a
// stub firing during a JSON run is itself a finding, so the runner must not
// be the thing that fires it.
// ---------------------------------------------------------------------------
func errWrite(_ s: String) {
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

func slurp(_ path: String) -> [UInt8] {
    let fd = open(path, O_RDONLY)
    guard fd >= 0 else { errWrite("cannot open \(path)\n"); exit(2) }
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

// Hand-rolled, in both binaries, for the same reason the reads are raw: the
// corpus loader must not exercise anything under test.  `Data(base64Encoded:)`
// is part of the port; using it here would mean a base64 defect showed up as
// a JSON result.
func base64Decode(_ s: String) -> [UInt8]? {
    var table = [Int8](repeating: -1, count: 256)
    let alpha = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".utf8)
    for (i, c) in alpha.enumerated() { table[Int(c)] = Int8(i) }
    var out = [UInt8]()
    var acc = 0
    var bits = 0
    for c in s.utf8 {
        if c == UInt8(ascii: "=") { break }
        if c == UInt8(ascii: "\n") || c == UInt8(ascii: "\r") { continue }
        let v = table[Int(c)]
        if v < 0 { return nil }
        acc = (acc << 6) | Int(v)
        bits += 6
        if bits >= 8 {
            bits -= 8
            out.append(UInt8((acc >> bits) & 0xff))
        }
    }
    return out
}

// ---------------------------------------------------------------------------
// The corpus row.  `b64` is the document; everything else is provenance and is
// never scored.
// ---------------------------------------------------------------------------
struct CorpusDoc: Decodable {
    let id: String
    let set: String
    let kind: String
    let origin: String
    let bytes: Int
    let b64: String
}

// ---------------------------------------------------------------------------
// The value tree.
// ---------------------------------------------------------------------------
struct AnyKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    init?(stringValue: String) { self.stringValue = stringValue; self.intValue = nil }
    init?(intValue: Int) { self.stringValue = String(intValue); self.intValue = intValue }
}

indirect enum JValue {
    case null
    case bool(Bool)
    case int(Int64)
    case uint(UInt64)
    case double(Double)
    case string(String)
    case array([JValue])
    case object([String: JValue])
}

extension JValue: Decodable {
    // ORDER IS THE CLASSIFIER, and it is the same code on both sides, so what
    // this measures is whether the two decoders answer the same way to the
    // same sequence of questions -- not whether one of them guessed a type.
    //
    // Bool before Int64 because a JSON `true` must not become 1.  Int64 before
    // UInt64 before Double because that is the widening order that keeps `1`
    // an integer and `1.0` a double.  The final `decode(String.self)` is NOT
    // wrapped in `try?`: something has to be allowed to throw, or a document
    // that cannot be decoded at all would silently become a string.
    init(from decoder: Decoder) throws {
        if let c = try? decoder.container(keyedBy: AnyKey.self) {
            var d = [String: JValue]()
            for k in c.allKeys { d[k.stringValue] = try c.decode(JValue.self, forKey: k) }
            self = .object(d); return
        }
        if var u = try? decoder.unkeyedContainer() {
            var a = [JValue]()
            while !u.isAtEnd { a.append(try u.decode(JValue.self)) }
            self = .array(a); return
        }
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null; return }
        if let b = try? c.decode(Bool.self) { self = .bool(b); return }
        if let i = try? c.decode(Int64.self) { self = .int(i); return }
        if let u = try? c.decode(UInt64.self) { self = .uint(u); return }
        if let d = try? c.decode(Double.self) { self = .double(d); return }
        self = .string(try c.decode(String.self))
    }
}

extension JValue: Encodable {
    func encode(to encoder: Encoder) throws {
        switch self {
        case .object(let d):
            var c = encoder.container(keyedBy: AnyKey.self)
            for (k, v) in d { try c.encode(v, forKey: AnyKey(stringValue: k)!) }
        case .array(let a):
            var c = encoder.unkeyedContainer()
            for v in a { try c.encode(v) }
        default:
            var c = encoder.singleValueContainer()
            switch self {
            case .null: try c.encodeNil()
            case .bool(let b): try c.encode(b)
            case .int(let i): try c.encode(i)
            case .uint(let u): try c.encode(u)
            case .double(let d): try c.encode(d)
            case .string(let s): try c.encode(s)
            default: break
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Canonical rendering.
// ---------------------------------------------------------------------------
private let hexDigits = Array("0123456789abcdef")

func hex16(_ v: UInt64) -> String {
    var s = ""
    var i = 60
    while i >= 0 { s.append(hexDigits[Int((v >> UInt64(i)) & 0xf)]); i -= 4 }
    return s
}

func hexMin(_ v: UInt32) -> String {
    if v == 0 { return "0" }
    var s = ""
    var x = v
    while x > 0 { s.append(hexDigits[Int(x & 0xf)]); x >>= 4 }
    return String(s.reversed())
}

/// Escapes the seven characters that carry structure in this canon, plus
/// everything outside printable ASCII.  The scalar COUNT is a prefix, so two
/// different strings cannot render alike even if the escaping were ambiguous.
func canonString(_ s: String) -> String {
    var out = "S"
    var n = 0
    var body = ""
    for u in s.unicodeScalars {
        n += 1
        let v = u.value
        if v >= 0x20 && v <= 0x7e {
            switch u {
            case "\\", "{", "}", "[", "]", ",", "=":
                body += "\\u{" + hexMin(v) + "}"
            default:
                body.unicodeScalars.append(u)
            }
        } else {
            body += "\\u{" + hexMin(v) + "}"
        }
    }
    out += String(n) + ":" + body
    return out
}

// ---------------------------------------------------------------------------
// OVERSIZE VALUES ARE DIGESTED, AND THIS IS A DELIBERATE WEAKENING, so it is
// bounded, named and reported rather than hidden.
//
// A handful of real API fixtures canonicalise to 50 KB of text, and three
// columns of that per row made the golden 9.7 MB -- four times the entire
// repository.  Anything longer than DIGEST_ABOVE characters is stored as
// `#<length>:<fnv1a64>` instead of its text.
//
// What it costs: a failing digested row can report its LENGTH and its HASH,
// not the first differing character.  What it does not cost: detection.  Both
// sides compute the same reduction over the same alphabet, and the length is
// part of the token, so a difference still fails the row.
//
// FNV-1a and not SHA-256 on purpose: it is six lines that can be read and
// checked by eye, whereas a hand-rolled SHA-256 in the runner would be a new
// piece of unverified code sitting between the measurement and the answer.
// It is a difference detector here, never a security claim.
let DIGEST_ABOVE = 4096

func fnv1a64(_ s: String) -> UInt64 {
    var h: UInt64 = 0xcbf2_9ce4_8422_2325
    for b in s.utf8 {
        h ^= UInt64(b)
        h = h &* 0x1000_0000_01b3
    }
    return h
}

func digestIfLarge(_ s: String) -> String {
    if s.utf8.count <= DIGEST_ABOVE { return s }
    return "#\(s.utf8.count):" + hex16(fnv1a64(s))
}

func canon(_ v: JValue) -> String {
    switch v {
    case .null: return "N"
    case .bool(let b): return b ? "T" : "F"
    case .int(let i): return "I\(i)"
    case .uint(let u): return "U\(u)"
    case .double(let d): return "D" + hex16(d.bitPattern)
    case .string(let s): return canonString(s)
    case .array(let a): return "[" + a.map(canon).joined(separator: ",") + "]"
    case .object(let d):
        let keys = d.keys.sorted { Array($0.utf8).lexicographicallyPrecedes(Array($1.utf8)) }
        return "{" + keys.map { canonString($0) + "=" + canon(d[$0]!) }.joined(separator: ",") + "}"
    }
}

// ---------------------------------------------------------------------------
// Error classification.
//
// PRE-REGISTERED RULE, and the single most important one in this file:
// COMPARE THE ERROR TYPE AND ITS CODING PATH, NEVER ITS TEXT.  Two builds of
// the same parser are entitled to word "Unexpected end of file" differently;
// they are not entitled to disagree about whether the failure was a
// dataCorrupted or a typeMismatch, or about where in the document it was.
// The text is recorded in a separate field and reported as a free
// side-measurement, never scored.
// ---------------------------------------------------------------------------
func codingPathString(_ p: [CodingKey]) -> String {
    if p.isEmpty { return "" }
    return p.map { k in k.intValue.map { "[\($0)]" } ?? "." + k.stringValue }.joined()
}

func errorKind(_ e: Error) -> String {
    guard let d = e as? DecodingError else { return "other" }
    switch d {
    case .dataCorrupted(let c): return "dataCorrupted@" + codingPathString(c.codingPath)
    case .keyNotFound(let k, let c): return "keyNotFound(\(k.stringValue))@" + codingPathString(c.codingPath)
    case .typeMismatch(_, let c): return "typeMismatch@" + codingPathString(c.codingPath)
    case .valueNotFound(_, let c): return "valueNotFound@" + codingPathString(c.codingPath)
    @unknown default: return "unknownDecodingError"
    }
}

func encErrorKind(_ e: Error) -> String {
    guard let d = e as? EncodingError else { return "other" }
    switch d {
    case .invalidValue(_, let c): return "invalidValue@" + codingPathString(c.codingPath)
    @unknown default: return "unknownEncodingError"
    }
}

// ---------------------------------------------------------------------------
// The one measurement, run identically on both sides.
// ---------------------------------------------------------------------------
struct Outcome {
    var decOK = false
    var decCanon: String? = nil
    var decErr: String? = nil
    var decErrText: String? = nil
    var encOK: Bool? = nil
    var encOut: String? = nil
    var encErr: String? = nil
}

func measure(_ bytes: [UInt8]) -> Outcome {
    var o = Outcome()
    let data = Data(bytes)
    let dec = JSONDecoder()
    let tree: JValue
    do {
        tree = try dec.decode(JValue.self, from: data)
    } catch {
        o.decOK = false
        o.decErr = errorKind(error)
        o.decErrText = "\(error)"
        return o
    }
    o.decOK = true
    o.decCanon = digestIfLarge(canon(tree))

    // Round-trip.  `.sortedKeys` because an unordered dictionary would
    // otherwise make the output nondeterministic and the comparison
    // meaningless; slashes are left escaped (the default) because that is one
    // of the few places JSON writers visibly differ.
    let enc = JSONEncoder()
    enc.outputFormatting = [.sortedKeys]
    do {
        let out = try enc.encode(tree)
        o.encOK = true
        o.encOut = digestIfLarge(String(decoding: out, as: UTF8.self))
    } catch {
        o.encOK = false
        o.encErr = encErrorKind(error)
    }
    return o
}
