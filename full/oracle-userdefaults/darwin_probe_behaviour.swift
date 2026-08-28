// Oracle probe: what does REAL Darwin Foundation's UserDefaults actually DO?
//
// Scoping instrument, not the oracle itself. Every row is a BEHAVIOUR question
// whose answer decides an implementation detail -- coercion tables, NSNumber
// folding, absence semantics, suite isolation, register() layering.
//
// Run as:  swift probe.swift <suite-name> [phase]
//   phase 1 (default) = write + read back in one process
//   phase 2           = read only, to measure what survived a process restart
//
// Everything goes into a throwaway suite so the user's own defaults are never
// touched, and phase 3 removes it.

import Foundation

let args = CommandLine.arguments
let suiteName = args.count > 1 ? args[1] : "com.example.udprobe.scratch"
let phase = args.count > 2 ? Int(args[2]) ?? 1 : 1

guard let d = UserDefaults(suiteName: suiteName) else {
    print("FATAL: UserDefaults(suiteName:) returned nil")
    exit(1)
}

func show(_ label: String, _ v: Any?) {
    if let v = v {
        let t = String(describing: type(of: v))
        print("  \(label.padding(toLength: 46, withPad: " ", startingAt: 0)) \(t) = \(v)")
    } else {
        print("  \(label.padding(toLength: 46, withPad: " ", startingAt: 0)) nil")
    }
}

if phase == 3 {
    d.removePersistentDomain(forName: suiteName)
    print("removed persistent domain \(suiteName)")
    exit(0)
}

if phase == 1 {
    // ---------------------------------------------------------------- writes
    d.set("hello", forKey: "k_string")
    d.set(42, forKey: "k_int")
    d.set(true, forKey: "k_bool_true")
    d.set(false, forKey: "k_bool_false")
    d.set(3.5, forKey: "k_double")
    d.set(Float(1.5), forKey: "k_float")
    d.set(Data([0xde, 0xad, 0xbe, 0xef]), forKey: "k_data")
    d.set(Date(timeIntervalSince1970: 1000), forKey: "k_date")
    d.set([1, 2, 3], forKey: "k_array_int")
    d.set(["a", "b"], forKey: "k_array_string")
    d.set(["x": 1, "y": "two"] as [String: Any], forKey: "k_dict")
    d.set(URL(fileURLWithPath: "/tmp/x"), forKey: "k_url_file")
    d.set(URL(string: "https://example.com/a?b=c"), forKey: "k_url_http")
    // strings that LOOK like other types -- the coercion table's real subjects
    d.set("123", forKey: "k_string_numeric")
    d.set("3.75", forKey: "k_string_double")
    d.set("YES", forKey: "k_string_YES")
    d.set("true", forKey: "k_string_true")
    d.set("no", forKey: "k_string_no")
    d.set("banana", forKey: "k_string_nonnumeric")
    d.set(0, forKey: "k_int_zero")
    d.set(1, forKey: "k_int_one")
    d.set(2, forKey: "k_int_two")
    d.set(-1, forKey: "k_int_neg")
    d.set(Int.max, forKey: "k_int_max")
    d.set(Int.min, forKey: "k_int_min")
    d.set(NSNumber(value: 1), forKey: "k_nsnumber_one")
    d.set(NSNumber(value: true), forKey: "k_nsnumber_true")
    d.set(1.0, forKey: "k_double_whole")
    d.set("", forKey: "k_empty_string")
    d.set([] as [Any], forKey: "k_empty_array")
    d.synchronize()
}

print("=== PHASE \(phase) · suite \(suiteName) ===")

// ------------------------------------------------------- 1. type round-trips
print("\n[1] object(forKey:) -- the DYNAMIC TYPE the value comes back as")
for k in ["k_string", "k_int", "k_bool_true", "k_bool_false", "k_double",
          "k_float", "k_data", "k_date", "k_array_int", "k_dict",
          "k_url_file", "k_url_http", "k_int_zero", "k_int_one",
          "k_nsnumber_one", "k_nsnumber_true", "k_double_whole"] {
    show(k, d.object(forKey: k))
}

// ------------------------------------------------- 2. THE COERCION TABLE
print("\n[2] COERCION -- every typed getter over every stored type")
let keys = ["k_string", "k_int", "k_bool_true", "k_bool_false", "k_double",
            "k_string_numeric", "k_string_double", "k_string_YES",
            "k_string_true", "k_string_no", "k_string_nonnumeric",
            "k_int_zero", "k_int_two", "k_int_neg", "k_data", "k_date",
            "k_array_int", "k_dict", "k_empty_string", "k_absent"]
print("  key                      string        integer   double     bool   array? dict? data?")
for k in keys {
    let s = d.string(forKey: k).map { "\"\($0)\"" } ?? "nil"
    let i = d.integer(forKey: k)
    let db = d.double(forKey: k)
    let b = d.bool(forKey: k)
    let a = d.array(forKey: k) != nil
    let dd = d.dictionary(forKey: k) != nil
    let da = d.data(forKey: k) != nil
    print("  \(k.padding(toLength: 22, withPad: " ", startingAt: 0)) "
        + "\(s.padding(toLength: 14, withPad: " ", startingAt: 0))"
        + "\(String(i).padding(toLength: 9, withPad: " ", startingAt: 0))"
        + "\(String(format: "%-10.4g", db))"
        + "\(String(b).padding(toLength: 8, withPad: " ", startingAt: 0))"
        + "\(a ? "Y" : ".")      \(dd ? "Y" : ".")     \(da ? "Y" : ".")")
}

// ---------------------------------------------------- 3. ABSENCE IS AN ANSWER
print("\n[3] ABSENT KEY -- absence is an answer, and the answers differ per getter")
show("object(forKey: absent)", d.object(forKey: "k_absent"))
show("string(forKey: absent)", d.string(forKey: "k_absent"))
show("integer(forKey: absent)", d.integer(forKey: "k_absent"))
show("double(forKey: absent)", d.double(forKey: "k_absent"))
show("float(forKey: absent)", d.float(forKey: "k_absent"))
show("bool(forKey: absent)", d.bool(forKey: "k_absent"))
show("array(forKey: absent)", d.array(forKey: "k_absent"))
show("data(forKey: absent)", d.data(forKey: "k_absent"))
show("url(forKey: absent)", d.url(forKey: "k_absent"))
show("stringArray(forKey: absent)", d.stringArray(forKey: "k_absent"))

// ------------------------------------------------------------- 4. URL round-trip
print("\n[4] URL -- set(URL) stores WHAT, and url(forKey:) returns WHAT")
show("object(k_url_file)", d.object(forKey: "k_url_file"))
show("url(k_url_file)", d.url(forKey: "k_url_file"))
show("object(k_url_http)", d.object(forKey: "k_url_http"))
show("url(k_url_http)", d.url(forKey: "k_url_http"))
show("url(k_string) -- a plain string read as URL", d.url(forKey: "k_string"))
show("url(k_int)", d.url(forKey: "k_int"))

// -------------------------------------------------------- 5. register layering
print("\n[5] register(defaults:) LAYERING")
d.register(defaults: ["reg_only": "from-register",
                      "k_string": "register-should-LOSE",
                      "reg_int": 7])
show("reg_only (registered, never set)", d.object(forKey: "reg_only"))
show("k_string (set AND registered)", d.object(forKey: "k_string"))
show("reg_int integer(forKey:)", d.integer(forKey: "reg_int"))
let drAll = d.dictionaryRepresentation()
print("  dictionaryRepresentation() contains reg_only:  \(drAll["reg_only"] != nil)")
print("  dictionaryRepresentation() count:              \(drAll.count)")
let pd = d.persistentDomain(forName: suiteName) ?? [:]
print("  persistentDomain contains reg_only:            \(pd["reg_only"] != nil)   (registered values are NOT persistent)")
print("  persistentDomain count:                        \(pd.count)")

// ------------------------------------------------------------ 6. removeObject
print("\n[6] removeObject -- does it fall back to the registered value?")
d.set("set-value", forKey: "reg_only")
show("after set", d.object(forKey: "reg_only"))
d.removeObject(forKey: "reg_only")
show("after removeObject", d.object(forKey: "reg_only"))
d.removeObject(forKey: "never_existed")
print("  removeObject on an absent key: did not trap")

// -------------------------------------------------------- 7. suite isolation
print("\n[7] SUITE ISOLATION")
let other = UserDefaults(suiteName: suiteName + ".other")!
other.set("other-value", forKey: "k_string")
show("this suite   k_string", d.object(forKey: "k_string"))
show("other suite  k_string", other.object(forKey: "k_string"))
show("standard     k_string (must be nil)", UserDefaults.standard.object(forKey: "k_string"))
print("  UserDefaults(suiteName: nil)  is standard?  "
    + "\(UserDefaults(suiteName: nil) === UserDefaults.standard)")
print("  two UserDefaults(suiteName: same) identical? "
    + "\(UserDefaults(suiteName: suiteName) === d)")
other.removePersistentDomain(forName: suiteName + ".other")

// ------------------------------------------------------ 8. what set() REFUSES
print("\n[8] WHAT set() ACCEPTS AND REFUSES (non-plist values)")
// Darwin raises; we only record what is documented-legal here and note the rest
d.set(["nested": ["deep": [1, 2, Date(timeIntervalSince1970: 5)]]] as [String: Any],
      forKey: "k_nested")
show("k_nested round-trip", d.object(forKey: "k_nested"))

// --------------------------------------------------------- 9. the storage file
print("\n[9] STORAGE")
let home = FileManager.default.homeDirectoryForCurrentUser
let plist = home.appendingPathComponent("Library/Preferences/\(suiteName).plist")
print("  expected path: \(plist.path)")
print("  exists:        \(FileManager.default.fileExists(atPath: plist.path))")
if let dta = try? Data(contentsOf: plist) {
    let magic = dta.prefix(8)
    let isB = dta.prefix(6).elementsEqual("bplist".utf8)
    print("  size:          \(dta.count) bytes")
    print("  magic:         \(magic.map { String(format: "%02x", $0) }.joined(separator: " "))")
    print("  FORMAT:        \(isB ? "BINARY plist (bplist00)" : "not binary -- probably XML")")
}
print("  synchronize() -> \(d.synchronize())")
