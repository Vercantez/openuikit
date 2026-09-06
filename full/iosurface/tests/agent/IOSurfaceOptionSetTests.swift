import Foundation
import IOSurface

func testLockOptionsMembers() {
    precondition(IOSurfaceLockOptions.readOnly.rawValue == 1)
    precondition(IOSurfaceLockOptions.avoidSync.rawValue == 2)
    precondition(IOSurfaceLockOptions(rawValue: 1) == .readOnly)
    precondition(IOSurfaceLockOptions.readOnly != .avoidSync)
}

func testLockOptionsAlgebra() {
    var flags = IOSurfaceLockOptions()
    precondition(flags.isEmpty)
    let inserted = flags.insert(.readOnly)
    precondition(inserted.inserted)
    precondition(flags.contains(.readOnly))
    precondition(!flags.contains(.avoidSync))
    precondition(flags.union(.avoidSync) == [.readOnly, .avoidSync])
    precondition(flags.intersection(.readOnly) == .readOnly)
    precondition(flags.symmetricDifference(.avoidSync).contains(.avoidSync))
    flags.formUnion(.avoidSync)
    flags.formIntersection([.readOnly, .avoidSync])
    flags.formSymmetricDifference(.avoidSync)
    _ = flags.remove(.readOnly)
    _ = flags.update(with: .avoidSync)
    flags.subtract(.avoidSync)
    precondition(IOSurfaceLockOptions.readOnly.isSuperset(of: .readOnly))
    precondition(IOSurfaceLockOptions.readOnly.isSubset(of: [.readOnly, .avoidSync]))
    precondition(IOSurfaceLockOptions.readOnly.isStrictSubset(of: [.readOnly, .avoidSync]))
    precondition(IOSurfaceLockOptions([.readOnly, .avoidSync]).isStrictSuperset(of: .readOnly))
    precondition(IOSurfaceLockOptions.readOnly.isDisjoint(with: .avoidSync))
    precondition(IOSurfaceLockOptions.readOnly.subtracting(.readOnly).isEmpty)
    precondition(IOSurfaceLockOptions(arrayLiteral: .readOnly) == .readOnly)
    precondition(IOSurfaceLockOptions([.avoidSync]) == .avoidSync)
    precondition(IOSurfaceLockOptions.readOnly != [])
    var hasher = Hasher()
    IOSurfaceLockOptions.readOnly.hash(into: &hasher)
    _ = IOSurfaceLockOptions.avoidSync.hashValue
}

func testMemoryLedgerFlagsMembers() {
    precondition(IOSurfaceMemoryLedgerFlags.noFootprint.rawValue == 1)
    precondition(IOSurfaceMemoryLedgerFlags(rawValue: 1) == .noFootprint)
    precondition(IOSurfaceMemoryLedgerFlags.noFootprint != [])
}

func testMemoryLedgerFlagsAlgebra() {
    var flags = IOSurfaceMemoryLedgerFlags()
    precondition(flags.isEmpty)
    _ = flags.insert(.noFootprint)
    precondition(flags.contains(.noFootprint))
    precondition(flags.union(.noFootprint) == .noFootprint)
    precondition(flags.intersection(.noFootprint) == .noFootprint)
    _ = flags.symmetricDifference([])
    flags.formUnion(.noFootprint)
    flags.formIntersection(.noFootprint)
    flags.formSymmetricDifference([])
    _ = flags.remove(.noFootprint)
    _ = flags.update(with: .noFootprint)
    flags.subtract(.noFootprint)
    precondition(IOSurfaceMemoryLedgerFlags.noFootprint.isSuperset(of: .noFootprint))
    precondition(IOSurfaceMemoryLedgerFlags.noFootprint.isSubset(of: .noFootprint))
    precondition(!IOSurfaceMemoryLedgerFlags.noFootprint.isStrictSubset(of: .noFootprint))
    precondition(!IOSurfaceMemoryLedgerFlags.noFootprint.isStrictSuperset(of: .noFootprint))
    precondition(IOSurfaceMemoryLedgerFlags.noFootprint.isDisjoint(with: []))
    precondition(IOSurfaceMemoryLedgerFlags.noFootprint.subtracting(.noFootprint).isEmpty)
    precondition(IOSurfaceMemoryLedgerFlags(arrayLiteral: .noFootprint) == .noFootprint)
    precondition(IOSurfaceMemoryLedgerFlags([.noFootprint]) == .noFootprint)
    var hasher = Hasher()
    IOSurfaceMemoryLedgerFlags.noFootprint.hash(into: &hasher)
    _ = flags.hashValue
}

func testPurgeabilityStateMembers() {
    precondition(IOSurfacePurgeabilityState.purgeableVolatile.rawValue == 1)
    precondition(IOSurfacePurgeabilityState.purgeableEmpty.rawValue == 2)
    precondition(IOSurfacePurgeabilityState.purgeableKeepCurrent.rawValue == 3)
    precondition(IOSurfacePurgeabilityState(rawValue: 2) == .purgeableEmpty)
    precondition(IOSurfacePurgeabilityState.purgeableVolatile != .purgeableEmpty)
}

func testPurgeabilityStateAlgebra() {
    var state = IOSurfacePurgeabilityState()
    precondition(state.isEmpty)
    _ = state.insert(.purgeableVolatile)
    precondition(state.contains(.purgeableVolatile))
    precondition(state.union(.purgeableEmpty).contains(.purgeableEmpty))
    precondition(state.intersection(.purgeableVolatile) == .purgeableVolatile)
    _ = state.symmetricDifference(.purgeableEmpty)
    state.formUnion(.purgeableEmpty)
    state.formIntersection([.purgeableVolatile, .purgeableEmpty])
    state.formSymmetricDifference(.purgeableKeepCurrent)
    _ = state.remove(.purgeableEmpty)
    _ = state.update(with: .purgeableKeepCurrent)
    state.subtract(.purgeableKeepCurrent)
    precondition(IOSurfacePurgeabilityState.purgeableEmpty.isSuperset(of: .purgeableEmpty))
    precondition(IOSurfacePurgeabilityState.purgeableVolatile.isSubset(of: .purgeableVolatile))
    precondition(!IOSurfacePurgeabilityState.purgeableEmpty.isStrictSubset(of: .purgeableEmpty))
    precondition(IOSurfacePurgeabilityState.purgeableKeepCurrent.isDisjoint(with: .purgeableVolatile))
    precondition(IOSurfacePurgeabilityState.purgeableEmpty.subtracting(.purgeableEmpty).isEmpty)
    precondition(IOSurfacePurgeabilityState(arrayLiteral: .purgeableVolatile) == .purgeableVolatile)
    precondition(IOSurfacePurgeabilityState([.purgeableEmpty]) == .purgeableEmpty)
    var hasher = Hasher()
    IOSurfacePurgeabilityState.purgeableEmpty.hash(into: &hasher)
    _ = IOSurfacePurgeabilityState.purgeableKeepCurrent.hashValue
}
