import Foundation
import LightweightCodeRequirements

func testOnDiskSigningFlagRawValues() {
    typealias Flags = OnDiskCodeSigningFlags.ValueSet
    precondition(Flags.terminatesOnCodeSigningFailure.rawValue == 0x200)
    precondition(Flags.signalsBusErrorOnCodeSigningFailure.rawValue == 0x100)
    precondition(Flags.isCodeSignatureRequiredForAllExecutableCode.rawValue == 0x1000)
    precondition(Flags.isAdhocSigned.rawValue == 0x2)
    precondition(Flags.isSignedByLinker.rawValue == 0x20000)
    precondition(Flags.isHardenedRuntimeEnforced.rawValue == 0x10000)
    precondition(Flags.isLibraryValidationRequired.rawValue == 0x2000)
    precondition(Flags.isDynamicLinkerPolicyHardened.rawValue == 0x800)
    precondition(Flags.isCertificateExpirationEnforced.rawValue == 0x400)
    let rebuilt = Flags(rawValue: Flags.isAdhocSigned.rawValue)
    precondition(rebuilt == .isAdhocSigned)
    let _: Flags.RawValue = rebuilt.rawValue
}

func testOnDiskSigningFlagsIsSuperset() {
    let constraint = OnDiskCodeSigningFlags.isSuperset(of: [.isAdhocSigned, .isSignedByLinker])
    precondition(constraint.required.contains(.isAdhocSigned))
    precondition(constraint.required.contains(.isSignedByLinker))
    precondition(!constraint.required.contains(.isHardenedRuntimeEnforced))
    let _: OnDiskCodeSigningFlags.OutType = constraint
    let _: OnDiskCodeSigningFlags.DataType = constraint.required
}

func testOnDiskSigningFlagsOptionSetUnion() {
    var flags: OnDiskCodeSigningFlags.ValueSet = [.isAdhocSigned]
    flags.formUnion(.isSignedByLinker)
    precondition(flags.contains(.isAdhocSigned))
    precondition(flags.contains(.isSignedByLinker))
    let united = OnDiskCodeSigningFlags.ValueSet.isAdhocSigned.union(.isLibraryValidationRequired)
    precondition(united.contains(.isAdhocSigned) && united.contains(.isLibraryValidationRequired))
}

func testOnDiskSigningFlagsOptionSetIntersection() {
    let left: OnDiskCodeSigningFlags.ValueSet = [.isAdhocSigned, .isSignedByLinker]
    let right: OnDiskCodeSigningFlags.ValueSet = [.isSignedByLinker, .isHardenedRuntimeEnforced]
    precondition(left.intersection(right) == .isSignedByLinker)
    var mutating = left
    mutating.formIntersection(right)
    precondition(mutating == .isSignedByLinker)
}

func testOnDiskSigningFlagsOptionSetSymmetricDifference() {
    let left: OnDiskCodeSigningFlags.ValueSet = [.isAdhocSigned, .isSignedByLinker]
    let right: OnDiskCodeSigningFlags.ValueSet = [.isSignedByLinker, .isHardenedRuntimeEnforced]
    let diff = left.symmetricDifference(right)
    precondition(diff.contains(.isAdhocSigned))
    precondition(diff.contains(.isHardenedRuntimeEnforced))
    precondition(!diff.contains(.isSignedByLinker))
    var mutating = left
    mutating.formSymmetricDifference(right)
    precondition(mutating == diff)
}

func testOnDiskSigningFlagsOptionSetSubtract() {
    var flags: OnDiskCodeSigningFlags.ValueSet = [.isAdhocSigned, .isSignedByLinker]
    flags.subtract(.isAdhocSigned)
    precondition(flags == .isSignedByLinker)
    let subtracted = OnDiskCodeSigningFlags.ValueSet([.isAdhocSigned, .isHardenedRuntimeEnforced])
        .subtracting(.isAdhocSigned)
    precondition(subtracted == .isHardenedRuntimeEnforced)
}

func testOnDiskSigningFlagsOptionSetMembership() {
    let flags: OnDiskCodeSigningFlags.ValueSet = [.isAdhocSigned, .isSignedByLinker]
    precondition(flags.contains(.isAdhocSigned))
    precondition(!flags.contains(.isHardenedRuntimeEnforced))
    precondition(flags.isSuperset(of: .isAdhocSigned))
    precondition(!flags.isSubset(of: .isAdhocSigned))
    precondition(flags.isSubset(of: flags))
    precondition(OnDiskCodeSigningFlags.ValueSet.isAdhocSigned.isDisjoint(with: .isSignedByLinker))
    precondition(OnDiskCodeSigningFlags.ValueSet.isAdhocSigned.isStrictSubset(of: flags))
    precondition(flags.isStrictSuperset(of: .isAdhocSigned))
    precondition(!OnDiskCodeSigningFlags.ValueSet().isEmpty == false)
    precondition(OnDiskCodeSigningFlags.ValueSet().isEmpty)
}

func testOnDiskSigningFlagsOptionSetInsertRemove() {
    var flags = OnDiskCodeSigningFlags.ValueSet()
    let inserted = flags.insert(.isAdhocSigned)
    precondition(inserted.inserted)
    precondition(inserted.memberAfterInsert == .isAdhocSigned)
    let updated = flags.update(with: .isSignedByLinker)
    precondition(updated == nil)
    let removed = flags.remove(.isAdhocSigned)
    precondition(removed == .isAdhocSigned)
    precondition(!flags.contains(.isAdhocSigned))
}

func testOnDiskSigningFlagsInits() {
    let empty = OnDiskCodeSigningFlags.ValueSet()
    precondition(empty.isEmpty)
    let literal: OnDiskCodeSigningFlags.ValueSet = [.isAdhocSigned, .isLibraryValidationRequired]
    precondition(literal.contains(.isAdhocSigned))
    let sequenced = OnDiskCodeSigningFlags.ValueSet([.isSignedByLinker, .isHardenedRuntimeEnforced])
    precondition(sequenced.contains(.isSignedByLinker))
    precondition(literal != empty)
}

func testOnDiskSigningFlagsCodable() {
    let flags: OnDiskCodeSigningFlags.ValueSet = [.isAdhocSigned, .isSignedByLinker]
    let decodedFlags = try! lcrRoundTrip(flags)
    precondition(decodedFlags == flags)
    let constraint = OnDiskCodeSigningFlags.isSuperset(of: flags)
    let decoded = try! lcrRoundTrip(constraint)
    precondition(decoded.required == flags)
}

func testProcessSigningFlagRawValues() {
    typealias Flags = ProcessCodeSigningFlags.ValueSet
    precondition(Flags.terminatesOnCodeSigningFailure.rawValue == 0x200)
    precondition(Flags.signalsBusErrorOnCodeSigningFailure.rawValue == 0x100)
    precondition(Flags.isCodeSignatureRequiredForAllExecutableCode.rawValue == 0x1000)
    precondition(Flags.isDebugged.rawValue == 0x10000000)
    precondition(Flags.isDebuggable.rawValue == 0x4)
    precondition(Flags.isAdhocSigned.rawValue == 0x2)
    precondition(Flags.isPlatformSigned.rawValue == 0x04000000)
    precondition(Flags.isSignedByLinker.rawValue == 0x20000)
    precondition(Flags.isDynamicallyValid.rawValue == 0x1)
    precondition(Flags.isHardenedRuntimeEnforced.rawValue == 0x10000)
    precondition(Flags.isLibraryValidationRequired.rawValue == 0x2000)
    precondition(Flags.isDynamicLinkerPolicyHardened.rawValue == 0x800)
    precondition(Flags.isCertificateExpirationEnforced.rawValue == 0x400)
    precondition(Flags.isSigned.rawValue == 0x20000000)
    precondition(Flags(rawValue: 0x1) == .isDynamicallyValid)
    let _: Flags.RawValue = Flags.isSigned.rawValue
}

func testProcessSigningFlagsIsSuperset() {
    let constraint = ProcessCodeSigningFlags.isSuperset(of: [.isDebuggable, .isSigned])
    precondition(constraint.required.contains(.isDebuggable))
    precondition(constraint.required.contains(.isSigned))
    let _: ProcessCodeSigningFlags.OutType = constraint
    let _: ProcessCodeSigningFlags.DataType = constraint.required
}

func testProcessSigningFlagsOptionSetUnion() {
    var flags: ProcessCodeSigningFlags.ValueSet = [.isDebugged]
    flags.formUnion(.isDebuggable)
    precondition(flags.contains(.isDebugged) && flags.contains(.isDebuggable))
    let united = ProcessCodeSigningFlags.ValueSet.isSigned.union(.isPlatformSigned)
    precondition(united.contains(.isSigned) && united.contains(.isPlatformSigned))
}

func testProcessSigningFlagsOptionSetIntersection() {
    let left: ProcessCodeSigningFlags.ValueSet = [.isSigned, .isDebuggable]
    let right: ProcessCodeSigningFlags.ValueSet = [.isDebuggable, .isPlatformSigned]
    precondition(left.intersection(right) == .isDebuggable)
    var mutating = left
    mutating.formIntersection(right)
    precondition(mutating == .isDebuggable)
}

func testProcessSigningFlagsOptionSetSymmetricDifference() {
    let left: ProcessCodeSigningFlags.ValueSet = [.isSigned, .isDebuggable]
    let right: ProcessCodeSigningFlags.ValueSet = [.isDebuggable, .isPlatformSigned]
    let diff = left.symmetricDifference(right)
    precondition(diff.contains(.isSigned) && diff.contains(.isPlatformSigned))
    var mutating = left
    mutating.formSymmetricDifference(right)
    precondition(mutating == diff)
}

func testProcessSigningFlagsOptionSetSubtract() {
    var flags: ProcessCodeSigningFlags.ValueSet = [.isSigned, .isDebuggable]
    flags.subtract(.isDebuggable)
    precondition(flags == .isSigned)
    let subtracted = ProcessCodeSigningFlags.ValueSet([.isSigned, .isPlatformSigned]).subtracting(.isSigned)
    precondition(subtracted == .isPlatformSigned)
}

func testProcessSigningFlagsOptionSetMembership() {
    let flags: ProcessCodeSigningFlags.ValueSet = [.isSigned, .isDebuggable]
    precondition(flags.contains(.isSigned))
    precondition(!flags.contains(.isPlatformSigned))
    precondition(flags.isSuperset(of: .isSigned))
    precondition(flags.isSubset(of: flags))
    precondition(ProcessCodeSigningFlags.ValueSet.isSigned.isDisjoint(with: .isDebuggable))
    precondition(ProcessCodeSigningFlags.ValueSet.isSigned.isStrictSubset(of: flags))
    precondition(flags.isStrictSuperset(of: .isSigned))
    precondition(ProcessCodeSigningFlags.ValueSet().isEmpty)
}

func testProcessSigningFlagsOptionSetInsertRemove() {
    var flags = ProcessCodeSigningFlags.ValueSet()
    let inserted = flags.insert(.isSigned)
    precondition(inserted.inserted)
    let updated = flags.update(with: .isDebuggable)
    precondition(updated == nil)
    let removed = flags.remove(.isSigned)
    precondition(removed == .isSigned)
}

func testProcessSigningFlagsInits() {
    let empty = ProcessCodeSigningFlags.ValueSet()
    precondition(empty.isEmpty)
    let literal: ProcessCodeSigningFlags.ValueSet = [.isSigned, .isDynamicallyValid]
    precondition(literal.contains(.isSigned))
    let sequenced = ProcessCodeSigningFlags.ValueSet([.isPlatformSigned])
    precondition(sequenced.contains(.isPlatformSigned))
    precondition(literal != empty)
}

func testProcessSigningFlagsCodable() {
    let flags: ProcessCodeSigningFlags.ValueSet = [.isSigned, .isDebuggable]
    precondition(try! lcrRoundTrip(flags) == flags)
    let constraint = ProcessCodeSigningFlags.isSuperset(of: flags)
    precondition(try! lcrRoundTrip(constraint).required == flags)
}
