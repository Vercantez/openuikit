import Foundation
import PHASE

func phaseDependencyIdentityProbe() {
    let engine = PHASEEngine(updateMode: .manual)
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("phase-identity-\(UUID().uuidString).bin")
    try! Data([0x01, 0x02]).write(to: url)
    defer { try? FileManager.default.removeItem(at: url) }
    precondition(!String(reflecting: type(of: url)).hasPrefix("PHASE."))
    let pair = PHASENumericPair(firstValue: TimeInterval(1.5), secondValue: TimeInterval(3))
    precondition(pair.first == 1.5)
    pair.second = TimeInterval(4)
    precondition(pair.second == 4)
    let info: [String: Any] = ["url": url.path]
    let error = PHASEError(.initializeFailed, userInfo: info)
    precondition(error.userInfo["url"] as? String == url.path)
    let ns = error as NSError
    precondition(ns.domain == PHASEErrorDomain)
    _ = engine
}

#if PHASE_IDENTITY_MAIN
phaseDependencyIdentityProbe()
print("PHASE_DEPENDENCY_IDENTITY_OK")
#endif
