import Network
let m = NWPathMonitor()
let p = m.currentPath
print("reason=\(p.unsatisfiedReason) v4=\(p.supportsIPv4) v6=\(p.supportsIPv6) dns=\(p.supportsDNS) usesWifi=\(p.usesInterfaceType(.wifi)) eq=\(p == m.currentPath)")
let r = NWPathMonitor(requiredInterfaceType: .cellular).currentPath
print("required-cellular before start: \(r.status) \(r.unsatisfiedReason)")
