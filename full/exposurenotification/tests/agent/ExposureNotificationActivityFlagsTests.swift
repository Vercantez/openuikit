import Foundation
import ExposureNotification

func testENActivityFlagsMembers() {
    precondition(ENActivityFlags.reserved1.rawValue == 1 << 0)
    precondition(ENActivityFlags.reserved2.rawValue == 1 << 1)
    precondition(ENActivityFlags.periodicRun.rawValue == 1 << 2)
    precondition(ENActivityFlags.preAuthorizedKeyReleaseNotificationTapped.rawValue == 1 << 3)
    precondition(ENActivityFlags(rawValue: 1 << 2) == .periodicRun)
    precondition(ENActivityFlags.reserved1 != .reserved2)
}

func testENActivityFlagsEmptyAndContains() {
    let empty = ENActivityFlags()
    precondition(empty.isEmpty)
    precondition(!empty.contains(.periodicRun))
    precondition(ENActivityFlags.periodicRun.contains(.periodicRun))
    precondition(!ENActivityFlags.periodicRun.contains(.reserved1))
}

func testENActivityFlagsUnionAndIntersection() {
    let combined = ENActivityFlags.periodicRun.union(.reserved1)
    precondition(combined.contains(.periodicRun))
    precondition(combined.contains(.reserved1))
    precondition(combined.intersection(.periodicRun) == .periodicRun)
    precondition(combined.symmetricDifference(.reserved1) == .periodicRun)
}

func testENActivityFlagsFormOperations() {
    var flags: ENActivityFlags = .periodicRun
    flags.formUnion(.reserved2)
    precondition(flags.contains(.periodicRun) && flags.contains(.reserved2))
    flags.formIntersection(.reserved2)
    precondition(flags == .reserved2)
    flags.formSymmetricDifference(.preAuthorizedKeyReleaseNotificationTapped)
    precondition(flags.contains(.reserved2))
    precondition(flags.contains(.preAuthorizedKeyReleaseNotificationTapped))
}

func testENActivityFlagsInsertRemoveUpdate() {
    var flags = ENActivityFlags()
    let inserted = flags.insert(.periodicRun)
    precondition(inserted.inserted)
    precondition(inserted.memberAfterInsert == .periodicRun)
    let removed = flags.remove(.periodicRun)
    precondition(removed == .periodicRun)
    precondition(flags.isEmpty)
    let updated = flags.update(with: .reserved1)
    precondition(updated == nil)
    precondition(flags.contains(.reserved1))
}

func testENActivityFlagsSubsetAlgebra() {
    let small: ENActivityFlags = .periodicRun
    let large: ENActivityFlags = [.periodicRun, .reserved1]
    precondition(small.isSubset(of: large))
    precondition(large.isSuperset(of: small))
    precondition(small.isStrictSubset(of: large))
    precondition(large.isStrictSuperset(of: small))
    precondition(small.isDisjoint(with: .reserved2))
    precondition(!small.isDisjoint(with: large))
}

func testENActivityFlagsSubtractAndSequence() {
    var flags: ENActivityFlags = [.periodicRun, .reserved1, .reserved2]
    flags.subtract(.reserved1)
    precondition(!flags.contains(.reserved1))
    precondition(flags.contains(.periodicRun))
    let subtracted = flags.subtracting(.periodicRun)
    precondition(subtracted == .reserved2)

    let fromSequence = ENActivityFlags([.periodicRun, .reserved2])
    precondition(fromSequence.contains(.periodicRun))
    precondition(fromSequence.contains(.reserved2))

    let literal: ENActivityFlags = [.periodicRun, .preAuthorizedKeyReleaseNotificationTapped]
    precondition(literal.contains(.periodicRun))
    precondition(literal.contains(.preAuthorizedKeyReleaseNotificationTapped))
}

func testENActivityFlagsInequality() {
    precondition(ENActivityFlags.periodicRun != ENActivityFlags.reserved1)
    precondition(!(ENActivityFlags.periodicRun != ENActivityFlags.periodicRun))
}
