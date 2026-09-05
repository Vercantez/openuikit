import CFNetwork
import CoreFoundation
import Foundation
#if canImport(Glibc)
import Glibc
#endif

final class CallbackCounter {
    var value = 0
}

func cfDataFromUTF8(_ value: String) -> CFData {
    Array(value.utf8).withUnsafeBufferPointer { buffer in
        CFDataCreate(nil, buffer.baseAddress, CFIndex(buffer.count))!
    }
}

func cfDataBytes(_ data: CFData) -> [UInt8] {
    let length = Int(CFDataGetLength(data))
    guard length > 0, let pointer = CFDataGetBytePtr(data) else { return [] }
    return Array(UnsafeBufferPointer(start: pointer, count: length))
}

func require(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError("CFNetworkRuntime: \(message)")
    }
}

func swiftString(_ value: CFString) -> String {
    let length = Int(CFStringGetLength(value))
    var buffer = [CChar](repeating: 0, count: max(16, length * 4 + 1))
    require(
        CFStringGetCString(
            value,
            &buffer,
            CFIndex(buffer.count),
            CFStringBuiltInEncodings.UTF8.rawValue
        ),
        "CFString conversion"
    )
    return String(cString: buffer)
}

func cfString(_ value: String) -> CFString {
    value.withCString { CFStringCreateWithCString(nil, $0, CFStringBuiltInEncodings.UTF8.rawValue)! }
}

func testCFNetServiceMonitorTypeRawValues() {

    require(CFNetServiceMonitorType.TXT.rawValue == 1, "TXT monitor")
    require(CFNetServiceMonitorType(rawValue: 1) == .TXT, "TXT init")
    require(CFNetServiceMonitorType.TXT == CFNetServiceMonitorType.TXT, "TXT equality")
    require(CFNetServiceMonitorType.TXT.hashValue == CFNetServiceMonitorType.TXT.hashValue, "TXT hashValue")
    var hasher = Hasher()
    CFNetServiceMonitorType.TXT.hash(into: &hasher)
    _ = hasher.finalize()
}

func testCFNetServiceBrowserFlagAlgebra() {

    var flags: CFNetServiceBrowserFlags = []
    require(flags.isEmpty, "empty browser flags")
    let inserted = flags.insert(.moreComing)
    require(inserted.inserted, "insert moreComing")
    require(flags.contains(.moreComing), "contains moreComing")
    require(!flags.contains(.isDomain), "does not contain isDomain")
    flags.formUnion(.isDomain)
    require(flags.contains(.isDomain), "union isDomain")
    let intersection = flags.intersection([.moreComing])
    require(intersection.contains(.moreComing) && !intersection.contains(.isDomain), "intersection")
    flags.remove(.moreComing)
    require(!flags.contains(.moreComing), "remove moreComing")
    _ = flags.update(with: .isDefault)
    require(flags.contains(.isDefault), "update isDefault")
    flags.insert(.remove)
    require(flags.contains(.remove), "contains remove")
    let unioned = flags.union(.moreComing)
    require(unioned.contains(.moreComing), "union moreComing")
    let symmetric = flags.symmetricDifference(.isDefault)
    require(!symmetric.contains(.isDefault), "symmetric difference")
    let subtracted = flags.subtracting(.remove)
    require(!subtracted.contains(.remove), "subtracting remove")
    flags.subtract(.remove)
    require(!flags.contains(.remove), "subtract remove")
    flags.formIntersection(.isDefault)
    require(flags.contains(.isDefault) && !flags.contains(.isDomain), "formIntersection")
    flags.formSymmetricDifference(.moreComing)
    require(flags.contains(.moreComing), "formSymmetricDifference")
    require(flags.isDisjoint(with: .remove), "isDisjoint")
    require(flags.isSubset(of: [.isDefault, .moreComing, .isDomain]), "isSubset")
    require(flags.isSuperset(of: [.moreComing]), "isSuperset")
    require(
        flags.isStrictSubset(of: [.isDefault, .moreComing, .isDomain, .remove]),
        "isStrictSubset"
    )
    require(!flags.isStrictSuperset(of: flags), "isStrictSuperset self")
    let fromSequence = CFNetServiceBrowserFlags([.moreComing, .isDomain])
    require(fromSequence.contains(.isDomain), "sequence init")
    _ = CFNetServiceBrowserFlags()
    require(CFNetServiceBrowserFlags(rawValue: 1) == .moreComing, "rawValue moreComing")
    require(CFNetServiceBrowserFlags.moreComing != .remove, "browser flag inequality")
}

func testCFNetServiceRegisterFlagAlgebra() {

    var renamed: CFNetServiceRegisterFlags = []
    require(renamed.isEmpty, "register empty")
    _ = renamed.insert(.noAutoRename)
    require(renamed.contains(.noAutoRename), "noAutoRename")
    _ = renamed.remove(.noAutoRename)
    _ = renamed.update(with: .noAutoRename)
    require(renamed.union(.noAutoRename).contains(.noAutoRename), "register union")
    require(renamed.intersection(.noAutoRename).contains(.noAutoRename), "register intersection")
    require(renamed.symmetricDifference([]).contains(.noAutoRename), "register symmetric")
    require(renamed.subtracting(.noAutoRename).isEmpty, "register subtracting")
    renamed.subtract(.noAutoRename)
    renamed.formUnion(.noAutoRename)
    renamed.formIntersection(.noAutoRename)
    renamed.formSymmetricDifference([])
    require(renamed.isDisjoint(with: []), "register disjoint empty")
    require(renamed.isSubset(of: .noAutoRename), "register subset")
    require(renamed.isSuperset(of: []), "register superset")
    require(!renamed.isStrictSubset(of: .noAutoRename), "register strict subset equal")
    require(renamed.isStrictSuperset(of: []), "register strict superset")
    _ = CFNetServiceRegisterFlags([.noAutoRename])
    _ = CFNetServiceRegisterFlags()
    require(CFNetServiceRegisterFlags(arrayLiteral: .noAutoRename).contains(.noAutoRename), "arrayLiteral")
    require(CFNetServiceRegisterFlags(rawValue: 1) == .noAutoRename, "register rawValue")
    require(CFNetServiceRegisterFlags.noAutoRename != CFNetServiceRegisterFlags(), "register inequality")
}
