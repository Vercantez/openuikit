// Focused probe: the string->number/bool coercion rules, which is where the
// scoping probe found real Foundation and swift-corelibs-foundation DISAGREE.
//
// corelibs' UserDefaults.integer(forKey:) does `NSString(string: v).integerValue`
// and bool(forKey:) does `NSString(string: v).boolValue`. Phase 1 showed Darwin
// returning 0 for integer("3.75") where integerValue gives 3, and false for
// bool("123") where boolValue gives true. Both getters are therefore NOT the
// NSString conversions corelibs uses. This measures the real rule.
//
// The NSString values are printed alongside so the divergence is a DIFF, not a
// claim -- the same process, the same strings, both answers.

import Foundation

let suite = "com.example.udprobe.coerce"
let d = UserDefaults(suiteName: suite)!

let strings = ["123", "0123", " 123", "123 ", "12.9", "3.75", "-7", "+7",
               "0", "1", "2", "-1", "0.0", "1.0", "1e3", "0x10",
               "YES", "Yes", "yes", "Y", "y", "TRUE", "True", "true", "T", "t",
               "NO", "no", "N", "n", "FALSE", "false", "F", "f",
               "banana", "", " ", "1banana", "banana1",
               "9223372036854775807", "9223372036854775808", "-0"]

for (i, s) in strings.enumerated() { d.set(s, forKey: "s\(i)") }
// numbers, to see the other direction
d.set(2, forKey: "n_two"); d.set(-1, forKey: "n_neg"); d.set(0.4, forKey: "n_frac")
d.set(0.0, forKey: "n_zerod"); d.set(Int64(1) << 40, forKey: "n_big")

print("stored string        | UD.integer  UD.double   UD.bool  | NSString.integerValue  .doubleValue  .boolValue")
print(String(repeating: "-", count: 104))
var diffs = 0
for (i, s) in strings.enumerated() {
    let k = "s\(i)"
    let ui = d.integer(forKey: k), ud = d.double(forKey: k), ub = d.bool(forKey: k)
    let ns = NSString(string: s)
    let ni = ns.integerValue, nd = ns.doubleValue, nb = ns.boolValue
    let mark = (ui != ni || ub != nb || ud != nd) ? "  <-- DIVERGES" : ""
    if !mark.isEmpty { diffs += 1 }
    print("\(("\"" + s + "\"").padding(toLength: 21, withPad: " ", startingAt: 0))| "
        + "\(String(ui).padding(toLength: 12, withPad: " ", startingAt: 0))"
        + "\(String(format: "%-12g", ud))"
        + "\(String(ub).padding(toLength: 9, withPad: " ", startingAt: 0))| "
        + "\(String(ni).padding(toLength: 22, withPad: " ", startingAt: 0))"
        + "\(String(format: "%-14g", nd))"
        + "\(String(nb))\(mark)")
}
print("\nrows where UserDefaults' answer != the NSString conversion: \(diffs) of \(strings.count)")

print("\n--- numbers, the other direction ---")
for k in ["n_two", "n_neg", "n_frac", "n_zerod", "n_big"] {
    print("  \(k.padding(toLength: 10, withPad: " ", startingAt: 0)) "
        + "object=\(d.object(forKey: k)!)  string=\(d.string(forKey: k) ?? "nil")  "
        + "integer=\(d.integer(forKey: k))  double=\(d.double(forKey: k))  bool=\(d.bool(forKey: k))")
}

print("\n--- register(defaults:) with a STRING, read through typed getters ---")
d.register(defaults: ["r_str_num": "42", "r_bool_str": "YES", "r_int": 5])
print("  integer(r_str_num) = \(d.integer(forKey: "r_str_num"))")
print("  bool(r_bool_str)   = \(d.bool(forKey: "r_bool_str"))")
print("  object(r_int)      = \(type(of: d.object(forKey: "r_int")!)) \(d.object(forKey: "r_int")!)")

print("\n--- stringArray on a mixed array ---")
d.set(["a", 1, "b"] as [Any], forKey: "mixed")
print("  array(mixed)       = \(d.array(forKey: "mixed") ?? [])")
print("  stringArray(mixed) = \(String(describing: d.stringArray(forKey: "mixed")))")
d.set(["a", "b"], forKey: "allstr")
print("  stringArray(allstr)= \(String(describing: d.stringArray(forKey: "allstr")))")

print("\n--- set(nil) vs removeObject ---")
d.set("x", forKey: "nilme")
d.set(nil, forKey: "nilme")
print("  after set(nil): \(String(describing: d.object(forKey: "nilme")))")

d.removePersistentDomain(forName: suite)
