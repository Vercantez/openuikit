// Rule refinement: the SAMPLES in probe2 show integer/bool/double on strings are
// not the NSString conversions. This pins the actual RULES, because the port has
// to justify each correction at its own site, not gesture at a table.
import Foundation
let suite = "com.example.udprobe.rules"
let d = UserDefaults(suiteName: suite)!

func row(_ s: String) -> (Int, Double, Bool) {
    d.set(s, forKey: "k"); return (d.integer(forKey: "k"), d.double(forKey: "k"), d.bool(forKey: "k"))
}
print("=== INTEGER: where exactly is the boundary? ===")
for s in ["2147483647","2147483648","3000000000","-2147483648","-2147483649","-3000000000",
          " 123","\t123","\n123","123\t","  -7","- 7","--7","+ 7","007",
          "2147483647x","","+","-","+0","1_000"] {
    let (i,_,_) = row(s); print("  integer(\"\(s.replacingOccurrences(of:"\n",with:"\\n").replacingOccurrences(of:"\t",with:"\\t"))\") = \(i)")
}
print("\n  and on a STORED NUMBER (not a string), is there a clamp?")
d.set(Int(3000000000), forKey: "n"); print("    integer(stored Int 3000000000) = \(d.integer(forKey: "n"))")
d.set(Int.max, forKey: "n2"); print("    integer(stored Int.max)          = \(d.integer(forKey: "n2"))")
d.set(2.9, forKey: "n3"); print("    integer(stored Double 2.9)       = \(d.integer(forKey: "n3"))")
d.set(-2.9, forKey: "n4"); print("    integer(stored Double -2.9)      = \(d.integer(forKey: "n4"))")

print("\n=== BOOL: is it a literal word list, and is it case-insensitive? ===")
for s in ["1"," 1","1 ","01","1.0","+1","yEs","YeS","tRuE","truex","yess","yes ", " yes",
          "0","00"," 0","-1","2","true1","YES\n"] {
    let (_,_,b) = row(s); print("  bool(\"\(s.replacingOccurrences(of:"\n",with:"\\n"))\") = \(b)")
}
print("\n=== DOUBLE: prefix parse? which grammar? ===")
for s in ["123 "," 123","1banana","1e3","1E3","0x10","0X10",".5","5.","1e","inf","INF","nan","-inf",
          "1e400","0.1","1,5"] {
    let (_,db,_) = row(s); print("  double(\"\(s)\") = \(db)")
}
print("\n=== FLOAT vs DOUBLE on the same stored value ===")
d.set("3.14159265358979", forKey: "pi")
print("  float(pi)=\(d.float(forKey: "pi"))  double(pi)=\(d.double(forKey: "pi"))")
d.set(Double.pi, forKey: "pid")
print("  float(pid)=\(d.float(forKey: "pid"))  double(pid)=\(d.double(forKey: "pid"))")

print("\n=== string(forKey:) on numbers -- what FORMAT? ===")
for (k,v) in [("d1",1.0),("d2",0.1),("d3",1e21),("d4",1.5),("d5",-0.0)] as [(String,Double)] {
    d.set(v, forKey: k); print("  string(stored Double \(v)) = \(d.string(forKey: k) ?? "nil")")
}
d.set(Int.max, forKey: "i1"); print("  string(stored Int.max)    = \(d.string(forKey: "i1") ?? "nil")")
d.set(true, forKey: "b1");    print("  string(stored true)       = \(d.string(forKey: "b1") ?? "nil")")
d.set(false, forKey: "b2");   print("  string(stored false)      = \(d.string(forKey: "b2") ?? "nil")")
d.removePersistentDomain(forName: suite)
