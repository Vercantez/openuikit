// The first process to hold BOTH halves of Foundation at once.
//
// FoundationEssentials (the Swift port) and our CoreFoundation (the C port)
// have never been in one process. UserDefaults is the first ported class whose
// implementation is Swift-over-CF rather than pure Swift, so this runner is the
// artifact that needs both -- and it is why #87 exists.
//
// This is DELIBERATELY NOT THE SCOREBOARD. It answers one question -- do the
// two halves load and interoperate in a live process under machorun -- and
// says so. Scoring the port against the Darwin golden is step 4 and needs the
// value marshalling this bridge does not yet do.
//
// THE NON-ASCII KEY IS A CONDITION ON THIS WORK, NOT DECORATION. The guest
// bridge builds CFStrings with CFStringCreateWithBytes(UTF-8, no BOM), and an
// ASCII-only corpus would pass with almost any encoding argument. A key with
// multi-byte UTF-8 in it is the smallest thing that can tell a correct encoding
// from a plausible one.

import FoundationEssentials
import PortedUserDefaultsGuest
import UDPlatformMinimal   // exit(); NOT Darwin -- see the header

var pass = 0, fail = 0
func check(_ label: String, _ got: String, _ want: String) {
    if got == want { pass += 1; print("  OK   \(label)  =\(got)") }
    else { fail += 1; print("  FAIL \(label)  got \(got)  want \(want)") }
}

print("\n=== FE + our CoreFoundation, in ONE process ===")

let suite = "com.example.udguest"
guard let d = UserDefaults(suiteName: suite) else {
    print("FATAL: UserDefaults(suiteName:) returned nil"); ud_exit(1)
}

// Negative control FIRST. If a read returned something for every key, every
// check below would pass for the wrong reason.
check("absent key reads nil", d.object(forKey: "never_set") == nil ? "nil" : "some", "nil")

d.set("hello", forKey: "k_string")
check("string round-trip", d.string(forKey: "k_string") ?? "nil", "hello")

d.set(true, forKey: "k_bool")
check("bool round-trip", String(d.bool(forKey: "k_bool")), "true")

// The folding hazard, in the direction that matters: a stored `true` must not
// come back as an Int, and a stored 1 must not come back as a Bool.
d.set(1, forKey: "k_one")
check("Int 1 stays Int", String(describing: type(of: d.object(forKey: "k_one")!)), "Int")
check("Bool stays Bool", String(describing: type(of: d.object(forKey: "k_bool")!)), "Bool")

d.set(42, forKey: "k_int")
check("integer round-trip", String(d.integer(forKey: "k_int")), "42")

d.set(3.5, forKey: "k_double")
check("double round-trip", String(d.double(forKey: "k_double")), "3.5")

// THE ENCODING PATH. Multi-byte UTF-8 in both the key and the value.
let uk = "clé_caché_日本"
d.set("café_日本", forKey: uk)
check("non-ASCII key and value", d.string(forKey: uk) ?? "nil", "café_日本")

// The measured Darwin coercion rules, through the guest bridge this time.
d.set("3.75", forKey: "k_numstr")
check("integer(\"3.75\") is 0, not 3", String(d.integer(forKey: "k_numstr")), "0")
check("double(\"3.75\") is 3.75", String(d.double(forKey: "k_numstr")), "3.75")
d.set("YES", forKey: "k_yes")
check("bool(\"YES\") is true", String(d.bool(forKey: "k_yes")), "true")
d.set("2", forKey: "k_two")
check("bool(\"2\") is false", String(d.bool(forKey: "k_two")), "false")

d.removeObject(forKey: "k_string")
check("removeObject", d.object(forKey: "k_string") == nil ? "nil" : "some", "nil")

check("synchronize", String(d.synchronize()), "true")

print("\nguest runner: pass \(pass)  fail \(fail)")
print(fail == 0 ? "GUEST RUNNER PASS" : "GUEST RUNNER FAIL")
ud_exit(fail == 0 ? 0 : 1)
