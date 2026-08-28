// json_probes.swift -- the CODABLE half, compiled into both the oracle and the
// runner exactly like `json_canon.swift`.
//
// WHY A SECOND SECTION EXISTS.  The value-tree corpus exercises the SCANNER
// and the container machinery, and that is most of JSON.  It does not exercise
// the part of the census that is actually largest: `Decodable` 294 uses,
// `CodingKeys` 292, `JSONDecoder` 113 -- i.e. apps decoding into their OWN
// types, with strategies set on the decoder.  A tree of `JValue` never asks
// for a missing key, never mismatches a type against a declared property,
// never converts snake_case, and never decodes a `Date`.
//
// These probes are SYNTHETIC and are denominated as their own set.  They are
// small, hand-written and labelled by the property each one tests, in the same
// spirit as `gen_synthetic.py`: the real corpus says what apps contain, this
// says what the Codable contract is.
//
// Each probe reduces to ONE string, so the scoring is the same string
// comparison the corpus rows use, and a failure names the property.

#if ORACLE_BUILD
import Foundation
#else
import FoundationEssentials
#endif

// ---- the app-side types, in the shapes apps actually declare ---------------

struct Flat: Codable {
    let id: Int
    let name: String
    let active: Bool
    let score: Double?
}

struct Nested: Codable {
    let outer: Flat
    let list: [Flat]
    let map: [String: Int]
}

struct CustomKeys: Codable {
    let identifier: String
    let count: Int
    enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case count = "n"
    }
}

struct SnakeCased: Codable {
    let userName: String
    let createdAtMs: Int
    let isURLValid: Bool
}

enum Color: String, Codable { case red, blue }

struct WithEnum: Codable { let c: Color }
struct WithDate: Codable { let when: Date }
struct WithData: Codable { let blob: Data }
struct WithURL: Codable { let u: URL }
struct WithOptionals: Codable { let a: Int?; let b: Int? }
struct WithNestedContainer: Codable {
    let top: String
    let inner: String
    enum CodingKeys: String, CodingKey { case top, nested }
    enum NestedKeys: String, CodingKey { case inner }
    init(from d: Decoder) throws {
        let c = try d.container(keyedBy: CodingKeys.self)
        top = try c.decode(String.self, forKey: .top)
        let n = try c.nestedContainer(keyedBy: NestedKeys.self, forKey: .nested)
        inner = try n.decode(String.self, forKey: .inner)
    }
    func encode(to e: Encoder) throws {
        var c = e.container(keyedBy: CodingKeys.self)
        try c.encode(top, forKey: .top)
        var n = c.nestedContainer(keyedBy: NestedKeys.self, forKey: .nested)
        try n.encode(inner, forKey: .inner)
    }
}

// ---- how a decoded value becomes one comparable string --------------------
//
// Deliberately NOT `String(describing:)`, whose output is a synthesised
// reflection format that neither implementation promises to keep stable.
// Every renderer below names the fields it reads.

func render(_ v: Flat) -> String {
    "Flat(id=\(v.id),name=\(canonString(v.name)),active=\(v.active),score=\(v.score.map { "D" + hex16($0.bitPattern) } ?? "nil"))"
}
func render(_ v: Nested) -> String {
    "Nested(outer=\(render(v.outer)),list=[\(v.list.map(render).joined(separator: ";"))],map={\(v.map.keys.sorted().map { "\($0)=\(v.map[$0]!)" }.joined(separator: ","))})"
}
func render(_ v: CustomKeys) -> String { "CustomKeys(id=\(canonString(v.identifier)),n=\(v.count))" }
func render(_ v: SnakeCased) -> String {
    "SnakeCased(userName=\(canonString(v.userName)),createdAtMs=\(v.createdAtMs),isURLValid=\(v.isURLValid))"
}
func render(_ v: WithEnum) -> String { "WithEnum(c=\(v.c.rawValue))" }
// Date renders as the BIT PATTERN of its reference-date interval: an ISO
// re-rendering would put a formatter between us and the number under test.
func render(_ v: WithDate) -> String { "WithDate(when=D\(hex16(v.when.timeIntervalSinceReferenceDate.bitPattern)))" }
func render(_ v: WithData) -> String {
    "WithData(blob=[\(v.blob.map { String($0) }.joined(separator: " "))])"
}
func render(_ v: WithURL) -> String { "WithURL(u=\(canonString(v.u.absoluteString)))" }
func render(_ v: WithOptionals) -> String {
    "WithOptionals(a=\(v.a.map(String.init) ?? "nil"),b=\(v.b.map(String.init) ?? "nil"))"
}
func render(_ v: WithNestedContainer) -> String {
    "WithNested(top=\(canonString(v.top)),inner=\(canonString(v.inner)))"
}

// ---- the probe table ------------------------------------------------------

enum ProbeType: String {
    case flat, nested, customKeys, snake, withEnum, withDate, withData, withURL
    case optionals, nestedContainer
}

enum ProbeConfig: String {
    case plain
    case snakeCase
    case dateSeconds
    case dateMillis
    case dateISO8601
    case dataBase64
}

struct Probe {
    let label: String
    let type: ProbeType
    let config: ProbeConfig
    let json: String
    /// Round-tripping is only meaningful where an encoder configuration mirrors
    /// the decoder one; probes that decode with a strategy but have no encoder
    /// counterpart set this false rather than compare an apples-to-oranges byte
    /// string.
    let roundTrip: Bool
}

let PROBES: [Probe] = [
    // shape and the ordinary happy paths
    Probe(label: "flat/all-present", type: .flat, config: .plain,
          json: #"{"id":1,"name":"a","active":true,"score":1.5}"#, roundTrip: true),
    Probe(label: "flat/optional-absent", type: .flat, config: .plain,
          json: #"{"id":1,"name":"a","active":false}"#, roundTrip: true),
    Probe(label: "flat/optional-explicit-null", type: .flat, config: .plain,
          json: #"{"id":1,"name":"a","active":false,"score":null}"#, roundTrip: true),
    Probe(label: "flat/extra-unknown-key", type: .flat, config: .plain,
          json: #"{"id":1,"name":"a","active":true,"extra":9}"#, roundTrip: false),
    Probe(label: "flat/key-missing", type: .flat, config: .plain,
          json: #"{"id":1,"active":true}"#, roundTrip: false),
    Probe(label: "flat/type-mismatch-string-for-int", type: .flat, config: .plain,
          json: #"{"id":"1","name":"a","active":true}"#, roundTrip: false),
    Probe(label: "flat/type-mismatch-int-for-bool", type: .flat, config: .plain,
          json: #"{"id":1,"name":"a","active":1}"#, roundTrip: false),
    Probe(label: "flat/null-for-nonoptional", type: .flat, config: .plain,
          json: #"{"id":null,"name":"a","active":true}"#, roundTrip: false),
    Probe(label: "flat/int-overflow", type: .flat, config: .plain,
          json: #"{"id":99999999999999999999,"name":"a","active":true}"#, roundTrip: false),
    Probe(label: "flat/int-from-double", type: .flat, config: .plain,
          json: #"{"id":1.0,"name":"a","active":true}"#, roundTrip: false),
    Probe(label: "flat/double-from-int", type: .flat, config: .plain,
          json: #"{"id":1,"name":"a","active":true,"score":2}"#, roundTrip: true),
    Probe(label: "flat/top-level-array", type: .flat, config: .plain,
          json: #"[1,2]"#, roundTrip: false),

    Probe(label: "nested/full", type: .nested, config: .plain,
          json: #"{"outer":{"id":1,"name":"o","active":true,"score":0.5},"list":[{"id":2,"name":"x","active":false}],"map":{"k":3,"j":4}}"#,
          roundTrip: true),
    Probe(label: "nested/error-deep-in-list", type: .nested, config: .plain,
          json: #"{"outer":{"id":1,"name":"o","active":true},"list":[{"id":2,"name":"x"}],"map":{}}"#,
          roundTrip: false),

    Probe(label: "codingkeys/renamed", type: .customKeys, config: .plain,
          json: #"{"id":"abc","n":7}"#, roundTrip: true),
    Probe(label: "codingkeys/original-name-rejected", type: .customKeys, config: .plain,
          json: #"{"identifier":"abc","count":7}"#, roundTrip: false),

    Probe(label: "snake/convert", type: .snake, config: .snakeCase,
          json: #"{"user_name":"bo","created_at_ms":12,"is_url_valid":true}"#, roundTrip: false),
    Probe(label: "snake/already-camel-fails", type: .snake, config: .snakeCase,
          json: #"{"userName":"bo","createdAtMs":12,"isURLValid":true}"#, roundTrip: false),
    Probe(label: "snake/leading-underscore", type: .snake, config: .snakeCase,
          json: #"{"_user_name":"bo","created_at_ms":12,"is_url_valid":true}"#, roundTrip: false),
    Probe(label: "snake/double-underscore", type: .snake, config: .snakeCase,
          json: #"{"user__name":"bo","created_at_ms":12,"is_url_valid":true}"#, roundTrip: false),

    Probe(label: "enum/valid", type: .withEnum, config: .plain, json: #"{"c":"red"}"#, roundTrip: true),
    Probe(label: "enum/unknown-case", type: .withEnum, config: .plain, json: #"{"c":"green"}"#, roundTrip: false),

    Probe(label: "date/seconds", type: .withDate, config: .dateSeconds,
          json: #"{"when":1700000000}"#, roundTrip: false),
    Probe(label: "date/seconds-fractional", type: .withDate, config: .dateSeconds,
          json: #"{"when":1700000000.25}"#, roundTrip: false),
    Probe(label: "date/seconds-negative", type: .withDate, config: .dateSeconds,
          json: #"{"when":-1}"#, roundTrip: false),
    Probe(label: "date/millis", type: .withDate, config: .dateMillis,
          json: #"{"when":1700000000123}"#, roundTrip: false),
    Probe(label: "date/iso8601", type: .withDate, config: .dateISO8601,
          json: #"{"when":"2023-11-14T22:13:20Z"}"#, roundTrip: false),
    Probe(label: "date/iso8601-offset", type: .withDate, config: .dateISO8601,
          json: #"{"when":"2023-11-14T22:13:20+01:00"}"#, roundTrip: false),
    Probe(label: "date/iso8601-fractional", type: .withDate, config: .dateISO8601,
          json: #"{"when":"2023-11-14T22:13:20.500Z"}"#, roundTrip: false),
    Probe(label: "date/iso8601-invalid", type: .withDate, config: .dateISO8601,
          json: #"{"when":"not a date"}"#, roundTrip: false),
    Probe(label: "date/iso8601-date-only", type: .withDate, config: .dateISO8601,
          json: #"{"when":"2023-11-14"}"#, roundTrip: false),

    Probe(label: "data/base64", type: .withData, config: .dataBase64,
          json: #"{"blob":"aGVsbG8="}"#, roundTrip: false),
    Probe(label: "data/base64-empty", type: .withData, config: .dataBase64,
          json: #"{"blob":""}"#, roundTrip: false),
    Probe(label: "data/base64-invalid", type: .withData, config: .dataBase64,
          json: #"{"blob":"!!!!"}"#, roundTrip: false),
    Probe(label: "data/base64-unpadded", type: .withData, config: .dataBase64,
          json: #"{"blob":"aGVsbG8"}"#, roundTrip: false),

    Probe(label: "url/absolute", type: .withURL, config: .plain,
          json: #"{"u":"https://example.com/a?b=c"}"#, roundTrip: true),
    Probe(label: "url/relative", type: .withURL, config: .plain,
          json: #"{"u":"a/b"}"#, roundTrip: true),
    Probe(label: "url/empty", type: .withURL, config: .plain,
          json: #"{"u":""}"#, roundTrip: false),

    Probe(label: "optionals/both-absent", type: .optionals, config: .plain,
          json: #"{}"#, roundTrip: true),
    Probe(label: "optionals/one-null-one-absent", type: .optionals, config: .plain,
          json: #"{"a":null}"#, roundTrip: true),

    Probe(label: "nestedcontainer/present", type: .nestedContainer, config: .plain,
          json: #"{"top":"t","nested":{"inner":"i"}}"#, roundTrip: true),
    Probe(label: "nestedcontainer/missing-nested", type: .nestedContainer, config: .plain,
          json: #"{"top":"t"}"#, roundTrip: false),
    Probe(label: "nestedcontainer/nested-wrong-type", type: .nestedContainer, config: .plain,
          json: #"{"top":"t","nested":[]}"#, roundTrip: false),
]

func decoderFor(_ c: ProbeConfig) -> JSONDecoder {
    let d = JSONDecoder()
    switch c {
    case .plain: break
    case .snakeCase: d.keyDecodingStrategy = .convertFromSnakeCase
    case .dateSeconds: d.dateDecodingStrategy = .secondsSince1970
    case .dateMillis: d.dateDecodingStrategy = .millisecondsSince1970
    case .dateISO8601: d.dateDecodingStrategy = .iso8601
    case .dataBase64: d.dataDecodingStrategy = .base64
    }
    return d
}

func encoderFor(_ c: ProbeConfig) -> JSONEncoder {
    let e = JSONEncoder()
    e.outputFormatting = [.sortedKeys]
    switch c {
    case .plain, .snakeCase: break
    case .dateSeconds: e.dateEncodingStrategy = .secondsSince1970
    case .dateMillis: e.dateEncodingStrategy = .millisecondsSince1970
    case .dateISO8601: e.dateEncodingStrategy = .iso8601
    case .dataBase64: e.dataEncodingStrategy = .base64
    }
    return e
}

/// Runs one probe and reduces it to a single comparable string.  A THROW IS A
/// RESULT, not an accident: half the probes exist to pin the error type, so
/// "keyNotFound(name)@" is as much a golden value as a decoded struct is.
func runProbe(_ p: Probe) -> String {
    let d = decoderFor(p.config)
    let data = Data(Array(p.json.utf8))
    func attempt<T: Codable>(_ t: T.Type, _ r: (T) -> String) -> String {
        do {
            let v = try d.decode(t, from: data)
            var s = "OK " + r(v)
            if p.roundTrip {
                do {
                    let out = try encoderFor(p.config).encode(v)
                    s += " | RT " + String(decoding: out, as: UTF8.self)
                } catch {
                    s += " | RT-ERR " + encErrorKind(error)
                }
            }
            return s
        } catch {
            return "ERR " + errorKind(error)
        }
    }
    switch p.type {
    case .flat: return attempt(Flat.self, render)
    case .nested: return attempt(Nested.self, render)
    case .customKeys: return attempt(CustomKeys.self, render)
    case .snake: return attempt(SnakeCased.self, render)
    case .withEnum: return attempt(WithEnum.self, render)
    case .withDate: return attempt(WithDate.self, render)
    case .withData: return attempt(WithData.self, render)
    case .withURL: return attempt(WithURL.self, render)
    case .optionals: return attempt(WithOptionals.self, render)
    case .nestedContainer: return attempt(WithNestedContainer.self, render)
    }
}
