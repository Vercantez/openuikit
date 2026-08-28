import Foundation
let suite = "com.example.udprobe.dr"
let d = UserDefaults(suiteName: suite)!
d.set("v", forKey: "mine_1"); d.set(2, forKey: "mine_2"); d.synchronize()
let dr = d.dictionaryRepresentation()
let pd = d.persistentDomain(forName: suite) ?? [:]
print("dictionaryRepresentation count = \(dr.count)")
print("persistentDomain(suite) count  = \(pd.count)   keys=\(pd.keys.sorted())")
let g = d.persistentDomain(forName: UserDefaults.globalDomain) ?? [:]
print("persistentDomain(NSGlobalDomain) count = \(g.count)")
let extras = Set(dr.keys).subtracting(pd.keys)
print("\nkeys in dictionaryRepresentation but NOT in this suite: \(extras.count)")
print("  of those, in NSGlobalDomain: \(extras.intersection(g.keys).count)")
print("  sample: \(extras.sorted().prefix(12).joined(separator: ", "))")
print("\nvolatileDomainNames = \(d.volatileDomainNames)")
print("argumentDomain      = \(d.volatileDomain(forName: UserDefaults.argumentDomain))")
print("registrationDomain in volatile names? \(d.volatileDomainNames.contains(UserDefaults.registrationDomain))")
d.removePersistentDomain(forName: suite)
