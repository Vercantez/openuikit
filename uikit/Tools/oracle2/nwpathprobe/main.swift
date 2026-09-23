import Foundation
import Network

// Contract probe for the NWPathMonitor surface NetNewsWire RSWeb/NetworkMonitor.swift uses.
let m = NWPathMonitor()
func describe(_ p: NWPath) -> String {
    "status=\(p.status) interfaces=\(p.availableInterfaces.map { "\($0.type)" }) expensive=\(p.isExpensive) constrained=\(p.isConstrained)"
}
print("before start: \(describe(m.currentPath))")
print("queue before start: \(String(describing: m.queue))")
let q = DispatchQueue(label: "probe")
var calls = 0
let lock = NSLock()
m.pathUpdateHandler = { p in
    lock.lock(); calls += 1; let n = calls; lock.unlock()
    let onQueue = String(cString: __dispatch_queue_get_label(nil))
    print("handler #\(n) on=\(onQueue) \(describe(p))")
}
m.start(queue: q)
Thread.sleep(forTimeInterval: 1.5)
lock.lock(); print("calls after 1.5s: \(calls)"); lock.unlock()
print("after start: \(describe(m.currentPath)) queue=\(m.queue?.label ?? "nil")")
m.cancel()
Thread.sleep(forTimeInterval: 0.5)
lock.lock(); print("calls after cancel: \(calls)"); lock.unlock()
print("after cancel: \(describe(m.currentPath))")
print("unsatisfied==unsatisfied: \(NWPath.Status.unsatisfied == .unsatisfied)")
print("interface types: \([NWInterface.InterfaceType.other, .wifi, .cellular, .wiredEthernet, .loopback].map { "\($0)" })")
